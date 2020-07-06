defmodule Hui.Http.Httpoison do
  alias Hui.Http

  @behaviour Hui.Http

  @impl Hui.Http
  def get(request) do
    HTTPoison.get(request.url, request.headers, request.options)
    |> handle_response
  end

  @impl Hui.Http
  def post(request) do
    HTTPoison.post(request.url, request.body, request.headers, request.options)
    |> handle_response
  end

  defp handle_response({:ok, %{body: body, headers: headers, request_url: url, status_code: status}}) do
    case headers_map(headers) |> json?() do
      true -> {:ok, %Http{body: decode_json(body), headers: headers, status: status, url: url}}
      _ -> {:ok, %Http{body: body, headers: headers, status: status, url: url}}
    end
  end

  defp handle_response({:error, resp}), do: {:error, resp}

  defp headers_map(headers), do: Enum.into(headers, %{}, fn {k, v} -> {String.downcase(k), String.downcase(v)} end)

  defp json?(%{"content-type" => "application/json" <> _}), do: true
  defp json?(_), do: false

  defp decode_json(body) do
    case Poison.decode(body) do
      {:ok, map} -> map
      {:error, _} -> body
    end
  end
end
