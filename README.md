# FixMixLock

This is a command line tool(mix-task) to address the problem of fetching a newer
version of a transitive dependency that causes compatibility issues.

When you need to manage your Elixir project with specific old versions of
dependencies while also ensuring compatibility with a specific point in time -
for a specific historical versions.

It is designed to provide the ability to correct the work of a new generated
project, which generates a broken `mix.lock` file. For example when you need
to start a new project with old dependencies, but the project is not compile
and falls with errors.

For example, this can be useful when you want to study some old tutorial,
repeating the code from it yourself, and you need to generate a new project with
a large number of dependencies. But resolving transitive dependencies breaks and
the project cannot be compiled because too new versions of dependencies are
pulled in, while you just need to use the versions for the period of time when
this tutorial was written.

Usecase: you would like to go through the Phoenix 1.6 tutorial, and there are
even specific versions of the main dependencies, but after `mix dps.get`,
too new transitive dependencies are found in `mix.lock` and the project simply
does not work, and falling with errors.

This tool can helps you to fix this kind of problem and automatically select the
correct versions of transitive dependencies at a specific historical point in
time. And this point in time is also determined automatically on the basis of
specific versions of the packages defined in your `mix.exs` file


## Features

- Get a historical point in time for defined direct dependencies (via mix.exs)
- Get specific numbers of correct versions for a specific historical period of
  time. That is, the latest dependencies, but for some moment in the past.
  (to fix the issue with broken versions of transitive dependencies)
- get a list of all available versions and date of their releases for a
  particular package.


## Limitation

- 1. At the moment, the correct versions of transitive dependencies can only be
  built based on the contents of the `mix.lock` file.
  That is, the ability to build a list of all transitive dependencies by based
  only on direct dependencies has not yet been implemented.



## How Its works:

