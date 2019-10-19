defmodule Hui.F.Interval do
  @moduledoc deprecated: """
  Please use Hui.Query.FacetInterval instead.
  """

  defstruct [:interval, set: [], per_field: false]

  @typedoc """
  Struct for interval faceting parameters, use in conjunction with
  the main faceting `t:Hui.F.t/0` struct (interval).

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{interval: binary, set: binary | list(binary), per_field: boolean}

end