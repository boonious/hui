defmodule Hui.Query.HighlighterUnified do
  @moduledoc """
  Struct related to results highlighting - [Unified Highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-unified-highlighter).
  """

  # additional parameters for Unified Highlighter
  defstruct [
              :"bs.country",
              :"bs.language",
              :"bs.separator",
              :"bs.type",
              :"bs.variant",
              :defaultSummary,
              :offsetSource,
              :"score.b",
              :"score.k1",
              :"score.pivot",
              :"tag.ellipsis",
              :weightMatches
            ] ++ [per_field: false]

  @typedoc """
  Struct for [unified highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-unified-highlighter),
  use in conjunction with the highlighting struct -`t:Hui.Query.Highlight.t/0`.
  """
  @type t :: %__MODULE__{
          "bs.country": binary,
          "bs.language": binary,
          "bs.separator": binary,
          "bs.type": :SEPARATOR | :SENTENCE | :WORD | :CHARACTER | :LINE | :WHOLE,
          "bs.variant": binary,
          defaultSummary: boolean,
          offsetSource: :ANALYSIS | :POSTINGS | :POSTINGS_WITH_TERM_VECTORS | :TERM_VECTORS,
          per_field: false,
          "score.b": number,
          "score.k1": number,
          "score.pivot": number,
          "tag.ellipsis": binary,
          weightMatches: boolean
        }

  @spec new :: t
  def new(), do: %__MODULE__{}
end
