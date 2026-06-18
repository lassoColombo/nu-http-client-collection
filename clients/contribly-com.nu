# Auto-generated client for Contribly v1.0.0
# Source: https://api.apis.guru/v2/specs/contribly.com/1.0.0/openapi.json
# Auth: --token flag or $env.CONTRIBLY_TOKEN

const BASE_URL = "https://api.contribly.com/1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTRIBLY_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.contribly.com/1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "artifact-formats get" } } | get name | first)
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

# Artifact formats
#
# GET /artifact-formats
export def "artifact-formats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contribution: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>, cover: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>, profileImage: table<contentType: string, fileExtension: string, forContentType: string, label: string, preserveAspectRatio: bool, public: bool, upscaleAllowed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/artifact-formats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List assignments
#
# GET /assignments
export def "assignments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to assignments owned by this user.
  --page: int # Pagination page
  --page-size: int # Pagination page size
  --q: string # Restrict results to assignments whose name or description matches this keyword.
  --url-words: string # Select an assignment by urlWords.
  --qp-open: oneof<nothing, bool> # Select open or closed assignments
  --always-open: oneof<nothing, bool> # Select assignments with no closing date.
  --tag: string # Restrict results to assignments which are tagged with this tag.
  --name: string # Restrict results to the assignment (or potentially assignments) with this exact name
]: nothing -> table<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "urlWords" $url_words "scalar") (serialize-qp "open" $qp_open "scalar") (serialize-qp "alwaysOpen" $always_open "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new assignment
#
# POST /assignments
# --cover shape: {artifacts?: list, id?: string, media?: record}
# --tags item shape: {colour?: string, id: string, name: string, tagSet?: record, urlWords?: string}
export def "assignments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allows-anonymous-contributions: oneof<nothing, bool>
  --cover: record # shape: {artifacts?: list, id?: string, media?: record}
  --description: string
  --embargo: string # format: date-time
  --ends: string # format: date-time
  --featured: oneof<nothing, bool>
  --id: string
  --media-required: oneof<nothing, bool>
  --moderator: string # Optional credential id of the login which will moderator this assignment.
  name: string
  --receipt-message: string # An optional assignment specific message to be displayed on successful contribution submission. For example, this might be used to inform contributors of assignment specific moderation time frames.
  --starts: string # format: date-time
  --tags: list # item shape: {colour?: string, id: string, name: string, tagSet?: record, urlWords?: string}
  --url-words: string
]: any -> record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list<record>, id: string, media: record<duration: float, id: string, place: record, type: string>>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>, urlWords: string, webUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assignments")
  let req_body = {"allowsAnonymousContributions": $allows_anonymous_contributions, "cover": $cover, "description": $description, "embargo": $embargo, "ends": $ends, "featured": $featured, "id": $id, "mediaRequired": $media_required, "moderator": $moderator, "name": $name, "receiptMessage": $receipt_message, "starts": $starts, "tags": $tags, "urlWords": $url_words} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete this assignment and all of it's contributions
#
# DELETE /assignments/{id}
export def "assignments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/assignments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single assigment by id
#
# GET /assignments/{id}
export def "assignments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list<record>, id: string, media: record<duration: float, id: string, place: record, type: string>>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>, urlWords: string, webUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/assignments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Recent changes
#
# GET /change-log
export def "change-log get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<date: string, description: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/change-log")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List valid contribution refinement types
#
# GET /contribution-refinement-types
export def "contribution-refinement-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contribution-refinement-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List contribution refinement options
#
# GET /contribution-refinements
export def "contribution-refinements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
  --refinements: string # Comma seperated list of refinement names.
  --refinement-size: float # Number of refinement options to return.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignment" $assignment "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "geohash" $geohash "scalar") (serialize-qp "hasLocation" $has_location "scalar") (serialize-qp "latLong" $lat_long "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "mediaType" $media_type "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "urlWords" $url_words "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "refinements" $refinements "scalar") (serialize-qp "refinementSize" $refinement_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contribution-refinements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List contributions
