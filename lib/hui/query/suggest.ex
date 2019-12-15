defmodule Hui.Query.Suggest do
  @moduledoc """
  Struct for [suggester](http://lucene.apache.org/solr/guide/suggester.html#suggest-request-handler-parameters) query.
  """
  defstruct [:build, :buildAll, :cfq, :count, :dictionary, :q, :reload, :reloadAll, suggest: true]

  @typedoc """
  Struct for [suggester](http://lucene.apache.org/solr/guide/suggester.html#suggest-request-handler-parameters)
  """
  @type t :: %__MODULE__{
          build: boolean,
          buildAll: boolean,
          cfq: binary,
          count: number,
          dictionary: binary | list(binary),
          q: binary,
          reload: boolean,
          reloadAll: boolean,
          suggest: boolean
        }

  @spec new(binary, number, binary | list(binary), binary) :: t
  def new(q, count \\ nil, dictionaries \\ nil, context \\ nil),
    do: %__MODULE__{q: q, count: count, dictionary: dictionaries, cfq: context}

  @spec new :: t
  def new(), do: %__MODULE__{}
end
