defmodule Hui.ResponseParsers.JsonParser do
  @moduledoc false

  @behaviour Hui.ResponseParsers.Parser

  alias Hui.Http

  @impl true
  def parse({:ok, %Http{body: body} = response}), do: {:ok, %{response | body: decode_json(body)}}

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, map} -> map
      {:error, _} -> to_string(body)
    end
  end
end
