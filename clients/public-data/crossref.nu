# Auto-generated client for Crossref REST API v3.54.1
# Source: https://api.crossref.org/swagger-docs
# Auth: --token flag or $env.CROSSREF_REST_API_TOKEN

const BASE_URL = "https://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CROSSREF_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "members-works get" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Returns list of works associated with a Crossref member (deposited by a Crossref member) with {id}.  In addition to the `query` parameter, this endpoint supports the following <a href="#queries">field queries</a>:   + `query.affiliation` - query contributor affiliations  + `query.author` - query author given and family names  + `query.bibliographic` - query bibliographic information, useful for citation look up, includes titles, authors, ISSNs and publication years  + `query.chair` - query chair given and family names  + `query.container-title` - query container title aka. publication name  + `query.contributor` - query author, editor, chair and translator given and family names  + `query.degree` - query degree  + `query.description` - query description  + `query.editor` - query editor given and family names  + `query.event-acronym` - query acronym of the event  + `query.event-location` - query location of the event  + `query.event-name` - query name of the event  + `query.event-sponsor` - query sponsor of the event  + `query.event-theme` - query theme of the event  + `query.funder-name` - query name of the funder  + `query.publisher-location` - query location of the publisher  + `query.publisher-name` - query publisher name  + `query.standards-body-acronym` - query acronym of the standards body  + `query.standards-body-name` - query standards body name  + `query.title` - query title  + `query.translator` - query translator given and family names  `sort`: <a href="#sort">Sorting</a> by the following fields is supported: `created` `deposited` `indexed` `is-referenced-by-count` `issued` `published` `published-online` `published-print` `references-count` `relevance` `score` `updated`   `facet`: This endpoint supports the following <a href="#facets">facets</a>:   + `affiliation` - author affiliation  + `archive` - archive location  + `assertion` - custom Crossmark assertion name  + `assertion-group` - custom Crossmark assertion group name  + `category-name` - category name of work  + `container-title` - [max value 100], work container title, such as journal title, or book title  + `funder-doi` - funder DOI  + `funder-name` - funder name as deposited it appears in a metadata record  + `issn` - [max value 100], journal ISSN (any - print, electronic, link)  + `journal-issue` - journal issue number  + `journal-volume` - journal volume  + `license` - license URI of work  + `link-application` - intended application of the full text link  + `orcid` - [max value 100], contributor ORCID  + `published` - earliest year of publication  + `publisher-name` - publisher name of work  + `relation-type` - relation type described by work or described by another work with work as object  + `ror-id` - institution ROR ID  + `source` - source of the DOI  + `type-name` - work type name, such as journal-article or book-chapter  + `update-type` - significant update type  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters.   `select`: You can <a href="#select">select</a> any of the following fields: `DOI` `ISBN` `ISSN` `URL` `abstract` `accepted` `alternative-id` `approved` `archive` `article-number` `assertion` `author` `chair` `clinical-trial-number` `container-title` `content-created` `content-domain` `contributor` `created` `degree` `deposited` `editor` `event` `funder` `group-title` `indexed` `is-referenced-by-count` `issn-type` `issue` `issued` `license` `link` `member` `original-title` `page` `posted` `prefix` `published` `published-online` `published-print` `publisher` `publisher-location` `reference` `references-count` `relation` `resource` `score` `short-container-title` `short-title` `standards-body` `subject` `subtitle` `title` `translator` `type` `update-policy` `update-to` `updated-by` `volume` 
#
# GET /members/{id}/works
export def "members-works get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --order: string # Specify the order of sorted results, e.g. asc or desc (default).
  --facet: string # Retrieve counts for pre-defined facets e.g. `type-name:*` returns counts of all works by type. See <a href='#facets'>Facets</a>.
  --sample: int # Retrieve `N` randomly sampled items (format: int64)
  --qp-sort: string # Sort results by a certain field. See <a href='#sort'>Sorting</a>.
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --select: string # Select certain fields, supports a comma separated list of fields. See <a href='#select'>Select response fields</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, next_cursor: string, facets: any, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/members/($id)/works" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of journals in the Crossref database.
#
# GET /journals
export def "journals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --rows: int # The number of rows per page of results (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/journals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata for a Crossref member, as an example use id 324
#
# GET /members/{id}
export def "members get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<last_status_check_time: int, primary_name: string, counts: record<total_dois: int, current_dois: int, backfile_dois: int>, breakdowns: record<dois_by_issued_year: list>, prefixes: list<string>, coverage: record<affiliations_current: float, similarity_checking_current: float, descriptions_current: float, ror_ids_current: float, references_backfie: float, funders_backfile: float, licenses_backfile: float, funders_current: float, affiliations_backfile: float, resource_links_backfile: float, orcids_backfile: float, update_policies_current: float, ror_ids_backfile: float, orcids_current: float, similarity_checking_backfile: float, descriptions_backfile: float, award_numbers_backfile: float, update_policies_backfile: float, licenses_current: float, award_numbers_current: float, abstracts_backfile: float, resource_links_current: float, abstracts_current: float, references_current: float>, prefix: list<record>, id: int, tokens: list<string>, counts_type: record<all: record, current: record, backfile: record>, coverage_type: record<all: record, current: record, backfile: record>, flags: record<deposits_abstracts_current: bool, deposits_orcids_current: bool, deposits: bool, deposits_affiliations_backfile: bool, deposits_update_policies_backfile: bool, deposits_award_numbers_current: bool, deposits_resource_links_current: bool, deposits_ror_ids_current: bool, deposits_articles: bool, deposits_affiliations_current: bool, deposits_funders_current: bool, deposits_references_backfile: bool, deposits_ror_ids_backfile: bool, deposits_abstracts_backfile: bool, deposits_licenses_backfile: bool, deposits_award_numbers_backfile: bool, deposits_descriptions_current: bool, deposits_references_current: bool, deposits_resource_links_backfile: bool, deposits_descriptions_backfile: bool, deposits_orcids_backfile: bool, deposits_funders_backfile: bool, deposits_update_policies_current: bool, deposits_licenses_current: bool>, location: string, names: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of works associated with specified {prefix}.  In addition to the `query` parameter, this endpoint supports the following <a href="#queries">field queries</a>:   + `query.affiliation` - query contributor affiliations  + `query.author` - query author given and family names  + `query.bibliographic` - query bibliographic information, useful for citation look up, includes titles, authors, ISSNs and publication years  + `query.chair` - query chair given and family names  + `query.container-title` - query container title aka. publication name  + `query.contributor` - query author, editor, chair and translator given and family names  + `query.degree` - query degree  + `query.description` - query description  + `query.editor` - query editor given and family names  + `query.event-acronym` - query acronym of the event  + `query.event-location` - query location of the event  + `query.event-name` - query name of the event  + `query.event-sponsor` - query sponsor of the event  + `query.event-theme` - query theme of the event  + `query.funder-name` - query name of the funder  + `query.publisher-location` - query location of the publisher  + `query.publisher-name` - query publisher name  + `query.standards-body-acronym` - query acronym of the standards body  + `query.standards-body-name` - query standards body name  + `query.title` - query title  + `query.translator` - query translator given and family names  `sort`: <a href="#sort">Sorting</a> by the following fields is supported: `created` `deposited` `indexed` `is-referenced-by-count` `issued` `published` `published-online` `published-print` `references-count` `relevance` `score` `updated`   `facet`: This endpoint supports the following <a href="#facets">facets</a>:   + `affiliation` - author affiliation  + `archive` - archive location  + `assertion` - custom Crossmark assertion name  + `assertion-group` - custom Crossmark assertion group name  + `category-name` - category name of work  + `container-title` - [max value 100], work container title, such as journal title, or book title  + `funder-doi` - funder DOI  + `funder-name` - funder name as deposited it appears in a metadata record  + `issn` - [max value 100], journal ISSN (any - print, electronic, link)  + `journal-issue` - journal issue number  + `journal-volume` - journal volume  + `license` - license URI of work  + `link-application` - intended application of the full text link  + `orcid` - [max value 100], contributor ORCID  + `published` - earliest year of publication  + `publisher-name` - publisher name of work  + `relation-type` - relation type described by work or described by another work with work as object  + `ror-id` - institution ROR ID  + `source` - source of the DOI  + `type-name` - work type name, such as journal-article or book-chapter  + `update-type` - significant update type  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters.   `select`: You can <a href="#select">select</a> any of the following fields: `DOI` `ISBN` `ISSN` `URL` `abstract` `accepted` `alternative-id` `approved` `archive` `article-number` `assertion` `author` `chair` `clinical-trial-number` `container-title` `content-created` `content-domain` `contributor` `created` `degree` `deposited` `editor` `event` `funder` `group-title` `indexed` `is-referenced-by-count` `issn-type` `issue` `issued` `license` `link` `member` `original-title` `page` `posted` `prefix` `published` `published-online` `published-print` `publisher` `publisher-location` `reference` `references-count` `relation` `resource` `score` `short-container-title` `short-title` `standards-body` `subject` `subtitle` `title` `translator` `type` `update-policy` `update-to` `updated-by` `volume` 
#
# GET /prefixes/{prefix}/works
export def "prefixes-works get" [
  prefix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --order: string # Specify the order of sorted results, e.g. asc or desc (default).
  --facet: string # Retrieve counts for pre-defined facets e.g. `type-name:*` returns counts of all works by type. See <a href='#facets'>Facets</a>.
  --sample: int # Retrieve `N` randomly sampled items (format: int64)
  --qp-sort: string # Sort results by a certain field. See <a href='#sort'>Sorting</a>.
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --select: string # Select certain fields, supports a comma separated list of fields. See <a href='#select'>Select response fields</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, next_cursor: string, facets: any, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/prefixes/($prefix)/works" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of works associated with the specified {id}.  In addition to the `query` parameter, this endpoint supports the following <a href="#queries">field queries</a>:   + `query.affiliation` - query contributor affiliations  + `query.author` - query author given and family names  + `query.bibliographic` - query bibliographic information, useful for citation look up, includes titles, authors, ISSNs and publication years  + `query.chair` - query chair given and family names  + `query.container-title` - query container title aka. publication name  + `query.contributor` - query author, editor, chair and translator given and family names  + `query.degree` - query degree  + `query.description` - query description  + `query.editor` - query editor given and family names  + `query.event-acronym` - query acronym of the event  + `query.event-location` - query location of the event  + `query.event-name` - query name of the event  + `query.event-sponsor` - query sponsor of the event  + `query.event-theme` - query theme of the event  + `query.funder-name` - query name of the funder  + `query.publisher-location` - query location of the publisher  + `query.publisher-name` - query publisher name  + `query.standards-body-acronym` - query acronym of the standards body  + `query.standards-body-name` - query standards body name  + `query.title` - query title  + `query.translator` - query translator given and family names  `sort`: <a href="#sort">Sorting</a> by the following fields is supported: `created` `deposited` `indexed` `is-referenced-by-count` `issued` `published` `published-online` `published-print` `references-count` `relevance` `score` `updated`   `facet`: This endpoint supports the following <a href="#facets">facets</a>:   + `affiliation` - author affiliation  + `archive` - archive location  + `assertion` - custom Crossmark assertion name  + `assertion-group` - custom Crossmark assertion group name  + `category-name` - category name of work  + `container-title` - [max value 100], work container title, such as journal title, or book title  + `funder-doi` - funder DOI  + `funder-name` - funder name as deposited it appears in a metadata record  + `issn` - [max value 100], journal ISSN (any - print, electronic, link)  + `journal-issue` - journal issue number  + `journal-volume` - journal volume  + `license` - license URI of work  + `link-application` - intended application of the full text link  + `orcid` - [max value 100], contributor ORCID  + `published` - earliest year of publication  + `publisher-name` - publisher name of work  + `relation-type` - relation type described by work or described by another work with work as object  + `ror-id` - institution ROR ID  + `source` - source of the DOI  + `type-name` - work type name, such as journal-article or book-chapter  + `update-type` - significant update type  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters.   `select`: You can <a href="#select">select</a> any of the following fields: `DOI` `ISBN` `ISSN` `URL` `abstract` `accepted` `alternative-id` `approved` `archive` `article-number` `assertion` `author` `chair` `clinical-trial-number` `container-title` `content-created` `content-domain` `contributor` `created` `degree` `deposited` `editor` `event` `funder` `group-title` `indexed` `is-referenced-by-count` `issn-type` `issue` `issued` `license` `link` `member` `original-title` `page` `posted` `prefix` `published` `published-online` `published-print` `publisher` `publisher-location` `reference` `references-count` `relation` `resource` `score` `short-container-title` `short-title` `standards-body` `subject` `subtitle` `title` `translator` `type` `update-policy` `update-to` `updated-by` `volume` 
#
# GET /funders/{id}/works
export def "funders-works get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --order: string # Specify the order of sorted results, e.g. asc or desc (default).
  --facet: string # Retrieve counts for pre-defined facets e.g. `type-name:*` returns counts of all works by type. See <a href='#facets'>Facets</a>.
  --sample: int # Retrieve `N` randomly sampled items (format: int64)
  --qp-sort: string # Sort results by a certain field. See <a href='#sort'>Sorting</a>.
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --select: string # Select certain fields, supports a comma separated list of fields. See <a href='#select'>Select response fields</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, next_cursor: string, facets: any, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/funders/($id)/works" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a journal with the given ISSN, as an example use ISSN 03064530
#
# GET /journals/{issn}
export def "journals get" [
  issn: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<last_status_check_time: int, counts: record<total_dois: int, current_dois: int, backfile_dois: int>, breakdowns: record<dois_by_issued_year: list>, publisher: string, coverage: record<affiliations_current: float, similarity_checking_current: float, descriptions_current: float, ror_ids_current: float, references_backfie: float, funders_backfile: float, licenses_backfile: float, funders_current: float, affiliations_backfile: float, resource_links_backfile: float, orcids_backfile: float, update_policies_current: float, ror_ids_backfile: float, orcids_current: float, similarity_checking_backfile: float, descriptions_backfile: float, award_numbers_backfile: float, update_policies_backfile: float, licenses_current: float, award_numbers_current: float, abstracts_backfile: float, resource_links_current: float, abstracts_current: float, references_current: float>, title: string, subjects: list<string>, coverage_type: record<all: record, current: record, backfile: record>, flags: record<deposits_abstracts_current: bool, deposits_orcids_current: bool, deposits: bool, deposits_affiliations_backfile: bool, deposits_update_policies_backfile: bool, deposits_award_numbers_current: bool, deposits_resource_links_current: bool, deposits_ror_ids_current: bool, deposits_articles: bool, deposits_affiliations_current: bool, deposits_funders_current: bool, deposits_references_backfile: bool, deposits_ror_ids_backfile: bool, deposits_abstracts_backfile: bool, deposits_licenses_backfile: bool, deposits_award_numbers_backfile: bool, deposits_descriptions_current: bool, deposits_references_current: bool, deposits_resource_links_backfile: bool, deposits_descriptions_backfile: bool, deposits_orcids_backfile: bool, deposits_funders_backfile: bool, deposits_update_policies_current: bool, deposits_licenses_current: bool>, ISSN: list<string>, issn_type: record<value: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/journals/($issn)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a metadata work type.
#
# GET /types/{id}
export def "types get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<id: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of licenses.
#
# GET /licenses
export def "licenses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>
  --rows: int # The number of rows per page of results (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<total_results: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/licenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of valid work types.
#
# GET /types
export def "types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata for the specified Crossref DOI, as an example use DOI 10.5555/12345678
#
# GET /works/{doi}
export def "works get" [
  doi: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<institution: list<record>, indexed: record<date_parts: list, version: string>, description: string, posted: record<date_parts: list>, publisher_location: string, update_to: list<record>, standards_body: record<name: string, acronym: string>, edition_number: string, group_title: string, reference_count: int, publisher: string, issue: string, isbn_type: list<record>, license: list<record>, funder: list<record>, content_domain: record<domain: list, crossmark_restriction: bool>, chair: list<record>, short_container_title: list<string>, accepted: record<date_parts: list>, special_numbering: string, content_updated: record<date_parts: list>, published_print: record<date_parts: list>, abstract: string, DOI: string, type: string, created: record<date_parts: list, date_time: string, timestamp: int>, approved: record<date_parts: list>, page: string, update_policy: string, source: string, is_referenced_by_count: int, title: list<string>, prefix: string, volume: string, clinical_trial_number: list<record>, author: list<record>, member: string, content_created: record<date_parts: list>, published_online: record<date_parts: list>, reference: list<record>, updated_by: list<record>, event: record<name: string, location: string, start: record, end: record>, container_title: list<string>, review: record<type: string, running_number: string, revision_round: string, stage: string, competing_interest_statement: string, recommendation: string, language: string>, project: list<record>, original_title: list<string>, status: record<type: string, update: record, status_description: list>, language: string, link: list<record>, deposited: record<date_parts: list, date_time: string, timestamp: int>, score: float, degree: list<string>, resource: record<primary: record, secondary: list>, subtitle: list<string>, translator: list<record>, free_to_read: record<start_date: record, end_date: record>, editor: list<record>, proceedings_subject: string, component_number: string, short_title: list<string>, issued: record<date_parts: list>, ISBN: list<string>, references_count: int, part_number: string, aliases: list<string>, issue_title: list<string>, journal_issue: record<issue: string, published_online: record, published_print: record>, alternative_id: list<string>, version: record<version: string, language: string, version_description: list>, URL: string, archive: list<string>, relation: record, ISSN: list<string>, issn_type: list<record>, subject: list<string>, published_other: record<date_parts: list>, published: record<date_parts: list>, assertion: list<record>, subtype: string, article_number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/works/($doi)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of works of type {id}.  In addition to the `query` parameter, this endpoint supports the following <a href="#queries">field queries</a>:   + `query.affiliation` - query contributor affiliations  + `query.author` - query author given and family names  + `query.bibliographic` - query bibliographic information, useful for citation look up, includes titles, authors, ISSNs and publication years  + `query.chair` - query chair given and family names  + `query.container-title` - query container title aka. publication name  + `query.contributor` - query author, editor, chair and translator given and family names  + `query.degree` - query degree  + `query.description` - query description  + `query.editor` - query editor given and family names  + `query.event-acronym` - query acronym of the event  + `query.event-location` - query location of the event  + `query.event-name` - query name of the event  + `query.event-sponsor` - query sponsor of the event  + `query.event-theme` - query theme of the event  + `query.funder-name` - query name of the funder  + `query.publisher-location` - query location of the publisher  + `query.publisher-name` - query publisher name  + `query.standards-body-acronym` - query acronym of the standards body  + `query.standards-body-name` - query standards body name  + `query.title` - query title  + `query.translator` - query translator given and family names  `sort`: <a href="#sort">Sorting</a> by the following fields is supported: `created` `deposited` `indexed` `is-referenced-by-count` `issued` `published` `published-online` `published-print` `references-count` `relevance` `score` `updated`   `facet`: This endpoint supports the following <a href="#facets">facets</a>:   + `affiliation` - author affiliation  + `archive` - archive location  + `assertion` - custom Crossmark assertion name  + `assertion-group` - custom Crossmark assertion group name  + `category-name` - category name of work  + `container-title` - [max value 100], work container title, such as journal title, or book title  + `funder-doi` - funder DOI  + `funder-name` - funder name as deposited it appears in a metadata record  + `issn` - [max value 100], journal ISSN (any - print, electronic, link)  + `journal-issue` - journal issue number  + `journal-volume` - journal volume  + `license` - license URI of work  + `link-application` - intended application of the full text link  + `orcid` - [max value 100], contributor ORCID  + `published` - earliest year of publication  + `publisher-name` - publisher name of work  + `relation-type` - relation type described by work or described by another work with work as object  + `ror-id` - institution ROR ID  + `source` - source of the DOI  + `type-name` - work type name, such as journal-article or book-chapter  + `update-type` - significant update type  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters.   `select`: You can <a href="#select">select</a> any of the following fields: `DOI` `ISBN` `ISSN` `URL` `abstract` `accepted` `alternative-id` `approved` `archive` `article-number` `assertion` `author` `chair` `clinical-trial-number` `container-title` `content-created` `content-domain` `contributor` `created` `degree` `deposited` `editor` `event` `funder` `group-title` `indexed` `is-referenced-by-count` `issn-type` `issue` `issued` `license` `link` `member` `original-title` `page` `posted` `prefix` `published` `published-online` `published-print` `publisher` `publisher-location` `reference` `references-count` `relation` `resource` `score` `short-container-title` `short-title` `standards-body` `subject` `subtitle` `title` `translator` `type` `update-policy` `update-to` `updated-by` `volume` 
#
# GET /types/{id}/works
export def "types-works get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --order: string # Specify the order of sorted results, e.g. asc or desc (default).
  --facet: string # Retrieve counts for pre-defined facets e.g. `type-name:*` returns counts of all works by type. See <a href='#facets'>Facets</a>.
  --sample: int # Retrieve `N` randomly sampled items (format: int64)
  --qp-sort: string # Sort results by a certain field. See <a href='#sort'>Sorting</a>.
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --select: string # Select certain fields, supports a comma separated list of fields. See <a href='#select'>Select response fields</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, next_cursor: string, facets: any, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/types/($id)/works" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of all works (journal articles, conference proceedings, books, components, etc), 20 per page by default.  In addition to the `query` parameter, this endpoint supports the following <a href="#queries">field queries</a>:   + `query.affiliation` - query contributor affiliations  + `query.author` - query author given and family names  + `query.bibliographic` - query bibliographic information, useful for citation look up, includes titles, authors, ISSNs and publication years  + `query.chair` - query chair given and family names  + `query.container-title` - query container title aka. publication name  + `query.contributor` - query author, editor, chair and translator given and family names  + `query.degree` - query degree  + `query.description` - query description  + `query.editor` - query editor given and family names  + `query.event-acronym` - query acronym of the event  + `query.event-location` - query location of the event  + `query.event-name` - query name of the event  + `query.event-sponsor` - query sponsor of the event  + `query.event-theme` - query theme of the event  + `query.funder-name` - query name of the funder  + `query.publisher-location` - query location of the publisher  + `query.publisher-name` - query publisher name  + `query.standards-body-acronym` - query acronym of the standards body  + `query.standards-body-name` - query standards body name  + `query.title` - query title  + `query.translator` - query translator given and family names  `sort`: <a href="#sort">Sorting</a> by the following fields is supported: `created` `deposited` `indexed` `is-referenced-by-count` `issued` `published` `published-online` `published-print` `references-count` `relevance` `score` `updated`   `facet`: This endpoint supports the following <a href="#facets">facets</a>:   + `affiliation` - author affiliation  + `archive` - archive location  + `assertion` - custom Crossmark assertion name  + `assertion-group` - custom Crossmark assertion group name  + `category-name` - category name of work  + `container-title` - [max value 100], work container title, such as journal title, or book title  + `funder-doi` - funder DOI  + `funder-name` - funder name as deposited it appears in a metadata record  + `issn` - [max value 100], journal ISSN (any - print, electronic, link)  + `journal-issue` - journal issue number  + `journal-volume` - journal volume  + `license` - license URI of work  + `link-application` - intended application of the full text link  + `orcid` - [max value 100], contributor ORCID  + `published` - earliest year of publication  + `publisher-name` - publisher name of work  + `relation-type` - relation type described by work or described by another work with work as object  + `ror-id` - institution ROR ID  + `source` - source of the DOI  + `type-name` - work type name, such as journal-article or book-chapter  + `update-type` - significant update type  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters.   `select`: You can <a href="#select">select</a> any of the following fields: `DOI` `ISBN` `ISSN` `URL` `abstract` `accepted` `alternative-id` `approved` `archive` `article-number` `assertion` `author` `chair` `clinical-trial-number` `container-title` `content-created` `content-domain` `contributor` `created` `degree` `deposited` `editor` `event` `funder` `group-title` `indexed` `is-referenced-by-count` `issn-type` `issue` `issued` `license` `link` `member` `original-title` `page` `posted` `prefix` `published` `published-online` `published-print` `publisher` `publisher-location` `reference` `references-count` `relation` `resource` `score` `short-container-title` `short-title` `standards-body` `subject` `subtitle` `title` `translator` `type` `update-policy` `update-to` `updated-by` `volume` 
#
# GET /works
export def "works list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --order: string # Specify the order of sorted results, e.g. asc or desc (default).
  --facet: string # Retrieve counts for pre-defined facets e.g. `type-name:*` returns counts of all works by type. See <a href='#facets'>Facets</a>.
  --sample: int # Retrieve `N` randomly sampled items (format: int64)
  --qp-sort: string # Sort results by a certain field. See <a href='#sort'>Sorting</a>.
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --select: string # Select certain fields, supports a comma separated list of fields. See <a href='#select'>Select response fields</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, next_cursor: string, facets: any, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/works" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the agency associated with a specific work by its DOI, as an example use DOI 10.5555/12345678
#
# GET /works/{doi}/agency
export def "works-agency get" [
  doi: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<DOI: string, agency: record<id: string, label: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/works/($doi)/agency")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of organisations that have registered content with Crossref.  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters. This endpoint supports the following filters:   + `backfile-doi-count` - members with given count of DOIs for material published more than two years ago  + `current-doi-count` - members with given count of DOIs for material published within last two years  + `prefix` - members with given prefix
#
# GET /members
export def "members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --rows: int # The number of rows per page of results (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of works in the journal identified by {issn}.  In addition to the `query` parameter, this endpoint supports the following <a href="#queries">field queries</a>:   + `query.affiliation` - query contributor affiliations  + `query.author` - query author given and family names  + `query.bibliographic` - query bibliographic information, useful for citation look up, includes titles, authors, ISSNs and publication years  + `query.chair` - query chair given and family names  + `query.container-title` - query container title aka. publication name  + `query.contributor` - query author, editor, chair and translator given and family names  + `query.degree` - query degree  + `query.description` - query description  + `query.editor` - query editor given and family names  + `query.event-acronym` - query acronym of the event  + `query.event-location` - query location of the event  + `query.event-name` - query name of the event  + `query.event-sponsor` - query sponsor of the event  + `query.event-theme` - query theme of the event  + `query.funder-name` - query name of the funder  + `query.publisher-location` - query location of the publisher  + `query.publisher-name` - query publisher name  + `query.standards-body-acronym` - query acronym of the standards body  + `query.standards-body-name` - query standards body name  + `query.title` - query title  + `query.translator` - query translator given and family names  `sort`: <a href="#sort">Sorting</a> by the following fields is supported: `created` `deposited` `indexed` `is-referenced-by-count` `issued` `published` `published-online` `published-print` `references-count` `relevance` `score` `updated`   `facet`: This endpoint supports the following <a href="#facets">facets</a>:   + `affiliation` - author affiliation  + `archive` - archive location  + `assertion` - custom Crossmark assertion name  + `assertion-group` - custom Crossmark assertion group name  + `category-name` - category name of work  + `container-title` - [max value 100], work container title, such as journal title, or book title  + `funder-doi` - funder DOI  + `funder-name` - funder name as deposited it appears in a metadata record  + `issn` - [max value 100], journal ISSN (any - print, electronic, link)  + `journal-issue` - journal issue number  + `journal-volume` - journal volume  + `license` - license URI of work  + `link-application` - intended application of the full text link  + `orcid` - [max value 100], contributor ORCID  + `published` - earliest year of publication  + `publisher-name` - publisher name of work  + `relation-type` - relation type described by work or described by another work with work as object  + `ror-id` - institution ROR ID  + `source` - source of the DOI  + `type-name` - work type name, such as journal-article or book-chapter  + `update-type` - significant update type  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters.   `select`: You can <a href="#select">select</a> any of the following fields: `DOI` `ISBN` `ISSN` `URL` `abstract` `accepted` `alternative-id` `approved` `archive` `article-number` `assertion` `author` `chair` `clinical-trial-number` `container-title` `content-created` `content-domain` `contributor` `created` `degree` `deposited` `editor` `event` `funder` `group-title` `indexed` `is-referenced-by-count` `issn-type` `issue` `issued` `license` `link` `member` `original-title` `page` `posted` `prefix` `published` `published-online` `published-print` `publisher` `publisher-location` `reference` `references-count` `relation` `resource` `score` `short-container-title` `short-title` `standards-body` `subject` `subtitle` `title` `translator` `type` `update-policy` `update-to` `updated-by` `volume` 
#
# GET /journals/{issn}/works
export def "journals-works get" [
  issn: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # The number of rows per page of results (format: int64)
  --order: string # Specify the order of sorted results, e.g. asc or desc (default).
  --facet: string # Retrieve counts for pre-defined facets e.g. `type-name:*` returns counts of all works by type. See <a href='#facets'>Facets</a>.
  --sample: int # Retrieve `N` randomly sampled items (format: int64)
  --qp-sort: string # Sort results by a certain field. See <a href='#sort'>Sorting</a>.
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --select: string # Select certain fields, supports a comma separated list of fields. See <a href='#select'>Select response fields</a>
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --filter: string # Filter by certain fields. See <a href='#filters'>filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, next_cursor: string, facets: any, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rows" $rows "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/journals/($issn)/works" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata for specified funder **and** its suborganizations, as an example use id 501100006004
#
# GET /funders/{id}
export def "funders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<hierarchy_names: record, replaced_by: list<string>, work_count: int, name: string, descendants: list<string>, descendant_work_count: int, id: string, tokens: list<string>, replaces: list<string>, uri: string, hierarchy: record<more: bool>, alt_names: list<string>, location: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/funders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of all funders in the [Funder Registry](https://gitlab.com/crossref/open_funder_registry).  `filter`: See [our documentation website](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-filters/) for a full list of available filters. This endpoint supports the following filters:   + `location` - funders located in given country
#
# GET /funders
export def "funders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Search funders by location using a Lucene based syntax. See <a href='#filters'>Filters</a>
  --cursor: string # Page through large result sets. See <a href='#cursors'>Retrieving large results sets</a>.
  --qp-query: string # Query certain fields. See <a href='#queries'>Queries</a>.
  --rows: int # The number of rows per page of results (format: int64)
  --mailto: string # The email address to identify yourself and access the 'polite pool'
  --offset: int # The number of rows to skip before returning. See <a href='#cursors'>Retrieving large results sets</a>. (format: int64)
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<items_per_page: int, query: record<start_index: int, search_terms: any>, total_results: int, items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "mailto" $mailto "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/funders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata for the DOI owner prefix, as an example use prefix 10.1016
#
# GET /prefixes/{prefix}
export def "prefixes get" [
  prefix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, message_type: string, message_version: string, message: record<member: string, name: string, prefix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prefixes/($prefix)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
