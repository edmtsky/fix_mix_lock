defmodule Mix.Tasks.Fix.Lock do
  use Mix.Task
  alias FixMixLock.HexPmApi

  @version Mix.Project.config()[:version]
  @switches [version: :boolean, help: :boolean, releases: :string]
  @aliases [v: :version, h: :help, r: :releases]

  @shortdoc "Fix a mix.lock file based on max datetime from used deps in mix.exs"

  defp help_and_usage do
    """
    The task intended for correct broken transitive dependencies due to
    automatic pull-ups of too new versions of packages.

    How its works:
      - Reads your mix.exs file and based on specific versions of direct
        dependencies, it receives the maximum datetime of used packages.
      - Then reads the mix.lock file and for all the transitive dependencies
        defined in this file, it searches for the version no newer(more) than
        the maximum datetime from the mix.exs file.

    Usage: mix my_cli_tool [options]

    Options:
      -h, --help       Show this help message
      -v, --version    Show the version of the task
      -p, --package    Show versions and release datetime for a given package
    """
  end

  @impl true
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("mix.lock fixer v#{@version}")
  end

  def run([help]) when help in ~w(-h --help) do
    Mix.shell().info(help_and_usage())
  end

  @doc """
  show all available versions with release datetime of the given package
  """
  def run([releases, pkg]) when releases in ~w(-p --package) do
    pkg_name = String.to_atom(pkg)
    Mix.shell().info("Fetching releases of the '#{pkg}' package...")

    case HexPmApi.fetch_pkg_releases(pkg_name) do
      {:ok, releases} ->
        releases
        |> Enum.each(fn {version, datetime} ->
          Mix.shell().info("#{version}        #{datetime}")
        end)

      err ->
        IO.inspect(err)
    end
  end

  def run(args) do
    {_opts, _args} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)
    do_fix_mix_file()
    # IO.inspect(opts)
    # IO.inspect(args)
  end

  defp do_fix_mix_file() do
    Mix.Project.get!()
    # list of %Mix.Dep{}
    direct_deps = Mix.Dep.Loader.children()

    direct_deps_map =
      direct_deps
      |> Enum.reduce(%{}, fn %Mix.Dep{app: name, requirement: version}, acc ->
        Map.put(acc, name, version)
      end)

    transitive_deps =
      case parse_mix_lock_file("mix.lock") do
        {:error, err} ->
          Mix.shell().error("Cannot read mix.lock #{inspect(err)}")

        all_locked_deps ->
          all_locked_deps
          |> Enum.filter(fn {name, _version} ->
            !Map.has_key?(direct_deps_map, name)
          end)
      end

    cond do
      !is_list(direct_deps) || length(direct_deps) < 1 ->
        Mix.shell().error("No dependencies found in mix.exs")

      !is_list(transitive_deps) || length(transitive_deps) < 1 ->
        Mix.shell().error("No transitive dependencies found in mix.lock")

      true ->
        Mix.shell().info("\nFetching release dates of direct dependencies...")
        time_range = get_datetime_range(direct_deps)

        Mix.shell().info("\nFetching release dates of transitive dependencies...")

        code_snippet =
          build_fixed_transitive_deps(transitive_deps, time_range)
          |> readable_fixed_deps()

        Mix.shell().info("\nCode snippet for mix.exs with exact versions:\n")
        Mix.shell().info(code_snippet)
    end
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
  in time_range
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
                case HexPmApi.compare_versions(old_version, version) do
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

  # determine the datetime range(min/max) datetime used in the specified deps
  # using access to http://hex.pm
  # {name, time}
  @spec get_datetime_range([Map.Dep.t()]) :: map()
  defp get_datetime_range(deps) do
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
