# How to fix issue when generating a new Phoenix-1.6 project in 2025

## Context

In order to study, you begin to study Phoenix framework on old materials, but
it is not possible to compile the project.

## The first thing to do

Set specific versions of direct dependencies, otherwise the most recent ones will be pulled by `mix`, which will break the compilation of the project:

```elixir
  defp deps do
  [
    {:phoenix, "1.6.2"}, # old: {:phoenix, "~> 1.6.2"},
    {:phoenix_ecto, "4.4.0"}, # old: {:phoenix_ecto, "~> 4.4"},
    # ...
  ]
  end
```

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
      # Pay attention to the fact that specific versions of packages are used:
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

Now, if you do not change transitve dependencies, the project will already be
able to compile, but will fall with an incoming request.

> terminal 1
```sh
cd hello_app
mix phx.server

[info] Running HelloAppWeb.Endpoint with cowboy 2.13.0 at 127.0.0.1:4000 (http)
[debug] Downloading esbuild from https://registry.npmjs.org/esbuild-linux-64/-/esbuild-linux-64-0.12.18.tgz
[info] Access HelloAppWeb.Endpoint at http://localhost:4000
[watch] build finished, watching for changes...
```

> terminal 2:
```sh
curl http://localhost:4000/
```


> unhandled exit at GET /

Exception:
```
** (exit) {:response_error, :invalid_header, :"Response cookies must be set using cowboy_req:set_resp_cookie/3,4."}
    (cowboy 2.13.0) ~/code/hello_app/deps/cowboy/src/cowboy_req.erl:828: :cowboy_req.reply/4
    (plug_cowboy 2.5.2) lib/plug/cowboy/conn.ex:35: Plug.Cowboy.Conn.send_resp/4
    (plug 1.17.0) lib/plug/conn.ex:448: Plug.Conn.send_resp/1
    (hello_app 0.1.0) lib/hello_app_web/controllers/page_controller.ex:1: HelloAppWeb.PageController.action/2
    (hello_app 0.1.0) lib/hello_app_web/controllers/page_controller.ex:1: HelloAppWeb.PageController.phoenix_controller_pipeline/2
    (phoenix 1.6.2) lib/phoenix/router.ex:355: Phoenix.Router.__call__/2
    (hello_app 0.1.0) lib/hello_app_web/endpoint.ex:1: HelloAppWeb.Endpoint.plug_builder_call/2
    (hello_app 0.1.0) lib/plug/debugger.ex:155: HelloAppWeb.Endpoint."call (overridable 3)"/2
    (hello_app 0.1.0) lib/hello_app_web/endpoint.ex:1: HelloAppWeb.Endpoint.call/2
    (phoenix 1.6.2) lib/phoenix/endpoint/cowboy2_handler.ex:43: Phoenix.Endpoint.Cowboy2Handler.init/4
    (cowboy 2.13.0) ~/code/hello_app/deps/cowboy/src/cowboy_handler.erl:37: :cowboy_handler.execute/2
    (cowboy 2.13.0) ~/code/hello_app/deps/cowboy/src/cowboy_stream_h.erl:310: :cowboy_stream_h.execute/3
    (cowboy 2.13.0) ~/code/hello_app/deps/cowboy/src/cowboy_stream_h.erl:299: :cowboy_stream_h.request_process/3
    (stdlib 3.17.2.4) proc_lib.erl:226: :proc_lib.init_p_do_apply/3
...
```

```elixir
{
  :response_error, :invalid_header,
  :"Response cookies must be set using cowboy_req:set_resp_cookie/3,4."
}
```
in terminal with mix phx.server
```
[error] Ranch listener HelloAppWeb.Endpoint.HTTP, connection process #PID<0.641.0>,
stream 1 had its request process #PID<0.642.0> exit with reason
{{{:response_error,
   :invalid_header,
   :"Response cookies must be set using cowboy_req:set_resp_cookie/3,4."},
  {HelloAppWeb.Endpoint,
   :call,
   [
     %Plug.Conn{
       adapter: {Plug.Cowboy.Conn,
        :...},
```

