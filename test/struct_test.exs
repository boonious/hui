defmodule HuiStructTest do
  use ExUnit.Case, async: true

  alias Hui.Query

  doctest Query.Facet
  doctest Query.FacetRange
  doctest Query.FacetInterval

  describe "new instance" do
    test "HighlighterOriginal" do
      x = Query.HighlighterOriginal.new()
      assert x.__struct__ == Query.HighlighterOriginal

      {alt_field, len, highlight} = {"description", 500, false}

      x = Query.HighlighterOriginal.new(alt_field)
      assert x.alternateField == alt_field
      assert is_nil(x.maxAlternateFieldLength)
      assert is_nil(x.highlightAlternate)

      x = Query.HighlighterOriginal.new(alt_field, len, highlight)
      assert x.alternateField == alt_field
      assert x.maxAlternateFieldLength == len
      assert x.highlightAlternate == highlight
    end

    test "HighlighterUnified" do
      x = Query.HighlighterUnified.new()
      assert x.__struct__ == Query.HighlighterUnified

      {d, s} = {true, :POSTINGS}

      x = Query.HighlighterUnified.new(d)
      assert x.defaultSummary == d
      assert is_nil(x.offsetSource)

      x = Query.HighlighterUnified.new(d, s)
      assert x.defaultSummary == d
      assert x.offsetSource == s
    end

    test "MoreLikeThis" do
      x = Query.MoreLikeThis.new()
      assert x.__struct__ == Query.MoreLikeThis

      {fl, count, min_tf, min_df, max_df} = {"words", 3, 10, 10, 10000}

      x = Query.MoreLikeThis.new(fl)
      assert x.fl == fl
      assert is_nil(x.count)
      assert is_nil(x.mintf)
      assert is_nil(x.mindf)
      assert is_nil(x.maxdf)

      x = Query.MoreLikeThis.new(fl, count)
      assert x.fl == fl
      assert x.count == count

      x = Query.MoreLikeThis.new(fl, count, min_tf, min_df, max_df)
      assert x.fl == fl
      assert x.count == count
      assert x.mintf == min_tf
      assert x.mindf == min_df
      assert x.maxdf == max_df
    end

    test "SpellCheck" do
      x = Query.SpellCheck.new()
      assert x.__struct__ == Query.SpellCheck

      x = Query.SpellCheck.new("javaw")
      assert x.q == "javaw"
      assert is_nil(x.collate)

      x = Query.SpellCheck.new("javaw", true)
      assert x.q == "javaw"
      assert x.collate == true
    end

    test "Standard" do
      x = Query.Standard.new()
      assert x.__struct__ == Query.Standard

      x = Query.Standard.new("jakarta^4 apache")
      assert x.q == "jakarta^4 apache"
    end

    test "Suggest" do
      x = Query.Suggest.new()
      assert x.__struct__ == Query.Suggest

      {q, count, dictionary, context} = {"ha", 10, ["name_infix", "ln_prefix"], "subscriber"}

      x = Query.Suggest.new(q)
      assert x.q == q
      assert is_nil(x.count)
      assert is_nil(x.dictionary)
      assert is_nil(x.cfq)

      x = Query.Suggest.new(q, count)
      assert x.q == q
      assert x.count == count

      x = Query.Suggest.new(q, count, dictionary, context)
      assert x.q == q
      assert x.count == count
      assert x.dictionary == dictionary
      assert x.cfq == context
    end

    test "Update" do
      x = Query.Update.new()
      assert x.__struct__ == Query.Update
    end
  end
end
