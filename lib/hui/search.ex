defmodule Hui.Search do
  @moduledoc """
  
  Hui.Search provide various underpinning functions including `search/1`, `search/2` for querying Solr.

  ### Other low-level HTTP client features

  Under the hood, Hui uses `HTTPoison` - an HTTP client to interact with Solr.
  The default low-level functions such as `get/1`, `get/3`
  of HTTPoison remains available via the `Hui.Search` Module.
  For example, if needs be you could create a "get" direct request to a Solr endpoint
  using options such as `params` for query parameters:

  ```
      iex> Hui.Search.get("http://localhost:8983/solr/gettingstarted/select?q=test")
      iex> Hui.Search.get("http://localhost:8983/solr/gettingstarted/select", [], params: [{"q", "*"}])
  ```

  See [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.html#content) module
  and [HTTPoison.request/5](https://hexdocs.pm/httpoison/HTTPoison.html#request/5)
  for more details on how to issue HTTP requests and other availlable options in addition 
  to `params`.

  """

  use HTTPoison.Base 

  @default_url %Hui.URL{ url: Application.get_env(:hui, :urls)[:default] }
  @type solr_query :: binary | list
  @type url :: binary

  @doc """
  Issues a search query to the default Solr URL.

  The query can be a search string or a comprehensive keywords list of Solr parameters.
  
  ## Example
  ```
    Hui.Search.search("loch")
    Hui.Search.search(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
  ```

  See `Hui.URL.encode_query/1` for more details on Solr parameter list.

  """
  @spec search(solr_query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(query) when is_bitstring(query), do: search(@default_url |> Hui.URL.select_path, q: query)
  def search(query) when is_list(query), do: search(@default_url |> Hui.URL.select_path, query)
  def search(_query), do: {:error, "unsupported or malformed query"}

  @doc """
  Issues a search query to a Solr URL.

  The query can be a search string or a comprehensive keywords list of Solr parameters.

  ## Example
  ```
    Hui.Search.search("http://localhost:8983/solr/gettingstarted/select", "loch")
    Hui.Search.search("http://localhost:8983/solr/gettingstarted/select", q: "loch", rows: 5)
  ```

  See `Hui.URL.encode_query/1` for more details on Solr parameter list.

  """
  @spec search(url, solr_query) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t} | {:error, String.t}
  def search(url, query) when is_binary(query), do: exec_search(url, Hui.URL.encode_query(q: query))
  def search(url, query) when is_list(query) do
    cond do
      Keyword.keyword?(query) -> exec_search(url, Hui.URL.encode_query(query))
      true -> {:error, "unsupported or malformed query"}
    end
  end

  defp exec_search(url, query) when is_binary(query), do: get( url <> "?" <> query )


end