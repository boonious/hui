defmodule HuiStructUpdateTest do
  use ExUnit.Case, async: true

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc2.json") 
    bypass = Bypass.open
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}
    {:ok, bypass: bypass, update_doc: update_doc, error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "Hui.U struct" do

    test "should encode a single doc", context do
      update_doc =  context.update_doc |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      expected_data = update_doc |> Poison.encode!

      x = %Hui.U{doc: doc_map}
      assert Hui.U.encode(x) == expected_data
    end

    test "should encode multiple docs" do
      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }
      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto",
         "Yoshio Harada"],
        "desc" => "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      x = %Hui.U{doc: [doc_map1, doc_map2]}
      assert Hui.U.encode(x) == File.read!("./test/data/update_doc3.json")
    end
 
    test "update should post a single doc to a URL (struct)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      update_doc =  context.update_doc |> Poison.decode!
      expected_data = update_doc |> Poison.encode!

      Bypass.expect context.bypass, fn conn ->
        assert "/update" == conn.request_path
        assert "POST" == conn.method
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == expected_data
        Plug.Conn.resp(conn, 200, "")
      end

      doc_map = update_doc["add"]["doc"]
      x = %Hui.U{doc: doc_map}
      Hui.Request.update(url, x)
    end

    test "update should post multiple docs to a URL (struct)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = File.read!("./test/data/update_doc3.json")

      Bypass.expect context.bypass, fn conn ->
        assert "/update" == conn.request_path
        assert "POST" == conn.method
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == expected_data
        Plug.Conn.resp(conn, 200, "")
      end

      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }
      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto",
         "Yoshio Harada"],
        "desc" => "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }
      x = %Hui.U{doc: [doc_map1, doc_map2]}
      Hui.Request.update(url, x)
    end

  end

end