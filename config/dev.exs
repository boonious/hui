use Mix.Config

config :hui, :gettingstarted,
  url: "http://localhost:8983/solr/gettingstarted",
  handler: "select",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]
