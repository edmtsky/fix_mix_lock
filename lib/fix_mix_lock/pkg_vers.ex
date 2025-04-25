defmodule Mix.Tasks.Pkg.Vers do
  use Mix.Task
  alias FixMixLock.HexPmApi

  @version Mix.Project.config()[:version]
  @switches [version: :boolean, help: :boolean]
  @aliases [v: :version, h: :help]

  @shortdoc "Show versions of the given package and the dates of releases"

  defp help_and_usage do
    """
    Show all available versions of the given package and the dates of releases

    Usage: mix pkg.vers <package_name>

    Options:
      -h, --help       Show this help message
      -v, --version    Show the version of the task
    """
  end

  @impl true
  def run([help]) when help in ~w(-h --help) do
    Mix.shell().info(help_and_usage())
  end

  def run([]), do: Mix.shell().info(help_and_usage())

  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("mix.lock fixer v#{@version}")
  end

  @doc """
  show all available versions of the given package with release datetime
  """
  def run([pkg]) do
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
end
