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

  @spec new :: t
  def new(), do: %__MODULE__{}
end
