defmodule Hui.Http.Clients.Httpc do
  @moduledoc false

  @behaviour Hui.Http.Client

  @httpc_options [:timeout, :connect_timeout, :ssl, :essl, :autoredirect, :proxy_auth, :version, :relaxed]

  @doc """
  Dispatch HTTP request to a Solr endpoint using the built-in Erlang [httpc](https://erlang.org/doc/man/httpc.html) client.

  This provides a default implementation of `c:dispatch/1` callback based on [httpc](https://erlang.org/doc/man/httpc.html).

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
  @impl true
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

  defp handle_options([], {http_opts, opts}), do: {http_opts, opts}

  defp handle_options([{k, v} | t], {http_opts, opts}) do
    case k in @httpc_options do
      true -> handle_options(t, {[{k, v} | http_opts], opts})
      false -> handle_options(t, {http_opts, [{k, v} | opts]})
    end
  end

  defp handle_req_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)
  defp handle_resp_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

  defp handle_response({:ok, {{[?H, ?T, ?T, ?P | _], status, _}, headers, body}}, req) do
    headers = handle_resp_headers(headers)
    {:ok, %{req | body: to_string(body), headers: headers, status: status}}
  end

  defp handle_response({:error, {reason, _details}}, _req), do: {:error, %Hui.Error{reason: reason}}

  # httpc could also return errors with only reason and without further details
  defp handle_response({:error, reason}, _req), do: {:error, %Hui.Error{reason: reason}}

  defp handle_url(url) when is_list(url), do: Enum.map(url, &handle_url(&1))
  defp handle_url(url), do: url |> String.replace("%", "%25") |> to_charlist()
end
