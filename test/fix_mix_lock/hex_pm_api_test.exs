defmodule FixMixLock.HexPmApiTest do
  use ExUnit.Case
  import FixMixLock.HexPmApi

  describe "parse api response" do
    test "convert datetime" do
      datetime = "2021-10-09T00:27:07.053995Z"
      assert DateTime.from_iso8601(datetime) == {:ok, ~U[2021-10-09 00:27:07.053995Z], 0}
    end

    test "parse json" do
      json_phoenix_1_6_2 = """
      {"inserted_at":"2021-10-09T00:26:57.400252Z","updated_at":"2021-10-09T00:27:07.053995Z","retirement":null}
      """

      assert parse_pkg_release_version(json_phoenix_1_6_2) == %{
               updated_at: ~U[2021-10-09 00:27:07.053995Z]
             }
    end

    test "parse_release_sub_json" do
      json =
        "{\"version\":\"2.0.5\",\"url\":\"https://hex.pm/api/packages/mime/releases/2.0.5\",\"has_docs\":true,\"inserted_at\":\"2023-06-01T07:26:55.691068Z\""

      assert parse_release_sub_json(json) ==
               {:ok, {"2.0.5", ~U[2023-06-01 07:26:55.691068Z]}}
    end

    test "parse_pkg_releases" do
      json = File.read!("test/samples/phx_1_6_2/hex_pm_api_packages/mime.json")

      assert parse_pkg_releases(json) == [
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

    # test "fetch_pkg_info" do
    #   time_range = %{ # hardcoded values for fast debuggin
    #     max_name: :swoosh,
    #     max_time: ~U[2022-05-31 07:39:56.141016Z],
    #     min_name: :telemetry_metrics,
    #     min_time: ~U[2021-07-03 20:47:06.488206Z]
    #   }
    #   info = fetch_pkg_info(:plug)
    #   assert info = 1
    # end
  end
end
