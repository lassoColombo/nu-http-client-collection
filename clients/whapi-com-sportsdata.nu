# Auto-generated client for SportsData API v2
# Source: https://api.apis.guru/v2/specs/whapi.com/sportsdata/2/swagger.json
# Auth: --token flag or $env.SPORTSDATA_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/sportsdata"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPORTSDATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://sandbox.whapi.com/v2/sportsdata"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "classes-competitions get-for-class" } } | get name | first)
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

# Retrieves a list of competitions for a given class id.
#
# GET /classes/{classId}/competitions/
# operationId: getCompetitionsForClass
export def "classes-competitions get-for-class" [
  class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<competitions: table<betInRunningDelay: float, cashinAvailable: bool, channels: list, description: string, displayed: bool, flags: list, id: string, isPublished: bool, name: string, order: int, parentIds: list, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($class_id | is-empty) { error make --unspanned { msg: "path parameter 'classId' must be non-empty" } }
  let qp = [(serialize-qp "isPublished" $is_published "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_id: (encode-path-segment $class_id)} | format pattern "/classes/{class_id}/competitions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isPublished": $is_published, "fields": $fields, "include": $include, "exclude": $exclude, "displayed": $displayed, "channel": $channel, "status": $status, "sort": $qp_sort, "offset": $offset, "limit": $limit, "culture": $culture} | compact), body: null}
}

# Retrieves a list of events for a given class id.
#
# GET /classes/{classId}/events/
# operationId: getEventsForClass
export def "classes-events get-for-class" [
  class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --settled: oneof<nothing, bool> # Specify wether only settled entities should be returned
  --include-empty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --headline-summary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --include-all-descendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --is-in-play: oneof<nothing, bool> # Show only events that are in-play
  --market-count: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --date: string # Return only events for the specified date (yyyy-MM-dd).
  --date-from: string # The UTC datetime from the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --date-to: string # The UTC datetime TO the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --event-sort: string # Filter event by event sort
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --market-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --market-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --market-displayed: string # Specify whether to return displayed entities or not (default: yes)
  --market-channel: string # Specify a channel filter and only results from that channel will be returned
  --market-sort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --market-ew: string # Specify whether to return markets with each way betting or those without
  --selection-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selection-channel: string # Specify a channel filter and only results from that channel will be returned
  --selection-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($class_id | is-empty) { error make --unspanned { msg: "path parameter 'classId' must be non-empty" } }
  let qp = [(serialize-qp "isPublished" $is_published "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "settled" $settled "scalar") (serialize-qp "includeEmpty" $include_empty "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "headlineSummary" $headline_summary "scalar") (serialize-qp "includeAllDescendants" $include_all_descendants "scalar") (serialize-qp "isInPlay" $is_in_play "scalar") (serialize-qp "marketCount" $market_count "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "eventSort" $event_sort "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $market_published "scalar") (serialize-qp "marketStatus" $market_status "scalar") (serialize-qp "marketDisplayed" $market_displayed "scalar") (serialize-qp "marketChannel" $market_channel "scalar") (serialize-qp "marketSort" $market_sort "scalar") (serialize-qp "marketEW" $market_ew "scalar") (serialize-qp "selectionStatus" $selection_status "scalar") (serialize-qp "selectionChannel" $selection_channel "scalar") (serialize-qp "selectionPublished" $selection_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_id: (encode-path-segment $class_id)} | format pattern "/classes/{class_id}/events/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isPublished": $is_published, "fields": $fields, "include": $include, "exclude": $exclude, "displayed": $displayed, "channel": $channel, "settled": $settled, "includeEmpty": $include_empty, "status": $status, "sort": $qp_sort, "offset": $offset, "limit": $limit, "headlineSummary": $headline_summary, "includeAllDescendants": $include_all_descendants, "isInPlay": $is_in_play, "marketCount": $market_count, "date": $date, "dateFrom": $date_from, "dateTo": $date_to, "eventSort": $event_sort, "culture": $culture, "marketPublished": $market_published, "marketStatus": $market_status, "marketDisplayed": $market_displayed, "marketChannel": $market_channel, "marketSort": $market_sort, "marketEW": $market_ew, "selectionStatus": $selection_status, "selectionChannel": $selection_channel, "selectionPublished": $selection_published} | compact), body: null}
}

