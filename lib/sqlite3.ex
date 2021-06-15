# Copyright (C) 2020 by the Georgia Tech Research Institute (GTRI)
# This software may be modified and distributed under the terms of
# the BSD 3-Clause license. See the LICENSE file for details.

defmodule Sqlite3 do
  require Logger
  def create_db() do
    Logger.info("Opening DB")
    {:ok, conn} = Exqlite.Sqlite3.open(Application.fetch_env!(:lowendinsight, :persist_path))

    Exqlite.Sqlite3.execute(
      conn,
      "create table lei (id integer primary key, repo text, risk text, created_at text, stuff text)"
    )
  end

  def repo_in_db?(repo, options) do
    db_conn =
      if Map.has_key?(options, :db_conn) do
        Map.get(options, :db_conn)
      else
        Logger.error("Failed to get DB connection from options")
      end
    # Prepare a select statement
    {:ok, statement} = Exqlite.Sqlite3.prepare(db_conn, "SELECT id FROM lei WHERE repo LIKE '#{repo}'")

    # Get the results
    case Exqlite.Sqlite3.step(db_conn, statement) do
      :done -> false
      _ -> true
    end
  end

  def write_to_db(report, options) do
    if Application.fetch_env!(:lowendinsight, :persist) do
      db_conn =
        if Map.has_key?(options, :db_conn) do
          Map.get(options, :db_conn)
        else
          Logger.error("Failed to get DB connection from options")
        end

      {:ok, statement} =
        Exqlite.Sqlite3.prepare(
          db_conn,
          "insert into lei (repo, risk, created_at, stuff) values (?1, ?2, ?3, ?4)"
        )

      Exqlite.Sqlite3.bind(db_conn, statement, [
        report.data.repo,
        report.data.risk,
        DateTime.utc_now() |> DateTime.to_iso8601(),
        Poison.encode!(report)
      ])

      # Step is used to run statements
      case Exqlite.Sqlite3.step(db_conn, statement) do
        :done -> Logger.info("Report written to DB")
        _ -> Logger.error("Error writing to DB")
      end
    end
  end
end
