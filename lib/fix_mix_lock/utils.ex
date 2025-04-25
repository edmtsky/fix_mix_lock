defmodule FixMixLock.Utils do
  @moduledoc """
  Helper functions for working with Mix.Deps, packages and its versions
  """
  alias FixMixLock.HexPmApi

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

  @doc """
  map of (atom)depname => (string)version
  """
  @spec readable_fixed_deps(map()) :: String.t()
  def readable_fixed_deps(deps) do
    deps
    |> Enum.map(fn {name, version} ->
      # todo only: test if parent has only test (e.g. for floki)
      "      {:#{name}, \"#{version}\"},"
    end)
    |> Enum.join("\n")
  end

  @doc """
  create map with correct versions for a given deps.
  through sending requests to http://hex.pm and pulling out versions of packages
  of the releases of which were posted no earlier than the specified max date
  in time_range.
  In other words, it corrects the versions of the packages so that they
  correspond to a given historical moment of time (by time_range.max_time)
  """
  @spec build_fixed_transitive_deps(map(), map()) :: map()
  def build_fixed_transitive_deps(deps, time_range) do
    Enum.reduce(deps, %{}, fn {name, old_version}, acc ->
      Mix.shell().info("  - #{name}  (locked: #{old_version})")
      %{min_time: min_time, max_time: max_time} = time_range

      case HexPmApi.fetch_pkg_releases(name) do
        {:ok, releases} ->
          case select_correct_version(releases, min_time, max_time) do
            nil ->
              IO.puts("[WARNING] Cannot get correct version for #{name}")
              acc

            version ->
              correct_version =
                case compare_versions(old_version, version) do
                  :lt -> old_version
                  _ -> version
                end

              # IO.puts("[DEBUG] '#{name}' correct version: #{version}")
              Map.put(acc, name, correct_version)
          end

        _ ->
          IO.puts("[WARNING] Cannot fetch releases for #{name}")
          acc
      end
    end)
  end

  @doc """
  select correct version from given releases (list of {version, datetime)
  which less than a given max_time
  """
  @spec select_correct_version([{atom(), DateTime.t()}], integer(), integer()) :: map()
  def select_correct_version(releases, _min_time, max_time) do
    # IO.puts("[DEBUG] min: #{min_time} max: #{max_time}")

    releases
    |> Enum.find_value(fn {version, datetime} ->
      if DateTime.compare(datetime, max_time) == :lt do
        version
      end
    end)
  end

  @doc """
  Determine the datetime range(min/max) datetime used in the specified deps.
  it use access via network to the http://hex.pm API

  In other words, this function is needed to determine the historical time point
  to adjust transitive dependencies, so that the versions are used about the
  same time as in the direct dependencies(defined in mix.exs file)
  {pkg_name, datetime}

  Reasoning: it is possible to go through all the dependencies from mix.exs
  and release the interval of the moment of time, but simply take the first
  package defined as dependency and take its release date.
  Why does this make sense - for example, in the project based on the Phoenix
  framework, the main thing on which other package depends this package of
  the phoenix framework itself
  """
  @spec get_datetime_range([Map.Dep.t()]) :: map()
  def get_datetime_range(deps) do
    deps
    |> Enum.reduce(new_map_for_process_min_max_datetime(), fn dep, acc ->
      case dep do
        %Mix.Dep{app: dep_name, requirement: requirement, scm: _scm} ->
          Mix.shell().info("  - #{dep_name}  #{requirement}")
          # todo remove `~>` if has
          version = requirement

          case HexPmApi.fetch_pkg_release_version(dep_name, version) do
            {:ok, pkg_info} ->
              %{updated_at: updated_at} = pkg_info
              # IO.inspect(updated_at)
              process_min_max_datetime(acc, updated_at, dep_name)

            _ ->
              acc
          end

        _ ->
          acc
      end
    end)
  end

  def new_map_for_process_min_max_datetime(now \\ DateTime.now!("Etc/UTC")) do
    %{
      max_name: nil,
      max_time: ~U[1970-01-01 00:00:00.0Z],
      min_name: nil,
      min_time: now
    }
  end

  @spec process_min_max_datetime(map, DateTime.t(), atom()) :: map()
  def process_min_max_datetime(map, dt, dep_name) do
    %{max_time: max_time, min_time: min_time} = map

    case DateTime.compare(dt, max_time) do
      :gt ->
        map
        |> Map.put(:max_name, dep_name)
        |> Map.put(:max_time, dt)

      _ ->
        case DateTime.compare(dt, min_time) do
          :lt ->
            map
            |> Map.put(:min_name, dep_name)
            |> Map.put(:min_time, dt)

          _ ->
            map
        end
    end
  end

  def parse_mix_lock_line(line) do
    case Regex.run(~r/\s+"[^"]+":\s+{:hex,\s+:([^"]+),\s+"([^"]+)",/, line) do
      # case Regex.run(~r/,\s+"(\d+\.\d+\.\d+)",/, line) do
      [_, name, version] ->
        # IO.puts("[DEBUG] #{name}  #{version}")
        {name, version}

      _ ->
        :error
    end
  end

  @doc """
  parse the content of given mix.lock into Map
  """
  @spec parse_mix_lock_file(String.t()) :: map()
  def parse_mix_lock_file(path) do
    initial_state = %{}

    case File.read(path) do
      {:ok, binary} ->
        binary
        |> String.split("\n")
        |> Enum.reduce(initial_state, fn line, acc ->
          case parse_mix_lock_line(line) do
            {dep_name, version} ->
              key = String.to_atom(dep_name)
              Map.put(acc, key, version)

            :error ->
              acc
          end
        end)

      err ->
        err
    end
  end
end