#
# GET /contributions
export def "contributions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --created-day: string # Limit results to contributions created on this day. (format: date)
  --created-month: string # Limit results to contributions created during this month.
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
  --ids: string # Restrict results to a list of specific contributions identified by a comma seperated list of ids.
  --format: string # Select output format. 'json' or 'rss'. Defaults to JSON.
]: nothing -> table<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: list<record>, moderationHistory: list<record>, place: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>, urlWords: string, via: record<authority: record, ipAddress: string, ipAddressPlace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignment" $assignment "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdDay" $created_day "scalar") (serialize-qp "createdMonth" $created_month "scalar") (serialize-qp "geohash" $geohash "scalar") (serialize-qp "hasLocation" $has_location "scalar") (serialize-qp "latLong" $lat_long "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "mediaType" $media_type "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "urlWords" $url_words "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contributions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new contribution
#
# POST /contributions
# --assignment shape: {allowsAnonymousContributions?: bool, callToAction?: string, cover?: record, created?: string, description?: string, embargo?: string, ends?: string, featured?: bool, id?: string, mediaRequired?: bool, moderator?: string, name?: string, open?: bool, receiptMessage?: string, starts?: string, tags?: list, urlWords?: string, webUrl?: string}
# --mediaUsages item shape: {artifacts?: list, id?: string, media?: record}
# --moderationHistory item shape: {action?: record, date: string, notes?: string}
# --place shape: {country?: string, geohash?: string, google?: string, latLong?: record, name?: string, osm?: record}
# --via shape: {authority?: record, ipAddress?: string, ipAddressPlace?: record}
export def "contributions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: record # shape: {allowsAnonymousContributions?: bool, callToAction?: string, cover?: record, created?: string, description?: string, embargo?: string, ends?: string, featured?: bool, id?: string, mediaRequired?: bool, moderator?: string, name?: string, open?: bool, receiptMessage?: string, starts?: string, tags?: list, urlWords?: string, webUrl?: string}
  --attribution: string # The public attribution for this contribution. This will be the display name of the registered user or the contributor's first and last name if they provided them while making a non authenticated contribution. A blank attribution field indicates and anonymous contribution.
  --body: string
  --created: string # format: date-time
  --headline: string
  --id: string
  --media-usages: list # item shape: {artifacts?: list, id?: string, media?: record}
  --moderation-history: list # item shape: {action?: record, date: string, notes?: string}
  --place: record # shape: {country?: string, geohash?: string, google?: string, latLong?: record, name?: string, osm?: record}
  --url-words: string
  --via: record # shape: {authority?: record, ipAddress?: string, ipAddressPlace?: record}
]: any -> record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contributions")
  let req_body = {"assignment": $assignment, "attribution": $attribution, "body": $body, "created": $created, "headline": $headline, "id": $id, "mediaUsages": $media_usages, "moderationHistory": $moderation_history, "place": $place, "urlWords": $url_words, "via": $via} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete this contribution
