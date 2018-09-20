defmodule Hui.H1 do
  @moduledoc """
  Struct and functions related to results highlighting - Unified Highlighter.
  """

  defstruct [hl: true, per_field: false, method: "unified"] ++
            [:field, :fl, :q, :qparser, :requireFieldMatch,
             :usePhraseHighlighter, :highlightMultiTerm, :snippets,
             :fragsize, :"tag.pre", :"tag.post", :encoder, :maxAnalyzedChars] ++ 
            [:offsetSource, :"tag.ellipsis", :defaultSummary, :"score.k1", :"score.b", # additional parameters for Unified Highlighter
             :"score.pivot", :"bs.language", :"bs.country", :"bs.variant", :"bs.type", :"bs.separator"] 

  @typedoc """
  Struct for results highlighting - [Unified Highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-unified-highlighter).
  """
  @type t :: %__MODULE__{hl: boolean, per_field: boolean, field: binary,
                         method: binary, fl: binary, q: binary, qparser: binary, requireFieldMatch: boolean,
                         usePhraseHighlighter: boolean, highlightMultiTerm: boolean, snippets: number,
                         fragsize: number, "tag.pre": binary, "tag.post": binary, encoder: binary, maxAnalyzedChars: number,
                         offsetSource: binary, "tag.ellipsis": binary, defaultSummary: boolean, "score.k1": number, "score.b": number,
                         "score.pivot": number, "bs.language": binary, "bs.country": binary,
                         "bs.variant": binary, "bs.type": binary, "bs.separator": binary}

end