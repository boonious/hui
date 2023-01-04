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
  alias Hui.Query

  @type http_response :: {:ok, term()} | {:ok, term()}
  @type request :: Http.t()
  @type response :: {:ok, Http.t()} | {:error, Hui.Error.t()}

  @doc """
  Dispatch HTTP request to a Solr endpoint.

  If a client is not set via `c:build_request/3`, the default httpc-based client
  will be used.
  """
  @callback dispatch(request) :: http_response

  @doc """
  For post-dispatch processing such as error handling and parsing Solr documents.
  """
  @callback handle_response(http_response, request) :: response

  ### common functions

  @spec dispatch(request) :: response
  def dispatch(request), do: request.client.dispatch(request)

  @spec handle_response(http_response, request) :: response
  def handle_response(resp, request), do: request.client.handle_response(resp, request)
end
