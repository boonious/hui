use Mix.Config

# A default Solr endpoint may be configured via the 'default_url' property
#
config :hui, :default_url, # default endpoint
  url: "http://localhost:8983/solr/gettingstarted",
  handler: "select" # optional
