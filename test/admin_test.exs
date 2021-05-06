defmodule Hui.AdminTest do
  use ExUnit.Case, async: true
  import Hui.Admin
  alias Hui.Query.Metrics

  defp metrics_json_response() do
    ~s"""
    {
      "responseHeader": {
          "status": 0,
          "QTime": 0
      },
      "metrics": {
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms": 0.0,
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms": 0.0
      }
    }
    """
  end

  defp metrics_xml_response() do
    ~s"""
    <?xml version="1.0" encoding="UTF-8"?>
    <response>

    <lst name="responseHeader">
      <int name="status">0</int>
      <int name="QTime">0</int>
    </lst>
    <lst name="metrics">
      <double name="solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms">0.0</double>
      <double name="solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms">0.0</double>
    </lst>
    </response>
    """
  end

  setup do
    %{bypass: Bypass.open()}
  end

  describe "metrics/2" do
    test "handles the configured default URL" do
      default_url = Application.get_env(:hui, :default)[:url] |> URI.parse()
      bypass = Bypass.open(port: default_url.port)

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "hitting default endpoint")
      end)

      {:ok, resp} = metrics(group: "core")
      assert resp.status == 200
      assert resp.body == "hitting default endpoint"
    end

    test "handles the atomic URL" do
      metrics_url = Application.get_env(:hui, :metrics)[:url] |> URI.parse()
      bypass = Bypass.open(port: metrics_url.port)

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "hitting endpoint")
      end)

      {:ok, resp} = metrics(group: "core")
      assert resp.status == 200
    end

    test "handles the binary URL", %{bypass: bypass} do
      metrics_url = "http://localhost:#{bypass.port}/solr/admin/metrics"

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "hitting default endpoint")
      end)

      {:ok, resp} = metrics(metrics_url, group: "core")
      assert resp.status == 200
    end

    test "makes the correct request given metrics options", %{bypass: bypass} do
      metrics_url = "http://localhost:#{bypass.port}/solr/admin/metrics"
      options = [group: "core", type: "timer", property: ["mean_ms", "max_ms", "p99_ms"], wt: "xml"]
      metrics_struct = struct(Metrics, options)

      Bypass.expect(bypass, fn conn ->
        assert conn.path_info == ["solr", "admin", "metrics"]
        assert conn.query_string == Hui.Encoder.encode(metrics_struct)
        Plug.Conn.resp(conn, 200, "solr metrics")
      end)

      metrics(metrics_url, options)
    end

    test "parses JSON response", %{bypass: bypass} do
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

      Bypass.expect(bypass, fn conn ->
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

    test "parses non-JSON response as raw text", %{bypass: bypass} do
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

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/xml; charset=UTF-8")
        |> Plug.Conn.resp(200, metrics_xml_response())
      end)

      assert {:ok, resp} = metrics(metrics_url, options)
      assert is_binary(resp.body)
      assert resp.body == metrics_xml_response()
      assert {"content-type", "application/xml; charset=UTF-8"} in resp.headers
    end
  end
end
