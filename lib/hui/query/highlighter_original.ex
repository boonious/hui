defmodule Hui.Query.HighlighterOriginal do
  @moduledoc """
  Struct related to results highlighting - [Original highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-original-highlighter)
  """
  defstruct [
              :alternateField,
              :formatter,
              :fragmenter,
              :highlightAlternate,
              :maxAlternateFieldLength,
              :maxMultiValuedToExamine,
              :maxMultiValuedToMatch,
              :mergeContiguous,
              :payloads,
              :per_field_method,
              :preserveMulti,
              :"regex.maxAnalyzedChars",
              :"regex.pattern",
              :"regex.slop",
              :"simple.post",
              :"simple.pre"
            ] ++ [per_field: false]

  @typedoc """
  Struct for [original highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-original-highlighter),
  use in conjunction with the highlighting struct -`t:Hui.Query.Highlight.t/0`.
  """
  @type t :: %__MODULE__{
          alternateField: binary,
          formatter: :simple,
          fragmenter: :gap | :regex,
          highlightAlternate: boolean,
          maxAlternateFieldLength: number,
          maxMultiValuedToExamine: number,
          maxMultiValuedToMatch: number,
          mergeContiguous: boolean,
          payloads: boolean,
          per_field: boolean,
          per_field_method: :fastVector,
          preserveMulti: boolean,
          "regex.maxAnalyzedChars": number,
          "regex.pattern": binary,
          "regex.slop": number,
          "simple.post": binary,
          "simple.pre": binary,
        }
end
