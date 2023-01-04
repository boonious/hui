defmodule Hui.Http do
  @moduledoc """
  A struct for Solr HTTP request and response.
  """

  @default_client Hui.Http.Clients.Httpc

  defstruct body: nil,
            client: @default_client,
            headers: [],
            method: :get,
            options: [],
            status: nil,
            url: ""

  @typedoc """
  Request or response body in either iodata or parsed (as map) format.
  """
  @type body :: nil | iodata() | map()

  @typedoc """
  The request url in iodata format consisting the full path and encoded query params.
  """
  @type request_url :: iodata()

  @typedoc """
  Response tuple from a HTTP request consists of the `t:Hui.Http.t/0` struct and Solr response.
  """
  @type response :: {:ok, t} | {:error, Hui.Error.t()}

  @typedoc """
  The main request and response data struct.
  """
  @type t :: %__MODULE__{
          body: body,
          client: module(),
          headers: list(),
          method: :get | :post,
          options: keyword(),
          status: nil | integer(),
          url: request_url
        }
end
