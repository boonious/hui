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

  def encode(%__MODULE__{} = s), do: "{#{encode(doc: s.doc, within: s.commitWithin, overwrite: s.overwrite)}}"
  def encode(doc) when is_map(doc), do: Poison.encode!(doc)

  def encode(doc: doc, within: w, overwrite: o) when is_map(doc), do: "\"add\":{#{encode(within: w)}#{encode(overwrite: o)}\"doc\":#{encode(doc)}}"
  def encode(doc: [h|t], within: w, overwrite: o) when is_map(h), do: Enum.map_join([h]++t, "," , &encode(doc: &1, within: w, overwrite: o))
  def encode(doc: _, within: _, overwrite: _), do: ""

  def encode(within: w) when is_integer(w), do: "\"commitWithin\":#{w},"
  def encode(within: _), do: ""

  def encode(overwrite: o) when is_boolean(o), do: "\"overwrite\":#{o},"
  def encode(overwrite: _), do: ""

end