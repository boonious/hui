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

  @type highlighter_struct :: Hui.H.t | Hui.H1.t | Hui.H2.t | Hui.H3.t
  @type misc_struct :: Hui.S.t | Hui.Sp.t | Hui.M.t
  @type query_struct_list :: list(Hui.Q.t | Hui.D.t | Hui.F.t | highlighter_struct | misc_struct)
  
  @type solr_params :: Keyword.t | query_struct_list
  @type solr_url :: :default | atom | Hui.URL.t

  @error_einval %Hui.Error{reason: :einval} # invalid argument exception
  @error_nxdomain %Hui.Error{reason: :nxdomain} # invalid / non existing host or domain

  @doc """
  Issues a search query to a specific Solr endpoint.

  The query parameters can be a keyword list or a list of Hui query structs: `t:Hui.Q.t/0`, `t:Hui.F.t/0`.

  ## Example - parameters

  ```
    url = "http://..."

    # Parameters can be supplied as a list of keywords, which are unbound and sent to Solr directly
    Hui.Search.search(url, q: "glen cova", facet: "true", "facet.field": ["type", "year"])

    # Parameters can be a list of query structs
    Hui.Search.search(url, [%Hui.Q{q: "glen cova"}, %Hui.F{field: ["type", "year"]}])

    # DisMax query, multiple structs usage
    x = %Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3"}
    y = %Hui.Q{rows: 10, fq: ["cat:electronics"]}
    z = %Hui.F{field: ["popularity"]} # faceting
    Hui.Search.search(url, [x, y, z])
  ```

  The use of structs is more idiomatic and succinct. It is bound to qualified Solr fields. See `Hui.Q`, `Hui.F`, `Hui.URL.encode_query/1` for more details

  ## Example - URL endpoints
  The URL can be specified as `t:Hui.URL.t/0`.

  ```
    url = %Hul.URL{url: "http://..."}
    Hui.Search.search(url, q: "loch", rows: 5)
    # -> http://.../select?q=loch&rows=5
  ```

  A key for application-configured endpoint may also be used.
    
  ```
    url = :suggester
    Hui.Search.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
    # the above sends http://..configured_url../suggest?suggest=true&suggest.dictionary=mySuggester&suggest.q=el
  ```

  See `Hui.URL.configured_url/1` for more details.

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
  @spec search(solr_url, solr_params) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}
  def search(%Hui.URL{} = url_struct, query), do: _search(url_struct, query)
  def search(url, query) when is_binary(url), do: _search(%Hui.URL{url: url}, query)
  def search(url, query) when is_atom(url) do
    {status, url_struct} = Hui.URL.configured_url(url)
    case status do
      :ok -> _search(url_struct, query)
      :error -> {:error, @error_nxdomain}
    end
  end
  def search(_, _), do: {:error, @error_einval}

  # decode JSON data and return other response formats as
  # raw text
  def process_response_body(""), do: ""
  def process_response_body(body) do
    {status, solr_results} = Poison.decode body
    case status do
      :ok -> solr_results
      :error -> body
    end
  end

  defp _search(%Hui.URL{} = url_struct, [head|tail]) do
    url = Hui.URL.to_string(url_struct)
    cond do
     url_struct.url == "" -> {:error, @error_nxdomain}
     is_tuple(head) -> _search( url <> "?" <> Hui.URL.encode_query([head] ++ tail), url_struct.headers, url_struct.options )
     is_map(head) ->  _search( url <> "?" <> Enum.map_join([head] ++ tail, "&", &Hui.URL.encode_query/1), url_struct.headers, url_struct.options )
     true -> {:error, @error_einval}
    end
  end
  defp _search(_,_), do: {:error, @error_einval}

  defp _search(url, headers, options) do
   {status, resp} = get(url, headers, options)
   case status do
     :ok -> {:ok, resp}
     :error -> {:error, %Hui.Error{reason: resp.reason}}
   end
  end

end