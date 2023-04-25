defmodule Hui.Suggest do
  @moduledoc false

  alias Hui.Http
  alias Hui.Query.Suggest

  def suggest(endpoint, %Suggest{} = query), do: Http.get(endpoint, query)

  def suggest(endpoint, q, count \\ nil, dictionaries \\ nil, context \\ nil)

  def suggest(endpoint, q, count, dictionaries, context) do
    suggest(endpoint, %Suggest{q: q, count: count, dictionary: dictionaries, cfq: context})
  end
end
