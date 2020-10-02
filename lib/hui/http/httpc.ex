defmodule Hui.Http.Httpc do
  @behaviour Hui.Http

  @impl Hui.Http
  def dispatch(%{body: nil} = req) do
    :httpc.request(req.method, {req.url |> to_charlist(), req.headers}, [], [])
    |> handle_response(req)
  end

  defp handle_response({:ok, {{'HTTP/1.1', status, 'OK'}, headers, body}}, req) do
    headers = process_headers(headers)
    {_, content_type} = List.keyfind(headers, "content-type", 0, {"content-type", ""})

    case content_type do
      "application/json" <> _ -> {:ok, %{req | body: decode_json(body), headers: headers, status: status}}
      _ -> {:ok, %{req | body: to_string(body), headers: headers, status: status}}
    end
  end

  defp process_headers(headers), do: Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      {:error, _} -> to_string(body)
    end
  end
end
