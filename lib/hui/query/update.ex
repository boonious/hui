defmodule Hui.Query.Update do
  @moduledoc """
  Struct related to Solr updating.

  ## Example
  ```
      alias Hui.Query
      alias Hui.Encoder

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
      iex> x = %Query.Update{doc: [doc1, doc2], commit: true, commitWithin: 1000}
      %Hui.Query.Update{
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
      iex> x |> Encoder.encode
      "{\\\"add\\\":{\\\"commitWithin\\\":1000,\\\"doc\\\":{\\\"name\\\":\\\"The Turin Horse\\\",\\\"id\\\":\\\"tt1316540\\\",\\\"genre\\\":[\\\"Drama\\\"],\\\"directed_by\\\":[\\\"Béla Tarr\\\"]}},\\\"add\\\":{\\\"commitWithin\\\":1000,\\\"doc\\\":{\\\"name\\\":\\\"I Wish\\\",\\\"id\\\":\\\"tt1650453\\\",\\\"genre\\\":[\\\"Drama\\\"],\\\"directed_by\\\":[\\\"Hirokazu Koreeda\\\"]}},\\\"commit\\\":{}}"

      # Delete the documents by ID
      iex> %Query.Update{delete_id: ["tt1316540", "tt1650453"]} |> Encoder.encode
      "{\\\"delete\\\":{\\\"id\\\":\\\"tt1316540\\\"},\\\"delete\\\":{\\\"id\\\":\\\"tt1650453\\\"}}"

      # Delete the documents by filter query
      iex> %Query.Update{delete_query: "id:tt*"} |> Encoder.encode
      "{\\\"delete\\\":{\\\"query\\\":\\\"id:tt*\\\"}}"

      # Commits the docs, make them visible and remove previously deleted docs from the index
      iex> %Query.Update{commit: true, waitSearcher: true, expungeDeletes: true} |> Encoder.encode
      "{\\\"commit\\\":{\\\"waitSearcher\\\":true,\\\"expungeDeletes\\\":true}}"

      # Optimise the index, and keep the number of index segments 10 max
      iex> %Query.Update{optimize: true, maxSegments: 10} |> Encoder.encode
      "{\\\"optimize\\\":{\\\"maxSegments\\\":10}}"
  ```
  """

  defstruct [
    :commit,
    :commitWithin,
    :delete_id,
    :delete_query,
    :doc,
    :expungeDeletes,
    :maxSegments,
    :optimize,
    :overwrite,
    :rollback,
    :waitSearcher
  ]

  @typedoc """
  Struct related to Solr [updating](http://lucene.apache.org/solr/guide/uploading-data-with-index-handlers.html).
  """
  @type t :: %__MODULE__{
          commit: boolean,
          commitWithin: integer,
          delete_id: binary | list(binary),
          delete_query: binary | list(binary),
          doc: map | list(map),
          expungeDeletes: boolean,
          maxSegments: integer,
          optimize: boolean,
          overwrite: boolean,
          rollback: boolean,
          waitSearcher: boolean
        }

  @spec new :: t
  def new(), do: %__MODULE__{}
end
