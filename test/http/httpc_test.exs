defmodule Hui.Http.HttpcTest do
  use ExUnit.Case, async: true

  alias Hui.Http.Httpc
  alias Hui.Http

  setup do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"

    %{bypass: bypass, bypass_url: bypass_url}
  end

  describe "get/1" do
    test "response status and body", %{bypass: bypass, bypass_url: url} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "getting a response")
      end)

      {_, resp} = %Http{url: url} |> Httpc.dispatch()

      assert resp.status == 200
      assert resp.body == "getting a response"
    end

    test "returns a map body for json response", %{bypass: bypass, bypass_url: url} do
      json = %{"responseHeader" => "123", "response" => %{"numFound" => 47}} |> Jason.encode!()

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, json)
      end)

      {_, resp} = %Http{url: url} |> Httpc.dispatch()

      assert resp.body == json |> Jason.decode!()
    end

    test "returns the unparsed binary body if json response is invalid", %{bypass: bypass, bypass_url: url} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, "non json response")
      end)

      {_, resp} = %Http{url: url} |> Httpc.dispatch()
      assert resp.body == "non json response"
    end
  end
end