#
# DELETE /contributions/{id}
export def "contributions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contributions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single contribution by id
#
# GET /contributions/{id}
export def "contributions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignment: record<allowsAnonymousContributions: bool, callToAction: string, cover: record<artifacts: list, id: string, media: record>, created: string, description: string, embargo: string, ends: string, featured: bool, id: string, mediaRequired: bool, moderator: string, name: string, open: bool, receiptMessage: string, starts: string, tags: list<record>, urlWords: string, webUrl: string>, attribution: string, body: string, created: string, headline: string, id: string, mediaUsages: table<artifacts: list, id: string, media: record>, moderationHistory: table<action: record, date: string, notes: string>, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, urlWords: string, via: record<authority: record<client: record, id: string, user: record>, ipAddress: string, ipAddressPlace: record<country: string, geohash: string, google: string, latLong: record, name: string, osm: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contributions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Raise a flag against this contribution
#
# POST /contributions/{id}/flag
export def "contributions-flag create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # format: date-time
  --email: string
  --body-id: string
  --notes: string
  --type: string
]: any -> record<date: string, email: string, id: string, notes: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contributions/{id}/flag"))
  let req_body = {"date": $date, "email": $email, "id": $body_id, "notes": $notes, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Allows a user to mark a contribution as liked
#
# POST /contributions/{id}/like
export def "contributions-like create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contributions/{id}/like"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List users who have liked this contributions
#
# GET /contributions/{id}/likes
export def "contributions-likes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contributions/{id}/likes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Perform a moderation action on this contribution
#
# POST /contributions/{id}/moderate
# --action shape: {id: string, label: string, resultingState: record}
export def "contributions-moderate create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: record # shape: {id: string, label: string, resultingState: record}
  --notes: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contributions/{id}/moderate"))
  let req_body = {"action": $action, "notes": $notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List the credentials associated with the authenticated user.
#
# GET /credentials
export def "credentials get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<scopes: list<string>, type: string, user: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Event types
#
# GET /event-types
export def "event-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Export contributions.
#
# POST /export
export def "export create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
  --tagged: oneof<nothing, bool> # Should exported media files be tagged with metadata. Deprecated; use format instead.
  --combined: oneof<nothing, bool> # Included a combined file with all contribution text.
  --individual: oneof<nothing, bool> # Include individual text files for each contribution.
  --format: string # Media format to export; none, fullsize, tagged or original.
  --json: oneof<nothing, bool> # Include raw JSON for each contribution.
]: nothing -> record<downloadUrl: string, finished: string, id: string, owner: string, progress: float, started: string, step: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignment" $assignment "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "geohash" $geohash "scalar") (serialize-qp "hasLocation" $has_location "scalar") (serialize-qp "latLong" $lat_long "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "mediaType" $media_type "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "urlWords" $url_words "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "tagged" $tagged "scalar") (serialize-qp "combined" $combined "scalar") (serialize-qp "individual" $individual "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "json" $json "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Export contributions preflight summary.
#
# POST /export-summary
export def "export-summary create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to contributions submitted to this assignment.
  --country: string # Limit results to contributions which have a publicly visible location within the given country (specified by two letter country code).
  --created-before: string # Limit results to contributions created before this date time. (format: date-time)
  --created-after: string # Limit results to contributions created after this date time. (format: date-time)
  --geohash: string # Restrict results to contributions which have specified a location which falls within this geohash (or comma seperated list of multiple geohashes)
  --has-location: oneof<nothing, bool> # Restrict results to contributions which have a publicly visible location.
  --lat-long: string # Limit results to contributions with location near this latitude and longitude (comma seperated lat/long pair). Also see radius
  --radius: float # When limiting result by location with the latLong parameter, specify the radius in kilometers. (format: double)
  --media-type: string # Restrict results to contributions which include a media file of the given type (ie. image / video)
  --owned-by: string # Restrict results to contributions which are fall under the jurisdiction by this user.
  --q: string # Restrict results to contributions whose headline text matches this keyword.
  --url-words: string # Locate a specific contribution by URL words
  --user: string # Restrict results to contributions by this user identified by id.
]: nothing -> record<contributions: float, estimatedSize: string, media: float, totalMediaSize: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignment" $assignment "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "geohash" $geohash "scalar") (serialize-qp "hasLocation" $has_location "scalar") (serialize-qp "latLong" $lat_long "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "mediaType" $media_type "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "urlWords" $url_words "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export-summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single export job; poll to follow export progress.
#
# GET /exports/{id}
export def "exports get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<downloadUrl: string, finished: string, id: string, owner: string, progress: float, started: string, step: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/exports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List form responses
#
# GET /form-responses
export def "form-responses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Restrict results to responses submitted by this user.
  --form: string # Restrict results to responses submitted to this form.
  --contribution: string # Restrict results to responses relating to this contribution.
]: nothing -> table<contribution: string, date: string, form: string, id: string, responses: record, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "form" $form "scalar") (serialize-qp "contribution" $contribution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/form-responses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Submit a response to a form
#
# POST /form-responses
export def "form-responses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contribution: string
  --form: string
  --responses: record
]: any -> record<contribution: string, date: string, form: string, id: string, responses: record, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/form-responses")
  let req_body = {"contribution": $contribution, "form": $form, "responses": $responses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a single form response by id
#
# GET /form-responses/{id}
export def "form-responses get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contribution: string, date: string, form: string, id: string, responses: record, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/form-responses/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List forms
#
# GET /forms
export def "forms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to forms owned by this user.
]: nothing -> table<callToAction: string, cssUrl: string, fields: list<record>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownedBy" $owned_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a form
#
# POST /forms
# --fields item shape: {description?: string, label?: string, name?: string, options?: list<string>, public?: bool, required?: bool, type?: string}
# --tags item shape: {colour?: string, id: string, name: string, tagSet?: record, urlWords?: string}
export def "forms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-to-action: string
  --css-url: string
  --fields: list # item shape: {description?: string, label?: string, name?: string, options?: list<string>, public?: bool, required?: bool, type?: string}
  --heading: string
  --name: string
  --no-css: oneof<nothing, bool>
  --tags: list # item shape: {colour?: string, id: string, name: string, tagSet?: record, urlWords?: string}
]: any -> record<callToAction: string, cssUrl: string, fields: table<description: string, label: string, name: string, options: list, public: bool, required: bool, type: string>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forms")
  let req_body = {"callToAction": $call_to_action, "cssUrl": $css_url, "fields": $fields, "heading": $heading, "name": $name, "noCss": $no_css, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete this form and all of it's responses.
#
# DELETE /forms/{id}
export def "forms delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/forms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a single form by id
#
# GET /forms/{id}
export def "forms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callToAction: string, cssUrl: string, fields: table<description: string, label: string, name: string, options: list, public: bool, required: bool, type: string>, heading: string, id: string, name: string, noCss: bool, ownedBy: string, tags: table<colour: string, id: string, name: string, tagSet: record, urlWords: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/forms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Submit a new media file
#
# POST /media
export def "media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<duration: float, id: string, place: record<country: string, geohash: string, google: string, latLong: record<latitude: float, longitude: float>, name: string, osm: record<osmId: float, osmType: string>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# GET /notifications/contributions/{id}/preview
export def "notifications-contributions-preview get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Type of message to preview.
]: nothing -> record<email: string, html: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "message" $message "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notifications/contributions/{id}/preview") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Scopes
#
# GET /scopes
export def "scopes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Subscription types
#
# GET /subscription-types
export def "subscription-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List subscriptions for the authorised user.
#
# GET /subscriptions
export def "subscriptions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string
  --email: string
  --include-body: oneof<nothing, bool>
  --include-thumbenail: oneof<nothing, bool>
  --slack-channel: string
  types: list<string>
]: any -> table<assignment: string, email: string, id: string, includeBody: bool, includeThumbenail: bool, slackChannel: string, token: string, types: list<string>, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscriptions")
  let req_body = {"assignment": $assignment, "email": $email, "includeBody": $include_body, "includeThumbenail": $include_thumbenail, "slackChannel": $slack_channel, "types": $types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a subscription.
#
# DELETE /subscriptions/{id}
export def "subscriptions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/subscriptions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List tags
#
# GET /tags
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to those owned by this user.
  --tag-set: string # Restrict results to tags belonging to this tag set.
  --url-words: string # Restrict results by urlWords. Should be used with ownedBy when searching for one of your own tags.
]: nothing -> table<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "tagSet" $tag_set "scalar") (serialize-qp "urlWords" $url_words "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new tag
#
# POST /tags
# --tagSet shape: {id: string, name: string}
export def "tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --colour: string
  name: string
  --tag-set: record # shape: {id: string, name: string}
  --url-words: string
]: any -> record<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let req_body = {"colour": $colour, "name": $name, "tagSet": $tag_set, "urlWords": $url_words} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve a single tag by id
#
# GET /tags/{id}
export def "tags get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colour: string, id: string, name: string, tagSet: record<id: string, name: string>, urlWords: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tags/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List tag sets
#
# GET /tagsets
export def "tagsets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owned-by: string # Restrict results to those owned by this user.
  --url-words: string # Restrict results by urlWords. Should be used with ownedBy when searching for one of your own tag sets.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "urlWords" $url_words "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tagsets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new tag set
