defmodule Hui.Query.FacetInterval do
  @moduledoc """
  Struct related to [interval faceting](http://lucene.apache.org/solr/guide/faceting.html#interval-faceting) query.
  """

  defstruct [:interval, set: [], per_field: false]

  @typedoc """
  Struct for interval faceting parameters, use in conjunction with
  the faceting struct - `t:Hui.Query.Facet.t/0`.
  """
  @type t :: %__MODULE__{interval: binary, set: binary | list(binary), per_field: boolean}

end