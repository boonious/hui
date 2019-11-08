defmodule Hui.U do
  @moduledoc deprecated: """
  Please use Hui.Query.Update instead
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

  @doc """
  Encodes the `Hui.U.t` module struct into Solr binary commands for JSON-formatted update.

  ## Example
  ```
      # Update / index 2 documents, commit them within 1s
      iex> doc1 = %{"name" => "The Turin Horse", "directed_by" => ["Béla Tarr"], "genre" => ["Drama"], "id" => "tt1316540"}
      %{
        "directed_by" => ["Béla Tarr"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "name" => "The Turin Horse"
      }
      iex> doc2 = %{"name" => "I Wish", "directed_by" => ["Hirokazu Koreeda"], "genre" => ["Drama"], "id" => "tt1650453"}
      %{
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drama"],
        "id" => "tt1650453",
        "name" => "I Wish"
      }
      iex> x = %Hui.U{doc: [doc1, doc2], commit: true, commitWithin: 1000}
      %Hui.U{
        commit: true,
        commitWithin: 1000,
        delete_id: nil,
        delete_query: nil,
        doc: [
          %{
            "directed_by" => ["Béla Tarr"],
            "genre" => ["Drama"],
            "id" => "tt1316540",
            "name" => "The Turin Horse"
          },
          %{
            "directed_by" => ["Hirokazu Koreeda"],
            "genre" => ["Drama"],
            "id" => "tt1650453",
            "name" => "I Wish"
          }
        ],
        expungeDeletes: nil,
        maxSegments: nil,
        optimize: nil,
        overwrite: nil,
        rollback: nil,
        waitSearcher: nil
      }
      iex> x |> Hui.U.encode
      "{\\\"add\\\":{\\\"commitWithin\\\":1000,\\\"doc\\\":{\\\"name\\\":\\\"The Turin Horse\\\",\\\"id\\\":\\\"tt1316540\\\",\\\"genre\\\":[\\\"Drama\\\"],\\\"directed_by\\\":[\\\"Béla Tarr\\\"]}},\\\"add\\\":{\\\"commitWithin\\\":1000,\\\"doc\\\":{\\\"name\\\":\\\"I Wish\\\",\\\"id\\\":\\\"tt1650453\\\",\\\"genre\\\":[\\\"Drama\\\"],\\\"directed_by\\\":[\\\"Hirokazu Koreeda\\\"]}},\\\"commit\\\":{}}"

      # Delete the documents by ID
      iex> %Hui.U{delete_id: ["tt1316540", "tt1650453"]} |> Hui.U.encode
      "{\\\"delete\\\":{\\\"id\\\":\\\"tt1316540\\\"},\\\"delete\\\":{\\\"id\\\":\\\"tt1650453\\\"}}"

      # Delete the documents by filter query
      iex> %Hui.U{delete_query: "id:tt*"} |> Hui.U.encode
      "{\\\"delete\\\":{\\\"query\\\":\\\"id:tt*\\\"}}"

      # Commits the docs, make them visible and remove previously deleted docs from the index
      iex> %Hui.U{commit: true, waitSearcher: true, expungeDeletes: true} |> Hui.U.encode
      "{\\\"commit\\\":{\\\"waitSearcher\\\":true,\\\"expungeDeletes\\\":true}}"

      # Optimise the index, and keep the number of index segments 10 max
      iex> %Hui.U{optimize: true, maxSegments: 10} |> Hui.U.encode
      "{\\\"optimize\\\":{\\\"maxSegments\\\":10}}"
  ```
  """
  @spec encode(Hui.U.t) :: binary
  def encode(%__MODULE__{} = s) do
   a = "#{_encode(doc: s.doc, within: s.commitWithin, overwrite: s.overwrite)}"
   b = "#{_encode(delete_id: s.delete_id)}"
   c = "#{_encode(delete_query: s.delete_query)}"
   d = "#{_encode(commit: s.commit, wait: s.waitSearcher, expunge: s.expungeDeletes)}"
   e = "#{_encode(optimize: s.optimize, wait: s.waitSearcher, max: s.maxSegments)}"
   f = "#{_encode(rollback: s.rollback)}"

   x = [a, b, c, d, e, f] |> Enum.filter(fn x -> x != "" end)
   "{#{Enum.join(x, ",")}}"
  end

  defp _encode(doc) when is_map(doc), do: Poison.encode!(doc)

  defp _encode(doc: doc, within: w, overwrite: o) when is_map(doc), do: "\"add\":{#{_encode(within: w)}#{_encode(overwrite: o)}\"doc\":#{_encode(doc)}}"
  defp _encode(doc: [h|t], within: w, overwrite: o) when is_map(h), do: Enum.map_join([h]++t, "," , &_encode(doc: &1, within: w, overwrite: o))
  defp _encode(doc: _, within: _, overwrite: _), do: ""

  defp _encode(within: w) when is_integer(w), do: "\"commitWithin\":#{w},"
  defp _encode(within: _), do: ""

  defp _encode(overwrite: o) when is_boolean(o), do: "\"overwrite\":#{o},"
  defp _encode(overwrite: _), do: ""

  defp _encode(commit: true, wait: w, expunge: e) when is_boolean(w) and is_boolean(e), do: "\"commit\":{\"waitSearcher\":#{w},\"expungeDeletes\":#{e}}"
  defp _encode(commit: true, wait: w, expunge: nil) when is_boolean(w), do: "\"commit\":{\"waitSearcher\":#{w}}"
  defp _encode(commit: true, wait: nil, expunge: e) when is_boolean(e), do: "\"commit\":{\"expungeDeletes\":#{e}}"
  defp _encode(commit: true, wait: nil, expunge: nil), do: "\"commit\":{}"
  defp _encode(commit: _, wait: _, expunge: _), do: ""

  defp _encode(optimize: true, wait: w, max: m) when is_boolean(w) and is_integer(m), do: "\"optimize\":{\"waitSearcher\":#{w},\"maxSegments\":#{m}}"
  defp _encode(optimize: true, wait: w, max: nil) when is_boolean(w), do: "\"optimize\":{\"waitSearcher\":#{w}}"
  defp _encode(optimize: true, wait: nil, max: m) when is_integer(m), do: "\"optimize\":{\"maxSegments\":#{m}}"
  defp _encode(optimize: true, wait: nil, max: nil), do: "\"optimize\":{}"
  defp _encode(optimize: _, wait: _, max: _), do: ""

  defp _encode(delete_id: id) when is_binary(id), do: "\"delete\":{\"id\":\"#{id}\"}"
  defp _encode(delete_id: id) when is_list(id), do: Enum.map_join(id, ",", &_encode(delete_id: &1))
  defp _encode(delete_id: _), do: ""

  defp _encode(delete_query: q) when is_binary(q), do: "\"delete\":{\"query\":\"#{q}\"}"
  defp _encode(delete_query: q) when is_list(q), do: Enum.map_join(q, ",", &_encode(delete_query: &1))
  defp _encode(delete_query: _), do: ""

  defp _encode(rollback: true), do: "\"rollback\":{}"
  defp _encode(rollback: _), do: ""

end