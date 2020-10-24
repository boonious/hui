defmodule Hui.Http do
  @default_client Hui.Http.Httpoison

  @type response :: {:ok, t} | {:error, Hui.Error.t()}
  @type t :: %__MODULE__{
          body: nil | binary() | map(),
          headers: list(),
          method: :get | :post,
          options: keyword(),
          status: nil | integer(),
          url: iodata()
        }

  defstruct body: nil,
            headers: [],
            method: :get,
            options: [],
            status: nil,
            url: ""

  @callback dispatch(request :: t) :: response

  @spec dispatch(request :: t, client :: module) :: response
  def dispatch(request, client \\ @default_client), do: client.dispatch(request)
end
