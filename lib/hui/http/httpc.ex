defmodule Hui.Http.Httpc do
  @behaviour Hui.Http

  @http_options [:timeout, :connect_timeout, :ssl, :essl, :autoredirect, :proxy_auth, :version, :relaxed]

  @impl Hui.Http
  def dispatch(%{method: :get, options: options} = req) do
    {http_opts, opts} = handle_options(options, {[], []})

    :httpc.request(:get, {req.url |> to_charlist(), req.headers}, http_opts, opts)
    |> handle_response(req)
  end

  def dispatch(%{method: :post, headers: headers, options: options} = req) do
    {_, content_type} = List.keyfind(headers, "content-type", 0, {"content-type", ""})
    {http_opts, opts} = handle_options(options, {[], []})

    :httpc.request(
      :post,
      {req.url |> to_charlist(), handle_req_headers(req.headers), content_type |> to_charlist(), req.body},
      http_opts,
      opts
    )
    |> handle_response(req)
  end

  # TODO: handle non ok responses
  defp handle_response({:ok, {{'HTTP/1.1', status, 'OK'}, headers, body}}, req) do
    headers = handle_resp_headers(headers)
    {_, content_type} = List.keyfind(headers, "content-type", 0, {"content-type", ""})

    case content_type do
      "application/json" <> _ -> {:ok, %{req | body: decode_json(body), headers: headers, status: status}}
      _ -> {:ok, %{req | body: to_string(body), headers: headers, status: status}}
    end
  end

  defp handle_resp_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)
  defp handle_req_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)

  defp handle_options([], {http_opts, opts}), do: {http_opts, opts}

  defp handle_options([{k, v} | t], {http_opts, opts}) do
    case k in @http_options do
      true -> handle_options(t, {[{k, v} | http_opts], opts})
      false -> handle_options(t, {http_opts, [{k, v} | opts]})
    end
  end

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      {:error, _} -> to_string(body)
    end
  end
end
