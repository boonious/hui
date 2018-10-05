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

  describe "Request.update" do

    test "should post binary data", context do
      check_post_data_bypass_setup(context.bypass, context.update_doc)
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      Hui.Request.update(url, context.update_doc)
    end

    test "should work with a configured URL key" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bypass = Bypass.open(port: 8989)
      check_post_data_bypass_setup(bypass, update_doc, "application/xml")
      Hui.Request.update(:update_test, update_doc)
    end

    test "should handle missing or malformed URL", context do
      assert {:error, context.error_einval} == Hui.Request.update(nil, context.update_doc)
      assert {:error, context.error_einval} == Hui.Request.update("", context.update_doc)
      assert {:error, context.error_einval} == Hui.Request.update([], context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.Request.update(:not_in_config_url, context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.Request.update(%Hui.URL{url: "boo"}, context.update_doc)
    end

  end

  describe "Request.update (bang)" do

    test "should post binary data", context do
      update_resp = File.read!("./test/data/update_resp1.json")
      check_post_data_bypass_setup(context.bypass, context.update_doc, "application/json", update_resp)
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}

      bang = true
      resp  = Hui.Request.update(url, bang, context.update_doc)
      assert resp.body == update_resp |> Poison.decode!
    end

    test "should handle missing or malformed URL", context do
      bang = true
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update(nil, bang, context.update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update("", bang, context.update_doc) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.update([], bang, context.update_doc) end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.Request.update(:url_in_config, bang, context.update_doc) end
    end

  end

end