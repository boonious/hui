defmodule Hui.H do
  @moduledoc """
  Struct and functions related to results [highlighting](http://lucene.apache.org/solr/guide/highlighting.html).
  """

  defstruct [hl: true, per_field: false] ++
            [:field, :method, :fl, :q, :qparser, :requireFieldMatch,
             :usePhraseHighlighter, :highlightMultiTerm, :snippets,
             :fragsize, :"tag.pre", :"tag.post", :encoder, :maxAnalyzedChars]

  @typedoc """
  Struct for results highlighting.
  """
  @type t :: %__MODULE__{hl: boolean, per_field: boolean, field: binary,
                         method: binary, fl: binary, q: binary, qparser: binary, requireFieldMatch: boolean,
                         usePhraseHighlighter: boolean, highlightMultiTerm: boolean, snippets: number,
                         fragsize: number, "tag.pre": binary, "tag.post": binary, encoder: binary, maxAnalyzedChars: number}

end