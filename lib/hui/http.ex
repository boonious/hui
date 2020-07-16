defmodule Hui.Http do
  @default_client Hui.Http.Httpoison

  @type t :: %__MODULE__{
          body: binary | map,
          headers: list,
          method: :get | :post,
          options: keyword,
          status: integer,
          url: iodata
        }

  defstruct body: nil,
            headers: [],
            method: :get,
            options: [],
            status: nil,
            url: ""

  @callback dispatch(request :: t) :: {:ok, t} | {:error, Hui.Error.t()}

  @spec dispatch(http_request :: t, client :: module) :: {:ok, t} | {:error, Hui.Error.t()}
  def dispatch(http_request, client \\ @default_client), do: client.dispatch(http_request)
end
