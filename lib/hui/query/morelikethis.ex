defmodule Hui.Query.MoreLikeThis do
  @moduledoc """
  Struct related to [MoreLikeThis](http://lucene.apache.org/solr/guide/morelikethis.html) query.
  """
  defstruct [
              :boost,
              :count,
              :fl,
              :interestingTerms,
              :"match.include",
              :"match.offset",
              :maxdf,
              :maxdfpct,
              :maxntp,
              :maxqt,
              :maxwl,
              :mindf,
              :mintf,
              :minwl,
              :qf
            ] ++ [mlt: true]

  @typedoc """
  Struct for [MoreLikeThis](http://lucene.apache.org/solr/guide/morelikethis.html) query.
  """
  @type t :: %__MODULE__{
          boost: boolean,
          count: number,
          fl: binary,
          interestingTerms: binary,
          "match.include": boolean,
          "match.offset": number,
          maxdf: number,
          maxdfpct: number,
          maxntp: number,
          maxqt: number,
          maxwl: number,
          mindf: number,
          mintf: number,
          minwl: number,
          mlt: boolean,
          qf: binary
        }

  @spec new :: t
  def new(), do: %__MODULE__{}
end
