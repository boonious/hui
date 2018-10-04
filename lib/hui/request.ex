defmodule Hui.Request do
  @moduledoc """

  Hui.Request module provides underpinning HTTP-based request functions for Solr, including:
  
  - `search/2`, `search/3`
  - `update/2`, `update/3`

  ### Other low-level HTTP client features

  Under the hood, Hui uses `HTTPoison` client to interact with Solr.
  The existing low-level functions of HTTPoison, e.g. `get/1`, `get/3` 
  remain available as part of this module.
  """

  use HTTPoison.Base 
  import Hui.Guards

  @type highlighter_struct :: Hui.H.t | Hui.H1.t | Hui.H2.t | Hui.H3.t
  @type misc_struct :: Hui.S.t | Hui.Sp.t | Hui.M.t
  @type query_struct_list :: list(Hui.Q.t | Hui.D.t | Hui.F.t | highlighter_struct | misc_struct)

  # Use the following equivalent typespecs when checking codes with
  # Dialyzer as the above typespec style doesn'seem to work with the tool.
  #
  #@type highlighter_struct :: %Hui.H{} | %Hui.H1{} | %Hui.H2{} | %Hui.H3{}
  #@type misc_struct :: %Hui.S{} | %Hui.Sp{} | %Hui.M{}
  #@type query_struct_list :: list(%Hui.Q{} | %Hui.D{} | %Hui.F{} | highlighter_struct | misc_struct)

  @type solr_params :: Keyword.t | query_struct_list
  @type solr_url :: atom | Hui.URL.t

  @error_einval %Hui.Error{reason: :einval} # invalid argument exception
  @error_nxdomain %Hui.Error{reason: :nxdomain} # invalid / non existing host or domain

  @doc """
  Issues a search query to a specific Solr endpoint.

  The query parameters can be a keyword list or a list of Hui query structs (`t:query_struct_list/0`).

  ## Example - parameters

  ```
    url = "http://..."

    # Parameters can be supplied as a list of keywords, which are unbound and sent to Solr directly
    Hui.Request.search(url, q: "glen cova", facet: "true", "facet.field": ["type", "year"])

    # Parameters can be a list of query structs
    Hui.Request.search(url, [%Hui.Q{q: "glen cova"}, %Hui.F{field: ["type", "year"]}])

    # DisMax query, multiple structs usage
    x = %Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3"}
    y = %Hui.Q{rows: 10, fq: ["cat:electronics"]}
    z = %Hui.F{field: ["popularity"]} # faceting
    Hui.Request.search(url, [x, y, z])
  ```

  The use of structs is more idiomatic and succinct. It is bound to qualified Solr fields.

  The function returns a tuple or a `HTTPoison.Response` directly when `bang = true`.
  This could be used to implement "bangified" functions such as `search!` as per Elixir convention.

  ```
    Hui.Request.search(url, [x, y, z]) 
    # => {:ok, %HTTPoison.Response{..}}

    bang = true
    Hui.Request.search(url, bang, [x, y, z]) 
    # => %HTTPoison.Response{..} or raise Hui.Error
  ```

  ## Example - URL endpoints
  The URL can be specified as `t:Hui.URL.t/0`.

  ```
    url = %Hul.URL{url: "http://..."}
    Hui.Request.search(url, q: "loch", rows: 5)
    # -> http://.../select?q=loch&rows=5
  ```

  A key for application-configured endpoint may also be used.
    
  ```
    url = :suggester
    Hui.Request.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
    # the above sends http://..configured_url../suggest?suggest=true&suggest.dictionary=mySuggester&suggest.q=el
  ```

  See `Hui.URL.configured_url/1` for more details.

  `t:Hui.URL.t/0` struct also enables HTTP headers and HTTPoison options to be specified
  in keyword lists. HTTPoison options provide further controls for a request, e.g. `timeout`, `recv_timeout`,
  `max_redirect`, `params` etc.

  ```
    # setting up a header and a 10s receiving connection timeout
    url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
    Hui.Request.search(url, q: "solr rocks")
  ```

  See `HTTPoison.request/5` for more details on HTTPoison options.
  """
  @spec search(solr_url, boolean, solr_params) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t} | HTTPoison.Response.t
  def search(url, bang \\ false, query)
  def search(%Hui.URL{} = url, bang, query), do: _search(url, bang, query)

  def search(url, true, _query) when is_nil_empty(url), do: raise @error_einval
  def search(url, _bang, _query) when is_nil_empty(url), do: {:error, @error_einval}

  def search(url, bang, query) when is_binary(url), do: _search(%Hui.URL{url: url}, bang, query)
  def search(url, bang, query) when is_atom(url) do
    {status, url_struct} = Hui.URL.configured_url(url)
    case {status, bang} do
      {:ok, _} -> _search(url_struct, bang, query)
      {:error, false} -> {:error, @error_nxdomain}
      {:error, true} -> raise @error_nxdomain
    end
  end
  def search(_,_,_), do: {:error, @error_einval}

  @doc """
  Issues an update request to a specific Solr endpoint, for data uploading and deletion.

  The request sends binary data to an endpoint
  specified in a `t:Hui.URL.t/0` struct or a key
  referring to a URL setting in configuration. A content type header is also required so that
  Solr can process that the data accordingly.

  ## Example

  ```
  # Specify an endpoint for JSON data
  headers = [{"Content-type", "application/json"}]
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}
  json_doc = # encoded binary data such as raw JSON text from a file
  {status, response} = Hui.Request.update(url, json_doc)

  # Send data to a pre-configured URL
  {status, response} = Hui.Request.update(:library, json_doc)

  # Direct response, or exception in case of failture
  bang = true
  response = Hui.Request.update(url, bang, json_doc)
  
  # Delete a document via XML message
  headers = [{"Content-type", "application/xml"}]
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}
  {status, response} = Hui.Request.update(url, "<delete><id>9780141981727</id></delete>")
  ```

  See [Solr reference](http://lucene.apache.org/solr/guide/uploading-data-with-index-handlers.html)
  for more details on various data commands, types and formats.
  """
  @spec update(solr_url, boolean, binary) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t} | HTTPoison.Response.t
  def update(url, bang \\ false, data)
  def update(%Hui.URL{} = url, bang, data) when is_binary(data), do: _update(url, bang, data)
  def update(%Hui.URL{} = url, bang, %Hui.U{} = data), do: _update(url, bang, data |> Hui.U.encode)

  def update(url, true, _data) when is_nil_empty(url), do: raise @error_einval
  def update(url, _bang, _data) when is_nil_empty(url), do: {:error, @error_einval}

  def update(url, bang, data) when is_atom(url) do
    {status, url_struct} = Hui.URL.configured_url(url)
    case {status, bang} do
      {:ok, _} -> _update(url_struct, bang, data)
      {:error, false} -> {:error, @error_nxdomain}
      {:error, true} -> raise @error_nxdomain
    end
  end
  def update(_,_,_), do: {:error, @error_einval}

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

  # for keyword lists query 
  defp _search(%Hui.URL{} = url_struct, bang, [head|tail]) when is_tuple(head) do
    url = Hui.URL.to_string(url_struct)
    _search( url <> "?" <> Hui.URL.encode_query([head] ++ tail), url_struct.headers, url_struct.options, bang )
  end

  # for struct-based query 
  defp _search(%Hui.URL{} = url_struct, bang, [head|tail]) when is_map(head) do
    url = Hui.URL.to_string(url_struct)
    _search( url <> "?" <> Enum.map_join([head] ++ tail, "&", &Hui.URL.encode_query/1), url_struct.headers, url_struct.options, bang )
  end
  defp _search(_,true,_), do: raise @error_einval
  defp _search(_,_,_), do: {:error, @error_einval}

  defp _search(url, headers, options, true), do: get!(url, headers, options)
  defp _search(url, headers, options, _bang) do
   {status, resp} = get(url, headers, options)
   case status do
     :ok -> {:ok, resp}
     :error -> {:error, %Hui.Error{reason: resp.reason}}
   end
  end

  defp  _update(%Hui.URL{} = url_struct, true, data), do: Hui.URL.to_string(url_struct) |> post!(data, url_struct.headers, url_struct.options)
  defp  _update(%Hui.URL{} = url_struct, _bang, data) do
    url = Hui.URL.to_string(url_struct)
    {status, resp} = post(url, data, url_struct.headers, url_struct.options)
    case status do
      :ok -> {:ok, resp}
      :error -> {:error, %Hui.Error{reason: resp.reason}}
    end
  end

end