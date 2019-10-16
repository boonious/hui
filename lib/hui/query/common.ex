defmodule Hui.Query.Common do
  @moduledoc """
  Struct for common and SolrCloud query parameters.

  See:
  - [Common query parameters](http://lucene.apache.org/solr/guide/common-query-parameters.html)
  - [SolrCloud query routing parameters](http://lucene.apache.org/solr/guide/solrcloud-query-routing-and-read-tolerance.html)
  - [SolrCloud distributed requests](http://lucene.apache.org/solr/guide/distributed-requests.html)
  """
  defstruct [
    :cache,
    :collection,
    :cursorMark,
    :debug,
    :debugQuery,
    :defType,
    :distrib,
    :"distrib.singlePass",
    :echoParams,
    :explainOther,
    :fl,
    :"json.nl",
    :"json.wrf",
    :logParamsList,
    :omitHeader,
    :rows,
    :segmentTerminateEarly,
    :shards,
    :"shards.info",
    :"shards.preference",
    :"shards.tolerant",
    :sort,
    :start,
    :timeAllowed,
    :tr,
    :wt,
    :_route_,
    fq: []
  ]

  @typedoc """
  Struct for the common and SolrCloud query parameters.
  """
  @type t :: %__MODULE__{
    cache: boolean,
    collection: binary,
    cursorMark: binary,
    debug: binary,
    debugQuery: boolean,    
    defType: binary,
    distrib: boolean,
    "distrib.singlePass": boolean,
    echoParams: binary,
    explainOther: binary,
    fl: binary,
    fq: binary | list(binary),
    "json.nl": binary,
    "json.wrf": binary,
    logParamsList: binary,
    omitHeader: boolean,
    rows: integer,
    segmentTerminateEarly: boolean,
    shards: binary,
    "shards.info": boolean,
    "shards.preference": binary,
    "shards.tolerant": boolean,
    sort: binary,
    start: number,
    timeAllowed: number,
    tr: binary,
    wt: binary,
    _route_: binary
  }

end