defmodule Hui.H2 do
  @moduledoc """
  Struct and functions related to results highlighting - Original Highlighter.
  """

  defstruct [hl: true, per_field: false, method: "original"] ++
            [:field, :fl, :q, :qparser, :requireFieldMatch,
             :usePhraseHighlighter, :highlightMultiTerm, :snippets,
             :fragsize, :"tag.pre", :"tag.post", :encoder, :maxAnalyzedChars] ++
            [:mergeContiguous, :maxMultiValuedToExamine, :maxMultiValuedToMatch, # additional parameters for Oiriginal Highlighter
             :alternateField, :maxAlternateFieldLength, :highlightAlternate,
             :formatter, :"simple.pre", :"simple.post", :fragmenter, :"regex.slop",
             :"regex.pattern", :"regex.maxAnalyzedChars", :preserveMulti, :payloads] 

  @typedoc """
  Struct for results highlighting - [Original Highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-original-highlighter).
  """
  @type t :: %__MODULE__{hl: boolean, per_field: boolean, field: binary,
                         method: binary, fl: binary, q: binary, qparser: binary, requireFieldMatch: boolean,
                         usePhraseHighlighter: boolean, highlightMultiTerm: boolean, snippets: number,
                         fragsize: number, "tag.pre": binary, "tag.post": binary, encoder: binary, maxAnalyzedChars: number,
                         mergeContiguous: boolean, maxMultiValuedToExamine: number, maxMultiValuedToMatch: number,
                         alternateField: binary, maxAlternateFieldLength: number, highlightAlternate: boolean,
                         formatter: binary, "simple.pre": binary, "simple.post": binary, fragmenter: binary, "regex.slop": number,
                         "regex.pattern": binary, "regex.maxAnalyzedChars": number, preserveMulti: boolean, payloads: boolean}

end