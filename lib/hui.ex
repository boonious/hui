defmodule Hui do
  @moduledoc """
  Hui (辉 "shine" in Chinese) is a client and library for Solr enterprise search platform.

  """

  @doc """
  Issue a search query request to the default configured Solr URL.

  ### Example

  ```
    Hui.search("ipod")
  ```
  """
  def search(query), do: Hui.Search.search(query)

end
