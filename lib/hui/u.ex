defmodule Hui.U do
  @moduledoc """
  Struct and functions related to Solr updating.
  """

  defstruct [:doc, :commitWithin, :overwrite, :optimize, :commit, 
             :waitSearcher, :expungeDeletes, :maxSegments, :rollback, 
             :delete_id, :delete_query]

  @typedoc """
  Struct and functions related to Solr [updating](http://lucene.apache.org/solr/guide/uploading-data-with-index-handlers.html).
  """
  @type t :: %__MODULE__{doc: map | list(map), commitWithin: integer, overwrite: boolean,
                         optimize: boolean, commit: boolean, rollback: boolean,
                         waitSearcher: boolean, expungeDeletes: boolean, maxSegments: integer,
                         delete_id: binary | list(binary), delete_query: binary | list(binary)}

  def encode(%__MODULE__{} = s), do: "{#{encode(doc: s.doc)}}"
  def encode(doc) when is_map(doc), do: Poison.encode!(doc)

  def encode(doc: nil), do: ""
  def encode(doc: doc) when is_map(doc), do: "\"add\":{\"doc\":#{encode(doc)}}"
  def encode(doc: [head|tail]) when is_map(head), do: Enum.map([head]++tail, &encode(doc: &1))

end