# Auto-generated client for LaunchLibrary API v2.3.0 vv2.3.0
# Source: https://ll.thespacedevs.com/2.3.0/schema/
# Auth: --token flag or $env.LAUNCHLIBRARY_API_V2_3_0_TOKEN

const BASE_URL = "https://ll.thespacedevs.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LAUNCHLIBRARY_API_V2_3_0_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "cookie-sessionid" => { {headers: {Cookie: $"sessionid=($token_val)"}, query: ""} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["https://ll.thespacedevs.com" "https://lldev.thespacedevs.com"] }
def auth-scheme-completer [] { ["bearer" "cookie-sessionid"] }

# Completers for enum parameters
def mode-completer [] { ["detailed" "list" "normal"] }
def mode-completer-1 [] { ["detailed" "normal"] }
def mode-completer-2 [] { ["list" "normal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "230-agencies list" } } | get name | first)
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

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/agencies/?mode=list](./?mode=list)  #### Filters Parameters - `abbrev`, `abbrev__contains`, `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `consecutive_successful_landings`, `consecutive_successful_landings__gt`, `consecutive_successful_landings__gte`, `consecutive_successful_landings__lt`, `consecutive_successful_landings__lte`, `consecutive_successful_launches`, `consecutive_successful_launches__gt`, `consecutive_successful_launches__gte`, `consecutive_successful_launches__lt`, `consecutive_successful_launches__lte`, `country_code`, `description`, `description__contains`, `failed_landings`, `failed_landings__gt`, `failed_landings__gte`, `failed_landings__lt`, `failed_landings__lte`, `failed_launches`, `failed_launches__gt`, `failed_launches__gte`, `failed_launches__lt`, `failed_launches__lte`, `featured`, `founding_year`, `founding_year__gt`, `founding_year__gte`, `founding_year__lt`, `founding_year__lte`, `id`, `name`, `name__contains`, `parent__id`, `pending_launches`, `pending_launches__gt`, `pending_launches__gte`, `pending_launches__lt`, `pending_launches__lte`, `spacecraft`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`, `successful_launches`, `successful_launches__gt`, `successful_launches__gte`, `successful_launches__lt`, `successful_launches__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`, `type__id`  Example - [/agencies/?abbrev=NASA](./?abbrev=NASA)  #### Search Fields searched - `abbrev`, `name`  Example - [/agencies/?search=SpaceX](./?search=SpaceX)  #### Ordering Fields - `attempted_landings`, `consecutive_successful_landings`, `consecutive_successful_launches`, `failed_landings`, `failed_launches`, `featured`, `id`, `name`, `pending_launches`, `successful_landings`, `successful_launches`, `total_launch_count`  Example - [/agencies/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/agencies/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/agencies/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/agencies/
# operationId: agencies_list
export def "230-agencies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --abbrev: string
  --abbrev-contains: string
  --attempted-landings: int
  --attempted-landings-gt: int
  --attempted-landings-gte: int
  --attempted-landings-lt: int
  --attempted-landings-lte: int
  --consecutive-successful-landings: int
  --consecutive-successful-landings-gt: int
  --consecutive-successful-landings-gte: int
  --consecutive-successful-landings-lt: int
  --consecutive-successful-landings-lte: int
  --consecutive-successful-launches: int
  --consecutive-successful-launches-gt: int
  --consecutive-successful-launches-gte: int
  --consecutive-successful-launches-lt: int
  --consecutive-successful-launches-lte: int
  --country-code: list # Multiple values may be separated by commas.
  --description: string
  --description-contains: string
  --failed-landings: int
  --failed-landings-gt: int
  --failed-landings-gte: int
  --failed-landings-lt: int
  --failed-landings-lte: int
  --failed-launches: int
  --failed-launches-gt: int
  --failed-launches-gte: int
  --failed-launches-lt: int
  --failed-launches-lte: int
  --featured: oneof<nothing, bool>
  --founding-year: int
  --founding-year-gt: int
  --founding-year-gte: int
  --founding-year-lt: int
  --founding-year-lte: int
  --id: int
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --parent-id: int
  --pending-launches: int
  --pending-launches-gt: int
  --pending-launches-gte: int
  --pending-launches-lt: int
  --pending-launches-lte: int
  --search: string # A search term.
  --spacecraft: oneof<nothing, bool>
  --successful-landings: int
  --successful-landings-gt: int
  --successful-landings-gte: int
  --successful-landings-lt: int
  --successful-landings-lte: int
  --successful-launches: int
  --successful-launches-gt: int
  --successful-launches-gte: int
  --successful-launches-lt: int
  --successful-launches-lte: int
  --total-launch-count: int
  --total-launch-count-gt: int
  --total-launch-count-gte: int
  --total-launch-count-lt: int
  --total-launch-count-lte: int
  --type-id: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "abbrev" $abbrev "scalar") (serialize-qp "abbrev__contains" $abbrev_contains "scalar") (serialize-qp "attempted_landings" $attempted_landings "scalar") (serialize-qp "attempted_landings__gt" $attempted_landings_gt "scalar") (serialize-qp "attempted_landings__gte" $attempted_landings_gte "scalar") (serialize-qp "attempted_landings__lt" $attempted_landings_lt "scalar") (serialize-qp "attempted_landings__lte" $attempted_landings_lte "scalar") (serialize-qp "consecutive_successful_landings" $consecutive_successful_landings "scalar") (serialize-qp "consecutive_successful_landings__gt" $consecutive_successful_landings_gt "scalar") (serialize-qp "consecutive_successful_landings__gte" $consecutive_successful_landings_gte "scalar") (serialize-qp "consecutive_successful_landings__lt" $consecutive_successful_landings_lt "scalar") (serialize-qp "consecutive_successful_landings__lte" $consecutive_successful_landings_lte "scalar") (serialize-qp "consecutive_successful_launches" $consecutive_successful_launches "scalar") (serialize-qp "consecutive_successful_launches__gt" $consecutive_successful_launches_gt "scalar") (serialize-qp "consecutive_successful_launches__gte" $consecutive_successful_launches_gte "scalar") (serialize-qp "consecutive_successful_launches__lt" $consecutive_successful_launches_lt "scalar") (serialize-qp "consecutive_successful_launches__lte" $consecutive_successful_launches_lte "scalar") (serialize-qp "country_code" $country_code "csv") (serialize-qp "description" $description "scalar") (serialize-qp "description__contains" $description_contains "scalar") (serialize-qp "failed_landings" $failed_landings "scalar") (serialize-qp "failed_landings__gt" $failed_landings_gt "scalar") (serialize-qp "failed_landings__gte" $failed_landings_gte "scalar") (serialize-qp "failed_landings__lt" $failed_landings_lt "scalar") (serialize-qp "failed_landings__lte" $failed_landings_lte "scalar") (serialize-qp "failed_launches" $failed_launches "scalar") (serialize-qp "failed_launches__gt" $failed_launches_gt "scalar") (serialize-qp "failed_launches__gte" $failed_launches_gte "scalar") (serialize-qp "failed_launches__lt" $failed_launches_lt "scalar") (serialize-qp "failed_launches__lte" $failed_launches_lte "scalar") (serialize-qp "featured" $featured "scalar") (serialize-qp "founding_year" $founding_year "scalar") (serialize-qp "founding_year__gt" $founding_year_gt "scalar") (serialize-qp "founding_year__gte" $founding_year_gte "scalar") (serialize-qp "founding_year__lt" $founding_year_lt "scalar") (serialize-qp "founding_year__lte" $founding_year_lte "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "parent__id" $parent_id "scalar") (serialize-qp "pending_launches" $pending_launches "scalar") (serialize-qp "pending_launches__gt" $pending_launches_gt "scalar") (serialize-qp "pending_launches__gte" $pending_launches_gte "scalar") (serialize-qp "pending_launches__lt" $pending_launches_lt "scalar") (serialize-qp "pending_launches__lte" $pending_launches_lte "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "spacecraft" $spacecraft "scalar") (serialize-qp "successful_landings" $successful_landings "scalar") (serialize-qp "successful_landings__gt" $successful_landings_gt "scalar") (serialize-qp "successful_landings__gte" $successful_landings_gte "scalar") (serialize-qp "successful_landings__lt" $successful_landings_lt "scalar") (serialize-qp "successful_landings__lte" $successful_landings_lte "scalar") (serialize-qp "successful_launches" $successful_launches "scalar") (serialize-qp "successful_launches__gt" $successful_launches_gt "scalar") (serialize-qp "successful_launches__gte" $successful_launches_gte "scalar") (serialize-qp "successful_launches__lt" $successful_launches_lt "scalar") (serialize-qp "successful_launches__lte" $successful_launches_lte "scalar") (serialize-qp "total_launch_count" $total_launch_count "scalar") (serialize-qp "total_launch_count__gt" $total_launch_count_gt "scalar") (serialize-qp "total_launch_count__gte" $total_launch_count_gte "scalar") (serialize-qp "total_launch_count__lt" $total_launch_count_lt "scalar") (serialize-qp "total_launch_count__lte" $total_launch_count_lte "scalar") (serialize-qp "type__id" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/agencies/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/agencies/?mode=list](./?mode=list)  #### Filters Parameters - `abbrev`, `abbrev__contains`, `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `consecutive_successful_landings`, `consecutive_successful_landings__gt`, `consecutive_successful_landings__gte`, `consecutive_successful_landings__lt`, `consecutive_successful_landings__lte`, `consecutive_successful_launches`, `consecutive_successful_launches__gt`, `consecutive_successful_launches__gte`, `consecutive_successful_launches__lt`, `consecutive_successful_launches__lte`, `country_code`, `description`, `description__contains`, `failed_landings`, `failed_landings__gt`, `failed_landings__gte`, `failed_landings__lt`, `failed_landings__lte`, `failed_launches`, `failed_launches__gt`, `failed_launches__gte`, `failed_launches__lt`, `failed_launches__lte`, `featured`, `founding_year`, `founding_year__gt`, `founding_year__gte`, `founding_year__lt`, `founding_year__lte`, `id`, `name`, `name__contains`, `parent__id`, `pending_launches`, `pending_launches__gt`, `pending_launches__gte`, `pending_launches__lt`, `pending_launches__lte`, `spacecraft`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`, `successful_launches`, `successful_launches__gt`, `successful_launches__gte`, `successful_launches__lt`, `successful_launches__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`, `type__id`  Example - [/agencies/?abbrev=NASA](./?abbrev=NASA)  #### Search Fields searched - `abbrev`, `name`  Example - [/agencies/?search=SpaceX](./?search=SpaceX)  #### Ordering Fields - `attempted_landings`, `consecutive_successful_landings`, `consecutive_successful_launches`, `failed_landings`, `failed_launches`, `featured`, `id`, `name`, `pending_launches`, `successful_landings`, `successful_launches`, `total_launch_count`  Example - [/agencies/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/agencies/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/agencies/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/agencies/{id}/
# operationId: agencies_retrieve
export def "230-agencies get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: table<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: table<id: int, social_media: record, url: string>, launcher_list: table<response_mode: string, id: int, url: string, name: string, families: list, full_name: string, variant: string, active: bool, is_placeholder: bool, program: list, reusable: bool, image: record, info_url: string, wiki_url: string, description: string, alias: string, min_stage: int, max_stage: int, length: float, diameter: float, maiden_flight: string, launch_cost: int, launch_mass: float, leo_capacity: float, gto_capacity: float, geo_capacity: float, sso_capacity: float, to_thrust: float, apogee: float, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int, fastest_turnaround: string>, spacecraft_list: table<response_mode: string, id: int, url: string, name: string, type: record, agency: record, family: list, in_use: bool, image: record, capability: string, history: string, details: string, maiden_flight: string, height: float, diameter: float, human_rated: bool, crew_capacity: int, payload_capacity: int, payload_return_capacity: int, flight_life: string, wiki_link: string, info_link: string, spacecraft_flown: int, total_launch_count: int, successful_launches: int, failed_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, fastest_turnaround: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/agencies/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API endpoint that allows API Throttle information to be viewed.  GET: Returns a range of information about your API access
#
# GET /2.3.0/api-throttle/
# operationId: api_throttle_list
export def "230-api-throttle list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<your_request_limit: int, limit_frequency_secs: int, current_use: int, next_use_secs: int, ident: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2.3.0/api-throttle/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/astronauts/?mode=list](./?mode=list)  #### Filters Parameters - `age`, `age__gt`, `age__gte`, `age__lt`, `age__lte`, `agency_ids`, `date_of_birth`, `date_of_birth__gt`, `date_of_birth__gte`, `date_of_birth__lt`, `date_of_birth__lte`, `date_of_death`, `date_of_death__gt`, `date_of_death__gte`, `date_of_death__lt`, `date_of_death__lte`, `first_flight`, `first_flight__gt`, `first_flight__gte`, `first_flight__lt`, `first_flight__lte`, `flights_count`, `flights_count__gt`, `flights_count__gte`, `flights_count__lt`, `flights_count__lte`, `has_flown`, `in_space`, `is_human`, `landings_count`, `landings_count__gt`, `landings_count__gte`, `landings_count__lt`, `landings_count__lte`, `last_flight`, `last_flight__gt`, `last_flight__gte`, `last_flight__lt`, `last_flight__lte`, `nationality`, `status_ids`, `type__id`  Example - [/astronauts/?has_flown=true](./?has_flown=true)  #### Search Fields searched - `agency__abbrev`, `agency__name`, `name`, `nationality__nationality_name`  Example - [/astronauts/?search=Pesquet](./?search=Pesquet)  #### Ordering Fields - `age`, `date_of_birth`, `eva_time`, `flights_count`, `id`, `landings_count`, `last_flight`, `name`, `spacewalks_count`, `status`, `time_in_space`  Example - [/astronauts/?ordering=-time_in_space](./?ordering=-time_in_space)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/astronauts/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/astronauts/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/astronauts/
# operationId: astronauts_list
export def "230-astronauts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --age: int
  --age-gt: int
  --age-gte: int
  --age-lt: int
  --age-lte: int
  --agency-ids: list # Comma-separated agency IDs.
  --date-of-birth: string # format: date
  --date-of-birth-gt: string # format: date
  --date-of-birth-gte: string # format: date
  --date-of-birth-lt: string # format: date
  --date-of-birth-lte: string # format: date
  --date-of-death: string # format: date
  --date-of-death-gt: string # format: date
  --date-of-death-gte: string # format: date
  --date-of-death-lt: string # format: date
  --date-of-death-lte: string # format: date
  --first-flight: string # format: date-time
  --first-flight-gt: string # format: date-time
  --first-flight-gte: string # format: date-time
  --first-flight-lt: string # format: date-time
  --first-flight-lte: string # format: date-time
  --flights-count: int
  --flights-count-gt: int
  --flights-count-gte: int
  --flights-count-lt: int
  --flights-count-lte: int
  --has-flown: oneof<nothing, bool>
  --in-space: oneof<nothing, bool>
  --is-human: oneof<nothing, bool>
  --landings-count: int
  --landings-count-gt: int
  --landings-count-gte: int
  --landings-count-lt: int
  --landings-count-lte: int
  --last-flight: string # format: date-time
  --last-flight-gt: string # format: date-time
  --last-flight-gte: string # format: date-time
  --last-flight-lt: string # format: date-time
  --last-flight-lte: string # format: date-time
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --nationality: string # Nationality
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --status-ids: list # Comma-separated astronaut status IDs.
  --type-id: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age" $age "scalar") (serialize-qp "age__gt" $age_gt "scalar") (serialize-qp "age__gte" $age_gte "scalar") (serialize-qp "age__lt" $age_lt "scalar") (serialize-qp "age__lte" $age_lte "scalar") (serialize-qp "agency_ids" $agency_ids "csv") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "date_of_birth__gt" $date_of_birth_gt "scalar") (serialize-qp "date_of_birth__gte" $date_of_birth_gte "scalar") (serialize-qp "date_of_birth__lt" $date_of_birth_lt "scalar") (serialize-qp "date_of_birth__lte" $date_of_birth_lte "scalar") (serialize-qp "date_of_death" $date_of_death "scalar") (serialize-qp "date_of_death__gt" $date_of_death_gt "scalar") (serialize-qp "date_of_death__gte" $date_of_death_gte "scalar") (serialize-qp "date_of_death__lt" $date_of_death_lt "scalar") (serialize-qp "date_of_death__lte" $date_of_death_lte "scalar") (serialize-qp "first_flight" $first_flight "scalar") (serialize-qp "first_flight__gt" $first_flight_gt "scalar") (serialize-qp "first_flight__gte" $first_flight_gte "scalar") (serialize-qp "first_flight__lt" $first_flight_lt "scalar") (serialize-qp "first_flight__lte" $first_flight_lte "scalar") (serialize-qp "flights_count" $flights_count "scalar") (serialize-qp "flights_count__gt" $flights_count_gt "scalar") (serialize-qp "flights_count__gte" $flights_count_gte "scalar") (serialize-qp "flights_count__lt" $flights_count_lt "scalar") (serialize-qp "flights_count__lte" $flights_count_lte "scalar") (serialize-qp "has_flown" $has_flown "scalar") (serialize-qp "in_space" $in_space "scalar") (serialize-qp "is_human" $is_human "scalar") (serialize-qp "landings_count" $landings_count "scalar") (serialize-qp "landings_count__gt" $landings_count_gt "scalar") (serialize-qp "landings_count__gte" $landings_count_gte "scalar") (serialize-qp "landings_count__lt" $landings_count_lt "scalar") (serialize-qp "landings_count__lte" $landings_count_lte "scalar") (serialize-qp "last_flight" $last_flight "scalar") (serialize-qp "last_flight__gt" $last_flight_gt "scalar") (serialize-qp "last_flight__gte" $last_flight_gte "scalar") (serialize-qp "last_flight__lt" $last_flight_lt "scalar") (serialize-qp "last_flight__lte" $last_flight_lte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "nationality" $nationality "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status_ids" $status_ids "csv") (serialize-qp "type__id" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/astronauts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/astronauts/?mode=list](./?mode=list)  #### Filters Parameters - `age`, `age__gt`, `age__gte`, `age__lt`, `age__lte`, `agency_ids`, `date_of_birth`, `date_of_birth__gt`, `date_of_birth__gte`, `date_of_birth__lt`, `date_of_birth__lte`, `date_of_death`, `date_of_death__gt`, `date_of_death__gte`, `date_of_death__lt`, `date_of_death__lte`, `first_flight`, `first_flight__gt`, `first_flight__gte`, `first_flight__lt`, `first_flight__lte`, `flights_count`, `flights_count__gt`, `flights_count__gte`, `flights_count__lt`, `flights_count__lte`, `has_flown`, `in_space`, `is_human`, `landings_count`, `landings_count__gt`, `landings_count__gte`, `landings_count__lt`, `landings_count__lte`, `last_flight`, `last_flight__gt`, `last_flight__gte`, `last_flight__lt`, `last_flight__lte`, `nationality`, `status_ids`, `type__id`  Example - [/astronauts/?has_flown=true](./?has_flown=true)  #### Search Fields searched - `agency__abbrev`, `agency__name`, `name`, `nationality__nationality_name`  Example - [/astronauts/?search=Pesquet](./?search=Pesquet)  #### Ordering Fields - `age`, `date_of_birth`, `eva_time`, `flights_count`, `id`, `landings_count`, `last_flight`, `name`, `spacewalks_count`, `status`, `time_in_space`  Example - [/astronauts/?ordering=-time_in_space](./?ordering=-time_in_space)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/astronauts/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/astronauts/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/astronauts/{id}/
