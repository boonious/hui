defmodule Hui do
  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).

  ### Usage

  - Searching Solr: `q/1`, `q/6`, `search/2`, `search/7`
  - Updating: `update/3`, `delete/3`, `delete_by_query/3`, `commit/2`
  - Other: `suggest/2`, `suggest/5`
  - [README](https://hexdocs.pm/hui/readme.html#usage)
  """

  import Hui.Guards

  alias Hui.Query
  alias HTTPoison.Response

  @type url :: binary | atom | Hui.URL.t()
  @type query :: Query.solr_query()
  @type update_query :: binary | map | list(map) | Query.Update.t()

  # invalid / non existing host or domain
  @error_nxdomain %Hui.Error{reason: :nxdomain}

  @doc """
  Issue a keyword list or structured query to the default Solr endpoint.

  The query can either be a keyword list or a list of Hui structs - see `t:Hui.Query.solr_struct/0`. 
  This function is a shortcut for `search/2` with `:default` as URL key.

  ### Example

  ```
    Hui.q(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])

    # supply a list of Hui structs for more complex query, e.g. faceting
    alias Hui.Query

    Hui.q([%Query.Standard{q: "author:I*"}, %Query.Facet{field: ["cat", "author"], mincount: 1}])

    # DisMax
    x = %Query.Dismax{q: "run", qf: "description^2.3 title", mm: "2<-25% 9<-3"}
    y = %Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
    z = %Query.Facet{field: ["cat", "author"], mincount: 1}

    Hui.q([x, y, z])
  ```
  """
  @spec q(query) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def q(q) when is_list(q), do: query(q, :default)

  @doc """
  Convenience function for issuing various typical queries to the default Solr endpoint.

  ### Example

  ```
    Hui.q("scott")
    # keywords
    Hui.q("loch", 10, 20)
    # .. with paging parameters
    Hui.q("\\\"apache documentation\\\"~5", 1, 0, "stream_content_type_str:text/html", ["subject"])
    # .. plus filter(s) and facet fields
  ```
  """
  @spec q(
          binary,
          nil | integer,
          nil | integer,
          nil | binary | list(binary),
          nil | binary | list(binary),
          nil | binary
        ) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def q(keywords, rows \\ nil, start \\ nil, filters \\ nil, facet_fields \\ nil, sort \\ nil)

  def q(keywords, _, _, _, _, _) when is_nil_empty(keywords),
    do: {:error, %Hui.Error{reason: :einval}}

  def q(keywords, rows, start, filters, facet_fields, sort) do
    search(:default, keywords, rows, start, filters, facet_fields, sort)
  end

  @doc """
  Issue a keyword list or structured query to a specified Solr endpoint.

  ### Example - parameters 

  ```
    url = "http://localhost:8983/solr/collection"

    # a keyword list of arbitrary parameters
    Hui.search(url, q: "edinburgh", rows: 10)

    # supply a list of Hui structs for more complex query e.g. DisMax
    alias Hui.Query

    x = %Query.DisMax{q: "run", qf: "description^2.3 title", mm: "2<-25% 9<-3"}
    y = %Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
    z = %Query.Facet{field: ["cat", "author_str"], mincount: 1}
    Hui.search(url, [x, y, z])

    # SolrCloud query
    x = %Query.DisMax{q: "john"} 
    y = %Query.Common{collection: "library,commons", rows: 10, distrib: true, "shards.tolerant": true, "shards.info": true}
    Hui.search(url, [x,y])

    # With results highlighting (snippets)
    x = %Query.Standard{q: "features:photo"}
    y = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 }
    Hui.search(url, [x, y])
  ```

  ### Example - faceting

  ```
    alias Hui.Query

    range1 = %Query.FacetRange{range: "price", start: 0, end: 100, gap: 10, per_field: true}
    range2 = %Query.FacetRange{range: "popularity", start: 0, end: 5, gap: 1, per_field: true}

    x = %Query.DisMax{q: "ivan"}
    y = %Query.Facet{field: ["cat", "author_str"], mincount: 1, range: [range1, range2]}

    Hui.search(:default, [x, y])
  ```

  The above `Hui.search(:default, [x, y])` example issues a request that resulted in
  the following Solr response header showing the corresponding generated and encoded parameters.

  ```json
  "responseHeader" => %{
    "QTime" => 106,
    "params" => %{
      "f.popularity.facet.range.end" => "5",
      "f.popularity.facet.range.gap" => "1",
      "f.popularity.facet.range.start" => "0",
      "f.price.facet.range.end" => "100",
      "f.price.facet.range.gap" => "10",
      "f.price.facet.range.start" => "0",
      "facet" => "true",
      "facet.field" => ["cat", "author_str"],
      "facet.mincount" => "1",
      "facet.range" => ["price", "popularity"],
      "q" => "ivan"
    },
    "status" => 0,
    "zkConnected" => true
  }
  ```
  """
  @spec search(url, query) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def search(url, q) when is_list(q) or is_map(q), do: query(q, url)

  @doc """
  Convenience function for issuing various typical queries to a specified Solr endpoint.

  See `q/6`.
  """
  @spec search(
          url,
          binary,
          nil | integer,
          nil | integer,
          nil | binary | list(binary),
          nil | binary | list(binary),
          nil | binary
        ) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def search(
        url,
        keywords,
        rows \\ nil,
        start \\ nil,
        filters \\ nil,
        facet_fields \\ nil,
        sort \\ nil
      )

  def search(url, keywords, _, _, _, _, _) when is_nil_empty(keywords) or is_nil_empty(url),
    do: {:error, %Hui.Error{reason: :einval}}

  def search(url, keywords, rows, start, filters, facet_fields, sort) do
    x = %Query.Standard{q: keywords}
    y = %Query.Common{rows: rows, start: start, fq: filters, sort: sort}
    z = %Query.Facet{field: facet_fields}

    [x, y, z] |> query(url)
  end

  @doc """
  Issue a structured suggest query to a specified Solr endpoint.

  ### Example

  ```
    suggest_query = %Hui.Query.Suggest{q: "ha", count: 10, dictionary: "name_infix"}
    Hui.suggest(:library, suggest_query)
  ```
  """
  @spec suggest(url, Query.Suggest.t()) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def suggest(url, %Query.Suggest{} = q), do: q |> query(url)

  @doc """
  Convenience function for issuing a suggester query to a specified Solr endpoint.

  ### Example

  ```
    Hui.suggest(:autocomplete, "t")
    Hui.suggest(:autocomplete, "bo", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
  ```
  """
  @spec suggest(url, binary, nil | integer, nil | binary | list(binary), nil | binary) ::
          {:ok, Response.t()} | {:error, Hui.Error.t()}
  def suggest(url, q, count \\ nil, dictionaries \\ nil, context \\ nil)

  def suggest(url, q, _, _, _) when is_nil_empty(q) or is_nil_empty(url),
    do: {:error, %Hui.Error{reason: :einval}}

  def suggest(url, q, count, dictionaries, context) do
    %Query.Suggest{q: q, count: count, dictionary: dictionaries, cfq: context}
    |> query(url)
  end

  @doc """
  Updates or adds Solr documents to an index or collection.

  This function accepts documents as map (single or a list) and commits the docs
  to the index immediately by default - set `commit` to `false` for manual or
  auto commits later. 

  It can also operate in update struct and binary modes,
  the former uses the `t:Hui.Query.Update.t/0` struct
  while the latter acepts text containing any valid Solr update data or commands.

  An index/update handler endpoint should be specified through a `t:Hui.URL.t/0` struct
  or a URL config key. A content type header is required so that Solr knows the
  incoming data format (JSON, XML etc.) and can process data accordingly.

  ### Example - map, list and binary data

  ```
    # Index handler for JSON-formatted update
    headers = [{"Content-type", "application/json"}]
    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}

    # Solr docs in maps
    doc1 = %{
      "actors" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
      "desc" => "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
      "directed_by" => ["Ingmar Bergman"],
      "genre" => ["Drama", "Music"],
      "id" => "tt0077711",
      "initial_release_date" => "1978-10-08",
      "name" => "Autumn Sonata"
    }

    doc2 = %{
      "actors" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
      "desc" => "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
      "directed_by" => ["Ingmar Bergman"],
      "genre" => ["Drama", "Thriller"],
      "id" => "tt0060827",
      "initial_release_date" => "1967-09-21",
      "name" => "Persona"
    }

    Hui.update(url, doc1) # add a single doc
    Hui.update(url, [doc1, doc2]) # add a list of docs

    # Don't commit the docs e.g. mass ingestion when index handler is setup for autocommit. 
    Hui.update(url, [doc1, doc2], false)

    # Send to a configured endpoint
    Hui.update(:updater, [doc1, doc2])

    # Binary mode, add and commit a doc
    Hui.update(url, "{\\\"add\\\":{\\\"doc\\\":{\\\"name\\\":\\\"Blade Runner\\\",\\\"id\\\":\\\"tt0083658\\\",..}},\\\"commit\\\":{}}")

    # Binary mode, delete a doc via XML
    headers = [{"Content-type", "application/xml"}]
    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}
    Hui.update(url, "<delete><id>9780141981727</id></delete>")

  ```

  ### Example - `t:Hui.Query.Update.t/0` and other update options
  ```

    # url, doc1, doc2 from the above example
    ...

    # Hui.Query.Update struct command for updating and committing the docs to Solr within 5 seconds

    alias Hui.Query

    x = %Query.Update{doc: [doc1, doc2], commitWithin: 5000, overwrite: true}
    {status, resp} = Hui.update(url, x)

    # Delete the docs by IDs, with a URL key from configuration
    {status, resp} = Hui.update(:library_update, %Query.Update{delete_id: ["tt1316540", "tt1650453"]})

    # Commit and optimise index, keep max index segments at 10
    {status, resp} = Hui.update(url, %Query.Update{commit: true, waitSearcher: true, optimize: true, maxSegments: 10})

    # Commit index, expunge deleted docs
    {status, resp} = Hui.update(url, %Query.Update{commit: true, expungeDeletes: true})
  ```
  """
  @spec update(url, update_query, boolean) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def update(url, q, commit \\ true) do
    cond do
      is_binary(q) -> q
      is_map(q) and Map.has_key?(q, :__struct__) -> q
      is_map(q) or is_list(q) -> %Query.Update{doc: q, commit: commit}
    end
    |> query(url, :post)
  end

  @doc """
  Deletes Solr documents.

  This function accepts a single or list of IDs and immediately delete the corresponding
  documents from the Solr index (commit by default).

  An index/update handler endpoint should be specified through a `t:Hui.URL.t/0` struct
  or a URL config key. A JSON content type header for the URL is required so that Solr knows the
  incoming data format and can process data accordingly.

  ### Example
  ```
    # Index handler for JSON-formatted update
    headers = [{"Content-type", "application/json"}]
    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}

    Hui.delete(url, "tt2358891") # delete a single doc
    Hui.delete(url, ["tt2358891", "tt1602620"]) # delete a list of docs

    Hui.delete(url, ["tt2358891", "tt1602620"], false) # delete without immediate commit
  ```
  """
  @spec delete(binary | Hui.URL.t(), binary | list(binary), boolean) ::
          {:ok, Response.t()} | {:error, Hui.Error.t()}

  def delete(url, ids, commit \\ true) when is_binary(ids) or is_list(ids) do
    %Query.Update{delete_id: ids, commit: commit}
    |> query(url, :post)
  end

  @doc """
  Deletes Solr documents by filter queries.

  This function accepts a single or list of filter queries and immediately delete the corresponding
  documents from the Solr index (commit by default).

  An index/update handler endpoint should be specified through a `t:Hui.URL.t/0` struct
  or a URL config key. A JSON content type header for the URL is required so that Solr knows the
  incoming data format and can process data accordingly.

  ### Example
  ```
    # Index handler for JSON-formatted update
    headers = [{"Content-type", "application/json"}]
    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}

    Hui.delete_by_query(url, "name:Persona") # delete with a single filter
    Hui.delete_by_query(url, ["genre:Drama", "name:Persona"]) # delete with a list of filters
  ```
  """
  @spec delete_by_query(binary | Hui.URL.t(), binary | list(binary), boolean) ::
          {:ok, Response.t()} | {:error, Hui.Error.t()}

  def delete_by_query(url, q, commit \\ true) when is_binary(q) or is_list(q) do
    %Query.Update{delete_query: q, commit: commit}
    |> query(url, :post)
  end

  @doc """
  Commit any added or deleted Solr documents to the index.

  This provides a (separate) mechanism to commit previously added or deleted documents to
  Solr index for different updating and index maintenance scenarios. By default, the commit
  waits for a new Solr searcher to be regenerated, so that the commit result is made available
  for search.

  An index/update handler endpoint should be specified through a `t:Hui.URL.t/0` struct
  or a URL config key. A JSON content type header for the URL is required so that Solr knows the
  incoming data format and can process data accordingly.

  ### Example
  ```
    # Index handler for JSON-formatted update
    headers = [{"Content-type", "application/json"}]
    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}

    Hui.commit(url) # commits, make new docs available for search
    Hui.commit(url, false) # commits op only, new docs to be made available later
  ```

  Use `t:Hui.Query.Update.t/0` struct for other types of commit and index optimisation, e.g. expunge deleted docs to
  physically remove docs from the index, which could be a system-intensive operation.
  """
  @spec commit(binary | Hui.URL.t(), boolean) :: {:ok, Response.t()} | {:error, Hui.Error.t()}
  def commit(url, wait_searcher \\ true) do
    %Query.Update{commit: true, waitSearcher: wait_searcher}
    |> query(url, :post)
  end

  defp query(q, url, method \\ :get) do
    {status, url} = parse_url(url)

    case {status, method} do
      {:ok, :get} -> _parse_resp(Query.get(url, q))
      {:ok, :post} -> _parse_resp(Query.post(url, q))
      {:error, _} -> {:error, @error_nxdomain}
    end
  end

  defp parse_url(%Hui.URL{} = url), do: {:ok, url}
  defp parse_url(url) when is_atom(url), do: Hui.URL.configured_url(url)

  defp parse_url(url) when is_binary(url) do
    uri = URI.parse(url)

    if uri.scheme != nil && uri.host =~ ~r/./ do
      {:ok, %Hui.URL{url: url}}
    else
      {:error, @error_nxdomain}
    end
  end

  defp parse_url(_), do: {:error, @error_nxdomain}

  defp _parse_resp({:error, %HTTPoison.Error{id: _, reason: reason}}),
    do: {:error, %Hui.Error{reason: reason}}

  defp _parse_resp(resp), do: resp
end
