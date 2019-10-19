defmodule Hui.F.Range do
  @moduledoc deprecated: """
  Please use Hui.Query.FacetRange instead.
  """
  defstruct [:range, :start, :end, :gap]
         ++ [:hardend, :include, :other, :method, per_field: false]

  @typedoc """
  Struct for range faceting parameters, use in conjunction with
  the main faceting `t:Hui.F.t/0` struct (range).

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{range: binary, start: binary, end: binary, gap: binary,
                         hardend: boolean, include: binary,
                         other: binary, method: binary,
                         per_field: boolean}

end