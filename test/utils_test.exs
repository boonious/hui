defmodule Hui.UtilsTest do
  use ExUnit.Case, async: true
  alias Hui.Utils

  # see `:hui, :default` test configuration
  test "parse_url/1 handles config endpoint with only url field" do
    url = "http://localhost:8983/solr/gettingstarted/select"

    assert {:ok, {^url, _headers, _options}} = Utils.parse_endpoint(:default)
    assert url == Utils.config_url(:default)
  end

  # see `:hui, :url_handler` test configuration
  test "parse_url/1 handles config endpoint with url, handler fields" do
    url = "http://localhost:8983/solr/gettingstarted"
    handler = "select"
    parsed_url = [url, "/", handler]

    assert {:ok, {^parsed_url, _headers, _options}} = Utils.parse_endpoint(:url_handler)
    assert url == Utils.config_url(:url_handler)
  end

  # see `:hui, :url_collection` test configuration
  test "parse_url/1 handles config endpoint with url, collection fields" do
    url = "http://localhost:8983/solr"
    collection = "gettingstarted"
    parsed_url = [url, "/", collection]

    assert {:ok, {^parsed_url, _headers, _options}} = Utils.parse_endpoint(:url_collection)
    assert url == Utils.config_url(:url_collection)
  end

  # see `:hui, :url_collection_handler` test configuration
  test "parse_url/1 handles config endpoint with url, collection, handler fields" do
    url = "http://localhost:8983/solr"
    collection = "gettingstarted"
    handler = "update"
    parsed_url = [url, "/", collection, "/", handler]

    assert {:ok, {^parsed_url, _headers, _options}} = Utils.parse_endpoint(:url_collection_handler)
    assert url == Utils.config_url(:url_collection_handler)
  end
end
