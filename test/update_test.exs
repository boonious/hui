defmodule HuiUpdateTest do
  use ExUnit.Case, async: true

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc1.json")
    bypass = Bypass.open
    {:ok, bypass: bypass, update_doc: update_doc}
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
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update"}
      Hui.Request.update(url, context.update_doc)
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

  end

end