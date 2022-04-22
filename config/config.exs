use Mix.Config

# Could use another HTTP client that implements `Hui.Http` behaviour,
# instead of using the built-in httpc client. e.g. Hui.Http.Httpoison
# See: https://hexdocs.pm/hui/Hui.Http.html

# config :hui,
#   http_client: Hui.Http.Httpoison

import_config "#{Mix.env()}.exs"
