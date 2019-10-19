defmodule Hui.H3 do
  @moduledoc deprecated: """
  Please use Hui.Query.HighlighterFastVector instead
  """

  defstruct [hl: true, per_field: false, method: "fastVector"] ++
            [:field, :per_field_method, :fl, :q, :qparser, :requireFieldMatch,
             :usePhraseHighlighter, :highlightMultiTerm, :snippets,
             :fragsize, :"tag.pre", :"tag.post", :encoder, :maxAnalyzedChars] ++
            [:alternateField, :maxAlternateFieldLength, :highlightAlternate, # additional parameters for FastVector Highlighter
             :"simple.pre", :"simple.post",
             :fragListBuilder, :fragmentsBuilder, :boundaryScanner,
             :"bs.type", :"bs.language", :"bs.country", :"bs.maxScan", :"bs.chars",
             :phraseLimit, :multiValuedSeparatorChar] 

  @typedoc """
  Struct for results highlighting - [FastVector Highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-fastvector-highlighter).
  """
  @type t :: %__MODULE__{hl: boolean, per_field: boolean, field: binary, per_field_method: binary,
                         method: binary, fl: binary, q: binary, qparser: binary, requireFieldMatch: boolean,
                         usePhraseHighlighter: boolean, highlightMultiTerm: boolean, snippets: number,
                         fragsize: number, "tag.pre": binary, "tag.post": binary, encoder: binary, maxAnalyzedChars: number,
                         alternateField: binary, maxAlternateFieldLength: number, highlightAlternate: boolean,
                         "simple.pre": binary, "simple.post": binary,
                         fragListBuilder: binary, fragmentsBuilder: binary, boundaryScanner: binary,
                         "bs.type": binary, "bs.language": binary, "bs.country": binary, "bs.maxScan": number, "bs.chars": binary,
                         phraseLimit: number, multiValuedSeparatorChar: binary}
end