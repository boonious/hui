defmodule Hui.Http.Clients.HttpoisonTest do
  use ExUnit.Case, async: true

  alias Hui.Http
  alias Hui.Http.Clients.Httpoison

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

      {_, resp} = %Http{url: url} |> Httpoison.dispatch()

      assert resp.status == 200
      assert resp.body == "getting a response"
    end

    test "returns raw response body", %{bypass: bypass, bypass_url: url} do
      json = %{"responseHeader" => "123", "response" => %{"numFound" => 47}} |> Jason.encode!()

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, json)
      end)

      {_, resp} = %Http{url: url} |> Httpoison.dispatch()

      assert resp.body == json
    end
  end

  test "post/1", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.expect(bypass, fn conn ->
      assert {:ok, "request body", conn} = Plug.Conn.read_body(conn)
      assert conn.method == "POST"

      Plug.Conn.resp(conn, 200, "")
    end)

    {_, resp} = %Http{method: :post, url: bypass_url, body: "request body"} |> Httpoison.dispatch()
    assert 200 = resp.status
  end

  test "handle 404", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 404, "")
    end)

    {_, resp} = %Http{url: bypass_url} |> Httpoison.dispatch()
    assert 404 = resp.status
  end

  test "handle unreachable host", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.down(bypass)
    assert {:error, %Hui.Error{reason: :econnrefused}} == %Http{url: bypass_url} |> Httpoison.dispatch()
  end
end