# operationId: astronauts_retrieve
export def "230-astronauts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, name: string, status: record<id: int, name: string>, agency: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, response_mode: string, type: record<id: int, name: string>, in_space: bool, time_in_space: string, eva_time: string, age: int, date_of_birth: string, date_of_death: string, nationality: table<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, bio: string, wiki: string, last_flight: string, first_flight: string, social_media_links: table<id: int, social_media: record, url: string>, flights_count: int, landings_count: int, spacewalks_count: int, flights: table<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, landings: table<id: int, url: string, destination: string, mission_end: string, spacecraft: record, launch: record, landing: record, duration: string, turn_around_time: string, response_mode: string>, spacewalks: table<response_mode: string, id: int, url: string, name: string, start: string, end: string, duration: string, location: string, crew: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/astronauts/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/celestial_bodies/?mode=list](./?mode=list)  #### Search Fields searched - `name`, `type__name`  Example - [/celestial_bodies/?search=Mars](./?search=Mars)  #### Ordering Fields - `id`, `name`  Example - [/celestial_bodies/?ordering=-name](./?ordering=-name)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/celestial_bodies/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/celestial_bodies/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/celestial_bodies/
# operationId: celestial_bodies_list
export def "230-celestial-bodies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/celestial_bodies/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/celestial_bodies/?mode=list](./?mode=list)  #### Search Fields searched - `name`, `type__name`  Example - [/celestial_bodies/?search=Mars](./?search=Mars)  #### Ordering Fields - `id`, `name`  Example - [/celestial_bodies/?ordering=-name](./?ordering=-name)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/celestial_bodies/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/celestial_bodies/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/celestial_bodies/{id}/
# operationId: celestial_bodies_retrieve
export def "230-celestial-bodies get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, name: string, type: record<id: int, name: string>, diameter: float, mass: float, gravity: float, length_of_day: string, atmosphere: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, description: string, wiki_url: string, total_attempted_launches: int, successful_launches: int, failed_launches: int, total_attempted_landings: int, successful_landings: int, failed_landings: int, locations: table<response_mode: string, id: int, url: string, name: string, active: bool, country: record, description: string, image: record, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/celestial_bodies/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/agency_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/agency_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/agency_types/
# operationId: config_agency_types_list
export def "230-config-agency-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/agency_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/agency_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/agency_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/agency_types/{id}/
# operationId: config_agency_types_retrieve
export def "230-config-agency-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/agency_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/astronaut_roles/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/astronaut_roles/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/astronaut_roles/
# operationId: config_astronaut_roles_list
export def "230-config-astronaut-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, role: string, priority: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/astronaut_roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/astronaut_roles/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/astronaut_roles/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/astronaut_roles/{id}/
# operationId: config_astronaut_roles_retrieve
export def "230-config-astronaut-roles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, role: string, priority: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/astronaut_roles/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/astronaut_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/astronaut_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/astronaut_statuses/
# operationId: config_astronaut_statuses_list
export def "230-config-astronaut-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/astronaut_statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/astronaut_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/astronaut_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/astronaut_statuses/{id}/
# operationId: config_astronaut_statuses_retrieve
export def "230-config-astronaut-statuses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/astronaut_statuses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/astronaut_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/astronaut_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/astronaut_types/
# operationId: config_astronaut_types_list
export def "230-config-astronaut-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/astronaut_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/astronaut_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/astronaut_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/astronaut_types/{id}/
# operationId: config_astronaut_types_retrieve
export def "230-config-astronaut-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/astronaut_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/celestial_body_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/celestial_body_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/celestial_body_types/
# operationId: config_celestial_body_types_list
export def "230-config-celestial-body-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/celestial_body_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/celestial_body_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/celestial_body_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/celestial_body_types/{id}/
# operationId: config_celestial_body_types_retrieve
export def "230-config-celestial-body-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/celestial_body_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/countries/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/countries/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/countries/
# operationId: config_countries_list
export def "230-config-countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/countries/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/countries/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/countries/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/countries/{id}/
# operationId: config_countries_retrieve
export def "230-config-countries get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/countries/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/docking_locations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/docking_locations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/docking_locations/
# operationId: config_docking_locations_list
export def "230-config-docking-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, spacestation: record, spacecraft: record, payload: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/docking_locations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/docking_locations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/docking_locations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/docking_locations/{id}/
# operationId: config_docking_locations_retrieve
export def "230-config-docking-locations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, spacestation: record<id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>>, spacecraft: record<response_mode: string, id: int, url: string, name: string, type: record<id: int, name: string>, agency: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, family: list<record>, in_use: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>>, payload: record<response_mode: string, id: int, name: string, type: record<id: int, name: string>, manufacturer: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, operator: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/docking_locations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/event_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/event_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/event_types/
# operationId: config_event_types_list
export def "230-config-event-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/event_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/event_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/event_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/event_types/{id}/
# operationId: config_event_types_retrieve
export def "230-config-event-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/event_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/first_stage_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/first_stage_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/first_stage_types/
# operationId: config_first_stage_types_list
export def "230-config-first-stage-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/first_stage_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/first_stage_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/first_stage_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/first_stage_types/{id}/
# operationId: config_first_stage_types_retrieve
export def "230-config-first-stage-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/first_stage_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/image_licenses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/image_licenses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/image_licenses/
# operationId: config_image_licenses_list
export def "230-config-image-licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, priority: int, link: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/image_licenses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/image_licenses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/image_licenses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/image_licenses/{id}/
# operationId: config_image_licenses_retrieve
export def "230-config-image-licenses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, priority: int, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/image_licenses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/image_variant_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/image_variant_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/image_variant_types/
# operationId: config_image_variant_types_list
export def "230-config-image-variant-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/image_variant_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/image_variant_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/image_variant_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/image_variant_types/{id}/
# operationId: config_image_variant_types_retrieve
export def "230-config-image-variant-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/image_variant_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/infourl_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/infourl_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/infourl_types/
# operationId: config_infourl_types_list
export def "230-config-infourl-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/infourl_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/infourl_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/infourl_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/infourl_types/{id}/
# operationId: config_infourl_types_retrieve
export def "230-config-infourl-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/infourl_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/landing_locations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/landing_locations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/landing_locations/
# operationId: config_landing_locations_list
export def "230-config-landing-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, active: bool, abbrev: string, description: string, location: record, longitude: float, latitude: float, image: record, successful_landings: int, attempted_landings: int, failed_landings: int, celestial_body: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/landing_locations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/landing_locations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/landing_locations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/landing_locations/{id}/
# operationId: config_landing_locations_retrieve
export def "230-config-landing-locations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, active: bool, abbrev: string, description: string, location: record<response_mode: string, id: int, url: string, name: string, active: bool, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, description: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>, longitude: float, latitude: float, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, successful_landings: int, attempted_landings: int, failed_landings: int, celestial_body: record<response_mode: string, id: int, name: string, type: record<id: int, name: string>, diameter: float, mass: float, gravity: float, length_of_day: string, atmosphere: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, description: string, wiki_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/landing_locations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/landing_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/landing_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/landing_types/
# operationId: config_landing_types_list
export def "230-config-landing-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, abbrev: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/landing_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/landing_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/landing_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/landing_types/{id}/
# operationId: config_landing_types_retrieve
export def "230-config-landing-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, abbrev: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/landing_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/languages/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/languages/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/languages/
# operationId: config_languages_list
export def "230-config-languages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/languages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/languages/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/languages/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/languages/{id}/
# operationId: config_languages_retrieve
export def "230-config-languages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, code: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/languages/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/launch_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/launch_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/launch_statuses/
# operationId: config_launch_statuses_list
export def "230-config-launch-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, abbrev: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/launch_statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/launch_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/launch_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/launch_statuses/{id}/
# operationId: config_launch_statuses_retrieve
export def "230-config-launch-statuses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, abbrev: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/launch_statuses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/launcher_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/launcher_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/launcher_statuses/
# operationId: config_launcher_statuses_list
export def "230-config-launcher-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/launcher_statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/launcher_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/launcher_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/launcher_statuses/{id}/
# operationId: config_launcher_statuses_retrieve
export def "230-config-launcher-statuses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/launcher_statuses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/mission_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/mission_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/mission_types/
# operationId: config_mission_types_list
export def "230-config-mission-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/mission_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/mission_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/mission_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/mission_types/{id}/
# operationId: config_mission_types_retrieve
export def "230-config-mission-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/mission_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/net_precisions/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/net_precisions/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/net_precisions/
# operationId: config_net_precisions_list
export def "230-config-net-precisions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, abbrev: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/net_precisions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/net_precisions/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/net_precisions/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/net_precisions/{id}/
# operationId: config_net_precisions_retrieve
export def "230-config-net-precisions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, abbrev: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/net_precisions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/notice_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/notice_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/notice_types/
# operationId: config_notice_types_list
export def "230-config-notice-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/notice_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/notice_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/notice_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/notice_types/{id}/
# operationId: config_notice_types_retrieve
export def "230-config-notice-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/notice_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/orbits/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/orbits/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/orbits/
# operationId: config_orbits_list
export def "230-config-orbits list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, abbrev: string, celestial_body: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/orbits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/orbits/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/orbits/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/orbits/{id}/
# operationId: config_orbits_retrieve
export def "230-config-orbits get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, abbrev: string, celestial_body: record<response_mode: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/orbits/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/payload_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/payload_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/payload_types/
# operationId: config_payload_types_list
export def "230-config-payload-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/payload_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/payload_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/payload_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/payload_types/{id}/
# operationId: config_payload_types_retrieve
export def "230-config-payload-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/payload_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/program_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/program_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/program_types/
# operationId: config_program_types_list
export def "230-config-program-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/program_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/program_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/program_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/program_types/{id}/
# operationId: config_program_types_retrieve
export def "230-config-program-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/program_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/road_closure_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/road_closure_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/road_closure_statuses/
# operationId: config_road_closure_statuses_list
export def "230-config-road-closure-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/road_closure_statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/road_closure_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/road_closure_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/road_closure_statuses/{id}/
# operationId: config_road_closure_statuses_retrieve
export def "230-config-road-closure-statuses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/road_closure_statuses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/space_station_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/space_station_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/space_station_statuses/
# operationId: config_space_station_statuses_list
export def "230-config-space-station-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/space_station_statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/space_station_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/space_station_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/space_station_statuses/{id}/
# operationId: config_space_station_statuses_retrieve
export def "230-config-space-station-statuses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/space_station_statuses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/spacecraft_configuration_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/spacecraft_configuration_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/spacecraft_configuration_types/
# operationId: config_spacecraft_configuration_types_list
export def "230-config-spacecraft-configuration-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/spacecraft_configuration_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/spacecraft_configuration_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/spacecraft_configuration_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/spacecraft_configuration_types/{id}/
# operationId: config_spacecraft_configuration_types_retrieve
export def "230-config-spacecraft-configuration-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/spacecraft_configuration_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/spacecraft_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/spacecraft_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/spacecraft_statuses/
# operationId: config_spacecraft_statuses_list
export def "230-config-spacecraft-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/spacecraft_statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/spacecraft_statuses/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/spacecraft_statuses/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/spacecraft_statuses/{id}/
# operationId: config_spacecraft_statuses_retrieve
export def "230-config-spacecraft-statuses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/spacecraft_statuses/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/timeline_event_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/timeline_event_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/timeline_event_types/
# operationId: config_timeline_event_types_list
export def "230-config-timeline-event-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, abbrev: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/timeline_event_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/timeline_event_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/timeline_event_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/timeline_event_types/{id}/
# operationId: config_timeline_event_types_retrieve
export def "230-config-timeline-event-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, abbrev: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/timeline_event_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/vidurl_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/vidurl_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/vidurl_types/
# operationId: config_vidurl_types_list
export def "230-config-vidurl-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/config/vidurl_types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/config/vidurl_types/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/config/vidurl_types/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/config/vidurl_types/{id}/
# operationId: config_vidurl_types_retrieve
export def "230-config-vidurl-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/config/vidurl_types/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/dashboard/starship/?mode=list](./?mode=list)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/dashboard/starship/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/dashboard/starship/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/dashboard/starship/
# operationId: dashboard_starship_list
export def "230-dashboard-starship list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2.3.0/dashboard/starship/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/docking_events/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `docked`, `docking__gt`, `docking__gte`, `docking__lt`, `docking__lte`, `docking_location__id`, `flight_vehicle_chaser__id`, `space_station_target__id`  Example - [/docking_events/?space_station_target__id=6](./?space_station_target__id=6)  #### Search Fields searched - `docking_location__name`, `flight_vehicle_chaser__spacecraft__name`, `flight_vehicle_target__spacecraft__name`, `payload_flight_chaser__payload__name`, `payload_flight_target__payload__name`, `space_station_chaser__name`, `space_station_target__name`  Example - [/docking_events/?search=Salyut](./?search=Salyut)  #### Ordering Fields - `departure`, `docking`  Example - [/docking_events/?ordering=-docking](./?ordering=-docking)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/docking_events/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/docking_events/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/docking_events/
# operationId: docking_events_list
export def "230-docking-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --docked: oneof<nothing, bool>
  --docking-gt: string # Docking is greater than (format: date-time)
  --docking-gte: string # Docking is greater than or equal to (format: date-time)
  --docking-lt: string # Docking is less than (format: date-time)
  --docking-lte: string # Docking is less than or equal to (format: date-time)
  --docking-location-id: int
  --flight-vehicle-chaser-id: int
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --space-station-target-id: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docked" $docked "scalar") (serialize-qp "docking__gt" $docking_gt "scalar") (serialize-qp "docking__gte" $docking_gte "scalar") (serialize-qp "docking__lt" $docking_lt "scalar") (serialize-qp "docking__lte" $docking_lte "scalar") (serialize-qp "docking_location__id" $docking_location_id "scalar") (serialize-qp "flight_vehicle_chaser__id" $flight_vehicle_chaser_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "space_station_target__id" $space_station_target_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/docking_events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/docking_events/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `docked`, `docking__gt`, `docking__gte`, `docking__lt`, `docking__lte`, `docking_location__id`, `flight_vehicle_chaser__id`, `space_station_target__id`  Example - [/docking_events/?space_station_target__id=6](./?space_station_target__id=6)  #### Search Fields searched - `docking_location__name`, `flight_vehicle_chaser__spacecraft__name`, `flight_vehicle_target__spacecraft__name`, `payload_flight_chaser__payload__name`, `payload_flight_target__payload__name`, `space_station_chaser__name`, `space_station_target__name`  Example - [/docking_events/?search=Salyut](./?search=Salyut)  #### Ordering Fields - `departure`, `docking`  Example - [/docking_events/?ordering=-docking](./?ordering=-docking)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/docking_events/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/docking_events/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/docking_events/{id}/
# operationId: docking_events_retrieve
export def "230-docking-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, docking: string, departure: string, docking_location: record<id: int, name: string, spacestation: record<id: int, url: string, name: string, image: record>, spacecraft: record<response_mode: string, id: int, url: string, name: string, type: record, agency: record, family: list, in_use: bool, image: record>, payload: record<response_mode: string, id: int, name: string, type: record, manufacturer: record, operator: record, image: record>>, space_station_target: record<id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>>, flight_vehicle_target: record<id: int, url: string, destination: string, mission_end: string, spacecraft: record<response_mode: string, id: int, url: string, name: string, serial_number: string, is_placeholder: bool, image: record, in_space: bool, time_in_space: string, time_docked: string, flights_count: int, mission_ends_count: int, status: record, description: string, spacecraft_config: record, fastest_turnaround: string>, launch: record<id: string, url: string, name: string>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record, type: record>, duration: string, turn_around_time: string>, payload_flight_target: record<response_mode: string, id: int, url: string, destination: string, amount: int, payload: record<response_mode: string, id: int, name: string, type: record, manufacturer: record, operator: record, image: record>, launch: record<id: string, url: string, name: string>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record, type: record>>, response_mode: string, flight_vehicle_chaser: record<id: int, url: string, destination: string, mission_end: string, spacecraft: record<response_mode: string, id: int, url: string, name: string, serial_number: string, is_placeholder: bool, image: record, in_space: bool, time_in_space: string, time_docked: string, flights_count: int, mission_ends_count: int, status: record, description: string, spacecraft_config: record, fastest_turnaround: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record, type: record>, duration: string, turn_around_time: string, response_mode: string>, space_station_chaser: record<id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, status: record<id: int, name: string>, founded: string, deorbited: string, description: string, orbit: string, type: record<id: int, name: string>>, payload_flight_chaser: record<response_mode: string, id: int, url: string, destination: string, amount: int, payload: record<response_mode: string, id: int, name: string, type: record, manufacturer: record, operator: record, image: record, wiki_link: string, info_link: string, program: list, cost: int, mass: float, description: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record, type: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/docking_events/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/events/?mode=list](./?mode=list)  #### Filters Parameters - `agency__ids`, `date__gt`, `date__gte`, `date__lt`, `date__lte`, `day`, `expedition__ids`, `id`, `last_updated__gte`, `last_updated__lte`, `launch__ids`, `month`, `program`, `program__ids`, `slug`, `spacestation__ids`, `type`, `type__ids`, `video_url`, `year`  Example - [/events/?type__ids=2,8](./?type__ids=2,8)  #### Search Fields searched - `name`  Example - [/events/?search=Flyby](./?search=Flyby)  #### Ordering Fields - `date`, `last_updated`  Example - [/events/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/events/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/events/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/events/
# operationId: events_list
export def "230-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-ids: list # Comma-separated agency IDs.
  --date-gt: string # Date is greater than (format: date-time)
  --date-gte: string # Date is greater than or equal to (format: date-time)
  --date-lt: string # Date is less than (format: date-time)
  --date-lte: string # Date is less than or equal to (format: date-time)
  --day: list # Multiple values may be separated by commas.
  --expedition-ids: list # Comma-separated expedition IDs.
  --id: list # Multiple values may be separated by commas.
  --last-updated-gte: string # Last Update is greater than or equal to (format: date-time)
  --last-updated-lte: string # Last Update is less than or equal to (format: date-time)
  --launch-ids: list # Comma-separated launch IDs (UUIDs).
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --program: list
  --program-ids: list # Comma-separated program IDs.
  --search: string # A search term.
  --slug: string
  --spacestation-ids: list # Comma-separated space station IDs.
  --type: int
  --type-ids: list # Comma-separated event type IDs.
  --video-url: list # Comma-separated video URLs.
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency__ids" $agency_ids "csv") (serialize-qp "date__gt" $date_gt "scalar") (serialize-qp "date__gte" $date_gte "scalar") (serialize-qp "date__lt" $date_lt "scalar") (serialize-qp "date__lte" $date_lte "scalar") (serialize-qp "day" $day "csv") (serialize-qp "expedition__ids" $expedition_ids "csv") (serialize-qp "id" $id "csv") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "launch__ids" $launch_ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "program" $program "multi") (serialize-qp "program__ids" $program_ids "csv") (serialize-qp "search" $search "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "spacestation__ids" $spacestation_ids "csv") (serialize-qp "type" $type "scalar") (serialize-qp "type__ids" $type_ids "csv") (serialize-qp "video_url" $video_url "csv") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/events/?mode=list](./?mode=list)  #### Filters Parameters - `agency__ids`, `date__gt`, `date__gte`, `date__lt`, `date__lte`, `day`, `expedition__ids`, `id`, `last_updated__gte`, `last_updated__lte`, `launch__ids`, `month`, `program`, `program__ids`, `slug`, `spacestation__ids`, `type`, `type__ids`, `video_url`, `year`  Example - [/events/?type__ids=2,8](./?type__ids=2,8)  #### Search Fields searched - `name`  Example - [/events/?search=Flyby](./?search=Flyby)  #### Ordering Fields - `date`, `last_updated`  Example - [/events/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/events/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/events/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/events/{id}/
# operationId: events_retrieve
export def "230-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, name: string, info_urls: table<priority: int, source: string, title: string, description: string, feature_image: string, url: string, type: record, language: record>, vid_urls: table<priority: int, source: string, publisher: string, title: string, description: string, feature_image: string, url: string, type: record, language: record, start_time: string, end_time: string, live: bool>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, date: string, slug: string, type: record<id: int, name: string>, description: string, webcast_live: bool, location: string, date_precision: record<id: int, name: string, abbrev: string, description: string>, response_mode: string, duration: string, updates: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>, last_updated: string, agencies: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, launches: table<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string>, expeditions: table<id: int, url: string, name: string, start: string, end: string, response_mode: string, spacestation: record, mission_patches: list, spacewalks: list>, spacestations: table<id: int, url: string, name: string, image: record, status: record, founded: string, deorbited: string, description: string, orbit: string, type: record>, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, astronauts: table<id: int, url: string, name: string, status: record, agency: record, image: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/events/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/events/previous/?mode=list](./?mode=list)  #### Filters Parameters - `agency__ids`, `date__gt`, `date__gte`, `date__lt`, `date__lte`, `day`, `expedition__ids`, `id`, `last_updated__gte`, `last_updated__lte`, `launch__ids`, `month`, `program`, `program__ids`, `slug`, `spacestation__ids`, `type`, `type__ids`, `video_url`, `year`  Example - [/events/previous/?type__ids=2,8](./?type__ids=2,8)  #### Search Fields searched - `name`  Example - [/events/previous/?search=Flyby](./?search=Flyby)  #### Ordering Fields - `date`, `last_updated`  Example - [/events/previous/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/events/previous/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/events/previous/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/events/previous/
# operationId: events_previous_list
export def "230-events-previous list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-ids: list # Comma-separated agency IDs.
  --date-gt: string # Date is greater than (format: date-time)
  --date-gte: string # Date is greater than or equal to (format: date-time)
  --date-lt: string # Date is less than (format: date-time)
  --date-lte: string # Date is less than or equal to (format: date-time)
  --day: list # Multiple values may be separated by commas.
  --expedition-ids: list # Comma-separated expedition IDs.
  --id: list # Multiple values may be separated by commas.
  --last-updated-gte: string # Last Update is greater than or equal to (format: date-time)
  --last-updated-lte: string # Last Update is less than or equal to (format: date-time)
  --launch-ids: list # Comma-separated launch IDs (UUIDs).
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --program: list
  --program-ids: list # Comma-separated program IDs.
  --search: string # A search term.
  --slug: string
  --spacestation-ids: list # Comma-separated space station IDs.
  --type: int
  --type-ids: list # Comma-separated event type IDs.
  --video-url: list # Comma-separated video URLs.
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency__ids" $agency_ids "csv") (serialize-qp "date__gt" $date_gt "scalar") (serialize-qp "date__gte" $date_gte "scalar") (serialize-qp "date__lt" $date_lt "scalar") (serialize-qp "date__lte" $date_lte "scalar") (serialize-qp "day" $day "csv") (serialize-qp "expedition__ids" $expedition_ids "csv") (serialize-qp "id" $id "csv") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "launch__ids" $launch_ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "program" $program "multi") (serialize-qp "program__ids" $program_ids "csv") (serialize-qp "search" $search "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "spacestation__ids" $spacestation_ids "csv") (serialize-qp "type" $type "scalar") (serialize-qp "type__ids" $type_ids "csv") (serialize-qp "video_url" $video_url "csv") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/events/previous/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/events/previous/?mode=list](./?mode=list)  #### Filters Parameters - `agency__ids`, `date__gt`, `date__gte`, `date__lt`, `date__lte`, `day`, `expedition__ids`, `id`, `last_updated__gte`, `last_updated__lte`, `launch__ids`, `month`, `program`, `program__ids`, `slug`, `spacestation__ids`, `type`, `type__ids`, `video_url`, `year`  Example - [/events/previous/?type__ids=2,8](./?type__ids=2,8)  #### Search Fields searched - `name`  Example - [/events/previous/?search=Flyby](./?search=Flyby)  #### Ordering Fields - `date`, `last_updated`  Example - [/events/previous/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/events/previous/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/events/previous/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/events/previous/{id}/
# operationId: events_previous_retrieve
export def "230-events-previous get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, name: string, info_urls: table<priority: int, source: string, title: string, description: string, feature_image: string, url: string, type: record, language: record>, vid_urls: table<priority: int, source: string, publisher: string, title: string, description: string, feature_image: string, url: string, type: record, language: record, start_time: string, end_time: string, live: bool>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, date: string, slug: string, type: record<id: int, name: string>, description: string, webcast_live: bool, location: string, date_precision: record<id: int, name: string, abbrev: string, description: string>, response_mode: string, duration: string, updates: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>, last_updated: string, agencies: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, launches: table<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string>, expeditions: table<id: int, url: string, name: string, start: string, end: string, response_mode: string, spacestation: record, mission_patches: list, spacewalks: list>, spacestations: table<id: int, url: string, name: string, image: record, status: record, founded: string, deorbited: string, description: string, orbit: string, type: record>, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, astronauts: table<id: int, url: string, name: string, status: record, agency: record, image: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/events/previous/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/events/upcoming/?mode=list](./?mode=list)  #### Filters Parameters - `agency__ids`, `date__gt`, `date__gte`, `date__lt`, `date__lte`, `day`, `expedition__ids`, `hide_recent_previous`, `id`, `last_updated__gte`, `last_updated__lte`, `launch__ids`, `month`, `program`, `program__ids`, `slug`, `spacestation__ids`, `type`, `type__ids`, `video_url`, `year`  Example - [/events/upcoming/?type__ids=2,8](./?type__ids=2,8)  #### Search Fields searched - `name`  Example - [/events/upcoming/?search=Flyby](./?search=Flyby)  #### Ordering Fields - `date`, `last_updated`  Example - [/events/upcoming/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/events/upcoming/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/events/upcoming/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/events/upcoming/
# operationId: events_upcoming_list
export def "230-events-upcoming list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-ids: list # Comma-separated agency IDs.
  --date-gt: string # Date is greater than (format: date-time)
  --date-gte: string # Date is greater than or equal to (format: date-time)
  --date-lt: string # Date is less than (format: date-time)
  --date-lte: string # Date is less than or equal to (format: date-time)
  --day: list # Multiple values may be separated by commas.
  --expedition-ids: list # Comma-separated expedition IDs.
  --hide-recent-previous: oneof<nothing, bool> # Hide events from the past 24 hours, which are included by default for convenience.
  --id: list # Multiple values may be separated by commas.
  --last-updated-gte: string # Last Update is greater than or equal to (format: date-time)
  --last-updated-lte: string # Last Update is less than or equal to (format: date-time)
  --launch-ids: list # Comma-separated launch IDs (UUIDs).
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --program: list
  --program-ids: list # Comma-separated program IDs.
  --search: string # A search term.
  --slug: string
  --spacestation-ids: list # Comma-separated space station IDs.
  --type: int
  --type-ids: list # Comma-separated event type IDs.
  --video-url: list # Comma-separated video URLs.
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency__ids" $agency_ids "csv") (serialize-qp "date__gt" $date_gt "scalar") (serialize-qp "date__gte" $date_gte "scalar") (serialize-qp "date__lt" $date_lt "scalar") (serialize-qp "date__lte" $date_lte "scalar") (serialize-qp "day" $day "csv") (serialize-qp "expedition__ids" $expedition_ids "csv") (serialize-qp "hide_recent_previous" $hide_recent_previous "scalar") (serialize-qp "id" $id "csv") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "launch__ids" $launch_ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "program" $program "multi") (serialize-qp "program__ids" $program_ids "csv") (serialize-qp "search" $search "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "spacestation__ids" $spacestation_ids "csv") (serialize-qp "type" $type "scalar") (serialize-qp "type__ids" $type_ids "csv") (serialize-qp "video_url" $video_url "csv") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/events/upcoming/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/events/upcoming/?mode=list](./?mode=list)  #### Filters Parameters - `agency__ids`, `date__gt`, `date__gte`, `date__lt`, `date__lte`, `day`, `expedition__ids`, `hide_recent_previous`, `id`, `last_updated__gte`, `last_updated__lte`, `launch__ids`, `month`, `program`, `program__ids`, `slug`, `spacestation__ids`, `type`, `type__ids`, `video_url`, `year`  Example - [/events/upcoming/?type__ids=2,8](./?type__ids=2,8)  #### Search Fields searched - `name`  Example - [/events/upcoming/?search=Flyby](./?search=Flyby)  #### Ordering Fields - `date`, `last_updated`  Example - [/events/upcoming/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/events/upcoming/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/events/upcoming/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/events/upcoming/{id}/
# operationId: events_upcoming_retrieve
export def "230-events-upcoming get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, name: string, info_urls: table<priority: int, source: string, title: string, description: string, feature_image: string, url: string, type: record, language: record>, vid_urls: table<priority: int, source: string, publisher: string, title: string, description: string, feature_image: string, url: string, type: record, language: record, start_time: string, end_time: string, live: bool>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, date: string, slug: string, type: record<id: int, name: string>, description: string, webcast_live: bool, location: string, date_precision: record<id: int, name: string, abbrev: string, description: string>, response_mode: string, duration: string, updates: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>, last_updated: string, agencies: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, launches: table<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string>, expeditions: table<id: int, url: string, name: string, start: string, end: string, response_mode: string, spacestation: record, mission_patches: list, spacewalks: list>, spacestations: table<id: int, url: string, name: string, image: record, status: record, founded: string, deorbited: string, description: string, orbit: string, type: record>, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, astronauts: table<id: int, url: string, name: string, status: record, agency: record, image: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/events/upcoming/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/expeditions/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `crew__astronaut`, `crew__astronaut__agency`, `end__gt`, `end__gte`, `end__lt`, `end__lte`, `is_active`, `name`, `space_station`, `start__gt`, `start__gte`, `start__lt`, `start__lte`  Example - [/expeditions/?space_station=18](./?space_station=18)  #### Search Fields searched - `crew__astronaut__agency__abbrev`, `crew__astronaut__agency__name`, `crew__astronaut__name`, `crew__astronaut__nationality__nationality_name`, `name`  Example - [/expeditions/?search=Kelly](./?search=Kelly)  #### Ordering Fields - `end`, `id`, `start`  Example - [/expeditions/?ordering=-start](./?ordering=-start)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/expeditions/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/expeditions/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/expeditions/
# operationId: expeditions_list
export def "230-expeditions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --crew-astronaut: int
  --crew-astronaut--agency: int
  --end-gt: string # End is greater than (format: date-time)
  --end-gte: string # End is greater than or equal to (format: date-time)
  --end-lt: string # End is less than (format: date-time)
  --end-lte: string # End is greater than or equal to (format: date-time)
  --is-active: oneof<nothing, bool>
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --space-station: int
  --start-gt: string # Start is greater than (format: date-time)
  --start-gte: string # Start is greater than or equal to (format: date-time)
  --start-lt: string # Start is less than (format: date-time)
  --start-lte: string # Start is greater than or equal to (format: date-time)
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "crew__astronaut" $crew_astronaut "scalar") (serialize-qp "crew__astronaut__agency" $crew_astronaut__agency "scalar") (serialize-qp "end__gt" $end_gt "scalar") (serialize-qp "end__gte" $end_gte "scalar") (serialize-qp "end__lt" $end_lt "scalar") (serialize-qp "end__lte" $end_lte "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "space_station" $space_station "scalar") (serialize-qp "start__gt" $start_gt "scalar") (serialize-qp "start__gte" $start_gte "scalar") (serialize-qp "start__lt" $start_lt "scalar") (serialize-qp "start__lte" $start_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/expeditions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/expeditions/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `crew__astronaut`, `crew__astronaut__agency`, `end__gt`, `end__gte`, `end__lt`, `end__lte`, `is_active`, `name`, `space_station`, `start__gt`, `start__gte`, `start__lt`, `start__lte`  Example - [/expeditions/?space_station=18](./?space_station=18)  #### Search Fields searched - `crew__astronaut__agency__abbrev`, `crew__astronaut__agency__name`, `crew__astronaut__name`, `crew__astronaut__nationality__nationality_name`, `name`  Example - [/expeditions/?search=Kelly](./?search=Kelly)  #### Ordering Fields - `end`, `id`, `start`  Example - [/expeditions/?ordering=-start](./?ordering=-start)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/expeditions/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/expeditions/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/expeditions/{id}/
# operationId: expeditions_retrieve
export def "230-expeditions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, name: string, start: string, end: string, response_mode: string, spacestation: record<id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, status: record<id: int, name: string>, founded: string, deorbited: string, description: string, orbit: string, type: record<id: int, name: string>, owners: list<record>>, mission_patches: table<id: int, name: string, priority: int, image_url: string, agency: record, response_mode: string>, spacewalks: table<response_mode: string, id: int, url: string, name: string, start: string, end: string, duration: string, location: string>, crew: table<id: int, role: record, astronaut: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/expeditions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/landings/?mode=list](./?mode=list)  #### Filters Parameters - `attempt`, `firststage_launch__ids`, `landing_location__ids`, `landing_type__ids`, `launcher__ids`, `launcher_config__ids`, `launcher_serial_numbers`, `spacecraft__ids`, `spacecraft_config__ids`, `spacecraft_launch__ids`, `success`  Example - [/landings/?spacecraft__ids=39,37](./?spacecraft__ids=39,37)  #### Search Fields searched - `firststage__launcher__launcher_config__name`, `firststage__launcher__serial_number`, `firststage__rocket__launch__name`, `landing_location__abbrev`, `landing_location__name`, `spacecraftflight__rocket__launch__name`, `spacecraftflight__spacecraft__name`, `spacecraftflight__spacecraft__serial_number`, `spacecraftflight__spacecraft__spacecraft_config__name`  Example - [/landings/?search=B1059](./?search=B1059)  #### Ordering Fields - `downrange_distance`, `id`  Example - [/landings/?ordering=downrange_distance](./?ordering=downrange_distance)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/landings/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/landings/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/landings/
# operationId: landings_list
export def "230-landings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attempt: oneof<nothing, bool>
  --firststage-launch-ids: list # Multiple values may be separated by commas.
  --landing-location-ids: list # Multiple values may be separated by commas.
  --landing-type-ids: list # Multiple values may be separated by commas.
  --launcher-ids: list # Multiple values may be separated by commas.
  --launcher-config-ids: list # Multiple values may be separated by commas.
  --launcher-serial-numbers: list # Multiple values may be separated by commas.
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --spacecraft-ids: list # Multiple values may be separated by commas.
  --spacecraft-config-ids: list # Multiple values may be separated by commas.
  --spacecraft-launch-ids: list # Multiple values may be separated by commas.
  --success: oneof<nothing, bool>
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attempt" $attempt "scalar") (serialize-qp "firststage_launch__ids" $firststage_launch_ids "csv") (serialize-qp "landing_location__ids" $landing_location_ids "csv") (serialize-qp "landing_type__ids" $landing_type_ids "csv") (serialize-qp "launcher__ids" $launcher_ids "csv") (serialize-qp "launcher_config__ids" $launcher_config_ids "csv") (serialize-qp "launcher_serial_numbers" $launcher_serial_numbers "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "spacecraft__ids" $spacecraft_ids "csv") (serialize-qp "spacecraft_config__ids" $spacecraft_config_ids "csv") (serialize-qp "spacecraft_launch__ids" $spacecraft_launch_ids "csv") (serialize-qp "success" $success "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/landings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/landings/?mode=list](./?mode=list)  #### Filters Parameters - `attempt`, `firststage_launch__ids`, `landing_location__ids`, `landing_type__ids`, `launcher__ids`, `launcher_config__ids`, `launcher_serial_numbers`, `spacecraft__ids`, `spacecraft_config__ids`, `spacecraft_launch__ids`, `success`  Example - [/landings/?spacecraft__ids=39,37](./?spacecraft__ids=39,37)  #### Search Fields searched - `firststage__launcher__launcher_config__name`, `firststage__launcher__serial_number`, `firststage__rocket__launch__name`, `landing_location__abbrev`, `landing_location__name`, `spacecraftflight__rocket__launch__name`, `spacecraftflight__spacecraft__name`, `spacecraftflight__spacecraft__serial_number`, `spacecraftflight__spacecraft__spacecraft_config__name`  Example - [/landings/?search=B1059](./?search=B1059)  #### Ordering Fields - `downrange_distance`, `id`  Example - [/landings/?ordering=downrange_distance](./?ordering=downrange_distance)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/landings/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/landings/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/landings/{id}/
# operationId: landings_retrieve
export def "230-landings get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record<id: int, name: string, active: bool, abbrev: string, description: string, location: record<response_mode: string, id: int, url: string, name: string, active: bool, country: record, description: string, image: record, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>, longitude: float, latitude: float, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, successful_landings: int, attempted_landings: int, failed_landings: int, celestial_body: record<response_mode: string, id: int, name: string, type: record, diameter: float, mass: float, gravity: float, length_of_day: string, atmosphere: bool, image: record, description: string, wiki_url: string>>, type: record<id: int, name: string, abbrev: string, description: string>, response_mode: string, firststage: record<id: int, type: string, reused: bool, launcher_flight_number: int, launcher: record<response_mode: string, id: int, url: string, flight_proven: bool, serial_number: string, is_placeholder: bool, status: record, image: record, details: string, successful_landings: int, attempted_landings: int, flights: int, last_launch_date: string, first_launch_date: string, fastest_turnaround: string>, previous_flight_date: string, turn_around_time: string, previous_flight: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>>, spacecraftflight: record<id: int, url: string, destination: string, mission_end: string, spacecraft: record<response_mode: string, id: int, url: string, name: string, serial_number: string, is_placeholder: bool, image: record, in_space: bool, time_in_space: string, time_docked: string, flights_count: int, mission_ends_count: int, status: record, description: string, spacecraft_config: record, fastest_turnaround: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, duration: string, turn_around_time: string, response_mode: string, launch_crew: list<record>, onboard_crew: list<record>, landing_crew: list<record>, docking_events: list<record>>, payloadflight: record<response_mode: string, id: int, url: string, destination: string, amount: int, payload: record<response_mode: string, id: int, name: string, type: record, manufacturer: record, operator: record, image: record, wiki_link: string, info_link: string, program: list, cost: int, mass: float, description: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, docking_events: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/landings/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launcher_configuration_families/?mode=list](./?mode=list)  #### Filters Parameters - `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `consecutive_successful_landings`, `consecutive_successful_landings__gt`, `consecutive_successful_landings__gte`, `consecutive_successful_landings__lt`, `consecutive_successful_landings__lte`, `consecutive_successful_launches`, `consecutive_successful_launches__gt`, `consecutive_successful_launches__gte`, `consecutive_successful_launches__lt`, `consecutive_successful_launches__lte`, `failed_landings`, `failed_landings__gt`, `failed_landings__gte`, `failed_landings__lt`, `failed_landings__lte`, `failed_launches`, `failed_launches__gt`, `failed_launches__gte`, `failed_launches__lt`, `failed_launches__lte`, `maiden_flight`, `maiden_flight__gt`, `maiden_flight__gte`, `maiden_flight__lt`, `maiden_flight__lte`, `manufacturer__abbrev`, `manufacturer__abbrev__contains`, `manufacturer__country_code`, `manufacturer__id`, `manufacturer__id__contains`, `manufacturer__name`, `manufacturer__name__contains`, `name`, `name__contains`, `pending_launches`, `pending_launches__gt`, `pending_launches__gte`, `pending_launches__lt`, `pending_launches__lte`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`, `successful_launches`, `successful_launches__gt`, `successful_launches__gte`, `successful_launches__lt`, `successful_launches__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/launcher_configuration_families/?manufacturer__name=SpaceX](./?manufacturer__name=SpaceX)  #### Search Fields searched - `manufacturer__abbrev`, `manufacturer__name`, `name`  Example - [/launcher_configuration_families/?search=Ariane](./?search=Ariane)  #### Ordering Fields - `attempted_landings`, `consecutive_successful_landings`, `consecutive_successful_launches`, `failed_landings`, `failed_launches`, `name`, `pending_launches`, `successful_landings`, `successful_launches`, `total_launch_count`  Example - [/launcher_configuration_families/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launcher_configuration_families/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launcher_configuration_families/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launcher_configuration_families/
# operationId: launcher_configuration_families_list
export def "230-launcher-configuration-families list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attempted-landings: int
  --attempted-landings-gt: int
  --attempted-landings-gte: int
  --attempted-landings-lt: int
  --attempted-landings-lte: int
  --consecutive-successful-landings: int
  --consecutive-successful-landings-gt: int
  --consecutive-successful-landings-gte: int
  --consecutive-successful-landings-lt: int
  --consecutive-successful-landings-lte: int
  --consecutive-successful-launches: int
  --consecutive-successful-launches-gt: int
  --consecutive-successful-launches-gte: int
  --consecutive-successful-launches-lt: int
  --consecutive-successful-launches-lte: int
  --failed-landings: int
  --failed-landings-gt: int
  --failed-landings-gte: int
  --failed-landings-lt: int
  --failed-landings-lte: int
  --failed-launches: int
  --failed-launches-gt: int
  --failed-launches-gte: int
  --failed-launches-lt: int
  --failed-launches-lte: int
  --limit: int # Number of results to return per page.
  --maiden-flight: string # format: date
  --maiden-flight-gt: string # format: date
  --maiden-flight-gte: string # format: date
  --maiden-flight-lt: string # format: date
  --maiden-flight-lte: string # format: date
  --manufacturer-abbrev: string
  --manufacturer-abbrev--contains: string
  --manufacturer-country-code: string
  --manufacturer-id: int
  --manufacturer-id--contains: int
  --manufacturer-name: string
  --manufacturer-name--contains: string
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --pending-launches: int
  --pending-launches-gt: int
  --pending-launches-gte: int
  --pending-launches-lt: int
  --pending-launches-lte: int
  --search: string # A search term.
  --successful-landings: int
  --successful-landings-gt: int
  --successful-landings-gte: int
  --successful-landings-lt: int
  --successful-landings-lte: int
  --successful-launches: int
  --successful-launches-gt: int
  --successful-launches-gte: int
  --successful-launches-lt: int
  --successful-launches-lte: int
  --total-launch-count: int
  --total-launch-count-gt: int
  --total-launch-count-gte: int
  --total-launch-count-lt: int
  --total-launch-count-lte: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attempted_landings" $attempted_landings "scalar") (serialize-qp "attempted_landings__gt" $attempted_landings_gt "scalar") (serialize-qp "attempted_landings__gte" $attempted_landings_gte "scalar") (serialize-qp "attempted_landings__lt" $attempted_landings_lt "scalar") (serialize-qp "attempted_landings__lte" $attempted_landings_lte "scalar") (serialize-qp "consecutive_successful_landings" $consecutive_successful_landings "scalar") (serialize-qp "consecutive_successful_landings__gt" $consecutive_successful_landings_gt "scalar") (serialize-qp "consecutive_successful_landings__gte" $consecutive_successful_landings_gte "scalar") (serialize-qp "consecutive_successful_landings__lt" $consecutive_successful_landings_lt "scalar") (serialize-qp "consecutive_successful_landings__lte" $consecutive_successful_landings_lte "scalar") (serialize-qp "consecutive_successful_launches" $consecutive_successful_launches "scalar") (serialize-qp "consecutive_successful_launches__gt" $consecutive_successful_launches_gt "scalar") (serialize-qp "consecutive_successful_launches__gte" $consecutive_successful_launches_gte "scalar") (serialize-qp "consecutive_successful_launches__lt" $consecutive_successful_launches_lt "scalar") (serialize-qp "consecutive_successful_launches__lte" $consecutive_successful_launches_lte "scalar") (serialize-qp "failed_landings" $failed_landings "scalar") (serialize-qp "failed_landings__gt" $failed_landings_gt "scalar") (serialize-qp "failed_landings__gte" $failed_landings_gte "scalar") (serialize-qp "failed_landings__lt" $failed_landings_lt "scalar") (serialize-qp "failed_landings__lte" $failed_landings_lte "scalar") (serialize-qp "failed_launches" $failed_launches "scalar") (serialize-qp "failed_launches__gt" $failed_launches_gt "scalar") (serialize-qp "failed_launches__gte" $failed_launches_gte "scalar") (serialize-qp "failed_launches__lt" $failed_launches_lt "scalar") (serialize-qp "failed_launches__lte" $failed_launches_lte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "maiden_flight" $maiden_flight "scalar") (serialize-qp "maiden_flight__gt" $maiden_flight_gt "scalar") (serialize-qp "maiden_flight__gte" $maiden_flight_gte "scalar") (serialize-qp "maiden_flight__lt" $maiden_flight_lt "scalar") (serialize-qp "maiden_flight__lte" $maiden_flight_lte "scalar") (serialize-qp "manufacturer__abbrev" $manufacturer_abbrev "scalar") (serialize-qp "manufacturer__abbrev__contains" $manufacturer_abbrev__contains "scalar") (serialize-qp "manufacturer__country_code" $manufacturer_country_code "scalar") (serialize-qp "manufacturer__id" $manufacturer_id "scalar") (serialize-qp "manufacturer__id__contains" $manufacturer_id__contains "scalar") (serialize-qp "manufacturer__name" $manufacturer_name "scalar") (serialize-qp "manufacturer__name__contains" $manufacturer_name__contains "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "pending_launches" $pending_launches "scalar") (serialize-qp "pending_launches__gt" $pending_launches_gt "scalar") (serialize-qp "pending_launches__gte" $pending_launches_gte "scalar") (serialize-qp "pending_launches__lt" $pending_launches_lt "scalar") (serialize-qp "pending_launches__lte" $pending_launches_lte "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "successful_landings" $successful_landings "scalar") (serialize-qp "successful_landings__gt" $successful_landings_gt "scalar") (serialize-qp "successful_landings__gte" $successful_landings_gte "scalar") (serialize-qp "successful_landings__lt" $successful_landings_lt "scalar") (serialize-qp "successful_landings__lte" $successful_landings_lte "scalar") (serialize-qp "successful_launches" $successful_launches "scalar") (serialize-qp "successful_launches__gt" $successful_launches_gt "scalar") (serialize-qp "successful_launches__gte" $successful_launches_gte "scalar") (serialize-qp "successful_launches__lt" $successful_launches_lt "scalar") (serialize-qp "successful_launches__lte" $successful_launches_lte "scalar") (serialize-qp "total_launch_count" $total_launch_count "scalar") (serialize-qp "total_launch_count__gt" $total_launch_count_gt "scalar") (serialize-qp "total_launch_count__gte" $total_launch_count_gte "scalar") (serialize-qp "total_launch_count__lt" $total_launch_count_lt "scalar") (serialize-qp "total_launch_count__lte" $total_launch_count_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/launcher_configuration_families/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launcher_configuration_families/?mode=list](./?mode=list)  #### Filters Parameters - `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `consecutive_successful_landings`, `consecutive_successful_landings__gt`, `consecutive_successful_landings__gte`, `consecutive_successful_landings__lt`, `consecutive_successful_landings__lte`, `consecutive_successful_launches`, `consecutive_successful_launches__gt`, `consecutive_successful_launches__gte`, `consecutive_successful_launches__lt`, `consecutive_successful_launches__lte`, `failed_landings`, `failed_landings__gt`, `failed_landings__gte`, `failed_landings__lt`, `failed_landings__lte`, `failed_launches`, `failed_launches__gt`, `failed_launches__gte`, `failed_launches__lt`, `failed_launches__lte`, `maiden_flight`, `maiden_flight__gt`, `maiden_flight__gte`, `maiden_flight__lt`, `maiden_flight__lte`, `manufacturer__abbrev`, `manufacturer__abbrev__contains`, `manufacturer__country_code`, `manufacturer__id`, `manufacturer__id__contains`, `manufacturer__name`, `manufacturer__name__contains`, `name`, `name__contains`, `pending_launches`, `pending_launches__gt`, `pending_launches__gte`, `pending_launches__lt`, `pending_launches__lte`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`, `successful_launches`, `successful_launches__gt`, `successful_launches__gte`, `successful_launches__lt`, `successful_launches__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/launcher_configuration_families/?manufacturer__name=SpaceX](./?manufacturer__name=SpaceX)  #### Search Fields searched - `manufacturer__abbrev`, `manufacturer__name`, `name`  Example - [/launcher_configuration_families/?search=Ariane](./?search=Ariane)  #### Ordering Fields - `attempted_landings`, `consecutive_successful_landings`, `consecutive_successful_launches`, `failed_landings`, `failed_launches`, `name`, `pending_launches`, `successful_landings`, `successful_launches`, `total_launch_count`  Example - [/launcher_configuration_families/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launcher_configuration_families/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launcher_configuration_families/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launcher_configuration_families/{id}/
# operationId: launcher_configuration_families_retrieve
export def "230-launcher-configuration-families get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, name: string, manufacturer: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record, featured: bool, country: list, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record, logo: record, social_logo: record, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list>, parent: record<response_mode: string, id: int, name: string, manufacturer: list<record>, parent: record<response_mode: string, id: int, name: string>>, description: string, active: bool, maiden_flight: string, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/launcher_configuration_families/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launcher_configurations/?mode=list](./?mode=list)  #### Filters Parameters - `active`, `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `consecutive_successful_landings`, `consecutive_successful_landings__gt`, `consecutive_successful_landings__gte`, `consecutive_successful_landings__lt`, `consecutive_successful_landings__lte`, `consecutive_successful_launches`, `consecutive_successful_launches__gt`, `consecutive_successful_launches__gte`, `consecutive_successful_launches__lt`, `consecutive_successful_launches__lte`, `failed_landings`, `failed_landings__gt`, `failed_landings__gte`, `failed_landings__lt`, `failed_landings__lte`, `failed_launches`, `failed_launches__gt`, `failed_launches__gte`, `failed_launches__lt`, `failed_launches__lte`, `families`, `families__contains`, `full_name`, `full_name__contains`, `is_placeholder`, `maiden_flight`, `maiden_flight__gt`, `maiden_flight__gte`, `maiden_flight__lt`, `maiden_flight__lte`, `manufacturer__name`, `manufacturer__name__contains`, `name`, `name__contains`, `pending_launches`, `pending_launches__gt`, `pending_launches__gte`, `pending_launches__lt`, `pending_launches__lte`, `program`, `program__contains`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`, `successful_launches`, `successful_launches__gt`, `successful_launches__gte`, `successful_launches__lt`, `successful_launches__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/launcher_configurations/?manufacturer__name=SpaceX](./?manufacturer__name=SpaceX)  #### Search Fields searched - `full_name`, `manufacturer__abbrev`, `manufacturer__name`, `name`  Example - [/launcher_configurations/?search=Soyuz](./?search=Soyuz)  #### Ordering Fields - `attempted_landings`, `consecutive_successful_landings`, `consecutive_successful_launches`, `failed_landings`, `failed_launches`, `gto_capacity`, `launch_cost`, `launch_mass`, `leo_capacity`, `maiden_flight`, `name`, `pending_launches`, `successful_landings`, `successful_launches`, `total_launch_count`  Example - [/launcher_configurations/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launcher_configurations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launcher_configurations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launcher_configurations/
# operationId: launcher_configurations_list
export def "230-launcher-configurations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool>
  --attempted-landings: int
  --attempted-landings-gt: int
  --attempted-landings-gte: int
  --attempted-landings-lt: int
  --attempted-landings-lte: int
  --consecutive-successful-landings: int
  --consecutive-successful-landings-gt: int
  --consecutive-successful-landings-gte: int
  --consecutive-successful-landings-lt: int
  --consecutive-successful-landings-lte: int
  --consecutive-successful-launches: int
  --consecutive-successful-launches-gt: int
  --consecutive-successful-launches-gte: int
  --consecutive-successful-launches-lt: int
  --consecutive-successful-launches-lte: int
  --failed-landings: int
  --failed-landings-gt: int
  --failed-landings-gte: int
  --failed-landings-lt: int
  --failed-landings-lte: int
  --failed-launches: int
  --failed-launches-gt: int
  --failed-launches-gte: int
  --failed-launches-lt: int
  --failed-launches-lte: int
  --families: list
  --families-contains: list
  --full-name: string
  --full-name-contains: string
  --is-placeholder: oneof<nothing, bool>
  --limit: int # Number of results to return per page.
  --maiden-flight: string # format: date
  --maiden-flight-gt: string # format: date
  --maiden-flight-gte: string # format: date
  --maiden-flight-lt: string # format: date
  --maiden-flight-lte: string # format: date
  --manufacturer-name: string
  --manufacturer-name--contains: string
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --pending-launches: int
  --pending-launches-gt: int
  --pending-launches-gte: int
  --pending-launches-lt: int
  --pending-launches-lte: int
  --program: list
  --program-contains: list
  --search: string # A search term.
  --successful-landings: int
  --successful-landings-gt: int
  --successful-landings-gte: int
  --successful-landings-lt: int
  --successful-landings-lte: int
  --successful-launches: int
  --successful-launches-gt: int
  --successful-launches-gte: int
  --successful-launches-lt: int
  --successful-launches-lte: int
  --total-launch-count: int
  --total-launch-count-gt: int
  --total-launch-count-gte: int
  --total-launch-count-lt: int
  --total-launch-count-lte: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "attempted_landings" $attempted_landings "scalar") (serialize-qp "attempted_landings__gt" $attempted_landings_gt "scalar") (serialize-qp "attempted_landings__gte" $attempted_landings_gte "scalar") (serialize-qp "attempted_landings__lt" $attempted_landings_lt "scalar") (serialize-qp "attempted_landings__lte" $attempted_landings_lte "scalar") (serialize-qp "consecutive_successful_landings" $consecutive_successful_landings "scalar") (serialize-qp "consecutive_successful_landings__gt" $consecutive_successful_landings_gt "scalar") (serialize-qp "consecutive_successful_landings__gte" $consecutive_successful_landings_gte "scalar") (serialize-qp "consecutive_successful_landings__lt" $consecutive_successful_landings_lt "scalar") (serialize-qp "consecutive_successful_landings__lte" $consecutive_successful_landings_lte "scalar") (serialize-qp "consecutive_successful_launches" $consecutive_successful_launches "scalar") (serialize-qp "consecutive_successful_launches__gt" $consecutive_successful_launches_gt "scalar") (serialize-qp "consecutive_successful_launches__gte" $consecutive_successful_launches_gte "scalar") (serialize-qp "consecutive_successful_launches__lt" $consecutive_successful_launches_lt "scalar") (serialize-qp "consecutive_successful_launches__lte" $consecutive_successful_launches_lte "scalar") (serialize-qp "failed_landings" $failed_landings "scalar") (serialize-qp "failed_landings__gt" $failed_landings_gt "scalar") (serialize-qp "failed_landings__gte" $failed_landings_gte "scalar") (serialize-qp "failed_landings__lt" $failed_landings_lt "scalar") (serialize-qp "failed_landings__lte" $failed_landings_lte "scalar") (serialize-qp "failed_launches" $failed_launches "scalar") (serialize-qp "failed_launches__gt" $failed_launches_gt "scalar") (serialize-qp "failed_launches__gte" $failed_launches_gte "scalar") (serialize-qp "failed_launches__lt" $failed_launches_lt "scalar") (serialize-qp "failed_launches__lte" $failed_launches_lte "scalar") (serialize-qp "families" $families "multi") (serialize-qp "families__contains" $families_contains "multi") (serialize-qp "full_name" $full_name "scalar") (serialize-qp "full_name__contains" $full_name_contains "scalar") (serialize-qp "is_placeholder" $is_placeholder "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "maiden_flight" $maiden_flight "scalar") (serialize-qp "maiden_flight__gt" $maiden_flight_gt "scalar") (serialize-qp "maiden_flight__gte" $maiden_flight_gte "scalar") (serialize-qp "maiden_flight__lt" $maiden_flight_lt "scalar") (serialize-qp "maiden_flight__lte" $maiden_flight_lte "scalar") (serialize-qp "manufacturer__name" $manufacturer_name "scalar") (serialize-qp "manufacturer__name__contains" $manufacturer_name__contains "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "pending_launches" $pending_launches "scalar") (serialize-qp "pending_launches__gt" $pending_launches_gt "scalar") (serialize-qp "pending_launches__gte" $pending_launches_gte "scalar") (serialize-qp "pending_launches__lt" $pending_launches_lt "scalar") (serialize-qp "pending_launches__lte" $pending_launches_lte "scalar") (serialize-qp "program" $program "multi") (serialize-qp "program__contains" $program_contains "multi") (serialize-qp "search" $search "scalar") (serialize-qp "successful_landings" $successful_landings "scalar") (serialize-qp "successful_landings__gt" $successful_landings_gt "scalar") (serialize-qp "successful_landings__gte" $successful_landings_gte "scalar") (serialize-qp "successful_landings__lt" $successful_landings_lt "scalar") (serialize-qp "successful_landings__lte" $successful_landings_lte "scalar") (serialize-qp "successful_launches" $successful_launches "scalar") (serialize-qp "successful_launches__gt" $successful_launches_gt "scalar") (serialize-qp "successful_launches__gte" $successful_launches_gte "scalar") (serialize-qp "successful_launches__lt" $successful_launches_lt "scalar") (serialize-qp "successful_launches__lte" $successful_launches_lte "scalar") (serialize-qp "total_launch_count" $total_launch_count "scalar") (serialize-qp "total_launch_count__gt" $total_launch_count_gt "scalar") (serialize-qp "total_launch_count__gte" $total_launch_count_gte "scalar") (serialize-qp "total_launch_count__lt" $total_launch_count_lt "scalar") (serialize-qp "total_launch_count__lte" $total_launch_count_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/launcher_configurations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launcher_configurations/?mode=list](./?mode=list)  #### Filters Parameters - `active`, `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `consecutive_successful_landings`, `consecutive_successful_landings__gt`, `consecutive_successful_landings__gte`, `consecutive_successful_landings__lt`, `consecutive_successful_landings__lte`, `consecutive_successful_launches`, `consecutive_successful_launches__gt`, `consecutive_successful_launches__gte`, `consecutive_successful_launches__lt`, `consecutive_successful_launches__lte`, `failed_landings`, `failed_landings__gt`, `failed_landings__gte`, `failed_landings__lt`, `failed_landings__lte`, `failed_launches`, `failed_launches__gt`, `failed_launches__gte`, `failed_launches__lt`, `failed_launches__lte`, `families`, `families__contains`, `full_name`, `full_name__contains`, `is_placeholder`, `maiden_flight`, `maiden_flight__gt`, `maiden_flight__gte`, `maiden_flight__lt`, `maiden_flight__lte`, `manufacturer__name`, `manufacturer__name__contains`, `name`, `name__contains`, `pending_launches`, `pending_launches__gt`, `pending_launches__gte`, `pending_launches__lt`, `pending_launches__lte`, `program`, `program__contains`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`, `successful_launches`, `successful_launches__gt`, `successful_launches__gte`, `successful_launches__lt`, `successful_launches__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/launcher_configurations/?manufacturer__name=SpaceX](./?manufacturer__name=SpaceX)  #### Search Fields searched - `full_name`, `manufacturer__abbrev`, `manufacturer__name`, `name`  Example - [/launcher_configurations/?search=Soyuz](./?search=Soyuz)  #### Ordering Fields - `attempted_landings`, `consecutive_successful_landings`, `consecutive_successful_launches`, `failed_landings`, `failed_launches`, `gto_capacity`, `launch_cost`, `launch_mass`, `leo_capacity`, `maiden_flight`, `name`, `pending_launches`, `successful_landings`, `successful_launches`, `total_launch_count`  Example - [/launcher_configurations/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launcher_configurations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launcher_configurations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launcher_configurations/{id}/
