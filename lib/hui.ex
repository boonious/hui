defmodule Hui do
  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for
  [Solr enterprise search platform](http://lucene.apache.org/solr/).

  ### Usage

  - Searching Solr: `search/3`
  - Updating: `update/3`, `delete/3`, `delete_by_query/3`, `commit/2`
  - Other: `suggest/2`, `suggest/5`
  - Admin: `metrics/2`, `ping/1`
  - [README](https://hexdocs.pm/hui/readme.html#usage)
  """

  alias Hui.Http
  alias Hui.Query

  @client Hui.Http.Client.impl()

  @type endpoint :: Http.endpoint()
  @type query :: Http.query()
  @type update_query :: Http.update_query()

  @type http_response :: Http.response()

  @doc """
  Issue a keyword list or structured query to a Solr endpoint.

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
    y = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3}
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

  ### URLs, Headers, Options

  HTTP headers and client options for a specific endpoint may also be
  included in the a `{url, headers, options}` tuple where:

  - `url` is a typical Solr endpoint that includes a request handler
  - `headers`: a tuple list of [HTTP headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)
  - `options`: a keyword list of configured http client options such as [Erlang httpc](https://erlang.org/doc/man/httpc.html#request-4),
   [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.Request.html), e.g.
  `timeout`, `recv_timeout`, `max_redirect`

  If `HTTPoison` is used, advanced HTTP options such as the use of connection pools
  may also be specified via `options`.
  """
  @spec search(endpoint, query, module) :: http_response
  defdelegate search(endpoint, query, client), to: Http, as: :get

  @doc """
  Issue a structured suggest query to a specified Solr endpoint.

  ### Example

  ```
    # :library is a configured endpoint
    suggest_query = %Hui.Query.Suggest{q: "ha", count: 10, dictionary: "name_infix"}
    Hui.suggest(:library, suggest_query)
  ```
  """
  @spec suggest(endpoint, Query.Suggest.t()) :: http_response
  defdelegate suggest(endpoint, query), to: Hui.Suggest

  @doc """
  Convenience function for issuing a suggester query to a specified Solr endpoint.

  ### Example

  ```
    # :autocomplete is a configured endpoint
    Hui.suggest(:autocomplete, "t")
    Hui.suggest(:autocomplete, "bo", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
  ```
  """
  @spec suggest(endpoint, binary, nil | integer, nil | binary | list(binary), nil | binary) :: http_response
  defdelegate suggest(endpoint, q, count, dictionaries, context), to: Hui.Suggest

  @doc """
  Updates or adds Solr documents to an index or collection.

  This function accepts documents as map (single or a list) and commits the docs
  to the index immediately by default - set `commit` to `false` for manual or
  auto commits later.

  It can also operate in update struct and binary modes,
  the former uses the `t:Hui.Query.Update.t/0` struct
  while the latter acepts text containing any valid Solr update data or commands.

  An index/update handler endpoint should be specified through a URL string or
  {url, headers, options} tuple for headers and HTTP client options specification.

  A "content-type" request header is required so that Solr knows the
  incoming data format (JSON, XML etc.) and can process data accordingly.

  ### Example - map, list and binary data

  ```
    # Index handler for JSON-formatted update
    headers = [{"content-type", "application/json"}]
    endpoint = {"http://localhost:8983/solr/collection/update", headers}

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

    Hui.update(endpoint, doc1) # add a single doc
    Hui.update(endpoint, [doc1, doc2]) # add a list of docs

    # Don't commit the docs e.g. mass ingestion when index handler is setup for autocommit.
    Hui.update(endpoint, [doc1, doc2], false)

    # Send to a configured endpoint
    Hui.update(:updater, [doc1, doc2])

    # Binary mode, add and commit a doc
    Hui.update(endpoint, "{\\\"add\\\":{\\\"doc\\\":{\\\"name\\\":\\\"Blade Runner\\\",\\\"id\\\":\\\"tt0083658\\\",..}},\\\"commit\\\":{}}")

    # Binary mode, delete a doc via XML
    headers = [{"content-type", "application/xml"}]
    endpoint = {"http://localhost:8983/solr/collection/update", headers}
    Hui.update(endpoint, "<delete><id>9780141981727</id></delete>")

  ```

  ### Example - `t:Hui.Query.Update.t/0` and other update options
  ```

    # endpoint, doc1, doc2 from the above example
    ...

    # Hui.Query.Update struct command for updating and committing the docs to Solr within 5 seconds

    alias Hui.Query

    x = %Query.Update{doc: [doc1, doc2], commitWithin: 5000, overwrite: true}
    {status, resp} = Hui.update(endpoint, x)

    # Delete the docs by IDs, with a URL key from configuration
    {status, resp} = Hui.update(:library_update, %Query.Update{delete_id: ["tt1316540", "tt1650453"]})

    # Commit and optimise index, keep max index segments at 10
    {status, resp} = Hui.update(endpoint, %Query.Update{commit: true, waitSearcher: true, optimize: true, maxSegments: 10})

    # Commit index, expunge deleted docs
    {status, resp} = Hui.update(endpoint, %Query.Update{commit: true, expungeDeletes: true})
  ```
  """
  @spec update(endpoint, update_query) :: http_response
  defdelegate update(endpoint, query), to: Http, as: :post

  @spec update(endpoint, update_query, boolean, module) :: http_response
  defdelegate update(endpoint, query, commit, client), to: Http, as: :post

  @doc """
  Deletes Solr documents.

  This function accepts a single or list of IDs and immediately delete the corresponding
  documents from the Solr index (commit by default).

  An index/update handler endpoint should be specified through a URL string
  or {url, headers, options} tuple.

  A JSON "content-type" request header is required so that Solr knows the
  incoming data format and can process data accordingly.

  ### Example
  ```
    # Index handler for JSON-formatted update
    headers = [{"content-type", "application/json"}]
    endpoint = {"http://localhost:8983/solr/collection/update", headers}

    Hui.delete_by_id(endpoint, "tt2358891") # delete a single doc
    Hui.delete_by_id(endpoint, ["tt2358891", "tt1602620"]) # delete a list of docs

    Hui.delete_by_id(endpoint, ["tt2358891", "tt1602620"], false) # delete without immediate commit
  ```
  """
  @spec delete_by_id(endpoint, binary | list(binary), boolean, module) :: http_response
  def delete_by_id(endpoint, ids, commit \\ true, client \\ @client) when is_binary(ids) or is_list(ids) do
    Http.post(endpoint, %Query.Update{delete_id: ids, commit: commit}, commit, client)
  end

  # coveralls-ignore-start
  @deprecated "Use delete_by_id/3 instead"
  def delete(endpoint, ids, commit \\ true) when is_binary(ids) or is_list(ids) do
    Http.post(endpoint, %Query.Update{delete_id: ids, commit: commit})
  end

  # coveralls-ignore-stop

  @doc """
  Deletes Solr documents by filter queries.

  This function accepts a single or list of filter queries and immediately delete the corresponding
  documents from the Solr index (commit by default).

  An index/update handler endpoint should be specified through a URL string
  or {url, headers, options} tuple.

  A JSON "content-type" request header is required so that Solr knows the
  incoming data format and can process data accordingly.

  ### Example
  ```
    # Index handler for JSON-formatted update
    headers = [{"content-type", "application/json"}]
    endpoint = {"http://localhost:8983/solr/collection", headers}

    Hui.delete_by_query(endpoint, "name:Persona") # delete with a single filter
    Hui.delete_by_query(endpoint, ["genre:Drama", "name:Persona"]) # delete with a list of filters
  ```
  """
  @spec delete_by_query(endpoint, binary | list(binary), boolean) :: http_response
  def delete_by_query(endpoint, q, commit \\ true, client \\ @client) when is_binary(q) or is_list(q) do
    Http.post(endpoint, %Query.Update{delete_query: q, commit: commit}, commit, client)
  end

  @doc """
  Commit any added or deleted Solr documents to the index.

  This provides a (separate) mechanism to commit previously added or deleted documents to
  Solr index for different updating and index maintenance scenarios. By default, the commit
  waits for a new Solr searcher to be regenerated, so that the commit result is made available
  for search.

  An index/update handler endpoint should be specified through a URL string
  or {url, headers, options} tuple.

  A JSON "content-type" request header is required so that Solr knows the
  incoming data format and can process data accordingly.

  ### Example
  ```
    # Index handler for JSON-formatted update
    headers = [{"content-type", "application/json"}]
    endpoint = {"http://localhost:8983/solr/collection", headers}

    Hui.commit(endpoint) # commits, make new docs available for search
    Hui.commit(endpoint, false) # commits op only, new docs to be made available later
  ```

  Use `t:Hui.Query.Update.t/0` struct for other types of commit and index optimisation, e.g. expunge deleted docs to
  physically remove docs from the index, which could be a system-intensive operation.
  """
  @spec commit(endpoint, boolean) :: http_response
  def commit(endpoint, wait_searcher \\ true, client \\ @client) do
    Http.post(endpoint, %Query.Update{commit: true, waitSearcher: wait_searcher}, true, client)
  end

  @doc """
  Retrieves metrics data from the Solr admin API.

  ### Example
  ```
    endpoint = {"http://localhost:8983/solr/admin/metrics", [{"content-type", "application/json"}]}
    Hui.metrics(endpoint, group: "core", type: "timer", property: ["mean_ms", "max_ms", "p99_ms"])
  ```
  """
  @spec metrics(endpoint, keyword) :: http_response
  defdelegate metrics(endpoint, options), to: Hui.Admin

  @doc """
  Ping a given endpoint.

  ### Example
  ```
    # ping a configured atomic endpoint
    Hui.ping(:gettingstarted)

    # directly ping a binary URL
    Hui.ping("http://localhost:8983/solr/gettingstarted/admin/ping")
  ```

  Successful ping returns a `{:pong, qtime}` tuple, whereas failure gets a `:pang` response.
  """
  @spec ping(binary() | atom()) :: {:pong, integer} | :pang
  defdelegate ping(endpoint), to: Hui.Admin

  @doc """
  Ping a given endpoint with options.

  Raw HTTP response is returned when options such as `wt`, `distrib` is provided:
  ```
    Hui.ping(:gettingstarted, wt: "xml", distrib: false)
    # -> returns {:ok, %Hui.HTTP{body: "raw HTTP response", status: 200, ..}}
  ```
  """
  @spec ping(binary() | atom(), keyword) :: http_response
  defdelegate ping(endpoint, options), to: Hui.Admin
end
