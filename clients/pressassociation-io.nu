# Auto-generated client for TV API v2.0
# Source: https://api.apis.guru/v2/specs/pressassociation.io/2.0/openapi.json
# Auth: --token flag or $env.TV_API_TOKEN

const BASE_URL = "https://tv.api.pressassociation.io/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TV_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "apikey" => { {scheme: $scheme, headers: {apikey: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://tv.api.pressassociation.io/v2" "http://tv.api.pressassociation.io/v2"] }
def auth-scheme-completer [] { ["apikey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "asset list" } } | get name | first)
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

# Asset Collection
#
# GET /asset
# operationId: listAssets
export def "asset list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-after: string # Updated After (default: 2015-05-05T00:00:00.000Z)
  --limit: int # Limit the the number of items to be returned per page. For example: 5. (format: int32, default: 100)
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedAfter" $updated_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/asset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"updatedAfter": $updated_after, "limit": $limit, "aliases": $aliases} | compact), body: null}
}

# Asset Detail
#
# GET /asset/{assetId}
# operationId: getAsset
export def "asset get" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'assetId' must be non-empty" } }
  let qp = [(serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/asset/{asset_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aliases": $aliases} | compact), body: null}
}

# Asset Contributors
#
# GET /asset/{assetId}/contributor
# operationId: getAssetContributors
export def "asset-contributor get" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'assetId' must be non-empty" } }
  let qp = [(serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_id: (encode-path-segment $asset_id)} | format pattern "/asset/{asset_id}/contributor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aliases": $aliases} | compact), body: null}
}

# Catalogue Collection
#
# GET /catalogue
# operationId: listCatalogues
export def "catalogue list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalogue")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Catalogue Detail
#
# GET /catalogue/{catalogueId}
# operationId: getCatalogue
export def "catalogue get" [
  catalogue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogue_id | is-empty) { error make --unspanned { msg: "path parameter 'catalogueId' must be non-empty" } }
  let full_url = (build-url $base ({catalogue_id: (encode-path-segment $catalogue_id)} | format pattern "/catalogue/{catalogue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Catalogue Asset Collection
#
# GET /catalogue/{catalogueId}/asset
# operationId: getCatalogueAsset
export def "catalogue-asset get" [
  catalogue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The query string for a title search
  --start: string # The Start Date for the catalogue date range. (default: 2015-05-05T00:00:00)
  --end: string # The End Date for the catalogue date range. (default: 2015-05-06T00:00:00)
  --updated-after: string # Retrieve items only that have been updated after this point. (default: 2015-05-06T00:00:00)
  --limit: float # Restrict number of returned items Min = 1, Max = 500. (default: 500)
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogue_id | is-empty) { error make --unspanned { msg: "path parameter 'catalogueId' must be non-empty" } }
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "updatedAfter" $updated_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({catalogue_id: (encode-path-segment $catalogue_id)} | format pattern "/catalogue/{catalogue_id}/asset") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"title": $title, "start": $start, "end": $end, "updatedAfter": $updated_after, "limit": $limit, "aliases": $aliases} | compact), body: null}
}

