defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @type options :: __MODULE__.Options.t()

  @url_delimiters {?=, ?&}
  @json_delimiters {?:, ?,}

  defmodule Options do
    defstruct [:per_field, :prefix, type: :url]

    @type t :: %__MODULE__{
            type: :url | :json,
            per_field: binary,
            prefix: binary
          }
  end

  @doc """
  Encodes keywords list into IO data.
  """
  @spec encode(keyword() | map()) :: iodata()
  def encode([]), do: []
  def encode(query) when is_list(query), do: encode(query, %Options{})
  def encode(query) when is_map(query), do: encode(query |> Map.to_list(), %Options{})

  @doc """
  Encodes keywords of Solr query structs that require special handling into IO data.
  """
  @spec encode(keyword(), options) :: iodata()
  def encode(query, options)

  def encode([h | t], %{type: :url} = opts), do: transform({h, t}, opts, @url_delimiters)
  def encode([h | t], %{type: :json} = opts), do: transform({h, t}, opts, @json_delimiters)

  @doc false
  def encode_json([], %{type: :json}), do: [?{, ?}]
  def encode_json(query, %{type: :json} = opts), do: [?{, encode(query, opts), ?}]

  # expands and transforms fq: [x, y, z] => "fq=x&fq=&fq=z"
  defp transform({{k, v}, t}, %{type: :url} = opts, _delimiters) when is_list(v) do
    encode(Enum.map(v, &{k, &1}) ++ t, opts)
  end

  defp transform({{_k, %{:__struct__ => _} = v}, t}, opts, {_eql, delimiter}) do
    case t do
      [] -> Hui.Encoder.encode(v)
      _ -> [Hui.Encoder.encode(v), delimiter | [encode(t, opts)]]
    end
  end

  defp transform({h, []}, opts, {eql, _delimiter}), do: [key(h, opts), eql, value(h, opts)]

  defp transform({h, t}, opts, {eql, delimiter}) do
    [key(h, opts), eql, value(h, opts), delimiter | [encode(t, opts)]]
  end

  defp key({k, _v}, %{prefix: nil, type: :url}), do: to_string(k)
  defp key({k, _v}, %{prefix: nil, type: :json}), do: [?", to_string(k), ?"]

  defp key({k, _v}, %{prefix: prefix, per_field: field}) do
    key = to_string(k)

    cond do
      k in [:facet, :mlt, :spellcheck, :suggest] -> key
      String.ends_with?(prefix, key) -> prefix
      field != nil -> ["f", ".", field, ".", prefix, ".", key] |> to_string()
      field == nil -> [prefix, ".", key] |> to_string()
    end
  end

  defp value({_k, v}, %{type: :url}), do: URI.encode_www_form(to_string(v))
  defp value({_k, v}, %{type: :json}), do: Jason.encode_to_iodata!(v)

  @doc false
  @spec sanitise(list()) :: list()
  def sanitise(query) do
    query
    |> Enum.reject(fn {k, v} ->
      v in ["", nil, []] or k == :__struct__ or k == :per_field
    end)
  end
end
