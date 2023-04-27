for client <- Hui.Http.Client.all_clients() do
  test_module = Module.concat(client, ClientTest)

  defmodule test_module do
    use ExUnit.Case, async: true

    alias Hui.Error
    alias Hui.Http

    import TestHelpers, only: [body: 1, is_http_client_error: 1, status_code: 1]

    @client client |> Module.split() |> List.last()

    # hard-code specific client test options for now
    @http_options %{
      Hui.Http.Clients.Finch => [receive_timeout: 5_000, pool_timeout: 5_000],
      Hui.Http.Clients.Httpc => [timeout: 5_000, connect_timeout: 5_000, sync: true, body_format: :string],
      Hui.Http.Clients.Httpoison => [max_redirect: 3, recv_timeout: 10_000, hackney: [pool: :test_pool]]
    }

    setup do
      bypass = Bypass.open()
      bypass_url = "http://localhost:#{bypass.port}"
      http_options = @http_options[unquote(client)] || [timeout: 5_000]

      get_req = %Http{
        body: nil,
        client: unquote(client),
        headers: [{"accept", "application/json"}],
        method: :get,
        options: http_options,
        response_parser: Hui.ResponseParsers.JsonParser,
        status: nil,
        url: [bypass_url, "/solr/collection/select?", "q=solr+rocks"]
      }

      post_req = %Http{
        body: "<delete><id>9780141981727</id></delete>",
        client: unquote(client),
        headers: [{"content-type", "application/xml"}],
        method: :post,
        options: http_options,
        response_parser: Hui.ResponseParsers.JsonParser,
        status: nil,
        url: [bypass_url, "/solr/collection/update"]
      }

      serp = File.read!("./test/fixtures/search_response.json")

      %{bypass: bypass, bypass_url: bypass_url, get_req: get_req, post_req: post_req, serp: serp}
    end

    describe "#{@client} dispatch/1" do
      test "GET response status", %{bypass: bypass, get_req: req} do
        Bypass.expect(bypass, fn conn ->
          assert conn.method == "GET"
          Plug.Conn.resp(conn, 200, "getting a response")
        end)

        assert {:ok, http_resp} = req |> req.client.dispatch()
        assert status_code(http_resp) == 200
      end

      test "POST response status and body", %{bypass: bypass, post_req: req} do
        Bypass.expect(bypass, fn conn ->
          assert conn.method == "POST"
          assert {:ok, body, conn} = Plug.Conn.read_body(conn)
          assert body == req.body

          Plug.Conn.resp(conn, 200, "getting a response")
        end)

        assert {:ok, http_resp} = req |> req.client.dispatch()
        assert status_code(http_resp) == 200
      end

      test "returns raw response body", %{bypass: bypass, get_req: req, serp: serp} do
        Bypass.expect(bypass, fn conn ->
          Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
          |> Plug.Conn.resp(200, serp)
        end)

        assert {:ok, http_resp} = req |> req.client.dispatch()
        assert body(http_resp) == serp
      end

      test "handles non-200 status response", %{bypass: bypass, get_req: req} do
        Bypass.expect(bypass, fn conn ->
          Plug.Conn.resp(conn, 404, "")
        end)

        assert {:ok, http_resp} = req |> req.client.dispatch()
        assert status_code(http_resp) == 404
      end

      test "handles error response", %{bypass: bypass, get_req: req} do
        Bypass.down(bypass)
        assert {:error, error} = req |> req.client.dispatch()
        assert is_http_client_error(error)
      end
    end

    describe "#{@client} handle_response/2" do
      test "decodes JSON response given a parser", %{bypass: bypass, get_req: req, serp: serp} do
        Bypass.expect(bypass, fn conn ->
          Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
          |> Plug.Conn.resp(200, serp)
        end)

        assert {:ok, resp} = req |> req.client.dispatch() |> req.client.handle_response(req)
        assert resp.body == serp |> Jason.decode!()
      end

      test "returns raw JSON response without a parser", %{bypass: bypass, get_req: req, serp: serp} do
        req = %{req | response_parser: nil}

        Bypass.expect(bypass, fn conn ->
          Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
          |> Plug.Conn.resp(200, serp)
        end)

        assert {:ok, resp} = req |> req.client.dispatch() |> req.client.handle_response(req)
        assert resp.body == serp
      end

      # XML parser not available yet
      test "returns raw non-JSON response", %{bypass: bypass, get_req: req} do
        xml_serp = File.read!("./test/fixtures/search_response.xml")

        Bypass.expect(bypass, fn conn ->
          Plug.Conn.put_resp_header(conn, "content-type", "application/xml;charset=utf-8")
          |> Plug.Conn.resp(200, xml_serp)
        end)

        assert {:ok, resp} = req |> req.client.dispatch() |> req.client.handle_response(req)
        assert resp.body == xml_serp
      end

      test "returns error when endpoint is down", %{bypass: bypass, get_req: req} do
        Bypass.down(bypass)
        assert {:error, %Error{}} = req |> req.client.dispatch() |> req.client.handle_response(req)
      end
    end
  end
end
