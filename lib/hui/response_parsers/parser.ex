defmodule Hui.ResponseParsers.Parser do
  @moduledoc false

  alias Hui.Http

  @type http_response :: Http.response()
  @callback parse(http_response) :: http_response
end
