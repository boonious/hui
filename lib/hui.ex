defmodule Hui do
  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).

  ### Usage
  
  - Searching Solr: `q/1`, `q/2`, `search/2`, `search/3`
  - Other: `suggest/2`, `spellcheck/3`
  - [More details](https://hexdocs.pm/hui/readme.html#usage)
  """

  @type highlighter_struct :: Hui.H.t | Hui.H1.t | Hui.H2.t | Hui.H3.t
  @type misc_struct :: Hui.S.t | Hui.Sp.t | Hui.M.t
  @type query_struct_list :: list(Hui.Q.t | Hui.D.t | Hui.F.t | highlighter_struct | misc_struct)
  @type url :: binary | atom | Hui.URL.t

  @doc """
  Issue a search query to the default Solr endpoint.

  The query can be a string, a keyword list or a standard query struct (`Hui.Q`).
  This function is a shortcut for `search/2` with `:default` as URL key.

  ### Example

  ```
    Hui.q("scott") # keyword search
    Hui.q(%Hui.Q{q: "loch", fq: ["type:illustration", "format:image/jpeg"]})
    Hui.q(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])

    # supply a list of Hui structs for more complex query, e.g. DisMax
    x = %Hui.D{q: "run", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3}
    y = %Hui.Q{rows: 10, start: 10, fq: ["edited:true"]}
    z = %Hui.F{field: ["cat", "author_str"], mincount: 1}
    Hui.q([x, y, z])

  ```
  """
  @spec q(binary | Hui.Q.t | query_struct_list | Keyword.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def q(query) when is_binary(query), do: search(:default, q: query)
  def q(%Hui.Q{} = q), do: search(:default, [q])
  def q(query), do: search(:default, query)

  @doc """
  Issue a standard structured query and faceting request to the default Solr endpoint.

  ### Example

  ```
    Hui.q(%Hui.Q{q: "author:I*", rows: 5}, %Hui.F{field: ["cat", "author_str"], mincount: 1})
  ```
  """
  @spec q(Hui.Q.t, Hui.F.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def q(%Hui.Q{} = query, %Hui.F{} = facet), do: search(:default, [query, facet])

  @doc """
  Issue a search query to a specific Solr endpoint.
  
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

  See `Hui.URL.configured_url/1` amd `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  `t:Hui.URL.t/0` struct also enables HTTP headers and HTTPoison options to be specified
  in keyword lists. HTTPoison options provide further controls for a request, e.g. `timeout`, `recv_timeout`,
  `max_redirect`, `params` etc.

  ```
    # setting up a header and a 10s receiving connection timeout
    url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
    Hui.search(url, q: "solr rocks")
  ```

  See `HTTPoison.request/5` for more details on HTTPoison options.

  """
  @spec search(url, Hui.Q.t | query_struct_list) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, %Hui.Q{} = query), do: Hui.Search.search(url, [query])
  def search(url, query), do: Hui.Search.search(url, query)

  @doc """
  Issue a standard structured query and faceting request to a specific Solr endpoint.

  ### Example

  ```
    x = %Hui.Q{q: "author:I*", rows: 5}
    y = %Hui.F{field: ["cat", "author_str"], mincount: 1}
    Hui.search(:library, x, y)

    # more elaborated faceting query
    x = %Hui.Q{q: "*", rows: 5}
    range1 = %Hui.F.Range{range: "price", start: 0, end: 100, gap: 10, per_field: true}
    range2 = %Hui.F.Range{range: "popularity", start: 0, end: 5, gap: 1, per_field: true}
    y = %Hui.F{field: ["cat", "author_str"], mincount: 1, range: [range1, range2]}
    Hui.search(:default, x, y)
  ```

  The above `Hui.search(:default, x, y)` example issues a request that resulted in
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
  @spec search(url, Hui.Q.t, Hui.F.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, %Hui.Q{} = query, %Hui.F{} = facet), do: Hui.Search.search(url, [query, facet])

  @doc """
  Issue a spell checking query to a specific Solr endpoint.

  ### Example

  ```
    spellcheck_query = %Hui.Sp{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}
    Hui.spellcheck(:library, spellcheck_query)
  ```
  """
  @spec spellcheck(url, Hui.Sp.t, Hui.Q.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def spellcheck(url, %Hui.Sp{} = spellcheck_query_struct, query_struct \\ %Hui.Q{}), do: Hui.Search.search(url, [query_struct, spellcheck_query_struct])

  @doc """
  Issue a suggester query to a specific Solr endpoint.

  ### Example

  ```
    suggest_query = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}
    Hui.suggest(:library, suggest_query)
  ```
  """
  @spec suggest(url, Hui.S.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def suggest(url, %Hui.S{} = suggest_query_struct), do: Hui.Search.search(url, [suggest_query_struct])

  @doc """
  Issue a MoreLikeThis (mlt) query to a specific Solr endpoint.

  ### Example

  ```
    query = %Hui.Q{q: "apache", rows: 10, wt: "xml"}
    mlt = %Hui.M{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
    Hui.mlt(:library, query, mlt)
  ```
  """
  @spec mlt(url, Hui.Q.t, Hui.M.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def mlt(url, %Hui.Q{} = query_struct, %Hui.M{} = mlt_query_struct), do: Hui.Search.search(url, [query_struct, mlt_query_struct])

end
