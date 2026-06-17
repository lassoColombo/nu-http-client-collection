# Auto-generated client for DigitalNZ API v3
# Source: https://api.apis.guru/v2/specs/digitalnz.org/3/openapi.json
# Auth: --token flag or $env.DIGITALNZ_API_TOKEN

const BASE_URL = "https://api.digitalnz.org"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DIGITALNZ_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["https://api.digitalnz.org"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def and-category-completer [] { ["Archives" "Articles" "Audio" "Books" "Data" "Groups" "Images" "Journals" "Manuscripts" "Music Score" "Newspapers" "Other" "Reference sources" "Research papers" "Sets" "Videos" "Websites"] }
def and-usage-completer [] { ["All rights reserved" "Modify" "Share" "Unknown" "Use commercially"] }
def and-has-large-thumbnail-url-completer [] { ["Y"] }
def and-has-lat-lng-completer [] { ["false" "true"] }
def sort-completer [] { ["date" "syndication_date"] }
def direction-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "records-format get" } } | get name | first)
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

# Run queries against DigitalNZ metadata search service.
#
# GET /records.{format}
export def "records-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # This field enables queries based on one or more search terms and provides the functionality of the main search box on [digitalnz.org](https://digitalnz.org). Search terms can be combined with boolean operators (AND, OR).   A minus sign excludes certain terms, eg. "-horse".   An asterisk (\*) acts as a wildcard, eg. "ted*".   Multiple search terms are combined with an AND by default.   Examples: `"moustache"`, `"Wanganui OR Whanganui"`,  `"-paperspast"`, `"ted*"`
  --and-category: string@and-category-completer # These are the same categories that are used across the tabs in [digitalnz.org](https://digitalnz.org/records?text=&tab=Videos)
  --and-content-partner: string # Allows filtering for records from a particular Content Partner.   Examples: `"Ministry for Culture and Heritage"` `"Trove"` `"V.C. Browne & Son"`    *Tip* - To see a list of Content Partners available for filtering use the *facets* parameter, eg. *"&facets=content_partner"*.  
  --and-primary-collection: string # Allows filtering for records from a particular *primary_collection*.   Examples: `"Puke Ariki"` `"NZHistory"` `"TAPUHI"`      *Tip* - To see a list of Primary_Collections available for filtering use the *facets* parameter, eg. *"&facets=primary_collection"*.   
  --and-collection: string # Allows filtering for records from a particular Collection. Collections can be thought of as sub-collections or groupings under Primary_Collections.   Examples: `"Music 101"` `"Mollusks"` `"Wairarapa Daily Times"`    *Tip* - To see a list of Collections available for filtering use the *facets* parameter, eg. *"&facets=collection"*. 
  --and-usage: string@and-usage-completer
  --and-subject: string # Examples: `"Cats"` `"Weddings"` `"climb*"`
  --and-dc-type: string # Examples: `"Conference item"` `"Magazines"`
  --and-format: string # Examples: `"Photolithographs"` `"Glass*"`
  --and-placename: string # This field can be used for text-based location search. For a more advanced coordinate-based search, see the "geo_bbox" field below.   Examples: `"Scott Base"` `"Wainuiomata"` `"castle*"`
  --and-creator: string # Examples: `"Revelle Jackson"` `"Nicholas Chevalier"` `"Rita Angus"`
  --and-title: string # Examples: `"Pukeko"` `"Club"` `"Break*"`"
  --and-date: string # This field can be useful for querying and sorting (see the 'sort' param further down). But it should be noted that, as with some other fields, **not all records have date metadata associated**. There is good coverage of date metadata within certain collections, but there are plenty with no date information at all. So, if you query for records from a specific date you may get some matching results, but might also be missing other potentially relevant records that don't have date metadata available.   Example: `"1970-12-25"`  *Tip* - There is a related (but not searchable) field that is returned on each record (where available), that often has a more human readable version of the date information, called 'display_date'.
  --and-year: string # This field allows searching specifically by year. The metadata is derived from the same date information that is searchable and returned in the date field. It is possible to search across a range using syntax the following syntax `[{start year} TO {end year}]`.   Example: `"1893"` `"[1982 TO 1987]"`
  --and-decade: string # This field allows searching specifically by decade. The metadata is derived from the same date information that is searchable and returned in the date field.   Example: `"1850"` `"1990"`
  --and-century: string # This field allows searching specifically by century. The metadata is derived from the same date information that is searchable and returned in the date field.   Example: `"1900"` `"2000"`
  --without-filter-field: string # All of the above `and[___][]` filters in this document are also able to be used with this syntax to exclude specific matches. For example to exclude Papers Past content `&without[primary_collection]=Papers+Past`
  --and-or-filter-field: string # All of the above `and[___][]` filters in this document are also able to be used with the `and[or][___][]` syntax to allow multi-select *OR* queries within one field.   Basic example:  - To filter your results to only those with a category or Audio or Videos:    `&and[or][category][]=Audio&and[or][category][]=Videos`     In order to combine *OR* filters across multiple fields the syntax needs to be nested as follows   Nested examples:   - To search for *(year is 2014 OR 2015) AND (primary_collection is TAPUHI OR Public Address)*    `&and[or][year][]=2015&and[or][year][]=2014&and[and][or][primary_collection][]=TAPUHI&and[and][or][primary_collection][]=Public+Address`    - To search for *(category is Images OR Video) AND (subject is cat OR cats)*    `&and[or][category][]=Images&and[or][category][]=Videos&and[and][or][subject][]=cat&and[and][or][subject][]=cats`  
  --and-is-commercial-use: oneof<nothing, bool> # Some DigitalNZ partners offer their metadata for use in commercial applications. This content can be identified through the *is_commercial_use* flag. Only API results where the *is_commercial_use* field set to True can be used for commercial purposes. Check out the [terms of use](https://digitalnz.org/about/terms-of-use/developer-api-terms-of-use#commercial_use_terms) for more information.
  --and-has-large-thumbnail-url: string@and-has-large-thumbnail-url-completer # Filters results to only those records that have an image available in the *large_thumbnail_url* field.   **Note:** There is an issue with this field where, in order to get results, it needs to be specified with "Y" or not specified at all.
  --and-has-lat-lng: oneof<nothing, bool> # Filters results to only those records that have latitude and longitude coordinates present in the metadata.    *Tip* - To see the location metadata you'll need to specifically request that field using the *fields* parameter - *"&fields=verbose,locations"*  as it is not part of the default, or verbose field sets.
  --geo-bbox: string # A geographic bounding box scoping a search to a geographic region. Order of latitude-longitude coordinates is north, west, south, east.   For example, filtering the Wellington region would be *"&geo_bbox=-41,174,-42,175"*
  --fields: string # Comma-separated whitelist of fields to be returned. The syntax *"&fields=verbose"* can be used to return the bulk of the fields, or you can customise which fields you are interested in, eg. *"&fields=id,title,subject,collection,landing_url,locations"*.
  --qp-sort: string@sort-completer # Used to control the order of the results in conjunction with the *direction* field.   - *syndication_date* - is the creation date of the record within DigitalNZ, ie. when DigitalNZ first harvested the record.   - *date* - is the date metadata (if present) associated with the record.        To sort the search results with newest records at the top use: "&sort=syndication_date&direction=desc"
  --direction: string@direction-completer # Used in conjunction with *sort* to order the results  - *asc* - Ascending, oldest first.  - *desc* - Descending, newest first.  (default: asc)
  --page: int # Specify which page of results to return. (default: 1)
  --per-page: int # The number of records to return per page of search results. (default: 20)
  --facets: list # Shows a breakdown of record counts for the specified facets based on the current result set. In the [DigitalNZ search interface](https://digitalnz.org/records) these facets are used to list the values filterable for each field. A comma-separated list will return multiple facets in one call.
  --facets-page: int # This value specifies which page of facet results to return. Allowing pagination through large lists of facet values.
  --facets-per-page: int # The number of facets to return per page of facet results. (default: 10)
  --exclude-filters-from-facets: oneof<nothing, bool> # This field can be used when filtering into some facets, to maintain the context of the wider facet values. A common use case is to allow the results of a search to be filtered down into a specific category (eg Audio), while still showing the other possible filter options as facet counts (eg. Images, Audio, Video, etc). Setting this to 'true' will not effect the search results returned but will ignore all search filters (eg. "and[category]=Audio") when calculating the facet counts.   (default: false)
  --authentication-token: string # The DigitalNZ API no longer requires a key to access public content. However, if you plan on using the API regularly, expect to be a high volume consumer or are planning on creating an application, we encourage you to use an API key so that we can: - provide targeted help and support - increase your query throughput (by negotiation) - notify you directly of changes to the API - gather usage metrics to help improve the service    API requests that do not pass a valid API key/token are treated as unauthenticated. A maximum rate limit applies across all unauthenticated requests. This rate limit is in place to protect the service from overuse, resulting in unsustainable costs, or potential attack.  **Getting an API key**   [Create a DigitalNZ account](https://digitalnz.org/sign_up), log in and select "[my API key](https://digitalnz.org/api_keys/edit)" from your username drop-down menu (on the right hand side)'. The key is a long string of jumbled letters and numbers (hash) that is unique to you. You are required to keep the key secret. (Refer to the [Developer API Terms of Use](https://digitalnz.org/about/terms-of-use/developer-api-terms-of-use) for more information).  **Using an API key**   When you make a call to the API you'll need to pass the key in a custom HTTP header: ‘Authentication-Token’. For example, a query using the ‘curl’ command might look like the following (where ‘{YOUR_API_KEY}’ is replaced with a valid API key):  `curl -H "Authentication-Token:{YOUR_API_KEY}" http://api.digitalnz.org/v3/records.json?text=kiwi`
]: nothing -> record<facets: record, page: int, per_page: int, records: table<category: list, collection: list, collection_title: list, content_partner: list, copyright: list, created_at: string, creator: list, date: list, dc_identifier: list, description: string, display_collection: string, display_content_partner: string, display_date: string, id: int, landing_url: string, large_thumbnail_url: string, locations: list, primary_collection: list, rights: string, rights_url: list, source_url: string, subject: list, thumbnail_url: string, title: string, updated_at: string, usage: list>, request_url: string, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "and[category][]" $and_category "scalar") (serialize-qp "and[content_partner][]" $and_content_partner "scalar") (serialize-qp "and[primary_collection][]" $and_primary_collection "scalar") (serialize-qp "and[collection][]" $and_collection "scalar") (serialize-qp "and[usage][]" $and_usage "scalar") (serialize-qp "and[subject][]" $and_subject "scalar") (serialize-qp "and[dc_type][]" $and_dc_type "scalar") (serialize-qp "and[format][]" $and_format "scalar") (serialize-qp "and[placename][]" $and_placename "scalar") (serialize-qp "and[creator][]" $and_creator "scalar") (serialize-qp "and[title][]" $and_title "scalar") (serialize-qp "and[date]" $and_date "scalar") (serialize-qp "and[year]" $and_year "scalar") (serialize-qp "and[decade]" $and_decade "scalar") (serialize-qp "and[century]" $and_century "scalar") (serialize-qp "without[{filter_field}]" $without_filter_field "scalar") (serialize-qp "and[or][{filter_field}][]" $and_or_filter_field "scalar") (serialize-qp "and[is_commercial_use]" $and_is_commercial_use "scalar") (serialize-qp "and[has_large_thumbnail_url]" $and_has_large_thumbnail_url "scalar") (serialize-qp "and[has_lat_lng]" $and_has_lat_lng "scalar") (serialize-qp "geo_bbox" $geo_bbox "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "facets" $facets "csv") (serialize-qp "facets_page" $facets_page "scalar") (serialize-qp "facets_per_page" $facets_per_page "scalar") (serialize-qp "exclude_filters_from_facets" $exclude_filters_from_facets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: $format} | format pattern "/records.{format}") $qp)
  let extra_headers = {"Authentication-Token": $authentication_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View metadata associated with a single record.
#
# GET /records/{record_id}.{format}
export def "records get" [
  record_id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated whitelist of fields to be returned. The syntax *"&fields=verbose"* can be used to return the bulk of the fields, or you can customise which fields you are interested in, eg. *"&fields=id,title,subject,collection,landing_url,locations"*.
  --authentication-token: string # The DigitalNZ API no longer requires a key to access public content. However, if you plan on using the API regularly, expect to be a high volume consumer or are planning on creating an application, we encourage you to use an API key so that we can: - provide targeted help and support - increase your query throughput (by negotiation) - notify you directly of changes to the API - gather usage metrics to help improve the service    API requests that do not pass a valid API key/token are treated as unauthenticated. A maximum rate limit applies across all unauthenticated requests. This rate limit is in place to protect the service from overuse, resulting in unsustainable costs, or potential attack.  **Getting an API key**   [Create a DigitalNZ account](https://digitalnz.org/sign_up), log in and select "[my API key](https://digitalnz.org/api_keys/edit)" from your username drop-down menu (on the right hand side)'. The key is a long string of jumbled letters and numbers (hash) that is unique to you. You are required to keep the key secret. (Refer to the [Developer API Terms of Use](https://digitalnz.org/about/terms-of-use/developer-api-terms-of-use) for more information).  **Using an API key**   When you make a call to the API you'll need to pass the key in a custom HTTP header: ‘Authentication-Token’. For example, a query using the ‘curl’ command might look like the following (where ‘{YOUR_API_KEY}’ is replaced with a valid API key):  `curl -H "Authentication-Token:{YOUR_API_KEY}" http://api.digitalnz.org/v3/records.json?text=kiwi`
]: nothing -> record<category: list<string>, collection: list<string>, collection_title: list<string>, content_partner: list<string>, copyright: list<string>, created_at: string, creator: list<string>, date: list<string>, dc_identifier: list<string>, description: string, display_collection: string, display_content_partner: string, display_date: string, id: int, landing_url: string, large_thumbnail_url: string, locations: table<comment: string, lat: float, lng: float, placename: string>, primary_collection: list<string>, rights: string, rights_url: list<string>, source_url: string, subject: list<string>, thumbnail_url: string, title: string, updated_at: string, usage: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({record_id: $record_id, format: $format} | format pattern "/records/{record_id}.{format}") $qp)
  let extra_headers = {"Authentication-Token": $authentication_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The "More Like This" call returns similar records to the specified ID.
#
# GET /records/{record_id}/more_like_this.{format}
export def "records-more-like-this-format get" [
  record_id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated whitelist of fields to be returned. The syntax *"&fields=verbose"* can be used to return the bulk of the fields, or you can customise which fields you are interested in, eg. *"&fields=id,title,subject,collection,landing_url,locations"*.
  --mlt-fields: string # Comma-separated list of fields used to evaluate relatedness. Available fields to compare are *title* and *subject*, eg *&mlt_fields=title,subject* or *&mlt_fields=title*.
  --filtering: string # More Like This (MLT) queries can be filtered in the same ways as regular searches, using the same syntax outined in the GET /records call above. This enables things like scoping the related records to only return Images eg *&and[category]=Images*, or to only show related records from a specific content partner eg *&and[content_partner]=Puke+Ariki*.
  --authentication-token: string # The DigitalNZ API no longer requires a key to access public content. However, if you plan on using the API regularly, expect to be a high volume consumer or are planning on creating an application, we encourage you to use an API key so that we can: - provide targeted help and support - increase your query throughput (by negotiation) - notify you directly of changes to the API - gather usage metrics to help improve the service    API requests that do not pass a valid API key/token are treated as unauthenticated. A maximum rate limit applies across all unauthenticated requests. This rate limit is in place to protect the service from overuse, resulting in unsustainable costs, or potential attack.  **Getting an API key**   [Create a DigitalNZ account](https://digitalnz.org/sign_up), log in and select "[my API key](https://digitalnz.org/api_keys/edit)" from your username drop-down menu (on the right hand side)'. The key is a long string of jumbled letters and numbers (hash) that is unique to you. You are required to keep the key secret. (Refer to the [Developer API Terms of Use](https://digitalnz.org/about/terms-of-use/developer-api-terms-of-use) for more information).  **Using an API key**   When you make a call to the API you'll need to pass the key in a custom HTTP header: ‘Authentication-Token’. For example, a query using the ‘curl’ command might look like the following (where ‘{YOUR_API_KEY}’ is replaced with a valid API key):  `curl -H "Authentication-Token:{YOUR_API_KEY}" http://api.digitalnz.org/v3/records.json?text=kiwi`
]: nothing -> record<page: int, per_page: int, records: table<category: list, collection: list, collection_title: list, content_partner: list, copyright: list, created_at: string, creator: list, date: list, dc_identifier: list, description: string, display_collection: string, display_content_partner: string, display_date: string, id: int, landing_url: string, large_thumbnail_url: string, locations: list, primary_collection: list, rights: string, rights_url: list, source_url: string, subject: list, thumbnail_url: string, title: string, updated_at: string, usage: list>, request_url: string, result_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "mlt_fields" $mlt_fields "scalar") (serialize-qp "filtering" $filtering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({record_id: $record_id, format: $format} | format pattern "/records/{record_id}/more_like_this.{format}") $qp)
  let extra_headers = {"Authentication-Token": $authentication_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