compilation warnings was shown before first start:
```
..
==> plug_cowboy
Compiling 5 files (.ex)
warning: function upgrade/3 required by behaviour Plug.Conn.Adapter is not implemented (in module Plug.Cowboy.Conn)
  lib/plug/cowboy/conn.ex:1: Plug.Cowboy.Conn (module)
...

==> phoenix_live_view
Compiling 31 files (.ex)
warning: Plug.Conn.Query.decode_pair/2 is deprecated. Use decode_init/0, decode_each/2, and decode_done/2 instead
Found at 4 locations:
  lib/phoenix_live_view/test/client_proxy.ex:1095: Phoenix.LiveViewTest.ClientProxy.form_defaults/3
...
```



### steps to fix:

From a directory with your Phoenix-1.6 project:
```sh
cd  path/to/your/phoenix_project

mix lock.fix

Determine point of time by phoenix 1.6.2 ...
Point of time: 2021/10/9 - 2021/12/8

Fetching release dates of transitive dependencies...
  - html_entities  (locked: 0.5.2)
  - connection  (locked: 1.1.0)
  - cowlib  (locked: 2.11.0)
  - decimal  (locked: 2.0.0)
  - ranch  (locked: 1.8.0)
  - db_connection  (locked: 2.4.2)
  - plug  (locked: 1.13.6)
  - castore  (locked: 0.1.17)
  - telemetry  (locked: 1.1.0)
  - mime  (locked: 2.0.2)
  - file_system  (locked: 0.2.10)
  - cowboy_telemetry  (locked: 0.4.0)
  - cowboy  (locked: 2.9.0)
  - phoenix_view  (locked: 1.1.2)
  - ecto  (locked: 3.7.2)
  - phoenix_pubsub  (locked: 2.1.1)
  - plug_crypto  (locked: 1.2.2)

Code snippet for mix.exs with exact versions:

      {:castore, "0.1.13"},
      {:connection, "1.1.0"},
      {:cowboy, "2.9.0"},
      {:cowboy_telemetry, "0.4.0"},
      {:cowlib, "2.11.0"},
      {:db_connection, "2.4.1"},
      {:decimal, "2.0.0"},
      {:ecto, "3.7.1"},
      {:file_system, "0.2.10"},
      {:html_entities, "0.5.2"},
      {:mime, "2.0.2"},
      {:phoenix_pubsub, "2.0.0"},
      {:phoenix_view, "1.0.0"},
      {:plug, "1.12.1"},
      {:plug_crypto, "1.2.2"},
      {:ranch, "1.8.0"},
      {:telemetry, "1.0.0"},


Next steps:

    1. copy generated code into the deps block in your mix.exs file
    2. mix deps.clean --all --unlock
    3. mix deps.get
    4. mix compile
```

copy and paste generated version of transitive dependencies:

mix.exs
```elixir
defmodule HelloApp.MixProject do
  use Mix.Project
  # ...

  defp deps do
    [
      # Pay attention to the fact that specific versions of packages are used:
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

      # transitive
      {:castore, "0.1.13"},
      {:connection, "1.1.0"},
      {:cowboy, "2.9.0"},
      {:cowboy_telemetry, "0.4.0"},
      {:cowlib, "2.11.0"},
      {:db_connection, "2.4.1"},
      {:decimal, "2.0.0"},
      {:ecto, "3.7.1"},
      {:file_system, "0.2.10"},
      {:html_entities, "0.5.2"},
      {:mime, "2.0.2"},
      {:phoenix_pubsub, "2.0.0"},
      {:phoenix_view, "1.0.0"},
      {:plug, "1.12.1"},
      {:plug_crypto, "1.2.2"},
      {:ranch, "1.8.0"},
      {:telemetry, "1.0.0"},
    ]
  end

  #...
end
```


```sh
mix deps.clean --all --unlock
mix deps.get
```
- 1. delete all downloaded dependencies and mix.lock file
- 2. pulls up dependencies again (this time using the correct versions)

done!


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
mix compile
```
- 1. delete all downloaded dependencies and mix.lock file
- 2. pulls up dependencies again (this time using the correct versions)


run the server
> terminal 1
```sh
mix phx.server
```

> terminal 2 (or in the browser)
```sh
curl http://127.0.0.1:4000
```
no errors!

