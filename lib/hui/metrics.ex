defmodule Hui.Metrics do
  @moduledoc false

  alias Hui.Query.Metrics

  @spec metrics(Hui.url(), keyword) :: Http.response()
  def metrics(url \\ :default, options) do
    Hui.get(url, struct(Metrics, options))
  end
end
