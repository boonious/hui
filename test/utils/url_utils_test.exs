defmodule Hui.UtilsTest do
  use ExUnit.Case, async: true
  alias Hui.Utils.Url, as: UrlUtils

  # see `:hui, :default` test configuration
  test "parse_url/1 handles config endpoint with only url field" do
    url = "http://localhost:8983/solr/gettingstarted/select"
    assert {:ok, {^url, _headers, _options}} = UrlUtils.parse_endpoint(:default)
    assert url == UrlUtils.config_url(:default)
  end

  # see `:hui, :url_handler` test configuration
  test "parse_url/1 handles config endpoint with url, handler fields" do
    url = "http://localhost:8983/solr/gettingstarted"
    handler = "select"
    parsed_url = [url, "/", handler]

    assert {:ok, {^parsed_url, _headers, _options}} = UrlUtils.parse_endpoint(:url_handler)
    assert url == UrlUtils.config_url(:url_handler)
  end

  test "parse_url/1 handles config endpoint with url, collection fields" do
    bypass = Bypass.open()
    solr_url = "http://localhost:#{bypass.port}/solr"
    collection = "gettingstarted"
    headers = [{"accept", "application/json"}]
    options = [timeout: 10_000]
    parsed_url = [solr_url, "/", collection]

    Application.put_env(:hui, :utils_test_collection_endpoint,
      url: solr_url,
      collection: collection,
      headers: headers,
      options: options
    )

    assert {:ok, {^parsed_url, ^headers, ^options}} = UrlUtils.parse_endpoint(:utils_test_collection_endpoint)
    assert solr_url == UrlUtils.config_url(:utils_test_collection_endpoint)
  end

  test "parse_url/1 handles config endpoint with url, collection, handler fields" do
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

    assert {:ok, {^parsed_url, _headers, _options}} =
             UrlUtils.parse_endpoint(:utils_test_collection_with_handler_endpoint)

    assert solr_url == UrlUtils.config_url(:utils_test_collection_with_handler_endpoint)
  end
end
