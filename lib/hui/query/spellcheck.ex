defmodule Hui.Query.SpellCheck do
  @moduledoc """
  Struct for [spell checking](http://lucene.apache.org/solr/guide/spell-checking.html#spell-check-parameters) query.
  """
  defstruct [
              :accuracy,
              :alternativeTermCount,
              :build,
              :collate,
              :collateExtendedResults,
              :collateMaxCollectDocs,
              :"collateParam.mm",
              :"collateParam.q.op",
              :count,
              :dictionary,
              :extendedResults,
              :maxCollationEvaluations,
              :maxCollationTries,
              :maxCollations,
              :maxResultsForSuggest,
              :onlyMorePopular,
              :q,
              :queryAnalyzerFieldtype,
              :reload,
              :shards,
              :"shards.qt"
            ] ++ [spellcheck: true]

  @typedoc """
  Struct for [spell checking](http://lucene.apache.org/solr/guide/spell-checking.html#spell-check-parameters)
  """
  @type t :: %__MODULE__{
          accuracy: number,
          alternativeTermCount: number,
          build: boolean,
          collate: boolean,
          collateExtendedResults: boolean,
          collateMaxCollectDocs: number,
          "collateParam.mm": binary,
          "collateParam.q.op": binary,
          count: number,
          dictionary: binary,
          extendedResults: boolean,
          maxCollationEvaluations: number,
          maxCollationTries: number,
          maxCollations: number,
          maxResultsForSuggest: number,
          onlyMorePopular: boolean,
          q: binary,
          queryAnalyzerFieldtype: binary,
          reload: boolean,
          shards: binary,
          "shards.qt": binary,
          spellcheck: boolean
        }

  def new(), do: %__MODULE__{}
end
