defmodule Hui.AdminTest do
  use ExUnit.Case, async: true

  import Hui.Admin
  import Fixtures.Admin

  alias Hui.Query.Metrics

  setup_all context do
    bypass = Bypass.open()

    Application.put_env(:hui, :admin_test_metric_endpoint,
      url: "http://localhost:#{bypass.port}/solr/admin/metrics",
      headers: [{"accept", "application/json"}]
    )

    bypass = Bypass.open()
    Application.put_env(:hui, :admin_test_ping_endpoint,
      url: "http://localhost:#{bypass.port}/solr/ping_test",
      headers: [{"accept", "application/json"}]
    )

    Map.merge(context, %{metric_endpoint: :admin_test_metric_endpoint, ping_endpoint: :admin_test_ping_endpoint})
  end

  setup do
    %{bypass: Bypass.open()}
  end

  describe "metrics/2" do
    test "from configured endpoint", %{metric_endpoint: endpoint} do
      metrics_url = Application.get_env(:hui, endpoint)[:url] |> URI.parse()
      bypass = Bypass.open(port: metrics_url.port)

      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "hitting endpoint")
      end)

      {:ok, resp} = metrics(endpoint, group: "core")
      assert resp.status == 200
    end

    test "from binary endpoint", %{bypass: bypass} do
      metrics_url = "http://localhost:#{bypass.port}/solr/admin/metrics"

      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "hitting default endpoint")
      end)

      {:ok, resp} = metrics(metrics_url, group: "core")
      assert resp.status == 200
    end

    test "sends correct request query given metrics options", %{bypass: bypass} do
      metrics_url = "http://localhost:#{bypass.port}/solr/admin/metrics"
      options = [group: "core", type: "timer", property: ["mean_ms", "max_ms", "p99_ms"], wt: "xml"]
      metrics_struct = struct(Metrics, options)

      Bypass.expect_once(bypass, fn conn ->
        assert conn.path_info == ["solr", "admin", "metrics"]
        assert conn.query_string == Hui.Encoder.encode(metrics_struct)
        Plug.Conn.resp(conn, 200, "solr metrics")
      end)

      metrics(metrics_url, options)
    end

    test "returns parsed JSON response", %{bypass: bypass} do
      metrics_url = "http://localhost:#{bypass.port}/solr/admin/metrics"

      options = [
        group: "core",
        type: "timer",
        key: [
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms",
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms"
        ],
        wt: "json"
      ]

      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, metrics_json_response())
      end)

      assert {:ok, resp} = metrics(metrics_url, options)

      assert resp.body == %{
               "metrics" => %{
                 "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms" => 0.0,
                 "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms" => 0.0
               },
               "responseHeader" => %{"QTime" => 0, "status" => 0}
             }

      assert {"content-type", "application/json"} in resp.headers
    end

    test "returns raw non-JSON response", %{bypass: bypass} do
      metrics_url = "http://localhost:#{bypass.port}/solr/admin/metrics"

      options = [
        group: "core",
        type: "timer",
        key: [
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms",
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms"
        ],
        wt: "xml"
      ]

      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/xml; charset=UTF-8")
        |> Plug.Conn.resp(200, metrics_xml_response())
      end)

      assert {:ok, resp} = metrics(metrics_url, options)
      assert is_binary(resp.body)
      assert resp.body == metrics_xml_response()
      assert {"content-type", "application/xml; charset=UTF-8"} in resp.headers
    end
  end

  describe "ping/1" do
    test "configured endpoint", %{ping_endpoint: endpoint} do
      url = Application.get_env(:hui, endpoint)[:url] |> URI.parse()
      bypass = Bypass.open(port: url.port)

      Bypass.expect_once(bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end)
      ping(endpoint)
    end

    test "binary endpoint", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/collection/admin/ping"
      Bypass.expect_once(bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end)
      ping(url)
    end

    test "sends the correct request", %{ping_endpoint: endpoint} do
      url = Application.get_env(:hui, endpoint)[:url] |> URI.parse()
      bypass = Bypass.open(port: url.port)

      Bypass.expect_once(bypass, fn conn ->
        assert conn.path_info == ["solr", "ping_test", "admin", "ping"]
        assert conn.query_string == ""
        Plug.Conn.resp(conn, 200, "")
      end)

      ping(endpoint)
    end

    test "responds with :pong and request time tuple when successful", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/ping_test/admin/ping"

      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, successful_ping_json_response())
      end)

      assert {:pong, 13} = ping(url)
    end

    test "returns :pang when site is down", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/ping_test/admin/ping"
      Bypass.down(bypass)
      assert :pang = ping(url)
    end

    test "returns :pang on non-200 response", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/does_not_exists/admin/ping"

      Bypass.expect_once(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "text/html;charset=iso-8859-1")
        |> Plug.Conn.resp(404, "not found")
      end)

      assert :pang = ping(url)
    end

    test "returns :pang when non-existing atomic endpoint is used" do
      assert :pang = ping(:endpoint_not_configured)
    end
  end

  describe "ping/2" do
    test "sends correct request given ping options", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/collection/admin/ping"
      options = [wt: "xml", distrib: true]

      Bypass.expect_once(bypass, fn conn ->
        assert conn.path_info == ["solr", "collection", "admin", "ping"]
        assert conn.query_string == "wt=xml&distrib=true"
        Plug.Conn.resp(conn, 200, "")
      end)

      ping(url, options)
    end

    test "returns raw HTTP response", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/gettingstarted/admin/ping"

      Bypass.expect(bypass, fn conn -> Plug.Conn.resp(conn, 200, "raw response") end)
      assert {:ok, %Hui.Http{body: "raw response", status: 200}} = ping(url, wt: "xml")
      assert {:ok, %Hui.Http{body: "raw response", status: 200}} = ping(url, wt: "JSON", distrib: false)
    end

    test "returns raw HTTP response on non-200 response", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/not_avaiable/admin/ping"

      Bypass.expect_once(bypass, fn conn -> Plug.Conn.resp(conn, 404, "not found") end)
      assert {:ok, %Hui.Http{body: "not found", status: 404}} = ping(url, wt: "xml", distrib: true)
    end

    test "returns error tuple when site is down", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/solr/gettingstarted/admin/ping"
      Bypass.down(bypass)
      assert {:error, %Hui.Error{reason: :failed_connect}} = ping(url, wt: "xml", distrib: true)
    end
  end
end
