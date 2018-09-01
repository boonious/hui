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

  @type solr_params :: Keyword.t
  @type solr_url :: atom | Hui.URL.t

  @doc """
  Issues a search query to the default Solr URL.

  The query contains a comprehensive keyword list of Solr parameters.
  
  ## Example
  ```
    Hui.Search.search(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
  ```

  See `Hui.URL.default_url!/0` and `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  """
  @spec search(solr_params) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(query) when is_list(query), do: search(@default_url, query)
  def search(_query), do: {:error, @error_msg}

  @doc """
  Issues a search query to a given Solr URL.

  The query contains a comprehensive keyword list of Solr parameters.

  ## Example

  The URL can be specified as `t:Hui.URL.t/0`.

  ```
    url = %Hul.URL{url: "http://..."}
    Hui.Search.search(url, q: "loch", rows: 5)
  ```

  A key for application-configured URL may also be used.
    
  ```
    url = :suggester
    Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
  ```

  See `Hui.URL.configured_url/1` and `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  """
  @spec search(solr_url, solr_params) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(%Hui.URL{url: url, handler: handler}, query), do: exec_search("#{url}/#{handler}", query)
  def search(url, query) when is_atom(url) do
    {status, url_m} = Hui.URL.configured_url(url)
    case status do
      :ok -> exec_search(url_m|>Hui.URL.to_string, query)
      :error -> {:error, "URL not configured"}
    end
  end
  def search(_, _), do: {:error, @error_msg}

  defp exec_search(url, [head|tail]) when is_tuple(head), do: get( url <> "?" <> Hui.URL.encode_query([head] ++ tail) )
  defp exec_search(_,_), do: {:error, @error_msg}

end