#
# POST /tagsets
export def "tagsets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  url_words: string
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tagsets")
  let req_body = {"name": $name, "urlWords": $url_words} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve a single tag set by id
#
# GET /tagsets/{id}
export def "tagsets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tagsets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List users
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment: string # Restrict results to the users who have contributed to this assignment.
  --country: string # Restrict results to the users who have submitted a contribution with a public location located within this country.
  --minimum-contributions: float # Restrict results to the users who have submitted at least this many contributions.
  --linked-profile: string # Restrict results to the users who a linked profile of this type.
  --owned-by: string # Restrict results to the users who are owned by of this owner.
  --submitted-before: string # Limit results to users who have submitted at least one contribution before this date time. (format: date-time)
  --submitted-after: string # Limit results to users who have submitted at least one contribution after this date time. (format: date-time)
  --username: string # Restrict results to the user with this username.
]: nothing -> table<bio: string, displayName: string, id: string, registered: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignment" $assignment "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "minimumContributions" $minimum_contributions "scalar") (serialize-qp "linkedProfile" $linked_profile "scalar") (serialize-qp "ownedBy" $owned_by "scalar") (serialize-qp "submittedBefore" $submitted_before "scalar") (serialize-qp "submittedAfter" $submitted_after "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve a single user by id
#
# GET /users/{id}
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bio: string, displayName: string, id: string, registered: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve a users linked profile by type
#
# GET /users/{id}/linked/{type}
export def "users-linked get" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bio: string, email: string, id: string, name: string, picture: string, profile: string, registered: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), type: (encode-path-segment $type)} | format pattern "/users/{id}/linked/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Verify token and return details of the owning user
#
# POST /verify
export def "verify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client: record<id: string, name: string>, id: string, user: record<bio: string, displayName: string, id: string, registered: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
