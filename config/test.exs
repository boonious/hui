use Mix.Config

# variouns Solr endpoints may be configured with any atomic key
config :hui, :default,
  url: "http://localhost:8983/solr/gettingstarted/select",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]

config :hui, :metrics,
  url: "http://localhost:8983/solr/admin/metrics",
  headers: [{"accept", "application/json"}]

config :hui, :suggester, url: "http://localhost:8983/solr/collection/suggest"
config :hui, :library, url: "http://localhost:8984/solr/articles/dismax"

config :hui, :update_test,
  url: "http://localhost:8989/solr/articles/update",
  headers: [{"content-type", "application/xml"}]

config :hui, :update_struct_test,
  url: "http://localhost:9000/solr/articles/update",
  headers: [{"content-type", "application/json"}]

config :hui, :url_handler,
  url: "http://localhost:8983/solr/gettingstarted",
  handler: "select",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]

config :hui, :url_collection,
  url: "http://localhost:8983/solr",
  collection: "gettingstarted",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]

config :hui, :url_collection_handler,
  url: "http://localhost:8983/solr",
  collection: "gettingstarted",
  handler: "update",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]

config :hui, :gettingstarted,
  url: "http://localhost:8983/solr/gettingstarted",
  handler: "select",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]