# Retrieves a specific competition
#
# GET /competitions/{competitionId}
# operationId: getCompetition
export def "competitions get" [
  competition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<betInRunningDelay: float, cashinAvailable: bool, channels: list<string>, description: string, displayed: bool, flags: list<string>, id: string, isPublished: bool, name: string, order: int, parentIds: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($competition_id | is-empty) { error make --unspanned { msg: "path parameter 'competitionId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({competition_id: (encode-path-segment $competition_id)} | format pattern "/competitions/{competition_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude, "culture": $culture} | compact), body: null}
}

# Retrieves a list of events for a given competition id.
#
# GET /competitions/{competitionId}/events/
# operationId: getEventsForCompetition
export def "competitions-events get" [
  competition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --settled: oneof<nothing, bool> # Specify wether only settled entities should be returned
  --include-empty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --headline-summary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --include-all-descendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --is-in-play: oneof<nothing, bool> # Show only events that are in-play
  --market-count: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --date: string # Return only events for the specified date (yyyy-MM-dd).
  --date-from: string # The UTC datetime from the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --date-to: string # The UTC datetime TO the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --market-group-id: string # Filter by marketGroupId (e.g. OB_MG1276585).
  --event-sort: string # Filter event by event sort
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --market-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --market-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --market-displayed: string # Specify whether to return displayed entities or not (default: yes)
  --market-channel: string # Specify a channel filter and only results from that channel will be returned
  --market-sort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --market-ew: string # Specify whether to return markets with each way betting or those without
  --selection-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selection-channel: string # Specify a channel filter and only results from that channel will be returned
  --selection-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($competition_id | is-empty) { error make --unspanned { msg: "path parameter 'competitionId' must be non-empty" } }
  let qp = [(serialize-qp "isPublished" $is_published "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "settled" $settled "scalar") (serialize-qp "includeEmpty" $include_empty "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "headlineSummary" $headline_summary "scalar") (serialize-qp "includeAllDescendants" $include_all_descendants "scalar") (serialize-qp "isInPlay" $is_in_play "scalar") (serialize-qp "marketCount" $market_count "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "marketGroupId" $market_group_id "scalar") (serialize-qp "eventSort" $event_sort "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $market_published "scalar") (serialize-qp "marketStatus" $market_status "scalar") (serialize-qp "marketDisplayed" $market_displayed "scalar") (serialize-qp "marketChannel" $market_channel "scalar") (serialize-qp "marketSort" $market_sort "scalar") (serialize-qp "marketEW" $market_ew "scalar") (serialize-qp "selectionStatus" $selection_status "scalar") (serialize-qp "selectionChannel" $selection_channel "scalar") (serialize-qp "selectionPublished" $selection_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({competition_id: (encode-path-segment $competition_id)} | format pattern "/competitions/{competition_id}/events/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isPublished": $is_published, "fields": $fields, "include": $include, "exclude": $exclude, "displayed": $displayed, "channel": $channel, "settled": $settled, "includeEmpty": $include_empty, "status": $status, "sort": $qp_sort, "offset": $offset, "limit": $limit, "headlineSummary": $headline_summary, "includeAllDescendants": $include_all_descendants, "isInPlay": $is_in_play, "marketCount": $market_count, "date": $date, "dateFrom": $date_from, "dateTo": $date_to, "marketGroupId": $market_group_id, "eventSort": $event_sort, "culture": $culture, "marketPublished": $market_published, "marketStatus": $market_status, "marketDisplayed": $market_displayed, "marketChannel": $market_channel, "marketSort": $market_sort, "marketEW": $market_ew, "selectionStatus": $selection_status, "selectionChannel": $selection_channel, "selectionPublished": $selection_published} | compact), body: null}
}

# Retrieves a list of market groups for a given competition id
#
# GET /competitions/{competitionId}/marketgroups/
# operationId: getMarketGroupsForCompetition
export def "competitions-marketgroups get-market-groups" [
  competition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --name: string # Filter by market group name
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<marketGroups: table<collectionId: string, competitionId: string, id: string, marketSort: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($competition_id | is-empty) { error make --unspanned { msg: "path parameter 'competitionId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({competition_id: (encode-path-segment $competition_id)} | format pattern "/competitions/{competition_id}/marketgroups/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude, "sort": $qp_sort, "offset": $offset, "limit": $limit, "culture": $culture, "name": $name} | compact), body: null}
}

