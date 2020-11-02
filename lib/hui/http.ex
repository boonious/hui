defmodule Hui.Http do
  @httpc_options [:timeout, :connect_timeout, :ssl, :essl, :autoredirect, :proxy_auth, :version, :relaxed]

  defstruct body: nil,
            headers: [],
            method: :get,
            options: [],
            status: nil,
            url: ""

  @type t :: %__MODULE__{
          body: nil | binary() | map(),
          headers: list(),
          method: :get | :post,
          options: keyword(),
          status: nil | integer(),
          url: iodata()
        }

  @type response :: {:ok, t} | {:error, Hui.Error.t()}

  @callback dispatch(request :: t) :: response
  @optional_callbacks dispatch: 1

  @spec dispatch(request :: t) :: response
  def dispatch(%{method: :get, options: options} = request) do
    {http_opts, opts} = handle_options(options, {[], []})

    :httpc.request(:get, {handle_url(request.url), handle_req_headers(request.headers)}, http_opts, opts)
    |> handle_response(request)
  end

  def dispatch(%{method: :post, headers: headers, options: options} = request) do
    {_, content_type} = List.keyfind(headers, "content-type", 0, {"content-type", ""})
    {http_opts, opts} = handle_options(options, {[], []})

    :httpc.request(
      :post,
      {handle_url(request.url), handle_req_headers(request.headers), content_type |> to_charlist(), request.body},
      http_opts,
      opts
    )
    |> handle_response(request)
  end

  defoverridable dispatch: 1

  @spec dispatch(request :: t, client :: module) :: response
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

  defp handle_response({:ok, {{'HTTP/1.1', status, 'OK'}, headers, body}}, req) do
    headers = handle_resp_headers(headers)
    {_, content_type} = List.keyfind(headers, "content-type", 0, {"content-type", ""})

    case content_type do
      "application/json" <> _ -> {:ok, %{req | body: decode_json(body), headers: headers, status: status}}
      _ -> {:ok, %{req | body: to_string(body), headers: headers, status: status}}
    end
  end

  defp handle_response({:error, {reason, _details}}, _req), do: {:error, %Hui.Error{reason: reason}}

  # httpc could also return errors with only reason and without further details
  defp handle_response({:error, reason}, _req), do: {:error, %Hui.Error{reason: reason}}

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      {:error, _} -> to_string(body)
    end
  end
end
