use Mix.Config

# A default Solr endpoint may be configured via the 'default' property
config :hui, :default,
  url: "http://localhost:8983/solr/gettingstarted/select",
  headers: [{"accept", "application/json"}],
  options: [timeout: 10000]

config :hui, :metrics,
  url: "http://localhost:8983/solr/admin/metrics",
  headers: [{"accept", "application/json"}]

# Additional Solr endpoints may be configured with any atomic key, e.g. :suggester.
config :hui, :suggester, url: "http://localhost:8983/solr/collection/suggest"
config :hui, :library, url: "http://localhost:8984/solr/articles/dismax"

config :hui, :update_test,
  url: "http://localhost:8989/solr/articles/update",
  headers: [{"content-type", "application/xml"}]

config :hui, :update_struct_test,
  url: "http://localhost:9000/solr/articles/update",
  headers: [{"content-type", "application/json"}]
