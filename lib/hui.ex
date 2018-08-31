defmodule Hui do

  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).
  
  Usage
  
  - Searching Solr: `search/1`, `search/2`

  """

  @type solr_query :: binary | list
  @type solr_url :: binary | struct

  @doc """
  Issue a search query to a pre-configured default Solr endpoint.

  The query can be a search string or a keywords list of Solr parameters.

  ### Example

  ```
    Hui.search("scott") # keyword search
    Hui.search(q: "loch", fq: ["type:illustration", "format:image/jpeg"])
    Hui.search(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])
  ```

  See `Hui.URL.default_url!/0` and `Hui.URL.encode_query/1` for more details on Solr parameter keywords list.

  """

  @spec search(solr_query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(query) when is_binary(query), do: Hui.Search.search(q: query)
  def search(query), do: Hui.Search.search(query)

  @doc """
  Issue a search query to a Solr endpoint.

  The endpoint can either be a string URL or `t:Hui.URL.t/0` struct which defines
  a specific URL and request handler. The query is a keywords list of Solr parameters.

  ### Example

  ```
    Hui.search("http://localhost:8983/solr/collection", q: "loch")

    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
    Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
  ```

  See `Hui.URL.encode_query/1` for more details on Solr parameter keywords list.

  """
  @spec search(solr_url, list) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, query) when is_binary(url), do: Hui.Search.search(%Hui.URL{url: url}, query)
  def search(url, query) when is_map(url), do: Hui.Search.search(url, query)
  def search(_, _), do: {:error, "malformed query or URL"}

end
