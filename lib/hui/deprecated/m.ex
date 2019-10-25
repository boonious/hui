defmodule Hui.M do
  @moduledoc deprecated: """
  Please use Hui.Query.MoreLikeThis instead
  """
  defstruct [mlt: true] ++
            [:count, :fl, :mintf, :mindf, :maxdf, :maxdfpct,
             :minwl, :maxwl, :maxqt, :maxntp, :boost, :qf,
             :"match.include", :"match.offset", :interestingTerms]

  @typedoc """
  Struct for [MoreLikeThis](http://lucene.apache.org/solr/guide/morelikethis.html)
  """
  @type t :: %__MODULE__{mlt: boolean, count: number, fl: binary, 
                         mintf: number, mindf: number, maxdf: number, maxdfpct: number,
                         minwl: number, maxwl: number, maxqt: number, maxntp: number,
                         boost: boolean, qf: binary,
                         "match.include": boolean, "match.offset": number, interestingTerms: binary}
end