defmodule Mix.Tasks.Deps.Used do
  @shortdoc "Show the date of releases of versions of the packeges used"

  use Mix.Task
  alias FixMixLock.Utils

  @version Mix.Project.config()[:version]
  @switches [version: :boolean, help: :boolean]
  @aliases [v: :version, h: :help]

  defp help_and_usage do
    """
    Show the point of time during which the dependencies used were relevant
    (from the moment of their release to the appearance of the next newer version)

    Usage: mix deps.used [Options]

    Options:
      -h, --help       Show this help message
      -v, --version    Show the version of the task
      -a, --all        all dependencies(with transitive)  (not implemented yet)
    """
  end

  @impl true
  def run([help]) when help in ~w(-h --help) do
    Mix.shell().info(help_and_usage())
  end

  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("mix.lock fixer v#{@version}")
  end

  @doc """
  show all available versions of the given package with release datetime
  """
  def run([]) do
    Mix.Project.get!()
    direct_deps = Mix.Dep.Loader.children()

    deps = direct_deps
    # todo --all flag to add transitive deps

    {min_time, max_time} =
      deps
      |> Utils.deps_list_to_map()
      |> fetch_release_dates_of_pkg_version_map()

    # total min-max
    pad = String.pad_trailing("", 45)

    "\n#{pad} #{Utils.fmt_date(min_time)} - #{Utils.fmt_date(max_time)}"
    |> Mix.shell().info()
  end

  # process given map of pkg_name=>version to fetch a point of time for this
  # particular version. returns total min-max of all given packages
  # point-of-time is a min and max DateTime - this is a period of time from
  # the moment the given version is released until the next version appears
  @spec fetch_release_dates_of_pkg_version_map(map()) :: {DateTime.t(), DateTime.t()}
  defp fetch_release_dates_of_pkg_version_map(map) do
    Enum.reduce(map, {nil, nil}, fn {pkgn, version}, {acc_min, acc_max} = acc ->
      p = String.pad_trailing(to_string(pkgn), 32)
      v = String.pad_trailing(version, 10)

      case Utils.fetch_pkg_point_of_time(pkgn, version) do
        %{min_time: min, max_time: max} ->
          "#{p}  #{v}  #{Utils.fmt_date(min)} - #{Utils.fmt_date(max)}"
          |> Mix.shell().info()

          acc_min =
            cond do
              acc_min == nil -> min
              DateTime.compare(min, acc_min) == :lt -> min
              true -> acc_min
            end

          acc_max =
            cond do
              acc_max == nil -> max
              DateTime.compare(max, acc_max) == :gt -> max
              true -> acc_max
            end

          {acc_min, acc_max}

        _ ->
          Mix.shell().info("#{p}  #{v}  ?")
          acc
      end
    end)
  end
end
