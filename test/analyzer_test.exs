defmodule AnalyzerTest do
  use ExUnit.Case
  doctest AnalyzerModule

  setup_all do
    on_exit(
      fn ->
        File.rm_rf "xmpp4rails"
      end
    )
    File.rm_rf "xmpp4rails"

    {:ok, repo} = GitModule.clone_repo "https://github.com/kitplummer/xmpp4rails"
    {:ok, date} = GitModule.get_last_commit_date repo
    GitModule.delete_repo(repo)
    weeks = TimeHelper.get_commit_delta(date) |> TimeHelper.sec_to_weeks
    [weeks: weeks]
  end

  test "get report", context do
    report = AnalyzerModule.analyze "https://github.com/kitplummer/xmpp4rails", "test"
    data = JSON.decode!(report)
    expected_data = %{
              "commit_currency_risk" => "critical",
              "commit_currency_weeks" => context[:weeks],
              "contributor_count" => 1,
              "contributor_risk" => "critical",
              "repo" => "https://github.com/kitplummer/xmpp4rails"
    }

    assert "test" == data["header"]["source_client"]
    assert expected_data == data["data"]
  end

end