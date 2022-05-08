defmodule Hui.Admin do
  @moduledoc false

  alias Hui.Query.Metrics

  @spec metrics(Hui.url(), keyword) :: Http.response()
  def metrics(endpoint, options) do
    Hui.get(endpoint, struct(Metrics, options))
  end

  @spec ping(Hui.url()) :: {:pong, integer} | :pang | Http.response()
  def ping(endpoint, options \\ [])

  def ping(endpoint, opts) when is_atom(endpoint) do
    case Application.get_env(:hui, endpoint)[:url] do
      nil ->
        :pang

      url ->
        [url, "/admin/ping"]
        |> to_string()
        |> Hui.get(opts)
        |> handle_response(opts)
    end
  end

  def ping(endpoint, opts), do: Hui.get(endpoint, opts) |> handle_response(opts)

  defp handle_response({:ok, %{body: %{"status" => "OK"}, status: 200} = resp}, []) do
    {:pong, resp.body["responseHeader"]["QTime"]}
  end

  defp handle_response({:ok, %{status: status}}, []) when status != 200, do: :pang
  defp handle_response({:error, _resp}, []), do: :pang
  defp handle_response(resp, _opts), do: resp
end
