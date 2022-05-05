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
      {:ok, %Http{body: body, headers: headers, status: status, url: url}}
    end

    defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
      {:error, %Hui.Error{reason: reason}}
    end
  end
end