- This functionality is implemented as a Task for [Mix](https://hexdocs.pm/elixir/introduction-to-mix.html)
- Its reads your `mix.exs` file in the current directory and based on the
  specified versions of the direct dependencies, it takes the maximum date of
  used packages.
- Then this task reads the contents of the `mix.lock` file and takes from it
  only transitive dependencies that were not indicated in your `mix.exs` file.
- And then it turns to the site http://hex.pm in order to get all possible
  versions and dates of their releases for all transitive dependencies and
  selects only those versions of which the release date is not newer than
  the latest of the dependencies defined in `mix.exs`.


## Installation

For installation, you can clone the repository and install this project as
Mix Task after which it will be available through the `mix fix.lock` in your
terminal:

```sh
git clone --depth 1 https://github.com/edmtsky/fix_mix_lock
cd fix_mix_lock

MIX_ENV=prod mix archive.build
mix archive.install ./fix_mix_lock-*.ez


mix fix.lock --version
# => mix.lock fixer v0.1.0
```

Note:
If you use `asdf` and often switch versions of elixir, then pay attention to
the fact that the mix-archives in asdf are installed on a specific version of
the elixir, so if you need to have access to this command you need to install
this archive on different versions of the elixir in your environment.


## Usage example

example for old phoenix 1.6 project with exact numbers of dependencies known
only for direct dependencies:

mix.exs
```elixir
defmodule HelloApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :hello_app,
      version: "0.1.0",
      # ...
    ]
  end

  def application do
    # ...
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "1.6.2"},
      {:phoenix_ecto, "4.4.0"},
      {:ecto_sql, "3.7.1"},
      {:postgrex, "0.15.13"},
      {:phoenix_html, "3.2.0"},
      {:phoenix_live_reload, "1.3.3", only: :dev},
      {:phoenix_live_view, "0.17.10"},
      {:floki, "0.32.1", only: :test},
      {:phoenix_live_dashboard, "0.6.5"},
      {:esbuild, "0.4.0", runtime: Mix.env() == :dev},
      {:swoosh, "1.7.1"},
      {:telemetry_metrics, "0.6.1"},
      {:telemetry_poller, "1.0.0"},
      {:gettext, "0.19.1"},
      {:jason, "1.3.0"},
      {:plug_cowboy, "2.5.2"},
      #
    ]
  end

  #...
end
```

```sh
cd  path/to/your/phoenix_project
mix fix.lock

Fetching release dates of used direct dependencies...
  - phoenix  1.6.2
  - phoenix_ecto  4.4.0
  - ecto_sql  3.7.1
  - postgrex  0.15.13
  - phoenix_html  3.2.0
  - phoenix_live_reload  1.3.3
  - phoenix_live_view  0.17.10
  - floki  0.32.1
  - phoenix_live_dashboard  0.6.5
  - esbuild  0.4.0
  - swoosh  1.7.1
  - telemetry_metrics  0.6.1
  - telemetry_poller  1.0.0
  - gettext  0.19.1
  - jason  1.3.0
  - plug_cowboy  2.5.2

Fetching releases of the transitive dependencies...
  - cowlib  (locked: 2.15.0)
  - phoenix_view  (locked: 1.1.2)
  - telemetry  (locked: 1.3.0)
  - cowboy  (locked: 2.13.0)
  - connection  (locked: 1.1.0)
  - plug  (locked: 1.17.0)
  - castore  (locked: 1.0.12)
  - file_system  (locked: 0.2.10)
  - plug_crypto  (locked: 1.2.5)
  - mime  (locked: 2.0.6)
  - html_entities  (locked: 0.5.2)
  - cowboy_telemetry  (locked: 0.4.0)
  - ecto  (locked: 3.7.2)
  - phoenix_pubsub  (locked: 2.1.3)
  - decimal  (locked: 2.3.0)
  - ranch  (locked: 2.2.0)
  - db_connection  (locked: 2.7.0)

Code snippet for mix.exs with exact versions:

      {:castore, "0.1.17"},
      {:connection, "1.1.0"},
      {:cowboy, "2.9.0"},
      {:cowboy_telemetry, "0.4.0"},
      {:cowlib, "2.11.0"},
      {:db_connection, "2.4.2"},
      {:decimal, "2.0.0"},
      {:ecto, "3.7.2"},
      {:file_system, "0.2.10"},
      {:html_entities, "0.5.2"},
      {:mime, "2.0.2"},
      {:phoenix_pubsub, "2.1.1"},
      {:phoenix_view, "1.1.2"},
      {:plug, "1.13.6"},
      {:plug_crypto, "1.2.2"},
      {:ranch, "2.1.0"},
      {:telemetry, "1.1.0"},
```
then just copy-and-paste generated code into `deps` in your `mix.exs` file.

Note:
In this particular example, you will need to fix the version for the `:ranch`
package itself. The specific version will tell the mix himself when trying to
`mix deps.get`:

```
Because your app depends on cowboy 2.9.0 which depends on ranch 1.8.0,
ranch 1.8.0 is required.
So, because your app depends on ranch 2.1.0, version solving failed.
```

After you add these generated versions to your mix.exs, you will need to call
these commands:

```sh
mix deps.clean --all --unlock
mix deps.get
```
- 1. delete all downloaded dependencies and mix.lock file
- 2. pulls up dependencies again (this time using the correct versions)

done!


#### Another usefull commands

```sh
mix fix.lock --help
```

get all available versions for a given package
```sh
mix fix.lock --package plug
```
output:
```
Fetching releases of the 'plug' package...
1.17.0    2025-03-14 16:16:30.798813Z
1.16.2    2025-03-14 15:43:07.561881Z
...
1.13.6    2022-04-14 09:08:16.297297Z
...
0.4.1    2014-04-23 18:58:54.000000Z
```


### An example of a mistake that can be eliminated using this utility

- todo


## TODOList:

- [+] ability to show all available versions and release date of a given package
- [-] speed up the work with hex.pm API by sending http-request in parallel
- [-] build lis of required transitive deps based on direct deps without mix.lock
- [-] support version range, not only exact version like `{:phoenix, "1.6.16"}`
- [-] a more smart choice of the version of transitive dependence on with the
      support of these restrictions by minor, and patch number in version of pkg


