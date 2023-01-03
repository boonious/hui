defmodule Hui.Http do
  @moduledoc """
  A struct encapsulating Solr HTTP request and response.
  """

  defstruct body: nil,
            headers: [],
            method: :get,
            options: [],
            status: nil,
            url: ""

  @typedoc """
  Request or response body which can be in iodata or parsed (as map) format.
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
          headers: list(),
          method: :get | :post,
          options: keyword(),
          status: nil | integer(),
          url: request_url
        }
end
