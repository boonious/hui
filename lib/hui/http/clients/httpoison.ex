if Code.ensure_compiled(HTTPoison) == {:module, HTTPoison} and Code.ensure_loaded?(:hackney) do
  defmodule Hui.Http.Clients.Httpoison do
    @moduledoc false

    alias Hui.Http

    @behaviour Hui.Http.Client

    # FIX-ME: update implementation give Http.new, new client `handle_response/1` behaviour

    @impl true
    def dispatch(request) do
      body = if request.body == nil, do: "", else: request.body

      HTTPoison.request(request.method, request.url, body, request.headers, request.options)
      |> handle_response(request)
    end

    @impl true
    def handle_response({:ok, %{body: body, headers: headers, request_url: url, status_code: status}}, _req) do
      {:ok, %Http{body: body, headers: headers, status: status, url: url}}
    end

    def handle_response({:error, %HTTPoison.Error{reason: reason}}, _req) do
      {:error, %Hui.Error{reason: reason}}
    end
  end
end
