defmodule Fixtures.Admin do
  def metrics_json_response() do
    ~s"""
    {
      "responseHeader": {
          "status": 0,
          "QTime": 0
      },
      "metrics": {
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms": 0.0,
          "solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms": 0.0
      }
    }
    """
  end

  def metrics_xml_response() do
    ~s"""
    <?xml version="1.0" encoding="UTF-8"?>
    <response>

    <lst name="responseHeader">
      <int name="status">0</int>
      <int name="QTime">0</int>
    </lst>
    <lst name="metrics">
      <double name="solr.core.gettingstarted.shard2.replica_n6:QUERY./browse.requestTimes:mean_ms">0.0</double>
      <double name="solr.core.gettingstarted.shard2.replica_n6:QUERY./query.requestTimes:mean_ms">0.0</double>
    </lst>
    </response>
    """
  end

  def successful_ping_json_response() do
    ~s"""
    {
      "responseHeader": {
        "zkConnected": true,
        "status": 0,
        "QTime": 13,
        "params": {
            "q": "{!lucene}*:*",
            "distrib": "false",
            "df": "_text_",
            "rows": "10",
            "echoParams": "all"
        }
      },
      "status": "OK"
    }
    """
  end
end
