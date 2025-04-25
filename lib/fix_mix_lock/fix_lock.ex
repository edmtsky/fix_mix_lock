defmodule Mix.Tasks.Fix.Lock do
  use Mix.Task
  alias FixMixLock.HexPmApi
  import FixMixLock.Utils

  @version Mix.Project.config()[:version]
  @switches [version: :boolean, help: :boolean]
  @aliases [v: :version, h: :help]

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

    Usage: mix fix.lock [options]

    Options:
      -h, --help       Show this help message
      -v, --version    Show the version of the task
    """
  end

  # -p, --package    Show versions and release datetime for a given package

  @impl true
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("mix.lock fixer v#{@version}")
  end

  def run([help]) when help in ~w(-h --help) do
    Mix.shell().info(help_and_usage())
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

    direct_deps_map = deps_list_to_map(direct_deps)

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

      # todo case: all deps specified in mix.exs and this tool say
      # "no transitive_deps" - this can be confused if the user has forgotten
      # that he defined all his dependencies in mix.exs
      # Since, according to the idea, you need to look for only versions of
      # those packages that are indicated in mix.lock, but which are not in mix.exs
      !is_list(transitive_deps) || length(transitive_deps) < 1 ->
        Mix.shell().error("No transitive dependencies found in mix.lock")
        Mix.shell().error("Or all your dependencies are already defined in mix.exs")

      true ->
        code_snippet =
          gen_transitive_deps_for_time_point(direct_deps, transitive_deps)
          |> fixed_deps_map_to_code_snippet()

        Mix.shell().info("\nCode snippet for mix.exs with exact versions:\n")
        Mix.shell().info(code_snippet)

        Mix.shell().info("""


        Next steps:

            1. copy generated code into the deps block in your mix.exs file
            2. mix deps.clean --all --unlock
            3. mix deps.get
            4. mix compile
        """)
    end
  end

  @doc """
  detect point of time for first direct dependency in the direct_deps list
  and fix
  """
  @spec gen_transitive_deps_for_time_point([Mix.Deps.t()], map()) :: map()
  defp gen_transitive_deps_for_time_point(direct_deps, transitive_deps) do
    [main_mix_dep] = Enum.take(direct_deps, 1)
    # [main_mix_dep, _rest] = direct_deps
    {mdep_name, mdep_ver} = get_exact_dep_version(main_mix_dep)

    Mix.shell().info("Determine point of time by #{mdep_name} #{mdep_ver} ...")
    # time_range = get_datetime_range(direct_deps)
    time_range = fetch_pkg_point_of_time(mdep_name, mdep_ver)
    %{min_time: t1, max_time: t2} = time_range

    Mix.shell().info("Point of time: #{fmt_date(t1)} - #{fmt_date(t2)}")

    Mix.shell().info("\nFetching release dates of transitive dependencies...")
    fixed_deps_map = build_fixed_transitive_deps(transitive_deps, time_range)

    # todo fix version for deps of direct_deps (like for ranch "1.8.0")

    fixed_deps_map
  end
end
