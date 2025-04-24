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

For example, this can be useful when you want to study an old tutorial by
manually repeating the code from it, and you need to generate a new project
with a larger number of dependencies. But resolving transitive dependencies
breaks, and you can't compile the project because it pulls in too recent
versions of dependencies, whereas you actually need to use the versions that
were present at the time when the tutorial was written.

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

### step 1

setup exact versions in mix.exs (by removing the `~>` prefix) like:

mix.exs
```elixir
defmodule HelloApp.MixProject do
  use Mix.Project
  # ..

  defp deps do
    [
      {:phoenix, "1.6.2"},
      {:phoenix_ecto, "4.4.0"},
      # ...
      {:plug_cowboy, "2.5.2"},
    ]
  end

  #...
end
```


### step 2

Generate the code-snippet for deps-block

```sh
cd  path/to/your/phoenix_project
mix fix.lock

Fetching release dates of used direct dependencies...
  - phoenix  1.6.2
  - phoenix_ecto  4.4.0
  ...
  - plug_cowboy  2.5.2

Fetching releases of the transitive dependencies...
  - cowlib  (locked: 2.15.0)
  - cowboy  (locked: 2.13.0)
  - plug  (locked: 1.17.0)
  ...
  - ranch  (locked: 2.2.0)
  - db_connection  (locked: 2.7.0)

Code snippet for mix.exs with exact versions:

      {:cowboy, "2.9.0"},
      {:ecto, "3.7.2"},
      ...
      {:plug, "1.13.6"},
      {:ranch, "2.1.0"},


Next steps:

    1. copy-and-past generated code snippet into the deps block in your mix.exs
    2. mix deps.clean --all --unlock
    3. mix deps.get
    4. mix compile
```

### Detailed examples of the issues that can be fixed using this tool

- [issue with new Phoenix 1.6 project](./doc/phoenix-1_6_issue.md)


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


## TODOList:

- [+] ability to show all available versions and release date of a given package
- [+] description of steps how to fully update the dependencies after the fix
- [-] speed up the work with hex.pm API by sending http-request in parallel
- [-] build lis of required transitive deps based on direct deps without mix.lock
- [-] support version range, not only exact version like `{:phoenix, "1.6.16"}`
- [-] a more smart choice of the version of transitive dependence on with the
      support of these restrictions by minor, and patch number in version of pkg
- [-] convert direct dependencies in mix.exs to exact version (remove `~>` prefix)
- [-] a command to search for specific versions for a given packages by a given date
