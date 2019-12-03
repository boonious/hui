defmodule Hui.Query.Highlight do
  @moduledoc """
  Struct related to the common parameters of results highlighting.

  See :
  - [Highlighting parameters](http://lucene.apache.org/solr/guide/highlighting.html)

  """
  defstruct [
              :encoder,
              :field,
              :fl,
              :fragsize,
              :highlightMultiTerm,
              :maxAnalyzedChars,
              :method,
              :q,
              :qparser,
              :requireFieldMatch,
              :snippets,
              :"tag.post",
              :"tag.pre",
              :usePhraseHighlighter
            ] ++ [hl: true, per_field: false]

  @typedoc """
  Struct for [results highlighting](http://lucene.apache.org/solr/guide/highlighting.html) 
  """
  @type t :: %__MODULE__{
          encoder: binary,
          field: binary,
          fl: binary,
          fragsize: number,
          highlightMultiTerm: boolean,
          hl: boolean,
          maxAnalyzedChars: number,
          method: :unified | :original | :fastVector,
          per_field: boolean,
          q: binary,
          qparser: binary,
          requireFieldMatch: boolean,
          snippets: number,
          "tag.post": binary,
          "tag.pre": binary,
          usePhraseHighlighter: boolean
        }

  @spec new :: t
  def new(), do: %__MODULE__{}
end
