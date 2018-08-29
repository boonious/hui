defmodule Hui.URL do
  @moduledoc """
    Struct and utilities for working with Solr URLs and queries.

    Use the `%Hui.URL{url: url, handler: handler}` data struct to specify
    Solr URLs and request handlers. Functions such as `select_path`,
    `update_path` return the default paths for a given SOLR url.

  """

  defstruct [:url, :handler ]
  @type t :: %__MODULE__{url: nil | binary, handler: nil | binary}

  def select_path(%__MODULE__{url: url, handler: _handler}), do: "#{url}/select"
  def update_path(%__MODULE__{url: url, handler: _handler}), do: "#{url}/update"

  def to_string(%__MODULE__{url: url, handler: handler}), do: "#{url}/#{handler}"

end
