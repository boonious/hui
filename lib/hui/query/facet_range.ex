defmodule Hui.Query.FacetRange do
  @moduledoc """
  Struct related to [range faceting](http://lucene.apache.org/solr/guide/faceting.html#range-faceting) query.
  """
  defstruct [:range, :start, :end, :gap]
         ++ [:hardend, :include, :other, :method, per_field: false]

  @typedoc """
  Struct for range faceting parameters, use in conjunction with
  the faceting struct -`t:Hui.Query.Facet.t/0`.
  """
  @type t :: %__MODULE__{range: binary, start: binary, end: binary, gap: binary,
                         hardend: boolean, include: binary,
                         other: binary, method: binary,
                         per_field: boolean}

end