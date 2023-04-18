defmodule Hui.AdminTest do
  use ExUnit.Case, async: true

  import Fixtures.Admin
  import Hui.Admin
  import Mox

  alias Hui.Http.Client.Mock, as: ClientMock
  alias Hui.Query.Metrics

  describe "metrics/2" do
    test "via configured atomic endpoint" do
      metric_url = "http://localhost/solr/admin/metrics"
      Application.put_env(:hui, :test_endpoint, url: metric_url, headers: [{"accept", "application/json"}])

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      {:ok, resp} = metrics(:test_endpoint, group: "core")

      assert resp.status == 200
      assert resp.method == :get
      assert {"accept", "application/json"} in resp.headers
    end

    test "via binary endpoint" do
      metrics_url = "http://localhost/solr/admin/metrics"

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      {:ok, resp} = metrics(metrics_url, group: "core")
      assert resp.status == 200
    end

    test "request query string given metrics options" do
      metrics_url = "http://localhost/solr/admin/metrics"
      options = [group: "core", type: "timer", property: ["mean_ms", "max_ms", "p99_ms"], wt: "xml"]
      metrics_struct = struct(Metrics, options)

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      {:ok, resp} = metrics(metrics_url, options)

      assert [^metrics_url, "?", query_string] = resp.url
      assert query_string == Hui.Encoder.encode(metrics_struct)
    end

    test "returns parsed JSON response" do
      metrics_url = "http://localhost/solr/admin/metrics"
      metric_resp = metrics_json_response()

      options = [
        group: "core",
        type: "timer",
        key: [
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms",
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms"
        ],
        wt: "json"
      ]

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | body: metric_resp}} end)

      ClientMock
      |> expect(:handle_response, fn {:ok, %{body: ^metric_resp} = resp}, _req ->
        {:ok, %{resp | body: metric_resp |> Jason.decode!()}}
      end)

      assert {:ok, resp} = metrics(metrics_url, options)

      assert resp.body == %{
               "metrics" => %{
                 "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms" => 0.0,
                 "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms" => 0.0
               },
               "responseHeader" => %{"QTime" => 0, "status" => 0}
             }
    end
  end

  describe "ping/1" do
    test "via configured atomic endpoint" do
      url = "http://localhost:/solr/ping_test"
      Application.put_env(:hui, :test_endpoint, url: url, headers: [{"accept", "application/json"}])

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      {:ok, resp} = ping(:test_endpoint)
      assert resp.status == 200
      assert resp.method == :get
    end

    test "via binary endpoint" do
      url = "http://localhost/solr/collection/admin/ping"

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      {:ok, resp} = ping(url)
      assert resp.status == 200
      assert resp.method == :get
    end

    test "request query string" do
      url = "http://localhost:/solr/ping_test"
      Application.put_env(:hui, :test_endpoint, url: url, headers: [{"accept", "application/json"}])

      ClientMock
      |> expect(:dispatch, fn req ->
        assert ["http://localhost:/solr/ping_test/admin/ping", "?", ""] == req.url
        {:ok, req}
      end)

      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      ping(:test_endpoint)
    end

    test "responds with :pong and request time tuple when successful" do
      url = "http://localhost/solr/ping_test/admin/ping"

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)

      ClientMock
      |> expect(:handle_response, fn {:ok, resp}, _req ->
        {:ok, %{resp | body: successful_ping_json_response() |> Jason.decode!()}}
      end)

      assert {:pong, qtime} = ping(url)
      assert is_integer(qtime)
    end

    test "returns :pang when site is down" do
      url = "http://localhost/solr/ping_test/admin/ping"
      ClientMock |> expect(:dispatch, fn _req -> {:error, :econnrefused} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      assert :pang = ping(url)
    end

    test "returns :pang on non-200 response" do
      url = "http://localhost/solr/does_not_exists/admin/ping"
      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 404}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      assert :pang = ping(url)
    end

    test "returns :pang when non-existing atomic endpoint is used" do
      assert :pang = ping(:endpoint_not_configured)
    end
  end

  describe "ping/2" do
    test "request query string given ping options" do
      url = "http://localhost/solr/collection/admin/ping"
      options = [wt: "xml", distrib: true]

      ClientMock
      |> expect(:dispatch, fn req ->
        assert ["http://localhost/solr/collection/admin/ping", "?", "wt=xml&distrib=true"] == req.url
        {:ok, req}
      end)

      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      ping(url, options)
    end

    test "returns raw HTTP non-JSON response" do
      url = "http://localhost/solr/gettingstarted/admin/ping"
      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn {:ok, resp}, _req -> {:ok, %{resp | body: "raw resp"}} end)

      assert {:ok, %Hui.Http{body: "raw resp", status: 200}} = ping(url, wt: "xml")
    end

    test "returns raw HTTP response on non-200 response" do
      url = "http://localhost/not_avaiable/admin/ping"
      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 404}} end)
      ClientMock |> expect(:handle_response, fn {:ok, resp}, _req -> {:ok, %{resp | body: "not found"}} end)

      assert {:ok, %Hui.Http{body: "not found", status: 404}} = ping(url, wt: "xml", distrib: true)
    end
  end
end
