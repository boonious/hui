defmodule Hui.EncodeNew do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @type query :: Hui.Query.solr_query()
  @type options :: Hui.Encode.Options.t()

  @url_delimiters {?=, ?&}

  defmodule Options do
    defstruct [:per_field, :prefix, format: :url]

    @type t :: %__MODULE__{
            format: :url | :json,
            per_field: binary,
            prefix: binary
          }
  end

  @doc """
  Encodes keywords list into IO data.
  """
  @spec encode(list(keyword)) :: iodata()
  def encode([]), do: []
  def encode(query) when is_list(query), do: transform(sanitise(query), @url_delimiters)

  defp transform([h | t], delimiters), do: transform({h, t}, delimiters)

  # expands and transforms fq: [x, y, z] => "fq=x&fq=&fq=z"
  defp transform({{k, v}, t}, _delimiters) when is_list(v), do: encode(Enum.map(v, &{k, &1}) ++ t)
  defp transform({h, []}, {eql, _delimiter}), do: [key(h), eql, value(h)]

  defp transform({h, t}, {eql, delimiter}) do
    [key(h), eql, value(h), delimiter | [transform(t, {eql, delimiter})]]
  end

  defp key({k, _v}), do: to_string(k)

  defp value({_k, v}), do: URI.encode_www_form(to_string(v))

  defp sanitise(query) do
    query
    |> Enum.reject(fn {k, v} ->
      v in ["", nil, []] or k == :__struct__ or k == :per_field
    end)
  end
end
