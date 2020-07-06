# Changelog

## 0.10.0 (2020-07-06)
* New HTTP client architecture: introduce a behaviour with a HTTPoison implementation
* Begin HTTPoison dependency decoupling
* Removal of all bang (!) functions towards a simpler core library

## 0.9.3 (2020-05-08)
* Remove various deprecated functions and data structs
* `new` instantiation function for data structs

## 0.9.2 (2019-11-29)

* New JSON Encoder protocol implementation for `Hui.Query.Update` struct
* Refactor encoding utiliy functions: prep for forthcoming support of JSON request/facet APIs

## 0.9.1 (2019-11-19)

* New `Hui.Query.Update` struct for indexing documents
* `Hui.Encoder` encodes update query in JSON format
* `Hui.Query.get/2` and `Hui.Query.post/2` functions (accept built-in data structs) for HTTP requests

## 0.9.0 (2019-11-06)

* New query structs: `Hui.Query.Standard`, `Hui.Query.DisMax`, `Hui.Query.Common`, Faceting: `Hui.Query.Facet`, `Hui.Query.FacetRange`, `Hui.Query.FacetInterval`, `Hui.Query.Highlight`, `Hui.Query.HighlighterFastVector`, `Hui.Query.HighlighterOriginal`, `Hui.Query.HighlighterUnified`, `Hui.Query.SpellCheck`, `Hui.Query.Suggest` `Hui.Query.MoreLikeThis`
* `Hui.Encoder` protocol and implementation for encoding the new query structs

## 0.8.3, 0.8.4 (2019-10-03)

* update dependencies: newer versions of bypass, httpoison, cowboy

## 0.8.2 (2018-10-09)

* `update/3`, `update!/3` functions for adding and updating Solr docs
* `delete/3`, `delete!/3`, `delete_by_query/3`, `delete_by_query!/3` functions for deleting Solr docs
* `commit/2`, `commit!/2` functions for committing Solr docs to index

## 0.8.1 (2018-10-08)

* Documentation, README and doctests for Solr updating via `Hui.U` struct

## 0.8.0 (2018-10-06)

* Solr updating via struct: `Request.update/3` now accepts a `Hui.U` struct for adding, deleting and committing documents, as well as optimising indexes

## 0.7.0 (2018-10-03)

* Enable Solr updating with binary data (JSON, XML update docs) via `Request.update/3` function

## 0.6.3 (2018-09-28)

* Convenience functions for search and suggester requests (`q/6`, `search/7`, `suggest/5`)
* Bangified all main module functions (`q!/1`, `search!/2`, `spellcheck!/2`, `spellcheck!/3`, `suggest!/2`, `mlt!/3`)
* Deprecate the standard query + faceting functions (`q/2`, `search/3`) as these are now provided through the more general-purpose functions (`q/1`, `search/2`)

## 0.6.2 (2018-09-26)

* Introduce a "bang" feature via an additional boolean parameter in `Request.search/3` for implementing bangified functions later
* Deprecate `Hui.Search` module which is replaced by `Hui.Request` to provide update functions later
* Refactor search tests with a helper function that tests `search/2` in both `Hui` and `Hui.Request` modules
* Refactor and fix typespec issues with Dialyzir
* Code coverage metric via ExCoveralls and coveralls.io

## 0.6.1 (2018-09-24)

* Provide `cursorMark` parameter for deep paging in `Hui.Q`
* Define and use a custom exception `Hui.Error`, instead of the mixed usage of HTTPoison and arbitrary error text responses

## 0.6.0 (2018-09-21)

* Support SolrCloud request parameters such as 'collection', 'shards', 'shards.tolerant' in `Hui.Q` and distributed search

## 0.5.7 (2018-09-21)

* Support autosuggest (suggester) query via `suggest/2`
* Support spell checking query via `spellcheck/3`
* Support MoreLikeThis query via `mlt/3`
* Suggester query via `Hui.S` struct
* Spell checking query via `Hui.Sp` struct
* MoreLikeThis query via `Hui.M` struct

## 0.5.6 (2018-09-20)

* Results highlighting (snippets) query via `Hui.H` struct
* Unified, Original, Fast Vector results highlighting (snippets) via `Hui.H1/H2/H3` structs

## 0.5.5 (2018-09-20)

* `q/1`, `search/2` to generally accept a list of current and forthcoming Hui structs for more complex querying, e.g. DisMax
* DisMax (Maximum Disjunction) and Extended DisMax (eDisMax) query now via a new `Hui.D` struct
* Deprecate DisMax parameters from `Hui.Q` struct

## 0.5.4 (2018-09-16)

* Maximum Disjunction (DisMax) query via `Hui.Q` struct

## 0.5.3 (2018-09-14)

* Support JSON and XML response writer parameters in `Hui.Q` struct

## 0.5.2 (2018-09-13)

* New `q/2`, `search/3` features for structured querying and faceting - Solr standard parser
* `search/2`, `q/1` accepts query struct (Hui.Q) parameters
* `Search.search/2` works with query and faceting structs (`Hui.Q`, `Hui.F`) parameters

## 0.5.1 (2018-09-12)

* URL encoder renders faceting structs to string according to Solr prefix syntax e.g. "field" -> `facet.field`
* URL encoder for "per field" faceting (ranges, intervals) use cases, e.g. "gap" -> `f.[field].range.gap`
* Consolidate `URL.encode_query/1`; deprecate `Q.encode_query`
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


