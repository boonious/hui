defmodule HuiUrlTest do
  use ExUnit.Case, async: true
  doctest Hui.URL

  describe "Hui.URL" do
    # Using the config :hui, :default_url example in config.exs
    test "default_url! should return %Hui.URL stuct" do
      x = Hui.URL.default_url!()
      assert Hui.URL = x.__struct__
      assert x.url != nil
      assert x.handler != nil
    end

    # Using the config :hui examples in config.exs
    test "configured_url should return %Hui.URL stuct for a given config key" do
      assert {:ok, %Hui.URL{url: _, handler: _}} = Hui.URL.configured_url(:default)
      assert {:ok, %Hui.URL{url: _, handler: _}} = Hui.URL.configured_url(:suggester)

      assert {:error, %Hui.Error{reason: :nxdomain}} = Hui.URL.configured_url(:random_url_not_in_config)
    end

    # Using the config :hui examples in config.exs
    test "configured_url should return configured headers and options in %Hui.URL stuct" do
      {:ok, %Hui.URL{url: _, handler: _, headers: headers, options: options}} = Hui.URL.configured_url(:default)

      refute headers == []
      refute options == []
    end

    test "to_string should return a URL" do
      x = %Hui.URL{url: "http://localhost:8983/solr/newspapers", handler: "suggest"}
      y = %Hui.URL{url: "http://localhost:8983/solr/newspapers"}
      assert x |> Hui.URL.to_string() == "http://localhost:8983/solr/newspapers/suggest"
      assert y |> Hui.URL.to_string() == "http://localhost:8983/solr/newspapers/select"

      assert to_string(x) == "http://localhost:8983/solr/newspapers/suggest"
      assert to_string(y) == "http://localhost:8983/solr/newspapers/select"
    end
  end
end
