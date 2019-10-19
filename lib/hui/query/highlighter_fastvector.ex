defmodule Hui.Query.HighlighterFastVector do
  @moduledoc """
  Struct related to results highlighting - [Fast Vector highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-fastvector-highlighter)
  """

  defstruct [
              :alternateField,
              :boundaryScanner,
              :"bs.chars",
              :"bs.country",
              :"bs.language",
              :"bs.maxScan",
              :"bs.type",
              :fragListBuilder,
              :fragmentsBuilder,
              :highlightAlternate,
              :maxAlternateFieldLength,
              :multiValuedSeparatorChar,
              :phraseLimit
            ] ++ [per_field: false]

  @typedoc """
  Struct for [fast vector highlighter](http://lucene.apache.org/solr/guide/highlighting.html#the-fastvector-highlighter),
  use in conjunction with the highlighting struct -`t:Hui.Query.Highlight.t/0`.
  """
  @type t :: %__MODULE__{
          alternateField: binary,
          boundaryScanner: binary,
          "bs.chars": binary,
          "bs.country": binary,
          "bs.language": binary,
          "bs.maxScan": number,
          "bs.type": binary,
          fragListBuilder: binary,
          fragmentsBuilder: binary,
          highlightAlternate: boolean,
          maxAlternateFieldLength: number,
          multiValuedSeparatorChar: binary,
          per_field: boolean,
          phraseLimit: number
        }
end
