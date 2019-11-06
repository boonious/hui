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
  alias Hui.Request # deprecated

  alias Hui.Query

  @type url :: binary | atom | Hui.URL.t
  @type query :: Hui.Query.solr_query()

  @error_nxdomain %Hui.Error{reason: :nxdomain} # invalid / non existing host or domain

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
  @spec q(query) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  # deprecated - to be removed in a future version
  def q(%Hui.Q{} = query), do: Request.search(:default, [query])

  def q(query) when is_list(query), do: search(:default, query)

  @doc """
  Issue a keyword list or structured query to the default Solr endpoint, raising an exception in case of failure.

  See `q/1`.
  """
  @spec q!(Hui.Q.t | Request.query_struct_list | Keyword.t) :: HTTPoison.Response.t
  # deprecated - to be removed in a future version
  def q!(%Hui.Q{} = query), do: Request.search(:default, true, [query])

  def q!(query) when is_list(query), do: search!(:default, query)

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
  @spec q(binary, nil|integer, nil|integer, nil|binary|list(binary), nil|binary|list(binary), nil|binary)
        :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def q(keywords, rows \\ nil, start \\ nil, filters \\ nil, facet_fields \\ nil, sort \\ nil)
  def q(keywords, _, _, _, _, _) when is_nil_empty(keywords), do: {:error, %Hui.Error{reason: :einval}}

  def q(keywords, rows, start, filters, facet_fields, sort) do
    search(:default, keywords, rows, start, filters, facet_fields, sort)
  end

  @doc """
  Convenience function for issuing various typical queries to the default Solr endpoint,
  raise an exception in case of failure.
  """
  @spec q!(binary, nil|integer, nil|integer, nil|binary|list(binary), nil|binary|list(binary), nil|binary)
        :: HTTPoison.Response.t
  def q!(keywords, rows \\ nil, start \\ nil, filters \\ nil, facet_fields \\ nil, sort \\ nil)
  def q!(keywords, _, _, _, _, _) when is_nil_empty(keywords), do: raise %Hui.Error{reason: :einval}
  def q!(keywords, rows, start, filters, facet_fields, sort) do
    search!(:default, keywords, rows, start, filters, facet_fields, sort)
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
  @spec search(url, query) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  # deprecated - will be removed in a future version
  def search(url, %Hui.Q{} = query), do: Request.search(url, [query])

  def search(url, query) when is_list(query) or is_map(query), do: _search(url, query)

  defp _search(url, query) do
    {status, url_struct} = parse_url(url)
    if status == :ok, do: _parse_resp(Query.get(url_struct, query)), else: {:error, @error_nxdomain}
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
  
  defp _parse_resp({:error, %HTTPoison.Error{id: _, reason: reason}}), do: {:error, %Hui.Error{reason: reason}}
  defp _parse_resp(resp), do: resp

  @doc """
  Issue a keyword list or structured query to a specified Solr endpoint, raise an exception in case of failure.

  See `search/2`.
  """
  @spec search!(url, Hui.Q.t | Request.query_struct_list | Keyword.t) :: HTTPoison.Response.t
  # deprecated - will be removed in a future version
  def search!(url, %Hui.Q{} = query), do: Request.search(url, true, [query])

  def search!(url, query) when is_list(query) or is_map(query), do: _search!(url, query)

  defp _search!(url, query) do
    {status, url_struct} = parse_url(url)
    if status == :ok, do: Query.get!(url_struct, query), else: raise @error_nxdomain
  end

  @doc """
  Convenience function for issuing various typical queries to a specified Solr endpoint.

  See `q/6`.
  """
  @spec search(url, binary, nil|integer, nil|integer, nil|binary|list(binary), nil|binary|list(binary), nil|binary)
        :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def search(url, keywords, rows \\ nil, start \\ nil, filters \\ nil, facet_fields \\ nil, sort \\ nil)
  def search(url, keywords, _, _, _, _, _) when is_nil_empty(keywords) or is_nil_empty(url), do: {:error, %Hui.Error{reason: :einval}}
  def search(url, keywords, rows, start, filters, facet_fields, sort) do
    x = %Query.Standard{q: keywords} 
    y = %Query.Common{rows: rows, start: start, fq: filters, sort: sort} 
    z = %Query.Facet{field: facet_fields}

    _search(url, [x,y,z])
  end

  @doc """
  Convenience function for issuing various typical queries to a specified Solr endpoint,
  raise an exception in case of failure.

  See `q/6`.
  """
  @spec search!(url, binary, nil|integer, nil|integer, nil|binary|list(binary), nil|binary|list(binary), nil|binary)
        :: HTTPoison.Response.t
  def search!(url, keywords, rows \\ nil, start \\ nil, filters \\ nil, facet_fields \\ nil, sort \\ nil)
  def search!(url, keywords, _, _, _, _, _) when is_nil_empty(keywords) or is_nil_empty(url), do: raise %Hui.Error{reason: :einval}
  def search!(url, keywords, rows, start, filters, facet_fields, sort) do
    x = %Query.Standard{q: keywords} 
    y = %Query.Common{rows: rows, start: start, fq: filters, sort: sort} 
    z = %Query.Facet{field: facet_fields}

    _search!(url, [x,y,z])
  end

  @doc false
  @spec spellcheck(url, Query.SpellCheck.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  @deprecated "Please use search/2 with Hui.Query.SpellCheck query struct."
  def spellcheck(url, %Hui.Sp{} = query), do: Request.search(url, [query])

  @doc false
  @spec spellcheck!(url, Hui.Sp.t) :: HTTPoison.Response.t
  @deprecated "Please use search!/2 with Hui.Query.SpellCheck struct."
  def spellcheck!(url, %Hui.Sp{} = query), do: Request.search(url, true, [query])

  @doc false
  @spec spellcheck(url, Hui.Sp.t, Hui.Q.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  @deprecated "Please use search/2 with Hui.Query.SpellCheck struct."
  def spellcheck(url, %Hui.Sp{} = query_sp, %Hui.Q{} = query), do: Request.search(url, [query, query_sp])

  @doc false
  @spec spellcheck!(url, Hui.Sp.t, Hui.Q.t) :: HTTPoison.Response.t
  @deprecated "Please use search/2 with Hui.Query.SpellCheck struct."
  def spellcheck!(url, %Hui.Sp{} = query_sp, %Hui.Q{} = query), do: Request.search(url, true, [query, query_sp])

  @doc """
  Issue a structured suggest query to a specified Solr endpoint.

  ### Example

  ```
    suggest_query = %Hui.Query.Suggest{q: "ha", count: 10, dictionary: "name_infix"}
    Hui.suggest(:library, suggest_query)
  ```
  """
  @spec suggest(url, Query.Suggest.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def suggest(url, %Query.Suggest{} = query), do: search(url, query)

  @doc """
  Issue a structured suggester query to a specified Solr endpoint, raise an exception in case of failure.
  """
  @spec suggest!(url, Query.Suggest.t) :: HTTPoison.Response.t
  def suggest!(url, %Query.Suggest{} = query), do: search!(url, query)

  @doc """
  Convenience function for issuing a suggester query to a specified Solr endpoint.

  ### Example

  ```
    Hui.suggest(:autocomplete, "t")
    Hui.suggest(:autocomplete, "bo", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
  ```
  """
  @spec suggest(url, binary, nil|integer, nil|binary|list(binary), nil|binary)
        :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def suggest(url, q, count \\ nil, dictionaries \\ nil, context \\ nil)
  def suggest(url, q, _, _, _) when is_nil_empty(q) or is_nil_empty(url), do: {:error, %Hui.Error{reason: :einval}}
  def suggest(url, q, count, dictionaries, context) do
    query = %Query.Suggest{q: q, count: count, dictionary: dictionaries, cfq: context}
    search(url, query)
  end

  @doc """
  Convenience function for issuing a suggester query to a specified Solr endpoint,
  raise an exception in case of failure.
  """
  @spec suggest!(url, binary, nil|integer, nil|binary|list(binary), nil|binary)
        :: HTTPoison.Response.t
  def suggest!(url, q, count \\ nil, dictionaries \\ nil, context \\ nil)
  def suggest!(url, q, _, _, _) when is_nil_empty(q) or is_nil_empty(url), do: raise %Hui.Error{reason: :einval}
  def suggest!(url, q, count, dictionaries, context) do
    query = %Query.Suggest{q: q, count: count, dictionary: dictionaries, cfq: context}
    search!(url, query)
  end

  @doc false
  @spec mlt(url, Hui.Q.t, Hui.M.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  @deprecated "Please use search/2 with Hui.Query.MoreLikeThis struct."
  def mlt(url, %Hui.Q{} = query_struct, %Hui.M{} = mlt_query_struct), do: Request.search(url, [query_struct, mlt_query_struct])

  @doc false
  @deprecated "Please use search/2 with Hui.Query.MoreLikeThis struct."
  @spec mlt!(url, Hui.Q.t, Hui.M.t) :: HTTPoison.Response.t
  def mlt!(url, %Hui.Q{} = query_struct, %Hui.M{} = mlt_query_struct), do: Request.search(url, true, [query_struct, mlt_query_struct])

  @doc """
  Updates or adds Solr documents to an index or collection.

  This function accepts documents as map (single or a list) and commits the docs
  to the index immediately by default - set `commit` to `false` for manual or
  auto commits later. It can also operate in binary mode, accepting
  text containing any valid Solr update data or commands.

  An index/update handler endpoint should be specified through a `t:Hui.URL.t/0` struct
  or a URL config key. A content type header is required so that Solr knows the
  incoming data format (JSON, XML etc.) and can process data accordingly.

  ### Example

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

  See `Hui.Request.update/3` for more advanced update options.
  """
  @spec update(binary | Hui.URL.t, binary | map | list(map), boolean) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def update(url, docs, commit \\ true)
  def update(url, docs, _commit) when is_binary(docs), do: Request.update(url, docs)
  def update(url, docs, commit) when is_map(docs) or is_list(docs), do: Request.update(url, %Hui.U{doc: docs, commit: commit})

  @doc """
  Updates or adds Solr documents to an index or collection, raise an exception in case of failure.
  """
  @spec update!(binary | Hui.URL.t, binary | map | list(map), boolean) :: HTTPoison.Response.t
  def update!(url, docs, commit \\ true)
  def update!(url, docs, _commit) when is_binary(docs), do: Request.update(url, true, docs)
  def update!(url, docs, commit) when is_map(docs) or is_list(docs), do: Request.update(url, true, %Hui.U{doc: docs, commit: commit})

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
  @spec delete(binary | Hui.URL.t, binary | list(binary), boolean) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def delete(url, ids, commit \\ true)
  def delete(url, ids, commit) when is_binary(ids) or is_list(ids), do: Request.update(url, %Hui.U{delete_id: ids, commit: commit})

  @doc """
  Deletes Solr documents, raise an exception in case of failure.
  """
  @spec delete!(binary | Hui.URL.t, binary | list(binary), boolean) :: HTTPoison.Response.t
  def delete!(url, ids, commit \\ true)
  def delete!(url, ids, commit) when is_binary(ids) or is_list(ids), do: Request.update(url, true, %Hui.U{delete_id: ids, commit: commit})

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
  @spec delete_by_query(binary | Hui.URL.t, binary | list(binary), boolean) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def delete_by_query(url, queries, commit \\ true)
  def delete_by_query(url, queries, commit) when is_binary(queries) or is_list(queries), do: Request.update(url, %Hui.U{delete_query: queries, commit: commit})

  @doc """
  Deletes Solr documents by filter queries, raise an exception in case of failure.
  """
  @spec delete_by_query!(binary | Hui.URL.t, binary | list(binary), boolean) :: HTTPoison.Response.t
  def delete_by_query!(url, queries, commit \\ true)
  def delete_by_query!(url, queries, commit) when is_binary(queries) or is_list(queries), do: Request.update(url, %Hui.U{delete_query: queries, commit: commit})

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

  Use `Hui.Request.update/3` for other types of commit and index optimisation, e.g. expunge deleted docs to
  physically remove docs from the index, which could be a system-intensive operation.
  """
  @spec commit(binary | Hui.URL.t, boolean) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def commit(url, wait_searcher \\ true)
  def commit(url, wait_searcher), do: Request.update(url, %Hui.U{commit: true, waitSearcher: wait_searcher})

  @doc """
  Commit any added or deleted Solr documents to the index, raise an exception in case of failure.
  """
  @spec commit!(binary | Hui.URL.t, boolean) :: HTTPoison.Response.t
  def commit!(url, wait_searcher \\ true)
  def commit!(url, wait_searcher), do: Request.update(url, %Hui.U{commit: true, waitSearcher: wait_searcher})

end