# operationId: launcher_configurations_retrieve
export def "230-launcher-configurations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, families: table<response_mode: string, id: int, name: string, manufacturer: list, parent: record, description: string, active: bool, maiden_flight: string, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int>, full_name: string, variant: string, active: bool, is_placeholder: bool, manufacturer: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, reusable: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, info_url: string, wiki_url: string, description: string, alias: string, min_stage: int, max_stage: int, length: float, diameter: float, maiden_flight: string, launch_cost: int, launch_mass: float, leo_capacity: float, gto_capacity: float, geo_capacity: float, sso_capacity: float, to_thrust: float, apogee: float, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int, fastest_turnaround: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/launcher_configurations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launchers/?mode=list](./?mode=list)  #### Filters Parameters - `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `first_launch_date`, `flight_proven`, `flights`, `flights__gt`, `flights__gte`, `flights__lt`, `flights__lte`, `id`, `id__contains`, `is_placeholder`, `last_launch_date`, `launcher_config__ids`, `launcher_config__manufacturer__name`, `launcher_config__manufacturer__name__contains`, `serial_number`, `serial_number__contains`, `status`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`  Example - [/launchers/?is_placeholder=True](./?is_placeholder=True)  #### Search Fields searched - `serial_number`, `status__name`  Example - [/launchers/?search=B1048](./?search=B1048)  #### Ordering Fields - `attempted_landings`, `flight_proven`, `flights`, `id`, `successful_landings`  Example - [/launchers/?ordering=-flights](./?ordering=-flights)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launchers/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launchers/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launchers/
# operationId: launchers_list
export def "230-launchers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attempted-landings: int
  --attempted-landings-gt: int
  --attempted-landings-gte: int
  --attempted-landings-lt: int
  --attempted-landings-lte: int
  --first-launch-date: string # format: date-time
  --flight-proven: oneof<nothing, bool>
  --flights: int
  --flights-gt: int
  --flights-gte: int
  --flights-lt: int
  --flights-lte: int
  --id: int
  --id-contains: int
  --is-placeholder: oneof<nothing, bool>
  --last-launch-date: string # format: date-time
  --launcher-config-ids: list # Comma-separated launcher config IDs.
  --launcher-config-manufacturer--name: string
  --launcher-config-manufacturer--name--contains: string
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --serial-number: string
  --serial-number-contains: string
  --status: int
  --successful-landings: int
  --successful-landings-gt: int
  --successful-landings-gte: int
  --successful-landings-lt: int
  --successful-landings-lte: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attempted_landings" $attempted_landings "scalar") (serialize-qp "attempted_landings__gt" $attempted_landings_gt "scalar") (serialize-qp "attempted_landings__gte" $attempted_landings_gte "scalar") (serialize-qp "attempted_landings__lt" $attempted_landings_lt "scalar") (serialize-qp "attempted_landings__lte" $attempted_landings_lte "scalar") (serialize-qp "first_launch_date" $first_launch_date "scalar") (serialize-qp "flight_proven" $flight_proven "scalar") (serialize-qp "flights" $flights "scalar") (serialize-qp "flights__gt" $flights_gt "scalar") (serialize-qp "flights__gte" $flights_gte "scalar") (serialize-qp "flights__lt" $flights_lt "scalar") (serialize-qp "flights__lte" $flights_lte "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "id__contains" $id_contains "scalar") (serialize-qp "is_placeholder" $is_placeholder "scalar") (serialize-qp "last_launch_date" $last_launch_date "scalar") (serialize-qp "launcher_config__ids" $launcher_config_ids "csv") (serialize-qp "launcher_config__manufacturer__name" $launcher_config_manufacturer__name "scalar") (serialize-qp "launcher_config__manufacturer__name__contains" $launcher_config_manufacturer__name__contains "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "serial_number" $serial_number "scalar") (serialize-qp "serial_number__contains" $serial_number_contains "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "successful_landings" $successful_landings "scalar") (serialize-qp "successful_landings__gt" $successful_landings_gt "scalar") (serialize-qp "successful_landings__gte" $successful_landings_gte "scalar") (serialize-qp "successful_landings__lt" $successful_landings_lt "scalar") (serialize-qp "successful_landings__lte" $successful_landings_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/launchers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launchers/?mode=list](./?mode=list)  #### Filters Parameters - `attempted_landings`, `attempted_landings__gt`, `attempted_landings__gte`, `attempted_landings__lt`, `attempted_landings__lte`, `first_launch_date`, `flight_proven`, `flights`, `flights__gt`, `flights__gte`, `flights__lt`, `flights__lte`, `id`, `id__contains`, `is_placeholder`, `last_launch_date`, `launcher_config__ids`, `launcher_config__manufacturer__name`, `launcher_config__manufacturer__name__contains`, `serial_number`, `serial_number__contains`, `status`, `successful_landings`, `successful_landings__gt`, `successful_landings__gte`, `successful_landings__lt`, `successful_landings__lte`  Example - [/launchers/?is_placeholder=True](./?is_placeholder=True)  #### Search Fields searched - `serial_number`, `status__name`  Example - [/launchers/?search=B1048](./?search=B1048)  #### Ordering Fields - `attempted_landings`, `flight_proven`, `flights`, `id`, `successful_landings`  Example - [/launchers/?ordering=-flights](./?ordering=-flights)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launchers/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launchers/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launchers/{id}/
