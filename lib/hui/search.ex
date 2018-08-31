defmodule Hui.Search do
  @moduledoc """

  Hui.Search module provides various underpinning functions including `search/1`, `search/2` for querying Solr.

  ### Other low-level HTTP client features

  Under the hood, Hui uses `HTTPoison` - an HTTP client to interact with Solr.
  The existing low-level functions of HTTPoison, e.g. `get/1`, `get/3` 
  remain available as part of this module.

  See the rest of the documentation for more details.

  """

  use HTTPoison.Base 

  @default_url Hui.URL.default_url!
  @error_msg "malformed query or URL"

  @doc """
  Issues a search query to the default Solr URL.

  The query contains a comprehensive keywords list of Solr parameters.
  
  ## Example
  ```
    Hui.Search.search(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
  ```

  See `Hui.URL.encode_query/1` for more details on Solr parameter keywords list.

  """
  @spec search(list) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(query) when is_list(query), do: search(@default_url, query)
  def search(_query), do: {:error, @error_msg}

  @doc """
  Issues a search query to a Solr URL specified in `t:Hui.URL.t/0` struct.

  The query contains a comprehensive keywords list of Solr parameters.

  ## Example
  ```
    url = %Hul.URL{url: solr_endpoint}
    Hui.Search.search(url, q: "loch", rows: 5)
  ```

  See `Hui.URL.encode_query/1` for more details on Solr parameter keywords list.

  """
  @spec search(struct, list) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(%Hui.URL{url: url, handler: handler}, query), do: exec_search("#{url}/#{handler}", query)
  def search(_, _), do: {:error, @error_msg}

  defp exec_search(url, query) do
    cond do
      Keyword.keyword?(query) -> get( url <> "?" <> Hui.URL.encode_query(query) )
      true -> {:error, @error_msg}
    end
  end

end