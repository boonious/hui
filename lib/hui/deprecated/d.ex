defmodule Hui.D do
  @moduledoc deprecated: """
  Please use Hui.Query.DisMax instead.
  """

  defstruct [:q, :"q.alt", :qf, :mm, :pf, :ps, :qs, :tie, :bq, :bf, # dismax
             :sow, :"mm.autoRelax", :boost, :lowercaseOperators, :pf2, :ps2, :pf3, :ps3, :stopwords, :uf]  # extended dismax

  @typedoc """
  Struct for DisMax/eDismax query.

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{q: binary, "q.alt": binary, qf: binary, mm: binary, pf: binary, ps: integer,
                         qs: integer, tie: float, bq: binary, bf: binary, sow: boolean,
                         "mm.autoRelax": boolean, boost: binary, lowercaseOperators: binary,
                         pf2: binary, ps2: integer, pf3: binary, ps3: integer, stopwords: boolean, uf: binary}

end