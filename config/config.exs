use Mix.Config

# A default Solr endpoint may be configured via the 'default' property
config :hui, :default,
  # core or collection endpoint
  url: "http://localhost:8983/solr/gettingstarted",
  # optional
  handler: "select",
  # optional
  headers: [{"accept", "application/json"}],
  # optional
  options: [timeout: 10000]

# Additional Solr endpoints may be configured using any config key, e.g. :suggester.
# Use Hui.URL.config_url(:suggester) function to retrieve the corresponding URL struct
config :hui, :suggester,
  url: "http://localhost:8983/solr/collection",
  handler: "suggest"

config :hui, :library,
  url: "http://localhost:8984/solr/articles",
  handler: "dismax"

config :hui, :update_test,
  url: "http://localhost:8989/solr/articles",
  handler: "update",
  headers: [{"content-type", "application/xml"}]

config :hui, :update_struct_test,
  url: "http://localhost:9000/solr/articles",
  handler: "update",
  headers: [{"content-type", "application/json"}]
