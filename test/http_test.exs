defmodule Hui.HttpTest do
  use ExUnit.Case, async: true

  import Fixtures.Update
  import Mox

  alias Hui.Http
  alias Hui.Http.Client.Mock

  test "get/3" do
    resp = File.read!("./test/fixtures/search_response.json")
    resp_decoded = resp |> Jason.decode!()

    Mock |> expect(:dispatch, fn %Http{} = req -> {:ok, %{req | body: resp}} end)

    Mock
    |> expect(:handle_response, fn {:ok, %Http{body: ^resp} = req}, _parser ->
      {:ok, %{req | body: resp_decoded}}
    end)

    assert {:ok, %Http{body: ^resp_decoded}} = Http.get("http://solr_endpoint", q: "get test")
  end

  test "post/3" do
    docs = multi_docs()
    docs_encoded = docs |> Jason.encode!()

    Mock |> expect(:dispatch, fn %Http{body: ^docs_encoded} = req -> {:ok, req} end)
    Mock |> expect(:handle_response, fn {:ok, %Http{} = req}, _parser -> {:ok, req} end)

    assert {:ok, %Http{}} = Http.post("http://solr_endpoint", docs_encoded)
  end
end
