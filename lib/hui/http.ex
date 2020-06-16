defmodule Hui.Http do
  @default Hui.Http.Httpoison

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
end
