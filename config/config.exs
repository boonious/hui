use Mix.Config

# Could use another HTTP client that implements `Hui.Http` behaviour,
# instead of using the built-in httpc client. e.g. Hui.Http.Httpoison
# See: https://hexdocs.pm/hui/Hui.Http.Client.html

# config :hui,
#   http_client: Hui.Http.Clients.Httpoison

config :hui,
  json_parser: Hui.ResponseParsers.JsonParser

import_config "#{Mix.env()}.exs"
