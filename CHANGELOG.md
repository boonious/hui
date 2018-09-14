# Changelog

## 0.5.3 (2018-09-14)

* Support JSON and XML response writer parameters in Hui.Q struct

## 0.5.2 (2018-09-13)

* New q/2, search/3 features for structured querying and faceting - Solr standard parser
* search/2, q/1 accepts query struct (Hui.Q) parameters
* Search.search/2 works with query and faceting structs (Hui.Q, Hui.F) parameters

## 0.5.1 (2018-09-12)

* URL encoder renders faceting structs to string according to Solr prefix syntax e.g. "field" -> "facet.field"
* URL encoder for "per field" faceting (ranges, intervals) use cases, e.g. "gap" -> "f.[field].range.gap"
* Consolidate URL.encode_query/1; deprecate Q.encode_query
* Improve succinctness of range and interval faceting struct: remove redundant words, e.g. "range.start", "range.end" -> "start", "end" etc.

## 0.5.0 (2018-09-11)

* Introduce struct modules for standard query and faceting parameters

## 0.4.2 (2018-09-06)

* Enable HTTP headers and options per endpoint configuration

## 0.4.1 (2018-09-04)

* Decode and return Solr JSON response as Map

## 0.4.0 (2018-09-03)

* Support HTTP headers and options specification
* Remove Hui.Search.search/1 (cf. search/2)
* q/1 shortcut for search(:default, query)

## 0.3.0 (2018-09-01)

* Multiple Solr endpoints configuration and searching
* Apache 2 license

## 0.2.0 (2018-08-31)

* First release.
* Solr search capability


