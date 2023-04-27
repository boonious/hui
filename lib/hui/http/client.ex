defmodule Hui.Http.Client do
  @moduledoc """
  A client behaviour module for handling Solr HTTP requests and responses.

  This module is responsible for dispatching Solr request encapsulated in `t:Hui.Http.t/0` struct.
  It underpins the core functions of `Hui`. Three implementations have been provided:
    - [Erlang httpc](https://erlang.org/doc/man/httpc.html)
    - [HTTPoison](https://github.com/edgurgel/httpoison)
    - [Finch](https://github.com/sneako/finch)

  ### Using other HTTP clients
  `httpc` is used in Hui by default. One of the above HTTP clients may be deployed
  by adding the client as dependency and specificying it via the `http_client` configuration - see below.
  Other HTTP clients may also be used by implementing this behaviour.

  ```
    config :hui,
      http_client: Hui.Http.Clients.Finch
  ```

  Hui.Http.Clients.Finch depends on `Finch`. The dependency needs to be specified in `mix.exs`.
  You might also need to start the client application by specifying it (e.g. `:httpoison`) in
  the `application` section of `mix.exs`.

  ```
    defp deps do
      [
        {:finch, "~> 0.16"}
      ]
    end
  ```

  For Finch (only), you also need to name and
  [start it from your supervision tree](https://github.com/sneako/finch#usage) and
  configure it as below:

  ```ex
    # use the same name specified in the supervision tree
    config :hui, :finch, name: FinchSolr
  ```

  """

  alias Hui.Http

  @before_compile Hui.Http.Clients

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

  @spec impl() :: module()
  def impl(), do: Application.get_env(:hui, :http_client, Hui.Http.Clients.Httpc)

  @spec dispatch(request) :: response
  def dispatch(request), do: request.client.dispatch(request)

  @spec handle_response(http_response, request) :: response
  def handle_response(resp, request), do: request.client.handle_response(resp, request)
end
