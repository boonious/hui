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
  def encode(query) when is_list(query), do: transform(query, @url_delimiters)

  defp transform([h | t], delimiters), do: transform({h, t}, delimiters)

  # expands and transforms fq: [x, y, z] => "fq=x&fq=&fq=z"
  defp transform({{k, v}, t}, _delimiters) when is_list(v), do: encode(Enum.map(v, &{k, &1}) ++ t)
  defp transform({h, []}, {eql, _delimiter}), do: [key(h), eql, value(h)]

  defp transform({h, t}, {eql, delimiter}) do
    [key(h), eql, value(h), delimiter | [transform(t, {eql, delimiter})]]
  end

  defp key({k, _v}), do: to_string(k)

  defp value({_k, v}), do: URI.encode_www_form(to_string(v))

  @doc """
  Encodes Solr query structs that require special handling into IO data.
  """
  @spec encode(query, options) :: iodata()
  def encode(query, %{format: :url} = options), do: transform(query, options, @url_delimiters)

  defp transform([h | t], opts, delimiters), do: transform({h, t}, opts, delimiters)

  # expands and transforms fq: [x, y, z] => "fq=x&fq=&fq=z"
  defp transform({{k, v}, t}, opts, _delimiters) when is_list(v) do
    encode(Enum.map(v, &{k, &1}) ++ t, opts)
  end

  defp transform({{_k, %{:__struct__ => _} = v}, t}, opts, {eql, delimiter}) do
    case t do
      [] -> Hui.Encoder.encode(v)
      _ -> [Hui.Encoder.encode(v), delimiter | [transform(t, opts, {eql, delimiter})]]
    end
  end

  defp transform({h, []}, opts, {eql, _delimiter}), do: [key(h, opts), eql, value(h, opts)]

  defp transform({h, t}, opts, {eql, delimiter}) do
    [key(h, opts), eql, value(h, opts), delimiter | [transform(t, opts, {eql, delimiter})]]
  end

  defp key({k, _v}, %{prefix: prefix, per_field: field}) do
    key = to_string(k)

    cond do
      k in [:facet, :mlt, :spellcheck, :suggest] -> key
      String.ends_with?(prefix, key) -> prefix
      field != nil -> ["f", ".", field, ".", prefix, ".", key] |> to_string()
      field == nil -> [prefix, ".", key] |> to_string()
    end
  end

  defp value({_k, v}, _opts), do: URI.encode_www_form(to_string(v))

  @doc false
  @spec sanitise(list()) :: list()
  def sanitise(query) do
    query
    |> Enum.reject(fn {k, v} ->
      v in ["", nil, []] or k == :__struct__ or k == :per_field
    end)
  end
end
