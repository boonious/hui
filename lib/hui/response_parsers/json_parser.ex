defmodule Hui.ResponseParsers.JsonParser do
  @moduledoc false

  alias Hui.Http

  @type http_response :: Http.response()

  @spec parse(http_response) :: http_response
  def parse({:ok, %Http{body: body} = response}), do: {:ok, %{response | body: decode_json(body)}}

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      {:error, _} -> to_string(body)
    end
  end
end
