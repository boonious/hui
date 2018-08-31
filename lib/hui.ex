defmodule Hui do

  @moduledoc """
  Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
  [Solr enterprise search platform](http://lucene.apache.org/solr/).
  
  Usage
  
  - Searching Solr: `search/1`

  """

  @doc """
  Issue a search query to the default configured Solr URL.

  The query can be a search string or a comprehensive keywords list of Solr parameters.

  ### Example

  ```
    Hui.search("scott")
    Hui.search(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
    Hui.search(q: "loch", rows: 5, facet: true, "facet.field": ["year", "subject"])
  ```

  See `Hui.URL.encode_query/1` for more details on Solr parameter keywords list.

  """
  @type solr_query :: binary | list
  @spec search(solr_query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(query), do: Hui.Search.search(query)

  def search(url, query) when is_binary(url), do: Hui.Search.search(%Hui.URL{url: url}, query)

end
