defmodule HuiUpdateTest do
  use ExUnit.Case, async: true
  import TestHelpers

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc1.json")
    bypass = Bypass.open
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}
    {:ok, bypass: bypass, update_doc: update_doc, error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "update" do

    test "should post a single doc (Map)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data =  File.read!("./test/data/update_doc2c.json") 
      update_doc = expected_data |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      check_post_data_bypass_setup(context.bypass, expected_data)

      Hui.update(url, doc_map)
    end

    test "should post a single doc without commit (Map)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      doc_map = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }
      expected_data = %Hui.U{doc: doc_map} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)

      Hui.update(url, doc_map, false)
    end

    test "should post multiple docs (Map)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      check_post_data_bypass_setup(context.bypass, File.read!("./test/data/update_doc3c.json"))

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

      Hui.update(url, [doc_map1, doc_map2])
    end

    test "should post multiple docs without commit (Map)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
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
      expected_data = %Hui.U{doc: [doc_map1, doc_map2]} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)

      Hui.update(url, [doc_map1, doc_map2], false)
    end

    test "should post binary data", context do
      check_post_data_bypass_setup(context.bypass, context.update_doc)
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      Hui.Request.update(url, context.update_doc)
      Hui.update(url, context.update_doc)
    end

    test "should work with a configured URL key" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bypass = Bypass.open(port: 8989)
      check_post_data_bypass_setup(bypass, update_doc, "application/xml")
      Hui.Request.update(:update_test, update_doc)
      Hui.update(:update_test, update_doc)
    end

    test "should delete docs by ID", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = %Hui.U{delete_id: ["tt1650453", "tt1650453"], commit: true} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)
      Hui.delete(url, ["tt1650453", "tt1650453"])
    end

    test "should delete docs by query", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = %Hui.U{delete_query: ["name:Persona", "genre:Drama"], commit: true} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)
      Hui.delete_by_query(url, ["name:Persona", "genre:Drama"])
    end

    test "should commit docs", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = %Hui.U{commit: true, waitSearcher: true} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)
      Hui.commit(url)
    end

    test "should handle missing or malformed URL", context do
      assert {:error, context.error_einval} == Hui.update(nil, context.update_doc)
      assert {:error, context.error_einval} == Hui.update("", context.update_doc)
      assert {:error, context.error_einval} == Hui.update([], context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.update(:not_in_config_url, context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.update(%Hui.URL{url: "boo"}, context.update_doc)

      assert {:error, context.error_einval} == Hui.Request.update(nil, context.update_doc)
      assert {:error, context.error_einval} == Hui.Request.update("", context.update_doc)
      assert {:error, context.error_einval} == Hui.Request.update([], context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.Request.update(:not_in_config_url, context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.Request.update(%Hui.URL{url: "boo"}, context.update_doc)
    end

  end

  describe "update (bang)" do

    test "should post a single doc (Map)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data =  File.read!("./test/data/update_doc2c.json")
      update_doc = expected_data |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      check_post_data_bypass_setup(context.bypass, expected_data)

      Hui.update!(url, doc_map)
    end

    test "should post multiple docs (Map)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      check_post_data_bypass_setup(context.bypass, File.read!("./test/data/update_doc3c.json"))

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

      Hui.update!(url, [doc_map1, doc_map2])
    end

    test "should post binary data", context do
      update_resp = File.read!("./test/data/update_resp1.json")
      check_post_data_bypass_setup(context.bypass, context.update_doc, "application/json", update_resp)
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}

      Hui.update!(url, context.update_doc)

      bang = true
      resp  = Hui.Request.update(url, bang, context.update_doc)
      assert resp.body == update_resp |> Poison.decode!
    end

    test "should delete docs by ID", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = %Hui.U{delete_id: ["tt1650453", "tt1650453"], commit: true} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)
      Hui.delete!(url, ["tt1650453", "tt1650453"])
    end

    test "should delete docs by query", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = %Hui.U{delete_query: ["name:Persona"], commit: true} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)
      Hui.delete_by_query!(url, "name:Persona")
    end

    test "should commit docs", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = %Hui.U{commit: true, waitSearcher: true} |> Hui.U.encode
      check_post_data_bypass_setup(context.bypass, expected_data)
      Hui.commit!(url)
    end

    test "should handle missing or malformed URL", context do
      assert_raise Hui.Error, ":einval", fn -> Hui.update!(nil, context.update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.update!("", context.update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.update!([], context.update_doc) end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.update!(:url_in_config, context.update_doc) end

      bang = true
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update(nil, bang, context.update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update("", bang, context.update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update([], bang, context.update_doc) end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.Request.update(:url_in_config, bang, context.update_doc) end
    end
 
  end

end