# Retrieves a list of events/markets/selections where markets within said event match selected sort/groupId
#
# GET /competitions/{competitionId}/marketsByGroupid
# operationId: getMarketsByGroupId
export def "competitions-markets-by-groupid get-group" [
  competition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --market-sort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --market-group-id: string # Filter by marketGroupId (e.g. OB_MG1276585).
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<marketGroups: table<collectionId: string, competitionId: string, id: string, marketSort: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($competition_id | is-empty) { error make --unspanned { msg: "path parameter 'competitionId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "marketSort" $market_sort "scalar") (serialize-qp "marketGroupId" $market_group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({competition_id: (encode-path-segment $competition_id)} | format pattern "/competitions/{competition_id}/marketsByGroupid") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude, "marketSort": $market_sort, "marketGroupId": $market_group_id} | compact), body: null}
}

# Retrieves a list of events for the provided IDs.
#
# GET /events/
# operationId: getEvents
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # A comma-separated list of selectionIds
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --include-all-descendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --settled: oneof<nothing, bool> # Specify wether only settled entities should be returned
  --include-empty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --headline-summary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --market-count: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --market-ids: list<string> # Comma-seaerated list of market IDs to filter by
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --market-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --market-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --market-displayed: string # Specify whether to return displayed entities or not (default: yes)
  --market-channel: string # Specify a channel filter and only results from that channel will be returned
  --market-sort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --market-ew: string # Specify whether to return markets with each way betting or those without
  --selection-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selection-channel: string # Specify a channel filter and only results from that channel will be returned
  --selection-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "isPublished" $is_published "scalar") (serialize-qp "includeAllDescendants" $include_all_descendants "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "channel" $channel "scalar") (serialize-qp "settled" $settled "scalar") (serialize-qp "includeEmpty" $include_empty "scalar") (serialize-qp "headlineSummary" $headline_summary "scalar") (serialize-qp "marketCount" $market_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marketIds" $market_ids "csv") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $market_published "scalar") (serialize-qp "marketStatus" $market_status "scalar") (serialize-qp "marketDisplayed" $market_displayed "scalar") (serialize-qp "marketChannel" $market_channel "scalar") (serialize-qp "marketSort" $market_sort "scalar") (serialize-qp "marketEW" $market_ew "scalar") (serialize-qp "selectionStatus" $selection_status "scalar") (serialize-qp "selectionChannel" $selection_channel "scalar") (serialize-qp "selectionPublished" $selection_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "isPublished": $is_published, "includeAllDescendants": $include_all_descendants, "fields": $fields, "include": $include, "exclude": $exclude, "channel": $channel, "settled": $settled, "includeEmpty": $include_empty, "headlineSummary": $headline_summary, "marketCount": $market_count, "sort": $qp_sort, "offset": $offset, "limit": $limit, "marketIds": $market_ids, "culture": $culture, "marketPublished": $market_published, "marketStatus": $market_status, "marketDisplayed": $market_displayed, "marketChannel": $market_channel, "marketSort": $market_sort, "marketEW": $market_ew, "selectionStatus": $selection_status, "selectionChannel": $selection_channel, "selectionPublished": $selection_published} | compact), body: null}
}

# Retrieves a single event by ID.
#
# GET /events/{eventId}
# operationId: getEvent
export def "events get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-all-descendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --headline-summary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --market-count: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --market-ids: list<string> # Comma-seaerated list of market IDs to filter by
  --include-empty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --market-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --market-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --market-displayed: string # Specify whether to return displayed entities or not (default: yes)
  --market-channel: string # Specify a channel filter and only results from that channel will be returned
  --market-sort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --market-ew: string # Specify whether to return markets with each way betting or those without
  --selection-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selection-channel: string # Specify a channel filter and only results from that channel will be returned
  --selection-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "includeAllDescendants" $include_all_descendants "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "headlineSummary" $headline_summary "scalar") (serialize-qp "marketCount" $market_count "scalar") (serialize-qp "marketIds" $market_ids "csv") (serialize-qp "includeEmpty" $include_empty "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $market_published "scalar") (serialize-qp "marketStatus" $market_status "scalar") (serialize-qp "marketDisplayed" $market_displayed "scalar") (serialize-qp "marketChannel" $market_channel "scalar") (serialize-qp "marketSort" $market_sort "scalar") (serialize-qp "marketEW" $market_ew "scalar") (serialize-qp "selectionStatus" $selection_status "scalar") (serialize-qp "selectionChannel" $selection_channel "scalar") (serialize-qp "selectionPublished" $selection_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includeAllDescendants": $include_all_descendants, "fields": $fields, "include": $include, "exclude": $exclude, "headlineSummary": $headline_summary, "marketCount": $market_count, "marketIds": $market_ids, "includeEmpty": $include_empty, "culture": $culture, "marketPublished": $market_published, "marketStatus": $market_status, "marketDisplayed": $market_displayed, "marketChannel": $market_channel, "marketSort": $market_sort, "marketEW": $market_ew, "selectionStatus": $selection_status, "selectionChannel": $selection_channel, "selectionPublished": $selection_published} | compact), body: null}
}

