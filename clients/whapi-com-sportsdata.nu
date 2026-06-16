# Auto-generated client for SportsData API v2
# Source: https://api.apis.guru/v2/specs/whapi.com/sportsdata/2/swagger.json
# Auth: --token flag or $env.SPORTSDATA_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/sportsdata"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPORTSDATA_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox.whapi.com/v2/sportsdata"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "classes-competitions get" } } | get name | first)
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
export def "classes-competitions get" [
  classId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<competitions: table<betInRunningDelay: float, cashinAvailable: bool, channels: list, description: string, displayed: bool, flags: list, id: string, isPublished: bool, name: string, order: int, parentIds: list, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/classes/($classId)/competitions/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of events for a given class id.
#
# GET /classes/{classId}/events/
# operationId: getEventsForClass
export def "classes-events get" [
  classId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --settled: oneof<nothing, bool> # Specify wether only settled entities should be returned
  --includeEmpty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --headlineSummary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --includeAllDescendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --isInPlay: oneof<nothing, bool> # Show only events that are in-play
  --marketCount: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --date: string # Return only events for the specified date (yyyy-MM-dd).
  --dateFrom: string # The UTC datetime from the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --dateTo: string # The UTC datetime TO the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --eventSort: string # Filter event by event sort
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --marketPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --marketStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --marketDisplayed: string # Specify whether to return displayed entities or not (default: yes)
  --marketChannel: string # Specify a channel filter and only results from that channel will be returned
  --marketSort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --marketEW: string # Specify whether to return markets with each way betting or those without
  --selectionStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selectionChannel: string # Specify a channel filter and only results from that channel will be returned
  --selectionPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "settled" $settled "scalar") (serialize-qp "includeEmpty" $includeEmpty "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "headlineSummary" $headlineSummary "scalar") (serialize-qp "includeAllDescendants" $includeAllDescendants "scalar") (serialize-qp "isInPlay" $isInPlay "scalar") (serialize-qp "marketCount" $marketCount "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "eventSort" $eventSort "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $marketPublished "scalar") (serialize-qp "marketStatus" $marketStatus "scalar") (serialize-qp "marketDisplayed" $marketDisplayed "scalar") (serialize-qp "marketChannel" $marketChannel "scalar") (serialize-qp "marketSort" $marketSort "scalar") (serialize-qp "marketEW" $marketEW "scalar") (serialize-qp "selectionStatus" $selectionStatus "scalar") (serialize-qp "selectionChannel" $selectionChannel "scalar") (serialize-qp "selectionPublished" $selectionPublished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/classes/($classId)/events/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific competition
#
# GET /competitions/{competitionId}
# operationId: getCompetition
export def "competitions get" [
  competitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<betInRunningDelay: float, cashinAvailable: bool, channels: list<string>, description: string, displayed: bool, flags: list<string>, id: string, isPublished: bool, name: string, order: int, parentIds: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/competitions/($competitionId)" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of events for a given competition id.
#
# GET /competitions/{competitionId}/events/
# operationId: getEventsForCompetition
export def "competitions-events get" [
  competitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --settled: oneof<nothing, bool> # Specify wether only settled entities should be returned
  --includeEmpty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --headlineSummary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --includeAllDescendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --isInPlay: oneof<nothing, bool> # Show only events that are in-play
  --marketCount: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --date: string # Return only events for the specified date (yyyy-MM-dd).
  --dateFrom: string # The UTC datetime from the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --dateTo: string # The UTC datetime TO the events to be returned. (yyyy-MM-ddTHH:mm:ss)
  --marketGroupId: string # Filter by marketGroupId (e.g. OB_MG1276585).
  --eventSort: string # Filter event by event sort
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --marketPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --marketStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --marketDisplayed: string # Specify whether to return displayed entities or not (default: yes)
  --marketChannel: string # Specify a channel filter and only results from that channel will be returned
  --marketSort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --marketEW: string # Specify whether to return markets with each way betting or those without
  --selectionStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selectionChannel: string # Specify a channel filter and only results from that channel will be returned
  --selectionPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "settled" $settled "scalar") (serialize-qp "includeEmpty" $includeEmpty "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "headlineSummary" $headlineSummary "scalar") (serialize-qp "includeAllDescendants" $includeAllDescendants "scalar") (serialize-qp "isInPlay" $isInPlay "scalar") (serialize-qp "marketCount" $marketCount "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "marketGroupId" $marketGroupId "scalar") (serialize-qp "eventSort" $eventSort "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $marketPublished "scalar") (serialize-qp "marketStatus" $marketStatus "scalar") (serialize-qp "marketDisplayed" $marketDisplayed "scalar") (serialize-qp "marketChannel" $marketChannel "scalar") (serialize-qp "marketSort" $marketSort "scalar") (serialize-qp "marketEW" $marketEW "scalar") (serialize-qp "selectionStatus" $selectionStatus "scalar") (serialize-qp "selectionChannel" $selectionChannel "scalar") (serialize-qp "selectionPublished" $selectionPublished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/competitions/($competitionId)/events/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of market groups for a given competition id
#
# GET /competitions/{competitionId}/marketgroups/
# operationId: getMarketGroupsForCompetition
export def "competitions-marketgroups get" [
  competitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --name: string # Filter by market group name
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<marketGroups: table<collectionId: string, competitionId: string, id: string, marketSort: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/competitions/($competitionId)/marketgroups/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of events/markets/selections where markets within said event match selected sort/groupId
#
# GET /competitions/{competitionId}/marketsByGroupid
# operationId: getMarketsByGroupId
export def "competitions-markets-by-groupid get" [
  competitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --marketSort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --marketGroupId: string # Filter by marketGroupId (e.g. OB_MG1276585).
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<marketGroups: table<collectionId: string, competitionId: string, id: string, marketSort: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "marketSort" $marketSort "scalar") (serialize-qp "marketGroupId" $marketGroupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/competitions/($competitionId)/marketsByGroupid" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # A comma-separated list of selectionIds
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --includeAllDescendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --settled: oneof<nothing, bool> # Specify wether only settled entities should be returned
  --includeEmpty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --headlineSummary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --marketCount: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --marketIds: list # Comma-seaerated list of market IDs to filter by
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --marketPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --marketStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --marketDisplayed: string # Specify whether to return displayed entities or not (default: yes)
  --marketChannel: string # Specify a channel filter and only results from that channel will be returned
  --marketSort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --marketEW: string # Specify whether to return markets with each way betting or those without
  --selectionStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selectionChannel: string # Specify a channel filter and only results from that channel will be returned
  --selectionPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "includeAllDescendants" $includeAllDescendants "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "channel" $channel "scalar") (serialize-qp "settled" $settled "scalar") (serialize-qp "includeEmpty" $includeEmpty "scalar") (serialize-qp "headlineSummary" $headlineSummary "scalar") (serialize-qp "marketCount" $marketCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "marketIds" $marketIds "csv") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $marketPublished "scalar") (serialize-qp "marketStatus" $marketStatus "scalar") (serialize-qp "marketDisplayed" $marketDisplayed "scalar") (serialize-qp "marketChannel" $marketChannel "scalar") (serialize-qp "marketSort" $marketSort "scalar") (serialize-qp "marketEW" $marketEW "scalar") (serialize-qp "selectionStatus" $selectionStatus "scalar") (serialize-qp "selectionChannel" $selectionChannel "scalar") (serialize-qp "selectionPublished" $selectionPublished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a single event by ID.
#
# GET /events/{eventId}
# operationId: getEvent
export def "events get" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeAllDescendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --headlineSummary: oneof<nothing, bool> # Return only headline markets (Markets with the lowest display order) Either 1 InPlay and 1 Pre-Match, or the amount specified in marketCount, if available. Markets and Outcomes will be returned. (default: false)
  --marketCount: int # Specify the number of markets to return when requesting headlineSummary. This count of InPlay and Pre-Match markets will be returned.For example, when specifying 1, 1 In Play and 1 Pre Match market will be returned. (default: 1)
  --marketIds: list # Comma-seaerated list of market IDs to filter by
  --includeEmpty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --marketPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --marketStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --marketDisplayed: string # Specify whether to return displayed entities or not (default: yes)
  --marketChannel: string # Specify a channel filter and only results from that channel will be returned
  --marketSort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --marketEW: string # Specify whether to return markets with each way betting or those without
  --selectionStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selectionChannel: string # Specify a channel filter and only results from that channel will be returned
  --selectionPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<events: table<betInRunningDelay: float, bettingStatus: string, cashinAvailable: bool, channels: list, country: string, description: string, displayed: bool, eventSort: string, flags: list, hasInPlayMarkets: bool, hasLivePrices: bool, id: string, isInPlay: bool, isPublished: bool, marketCountActiveInPlay: float, marketCountActivePreMatch: float, marketCountActiveTotal: float, marketCountInPlay: float, marketCountPreMatch: float, markets: list, name: string, order: float, parentIds: list, raceNum: string, settled: bool, startDateTime: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAllDescendants" $includeAllDescendants "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "headlineSummary" $headlineSummary "scalar") (serialize-qp "marketCount" $marketCount "scalar") (serialize-qp "marketIds" $marketIds "csv") (serialize-qp "includeEmpty" $includeEmpty "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $marketPublished "scalar") (serialize-qp "marketStatus" $marketStatus "scalar") (serialize-qp "marketDisplayed" $marketDisplayed "scalar") (serialize-qp "marketChannel" $marketChannel "scalar") (serialize-qp "marketSort" $marketSort "scalar") (serialize-qp "marketEW" $marketEW "scalar") (serialize-qp "selectionStatus" $selectionStatus "scalar") (serialize-qp "selectionChannel" $selectionChannel "scalar") (serialize-qp "selectionPublished" $selectionPublished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($eventId)" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves competitors for a single event by ID.
#
# GET /events/{eventId}/competitors
# operationId: getEventCompetitors
export def "events-competitors get" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<competitors: table<age: float, colour: string, drawNumber: float, formGuide: string, id: float, jockeyName: string, name: string, overview: string, ownerName: string, rating: string, sex: string, silkImageUrl: string, trainerName: string, weightPounds: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($eventId)/competitors" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets one or more specific markets
#
# GET /events/{eventId}/markets/
# operationId: getMarkets
export def "events-markets get" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # A comma-separated list of selectionIds
  --includeAllDescendants: oneof<nothing, bool> # Include every descendant in the below heirarchy (default: false)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --includeEmpty: oneof<nothing, bool> # When declared as false it should exclude markets and events that have no selections / markets (default: true)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --marketPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --marketStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --marketDisplayed: string # Specify whether to return displayed entities or not (default: yes)
  --marketChannel: string # Specify a channel filter and only results from that channel will be returned
  --marketSort: string # Filter by market sort (e.g. MR (match result) -- (Outright)).
  --marketEW: string # Specify whether to return markets with each way betting or those without
  --selectionStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selectionChannel: string # Specify a channel filter and only results from that channel will be returned
  --selectionPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<markets: table<antepostMarket: bool, bestOddsGuaranteed: bool, betInRunningDelay: float, channels: string, description: string, displayed: bool, eachWay: bool, eachWayFactorDen: float, eachWayFactorNum: float, eachWayPlaces: float, earlyPriceAvailable: bool, fcAvailable: bool, firstFourAvailable: bool, firstPriceAvailable: bool, flags: string, hcapMakeup: float, hcapValue: float, id: string, isInPlayMarket: bool, isPublished: bool, livePriceAvailable: bool, marketGroupCollectionId: string, marketGroupId: string, marketGroupName: string, marketSort: string, name: string, order: float, parentIds: list, quinellaAvailable: bool, selections: list, settled: bool, startingPriceAvailable: bool, status: string, tcAvailable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "includeAllDescendants" $includeAllDescendants "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "includeEmpty" $includeEmpty "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "marketPublished" $marketPublished "scalar") (serialize-qp "marketStatus" $marketStatus "scalar") (serialize-qp "marketDisplayed" $marketDisplayed "scalar") (serialize-qp "marketChannel" $marketChannel "scalar") (serialize-qp "marketSort" $marketSort "scalar") (serialize-qp "marketEW" $marketEW "scalar") (serialize-qp "selectionStatus" $selectionStatus "scalar") (serialize-qp "selectionChannel" $selectionChannel "scalar") (serialize-qp "selectionPublished" $selectionPublished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($eventId)/markets/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets one or more selections for a market
#
# GET /events/{eventId}/markets/{marketId}/selections/
# operationId: getSelections
export def "events-markets-selections get" [
  eventId: string
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # A comma-separated list of selectionIds
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --selectionStatus: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --selectionChannel: string # Specify a channel filter and only results from that channel will be returned
  --selectionPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<selections: table<cashinPriceDen: float, cashinPriceNum: float, channels: list, csAway: float, csHome: float, currentPriceDen: float, currentPriceNum: float, description: string, displayed: bool, id: string, isPublished: bool, name: string, oddsDecimal: float, oddsFractional: float, order: float, parentIds: list, priceFormatted: record, result: string, resultType: string, runnerNum: float, settled: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "culture" $culture "scalar") (serialize-qp "selectionStatus" $selectionStatus "scalar") (serialize-qp "selectionChannel" $selectionChannel "scalar") (serialize-qp "selectionPublished" $selectionPublished "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($eventId)/markets/($marketId)/selections/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --limit: int # Specify the number of results to return (default: 100)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<sports: table<id: string, isPublished: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sports/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of classes for a given sport id.
#
# GET /sports/{sportId}/classes/
# operationId: getClassesForSport
export def "sports-classes get" [
  sportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<classes: table<id: string, isPublished: bool, name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sports/($sportId)/classes/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of competitions for a given sport id.
#
# GET /sports/{sportId}/competitions/
# operationId: getCompetitionsForSport
export def "sports-competitions get" [
  sportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPublished: string # Specify whether only active entities should be returned, according to the William Hill definition of active (default: yes)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --displayed: string # Specify whether to return displayed entities or not (default: yes)
  --channel: string # Specify a channel filter and only results from that channel will be returned
  --status: string # Specify a status to filter results by. This is currently A (active) or S (suspended)
  --qp-sort: string # The field to order the response by, followed by the order. For example: name,desc (default: id,asc)
  --offset: int # Skip over a number of elements by specifying a start value for the query (default: 0)
  --limit: int # Specify the number of results to return (default: 100)
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<competitions: table<betInRunningDelay: float, cashinAvailable: bool, channels: list, description: string, displayed: bool, flags: list, id: string, isPublished: bool, name: string, order: int, parentIds: list, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "displayed" $displayed "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "culture" $culture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sports/($sportId)/competitions/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a weighted list of Selections.
#
# GET /topbets/
# operationId: getTopBets
export def "topbets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sportIds: list # A comma-separated list of sportsIds for which to retrieve topBets for
  --competitionIds: list # A comma-separated list of competitionIds for which to retrieve topBets for
  --limit: int # Specify the number of results to return (default: 100)
  --fields: list # Specify an absolute field list to return (Comma-Separated List)
  --include: list # Specify fields in addition to the default to return (Comma-Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma-Separated List)
  --param-topBetEventId: string # The event ID to retrieve top bet information for. Multiple events up to 5 may be used
  --sortName: string # The market sort code used to further filter event results. Please note this can only be used with event id(s).
  --culture: string # Code used to return responses in language other than English, acceptable values are en-GB|de-DE|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --Locale: string # Code used to select a set of top bets settings, default is "whapi" which allows events set in far future to be included, setting the value to "en-GB" will activate english sportsbook settings, mirroring top bets on the website, which restricts events returned to those taking place in next 36 hours. Acceptable values (not all heve their own settings - if none currently available for that locale - en-GB will be used) are de-DE|whapi|en-GB|es-ES|fr-FR|nn-NO|fi-FI|ru-RU|pt-PT|hu-HU|sl-SL|ga-IE|en-CA|sr-Latn|sv-SE|el=GR|zh-CHS|it-IT|zh-CHT|cs-CZ|de-AT|ja-JP|pl-PL|da-DK|ro-RO|nl-NL|tr-TR
  --apiKey: string # Your API Key available from your developer portal
]: nothing -> record<bets: table<competition: record, event: record, market: record, selection: record, sport: record, weight: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sportIds" $sportIds "csv") (serialize-qp "competitionIds" $competitionIds "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "param_topBetEventId" $param_topBetEventId "scalar") (serialize-qp "sortName" $sortName "scalar") (serialize-qp "culture" $culture "scalar") (serialize-qp "Locale" $Locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topbets/" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
