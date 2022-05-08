defmodule Hui.Utils.UrlTest do
  use ExUnit.Case, async: true

  alias Hui.ResponseParsers.JsonParser
  alias Hui.Utils.ParserType
  alias Hui.Utils.Url, as: UrlUtils

  describe "parse_url/1" do
    # see `:hui, :default` test configuration
    test " fetches url from config" do
      url = Application.get_env(:hui, :default)[:url]
      assert {:ok, {^url, _headers, _options, _parser}} = UrlUtils.parse_endpoint(:default)
    end

    # see `:hui, :url_handler` test configuration
    test "builds url with handler field" do
      url = "http://localhost:8983/solr/gettingstarted"
      handler = "select"
      parsed_url = [url, "/", handler]

      assert {:ok, {^parsed_url, _headers, _options, _parser}} = UrlUtils.parse_endpoint(:url_handler)
    end

    test "builds url, collection fields" do
      bypass = Bypass.open()
      solr_url = "http://localhost:#{bypass.port}/solr"
      collection = "gettingstarted"
      parsed_url = [solr_url, "/", collection]

      endpoint_atom = "utils_test_endpoint#{bypass.port}" |> String.to_atom()

      Application.put_env(:hui, endpoint_atom,
        url: solr_url,
        collection: collection
      )

      assert {:ok, {^parsed_url, _headers, _options, _parser}} = UrlUtils.parse_endpoint(endpoint_atom)
    end

    test "builds url with collection, handler fields" do
      bypass = Bypass.open()
      solr_url = "http://localhost:#{bypass.port}/solr"
      collection = "gettingstarted"
      handler = "update"
      parsed_url = [solr_url, "/", collection, "/", handler]

      Application.put_env(:hui, :utils_test_collection_with_handler_endpoint,
        url: solr_url,
        collection: collection,
        handler: handler
      )

      assert {:ok, {^parsed_url, _headers, _options, _parser}} =
               UrlUtils.parse_endpoint(:utils_test_collection_with_handler_endpoint)
    end

    test "fetches headers, options from config" do
      bypass = Bypass.open()
      headers = [{"accept", "application/json"}]
      options = [timeout: 10_000]
      endpoint_atom = "utils_test_endpoint#{bypass.port}" |> String.to_atom()

      Application.put_env(:hui, endpoint_atom,
        url: "http://localhost:#{bypass.port}/solr",
        headers: headers,
        options: options
      )

      assert {:ok, {_url, ^headers, ^options, _parser}} = UrlUtils.parse_endpoint(endpoint_atom)
    end

    test "sets parser as not configured when non set in config" do
      bypass = Bypass.open()
      endpoint_atom = "utils_test_endpoint#{bypass.port}" |> String.to_atom()

      Application.put_env(:hui, endpoint_atom, url: "http://localhost:#{bypass.port}/solr")

      assert {:ok, {_url, _headers, _options, parser}} = UrlUtils.parse_endpoint(endpoint_atom)
      assert parser == ParserType.not_configured()
    end

    test "fetches configured parser option" do
      bypass = Bypass.open()
      endpoint_atom = "utils_test_endpoint#{bypass.port}" |> String.to_atom()

      Application.put_env(:hui, endpoint_atom,
        url: "http://localhost:#{bypass.port}/solr",
        options: [timeout: 10_000, response_parser: JsonParser]
      )

      assert {:ok, {_url, _headers, _options, JsonParser}} = UrlUtils.parse_endpoint(endpoint_atom)
    end
  end
end
