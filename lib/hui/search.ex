defmodule Hui.Search do
  @moduledoc """
  ...
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

end