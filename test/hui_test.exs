defmodule HuiTest do
  use ExUnit.Case, async: true
  doctest Hui.URL

  describe "Hui.URL" do

    # Using the config :hui, :default_url example in config.exs
    test "default_url! should return %Hui.URL stuct" do
      assert %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "select"} = Hui.URL.default_url!
    end

    # Using the config :hui, :suggester example in config.exs
    test "url function should return %Hui.URL stuct for a given config" do
      assert {:ok, %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}} = Hui.URL.configured_url(:suggester)
      assert {:error, "URL not found in configuration"} = Hui.URL.configured_url(:random_url_not_in_config)
    end

    test "to_string should return a URL" do
      x = %Hui.URL{url: "http://localhost:8983/solr/newspapers", handler: "suggest"}
      y = %Hui.URL{url: "http://localhost:8983/solr/newspapers"}
      assert "http://localhost:8983/solr/newspapers/suggest" = x |> Hui.URL.to_string
      assert "http://localhost:8983/solr/newspapers/select" = y |> Hui.URL.to_string
    end

  end

end