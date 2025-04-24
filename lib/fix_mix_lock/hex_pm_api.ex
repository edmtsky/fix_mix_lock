defmodule FixMixLock.HexPmApi do
  @moduledoc """
  parse json from response of the hex.pm API
  """
  alias FixMixLock.HttpClient
  @type release_entry :: {String.t(), DateTime.t()}

  @doc """
  send request to hex.pm to get info about specified package+version
  https://hex.pm/api/packages/<pkg>/releases/<version>
  """
  @spec fetch_pkg_release_version(String.t(), String.t()) :: map()
  def fetch_pkg_release_version(dep_name, version) do
    url = "http://hex.pm/api/packages/#{dep_name}/releases/#{version}"
    # IO.puts("[DEBUG] #{url}")

    case HttpClient.get(url) do
      {:ok, json} ->
        pkg_info = parse_pkg_release_version(json)
        {:ok, pkg_info}

      v ->
        IO.inspect(v)
        :error
    end
  end

  @doc """
  send request to hex.pm to get info about specified package (all versions)
  https://hex.pm/api/packages/<pkg>
  """
  @spec fetch_pkg_releases(String.t()) :: map()
  def fetch_pkg_releases(dep_name) do
    url = "http://hex.pm/api/packages/#{dep_name}"
    # IO.puts("[DEBUG] #{url}")

    case HttpClient.get(url) do
      {:ok, json} ->
        # Map
        releases = parse_pkg_releases(json)
        {:ok, releases}

      v ->
        IO.inspect(v)
        :error
    end
  end

  @doc """
  parse json response for a given package-version from
  https://hex.pm/api/packages/<pkg>/releases/<version>

  example:
  https://hex.pm/api/packages/phoenix/releases/1.6.2
  """
  @spec parse_pkg_release_version(binary()) :: map()
  def parse_pkg_release_version(json) do
    updated_at =
      case Regex.run(~r/"updated_at":"([^"]+)"/, json) do
        [_, datetime] ->
          {:ok, datetime, _offset} = DateTime.from_iso8601(datetime)
          datetime

        _ ->
          nil
      end

    %{updated_at: updated_at}
  end

  @doc """
  helper for parse_pkg_releases. to parse sub json with one specific version+date
  """
  @spec parse_release_sub_json(String.t()) :: {:ok, release_entry()} | :error
  def parse_release_sub_json(json) do
    case Regex.run(~r/"version":"([^"]+).+"inserted_at":"([^"]+)"/, json) do
      [_, version, datetime_str] ->
        {:ok, datetime, _offset} = DateTime.from_iso8601(datetime_str)
        {:ok, {version, datetime}}

      _ ->
        :error
    end
  end

  @doc """
  json response from the https://hex.pm/api/packages/<pkg>
  """
  @spec parse_pkg_releases(json :: String.t()) :: [release_entry()]
  def parse_pkg_releases(json) do
    case Regex.run(~r/"releases":\[([^\]]+)\]/, json) do
      [_, releases] ->
        releases
        |> String.split("},")
        |> Enum.reduce([], fn release_sub_json, acc ->
          case parse_release_sub_json(release_sub_json) do
            {:ok, entry} ->
              [entry | acc]

            _ ->
              acc
          end
        end)
        |> Enum.reverse()

      _ ->
        nil
    end
  end

  # major.minor.patch
  def parse_version(v) do
    case Regex.run(~r/(\d+)\.(\d+)\.(\d+)/, v) do
      [_, major, minor, patch] ->
        {String.to_integer(major), String.to_integer(minor), String.to_integer(patch)}

      _ ->
        :error
    end
  end

  def compare_versions(v1, v2) when is_binary(v1) and is_binary(v2) do
    a = parse_version(v1)
    b = parse_version(v2)

    case {a, b} do
      {{ma1, mi1, p1}, {ma2, mi2, p2}} ->
        cond do
          ma1 == ma2 && mi1 == mi2 && p1 == p2 ->
            :eq

          ma1 > ma2 || (ma1 == ma2 && (mi1 > mi2 || (mi1 == mi2 && p1 > p2))) ->
            :gt

          true ->
            :lt
        end

      _ ->
        :error
    end
  end

  def compare_versions(_, _) do
    :error
  end
end
