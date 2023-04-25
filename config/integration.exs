use Mix.Config

import_config "test.exs"

config :hui,
  http_client: Hui.Http.Clients.Httpc,
  test_url: "http://localhost:8983/solr/test_core1/select",
  json_parser: Hui.ResponseParsers.JsonParser
