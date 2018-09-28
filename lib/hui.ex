defmodule Hui do
  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).

  ### Usage
  
  - Searching Solr: `q/1`, `q/6`, `search/2`, `search/7`
  - Other: `suggest/2`, `suggest/5`, `spellcheck/3`
  - [More details](https://hexdocs.pm/hui/readme.html#usage)
  """

  import Hui.Guards
  alias Hui.Request

  @type url :: binary | atom | Hui.URL.t

  @doc """
  Issue a keyword list or structured query to the default Solr endpoint.

  The query can either be a keyword list, a standard query struct (`Hui.Q`)
  or a struct list. This function is a shortcut for `search/2` with `:default` as URL key.

  ### Example

  ```
    Hui.q(%Hui.Q{q: "loch", fq: ["type:illustration", "format:image/jpeg"]})
    Hui.q(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])

    # supply a list of Hui structs for more complex query, e.g. faceting
    Hui.q( [%Hui.Q{q: "author:I*", rows: 5}, %Hui.F{field: ["cat", "author_str"], mincount: 1}])

    # DisMax
    x = %Hui.D{q: "run", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3}
    y = %Hui.Q{rows: 10, start: 10, fq: ["edited:true"]}
    z = %Hui.F{field: ["cat", "author_str"], mincount: 1}
    Hui.q([x, y, z])

  ```
  """
  @spec q(Hui.Q.t | Request.query_struct_list | Keyword.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def q(%Hui.Q{} = query), do: search(:default, [query])
  def q(query) when is_list(query), do: search(:default, query)

  @doc """
  Issue a keyword list or structured query to the default Solr endpoint, raising an exception in case of failure.

  See `q/1`.
  """
  @spec q!(Hui.Q.t | Request.query_struct_list | Keyword.t) :: HTTPoison.Response.t
  def q!(%Hui.Q{} = query), do: Request.search(:default, true, [query])
  def q!(query) when is_list(query), do: Request.search(:default, true, query)

  @doc """
  Issue a standard structured query with faceting request to the default Solr endpoint.
  """
  @deprecated "Use q/1 instead, supply a list of structs as parameter"
  @spec q(Hui.Q.t, Hui.F.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def q(%Hui.Q{} = query_struct, %Hui.F{} = facet_struct), do: search(:default, [query_struct, facet_struct])

  @doc """
  Issue a standard structured query with faceting request to the default Solr endpoint, raise an exception in case of failure.
  """
  @deprecated "Use q!/1 instead, supply a list of structs as parameter"
  @spec q!(Hui.Q.t, Hui.F.t) :: HTTPoison.Response.t
  def q!(%Hui.Q{} = query_struct, %Hui.F{} = facet_struct), do: Request.search(:default, true, [query_struct, facet_struct])

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
    q = %Hui.Q{q: keywords, rows: rows, start: start, fq: filters, sort: sort}
    f = %Hui.F{field: facet_fields}
    Request.search(:default, false, [q,f])
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
    q = %Hui.Q{q: keywords, rows: rows, start: start, fq: filters, sort: sort}
    f = %Hui.F{field: facet_fields}
    Request.search(:default, true, [q,f])
  end

  @doc """
  Issue a keyword list or structured query to a specified Solr endpoint.
  
  ### Example - parameters 
  
  ```
    # structured query with permitted or qualified Solr parameters
    url = "http://localhost:8983/solr/collection"
    Hui.search(url, %Hui.Q{q: "loch", rows: 5, wt: "xml", fq: ["type:illustration", "format:image/jpeg"]})
    # a keyword list of arbitrary parameters
    Hui.search(url, q: "edinburgh", rows: 10)

    # supply a list of Hui structs for more complex query e.g. DisMax
    x = %Hui.D{q: "run", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3}
    y = %Hui.Q{rows: 10, start: 10, fq: ["edited:true"]}
    z = %Hui.F{field: ["cat", "author_str"], mincount: 1}
    Hui.search(url, [x, y, z])

    # SolrCloud query
    x = %Hui.Q{q: "john", collection: "library,commons", rows: 10, distrib: true, "shards.tolerant": true, "shards.info": true}
    Hui.search(url, x)

    # Add results highlighting (snippets) with `Hui.H`
    x = %Hui.Q{q: "features:photo", rows: 5}
    y = %Hui.H{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 }
    Hui.search(url, [x, y])
  ```

  ### Example - URL endpoints

  ```
    url = "http://localhost:8983/solr/collection"
    Hui.search(url, q: "loch")

    url = :library
    Hui.search(url, q: "edinburgh", rows: 10)

    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
    Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")

  ```

  See `Hui.URL.configured_url/1` and `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  `t:Hui.URL.t/0` struct also enables HTTP headers and HTTPoison options to be specified
  in keyword lists. HTTPoison options provide further controls for a request, e.g. `timeout`, `recv_timeout`,
  `max_redirect`, `params` etc.

  ```
    # setting up a header and a 10s receiving connection timeout
    url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
    Hui.search(url, q: "solr rocks")
  ```

  See `HTTPoison.request/5` for more details on HTTPoison options.

  ### Example - faceting

  ```
    x = %Hui.Q{q: "author:I*", rows: 5}
    y = %Hui.F{field: ["cat", "author_str"], mincount: 1}
    Hui.search(:library, [x, y])

    # more elaborated faceting query
    x = %Hui.Q{q: "*", rows: 5}
    range1 = %Hui.F.Range{range: "price", start: 0, end: 100, gap: 10, per_field: true}
    range2 = %Hui.F.Range{range: "popularity", start: 0, end: 5, gap: 1, per_field: true}
    y = %Hui.F{field: ["cat", "author_str"], mincount: 1, range: [range1, range2]}
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
      "q" => "*",
      "rows" => "5"
    },
    "status" => 0,
    "zkConnected" => true
  }
  ```
  """
  @spec search(url, Hui.Q.t | Request.query_struct_list | Keyword.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def search(url, %Hui.Q{} = query), do: Request.search(url, [query])
  def search(url, query) when is_list(query), do: Request.search(url, query)

  @doc """
  Issue a keyword list or structured query to a specified Solr endpoint, raise an exception in case of failure.

  See `search/2`.
  """
  @spec search!(url, Hui.Q.t | Request.query_struct_list | Keyword.t) :: HTTPoison.Response.t
  def search!(url, %Hui.Q{} = query), do: Request.search(url, true, [query])
  def search!(url, query) when is_list(query), do: Request.search(url, true, query)

  @doc """
  Issue a standard structured query with faceting request to a specified Solr endpoint.
  """
  @deprecated "Use search/2 instead, supply a list of structs as parameter"
  @spec search(url, Hui.Q.t, Hui.F.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def search(url, %Hui.Q{} = query, %Hui.F{} = facet), do: Request.search(url, [query, facet])

  @doc """
  Issue a standard structured query with faceting request to a specified Solr endpoint,
  raise an exception in case of failure.
  """
  @deprecated "Use search!/2 instead, supply a list of structs as parameter"
  @spec search!(url, Hui.Q.t, Hui.F.t) :: HTTPoison.Response.t
  def search!(url, %Hui.Q{} = query, %Hui.F{} = facet), do: Request.search(url, true, [query, facet])

  @doc """
  Convenience function for issuing various typical queries to a specified Solr endpoint.

  See `q/6`.
  """
  @spec search(url, binary, nil|integer, nil|integer, nil|binary|list(binary), nil|binary|list(binary), nil|binary)
        :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def search(url, keywords, rows \\ nil, start \\ nil, filters \\ nil, facet_fields \\ nil, sort \\ nil)
  def search(url, keywords, _, _, _, _, _) when is_nil_empty(keywords) or is_nil_empty(url), do: {:error, %Hui.Error{reason: :einval}}
  def search(url, keywords, rows, start, filters, facet_fields, sort) do
    q = %Hui.Q{q: keywords, rows: rows, start: start, fq: filters, sort: sort}
    f = %Hui.F{field: facet_fields}
    Request.search(url, false, [q,f])
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
    q = %Hui.Q{q: keywords, rows: rows, start: start, fq: filters, sort: sort}
    f = %Hui.F{field: facet_fields}
    Request.search(url, true, [q,f])
  end

  @doc """
  Issue a spell checking query to a specified Solr endpoint.

  ### Example

  ```
    spellcheck_query = %Hui.Sp{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}
    Hui.spellcheck(:library, spellcheck_query)
  ```
  """
  @spec spellcheck(url, Hui.Sp.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def spellcheck(url, %Hui.Sp{} = spellcheck_query_struct), do: Request.search(url, [spellcheck_query_struct])

  @doc """
  Issue a spell checking query to a specified Solr endpoint, raise an exception in case of failure.
  """
  @spec spellcheck!(url, Hui.Sp.t) :: HTTPoison.Response.t
  def spellcheck!(url, %Hui.Sp{} = spellcheck_query_struct), do: Request.search(url, true, [spellcheck_query_struct])

  @doc """
  Issue a spell checking query to a specified Solr endpoint.
  """
  @spec spellcheck(url, Hui.Sp.t, Hui.Q.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def spellcheck(url, %Hui.Sp{} = spellcheck_query_struct, %Hui.Q{} = query_struct), do: Request.search(url, [query_struct, spellcheck_query_struct])

  @doc """
  Issue a spell checking query to a specified Solr endpoint, raise an exception in case of failure.
  """
  @spec spellcheck!(url, Hui.Sp.t, Hui.Q.t) :: HTTPoison.Response.t
  def spellcheck!(url, %Hui.Sp{} = spellcheck_query_struct, %Hui.Q{} = query_struct), do: Request.search(url, true, [query_struct, spellcheck_query_struct])

  @doc """
  Issue a structured suggester query to a specified Solr endpoint.

  ### Example

  ```
    suggest_query = %Hui.S{q: "ha", count: 10, dictionary: "name_infix"}
    Hui.suggest(:library, suggest_query)
  ```
  """
  @spec suggest(url, Hui.S.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def suggest(url, %Hui.S{} = suggest_query_struct), do: Request.search(url, [suggest_query_struct])

  @doc """
  Issue a structured suggester query to a specified Solr endpoint, raise an exception in case of failure.
  """
  @spec suggest!(url, Hui.S.t) :: HTTPoison.Response.t
  def suggest!(url, %Hui.S{} = suggest_query_struct), do: Request.search(url, true, [suggest_query_struct])

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
    suggest_query = %Hui.S{q: q, count: count, dictionary: dictionaries, cfq: context}
    Request.search(url, false, [suggest_query])
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
    suggest_query = %Hui.S{q: q, count: count, dictionary: dictionaries, cfq: context}
    Request.search(url, true, [suggest_query])
  end

  @doc """
  Issue a MoreLikeThis (mlt) query to a specified Solr endpoint.

  ### Example

  ```
    query = %Hui.Q{q: "apache", rows: 10, wt: "xml"}
    mlt = %Hui.M{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
    Hui.mlt(:library, query, mlt)
  ```
  """
  @spec mlt(url, Hui.Q.t, Hui.M.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def mlt(url, %Hui.Q{} = query_struct, %Hui.M{} = mlt_query_struct), do: Request.search(url, [query_struct, mlt_query_struct])

  @doc """
  Issue a MoreLikeThis (mlt) query to a specified Solr endpoint, raise an exception in case of failure.
  """
  @spec mlt!(url, Hui.Q.t, Hui.M.t) :: HTTPoison.Response.t
  def mlt!(url, %Hui.Q{} = query_struct, %Hui.M{} = mlt_query_struct), do: Request.search(url, true, [query_struct, mlt_query_struct])
end
