defmodule Hui.Sp do
  @moduledoc """
  Struct and functions related to spell checking.
  """
  defstruct [spellcheck: true] ++
            [:q, :build, :reload, :count, :queryAnalyzerFieldtype, :onlyMorePopular,
             :maxResultsForSuggest, :alternativeTermCount, :extendedResults, :collate,
             :maxCollations, :maxCollationTries, :maxCollationEvaluations,
             :collateExtendedResults, :collateMaxCollectDocs,
             :"collateParam.q.op", :"collateParam.mm",
             :dictionary, :accuracy, :shards, :"shards.qt"]

  @typedoc """
  Struct for [spell checking](http://lucene.apache.org/solr/guide/spell-checking.html)
  """
  @type t :: %__MODULE__{spellcheck: boolean, 
                         q: binary, build: boolean, reload: boolean, count: number,
                         queryAnalyzerFieldtype: binary, onlyMorePopular: boolean,
                         maxResultsForSuggest: number, alternativeTermCount: number,
                         extendedResults: boolean, collate: boolean, maxCollations: number,
                         maxCollationTries: number, maxCollationEvaluations: number,
                         collateExtendedResults: boolean, collateMaxCollectDocs: number,
                         "collateParam.q.op": binary, "collateParam.mm": binary,
                         dictionary: binary, accuracy: number, shards: binary, "shards.qt": binary}
end