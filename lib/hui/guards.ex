defmodule Hui.Guards do
  @moduledoc false
  defguard is_nil_empty(value) when value == "" or is_nil(value) or value == []

  defguard is_url(url, headers, options)
           when is_binary(url) and url != "" and is_list(headers) and is_list(options)

  defguard is_url(url, headers) when is_binary(url) and url != "" and is_list(headers)
  defguard is_url(url) when is_binary(url) and url != ""
end
