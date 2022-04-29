if Code.ensure_compiled(HTTPoison) == {:module, HTTPoison} and Code.ensure_loaded?(:hackney) do
  defmodule Hui.Http.Httpoison do
    @moduledoc false

    alias Hui.Http

    @behaviour Hui.Http

    @impl Hui.Http
    def dispatch(request) do
      body = if request.body == nil, do: "", else: request.body

      HTTPoison.request(request.method, request.url, body, request.headers, request.options)
      |> handle_response()
    end

    defp handle_response({:ok, %{body: body, headers: headers, request_url: url, status_code: status}}) do
      case json?(headers) do
        true -> {:ok, %Http{body: decode_json(body), headers: headers, status: status, url: url}}
        false -> {:ok, %Http{body: body, headers: headers, status: status, url: url}}
      end
    end

    defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
      {:error, %Hui.Error{reason: reason}}
    end

    defp json?(headers) do
      {"content-type", "application/json;charset=utf-8"} in headers
    end

    defp decode_json(body) do
      case Jason.decode(body) do
        {:ok, map} -> map
        {:error, %Jason.DecodeError{}} -> body
      end
    end
  end
end
