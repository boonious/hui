defmodule Hui do

  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).
  
  Usage
  
  - Searching Solr: `search/1`, `search/2`

  """

  @type query :: binary | Hui.Search.solr_params
  @type url :: binary | Hui.Search.solr_url

  @doc """
  Issue a search query to the default Solr endpoint.

  The query can be a search string or a keyword list of Solr parameters.

  ### Example

  ```
    Hui.search("scott") # keyword search
    Hui.search(q: "loch", fq: ["type:illustration", "format:image/jpeg"])
    Hui.search(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])
  ```

  See `Hui.URL.default_url!/0` and `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  """

  @spec search(query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(query) when is_binary(query), do: Hui.Search.search(q: query)
  def search(query), do: Hui.Search.search(query)

  @doc """
  Issue a search query to a Solr endpoint.

  The endpoint can either be a string URL or `t:Hui.URL.t/0` struct which defines
  a specific URL and request handler. A key referring to an endpoint in configuration
  can also be used.
  
  The query is a keyword list of Solr parameters.

  ### Example

  ```
    Hui.search("http://localhost:8983/solr/collection", q: "loch")

    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
    Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")

    url = :library
    Hui.search(url, q: "edinburgh", rows: 10)
  ```

  See `Hui.URL.configured_url/1` amd `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  """
  @spec search(url, Hui.Search.solr_params) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, query) when is_binary(url), do: Hui.Search.search(%Hui.URL{url: url}, query)
  def search(url, query) when is_map(url) or is_atom(url), do: Hui.Search.search(url, query)
  def search(_, _), do: {:error, "malformed query or URL"}

end
