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

  def encode(%__MODULE__{} = s) do
   a = "#{encode(doc: s.doc, within: s.commitWithin, overwrite: s.overwrite)}"
   b = "#{encode(commit: s.commit, wait: s.waitSearcher, expunge: s.expungeDeletes)}"
   c = "#{encode(optimize: s.optimize, wait: s.waitSearcher, max: s.maxSegments)}"
   d = "#{encode(delete_id: s.delete_id)}"
   e = "#{encode(delete_query: s.delete_query)}"

   x = [a, b, c, d, e] |> Enum.filter(fn x -> x != "" end)
   "{#{Enum.join(x, ",")}}"
  end
  def encode(doc) when is_map(doc), do: Poison.encode!(doc)

  def encode(doc: doc, within: w, overwrite: o) when is_map(doc), do: "\"add\":{#{encode(within: w)}#{encode(overwrite: o)}\"doc\":#{encode(doc)}}"
  def encode(doc: [h|t], within: w, overwrite: o) when is_map(h), do: Enum.map_join([h]++t, "," , &encode(doc: &1, within: w, overwrite: o))
  def encode(doc: _, within: _, overwrite: _), do: ""

  def encode(within: w) when is_integer(w), do: "\"commitWithin\":#{w},"
  def encode(within: _), do: ""

  def encode(overwrite: o) when is_boolean(o), do: "\"overwrite\":#{o},"
  def encode(overwrite: _), do: ""

  def encode(commit: true, wait: w, expunge: e) when is_boolean(w) and is_boolean(e), do: "\"commit\":{\"waitSearcher\":#{w},\"expungeDeletes\":#{e}}"
  def encode(commit: true, wait: w, expunge: nil) when is_boolean(w), do: "\"commit\":{\"waitSearcher\":#{w}}"
  def encode(commit: true, wait: nil, expunge: e) when is_boolean(e), do: "\"commit\":{\"expungeDeletes\":#{e}}"
  def encode(commit: true, wait: nil, expunge: nil), do: "\"commit\":{}"
  def encode(commit: _, wait: _, expunge: _), do: ""

  def encode(optimize: true, wait: w, max: m) when is_boolean(w) and is_integer(m), do: "\"optimize\":{\"waitSearcher\":#{w},\"maxSegments\":#{m}}"
  def encode(optimize: true, wait: w, max: nil) when is_boolean(w), do: "\"optimize\":{\"waitSearcher\":#{w}}"
  def encode(optimize: true, wait: nil, max: m) when is_integer(m), do: "\"optimize\":{\"maxSegments\":#{m}}"
  def encode(optimize: true, wait: nil, max: nil), do: "\"optimize\":{}"
  def encode(optimize: _, wait: _, max: _), do: ""

  def encode(delete_id: id) when is_binary(id), do: "\"delete\":{\"id\":\"#{id}\"}"
  def encode(delete_id: id) when is_list(id), do: Enum.map_join(id, ",", &encode(delete_id: &1))
  def encode(delete_id: _), do: ""

  def encode(delete_query: q) when is_binary(q), do: "\"delete\":{\"query\":\"#{q}\"}"
  def encode(delete_query: q) when is_list(q), do: Enum.map_join(q, ",", &encode(delete_query: &1))
  def encode(delete_query: _), do: ""
end