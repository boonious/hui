defmodule Hui do
  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).
  
  ### Usage
  
  - Searching Solr: `q/1`, `q/2`, `search/2`, `search/3`
  - [More usage](https://hexdocs.pm/hui/readme.html#usage)
  """

  @type query :: Hui.Q.t | Hui.D.t | Keyword.t
  @type url :: binary | atom | Hui.URL.t

  @doc """
  Issue a search query to the default Solr endpoint.

  The query can be a string, a keyword list or query struct.
  This function is a shortcut for `search/2` with `:default` as URL key.

  ### Example

  ```
    Hui.q("scott") # keyword search
    Hui.q(%Hui.Q{q: "loch", fq: ["type:illustration", "format:image/jpeg"]})
    Hui.q(%Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"})
    Hui.q(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])
  ```
  """
  @spec q(binary | query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def q(query) when is_binary(query), do: search(:default, q: query)
  def q(%Hui.Q{} = q), do: search(:default, [q])
  def q(%Hui.D{} = q), do: search(:default, [q])
  def q(query), do: search(:default, query)

  @doc """
  Issue a structured query and faceting request to the default Solr endpoint.

  The query consists of a query struct (`t:Hui.Q.t/0`) and a faceting struct (`t:Hui.F.t/0`).

  ### Example

  ```
    Hui.q(%Hui.Q{q: "author:I*", rows: 5}, %Hui.F{field: ["cat", "author_str"], mincount: 1})
  ```
  """
  @spec q(Hui.Q.t, Hui.F.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def q(%Hui.Q{} = q, %Hui.F{} = f), do: search(:default, [q, f])

  @doc """
  Issue a search query to a specific Solr endpoint.

  The endpoint can either be a string URL or `t:Hui.URL.t/0` struct which defines
  a specific URL and request handler. A key referring to a configured endpoint
  may also be used.
  
  The query is a struct (`Hui.Q`) or a keyword list of Solr parameters.
  
  ### Example - parameters 
  
  ```
    # structured query with permitted or qualified Solr parameters
    Hui.search(url, %Hui.Q{q: "loch", rows: 5, wt: "xml", fq: ["type:illustration", "format:image/jpeg"]})
    # a keyword list of arbitrary parameters
    Hui.search(url, q: "edinburgh", rows: 10)

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
  @spec search(url, query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, %Hui.Q{} = q), do: Hui.Search.search(url, [q])
  def search(url, %Hui.D{} = q), do: Hui.Search.search(url, [q])
  def search(url, query), do: Hui.Search.search(url, query)

  @doc """
  Issue a structured query and faceting request to a specific Solr endpoint.

  The endpoint can be a string URL, a `t:Hui.URL.t/0` struct (for HTTP headers and options)
  which defines a specific URL and request handler or a key referring to a configured endpoint.

  The query consists of a query struct (`t:Hui.Q.t/0`) and a faceting struct (`t:Hui.F.t/0`).

  ### Example

  ```
    x = %Hui.Q{q: "author:I*", rows: 5}
    y = %Hui.F{field: ["cat", "author_str"], mincount: 1}
    Hui.search(:library, x, y)

    # DisMax query
    x = %Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
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

   See `Hui.Q`, `Hui.F`, `Hui.URL.encode_query/1` for more details on query structs.

  """
  @spec search(url, (Hui.Q.t| Hui.D.t), Hui.F.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, %Hui.Q{} = q, %Hui.F{} = f), do: Hui.Search.search(url, [q, f])
  def search(url, %Hui.D{} = q, %Hui.F{} = f), do: Hui.Search.search(url, [q, f])

end