# Catalogue Asset Detail
#
# GET /catalogue/{catalogueId}/asset/{assetId}
# operationId: getCatalogueAssetDetail
export def "catalogue-asset get-detail" [
  catalogue_id: string
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($catalogue_id | is-empty) { error make --unspanned { msg: "path parameter 'catalogueId' must be non-empty" } }
  if ($asset_id | is-empty) { error make --unspanned { msg: "path parameter 'assetId' must be non-empty" } }
  let full_url = (build-url $base ({catalogue_id: (encode-path-segment $catalogue_id), asset_id: (encode-path-segment $asset_id)} | format pattern "/catalogue/{catalogue_id}/asset/{asset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Channel Collection
#
# GET /channel
# operationId: listChannels
export def "channel list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform-id: string # The identifier for the selected platform. Multiple platforms can be passed to the API without a region Id. Passing multiple platforms without a region will not return epg numbers as these are linked to a platform and region. (default: d3b26caa-8c7d-5f97-9eff-40fcf1a6f8d3)
  --region-id: string # The platform region ID for the channel selection. (default: afa4f624-da9b-54ce-b514-570345dbbdce)
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
  --date: string # Date of the Channel State to select, this will display channel names and attributes in the future or past. (default: 2018-09-15)
  --schedule-start: string # The Start Date for the schedule. (default: 2015-05-05T00:00:00)
  --schedule-end: string # The End Date for the schedule. (default: 2015-05-06T00:00:00)
  --schedule-updated-since: string # Schedule Updated Since (default: 2015-05-05T00:00:00)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platformId" $platform_id "scalar") (serialize-qp "regionId" $region_id "scalar") (serialize-qp "aliases" $aliases "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "scheduleStart" $schedule_start "scalar") (serialize-qp "scheduleEnd" $schedule_end "scalar") (serialize-qp "scheduleUpdatedSince" $schedule_updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"platformId": $platform_id, "regionId": $region_id, "aliases": $aliases, "date": $date, "scheduleStart": $schedule_start, "scheduleEnd": $schedule_end, "scheduleUpdatedSince": $schedule_updated_since} | compact), body: null}
}

# Channel Detail
#
# GET /channel/{channelId}
# operationId: getChannel
export def "channel get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channelId' must be non-empty" } }
  let qp = [(serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channel/{channel_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aliases": $aliases} | compact), body: null}
}

# Contributor Collection
#
# GET /contributor
# operationId: listContributor
export def "contributor list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-after: string # Updated After (default: 2015-05-05T00:00:00.000Z)
  --limit: int # Limit the the number of items to be returned per page. For example: 5. (format: int32, default: 100)
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedAfter" $updated_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contributor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"updatedAfter": $updated_after, "limit": $limit, "aliases": $aliases} | compact), body: null}
}

# Contributor Detail
#
# GET /contributor/{contributorId}
# operationId: getContributor
export def "contributor get" [
  contributor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($contributor_id | is-empty) { error make --unspanned { msg: "path parameter 'contributorId' must be non-empty" } }
  let qp = [(serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contributor_id: (encode-path-segment $contributor_id)} | format pattern "/contributor/{contributor_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aliases": $aliases} | compact), body: null}
}

# Feature Collection
#
# GET /feature
# operationId: listFeatures
export def "feature list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The namespace of the feature type. (default: netflix-monthly)
  --date: string # Date of the collection of feature items. (default: 2018-09-15)
  --start: string # Start date for a range of features. (default: 2018-09-15)
  --end: string # End date for a range of features. (default: 2018-10-15)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feature" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "date": $date, "start": $start, "end": $end} | compact), body: null}
}

# Feature Type Collection
#
# GET /feature-type
# operationId: listFeatureTypes
export def "feature-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feature-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Feature Detail
#
# GET /feature/{featureId}
# operationId: getFeature
export def "feature get" [
  feature_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($feature_id | is-empty) { error make --unspanned { msg: "path parameter 'featureId' must be non-empty" } }
  let full_url = (build-url $base ({feature_id: (encode-path-segment $feature_id)} | format pattern "/feature/{feature_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Platform Collection
#
# GET /platform
# operationId: listPlatforms
export def "platform list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/platform" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aliases": $aliases} | compact), body: null}
}

# Platform Detail
#
# GET /platform/{platformId}
# operationId: getPlatform
export def "platform get" [
  platform_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($platform_id | is-empty) { error make --unspanned { msg: "path parameter 'platformId' must be non-empty" } }
  let full_url = (build-url $base ({platform_id: (encode-path-segment $platform_id)} | format pattern "/platform/{platform_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Platform Region Collection
#
# GET /platform/{platformId}/region
# operationId: listPlatformRegions
export def "platform-region list" [
  platform_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($platform_id | is-empty) { error make --unspanned { msg: "path parameter 'platformId' must be non-empty" } }
  let qp = [(serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform_id: (encode-path-segment $platform_id)} | format pattern "/platform/{platform_id}/region") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"aliases": $aliases} | compact), body: null}
}

# Schedule Collection
#
# GET /schedule
# operationId: listSchedule
export def "schedule list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # The identifier for the selected channel.
  --start: string # The Start Date for the schedule. (default: 2015-05-05T00:00:00)
  --end: string # The End Date for the schedule. (default: 2015-05-06T00:00:00)
  --aliases: oneof<nothing, bool> # Flag to display Legacy and Provider Ids. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelId" $channel_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "aliases" $aliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"channelId": $channel_id, "start": $start, "end": $end, "aliases": $aliases} | compact), body: null}
}
