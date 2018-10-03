defmodule HuiUpdateTest do
  use ExUnit.Case, async: true

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc1.json")
    bypass = Bypass.open
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}
    {:ok, bypass: bypass, update_doc: update_doc, error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "Request.update" do

    test "should post binary data", context do
      Bypass.expect context.bypass, fn conn ->
        assert "/update" == conn.request_path
        assert "POST" == conn.method
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == context.update_doc
        Plug.Conn.resp(conn, 200, "")
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      Hui.Request.update(url, context.update_doc)
    end

    test "should work with a configured URL key" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bypass = Bypass.open(port: 8989)
      Bypass.expect bypass, fn conn ->
        assert "/solr/articles/update" == conn.request_path
        assert "POST" == conn.method
        assert conn.req_headers |> Enum.member? {"content-type", "application/xml"}
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == update_doc
        Plug.Conn.resp(conn, 200, "")
      end

      Hui.Request.update(:update_test, update_doc)
    end

    test "should handle missing or malformed URL", context do
      update_doc = File.read!("./test/data/update_doc2.xml")
      assert {:error, context.error_einval} == Hui.Request.update(nil, update_doc)
      assert {:error, context.error_einval} == Hui.Request.update("", update_doc)
      assert {:error, context.error_einval} == Hui.Request.update([], update_doc)
      assert {:error, context.error_nxdomain} == Hui.Request.update(:not_in_config_url, update_doc)
      assert {:error, context.error_nxdomain} == Hui.Request.update(%Hui.URL{url: "boo"}, update_doc)
    end

  end

  describe "Request.update (bang)" do

    test "should post binary data", context do
      update_resp = File.read!("./test/data/update_resp1.json")
      Bypass.expect context.bypass, fn conn ->
        assert "/update" == conn.request_path
        assert "POST" == conn.method
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == context.update_doc
        Plug.Conn.resp(conn, 200, update_resp)
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update"}

      bang = true
      resp  = Hui.Request.update(url, bang, context.update_doc)
      assert resp.body == update_resp |> Poison.decode!
    end

    test "should work with a configured URL key" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bypass = Bypass.open(port: 8989)
      Bypass.expect bypass, fn conn ->
        assert "/solr/articles/update" == conn.request_path
        assert "POST" == conn.method
        assert conn.req_headers |> Enum.member? {"content-type", "application/xml"}
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == update_doc
        Plug.Conn.resp(conn, 200, "")
      end

      bang = true
      Hui.Request.update(:update_test, bang, update_doc)
    end

    test "should handle missing or malformed URL" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bang = true
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update(nil, bang, update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update("", bang, update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update([], bang, update_doc) end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.Request.update(:url_in_config, bang, update_doc) end
    end

  end

end