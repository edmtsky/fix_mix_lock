defmodule FixMixLock.HttpClient do
  @moduledoc """
  forked from Mix.Utils (elixir 1.12.2)
  """

  @doc """
  send http GET request to given url
  """
  def get(path) do
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:inets)

    # Starting an HTTP client profile allows us to scope
    # the effects of using an HTTP proxy to this function
    {:ok, _pid} = :inets.start(:httpc, profile: :mix)

    headers = [{'user-agent', 'Mix/#{System.version()}'}]
    request = {:binary.bin_to_list(path), headers}

    # We are using relaxed: true because some servers is returning a Location
    # header with relative paths, which does not follow the spec. This would
    # cause the request to fail with {:error, :no_scheme} unless :relaxed
    # is given.
    #
    # If a proxy environment variable was supplied add a proxy to httpc.
    # ++ proxy_config(path)
    http_options = [relaxed: true]

    # Silence the warning from OTP as we verify the contents
    level = Logger.level()
    Logger.configure(level: :error)

    try do
      case httpc_request(request, http_options) do
        {:error, {:failed_connect, [{:to_address, _}, {inet, _, reason}]}}
        when inet in [:inet, :inet6] and reason in [:ehostunreach, :enetunreach] ->
          :httpc.set_options([ipfamily: fallback(inet)], :mix)
          request |> httpc_request(http_options) |> httpc_response()

        response ->
          httpc_response(response)
      end
    after
      Logger.configure(level: level)
      :inets.stop(:httpc, :mix)
    end
  end

  defp fallback(:inet), do: :inet6
  defp fallback(:inet6), do: :inet

  defp httpc_request(request, http_options) do
    :httpc.request(:get, request, http_options, [body_format: :binary], :mix)
  end

  defp httpc_response(response) do
    case response do
      {:ok, {{_, status, _}, _, body}} when status in 200..299 ->
        {:ok, body}

      {:ok, {{_, status, _}, _, _}} ->
        {:remote, "httpc request failed with: {:bad_status_code, #{status}}"}

      {:error, reason} ->
        {:remote, "httpc request failed with: #{inspect(reason)}"}
    end
  end
end
