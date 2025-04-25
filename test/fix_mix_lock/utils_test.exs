# 25-04-2025 @author Edmtsky
defmodule FixMixLock.UtilsTest do
  use ExUnit.Case
  import FixMixLock.Utils

  test "process_min_max_datetime" do
    now = ~U[2025-04-24 06:35:25.077160Z]
    map = new_map_for_process_min_max_datetime(now)
    dt = ~U[2021-10-09 00:27:07.053995Z]
    name = :max
    updated_map = process_min_max_datetime(map, dt, name)

    assert updated_map == %{
             max_name: :max,
             max_time: ~U[2021-10-09 00:27:07.053995Z],
             min_name: nil,
             min_time: now
           }

    dt2 = ~U[2020-10-09 08:00:00.053995Z]
    name2 = :min
    updated_map2 = process_min_max_datetime(updated_map, dt2, name2)

    assert updated_map2 == %{
             max_name: :max,
             max_time: ~U[2021-10-09 00:27:07.053995Z],
             min_name: :min,
             min_time: ~U[2020-10-09 08:00:00.053995Z]
           }
  end

  test "parse_mix_lock_line" do
    line = """
      "cowboy": {:hex, :cowboy, "2.13.0", "09d770dd5f6a22cc60c071f432cd7cb87776164527f205c5a6b0f24ff6b38990", [:make, :rebar3], [{:cowlib, ">= 2.14.0 and < 3.0.0", [hex: :cowlib, repo: "hexpm", optional: false]}, {:ranch, ">= 1.8.0 and < 3.0.0", [hex: :ranch, repo: "hexpm", optional: false]}], "hexpm", "e724d3a70995025d654c1992c7b11dbfea95205c047d86ff9bf1cda92ddc5614"},
    """

    assert parse_mix_lock_line(line) == {"cowboy", "2.13.0"}

    line = """
      "cowboy": {:hex, :cowboy, "2.9.0", "865dd8b6607e14cf03282e10e934023a1bd8be6f6bacf921a7e2a96d800cd452", [:make, :rebar3], [{:cowlib, "2.11.0", [hex: :cowlib, repo: "hexpm", optional: false]}, {:ranch, "1.8.0", [hex: :ranch, repo: "hexpm", optional: false]}], "hexpm", "2c729f934b4e1aa149aff882f57c6372c15399a20d54f65c8d67bef583021bde"},
    """

    assert parse_mix_lock_line(line) == {"cowboy", "2.9.0"}
  end

  test "parse_mix_lock_file" do
    assert parse_mix_lock_file("test/samples/phx_1_6_2/mix.lock") == %{
             plug: "1.17.0",
             html_entities: "0.5.2",
             mime: "2.0.6",
             esbuild: "0.4.0",
             phoenix_live_view: "0.17.10",
             jason: "1.3.0",
             gettext: "0.19.1",
             ranch: "2.2.0",
             swoosh: "1.7.1",
             decimal: "2.3.0",
             telemetry_poller: "1.0.0",
             ecto: "3.7.2",
             telemetry: "1.3.0",
             floki: "0.32.1",
             phoenix_live_reload: "1.3.3",
             plug_cowboy: "2.5.2",
             phoenix: "1.6.2",
             telemetry_metrics: "0.6.1",
             cowlib: "2.15.0",
             phoenix_html: "3.2.0",
             postgrex: "0.15.13",
             phoenix_live_dashboard: "0.6.5",
             plug_crypto: "1.2.5",
             castore: "1.0.12",
             ecto_sql: "3.7.1",
             connection: "1.1.0",
             cowboy: "2.13.0",
             db_connection: "2.7.0",
             file_system: "0.2.10",
             phoenix_pubsub: "2.1.3",
             phoenix_ecto: "4.4.0",
             phoenix_view: "1.1.2",
             cowboy_telemetry: "0.4.0"
           }
  end

  test "select_correct_version" do
    min_time = ~U[2021-07-03 20:47:06.488206Z]
    max_time = ~U[2022-05-31 07:39:56.141016Z]

    releases = [
      {"2.0.6", ~U[2024-07-04 10:29:53.986455Z]},
      {"2.0.5", ~U[2023-06-01 07:26:55.691068Z]},
      {"2.0.4", ~U[2023-05-31 14:23:59.206950Z]},
      {"2.0.3", ~U[2022-08-04 16:22:31.386898Z]},
      {"2.0.2", ~U[2021-10-22 12:42:42.938613Z]},
      {"2.0.1", ~U[2021-08-15 06:59:42.471906Z]},
      {"2.0.0", ~U[2021-08-14 07:40:09.768205Z]},
      {"1.6.0", ~U[2021-03-31 12:25:34.629016Z]},
      {"1.5.0", ~U[2020-11-24 08:02:24.053553Z]},
      {"1.4.0", ~U[2020-08-17 17:20:31.189063Z]},
      {"1.3.1", ~U[2018-11-24 21:57:12.538123Z]},
      {"1.3.0", ~U[2018-05-28 14:00:36.715697Z]},
      {"1.2.0", ~U[2017-12-24 22:11:45.593824Z]},
      {"1.1.0", ~U[2017-02-16 10:53:44.584928Z]},
      {"1.0.1", ~U[2016-08-09 15:31:23.444186Z]},
      {"1.0.0", ~U[2016-05-03 17:54:11.474967Z]},
      {"0.0.1", ~U[2015-10-26 10:42:12.216908Z]}
    ]

    assert select_correct_version(releases, min_time, max_time) == "2.0.2"
  end

  # @tag slow
  test "build_fixed_transitive_deps" do
    # hardcoded values for fast debuggin
    time_range = %{
      max_name: :swoosh,
      max_time: ~U[2022-05-31 07:39:56.141016Z],
      min_name: :telemetry_metrics,
      min_time: ~U[2021-07-03 20:47:06.488206Z]
    }

    deps = %{mime: "2.0.6"}
    assert build_fixed_transitive_deps(deps, time_range) == %{mime: "2.0.2"}
  end

  test "parse_version" do
    assert parse_version("1.2.3") == {1, 2, 3}
    assert parse_version("3.0.0-rc.1") == {3, 0, 0}
    assert parse_version("0.0.1") == {0, 0, 1}
    assert parse_version("0.1") == :error
  end

  test "compare_versions" do
    assert compare_versions("0.0.0", "0.0.0") == :eq
    assert compare_versions("0.1.0", "0.1.0") == :eq
    assert compare_versions("1.0.0", "1.0.0") == :eq
    assert compare_versions("1.2.3", "1.2.3") == :eq
    # ignore suffix
    assert compare_versions("1.2.3", "1.2.3-rc.1") == :eq

    assert compare_versions("0.0.1", "0.0.0") == :gt
    assert compare_versions("0.1.0", "0.0.0") == :gt
    assert compare_versions("1.0.0", "0.0.0") == :gt

    assert compare_versions("0.0.2", "0.0.1") == :gt
    assert compare_versions("0.1.0", "0.0.2") == :gt
    assert compare_versions("1.0.0", "0.9.0") == :gt

    assert compare_versions("0.0.0", "0.0.1") == :lt
    assert compare_versions("0.0.9", "0.1.0") == :lt
    assert compare_versions("0.9.9", "1.0.0") == :lt
    assert compare_versions("1.8.9", "1.9.0") == :lt
    assert compare_versions("8.8.9", "8.9.6") == :lt

    assert compare_versions("bad", "8.9.6") == :error
    assert compare_versions("0.0.0", "bad") == :error
    assert compare_versions("abc", "abc") == :error
  end

  test "deps_list_to_map" do
    deps_list = [
      %Mix.Dep{
        app: :file_system,
        deps: [],
        extra: [],
        manager: :mix,
        opts: [
          lock: {:hex, :file_system, "0.2.10", "fb08200", [:mix], [], "hexpm", "41195ed"},
          only: :dev,
          env: :prod,
          hex: "file_system",
          repo: "hexpm",
          optional: false
        ],
        requirement: "~> 0.2.1 or ~> 0.3",
        scm: Hex.SCM,
        status: {:ok, "0.2.10"}
      },
      %Mix.Dep{
        app: :connection,
        deps: [],
        extra: [],
        manager: :mix,
        opts: [
          lock: {:hex, :connection, "1.1.0", "ff2a49", [:mix], [], "hexpm", "722c1e"},
          env: :prod,
          hex: "connection",
          repo: "hexpm",
          optional: false
        ],
        requirement: "~> 1.0",
        scm: Hex.SCM,
        status: {:ok, "1.1.0"}
      }
    ]

    assert deps_list_to_map(deps_list) == %{
             file_system: "0.2.10",
             connection: "1.1.0"
           }
  end
end
