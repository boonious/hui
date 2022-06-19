defmodule Hui.Integration.HuiTest do
  use ExUnit.Case, async: true
  alias Hui.Http

  @moduletag :integration

  @endpoint Application.compile_env(:hui, :test_url)

  describe "search/2" do
    test "handles keyword query" do
      query = [q: "*", rows: 10, fq: ["cat:electronics"]]

      assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(@endpoint, query)
      assert url == [@endpoint, "?", "q=%2A&rows=10&fq=cat%3Aelectronics"]

      assert %{
               "response" => %{"docs" => docs, "numFound" => hits, "start" => 0},
               "responseHeader" => %{"params" => params}
             } = body

      assert length(docs) > 0
      assert hits > 0
      assert params == %{"fq" => "cat:electronics", "q" => "*", "rows" => "10"}
    end
  end
end
