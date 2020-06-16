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
    {:ok, %Http{body: body, headers: headers, status: status, url: url}}
  end

  defp handle_response({:error, resp}), do: {:error, resp}
end
