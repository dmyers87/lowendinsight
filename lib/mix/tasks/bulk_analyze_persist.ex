# Copyright (C) 2020 by the Georgia Tech Research Institute (GTRI)
# This software may be modified and distributed under the terms of
# the BSD 3-Clause license. See the LICENSE file for details.

defmodule Mix.Tasks.Lei.BulkAnalyzePersist do
  use Mix.Task
  @shortdoc "Run LowEndInsight and analyze a list of git repositories, persisting results to a sqlite3 db file."
  @moduledoc ~S"""
  This is used to run a LowEndInsight scan against a repository, by cloning it locally, then looking
  into it.  Pass in the repo URL as a parameter to the task.

  Skipping validation is possible:
  ➜  lowendinsight git:(develop) ✗ mix lei.bulk_analyze test/fixtures/npm.short.csv
  invalid file contents
  ➜  lowendinsight git:(develop) ✗ mix lei.bulk_analyze test/fixtures/npm.short.csv no_validation
  11:45:39.773 [error] Not a Git repo URL, is a subdirectory
  11:45:40.102 [info]  Cloned -> 3: git+https://github.com/SuzuNohara/zzzROOTPreloader.git
  11:45:40.134 [info]  Cloned -> 7: git+https://github.com/zenghongyang/test.git
  11:45:40.177 [info]  Cloned -> 5: git+https://github.com/chameleonbr/zzzz-test-module.git

  This task should be used on very large input datasets.  Even though LEI has _some_ builtin
  error handling, and retry capabilities, this task will allow for the input to be rerun, and any
  existing data already existing (current within 30 days) will be used skipping repeated LEI
  analysis.

  #Usage
  ```
  cat url_list | mix lei.bulk_analyze_persist | jq
  ```
  This will return report metadata (prettied by jq) only.
  ```
  {
  "state": "complete",
  "report": {
    "uuid": "2916881c-67d7-11ea-be2b-88e9fe666193",
    "metadata": "",
  ...
  ```
  """

  def run(args) do
    file = List.first(args)
    db = List.last(args)

    case File.exists?(file) do
      false ->
        Mix.shell().info("\ninvalid file provided")

      true ->
        urls =
          File.read!(file)
          |> String.split("\n", trim: true)

        ## No URL validation done on input, so we can track the number of invalid sources
        ## in the analysis itself.
        {:ok, report} =
          AnalyzerModule.analyze(urls, "mix task", DateTime.utc_now(), %{types: false, db_path: db})

        Poison.encode!(report)
        |> Mix.shell().info()
    end
  end
end
