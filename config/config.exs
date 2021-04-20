use Mix.Config

# Could use another HTTP client that implements `Hui.Http` behaviour,
# instead of using the built-in httpc client. e.g. Hui.Http.Httpoison
# See: https://hexdocs.pm/hui/Hui.Http.html

# config :hui,
#   http_client: Hui.Http.Httpoison

# A default Solr endpoint may be configured via the 'default' property
config :hui, :default,
  url: "http://localhost:8983/solr/gettingstarted/select",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]

import_config "#{Mix.env()}.exs"
