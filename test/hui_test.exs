defmodule HuiTest do
  use ExUnit.Case, async: true
  doctest Hui.URL

  # Using the config :hui, :default_url example
  test "default_url! should return a %Hui.URL stuct" do
    assert %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "select"} = Hui.URL.default_url!
  end

  test "Hui.URL.to_string should return a URL" do
    x = %Hui.URL{url: "http://localhost:8983/solr/newspapers", handler: "suggest"}
    y = %Hui.URL{url: "http://localhost:8983/solr/newspapers"}
    assert "http://localhost:8983/solr/newspapers/suggest" = x |> Hui.URL.to_string
    assert "http://localhost:8983/solr/newspapers/select" = y |> Hui.URL.to_string
  end

end