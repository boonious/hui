defmodule Hui.Http.Client do
  @moduledoc """
  A client behaviour module for handling Solr HTTP requests and responses.

  This module is responsible for dispatching Solr request encapsulated in `t:Hui.Http.t/0` struct.
  It underpins the core functions of `Hui`, as well as provides default implementation and
  built-in HTTP client capability based on [Erlang httpc](https://erlang.org/doc/man/httpc.html).

  ### Using other HTTP clients
  Instead of using the built-in client, other HTTP clients may be developed
  by implementing `Hui.Http` behaviour and deployed through application configuration.
  For example, Hui provides another client option - `Hui.Http.Httpoison`.

  ```
    config :hui,
      http_client: Hui.Http.Httpoison
  ```

  Hui.Http.Httpoison depends on `HTTPoison`. The dependency needs to be specified in `mix.exs`.
  Add `:httpoison` to the applications section of the mix file to start up
  the client for runtime.

  ```
    defp deps do
      [
        {:httpoison, "~> 1.7"}
      ]
    end
  ```
  """

  alias Hui.Http

  @type request :: Http.t()
  @type response :: {:ok, Http.t()} | {:error, Hui.Error.t()}

  @doc """
  Dispatch HTTP request to a Solr endpoint.

  This callback is optional and can be used to adapt other HTTP clients to
  provide different HTTP options and performance. Hui provides `Hui.Http.Httpoison`,
  a reference implementation of this callback that can be
  used in conjunction with `dispatch/2`.

  If the callback is not implemented, the default built-in httpc-based client
  will be used.
  """
  @callback dispatch(request) :: response


  @doc """
  Dispatch HTTP request to a Solr endpoint using a given client implementing the `Hui.Http` behaviour.

  Same as `dispatch/1` but invoking request through dynamic dispatching. See `Hui.Http.Httpoison`
  for a reference client implementation based on `HTTPoison` that provides additional options
  such as [connection pooling](https://github.com/edgurgel/httpoison#connection-pools).
  """
  @spec dispatch(request) :: response
  def dispatch(request), do: request.client.dispatch(request)
end