# Retrieves competitors for a single event by ID.
#
# GET /events/{eventId}/competitors
# operationId: getEventCompetitors
export def "events-competitors get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<competitors: table<age: float, colour: string, drawNumber: float, formGuide: string, id: float, jockeyName: string, name: string, overview: string, ownerName: string, rating: string, sex: string, silkImageUrl: string, trainerName: string, weightPounds: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/competitors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "include": $include, "exclude": $exclude} | compact), body: null}
}

# Gets one or more specific markets
#
# GET /events/{eventId}/markets/
# operationId: getMarkets
export def "events-markets get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # A comma-separated list of selectionIds
  --include-all-descendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --include-empty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --market-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --market-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --market-displayed: string # Specify whether to return displayed entities or not (default: yes)
  --market-channel: string # Specify a channel filter and only results from that channel will be returned
  --market-sort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --market-ew: string # Specify whether to return markets with each way betting or those without
  --selection-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selection-channel: string # Specify a channel filter and only results from that channel will be returned
  --selection-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<markets: table<antepostMarket: bool, bestOddsGuaranteed: bool, betInRunningDelay: float, channels: string, description: string, displayed: bool, eachWay: bool, eachWayFactorDen: float, eachWayFactorNum: float, eachWayPlaces: float, earlyPriceAvailable: bool, fcAvailable: bool, firstFourAvailable: bool, firstPriceAvailable: bool, flags: string, hcapMakeup: float, hcapValue: float, id: string, isInPlayMarket: bool, isPublished: bool, livePriceAvailable: bool, marketGroupCollectionId: string, marketGroupId: string, marketGroupName: string, marketSort: string, name: string, order: float, parentIds: list, quinellaAvailable: bool, selections: list, settled: bool, startingPriceAvailable: bool, status: string, tcAvailable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "includeAllDescendants" $include_all_descendants "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "includeEmpty" $include_empty "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $market_published "scalar") (serialize-qp "marketStatus" $market_status "scalar") (serialize-qp "marketDisplayed" $market_displayed "scalar") (serialize-qp "marketChannel" $market_channel "scalar") (serialize-qp "marketSort" $market_sort "scalar") (serialize-qp "marketEW" $market_ew "scalar") (serialize-qp "selectionStatus" $selection_status "scalar") (serialize-qp "selectionChannel" $selection_channel "scalar") (serialize-qp "selectionPublished" $selection_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}/markets/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "includeAllDescendants": $include_all_descendants, "fields": $fields, "include": $include, "exclude": $exclude, "includeEmpty": $include_empty, "culture": $culture, "marketPublished": $market_published, "marketStatus": $market_status, "marketDisplayed": $market_displayed, "marketChannel": $market_channel, "marketSort": $market_sort, "marketEW": $market_ew, "selectionStatus": $selection_status, "selectionChannel": $selection_channel, "selectionPublished": $selection_published} | compact), body: null}
}

# Gets one or more selections for a market
#
# GET /events/{eventId}/markets/{marketId}/selections/
# operationId: getSelections
export def "events-markets-selections get" [
  event_id: string
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # A comma-separated list of selectionIds
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --selection-status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selection-channel: string # Specify a channel filter and only results from that channel will be returned
  --selection-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<selections: table<cashinPriceDen: float, cashinPriceNum: float, channels: list, csAway: float, csHome: float, currentPriceDen: float, currentPriceNum: float, description: string, displayed: bool, id: string, isPublished: bool, name: string, oddsDecimal: float, oddsFractional: float, order: float, parentIds: list, priceFormatted: record, result: string, resultType: string, runnerNum: float, settled: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "culture" $culture "scalar") (serialize-qp "selectionStatus" $selection_status "scalar") (serialize-qp "selectionChannel" $selection_channel "scalar") (serialize-qp "selectionPublished" $selection_published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id), market_id: (encode-path-segment $market_id)} | format pattern "/events/{event_id}/markets/{market_id}/selections/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids, "fields": $fields, "include": $include, "exclude": $exclude, "culture": $culture, "selectionStatus": $selection_status, "selectionChannel": $selection_channel, "selectionPublished": $selection_published} | compact), body: null}
}