# operationId: launchers_retrieve
export def "230-launchers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, flight_proven: bool, serial_number: string, is_placeholder: bool, status: record<id: int, name: string>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, details: string, successful_landings: int, attempted_landings: int, flights: int, last_launch_date: string, first_launch_date: string, fastest_turnaround: string, launcher_config: record<response_mode: string, id: int, url: string, name: string, families: list<record>, full_name: string, variant: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/launchers/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launches/?mode=list](./?mode=list)  #### Filters Parameters - `agency_launch_attempt_count`, `agency_launch_attempt_count__gt`, `agency_launch_attempt_count__gte`, `agency_launch_attempt_count__lt`, `agency_launch_attempt_count__lte`, `agency_launch_attempt_count_year`, `agency_launch_attempt_count_year__gt`, `agency_launch_attempt_count_year__gte`, `agency_launch_attempt_count_year__lt`, `agency_launch_attempt_count_year__lte`, `day`, `id`, `include_suborbital`, `is_crewed`, `last_updated__gte`, `last_updated__lte`, `launch_designator`, `launcher_config__id`, `location__ids`, `location_launch_attempt_count`, `location_launch_attempt_count__gt`, `location_launch_attempt_count__gte`, `location_launch_attempt_count__lt`, `location_launch_attempt_count__lte`, `location_launch_attempt_count_year`, `location_launch_attempt_count_year__gt`, `location_launch_attempt_count_year__gte`, `location_launch_attempt_count_year__lt`, `location_launch_attempt_count_year__lte`, `lsp__id`, `lsp__name`, `mission__agency__ids`, `mission__orbit__celestial_body__id`, `mission__orbit__name`, `mission__orbit__name__icontains`, `month`, `name`, `net__gt`, `net__gte`, `net__lt`, `net__lte`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `orbital_launch_attempt_count_year`, `orbital_launch_attempt_count_year__gt`, `orbital_launch_attempt_count_year__gte`, `orbital_launch_attempt_count_year__lt`, `orbital_launch_attempt_count_year__lte`, `pad`, `pad__location`, `pad__location__celestial_body__id`, `pad_launch_attempt_count`, `pad_launch_attempt_count__gt`, `pad_launch_attempt_count__gte`, `pad_launch_attempt_count__lt`, `pad_launch_attempt_count__lte`, `pad_launch_attempt_count_year`, `pad_launch_attempt_count_year__gt`, `pad_launch_attempt_count_year__gte`, `pad_launch_attempt_count_year__lt`, `pad_launch_attempt_count_year__lte`, `program`, `related_lsp__id`, `related_lsp__name`, `rocket__configuration__full_name`, `rocket__configuration__full_name__icontains`, `rocket__configuration__id`, `rocket__configuration__manufacturer__name`, `rocket__configuration__manufacturer__name__icontains`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__id`, `rocket__spacecraftflight__spacecraft__name`, `rocket__spacecraftflight__spacecraft__name__icontains`, `serial_number`, `slug`, `spacecraft_config__ids`, `status`, `status__ids`, `video_url`, `window_end__gt`, `window_end__gte`, `window_end__lt`, `window_end__lte`, `window_start__gt`, `window_start__gte`, `window_start__lt`, `window_start__lte`, `year`  Example - [/launches/?pad__location=13](./?pad__location=13)  #### Search Fields searched - `launch_designator`, `launch_service_provider__name`, `mission__name`, `name`, `pad__location__name`, `pad__name`, `rocket__configuration__manufacturer__abbrev`, `rocket__configuration__manufacturer__name`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__name`  Example - [/launches/?search=Starlink](./?search=Starlink)  #### Ordering Fields - `id`, `last_updated`, `name`, `net`  Example - [/launches/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launches/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launches/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launches/
# operationId: launches_list
export def "230-launches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-launch-attempt-count: int
  --agency-launch-attempt-count-gt: int
  --agency-launch-attempt-count-gte: int
  --agency-launch-attempt-count-lt: int
  --agency-launch-attempt-count-lte: int
  --agency-launch-attempt-count-year: int
  --agency-launch-attempt-count-year-gt: int
  --agency-launch-attempt-count-year-gte: int
  --agency-launch-attempt-count-year-lt: int
  --agency-launch-attempt-count-year-lte: int
  --day: list # Multiple values may be separated by commas.
  --id: list # Multiple values may be separated by commas.
  --include-suborbital: oneof<nothing, bool>
  --is-crewed: oneof<nothing, bool>
  --last-updated-gte: string # Last Update is greater than or equal to (format: date-time)
  --last-updated-lte: string # Last Update is less than or equal to (format: date-time)
  --launch-designator: list # Comma-separated (COSPAR) international launch designators.
  --launcher-config-id: list # Multiple values may be separated by commas.
  --limit: int # Number of results to return per page.
  --location-ids: list # Comma-separated location IDs.
  --location-launch-attempt-count: int
  --location-launch-attempt-count-gt: int
  --location-launch-attempt-count-gte: int
  --location-launch-attempt-count-lt: int
  --location-launch-attempt-count-lte: int
  --location-launch-attempt-count-year: int
  --location-launch-attempt-count-year-gt: int
  --location-launch-attempt-count-year-gte: int
  --location-launch-attempt-count-year-lt: int
  --location-launch-attempt-count-year-lte: int
  --lsp-id: list # Comma-separated launch service provider (agency) IDs.
  --lsp-name: list # Comma-separated launch service provider names.
  --mission-agency--ids: list # Comma-separated mission agency IDs.
  --mission-orbit--celestial-body--id: int
  --mission-orbit--name: string
  --mission-orbit--name--icontains: string
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --name: string
  --net-gt: string # NET is greater than (format: date-time)
  --net-gte: string # NET is greater than or equal to (format: date-time)
  --net-lt: string # NET is less than (format: date-time)
  --net-lte: string # NET is less than or equal to (format: date-time)
  --offset: int # The initial index from which to return the results.
  --orbital-launch-attempt-count: int
  --orbital-launch-attempt-count-gt: int
  --orbital-launch-attempt-count-gte: int
  --orbital-launch-attempt-count-lt: int
  --orbital-launch-attempt-count-lte: int
  --orbital-launch-attempt-count-year: int
  --orbital-launch-attempt-count-year-gt: int
  --orbital-launch-attempt-count-year-gte: int
  --orbital-launch-attempt-count-year-lt: int
  --orbital-launch-attempt-count-year-lte: int
  --ordering: string # Which field to use when ordering the results.
  --pad: int
  --pad-location: int
  --pad-location--celestial-body--id: int
  --pad-launch-attempt-count: int
  --pad-launch-attempt-count-gt: int
  --pad-launch-attempt-count-gte: int
  --pad-launch-attempt-count-lt: int
  --pad-launch-attempt-count-lte: int
  --pad-launch-attempt-count-year: int
  --pad-launch-attempt-count-year-gt: int
  --pad-launch-attempt-count-year-gte: int
  --pad-launch-attempt-count-year-lt: int
  --pad-launch-attempt-count-year-lte: int
  --program: list
  --related-lsp-id: list # Comma-separated agency IDs related to the launch service provider.
  --related-lsp-name: list # Comma-separated agency names related to the launch service provider.
  --rocket-configuration--full-name: string
  --rocket-configuration--full-name--icontains: string
  --rocket-configuration--id: int
  --rocket-configuration--manufacturer--name: string
  --rocket-configuration--manufacturer--name--icontains: string
  --rocket-configuration--name: string
  --rocket-spacecraftflight--spacecraft--id: int
  --rocket-spacecraftflight--spacecraft--name: string
  --rocket-spacecraftflight--spacecraft--name--icontains: string
  --search: string # A search term.
  --serial-number: list # Comma-separated first stage booster serial numbers.
  --slug: string
  --spacecraft-config-ids: list # Multiple values may be separated by commas.
  --status: int
  --status-ids: list # Multiple values may be separated by commas.
  --video-url: list # Comma-separated video URLs.
  --window-end-gt: string # Window End is greater than (format: date-time)
  --window-end-gte: string # Window End is greater than or equal to (format: date-time)
  --window-end-lt: string # Window End is less than (format: date-time)
  --window-end-lte: string # Window End is less than or equal to (format: date-time)
  --window-start-gt: string # Window Start is greater than (format: date-time)
  --window-start-gte: string # Window Start is greater than or equal to (format: date-time)
  --window-start-lt: string # Window Start is less than (format: date-time)
  --window-start-lte: string # Window Start is less than or equal to (format: date-time)
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency_launch_attempt_count" $agency_launch_attempt_count "scalar") (serialize-qp "agency_launch_attempt_count__gt" $agency_launch_attempt_count_gt "scalar") (serialize-qp "agency_launch_attempt_count__gte" $agency_launch_attempt_count_gte "scalar") (serialize-qp "agency_launch_attempt_count__lt" $agency_launch_attempt_count_lt "scalar") (serialize-qp "agency_launch_attempt_count__lte" $agency_launch_attempt_count_lte "scalar") (serialize-qp "agency_launch_attempt_count_year" $agency_launch_attempt_count_year "scalar") (serialize-qp "agency_launch_attempt_count_year__gt" $agency_launch_attempt_count_year_gt "scalar") (serialize-qp "agency_launch_attempt_count_year__gte" $agency_launch_attempt_count_year_gte "scalar") (serialize-qp "agency_launch_attempt_count_year__lt" $agency_launch_attempt_count_year_lt "scalar") (serialize-qp "agency_launch_attempt_count_year__lte" $agency_launch_attempt_count_year_lte "scalar") (serialize-qp "day" $day "csv") (serialize-qp "id" $id "csv") (serialize-qp "include_suborbital" $include_suborbital "scalar") (serialize-qp "is_crewed" $is_crewed "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "launch_designator" $launch_designator "csv") (serialize-qp "launcher_config__id" $launcher_config_id "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "location__ids" $location_ids "csv") (serialize-qp "location_launch_attempt_count" $location_launch_attempt_count "scalar") (serialize-qp "location_launch_attempt_count__gt" $location_launch_attempt_count_gt "scalar") (serialize-qp "location_launch_attempt_count__gte" $location_launch_attempt_count_gte "scalar") (serialize-qp "location_launch_attempt_count__lt" $location_launch_attempt_count_lt "scalar") (serialize-qp "location_launch_attempt_count__lte" $location_launch_attempt_count_lte "scalar") (serialize-qp "location_launch_attempt_count_year" $location_launch_attempt_count_year "scalar") (serialize-qp "location_launch_attempt_count_year__gt" $location_launch_attempt_count_year_gt "scalar") (serialize-qp "location_launch_attempt_count_year__gte" $location_launch_attempt_count_year_gte "scalar") (serialize-qp "location_launch_attempt_count_year__lt" $location_launch_attempt_count_year_lt "scalar") (serialize-qp "location_launch_attempt_count_year__lte" $location_launch_attempt_count_year_lte "scalar") (serialize-qp "lsp__id" $lsp_id "csv") (serialize-qp "lsp__name" $lsp_name "csv") (serialize-qp "mission__agency__ids" $mission_agency__ids "csv") (serialize-qp "mission__orbit__celestial_body__id" $mission_orbit__celestial_body__id "scalar") (serialize-qp "mission__orbit__name" $mission_orbit__name "scalar") (serialize-qp "mission__orbit__name__icontains" $mission_orbit__name__icontains "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "name" $name "scalar") (serialize-qp "net__gt" $net_gt "scalar") (serialize-qp "net__gte" $net_gte "scalar") (serialize-qp "net__lt" $net_lt "scalar") (serialize-qp "net__lte" $net_lte "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orbital_launch_attempt_count" $orbital_launch_attempt_count "scalar") (serialize-qp "orbital_launch_attempt_count__gt" $orbital_launch_attempt_count_gt "scalar") (serialize-qp "orbital_launch_attempt_count__gte" $orbital_launch_attempt_count_gte "scalar") (serialize-qp "orbital_launch_attempt_count__lt" $orbital_launch_attempt_count_lt "scalar") (serialize-qp "orbital_launch_attempt_count__lte" $orbital_launch_attempt_count_lte "scalar") (serialize-qp "orbital_launch_attempt_count_year" $orbital_launch_attempt_count_year "scalar") (serialize-qp "orbital_launch_attempt_count_year__gt" $orbital_launch_attempt_count_year_gt "scalar") (serialize-qp "orbital_launch_attempt_count_year__gte" $orbital_launch_attempt_count_year_gte "scalar") (serialize-qp "orbital_launch_attempt_count_year__lt" $orbital_launch_attempt_count_year_lt "scalar") (serialize-qp "orbital_launch_attempt_count_year__lte" $orbital_launch_attempt_count_year_lte "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "pad" $pad "scalar") (serialize-qp "pad__location" $pad_location "scalar") (serialize-qp "pad__location__celestial_body__id" $pad_location__celestial_body__id "scalar") (serialize-qp "pad_launch_attempt_count" $pad_launch_attempt_count "scalar") (serialize-qp "pad_launch_attempt_count__gt" $pad_launch_attempt_count_gt "scalar") (serialize-qp "pad_launch_attempt_count__gte" $pad_launch_attempt_count_gte "scalar") (serialize-qp "pad_launch_attempt_count__lt" $pad_launch_attempt_count_lt "scalar") (serialize-qp "pad_launch_attempt_count__lte" $pad_launch_attempt_count_lte "scalar") (serialize-qp "pad_launch_attempt_count_year" $pad_launch_attempt_count_year "scalar") (serialize-qp "pad_launch_attempt_count_year__gt" $pad_launch_attempt_count_year_gt "scalar") (serialize-qp "pad_launch_attempt_count_year__gte" $pad_launch_attempt_count_year_gte "scalar") (serialize-qp "pad_launch_attempt_count_year__lt" $pad_launch_attempt_count_year_lt "scalar") (serialize-qp "pad_launch_attempt_count_year__lte" $pad_launch_attempt_count_year_lte "scalar") (serialize-qp "program" $program "multi") (serialize-qp "related_lsp__id" $related_lsp_id "csv") (serialize-qp "related_lsp__name" $related_lsp_name "csv") (serialize-qp "rocket__configuration__full_name" $rocket_configuration__full_name "scalar") (serialize-qp "rocket__configuration__full_name__icontains" $rocket_configuration__full_name__icontains "scalar") (serialize-qp "rocket__configuration__id" $rocket_configuration__id "scalar") (serialize-qp "rocket__configuration__manufacturer__name" $rocket_configuration__manufacturer__name "scalar") (serialize-qp "rocket__configuration__manufacturer__name__icontains" $rocket_configuration__manufacturer__name__icontains "scalar") (serialize-qp "rocket__configuration__name" $rocket_configuration__name "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__id" $rocket_spacecraftflight__spacecraft__id "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__name" $rocket_spacecraftflight__spacecraft__name "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__name__icontains" $rocket_spacecraftflight__spacecraft__name__icontains "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "serial_number" $serial_number "csv") (serialize-qp "slug" $slug "scalar") (serialize-qp "spacecraft_config__ids" $spacecraft_config_ids "csv") (serialize-qp "status" $status "scalar") (serialize-qp "status__ids" $status_ids "csv") (serialize-qp "video_url" $video_url "csv") (serialize-qp "window_end__gt" $window_end_gt "scalar") (serialize-qp "window_end__gte" $window_end_gte "scalar") (serialize-qp "window_end__lt" $window_end_lt "scalar") (serialize-qp "window_end__lte" $window_end_lte "scalar") (serialize-qp "window_start__gt" $window_start_gt "scalar") (serialize-qp "window_start__gte" $window_start_gte "scalar") (serialize-qp "window_start__lt" $window_start_lt "scalar") (serialize-qp "window_start__lte" $window_start_lte "scalar") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/launches/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launches/?mode=list](./?mode=list)  #### Filters Parameters - `agency_launch_attempt_count`, `agency_launch_attempt_count__gt`, `agency_launch_attempt_count__gte`, `agency_launch_attempt_count__lt`, `agency_launch_attempt_count__lte`, `agency_launch_attempt_count_year`, `agency_launch_attempt_count_year__gt`, `agency_launch_attempt_count_year__gte`, `agency_launch_attempt_count_year__lt`, `agency_launch_attempt_count_year__lte`, `day`, `id`, `include_suborbital`, `is_crewed`, `last_updated__gte`, `last_updated__lte`, `launch_designator`, `launcher_config__id`, `location__ids`, `location_launch_attempt_count`, `location_launch_attempt_count__gt`, `location_launch_attempt_count__gte`, `location_launch_attempt_count__lt`, `location_launch_attempt_count__lte`, `location_launch_attempt_count_year`, `location_launch_attempt_count_year__gt`, `location_launch_attempt_count_year__gte`, `location_launch_attempt_count_year__lt`, `location_launch_attempt_count_year__lte`, `lsp__id`, `lsp__name`, `mission__agency__ids`, `mission__orbit__celestial_body__id`, `mission__orbit__name`, `mission__orbit__name__icontains`, `month`, `name`, `net__gt`, `net__gte`, `net__lt`, `net__lte`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `orbital_launch_attempt_count_year`, `orbital_launch_attempt_count_year__gt`, `orbital_launch_attempt_count_year__gte`, `orbital_launch_attempt_count_year__lt`, `orbital_launch_attempt_count_year__lte`, `pad`, `pad__location`, `pad__location__celestial_body__id`, `pad_launch_attempt_count`, `pad_launch_attempt_count__gt`, `pad_launch_attempt_count__gte`, `pad_launch_attempt_count__lt`, `pad_launch_attempt_count__lte`, `pad_launch_attempt_count_year`, `pad_launch_attempt_count_year__gt`, `pad_launch_attempt_count_year__gte`, `pad_launch_attempt_count_year__lt`, `pad_launch_attempt_count_year__lte`, `program`, `related_lsp__id`, `related_lsp__name`, `rocket__configuration__full_name`, `rocket__configuration__full_name__icontains`, `rocket__configuration__id`, `rocket__configuration__manufacturer__name`, `rocket__configuration__manufacturer__name__icontains`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__id`, `rocket__spacecraftflight__spacecraft__name`, `rocket__spacecraftflight__spacecraft__name__icontains`, `serial_number`, `slug`, `spacecraft_config__ids`, `status`, `status__ids`, `video_url`, `window_end__gt`, `window_end__gte`, `window_end__lt`, `window_end__lte`, `window_start__gt`, `window_start__gte`, `window_start__lt`, `window_start__lte`, `year`  Example - [/launches/?pad__location=13](./?pad__location=13)  #### Search Fields searched - `launch_designator`, `launch_service_provider__name`, `mission__name`, `name`, `pad__location__name`, `pad__name`, `rocket__configuration__manufacturer__abbrev`, `rocket__configuration__manufacturer__name`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__name`  Example - [/launches/?search=Starlink](./?search=Starlink)  #### Ordering Fields - `id`, `last_updated`, `name`, `net`  Example - [/launches/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launches/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launches/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launches/{id}/
# operationId: launches_retrieve
export def "230-launches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record<id: int, name: string, abbrev: string, description: string>, last_updated: string, net: string, net_precision: record<id: int, name: string, abbrev: string, description: string>, window_end: string, window_start: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, rocket: record<id: int, configuration: record<response_mode: string, id: int, url: string, name: string, families: list, full_name: string, variant: string, active: bool, is_placeholder: bool, manufacturer: record, program: list, reusable: bool, image: record, info_url: string, wiki_url: string, description: string, alias: string, min_stage: int, max_stage: int, length: float, diameter: float, maiden_flight: string, launch_cost: int, launch_mass: float, leo_capacity: float, gto_capacity: float, geo_capacity: float, sso_capacity: float, to_thrust: float, apogee: float, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int, fastest_turnaround: string>, launcher_stage: list<record>, spacecraft_stage: list<record>, payloads: list<record>>, mission: record<id: int, name: string, type: string, description: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, orbit: record<id: int, name: string, abbrev: string, celestial_body: record>, agencies: list<record>, info_urls: list<record>, vid_urls: list<record>>, pad: record<id: int, url: string, active: bool, agencies: list<record>, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record<response_mode: string, id: int, url: string, name: string, celestial_body: record, active: bool, country: record, description: string, image: record, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>>, webcast_live: bool, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int, flightclub_url: string, updates: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>, info_urls: table<priority: int, source: string, title: string, description: string, feature_image: string, url: string, type: record, language: record>, vid_urls: table<priority: int, source: string, publisher: string, title: string, description: string, feature_image: string, url: string, type: record, language: record, start_time: string, end_time: string, live: bool>, timeline: table<type: record, relative_time: string>, pad_turnaround: string, mission_patches: table<id: int, name: string, priority: int, image_url: string, agency: record, response_mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/launches/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launches/previous/?mode=list](./?mode=list)  #### Filters Parameters - `agency_launch_attempt_count`, `agency_launch_attempt_count__gt`, `agency_launch_attempt_count__gte`, `agency_launch_attempt_count__lt`, `agency_launch_attempt_count__lte`, `agency_launch_attempt_count_year`, `agency_launch_attempt_count_year__gt`, `agency_launch_attempt_count_year__gte`, `agency_launch_attempt_count_year__lt`, `agency_launch_attempt_count_year__lte`, `day`, `id`, `include_suborbital`, `is_crewed`, `last_updated__gte`, `last_updated__lte`, `launch_designator`, `launcher_config__id`, `location__ids`, `location_launch_attempt_count`, `location_launch_attempt_count__gt`, `location_launch_attempt_count__gte`, `location_launch_attempt_count__lt`, `location_launch_attempt_count__lte`, `location_launch_attempt_count_year`, `location_launch_attempt_count_year__gt`, `location_launch_attempt_count_year__gte`, `location_launch_attempt_count_year__lt`, `location_launch_attempt_count_year__lte`, `lsp__id`, `lsp__name`, `mission__agency__ids`, `mission__orbit__celestial_body__id`, `mission__orbit__name`, `mission__orbit__name__icontains`, `month`, `name`, `net__gt`, `net__gte`, `net__lt`, `net__lte`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `orbital_launch_attempt_count_year`, `orbital_launch_attempt_count_year__gt`, `orbital_launch_attempt_count_year__gte`, `orbital_launch_attempt_count_year__lt`, `orbital_launch_attempt_count_year__lte`, `pad`, `pad__location`, `pad__location__celestial_body__id`, `pad_launch_attempt_count`, `pad_launch_attempt_count__gt`, `pad_launch_attempt_count__gte`, `pad_launch_attempt_count__lt`, `pad_launch_attempt_count__lte`, `pad_launch_attempt_count_year`, `pad_launch_attempt_count_year__gt`, `pad_launch_attempt_count_year__gte`, `pad_launch_attempt_count_year__lt`, `pad_launch_attempt_count_year__lte`, `program`, `related_lsp__id`, `related_lsp__name`, `rocket__configuration__full_name`, `rocket__configuration__full_name__icontains`, `rocket__configuration__id`, `rocket__configuration__manufacturer__name`, `rocket__configuration__manufacturer__name__icontains`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__id`, `rocket__spacecraftflight__spacecraft__name`, `rocket__spacecraftflight__spacecraft__name__icontains`, `serial_number`, `slug`, `spacecraft_config__ids`, `status`, `status__ids`, `video_url`, `window_end__gt`, `window_end__gte`, `window_end__lt`, `window_end__lte`, `window_start__gt`, `window_start__gte`, `window_start__lt`, `window_start__lte`, `year`  Example - [/launches/previous/?pad__location=13](./?pad__location=13)  #### Search Fields searched - `launch_designator`, `launch_service_provider__name`, `mission__name`, `name`, `pad__location__name`, `pad__name`, `rocket__configuration__manufacturer__abbrev`, `rocket__configuration__manufacturer__name`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__name`  Example - [/launches/previous/?search=Starlink](./?search=Starlink)  #### Ordering Fields - `id`, `last_updated`, `name`, `net`  Example - [/launches/previous/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launches/previous/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launches/previous/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launches/previous/
# operationId: launches_previous_list
export def "230-launches-previous list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-launch-attempt-count: int
  --agency-launch-attempt-count-gt: int
  --agency-launch-attempt-count-gte: int
  --agency-launch-attempt-count-lt: int
  --agency-launch-attempt-count-lte: int
  --agency-launch-attempt-count-year: int
  --agency-launch-attempt-count-year-gt: int
  --agency-launch-attempt-count-year-gte: int
  --agency-launch-attempt-count-year-lt: int
  --agency-launch-attempt-count-year-lte: int
  --day: list # Multiple values may be separated by commas.
  --id: list # Multiple values may be separated by commas.
  --include-suborbital: oneof<nothing, bool>
  --is-crewed: oneof<nothing, bool>
  --last-updated-gte: string # Last Update is greater than or equal to (format: date-time)
  --last-updated-lte: string # Last Update is less than or equal to (format: date-time)
  --launch-designator: list # Comma-separated (COSPAR) international launch designators.
  --launcher-config-id: list # Multiple values may be separated by commas.
  --limit: int # Number of results to return per page.
  --location-ids: list # Comma-separated location IDs.
  --location-launch-attempt-count: int
  --location-launch-attempt-count-gt: int
  --location-launch-attempt-count-gte: int
  --location-launch-attempt-count-lt: int
  --location-launch-attempt-count-lte: int
  --location-launch-attempt-count-year: int
  --location-launch-attempt-count-year-gt: int
  --location-launch-attempt-count-year-gte: int
  --location-launch-attempt-count-year-lt: int
  --location-launch-attempt-count-year-lte: int
  --lsp-id: list # Comma-separated launch service provider (agency) IDs.
  --lsp-name: list # Comma-separated launch service provider names.
  --mission-agency--ids: list # Comma-separated mission agency IDs.
  --mission-orbit--celestial-body--id: int
  --mission-orbit--name: string
  --mission-orbit--name--icontains: string
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --name: string
  --net-gt: string # NET is greater than (format: date-time)
  --net-gte: string # NET is greater than or equal to (format: date-time)
  --net-lt: string # NET is less than (format: date-time)
  --net-lte: string # NET is less than or equal to (format: date-time)
  --offset: int # The initial index from which to return the results.
  --orbital-launch-attempt-count: int
  --orbital-launch-attempt-count-gt: int
  --orbital-launch-attempt-count-gte: int
  --orbital-launch-attempt-count-lt: int
  --orbital-launch-attempt-count-lte: int
  --orbital-launch-attempt-count-year: int
  --orbital-launch-attempt-count-year-gt: int
  --orbital-launch-attempt-count-year-gte: int
  --orbital-launch-attempt-count-year-lt: int
  --orbital-launch-attempt-count-year-lte: int
  --ordering: string # Which field to use when ordering the results.
  --pad: int
  --pad-location: int
  --pad-location--celestial-body--id: int
  --pad-launch-attempt-count: int
  --pad-launch-attempt-count-gt: int
  --pad-launch-attempt-count-gte: int
  --pad-launch-attempt-count-lt: int
  --pad-launch-attempt-count-lte: int
  --pad-launch-attempt-count-year: int
  --pad-launch-attempt-count-year-gt: int
  --pad-launch-attempt-count-year-gte: int
  --pad-launch-attempt-count-year-lt: int
  --pad-launch-attempt-count-year-lte: int
  --program: list
  --related-lsp-id: list # Comma-separated agency IDs related to the launch service provider.
  --related-lsp-name: list # Comma-separated agency names related to the launch service provider.
  --rocket-configuration--full-name: string
  --rocket-configuration--full-name--icontains: string
  --rocket-configuration--id: int
  --rocket-configuration--manufacturer--name: string
  --rocket-configuration--manufacturer--name--icontains: string
  --rocket-configuration--name: string
  --rocket-spacecraftflight--spacecraft--id: int
  --rocket-spacecraftflight--spacecraft--name: string
  --rocket-spacecraftflight--spacecraft--name--icontains: string
  --search: string # A search term.
  --serial-number: list # Comma-separated first stage booster serial numbers.
  --slug: string
  --spacecraft-config-ids: list # Multiple values may be separated by commas.
  --status: int
  --status-ids: list # Multiple values may be separated by commas.
  --video-url: list # Comma-separated video URLs.
  --window-end-gt: string # Window End is greater than (format: date-time)
  --window-end-gte: string # Window End is greater than or equal to (format: date-time)
  --window-end-lt: string # Window End is less than (format: date-time)
  --window-end-lte: string # Window End is less than or equal to (format: date-time)
  --window-start-gt: string # Window Start is greater than (format: date-time)
  --window-start-gte: string # Window Start is greater than or equal to (format: date-time)
  --window-start-lt: string # Window Start is less than (format: date-time)
  --window-start-lte: string # Window Start is less than or equal to (format: date-time)
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency_launch_attempt_count" $agency_launch_attempt_count "scalar") (serialize-qp "agency_launch_attempt_count__gt" $agency_launch_attempt_count_gt "scalar") (serialize-qp "agency_launch_attempt_count__gte" $agency_launch_attempt_count_gte "scalar") (serialize-qp "agency_launch_attempt_count__lt" $agency_launch_attempt_count_lt "scalar") (serialize-qp "agency_launch_attempt_count__lte" $agency_launch_attempt_count_lte "scalar") (serialize-qp "agency_launch_attempt_count_year" $agency_launch_attempt_count_year "scalar") (serialize-qp "agency_launch_attempt_count_year__gt" $agency_launch_attempt_count_year_gt "scalar") (serialize-qp "agency_launch_attempt_count_year__gte" $agency_launch_attempt_count_year_gte "scalar") (serialize-qp "agency_launch_attempt_count_year__lt" $agency_launch_attempt_count_year_lt "scalar") (serialize-qp "agency_launch_attempt_count_year__lte" $agency_launch_attempt_count_year_lte "scalar") (serialize-qp "day" $day "csv") (serialize-qp "id" $id "csv") (serialize-qp "include_suborbital" $include_suborbital "scalar") (serialize-qp "is_crewed" $is_crewed "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "launch_designator" $launch_designator "csv") (serialize-qp "launcher_config__id" $launcher_config_id "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "location__ids" $location_ids "csv") (serialize-qp "location_launch_attempt_count" $location_launch_attempt_count "scalar") (serialize-qp "location_launch_attempt_count__gt" $location_launch_attempt_count_gt "scalar") (serialize-qp "location_launch_attempt_count__gte" $location_launch_attempt_count_gte "scalar") (serialize-qp "location_launch_attempt_count__lt" $location_launch_attempt_count_lt "scalar") (serialize-qp "location_launch_attempt_count__lte" $location_launch_attempt_count_lte "scalar") (serialize-qp "location_launch_attempt_count_year" $location_launch_attempt_count_year "scalar") (serialize-qp "location_launch_attempt_count_year__gt" $location_launch_attempt_count_year_gt "scalar") (serialize-qp "location_launch_attempt_count_year__gte" $location_launch_attempt_count_year_gte "scalar") (serialize-qp "location_launch_attempt_count_year__lt" $location_launch_attempt_count_year_lt "scalar") (serialize-qp "location_launch_attempt_count_year__lte" $location_launch_attempt_count_year_lte "scalar") (serialize-qp "lsp__id" $lsp_id "csv") (serialize-qp "lsp__name" $lsp_name "csv") (serialize-qp "mission__agency__ids" $mission_agency__ids "csv") (serialize-qp "mission__orbit__celestial_body__id" $mission_orbit__celestial_body__id "scalar") (serialize-qp "mission__orbit__name" $mission_orbit__name "scalar") (serialize-qp "mission__orbit__name__icontains" $mission_orbit__name__icontains "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "name" $name "scalar") (serialize-qp "net__gt" $net_gt "scalar") (serialize-qp "net__gte" $net_gte "scalar") (serialize-qp "net__lt" $net_lt "scalar") (serialize-qp "net__lte" $net_lte "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orbital_launch_attempt_count" $orbital_launch_attempt_count "scalar") (serialize-qp "orbital_launch_attempt_count__gt" $orbital_launch_attempt_count_gt "scalar") (serialize-qp "orbital_launch_attempt_count__gte" $orbital_launch_attempt_count_gte "scalar") (serialize-qp "orbital_launch_attempt_count__lt" $orbital_launch_attempt_count_lt "scalar") (serialize-qp "orbital_launch_attempt_count__lte" $orbital_launch_attempt_count_lte "scalar") (serialize-qp "orbital_launch_attempt_count_year" $orbital_launch_attempt_count_year "scalar") (serialize-qp "orbital_launch_attempt_count_year__gt" $orbital_launch_attempt_count_year_gt "scalar") (serialize-qp "orbital_launch_attempt_count_year__gte" $orbital_launch_attempt_count_year_gte "scalar") (serialize-qp "orbital_launch_attempt_count_year__lt" $orbital_launch_attempt_count_year_lt "scalar") (serialize-qp "orbital_launch_attempt_count_year__lte" $orbital_launch_attempt_count_year_lte "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "pad" $pad "scalar") (serialize-qp "pad__location" $pad_location "scalar") (serialize-qp "pad__location__celestial_body__id" $pad_location__celestial_body__id "scalar") (serialize-qp "pad_launch_attempt_count" $pad_launch_attempt_count "scalar") (serialize-qp "pad_launch_attempt_count__gt" $pad_launch_attempt_count_gt "scalar") (serialize-qp "pad_launch_attempt_count__gte" $pad_launch_attempt_count_gte "scalar") (serialize-qp "pad_launch_attempt_count__lt" $pad_launch_attempt_count_lt "scalar") (serialize-qp "pad_launch_attempt_count__lte" $pad_launch_attempt_count_lte "scalar") (serialize-qp "pad_launch_attempt_count_year" $pad_launch_attempt_count_year "scalar") (serialize-qp "pad_launch_attempt_count_year__gt" $pad_launch_attempt_count_year_gt "scalar") (serialize-qp "pad_launch_attempt_count_year__gte" $pad_launch_attempt_count_year_gte "scalar") (serialize-qp "pad_launch_attempt_count_year__lt" $pad_launch_attempt_count_year_lt "scalar") (serialize-qp "pad_launch_attempt_count_year__lte" $pad_launch_attempt_count_year_lte "scalar") (serialize-qp "program" $program "multi") (serialize-qp "related_lsp__id" $related_lsp_id "csv") (serialize-qp "related_lsp__name" $related_lsp_name "csv") (serialize-qp "rocket__configuration__full_name" $rocket_configuration__full_name "scalar") (serialize-qp "rocket__configuration__full_name__icontains" $rocket_configuration__full_name__icontains "scalar") (serialize-qp "rocket__configuration__id" $rocket_configuration__id "scalar") (serialize-qp "rocket__configuration__manufacturer__name" $rocket_configuration__manufacturer__name "scalar") (serialize-qp "rocket__configuration__manufacturer__name__icontains" $rocket_configuration__manufacturer__name__icontains "scalar") (serialize-qp "rocket__configuration__name" $rocket_configuration__name "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__id" $rocket_spacecraftflight__spacecraft__id "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__name" $rocket_spacecraftflight__spacecraft__name "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__name__icontains" $rocket_spacecraftflight__spacecraft__name__icontains "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "serial_number" $serial_number "csv") (serialize-qp "slug" $slug "scalar") (serialize-qp "spacecraft_config__ids" $spacecraft_config_ids "csv") (serialize-qp "status" $status "scalar") (serialize-qp "status__ids" $status_ids "csv") (serialize-qp "video_url" $video_url "csv") (serialize-qp "window_end__gt" $window_end_gt "scalar") (serialize-qp "window_end__gte" $window_end_gte "scalar") (serialize-qp "window_end__lt" $window_end_lt "scalar") (serialize-qp "window_end__lte" $window_end_lte "scalar") (serialize-qp "window_start__gt" $window_start_gt "scalar") (serialize-qp "window_start__gte" $window_start_gte "scalar") (serialize-qp "window_start__lt" $window_start_lt "scalar") (serialize-qp "window_start__lte" $window_start_lte "scalar") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/launches/previous/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launches/previous/?mode=list](./?mode=list)  #### Filters Parameters - `agency_launch_attempt_count`, `agency_launch_attempt_count__gt`, `agency_launch_attempt_count__gte`, `agency_launch_attempt_count__lt`, `agency_launch_attempt_count__lte`, `agency_launch_attempt_count_year`, `agency_launch_attempt_count_year__gt`, `agency_launch_attempt_count_year__gte`, `agency_launch_attempt_count_year__lt`, `agency_launch_attempt_count_year__lte`, `day`, `id`, `include_suborbital`, `is_crewed`, `last_updated__gte`, `last_updated__lte`, `launch_designator`, `launcher_config__id`, `location__ids`, `location_launch_attempt_count`, `location_launch_attempt_count__gt`, `location_launch_attempt_count__gte`, `location_launch_attempt_count__lt`, `location_launch_attempt_count__lte`, `location_launch_attempt_count_year`, `location_launch_attempt_count_year__gt`, `location_launch_attempt_count_year__gte`, `location_launch_attempt_count_year__lt`, `location_launch_attempt_count_year__lte`, `lsp__id`, `lsp__name`, `mission__agency__ids`, `mission__orbit__celestial_body__id`, `mission__orbit__name`, `mission__orbit__name__icontains`, `month`, `name`, `net__gt`, `net__gte`, `net__lt`, `net__lte`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `orbital_launch_attempt_count_year`, `orbital_launch_attempt_count_year__gt`, `orbital_launch_attempt_count_year__gte`, `orbital_launch_attempt_count_year__lt`, `orbital_launch_attempt_count_year__lte`, `pad`, `pad__location`, `pad__location__celestial_body__id`, `pad_launch_attempt_count`, `pad_launch_attempt_count__gt`, `pad_launch_attempt_count__gte`, `pad_launch_attempt_count__lt`, `pad_launch_attempt_count__lte`, `pad_launch_attempt_count_year`, `pad_launch_attempt_count_year__gt`, `pad_launch_attempt_count_year__gte`, `pad_launch_attempt_count_year__lt`, `pad_launch_attempt_count_year__lte`, `program`, `related_lsp__id`, `related_lsp__name`, `rocket__configuration__full_name`, `rocket__configuration__full_name__icontains`, `rocket__configuration__id`, `rocket__configuration__manufacturer__name`, `rocket__configuration__manufacturer__name__icontains`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__id`, `rocket__spacecraftflight__spacecraft__name`, `rocket__spacecraftflight__spacecraft__name__icontains`, `serial_number`, `slug`, `spacecraft_config__ids`, `status`, `status__ids`, `video_url`, `window_end__gt`, `window_end__gte`, `window_end__lt`, `window_end__lte`, `window_start__gt`, `window_start__gte`, `window_start__lt`, `window_start__lte`, `year`  Example - [/launches/previous/?pad__location=13](./?pad__location=13)  #### Search Fields searched - `launch_designator`, `launch_service_provider__name`, `mission__name`, `name`, `pad__location__name`, `pad__name`, `rocket__configuration__manufacturer__abbrev`, `rocket__configuration__manufacturer__name`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__name`  Example - [/launches/previous/?search=Starlink](./?search=Starlink)  #### Ordering Fields - `id`, `last_updated`, `name`, `net`  Example - [/launches/previous/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launches/previous/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launches/previous/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launches/previous/{id}/
# operationId: launches_previous_retrieve
export def "230-launches-previous get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record<id: int, name: string, abbrev: string, description: string>, last_updated: string, net: string, net_precision: record<id: int, name: string, abbrev: string, description: string>, window_end: string, window_start: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, rocket: record<id: int, configuration: record<response_mode: string, id: int, url: string, name: string, families: list, full_name: string, variant: string, active: bool, is_placeholder: bool, manufacturer: record, program: list, reusable: bool, image: record, info_url: string, wiki_url: string, description: string, alias: string, min_stage: int, max_stage: int, length: float, diameter: float, maiden_flight: string, launch_cost: int, launch_mass: float, leo_capacity: float, gto_capacity: float, geo_capacity: float, sso_capacity: float, to_thrust: float, apogee: float, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int, fastest_turnaround: string>, launcher_stage: list<record>, spacecraft_stage: list<record>, payloads: list<record>>, mission: record<id: int, name: string, type: string, description: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, orbit: record<id: int, name: string, abbrev: string, celestial_body: record>, agencies: list<record>, info_urls: list<record>, vid_urls: list<record>>, pad: record<id: int, url: string, active: bool, agencies: list<record>, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record<response_mode: string, id: int, url: string, name: string, celestial_body: record, active: bool, country: record, description: string, image: record, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>>, webcast_live: bool, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int, flightclub_url: string, updates: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>, info_urls: table<priority: int, source: string, title: string, description: string, feature_image: string, url: string, type: record, language: record>, vid_urls: table<priority: int, source: string, publisher: string, title: string, description: string, feature_image: string, url: string, type: record, language: record, start_time: string, end_time: string, live: bool>, timeline: table<type: record, relative_time: string>, pad_turnaround: string, mission_patches: table<id: int, name: string, priority: int, image_url: string, agency: record, response_mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/launches/previous/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launches/upcoming/?mode=list](./?mode=list)  #### Filters Parameters - `agency_launch_attempt_count`, `agency_launch_attempt_count__gt`, `agency_launch_attempt_count__gte`, `agency_launch_attempt_count__lt`, `agency_launch_attempt_count__lte`, `agency_launch_attempt_count_year`, `agency_launch_attempt_count_year__gt`, `agency_launch_attempt_count_year__gte`, `agency_launch_attempt_count_year__lt`, `agency_launch_attempt_count_year__lte`, `day`, `hide_recent_previous`, `id`, `include_suborbital`, `is_crewed`, `last_updated__gte`, `last_updated__lte`, `launch_designator`, `launcher_config__id`, `location__ids`, `location_launch_attempt_count`, `location_launch_attempt_count__gt`, `location_launch_attempt_count__gte`, `location_launch_attempt_count__lt`, `location_launch_attempt_count__lte`, `location_launch_attempt_count_year`, `location_launch_attempt_count_year__gt`, `location_launch_attempt_count_year__gte`, `location_launch_attempt_count_year__lt`, `location_launch_attempt_count_year__lte`, `lsp__id`, `lsp__name`, `mission__agency__ids`, `mission__orbit__celestial_body__id`, `mission__orbit__name`, `mission__orbit__name__icontains`, `month`, `name`, `net__gt`, `net__gte`, `net__lt`, `net__lte`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `orbital_launch_attempt_count_year`, `orbital_launch_attempt_count_year__gt`, `orbital_launch_attempt_count_year__gte`, `orbital_launch_attempt_count_year__lt`, `orbital_launch_attempt_count_year__lte`, `pad`, `pad__location`, `pad__location__celestial_body__id`, `pad_launch_attempt_count`, `pad_launch_attempt_count__gt`, `pad_launch_attempt_count__gte`, `pad_launch_attempt_count__lt`, `pad_launch_attempt_count__lte`, `pad_launch_attempt_count_year`, `pad_launch_attempt_count_year__gt`, `pad_launch_attempt_count_year__gte`, `pad_launch_attempt_count_year__lt`, `pad_launch_attempt_count_year__lte`, `program`, `related_lsp__id`, `related_lsp__name`, `rocket__configuration__full_name`, `rocket__configuration__full_name__icontains`, `rocket__configuration__id`, `rocket__configuration__manufacturer__name`, `rocket__configuration__manufacturer__name__icontains`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__id`, `rocket__spacecraftflight__spacecraft__name`, `rocket__spacecraftflight__spacecraft__name__icontains`, `serial_number`, `slug`, `spacecraft_config__ids`, `status`, `status__ids`, `video_url`, `window_end__gt`, `window_end__gte`, `window_end__lt`, `window_end__lte`, `window_start__gt`, `window_start__gte`, `window_start__lt`, `window_start__lte`, `year`  Example - [/launches/upcoming/?hide_recent_previous=True](./?hide_recent_previous=True)  #### Search Fields searched - `launch_service_provider__name`, `mission__name`, `name`, `pad__location__name`, `pad__name`, `rocket__configuration__manufacturer__abbrev`, `rocket__configuration__manufacturer__name`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__name`  Example - [/launches/upcoming/?search=Starlink](./?search=Starlink)  #### Ordering Fields - `id`, `last_updated`, `name`, `net`  Example - [/launches/upcoming/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launches/upcoming/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launches/upcoming/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launches/upcoming/
# operationId: launches_upcoming_list
export def "230-launches-upcoming list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-launch-attempt-count: int
  --agency-launch-attempt-count-gt: int
  --agency-launch-attempt-count-gte: int
  --agency-launch-attempt-count-lt: int
  --agency-launch-attempt-count-lte: int
  --agency-launch-attempt-count-year: int
  --agency-launch-attempt-count-year-gt: int
  --agency-launch-attempt-count-year-gte: int
  --agency-launch-attempt-count-year-lt: int
  --agency-launch-attempt-count-year-lte: int
  --day: list # Multiple values may be separated by commas.
  --hide-recent-previous: oneof<nothing, bool> # Hide launches from the past 24 hours, which are included by default for convenience.
  --id: list # Multiple values may be separated by commas.
  --include-suborbital: oneof<nothing, bool>
  --is-crewed: oneof<nothing, bool>
  --last-updated-gte: string # Last Update is greater than or equal to (format: date-time)
  --last-updated-lte: string # Last Update is less than or equal to (format: date-time)
  --launch-designator: list # Comma-separated (COSPAR) international launch designators.
  --launcher-config-id: list # Multiple values may be separated by commas.
  --limit: int # Number of results to return per page.
  --location-ids: list # Comma-separated location IDs.
  --location-launch-attempt-count: int
  --location-launch-attempt-count-gt: int
  --location-launch-attempt-count-gte: int
  --location-launch-attempt-count-lt: int
  --location-launch-attempt-count-lte: int
  --location-launch-attempt-count-year: int
  --location-launch-attempt-count-year-gt: int
  --location-launch-attempt-count-year-gte: int
  --location-launch-attempt-count-year-lt: int
  --location-launch-attempt-count-year-lte: int
  --lsp-id: list # Comma-separated launch service provider (agency) IDs.
  --lsp-name: list # Comma-separated launch service provider names.
  --mission-agency--ids: list # Comma-separated mission agency IDs.
  --mission-orbit--celestial-body--id: int
  --mission-orbit--name: string
  --mission-orbit--name--icontains: string
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --name: string
  --net-gt: string # NET is greater than (format: date-time)
  --net-gte: string # NET is greater than or equal to (format: date-time)
  --net-lt: string # NET is less than (format: date-time)
  --net-lte: string # NET is less than or equal to (format: date-time)
  --offset: int # The initial index from which to return the results.
  --orbital-launch-attempt-count: int
  --orbital-launch-attempt-count-gt: int
  --orbital-launch-attempt-count-gte: int
  --orbital-launch-attempt-count-lt: int
  --orbital-launch-attempt-count-lte: int
  --orbital-launch-attempt-count-year: int
  --orbital-launch-attempt-count-year-gt: int
  --orbital-launch-attempt-count-year-gte: int
  --orbital-launch-attempt-count-year-lt: int
  --orbital-launch-attempt-count-year-lte: int
  --ordering: string # Which field to use when ordering the results.
  --pad: int
  --pad-location: int
  --pad-location--celestial-body--id: int
  --pad-launch-attempt-count: int
  --pad-launch-attempt-count-gt: int
  --pad-launch-attempt-count-gte: int
  --pad-launch-attempt-count-lt: int
  --pad-launch-attempt-count-lte: int
  --pad-launch-attempt-count-year: int
  --pad-launch-attempt-count-year-gt: int
  --pad-launch-attempt-count-year-gte: int
  --pad-launch-attempt-count-year-lt: int
  --pad-launch-attempt-count-year-lte: int
  --program: list
  --related-lsp-id: list # Comma-separated agency IDs related to the launch service provider.
  --related-lsp-name: list # Comma-separated agency names related to the launch service provider.
  --rocket-configuration--full-name: string
  --rocket-configuration--full-name--icontains: string
  --rocket-configuration--id: int
  --rocket-configuration--manufacturer--name: string
  --rocket-configuration--manufacturer--name--icontains: string
  --rocket-configuration--name: string
  --rocket-spacecraftflight--spacecraft--id: int
  --rocket-spacecraftflight--spacecraft--name: string
  --rocket-spacecraftflight--spacecraft--name--icontains: string
  --search: string # A search term.
  --serial-number: list # Comma-separated first stage booster serial numbers.
  --slug: string
  --spacecraft-config-ids: list # Multiple values may be separated by commas.
  --status: int
  --status-ids: list # Multiple values may be separated by commas.
  --video-url: list # Comma-separated video URLs.
  --window-end-gt: string # Window End is greater than (format: date-time)
  --window-end-gte: string # Window End is greater than or equal to (format: date-time)
  --window-end-lt: string # Window End is less than (format: date-time)
  --window-end-lte: string # Window End is less than or equal to (format: date-time)
  --window-start-gt: string # Window Start is greater than (format: date-time)
  --window-start-gte: string # Window Start is greater than or equal to (format: date-time)
  --window-start-lt: string # Window Start is less than (format: date-time)
  --window-start-lte: string # Window Start is less than or equal to (format: date-time)
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency_launch_attempt_count" $agency_launch_attempt_count "scalar") (serialize-qp "agency_launch_attempt_count__gt" $agency_launch_attempt_count_gt "scalar") (serialize-qp "agency_launch_attempt_count__gte" $agency_launch_attempt_count_gte "scalar") (serialize-qp "agency_launch_attempt_count__lt" $agency_launch_attempt_count_lt "scalar") (serialize-qp "agency_launch_attempt_count__lte" $agency_launch_attempt_count_lte "scalar") (serialize-qp "agency_launch_attempt_count_year" $agency_launch_attempt_count_year "scalar") (serialize-qp "agency_launch_attempt_count_year__gt" $agency_launch_attempt_count_year_gt "scalar") (serialize-qp "agency_launch_attempt_count_year__gte" $agency_launch_attempt_count_year_gte "scalar") (serialize-qp "agency_launch_attempt_count_year__lt" $agency_launch_attempt_count_year_lt "scalar") (serialize-qp "agency_launch_attempt_count_year__lte" $agency_launch_attempt_count_year_lte "scalar") (serialize-qp "day" $day "csv") (serialize-qp "hide_recent_previous" $hide_recent_previous "scalar") (serialize-qp "id" $id "csv") (serialize-qp "include_suborbital" $include_suborbital "scalar") (serialize-qp "is_crewed" $is_crewed "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "launch_designator" $launch_designator "csv") (serialize-qp "launcher_config__id" $launcher_config_id "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "location__ids" $location_ids "csv") (serialize-qp "location_launch_attempt_count" $location_launch_attempt_count "scalar") (serialize-qp "location_launch_attempt_count__gt" $location_launch_attempt_count_gt "scalar") (serialize-qp "location_launch_attempt_count__gte" $location_launch_attempt_count_gte "scalar") (serialize-qp "location_launch_attempt_count__lt" $location_launch_attempt_count_lt "scalar") (serialize-qp "location_launch_attempt_count__lte" $location_launch_attempt_count_lte "scalar") (serialize-qp "location_launch_attempt_count_year" $location_launch_attempt_count_year "scalar") (serialize-qp "location_launch_attempt_count_year__gt" $location_launch_attempt_count_year_gt "scalar") (serialize-qp "location_launch_attempt_count_year__gte" $location_launch_attempt_count_year_gte "scalar") (serialize-qp "location_launch_attempt_count_year__lt" $location_launch_attempt_count_year_lt "scalar") (serialize-qp "location_launch_attempt_count_year__lte" $location_launch_attempt_count_year_lte "scalar") (serialize-qp "lsp__id" $lsp_id "csv") (serialize-qp "lsp__name" $lsp_name "csv") (serialize-qp "mission__agency__ids" $mission_agency__ids "csv") (serialize-qp "mission__orbit__celestial_body__id" $mission_orbit__celestial_body__id "scalar") (serialize-qp "mission__orbit__name" $mission_orbit__name "scalar") (serialize-qp "mission__orbit__name__icontains" $mission_orbit__name__icontains "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "name" $name "scalar") (serialize-qp "net__gt" $net_gt "scalar") (serialize-qp "net__gte" $net_gte "scalar") (serialize-qp "net__lt" $net_lt "scalar") (serialize-qp "net__lte" $net_lte "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orbital_launch_attempt_count" $orbital_launch_attempt_count "scalar") (serialize-qp "orbital_launch_attempt_count__gt" $orbital_launch_attempt_count_gt "scalar") (serialize-qp "orbital_launch_attempt_count__gte" $orbital_launch_attempt_count_gte "scalar") (serialize-qp "orbital_launch_attempt_count__lt" $orbital_launch_attempt_count_lt "scalar") (serialize-qp "orbital_launch_attempt_count__lte" $orbital_launch_attempt_count_lte "scalar") (serialize-qp "orbital_launch_attempt_count_year" $orbital_launch_attempt_count_year "scalar") (serialize-qp "orbital_launch_attempt_count_year__gt" $orbital_launch_attempt_count_year_gt "scalar") (serialize-qp "orbital_launch_attempt_count_year__gte" $orbital_launch_attempt_count_year_gte "scalar") (serialize-qp "orbital_launch_attempt_count_year__lt" $orbital_launch_attempt_count_year_lt "scalar") (serialize-qp "orbital_launch_attempt_count_year__lte" $orbital_launch_attempt_count_year_lte "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "pad" $pad "scalar") (serialize-qp "pad__location" $pad_location "scalar") (serialize-qp "pad__location__celestial_body__id" $pad_location__celestial_body__id "scalar") (serialize-qp "pad_launch_attempt_count" $pad_launch_attempt_count "scalar") (serialize-qp "pad_launch_attempt_count__gt" $pad_launch_attempt_count_gt "scalar") (serialize-qp "pad_launch_attempt_count__gte" $pad_launch_attempt_count_gte "scalar") (serialize-qp "pad_launch_attempt_count__lt" $pad_launch_attempt_count_lt "scalar") (serialize-qp "pad_launch_attempt_count__lte" $pad_launch_attempt_count_lte "scalar") (serialize-qp "pad_launch_attempt_count_year" $pad_launch_attempt_count_year "scalar") (serialize-qp "pad_launch_attempt_count_year__gt" $pad_launch_attempt_count_year_gt "scalar") (serialize-qp "pad_launch_attempt_count_year__gte" $pad_launch_attempt_count_year_gte "scalar") (serialize-qp "pad_launch_attempt_count_year__lt" $pad_launch_attempt_count_year_lt "scalar") (serialize-qp "pad_launch_attempt_count_year__lte" $pad_launch_attempt_count_year_lte "scalar") (serialize-qp "program" $program "multi") (serialize-qp "related_lsp__id" $related_lsp_id "csv") (serialize-qp "related_lsp__name" $related_lsp_name "csv") (serialize-qp "rocket__configuration__full_name" $rocket_configuration__full_name "scalar") (serialize-qp "rocket__configuration__full_name__icontains" $rocket_configuration__full_name__icontains "scalar") (serialize-qp "rocket__configuration__id" $rocket_configuration__id "scalar") (serialize-qp "rocket__configuration__manufacturer__name" $rocket_configuration__manufacturer__name "scalar") (serialize-qp "rocket__configuration__manufacturer__name__icontains" $rocket_configuration__manufacturer__name__icontains "scalar") (serialize-qp "rocket__configuration__name" $rocket_configuration__name "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__id" $rocket_spacecraftflight__spacecraft__id "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__name" $rocket_spacecraftflight__spacecraft__name "scalar") (serialize-qp "rocket__spacecraftflight__spacecraft__name__icontains" $rocket_spacecraftflight__spacecraft__name__icontains "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "serial_number" $serial_number "csv") (serialize-qp "slug" $slug "scalar") (serialize-qp "spacecraft_config__ids" $spacecraft_config_ids "csv") (serialize-qp "status" $status "scalar") (serialize-qp "status__ids" $status_ids "csv") (serialize-qp "video_url" $video_url "csv") (serialize-qp "window_end__gt" $window_end_gt "scalar") (serialize-qp "window_end__gte" $window_end_gte "scalar") (serialize-qp "window_end__lt" $window_end_lt "scalar") (serialize-qp "window_end__lte" $window_end_lte "scalar") (serialize-qp "window_start__gt" $window_start_gt "scalar") (serialize-qp "window_start__gte" $window_start_gte "scalar") (serialize-qp "window_start__lt" $window_start_lt "scalar") (serialize-qp "window_start__lte" $window_start_lte "scalar") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/launches/upcoming/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/launches/upcoming/?mode=list](./?mode=list)  #### Filters Parameters - `agency_launch_attempt_count`, `agency_launch_attempt_count__gt`, `agency_launch_attempt_count__gte`, `agency_launch_attempt_count__lt`, `agency_launch_attempt_count__lte`, `agency_launch_attempt_count_year`, `agency_launch_attempt_count_year__gt`, `agency_launch_attempt_count_year__gte`, `agency_launch_attempt_count_year__lt`, `agency_launch_attempt_count_year__lte`, `day`, `hide_recent_previous`, `id`, `include_suborbital`, `is_crewed`, `last_updated__gte`, `last_updated__lte`, `launch_designator`, `launcher_config__id`, `location__ids`, `location_launch_attempt_count`, `location_launch_attempt_count__gt`, `location_launch_attempt_count__gte`, `location_launch_attempt_count__lt`, `location_launch_attempt_count__lte`, `location_launch_attempt_count_year`, `location_launch_attempt_count_year__gt`, `location_launch_attempt_count_year__gte`, `location_launch_attempt_count_year__lt`, `location_launch_attempt_count_year__lte`, `lsp__id`, `lsp__name`, `mission__agency__ids`, `mission__orbit__celestial_body__id`, `mission__orbit__name`, `mission__orbit__name__icontains`, `month`, `name`, `net__gt`, `net__gte`, `net__lt`, `net__lte`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `orbital_launch_attempt_count_year`, `orbital_launch_attempt_count_year__gt`, `orbital_launch_attempt_count_year__gte`, `orbital_launch_attempt_count_year__lt`, `orbital_launch_attempt_count_year__lte`, `pad`, `pad__location`, `pad__location__celestial_body__id`, `pad_launch_attempt_count`, `pad_launch_attempt_count__gt`, `pad_launch_attempt_count__gte`, `pad_launch_attempt_count__lt`, `pad_launch_attempt_count__lte`, `pad_launch_attempt_count_year`, `pad_launch_attempt_count_year__gt`, `pad_launch_attempt_count_year__gte`, `pad_launch_attempt_count_year__lt`, `pad_launch_attempt_count_year__lte`, `program`, `related_lsp__id`, `related_lsp__name`, `rocket__configuration__full_name`, `rocket__configuration__full_name__icontains`, `rocket__configuration__id`, `rocket__configuration__manufacturer__name`, `rocket__configuration__manufacturer__name__icontains`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__id`, `rocket__spacecraftflight__spacecraft__name`, `rocket__spacecraftflight__spacecraft__name__icontains`, `serial_number`, `slug`, `spacecraft_config__ids`, `status`, `status__ids`, `video_url`, `window_end__gt`, `window_end__gte`, `window_end__lt`, `window_end__lte`, `window_start__gt`, `window_start__gte`, `window_start__lt`, `window_start__lte`, `year`  Example - [/launches/upcoming/?hide_recent_previous=True](./?hide_recent_previous=True)  #### Search Fields searched - `launch_service_provider__name`, `mission__name`, `name`, `pad__location__name`, `pad__name`, `rocket__configuration__manufacturer__abbrev`, `rocket__configuration__manufacturer__name`, `rocket__configuration__name`, `rocket__spacecraftflight__spacecraft__name`  Example - [/launches/upcoming/?search=Starlink](./?search=Starlink)  #### Ordering Fields - `id`, `last_updated`, `name`, `net`  Example - [/launches/upcoming/?ordering=-last_updated](./?ordering=-last_updated)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/launches/upcoming/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/launches/upcoming/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/launches/upcoming/{id}/
# operationId: launches_upcoming_retrieve
export def "230-launches-upcoming get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record<id: int, name: string, abbrev: string, description: string>, last_updated: string, net: string, net_precision: record<id: int, name: string, abbrev: string, description: string>, window_end: string, window_start: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, rocket: record<id: int, configuration: record<response_mode: string, id: int, url: string, name: string, families: list, full_name: string, variant: string, active: bool, is_placeholder: bool, manufacturer: record, program: list, reusable: bool, image: record, info_url: string, wiki_url: string, description: string, alias: string, min_stage: int, max_stage: int, length: float, diameter: float, maiden_flight: string, launch_cost: int, launch_mass: float, leo_capacity: float, gto_capacity: float, geo_capacity: float, sso_capacity: float, to_thrust: float, apogee: float, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, consecutive_successful_landings: int, fastest_turnaround: string>, launcher_stage: list<record>, spacecraft_stage: list<record>, payloads: list<record>>, mission: record<id: int, name: string, type: string, description: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, orbit: record<id: int, name: string, abbrev: string, celestial_body: record>, agencies: list<record>, info_urls: list<record>, vid_urls: list<record>>, pad: record<id: int, url: string, active: bool, agencies: list<record>, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record<response_mode: string, id: int, url: string, name: string, celestial_body: record, active: bool, country: record, description: string, image: record, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>>, webcast_live: bool, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int, flightclub_url: string, updates: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>, info_urls: table<priority: int, source: string, title: string, description: string, feature_image: string, url: string, type: record, language: record>, vid_urls: table<priority: int, source: string, publisher: string, title: string, description: string, feature_image: string, url: string, type: record, language: record, start_time: string, end_time: string, live: bool>, timeline: table<type: record, relative_time: string>, pad_turnaround: string, mission_patches: table<id: int, name: string, priority: int, image_url: string, agency: record, response_mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/launches/upcoming/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/locations/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `active`, `country_code`, `id`, `name`, `name__contains`, `total_landing_count`, `total_landing_count__gt`, `total_landing_count__gte`, `total_landing_count__lt`, `total_landing_count__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/locations/?country_code=NZL](./?country_code=NZL)  #### Search Fields searched - `country__alpha_3_code`, `name`  Example - [/locations/?search=Cape Canaveral](./?search=Cape Canaveral)  #### Ordering Fields - `name`, `total_landing_count`, `total_launch_count`  Example - [/locations/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/locations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/locations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/locations/
# operationId: locations_list
export def "230-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool>
  --country-code: string # Country Code
  --id: int
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --total-landing-count: int
  --total-landing-count-gt: int
  --total-landing-count-gte: int
  --total-landing-count-lt: int
  --total-landing-count-lte: int
  --total-launch-count: int
  --total-launch-count-gt: int
  --total-launch-count-gte: int
  --total-launch-count-lt: int
  --total-launch-count-lte: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "country_code" $country_code "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "total_landing_count" $total_landing_count "scalar") (serialize-qp "total_landing_count__gt" $total_landing_count_gt "scalar") (serialize-qp "total_landing_count__gte" $total_landing_count_gte "scalar") (serialize-qp "total_landing_count__lt" $total_landing_count_lt "scalar") (serialize-qp "total_landing_count__lte" $total_landing_count_lte "scalar") (serialize-qp "total_launch_count" $total_launch_count "scalar") (serialize-qp "total_launch_count__gt" $total_launch_count_gt "scalar") (serialize-qp "total_launch_count__gte" $total_launch_count_gte "scalar") (serialize-qp "total_launch_count__lt" $total_launch_count_lt "scalar") (serialize-qp "total_launch_count__lte" $total_launch_count_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/locations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/locations/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `active`, `country_code`, `id`, `name`, `name__contains`, `total_landing_count`, `total_landing_count__gt`, `total_landing_count__gte`, `total_landing_count__lt`, `total_landing_count__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/locations/?country_code=NZL](./?country_code=NZL)  #### Search Fields searched - `country__alpha_3_code`, `name`  Example - [/locations/?search=Cape Canaveral](./?search=Cape Canaveral)  #### Ordering Fields - `name`, `total_landing_count`, `total_launch_count`  Example - [/locations/?ordering=-total_launch_count](./?ordering=-total_launch_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/locations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/locations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/locations/{id}/
