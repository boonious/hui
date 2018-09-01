use Mix.Config

# A default Solr endpoint may be configured via the 'default_url' property
#
config :hui, :default_url, # default endpoint
  url: "http://localhost:8983/solr/gettingstarted", # core or collection endpoint
  handler: "select" # optional

# Additional Solr endpoints may be configured using any config key, e.g. :suggester.
# Use Hui.URL.config_url(:suggester) function to retrieve the corresponding URL struct
#
config :hui, :suggester,
  url: "http://localhost:8983/solr/collection",
  handler: "suggest"