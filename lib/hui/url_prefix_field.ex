# prefix and field constant for per-field encoding of query structs in URL
defmodule Hui.URLPrefixField do
  @moduledoc false

  @prefix_field %{
    "Elixir.Hui.Query.Facet": {"facet", :field},
    "Elixir.Hui.Query.FacetRange": {"facet.range", :range},
    "Elixir.Hui.Query.FacetInterval": {"facet.interval", :interval},
    "Elixir.Hui.Query.Highlight": {"hl", :field},
    "Elixir.Hui.Query.HighlighterUnified": {"hl", nil},
    "Elixir.Hui.Query.HighlighterOriginal": {"hl", nil},
    "Elixir.Hui.Query.HighlighterFastVector": {"hl", nil},
    "Elixir.Hui.Query.MoreLikeThis": {"mlt", nil},
    "Elixir.Hui.Query.SpellCheck": {"spellcheck", nil},
    "Elixir.Hui.Query.Suggest": {"suggest", nil}
  }

  def prefix_field, do: @prefix_field
end