# Gets a list of all sports
#
# GET /sports/
# operationId: getSports
export def "sports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --limit: int # Specify the number of results to return (default: 100)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<sports: table<id: string, isPublished: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "isPublished" $is_published "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "offset": $offset, "isPublished": $is_published, "limit": $limit, "fields": $fields, "include": $include, "exclude": $exclude, "culture": $culture} | compact), body: null}
}

# Retrieves a list of classes for a given sport id.
#
# GET /sports/{sportId}/classes/
# operationId: getClassesForSport
export def "sports-classes get" [
  sport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<classes: table<id: string, isPublished: bool, name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sport_id | is-empty) { error make --unspanned { msg: "path parameter 'sportId' must be non-empty" } }
  let qp = [(serialize-qp "isPublished" $is_published "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sport_id: (encode-path-segment $sport_id)} | format pattern "/sports/{sport_id}/classes/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isPublished": $is_published, "fields": $fields, "include": $include, "exclude": $exclude, "displayed": $displayed, "channel": $channel, "status": $status, "sort": $qp_sort, "offset": $offset, "limit": $limit, "culture": $culture} | compact), body: null}
}

# Retrieves a list of competitions for a given sport id.
#
# GET /sports/{sportId}/competitions/
# operationId: getCompetitionsForSport
export def "sports-competitions get" [
  sport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-published: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<competitions: table<betInRunningDelay: float, cashinAvailable: bool, channels: list, description: string, displayed: bool, flags: list, id: string, isPublished: bool, name: string, order: int, parentIds: list, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sport_id | is-empty) { error make --unspanned { msg: "path parameter 'sportId' must be non-empty" } }
  let qp = [(serialize-qp "isPublished" $is_published "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sport_id: (encode-path-segment $sport_id)} | format pattern "/sports/{sport_id}/competitions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isPublished": $is_published, "fields": $fields, "include": $include, "exclude": $exclude, "displayed": $displayed, "channel": $channel, "status": $status, "sort": $qp_sort, "offset": $offset, "limit": $limit, "culture": $culture} | compact), body: null}
}

# Retrieves a weighted list of Selections.
#
# GET /topbets/
# operationId: getTopBets
export def "topbets get-top-bets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sport-ids: list<string> # A comma-separated list of sportsIds for which to retrieve topBets for
  --competition-ids: list<string> # A comma-separated list of competitionIds for which to retrieve topBets for
  --limit: int # Specify the number of results to return (default: 100)
  --fields: list<string> # Specify an absolute field list to return (Comma-Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma-Separated List)
  --param-top-bet-event-id: string # The event ID to retrieve top bet information for. Multiple events up to 5 may be used
  --sort-name: string # The market sort code used to further filter event results. Please note this can only be used with event id(s).
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --locale: string # Code used to select a set of top bets settings, default is "whapi" which allows events set in far future to be included, setting the value to "en-GB" will activate english sportsbook settings, mirroring top bets on the website, which restricts events returned to those taking place in next 36 hours. Acceptable values (not all heve their own settings - if none currently available for that locale - en-GB will be used) are de-DE|whapi|en-GB|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --api-key: string # Your API Key available from your developer portal
]: nothing -> record<bets: table<competition: record, event: record, market: record, selection: record, sport: record, weight: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sportIds" $sport_ids "csv") (serialize-qp "competitionIds" $competition_ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "param_topBetEventId" $param_top_bet_event_id "scalar") (serialize-qp "sortName" $sort_name "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "Locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topbets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sportIds": $sport_ids, "competitionIds": $competition_ids, "limit": $limit, "fields": $fields, "include": $include, "exclude": $exclude, "param_topBetEventId": $param_top_bet_event_id, "sortName": $sort_name, "culture": $culture, "Locale": $locale} | compact), body: null}
}
