defmodule Hui.Search do
  @moduledoc """

  Hui.Search module provides various underpinning functions for querying Solr, including:
  
  - `search/2`

  ### Other low-level HTTP client features

  Under the hood, Hui uses `HTTPoison` - an HTTP client to interact with Solr.
  The existing low-level functions of HTTPoison, e.g. `get/1`, `get/3` 
  remain available as part of this module.

  See the rest of the documentation for more details.

  """

  use HTTPoison.Base 

  @error_msg "malformed query or URL"
  @type solr_params :: Keyword.t
  @type solr_url :: :default | atom | Hui.URL.t

  @doc """
  Issues a search query to a specific Solr endpoint.

  The query is a comprehensive keyword list of Solr parameters.

  ## Example

  The URL can be specified as `t:Hui.URL.t/0`.

  ```
    url = %Hul.URL{url: "http://..."}
    Hui.Search.search(url, q: "loch", rows: 5)
    # the above sends http://.../select?q=loch&rows=5
  ```

  A key for application-configured endpoint may also be used.
    
  ```
    url = :suggester
    Hui.Search.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
    # the above sends http://..configured_url../suggest?suggest=true&suggest.dictionary=mySuggester&suggest.q=el
  ```

  See `Hui.URL.configured_url/1` and `Hui.URL.encode_query/1` for more details on Solr parameter keyword list.

  `t:Hui.URL.t/0` struct also enables HTTP headers and HTTPoison options to be specified
  in keyword lists. HTTPoison options provide further controls for a request, e.g. `timeout`, `recv_timeout`,
  `max_redirect`, `params` etc.

  ```
    # setting up a header and a 10s receiving connection timeout
    url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
    Hui.Search.search(url, q: "solr rocks")
  ```

  See `HTTPoison.request/5` for more details on HTTPoison options.

  """
  @spec search(solr_url, solr_params) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(%Hui.URL{} = url_struct, query), do: exec_search(url_struct, query)
  def search(url, query) when is_atom(url) do
    {status, url_struct} = Hui.URL.configured_url(url)
    case status do
      :ok -> exec_search(url_struct, query)
      :error -> {:error, "URL not configured"}
    end
  end
  def search(_, _), do: {:error, @error_msg}

  defp exec_search(%Hui.URL{} = url_struct, [head|tail]) when is_tuple(head) do 
    url = Hui.URL.to_string(url_struct)
    get( url <> "?" <> Hui.URL.encode_query([head] ++ tail), url_struct.headers, url_struct.options )
  end
  defp exec_search(_,_), do: {:error, @error_msg}

end