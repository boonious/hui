defmodule Hui.Http.Client do
  @moduledoc """
  A client behaviour module for handling Solr HTTP requests and responses.

  This module is responsible for dispatching Solr request encapsulated in `t:Hui.Http.t/0` struct.
  It underpins the core functions of `Hui`, as well as provides default implementation and
  built-in HTTP client capability based on [Erlang httpc](https://erlang.org/doc/man/httpc.html).

  ### Using other HTTP clients
  Instead of using the built-in client, other HTTP clients may be developed
  by implementing `Hui.Http` behaviour and deployed through application configuration.
  For example, Hui provides another client option - `Hui.Http.Httpoison`.

  ```
    config :hui,
      http_client: Hui.Http.Httpoison
  ```

  Hui.Http.Httpoison depends on `HTTPoison`. The dependency needs to be specified in `mix.exs`.
  Add `:httpoison` to the applications section of the mix file to start up
  the client for runtime.

  ```
    defp deps do
      [
        {:httpoison, "~> 1.7"}
      ]
    end
  ```
  """

  alias Hui.Http

  @httpc_options [:timeout, :connect_timeout, :ssl, :essl, :autoredirect, :proxy_auth, :version, :relaxed]

  @type request :: Http.t()
  @type response :: {:ok, Http.t()} | {:error, Hui.Error.t()}

  @doc """
  Dispatch HTTP request to a Solr endpoint.

  This callback is optional and can be used to adapt other HTTP clients to
  provide different HTTP options and performance. Hui provides `Hui.Http.Httpoison`,
  a reference implementation of this callback that can be
  used in conjunction with `dispatch/2`.

  If the callback is not implemented, the default built-in httpc-based client
  will be used.
  """
  @callback dispatch(request) :: response

  @optional_callbacks dispatch: 1

  @doc """
  Dispatch HTTP request to a Solr endpoint using the built-in Erlang [httpc](https://erlang.org/doc/man/httpc.html) client.

  This is a default implementation of `c:dispatch/1` callback based on [httpc](https://erlang.org/doc/man/httpc.html).

  ### Example

  ```
    request = %Hui.Http{
                url: ["http://localhost:8080/solr/select", "?", "q=loch"],
                headers: [{"accept", "application/json"}],
                options: [{:timeout, 1000}]
              }

    {:ok, response} = HTTP.dispatch(request)
  ```

  Find out more about the available options from [httpc documentation](https://erlang.org/doc/man/httpc.html#request-5).
  """
  def dispatch(%{method: :get, options: options} = request) do
    {http_opts, opts} = handle_options(options, {[], []})

    :httpc.request(:get, {handle_url(request.url), handle_req_headers(request.headers)}, http_opts, opts)
    |> handle_response(request)
  end

  def dispatch(%{method: :post} = request) do
    headers = handle_req_headers(request.headers)
    {http_opts, opts} = handle_options(request.options, {[], []})

    {_, content_type} = List.keyfind(headers, 'content-type', 0, {'content-type', ''})

    :httpc.request(
      :post,
      {handle_url(request.url), headers, content_type, request.body},
      http_opts,
      opts
    )
    |> handle_response(request)
  end

  defoverridable dispatch: 1

  @doc """
  Dispatch HTTP request to a Solr endpoint using a given client implementing the `Hui.Http` behaviour.

  Same as `dispatch/1` but invoking request through dynamic dispatching. See `Hui.Http.Httpoison`
  for a reference client implementation based on `HTTPoison` that provides additional options
  such as [connection pooling](https://github.com/edgurgel/httpoison#connection-pools).
  """
  @spec dispatch(request, client :: module) :: response
  def dispatch(request, client), do: client.dispatch(request)

  defp handle_options([], {http_opts, opts}), do: {http_opts, opts}

  defp handle_options([{k, v} | t], {http_opts, opts}) do
    case k in @httpc_options do
      true -> handle_options(t, {[{k, v} | http_opts], opts})
      false -> handle_options(t, {http_opts, [{k, v} | opts]})
    end
  end

  defp handle_url(url) when is_list(url), do: Enum.map(url, &handle_url(&1))
  defp handle_url(url), do: url |> String.replace("%", "%25") |> to_charlist()

  defp handle_req_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)
  defp handle_resp_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

  defp handle_response({:ok, {{[?H, ?T, ?T, ?P | _], status, _}, headers, body}}, req) do
    headers = handle_resp_headers(headers)
    {:ok, %{req | body: to_string(body), headers: headers, status: status}}
  end

  defp handle_response({:error, {reason, _details}}, _req), do: {:error, %Hui.Error{reason: reason}}

  # httpc could also return errors with only reason and without further details
  defp handle_response({:error, reason}, _req), do: {:error, %Hui.Error{reason: reason}}
end