# operationId: locations_retrieve
export def "230-locations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, celestial_body: record<response_mode: string, id: int, name: string, type: record<id: int, name: string>, diameter: float, mass: float, gravity: float, length_of_day: string, atmosphere: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, description: string, wiki_url: string, total_attempted_launches: int, successful_launches: int, failed_launches: int, total_attempted_landings: int, successful_landings: int, failed_landings: int>, active: bool, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, description: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int, pads: table<id: int, url: string, active: bool, agencies: list, name: string, image: record, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/locations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/mission_patches/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `agency__id`, `agency__name`, `agency__name__contains`, `id`, `ids`, `name`, `name__contains`  Example - [/mission_patches/?agency__id=147](./?agency__id=147)  #### Search Fields searched - `agency__name`, `name`  Example - [/mission_patches/?search=Ariane](./?search=Ariane)  #### Ordering Fields - `agency__name`, `id`, `name`, `priority`  Example - [/mission_patches/?ordering=priority](./?ordering=priority)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/mission_patches/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/mission_patches/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/mission_patches/
# operationId: mission_patches_list
export def "230-mission-patches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency-id: int
  --agency-name: string
  --agency-name--contains: string
  --id: int
  --ids: list # Comma-separated mission patch IDs.
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency__id" $agency_id "scalar") (serialize-qp "agency__name" $agency_name "scalar") (serialize-qp "agency__name__contains" $agency_name__contains "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "ids" $ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/mission_patches/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/mission_patches/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `agency__id`, `agency__name`, `agency__name__contains`, `id`, `ids`, `name`, `name__contains`  Example - [/mission_patches/?agency__id=147](./?agency__id=147)  #### Search Fields searched - `agency__name`, `name`  Example - [/mission_patches/?search=Ariane](./?search=Ariane)  #### Ordering Fields - `agency__name`, `id`, `name`, `priority`  Example - [/mission_patches/?ordering=priority](./?ordering=priority)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/mission_patches/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/mission_patches/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/mission_patches/{id}/
# operationId: mission_patches_retrieve
export def "230-mission-patches get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, priority: int, image_url: string, agency: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, response_mode: string, launches: table<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, expeditions: table<id: int, url: string, name: string, start: string, end: string, response_mode: string, spacestation: record, mission_patches: list, spacewalks: list>, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/mission_patches/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Filters Parameters - `active`, `agencies_ids`, `id`, `id__contains`, `latitude__gt`, `latitude__gte`, `latitude__lt`, `latitude__lte`, `location__id`, `location__name`, `location__name__contains`, `longitude__gt`, `longitude__gte`, `longitude__lt`, `longitude__lte`, `name`, `name__contains`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/pads/?location__id=11](./?location__id=11)  #### Search Fields searched - `location__name`, `name`, `orbital_launch_attempt_count`, `total_launch_count`  Example - [/pads/?search=39A](./?search=39A)  #### Ordering Fields - `id`, `location__id`, `location__name`, `name`, `orbital_launch_attempt_count`, `total_launch_count`  Example - [/pads/?ordering=-orbital_launch_attempt_count](./?ordering=-orbital_launch_attempt_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/pads/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/pads/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/pads/
# operationId: pads_list
export def "230-pads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool>
  --agencies-ids: list # Multiple values may be separated by commas.
  --id: int
  --id-contains: int
  --latitude-gt: float # format: float
  --latitude-gte: float # format: float
  --latitude-lt: float # format: float
  --latitude-lte: float # format: float
  --limit: int # Number of results to return per page.
  --location-id: int
  --location-name: string
  --location-name--contains: string
  --longitude-gt: float # format: float
  --longitude-gte: float # format: float
  --longitude-lt: float # format: float
  --longitude-lte: float # format: float
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --orbital-launch-attempt-count: int
  --orbital-launch-attempt-count-gt: int
  --orbital-launch-attempt-count-gte: int
  --orbital-launch-attempt-count-lt: int
  --orbital-launch-attempt-count-lte: int
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --total-launch-count: int
  --total-launch-count-gt: int
  --total-launch-count-gte: int
  --total-launch-count-lt: int
  --total-launch-count-lte: int
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, url: string, active: bool, agencies: list, name: string, image: record, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "agencies_ids" $agencies_ids "csv") (serialize-qp "id" $id "scalar") (serialize-qp "id__contains" $id_contains "scalar") (serialize-qp "latitude__gt" $latitude_gt "scalar") (serialize-qp "latitude__gte" $latitude_gte "scalar") (serialize-qp "latitude__lt" $latitude_lt "scalar") (serialize-qp "latitude__lte" $latitude_lte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "location__id" $location_id "scalar") (serialize-qp "location__name" $location_name "scalar") (serialize-qp "location__name__contains" $location_name__contains "scalar") (serialize-qp "longitude__gt" $longitude_gt "scalar") (serialize-qp "longitude__gte" $longitude_gte "scalar") (serialize-qp "longitude__lt" $longitude_lt "scalar") (serialize-qp "longitude__lte" $longitude_lte "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orbital_launch_attempt_count" $orbital_launch_attempt_count "scalar") (serialize-qp "orbital_launch_attempt_count__gt" $orbital_launch_attempt_count_gt "scalar") (serialize-qp "orbital_launch_attempt_count__gte" $orbital_launch_attempt_count_gte "scalar") (serialize-qp "orbital_launch_attempt_count__lt" $orbital_launch_attempt_count_lt "scalar") (serialize-qp "orbital_launch_attempt_count__lte" $orbital_launch_attempt_count_lte "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "total_launch_count" $total_launch_count "scalar") (serialize-qp "total_launch_count__gt" $total_launch_count_gt "scalar") (serialize-qp "total_launch_count__gte" $total_launch_count_gte "scalar") (serialize-qp "total_launch_count__lt" $total_launch_count_lt "scalar") (serialize-qp "total_launch_count__lte" $total_launch_count_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/pads/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Filters Parameters - `active`, `agencies_ids`, `id`, `id__contains`, `latitude__gt`, `latitude__gte`, `latitude__lt`, `latitude__lte`, `location__id`, `location__name`, `location__name__contains`, `longitude__gt`, `longitude__gte`, `longitude__lt`, `longitude__lte`, `name`, `name__contains`, `orbital_launch_attempt_count`, `orbital_launch_attempt_count__gt`, `orbital_launch_attempt_count__gte`, `orbital_launch_attempt_count__lt`, `orbital_launch_attempt_count__lte`, `total_launch_count`, `total_launch_count__gt`, `total_launch_count__gte`, `total_launch_count__lt`, `total_launch_count__lte`  Example - [/pads/?location__id=11](./?location__id=11)  #### Search Fields searched - `location__name`, `name`, `orbital_launch_attempt_count`, `total_launch_count`  Example - [/pads/?search=39A](./?search=39A)  #### Ordering Fields - `id`, `location__id`, `location__name`, `name`, `orbital_launch_attempt_count`, `total_launch_count`  Example - [/pads/?ordering=-orbital_launch_attempt_count](./?ordering=-orbital_launch_attempt_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/pads/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/pads/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/pads/{id}/
# operationId: pads_retrieve
export def "230-pads get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, active: bool, agencies: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record, featured: bool, country: list, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record, logo: record, social_logo: record>, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record<response_mode: string, id: int, url: string, name: string, celestial_body: record<response_mode: string, id: int, name: string, type: record, diameter: float, mass: float, gravity: float, length_of_day: string, atmosphere: bool, image: record, description: string, wiki_url: string, total_attempted_launches: int, successful_launches: int, failed_launches: int, total_attempted_landings: int, successful_landings: int, failed_landings: int>, active: bool, country: record<id: int, name: string, alpha_2_code: string, alpha_3_code: string, nationality_name: string, nationality_name_composed: string>, description: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, map_image: string, longitude: float, latitude: float, timezone_name: string, total_launch_count: int, total_landing_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/pads/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/payload_flights/?mode=list](./?mode=list)  #### Filters Parameters - `payload`  Example - [/payload_flights/?payload=2](./?payload=2)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/payload_flights/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/payload_flights/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/payload_flights/
# operationId: payload_flights_list
export def "230-payload-flights list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --payload: int
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "payload" $payload "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/payload_flights/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/payload_flights/?mode=list](./?mode=list)  #### Filters Parameters - `payload`  Example - [/payload_flights/?payload=2](./?payload=2)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/payload_flights/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/payload_flights/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/payload_flights/{id}/
# operationId: payload_flights_retrieve
export def "230-payload-flights get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, destination: string, amount: int, payload: record<response_mode: string, id: int, name: string, type: record<id: int, name: string>, manufacturer: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record, featured: bool, country: list, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record, logo: record, social_logo: record, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list>, operator: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record, featured: bool, country: list, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record, logo: record, social_logo: record, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, wiki_link: string, info_link: string, program: list<record>, cost: int, mass: float, description: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record<id: int, name: string, abbrev: string, description: string>, last_updated: string, net: string, net_precision: record<id: int, name: string, abbrev: string, description: string>, window_end: string, window_start: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, rocket: record<id: int, configuration: record>, mission: record<id: int, name: string, type: string, description: string, image: record, orbit: record, agencies: list, info_urls: list, vid_urls: list>, pad: record<id: int, url: string, active: bool, agencies: list, name: string, image: record, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record>, webcast_live: bool, program: list<record>, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record<id: int, name: string, active: bool, abbrev: string, description: string, location: record, longitude: float, latitude: float, image: record, successful_landings: int, attempted_landings: int, failed_landings: int, celestial_body: record>, type: record<id: int, name: string, abbrev: string, description: string>>, docking_events: table<id: int, url: string, docking: string, departure: string, docking_location: record, space_station_target: record, flight_vehicle_target: record, payload_flight_target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/payload_flights/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/payloads/?mode=list](./?mode=list)  #### Filters Parameters - `manufacturer__id`, `manufacturer__name`, `name`, `operator`, `operator__id`, `operator__name`, `program__id`  Example - [/payloads/?program__id=18](./?program__id=18)  #### Search Fields searched - `manufacturer__name`, `name`, `operator__name`, `payloadflight__destination`, `payloadflight__rocket__launch__name`  Example - [/payloads/?search=EarthCare](./?search=EarthCare)  #### Ordering Fields - `id`, `name`, `payloadflight__rocket__launch__net`  Example - [/payloads/?ordering=-payloadflight__rocket__launch__net](./?ordering=-payloadflight__rocket__launch__net)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/payloads/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/payloads/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/payloads/
# operationId: payloads_list
export def "230-payloads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --manufacturer-id: int
  --manufacturer-name: string
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --offset: int # The initial index from which to return the results.
  --operator: int
  --operator-id: int
  --operator-name: string
  --ordering: string # Which field to use when ordering the results.
  --program-id: int
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "manufacturer__id" $manufacturer_id "scalar") (serialize-qp "manufacturer__name" $manufacturer_name "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "operator" $operator "scalar") (serialize-qp "operator__id" $operator_id "scalar") (serialize-qp "operator__name" $operator_name "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "program__id" $program_id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/payloads/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/payloads/?mode=list](./?mode=list)  #### Filters Parameters - `manufacturer__id`, `manufacturer__name`, `name`, `operator`, `operator__id`, `operator__name`, `program__id`  Example - [/payloads/?program__id=18](./?program__id=18)  #### Search Fields searched - `manufacturer__name`, `name`, `operator__name`, `payloadflight__destination`, `payloadflight__rocket__launch__name`  Example - [/payloads/?search=EarthCare](./?search=EarthCare)  #### Ordering Fields - `id`, `name`, `payloadflight__rocket__launch__net`  Example - [/payloads/?ordering=-payloadflight__rocket__launch__net](./?ordering=-payloadflight__rocket__launch__net)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/payloads/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/payloads/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/payloads/{id}/
# operationId: payloads_retrieve
export def "230-payloads get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, name: string, type: record<id: int, name: string>, manufacturer: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, operator: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, total_launch_count: int, consecutive_successful_launches: int, successful_launches: int, failed_launches: int, pending_launches: int, consecutive_successful_landings: int, successful_landings: int, failed_landings: int, attempted_landings: int, successful_landings_spacecraft: int, failed_landings_spacecraft: int, attempted_landings_spacecraft: int, successful_landings_payload: int, failed_landings_payload: int, attempted_landings_payload: int, info_url: string, wiki_url: string, social_media_links: list<record>>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, wiki_link: string, info_link: string, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>, cost: int, mass: float, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/payloads/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`  Example - [/programs/?mode=list](./?mode=list)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/programs/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/programs/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/programs/
# operationId: programs_list
export def "230-programs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-2 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/programs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`  Example - [/programs/?mode=list](./?mode=list)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/programs/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/programs/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/programs/{id}/
# operationId: programs_retrieve
export def "230-programs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, info_url: string, wiki_url: string, description: string, agencies: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, start_date: string, end_date: string, mission_patches: table<id: int, name: string, priority: int, image_url: string, agency: record, response_mode: string>, type: record<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/programs/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/space_stations/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `docked_vehicles`, `docked_vehicles__gt`, `docked_vehicles__gte`, `docked_vehicles__lt`, `docked_vehicles__lte`, `id`, `name`, `name__contains`, `onboard_crew`, `onboard_crew__gt`, `onboard_crew__gte`, `onboard_crew__lt`, `onboard_crew__lte`, `orbit`, `owner__ids`, `owners`, `status`, `status__ids`, `type`  Example - [/space_stations/?onboard_crew__gte=1](./?onboard_crew__gte=1)  #### Search Fields searched - `name`, `owners__abbrev`, `owners__name`  Example - [/space_stations/?search=Salyut](./?search=Salyut)  #### Ordering Fields - `docked_vehicles`, `founded`, `id`, `name`, `onboard_crew`, `status`, `type`, `volume`  Example - [/space_stations/?ordering=founded](./?ordering=founded)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/space_stations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/space_stations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/space_stations/
# operationId: space_stations_list
export def "230-space-stations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --docked-vehicles: int
  --docked-vehicles-gt: int
  --docked-vehicles-gte: int
  --docked-vehicles-lt: int
  --docked-vehicles-lte: int
  --id: int
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --onboard-crew: int
  --onboard-crew-gt: int
  --onboard-crew-gte: int
  --onboard-crew-lt: int
  --onboard-crew-lte: int
  --orbit: int
  --ordering: string # Which field to use when ordering the results.
  --owner-ids: list # Comma-separated agency IDs.
  --owners: list
  --search: string # A search term.
  --status: int
  --status-ids: list # Comma-separated spacestation status IDs.
  --type: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docked_vehicles" $docked_vehicles "scalar") (serialize-qp "docked_vehicles__gt" $docked_vehicles_gt "scalar") (serialize-qp "docked_vehicles__gte" $docked_vehicles_gte "scalar") (serialize-qp "docked_vehicles__lt" $docked_vehicles_lt "scalar") (serialize-qp "docked_vehicles__lte" $docked_vehicles_lte "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "onboard_crew" $onboard_crew "scalar") (serialize-qp "onboard_crew__gt" $onboard_crew_gt "scalar") (serialize-qp "onboard_crew__gte" $onboard_crew_gte "scalar") (serialize-qp "onboard_crew__lt" $onboard_crew_lt "scalar") (serialize-qp "onboard_crew__lte" $onboard_crew_lte "scalar") (serialize-qp "orbit" $orbit "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "owner__ids" $owner_ids "csv") (serialize-qp "owners" $owners "multi") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status__ids" $status_ids "csv") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/space_stations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/space_stations/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `docked_vehicles`, `docked_vehicles__gt`, `docked_vehicles__gte`, `docked_vehicles__lt`, `docked_vehicles__lte`, `id`, `name`, `name__contains`, `onboard_crew`, `onboard_crew__gt`, `onboard_crew__gte`, `onboard_crew__lt`, `onboard_crew__lte`, `orbit`, `owner__ids`, `owners`, `status`, `status__ids`, `type`  Example - [/space_stations/?onboard_crew__gte=1](./?onboard_crew__gte=1)  #### Search Fields searched - `name`, `owners__abbrev`, `owners__name`  Example - [/space_stations/?search=Salyut](./?search=Salyut)  #### Ordering Fields - `docked_vehicles`, `founded`, `id`, `name`, `onboard_crew`, `status`, `type`, `volume`  Example - [/space_stations/?ordering=founded](./?ordering=founded)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/space_stations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/space_stations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/space_stations/{id}/
