defmodule Hui.Search do
  @moduledoc """
  
  Hui.Search provide various underpinning functions such as `search/1`, `search/2` for querying Solr.

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

  @doc "Issues a simple query (`q=query`) request to the default Solr URL"
  def search(query) when is_bitstring(query), do: search(@default_url |> Hui.URL.select_path, query)
  def search(_query), do: {:error, "unsupported or malformed query"}

  @doc "Issues a simple query (`q=query`) request to a Solr url"
  def search(url, query), do: get( url <> "?q=" <> URI.encode(query))

end