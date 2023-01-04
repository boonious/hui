defmodule Hui.Http.Clients.Httpc do
  @moduledoc false

  @behaviour Hui.Http.Client

  @httpc_options [:timeout, :connect_timeout, :ssl, :essl, :autoredirect, :proxy_auth, :version, :relaxed]

  @impl true
  def dispatch(%{method: :get, options: options} = req) do
    {http_opts, opts} = split_options(options, {[], []})
    headers = handle_req_headers(req.headers)
    :httpc.request(:get, {format_url(req.url), headers}, http_opts, opts)
  end

  def dispatch(%{method: :post} = req) do
    headers = handle_req_headers(req.headers)
    {http_opts, opts} = split_options(req.options, {[], []})
    {_, content_type} = List.keyfind(headers, 'content-type', 0, {'content-type', ''})

    :httpc.request(
      :post,
      {format_url(req.url), headers, content_type, req.body},
      http_opts,
      opts
    )
  end

  defp format_url(url) when is_list(url), do: Enum.map(url, &format_url(&1))
  defp format_url(url), do: url |> String.replace("%", "%25") |> to_charlist()

  defp split_options([], {http_opts, opts}), do: {http_opts, opts}

  defp split_options([{k, v} | t], {http_opts, opts}) do
    case k in @httpc_options do
      true -> split_options(t, {[{k, v} | http_opts], opts})
      false -> split_options(t, {http_opts, [{k, v} | opts]})
    end
  end

  defp handle_req_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)

  @impl true
  def handle_response({:ok, {{[?H, ?T, ?T, ?P | _], status, _}, headers, body}}, req) do
    headers = handle_resp_headers(headers)

    {:ok, %{req | body: to_string(body), headers: headers, status: status}}
    |> parse_docs(req.response_parser)
  end

  def handle_response({:error, {reason, _details}}, _req), do: {:error, %Hui.Error{reason: reason}}

  # httpc could also return errors with only reason and without further details
  def handle_response({:error, reason}, _req), do: {:error, %Hui.Error{reason: reason}}

  defp handle_resp_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

  # no parser
  defp parse_docs(response, nil), do: response
  defp parse_docs({:error, _error} = response, _parser), do: response

  defp parse_docs(response, parser) do
    apply(parser, :parse, [response])
  end
end