# operationId: space_stations_retrieve
export def "230-space-stations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, status: record<id: int, name: string>, founded: string, deorbited: string, description: string, orbit: string, type: record<id: int, name: string>, owners: table<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record, featured: bool, country: list, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record, logo: record, social_logo: record>, response_mode: string, active_expeditions: table<id: int, url: string, name: string, start: string, end: string>, height: float, width: float, mass: float, volume: int, onboard_crew: int, docked_vehicles: int, docking_location: table<id: int, name: string, currently_docked: record>, active_docking_events: table<id: int, url: string, docking: string, departure: string, docking_location: record, space_station_target: record, flight_vehicle_target: record, payload_flight_target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/space_stations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/spacecraft/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `in_space`, `is_placeholder`, `name`, `spacecraft_config`, `status`  Example - [/spacecraft/?is_placeholder=True](./?is_placeholder=True)  #### Search Fields searched - `name`, `spacecraft_config__name`  Example - [/spacecraft/?search=Endeavour](./?search=Endeavour)  #### Ordering Fields - `flights_count`, `id`, `mission_ends_count`, `time_docked`, `time_in_space`  Example - [/spacecraft/?ordering=-flights_count](./?ordering=-flights_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft/
# operationId: spacecraft_list
export def "230-spacecraft list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --in-space: oneof<nothing, bool>
  --is-placeholder: oneof<nothing, bool>
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --spacecraft-config: int
  --status: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "in_space" $in_space "scalar") (serialize-qp "is_placeholder" $is_placeholder "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "spacecraft_config" $spacecraft_config "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/spacecraft/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/spacecraft/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `in_space`, `is_placeholder`, `name`, `spacecraft_config`, `status`  Example - [/spacecraft/?is_placeholder=True](./?is_placeholder=True)  #### Search Fields searched - `name`, `spacecraft_config__name`  Example - [/spacecraft/?search=Endeavour](./?search=Endeavour)  #### Ordering Fields - `flights_count`, `id`, `mission_ends_count`, `time_docked`, `time_in_space`  Example - [/spacecraft/?ordering=-flights_count](./?ordering=-flights_count)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft/{id}/
# operationId: spacecraft_retrieve
export def "230-spacecraft get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, serial_number: string, is_placeholder: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, in_space: bool, time_in_space: string, time_docked: string, flights_count: int, mission_ends_count: int, status: record<id: int, name: string>, description: string, spacecraft_config: record<response_mode: string, id: int, url: string, name: string, type: record<id: int, name: string>, agency: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record, featured: bool, country: list, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record, logo: record, social_logo: record>, family: list<record>, in_use: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, capability: string, history: string, details: string, maiden_flight: string, height: float, diameter: float, human_rated: bool, crew_capacity: int, payload_capacity: int, payload_return_capacity: int, flight_life: string, wiki_link: string, info_link: string, spacecraft_flown: int, total_launch_count: int, successful_launches: int, failed_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, fastest_turnaround: string>, fastest_turnaround: string, flights: table<id: int, url: string, destination: string, mission_end: string, spacecraft: record, launch: record, landing: record, duration: string, turn_around_time: string, response_mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/spacecraft/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/spacecraft_configuration_families/?mode=list](./?mode=list)  #### Filters Parameters - `manufacturer`, `name`  Example - [/spacecraft_configuration_families/?manufacturer=121](./?manufacturer=121)  #### Search Fields searched - `manufacturer__abbrev`, `manufacturer__name`, `name`  Example - [/spacecraft_configuration_families/?search=Northrop](./?search=Northrop)  #### Ordering Fields - `name`  Example - [/spacecraft_configuration_families/?ordering=name](./?ordering=name)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft_configuration_families/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft_configuration_families/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft_configuration_families/
# operationId: spacecraft_configuration_families_list
export def "230-spacecraft-configuration-families list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --manufacturer: int
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/spacecraft_configuration_families/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/spacecraft_configuration_families/?mode=list](./?mode=list)  #### Filters Parameters - `manufacturer`, `name`  Example - [/spacecraft_configuration_families/?manufacturer=121](./?manufacturer=121)  #### Search Fields searched - `manufacturer__abbrev`, `manufacturer__name`, `name`  Example - [/spacecraft_configuration_families/?search=Northrop](./?search=Northrop)  #### Ordering Fields - `name`  Example - [/spacecraft_configuration_families/?ordering=name](./?ordering=name)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft_configuration_families/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft_configuration_families/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft_configuration_families/{id}/
# operationId: spacecraft_configuration_families_retrieve
export def "230-spacecraft-configuration-families get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, name: string, description: string, manufacturer: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>>, parent: record<response_mode: string, id: int, name: string, description: string, manufacturer: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, parent: record<response_mode: string, id: int, name: string>, maiden_flight: string>, maiden_flight: string, spacecraft_flown: int, total_launch_count: int, successful_launches: int, failed_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, spacecraft: table<response_mode: string, id: int, url: string, name: string, type: record, agency: record, family: list, in_use: bool, image: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/spacecraft_configuration_families/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/spacecraft_configurations/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `agency`, `human_rated`, `in_use`, `name`  Example - [/spacecraft_configurations/?human_rated=True](./?human_rated=True)  #### Search Fields searched - `agency__abbrev`, `agency__name`, `name`  Example - [/spacecraft_configurations/?search=Dragon](./?search=Dragon)  #### Ordering Fields - `name`  Example - [/spacecraft_configurations/?ordering=name](./?ordering=name)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft_configurations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft_configurations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft_configurations/
# operationId: spacecraft_configurations_list
export def "230-spacecraft-configurations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agency: int
  --human-rated: oneof<nothing, bool>
  --in-use: oneof<nothing, bool>
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --name: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agency" $agency "scalar") (serialize-qp "human_rated" $human_rated "scalar") (serialize-qp "in_use" $in_use "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/spacecraft_configurations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/spacecraft_configurations/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `agency`, `human_rated`, `in_use`, `name`  Example - [/spacecraft_configurations/?human_rated=True](./?human_rated=True)  #### Search Fields searched - `agency__abbrev`, `agency__name`, `name`  Example - [/spacecraft_configurations/?search=Dragon](./?search=Dragon)  #### Ordering Fields - `name`  Example - [/spacecraft_configurations/?ordering=name](./?ordering=name)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft_configurations/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft_configurations/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft_configurations/{id}/
# operationId: spacecraft_configurations_retrieve
export def "230-spacecraft-configurations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, type: record<id: int, name: string>, agency: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record<id: int, name: string>, featured: bool, country: list<record>, description: string, administrator: string, founding_year: int, launchers: string, spacecraft: string, parent: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, social_logo: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>>, family: table<response_mode: string, id: int, name: string, description: string, manufacturer: record, parent: record, maiden_flight: string, spacecraft_flown: int, total_launch_count: int, successful_launches: int, failed_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int>, in_use: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record<id: int, name: string, priority: int, link: string>, single_use: bool, variants: list<record>>, capability: string, history: string, details: string, maiden_flight: string, height: float, diameter: float, human_rated: bool, crew_capacity: int, payload_capacity: int, payload_return_capacity: int, flight_life: string, wiki_link: string, info_link: string, spacecraft_flown: int, total_launch_count: int, successful_launches: int, failed_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, fastest_turnaround: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/spacecraft_configurations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/spacecraft_flights/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `spacecraft`  Example - [/spacecraft_flights/?spacecraft=289](./?spacecraft=289)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft_flights/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft_flights/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft_flights/
# operationId: spacecraft_flights_list
export def "230-spacecraft-flights list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer-1 # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --spacecraft: int
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "spacecraft" $spacecraft "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/spacecraft_flights/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `normal`, `detailed`  Example - [/spacecraft_flights/?mode=detailed](./?mode=detailed)  #### Filters Parameters - `spacecraft`  Example - [/spacecraft_flights/?spacecraft=289](./?spacecraft=289)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacecraft_flights/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacecraft_flights/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacecraft_flights/{id}/
# operationId: spacecraft_flights_retrieve
export def "230-spacecraft-flights get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, destination: string, mission_end: string, spacecraft: record<response_mode: string, id: int, url: string, name: string, serial_number: string, is_placeholder: bool, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, in_space: bool, time_in_space: string, time_docked: string, flights_count: int, mission_ends_count: int, status: record<id: int, name: string>, description: string, spacecraft_config: record<response_mode: string, id: int, url: string, name: string, type: record, agency: record, family: list, in_use: bool, image: record, capability: string, history: string, details: string, maiden_flight: string, height: float, diameter: float, human_rated: bool, crew_capacity: int, payload_capacity: int, payload_return_capacity: int, flight_life: string, wiki_link: string, info_link: string, spacecraft_flown: int, total_launch_count: int, successful_launches: int, failed_launches: int, attempted_landings: int, successful_landings: int, failed_landings: int, fastest_turnaround: string>, fastest_turnaround: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record<id: int, name: string, abbrev: string, description: string>, last_updated: string, net: string, net_precision: record<id: int, name: string, abbrev: string, description: string>, window_end: string, window_start: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record<response_mode: string, id: int, url: string, name: string, abbrev: string, type: record>, rocket: record<id: int, configuration: record>, mission: record<id: int, name: string, type: string, description: string, image: record, orbit: record, agencies: list, info_urls: list, vid_urls: list>, pad: record<id: int, url: string, active: bool, agencies: list, name: string, image: record, description: string, info_url: string, wiki_url: string, map_url: string, latitude: float, longitude: float, country: record, map_image: string, total_launch_count: int, orbital_launch_attempt_count: int, fastest_turnaround: string, location: record>, webcast_live: bool, program: list<record>, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record<id: int, name: string, active: bool, abbrev: string, description: string, location: record, longitude: float, latitude: float, image: record, successful_landings: int, attempted_landings: int, failed_landings: int, celestial_body: record>, type: record<id: int, name: string, abbrev: string, description: string>>, duration: string, turn_around_time: string, response_mode: string, launch_crew: table<id: int, role: record, astronaut: record>, onboard_crew: table<id: int, role: record, astronaut: record>, landing_crew: table<id: int, role: record, astronaut: record>, docking_events: table<id: int, url: string, docking: string, departure: string, docking_location: record, space_station_target: record, flight_vehicle_target: record, payload_flight_target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/spacecraft_flights/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/spacewalks/?mode=list](./?mode=list)  #### Filters Parameters - `astronaut__ids`, `day`, `end`, `end__gt`, `end__gte`, `end__lt`, `end__lte`, `event__ids`, `id`, `ids`, `launch__ids`, `month`, `name`, `name__contains`, `owner__ids`, `program__ids`, `program__name`, `program__name__contains`, `spacestation__ids`, `start__gt`, `start__gte`, `start__lt`, `start__lte`, `year`  Example - [/spacewalks/?program__name=Apollo](./?program__name=Apollo)  #### Search Fields searched - `crew__astronaut__name`, `location`, `name`, `program__name`  Example - [/spacewalks/?search=Hubble](./?search=Hubble)  #### Ordering Fields - `duration`, `end`, `id`, `name`, `start`  Example - [/spacewalks/?ordering=-duration](./?ordering=-duration)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacewalks/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacewalks/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacewalks/
# operationId: spacewalks_list
export def "230-spacewalks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --astronaut-ids: list # Multiple values may be separated by commas.
  --day: list # Multiple values may be separated by commas.
  --end: string # format: date-time
  --end-gt: string # format: date-time
  --end-gte: string # format: date-time
  --end-lt: string # format: date-time
  --end-lte: string # format: date-time
  --event-ids: list # Multiple values may be separated by commas.
  --id: int
  --ids: list # Multiple values may be separated by commas.
  --launch-ids: list # Multiple values may be separated by commas.
  --limit: int # Number of results to return per page.
  --mode: string@mode-completer # Specifies the level of detail for the response. Options are dynamically generated based on available serializers.
  --month: list # Multiple values may be separated by commas.
  --name: string
  --name-contains: string
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --owner-ids: list # Multiple values may be separated by commas.
  --program-ids: list # Multiple values may be separated by commas.
  --program-name: string
  --program-name--contains: string
  --search: string # A search term.
  --spacestation-ids: list # Multiple values may be separated by commas.
  --start-gt: string # format: date-time
  --start-gte: string # format: date-time
  --start-lt: string # format: date-time
  --start-lte: string # format: date-time
  --year: list # Multiple values may be separated by commas.
]: nothing -> record<count: int, next: string, previous: string, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "astronaut__ids" $astronaut_ids "csv") (serialize-qp "day" $day "csv") (serialize-qp "end" $end "scalar") (serialize-qp "end__gt" $end_gt "scalar") (serialize-qp "end__gte" $end_gte "scalar") (serialize-qp "end__lt" $end_lt "scalar") (serialize-qp "end__lte" $end_lte "scalar") (serialize-qp "event__ids" $event_ids "csv") (serialize-qp "id" $id "scalar") (serialize-qp "ids" $ids "csv") (serialize-qp "launch__ids" $launch_ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "month" $month "csv") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "owner__ids" $owner_ids "csv") (serialize-qp "program__ids" $program_ids "csv") (serialize-qp "program__name" $program_name "scalar") (serialize-qp "program__name__contains" $program_name__contains "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "spacestation__ids" $spacestation_ids "csv") (serialize-qp "start__gt" $start_gt "scalar") (serialize-qp "start__gte" $start_gte "scalar") (serialize-qp "start__lt" $start_lt "scalar") (serialize-qp "start__lte" $start_lte "scalar") (serialize-qp "year" $year "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/spacewalks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Modes Levels of detail in the response - `list`, `normal`, `detailed`  Example - [/spacewalks/?mode=list](./?mode=list)  #### Filters Parameters - `astronaut__ids`, `day`, `end`, `end__gt`, `end__gte`, `end__lt`, `end__lte`, `event__ids`, `id`, `ids`, `launch__ids`, `month`, `name`, `name__contains`, `owner__ids`, `program__ids`, `program__name`, `program__name__contains`, `spacestation__ids`, `start__gt`, `start__gte`, `start__lt`, `start__lte`, `year`  Example - [/spacewalks/?program__name=Apollo](./?program__name=Apollo)  #### Search Fields searched - `crew__astronaut__name`, `location`, `name`, `program__name`  Example - [/spacewalks/?search=Hubble](./?search=Hubble)  #### Ordering Fields - `duration`, `end`, `id`, `name`, `start`  Example - [/spacewalks/?ordering=-duration](./?ordering=-duration)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/spacewalks/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/spacewalks/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/spacewalks/{id}/
# operationId: spacewalks_retrieve
export def "230-spacewalks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response_mode: string, id: int, url: string, name: string, start: string, end: string, duration: string, location: string, crew: table<id: int, role: record, astronaut: record>, spacestation: record<id: int, url: string, name: string, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, status: record<id: int, name: string>, founded: string, deorbited: string, description: string, orbit: string, type: record<id: int, name: string>>, expedition: record<id: int, url: string, name: string, start: string, end: string, spacestation: record<id: int, url: string, name: string, image: record, status: record, founded: string, deorbited: string, description: string, orbit: string, type: record>, mission_patches: list<record>>, spacecraft_flight: record<id: int, url: string, destination: string, mission_end: string, spacecraft: record<response_mode: string, id: int, url: string, name: string, serial_number: string, is_placeholder: bool, image: record, in_space: bool, time_in_space: string, time_docked: string, flights_count: int, mission_ends_count: int, status: record, description: string, spacecraft_config: record, fastest_turnaround: string>, launch: record<id: string, url: string, name: string, response_mode: string, slug: string, launch_designator: string, status: record, last_updated: string, net: string, net_precision: record, window_end: string, window_start: string, image: record, infographic: string, probability: int, weather_concerns: string, failreason: string, hashtag: string, launch_service_provider: record, rocket: record, mission: record, pad: record, webcast_live: bool, program: list, orbital_launch_attempt_count: int, location_launch_attempt_count: int, pad_launch_attempt_count: int, agency_launch_attempt_count: int, orbital_launch_attempt_count_year: int, location_launch_attempt_count_year: int, pad_launch_attempt_count_year: int, agency_launch_attempt_count_year: int>, landing: record<id: int, url: string, attempt: bool, success: bool, description: string, downrange_distance: float, landing_location: record, type: record>, duration: string, turn_around_time: string, response_mode: string, launch_crew: list<record>, onboard_crew: list<record>, landing_crew: list<record>, docking_events: list<record>>, event: record<id: int, url: string, name: string, info_urls: list<record>, vid_urls: list<record>, image: record<id: int, name: string, image_url: string, thumbnail_url: string, credit: string, license: record, single_use: bool, variants: list>, date: string, slug: string, type: record<id: int, name: string>, description: string, webcast_live: bool, location: string, date_precision: record<id: int, name: string, abbrev: string, description: string>>, program: table<response_mode: string, id: int, url: string, name: string, image: record, info_url: string, wiki_url: string, description: string, agencies: list, start_date: string, end_date: string, mission_patches: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/spacewalks/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Filters Parameters - `created_on`, `launch`, `launch__launch_service_provider`, `program`  Example - [/updates/?launch__launch_service_provider=121](./?launch__launch_service_provider=121)  #### Ordering Fields - `created_on`  Example - [/updates/?ordering=-created_on](./?ordering=-created_on)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/updates/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/updates/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/updates/
# operationId: updates_list
export def "230-updates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-on: string # format: date-time
  --launch: string # format: uuid
  --launch-launch-service-provider: int
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --ordering: string # Which field to use when ordering the results.
  --program: int
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_on" $created_on "scalar") (serialize-qp "launch" $launch "scalar") (serialize-qp "launch__launch_service_provider" $launch_launch_service_provider "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "program" $program "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2.3.0/updates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# #### Filters Parameters - `created_on`, `launch`, `launch__launch_service_provider`, `program`  Example - [/updates/?launch__launch_service_provider=121](./?launch__launch_service_provider=121)  #### Ordering Fields - `created_on`  Example - [/updates/?ordering=-created_on](./?ordering=-created_on)  #### Number of results Use `limit` to control the number of objects in the response (max 100)  Example - [/updates/?limit=2](./?limit=2)  #### Format Switch to JSON output - [/updates/?format=json](./?format=json)  #### Help Find all the FAQs and support links on the documentation homepage - [ll.thespacedevs.com/docs](https://ll.thespacedevs.com/docs/)
#
# GET /2.3.0/updates/{id}/
# operationId: updates_retrieve
export def "230-updates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, profile_image: string, comment: string, info_url: string, created_by: string, created_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2.3.0/updates/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
