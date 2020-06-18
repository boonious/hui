defmodule Hui.Http do
  @default_client Hui.Http.Httpoison

  @type t :: %__MODULE__{
          body: term,
          headers: list,
          options: keyword,
          status: integer,
          url: binary | iodata
        }

  defstruct body: nil,
            headers: [],
            options: [],
            status: nil,
            url: ""

  @callback get(request :: t) :: {:ok, t} | {:error, term}
  @callback post(request :: t) :: {:ok, t} | {:error, term}

  @spec get(client :: module, request :: t) :: {:ok, t} | {:error, term}
  def get(client \\ @default_client, request), do: client.get(request)

  @spec post(client :: module, request :: t) :: {:ok, t} | {:error, term}
  def post(client \\ @default_client, request), do: client.post(request)
end
