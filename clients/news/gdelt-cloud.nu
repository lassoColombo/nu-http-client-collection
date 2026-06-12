# Auto-generated client for GDELT Cloud API v2 v2.0.0
# Source: https://docs.gdeltcloud.com/api-reference/openapi-v2.json
# Auth: --token flag or $env.GDELT_CLOUD_API_V2_TOKEN

const BASE_URL = "https://gdeltcloud.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GDELT_CLOUD_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://gdeltcloud.com" "http://localhost:3000"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def event-family-completer [] { ["cameoplus" "conflict"] }
def domain-completer [] { ["CORPORATE" "CRIME" "DEMOGRAPHIC" "ECONOMIC" "ENVIRONMENT" "HEALTH" "INFORMATION" "INFRASTRUCTURE" "POLITICAL" "TECHNOLOGY"] }
def sort-completer [] { ["recent" "significance"] }
def group-by-completer [] { ["category" "continent" "country" "date" "region" "subcategory"] }
def type-completer [] { ["organization" "person"] }
def asset-class-completer [] { ["all" "fixed" "mobile"] }
def sort-completer-1 [] { ["capacity_asc" "capacity_desc" "name" "recent" "start_year_asc" "start_year_desc"] }
def group-by-completer-1 [] { ["continent" "country" "fuel" "region" "start_year_decade" "status" "tier" "tracker"] }
def time-window-completer [] { ["24h" "30d" "6h" "72h" "7d"] }
def baseline-window-completer [] { ["14d" "30d" "7d"] }
def audience-completer [] { ["analyst" "executive" "operator"] }
def depth-completer [] { ["detailed" "skim" "standard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "events search-events-v2" } } | get name | first)
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

# Search Events
#
# GET /api/v2/events
# operationId: search-events-v2
@deprecated --flag event-family
@deprecated --flag domain
export def "events search-events-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-start: string # Inclusive start date in YYYY-MM-DD, matched against the event or story date. Alias `start_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-11)
  --date-end: string # Inclusive end date in YYYY-MM-DD, matched against the event or story date. Alias `end_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-17)
  --country: string # Documented input is a plain English country name. ISO-3 and legacy FIPS aliases are accepted; output normalizes to the country name. (e.g. Lebanon)
  --region: string # Plain English region such as `Middle East`, `Western Africa`, `South Asia`, or `Europe`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Middle East)
  --continent: string # Plain English continent such as `Africa`, `Asia`, `Europe`, `North America`, `South America`, or `Oceania`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Africa)
  --admin1: string # Optional state/province/admin1 location filter. Discover valid values through `/api/v2/geo/admin1`. Filters Event or Story location only, not actor origin. (e.g. Beirut)
  --bbox: string # Geographic bounding box on event latitude/longitude, formatted as lat_min,lon_min,lat_max,lon_max. Use for sub-country precision (e.g. a strait or port area). Combine with country or use alone; lat must be in [-90,90] and lon in [-180,180]. (e.g. 11.5,42.5,13.5,44.5)
  --event-family: string@event-family-completer # Deprecated legacy filter. Prefer `category`, which implies Conflict vs CAMEO+. Still accepted for backwards compatibility. (DEPRECATED)
  --category: string # Stable linked Event product category. Use a Conflict event type such as `Battles`, `Protests`, or `Explosions/Remote violence`, or one CAMEO+ domain such as `POLITICAL`, `INFRASTRUCTURE`, or `CRIME`; values may be single or comma-separated. On Story endpoints this filters linked Event evidence. Use `story_category` only for legacy Story-cluster categories such as `conflict_security`. (e.g. Battles)
  --subcategory: string # More specific linked Event subtype, CAMEO+ event description, or CAMEO+ code. Requires parent `category` and must belong to at least one selected category. For Conflict categories, use sub-event types such as `Armed clash`, `Peaceful protest`, or `Air/drone strike`. Validation errors include accepted_values, nearest_values when practical, and a corrected example. (e.g. Armed clash)
  --domain: string@domain-completer # Deprecated legacy CAMEO+ domain enum. Prefer `category`/`categories` for new integrations; retained for backwards compatibility. (DEPRECATED)
  --search: string # Free-text semantic search. The API ranks the filtered candidate set by semantic similarity against stored Event or Story representations. It is not a lexical keyword filter and has no public similarity cutoff. (e.g. attacks on energy infrastructure)
  --has-fatalities: oneof<nothing, bool> # Set `true` for fatality monitoring. v2 intentionally exposes only this boolean fatality filter. (e.g. true)
  --civilian-targeting: oneof<nothing, bool> # Filter Conflict-linked evidence by ACLED civilian_targeting. `true` keeps records where civilians are the primary target; `false` excludes those records.
  --significance-min: float # Significance minimum filter. Composite 0-1 Event significance score.
  --significance-max: float # Significance maximum filter. Composite 0-1 Event significance score.
  --confidence-min: float # Confidence minimum filter. Model confidence for the structured Event record.
  --confidence-max: float # Confidence maximum filter. Model confidence for the structured Event record.
  --goldstein-scale-min: float # Goldstein scale minimum filter. Signed Goldstein scale. Applies to Conflict Events and CAMEO+ POLITICAL Events where meaningful.
  --goldstein-scale-max: float # Goldstein scale maximum filter. Signed Goldstein scale. Applies to Conflict Events and CAMEO+ POLITICAL Events where meaningful.
  --goldstein-severity-min: float # Goldstein severity minimum filter. Absolute Goldstein intensity, regardless of positive or negative valence.
  --goldstein-severity-max: float # Goldstein severity maximum filter. Absolute Goldstein intensity, regardless of positive or negative valence.
  --magnitude-min: float # Magnitude minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --magnitude-max: float # Magnitude maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --systemic-importance-min: float # Systemic importance minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --systemic-importance-max: float # Systemic importance maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --propagation-potential-min: float # Propagation potential minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --propagation-potential-max: float # Propagation potential maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --market-sensitivity-min: float # Market sensitivity minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --market-sensitivity-max: float # Market sensitivity maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --qp-sort: string@sort-completer # `significance` is the default analyst ranking. Use `recent` when freshness matters more than importance. (default: significance, e.g. significance)
  --limit: int # Number of records to return. (default: 25, e.g. 25)
  --cursor: string # Pagination cursor from `pagination.next_cursor`.
]: nothing -> record<success: bool, pagination: record<limit: int, cursor: string, next_cursor: string>, data: table<id: string, url: string, primary_story_url: string, family: string, title: string, summary: string, image_url: string, event_date: string, category: string, subcategory: string, domain: string, event_code: string, geo: record, geo_context: record, actors: list, metrics: record, has_fatalities: bool, fatalities: int, story_refs: list, entity_refs: list, top_articles: list, civilian_targeting: bool, civilian_targeting_label: string>, sort: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "admin1" $admin1 "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "event_family" $event_family "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "subcategory" $subcategory "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "has_fatalities" $has_fatalities "scalar") (serialize-qp "civilian_targeting" $civilian_targeting "scalar") (serialize-qp "significance_min" $significance_min "scalar") (serialize-qp "significance_max" $significance_max "scalar") (serialize-qp "confidence_min" $confidence_min "scalar") (serialize-qp "confidence_max" $confidence_max "scalar") (serialize-qp "goldstein_scale_min" $goldstein_scale_min "scalar") (serialize-qp "goldstein_scale_max" $goldstein_scale_max "scalar") (serialize-qp "goldstein_severity_min" $goldstein_severity_min "scalar") (serialize-qp "goldstein_severity_max" $goldstein_severity_max "scalar") (serialize-qp "magnitude_min" $magnitude_min "scalar") (serialize-qp "magnitude_max" $magnitude_max "scalar") (serialize-qp "systemic_importance_min" $systemic_importance_min "scalar") (serialize-qp "systemic_importance_max" $systemic_importance_max "scalar") (serialize-qp "propagation_potential_min" $propagation_potential_min "scalar") (serialize-qp "propagation_potential_max" $propagation_potential_max "scalar") (serialize-qp "market_sensitivity_min" $market_sensitivity_min "scalar") (serialize-qp "market_sensitivity_max" $market_sensitivity_max "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Event
#
# GET /api/v2/events/{event_id}
# operationId: get-event-v2
export def "events get-event-v2" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: string, url: string, primary_story_url: string, family: string, title: string, summary: string, image_url: string, event_date: string, category: string, subcategory: string, domain: string, event_code: string, geo: record<country: string, region: string, continent: string, admin1: string, location: string, latitude: float, longitude: float>, geo_context: record<location_country: string, actor_origin_countries: list>, actors: list<record>, metrics: record<significance: float, goldstein_scale: float, magnitude: float, systemic_importance: float, propagation_potential: float, market_sensitivity: float, confidence: float, article_count: int>, has_fatalities: bool, fatalities: int, story_refs: list<record>, entity_refs: list<record>, top_articles: list<record>, civilian_targeting: bool, civilian_targeting_label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize Events
#
# GET /api/v2/events/summary
# operationId: summarize-events-v2
@deprecated --flag event-family
@deprecated --flag domain
export def "events-summary summarize-events-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-by: string@group-by-completer # Summary grouping dimension. For Events, category is Conflict event type or CAMEO+ domain and subcategory is Conflict sub-event type or CAMEO+ event description/code. For Stories, category/subcategory grouping uses linked Event taxonomy; use story_category only as a Story-cluster filter. (e.g. date)
  --date-start: string # Inclusive start date in YYYY-MM-DD, matched against the event or story date. Alias `start_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-11)
  --date-end: string # Inclusive end date in YYYY-MM-DD, matched against the event or story date. Alias `end_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-17)
  --country: string # Documented input is a plain English country name. ISO-3 and legacy FIPS aliases are accepted; output normalizes to the country name. (e.g. Lebanon)
  --region: string # Plain English region such as `Middle East`, `Western Africa`, `South Asia`, or `Europe`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Middle East)
  --continent: string # Plain English continent such as `Africa`, `Asia`, `Europe`, `North America`, `South America`, or `Oceania`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Africa)
  --admin1: string # Optional state/province/admin1 location filter. Discover valid values through `/api/v2/geo/admin1`. Filters Event or Story location only, not actor origin. (e.g. Beirut)
  --bbox: string # Geographic bounding box on event latitude/longitude, formatted as lat_min,lon_min,lat_max,lon_max. Use for sub-country precision (e.g. a strait or port area). Combine with country or use alone; lat must be in [-90,90] and lon in [-180,180]. (e.g. 11.5,42.5,13.5,44.5)
  --event-family: string@event-family-completer # Deprecated legacy filter. Prefer `category`, which implies Conflict vs CAMEO+. Still accepted for backwards compatibility. (DEPRECATED)
  --category: string # Stable linked Event product category. Use a Conflict event type such as `Battles`, `Protests`, or `Explosions/Remote violence`, or one CAMEO+ domain such as `POLITICAL`, `INFRASTRUCTURE`, or `CRIME`; values may be single or comma-separated. On Story endpoints this filters linked Event evidence. Use `story_category` only for legacy Story-cluster categories such as `conflict_security`. (e.g. Battles)
  --subcategory: string # More specific linked Event subtype, CAMEO+ event description, or CAMEO+ code. Requires parent `category` and must belong to at least one selected category. For Conflict categories, use sub-event types such as `Armed clash`, `Peaceful protest`, or `Air/drone strike`. Validation errors include accepted_values, nearest_values when practical, and a corrected example. (e.g. Armed clash)
  --domain: string@domain-completer # Deprecated legacy CAMEO+ domain enum. Prefer `category`/`categories` for new integrations; retained for backwards compatibility. (DEPRECATED)
  --has-fatalities: oneof<nothing, bool> # Set `true` for fatality monitoring. v2 intentionally exposes only this boolean fatality filter. (e.g. true)
  --civilian-targeting: oneof<nothing, bool> # Filter Conflict-linked evidence by ACLED civilian_targeting. `true` keeps records where civilians are the primary target; `false` excludes those records.
  --significance-min: float # Significance minimum filter. Composite 0-1 Event significance score.
  --significance-max: float # Significance maximum filter. Composite 0-1 Event significance score.
  --confidence-min: float # Confidence minimum filter. Model confidence for the structured Event record.
  --confidence-max: float # Confidence maximum filter. Model confidence for the structured Event record.
  --goldstein-scale-min: float # Goldstein scale minimum filter. Signed Goldstein scale. Applies to Conflict Events and CAMEO+ POLITICAL Events where meaningful.
  --goldstein-scale-max: float # Goldstein scale maximum filter. Signed Goldstein scale. Applies to Conflict Events and CAMEO+ POLITICAL Events where meaningful.
  --goldstein-severity-min: float # Goldstein severity minimum filter. Absolute Goldstein intensity, regardless of positive or negative valence.
  --goldstein-severity-max: float # Goldstein severity maximum filter. Absolute Goldstein intensity, regardless of positive or negative valence.
  --magnitude-min: float # Magnitude minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --magnitude-max: float # Magnitude maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --systemic-importance-min: float # Systemic importance minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --systemic-importance-max: float # Systemic importance maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --propagation-potential-min: float # Propagation potential minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --propagation-potential-max: float # Propagation potential maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --market-sensitivity-min: float # Market sensitivity minimum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --market-sensitivity-max: float # Market sensitivity maximum filter. CAMEO+ detail metric. Only matches Events with CAMEO+ scores.
  --limit: int # Number of summary buckets to return. (default: 50, e.g. 50)
]: nothing -> record<success: bool, data: table<key: string, group_by: string, event_count: int, conflict_event_count: int, cameoplus_event_count: int, fatality_event_count: int, fatalities: int, fatality_event_rate: float, country_count: int, region_count: int, article_count: int, avg_article_count: float, max_article_count: int, avg_significance: float, max_significance: float, min_significance: float, avg_goldstein_scale: float, metrics: record, metric_stats: record, min_article_count: int, min_goldstein_scale: float, max_goldstein_scale: float, avg_goldstein_severity: float, min_goldstein_severity: float, max_goldstein_severity: float, avg_magnitude: float, min_magnitude: float, max_magnitude: float, avg_systemic_importance: float, min_systemic_importance: float, max_systemic_importance: float, avg_propagation_potential: float, min_propagation_potential: float, max_propagation_potential: float, avg_market_sensitivity: float, min_market_sensitivity: float, max_market_sensitivity: float, avg_confidence: float, min_confidence: float, max_confidence: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "admin1" $admin1 "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "event_family" $event_family "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "subcategory" $subcategory "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "has_fatalities" $has_fatalities "scalar") (serialize-qp "civilian_targeting" $civilian_targeting "scalar") (serialize-qp "significance_min" $significance_min "scalar") (serialize-qp "significance_max" $significance_max "scalar") (serialize-qp "confidence_min" $confidence_min "scalar") (serialize-qp "confidence_max" $confidence_max "scalar") (serialize-qp "goldstein_scale_min" $goldstein_scale_min "scalar") (serialize-qp "goldstein_scale_max" $goldstein_scale_max "scalar") (serialize-qp "goldstein_severity_min" $goldstein_severity_min "scalar") (serialize-qp "goldstein_severity_max" $goldstein_severity_max "scalar") (serialize-qp "magnitude_min" $magnitude_min "scalar") (serialize-qp "magnitude_max" $magnitude_max "scalar") (serialize-qp "systemic_importance_min" $systemic_importance_min "scalar") (serialize-qp "systemic_importance_max" $systemic_importance_max "scalar") (serialize-qp "propagation_potential_min" $propagation_potential_min "scalar") (serialize-qp "propagation_potential_max" $propagation_potential_max "scalar") (serialize-qp "market_sensitivity_min" $market_sensitivity_min "scalar") (serialize-qp "market_sensitivity_max" $market_sensitivity_max "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/events/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Stories
#
# GET /api/v2/stories
# operationId: search-stories-v2
@deprecated --flag event-category
@deprecated --flag domain
export def "stories search-stories-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-start: string # Inclusive start date in YYYY-MM-DD, matched against the event or story date. Alias `start_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-11)
  --date-end: string # Inclusive end date in YYYY-MM-DD, matched against the event or story date. Alias `end_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-17)
  --country: string # Documented input is a plain English country name. ISO-3 and legacy FIPS aliases are accepted; output normalizes to the country name. (e.g. Lebanon)
  --region: string # Plain English region such as `Middle East`, `Western Africa`, `South Asia`, or `Europe`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Middle East)
  --continent: string # Plain English continent such as `Africa`, `Asia`, `Europe`, `North America`, `South America`, or `Oceania`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Africa)
  --admin1: string # Optional state/province/admin1 location filter. Discover valid values through `/api/v2/geo/admin1`. Filters Event or Story location only, not actor origin. (e.g. Beirut)
  --bbox: string # Geographic bounding box on event latitude/longitude, formatted as lat_min,lon_min,lat_max,lon_max. Use for sub-country precision (e.g. a strait or port area). Combine with country or use alone; lat must be in [-90,90] and lon in [-180,180]. (e.g. 11.5,42.5,13.5,44.5)
  --category: string # Stable linked Event product category. Use a Conflict event type such as `Battles`, `Protests`, or `Explosions/Remote violence`, or one CAMEO+ domain such as `POLITICAL`, `INFRASTRUCTURE`, or `CRIME`; values may be single or comma-separated. On Story endpoints this filters linked Event evidence. Use `story_category` only for legacy Story-cluster categories such as `conflict_security`. (e.g. Battles)
  --story-category: string # Legacy Story-cluster category filter such as `conflict_security` or `cameoplus_infrastructure`. Prefer linked Event `category`/`subcategory` for product taxonomy filtering. (e.g. conflict_security)
  --event-category: string # Deprecated alias for `category` on Story endpoints. Prefer `category=Battles` or a CAMEO+ domain such as `category=CRIME`. (DEPRECATED)
  --subcategory: string # More specific linked Event subtype, CAMEO+ event description, or CAMEO+ code. Requires parent `category` and must belong to at least one selected category. For Conflict categories, use sub-event types such as `Armed clash`, `Peaceful protest`, or `Air/drone strike`. Validation errors include accepted_values, nearest_values when practical, and a corrected example. (e.g. Armed clash)
  --domain: string@domain-completer # Deprecated legacy CAMEO+ domain enum. Prefer `category`/`categories` for new integrations; retained for backwards compatibility. (DEPRECATED)
  --search: string # Free-text semantic search. The API ranks the filtered candidate set by semantic similarity against stored Event or Story representations. It is not a lexical keyword filter and has no public similarity cutoff. (e.g. attacks on energy infrastructure)
  --has-events: oneof<nothing, bool> # For Stories, set `true` to require linked structured Events or `false` for Stories without linked Events. (e.g. true)
  --has-fatalities: oneof<nothing, bool> # Set `true` for fatality monitoring. v2 intentionally exposes only this boolean fatality filter. (e.g. true)
  --civilian-targeting: oneof<nothing, bool> # Filter Conflict-linked evidence by ACLED civilian_targeting. `true` keeps records where civilians are the primary target; `false` excludes those records.
  --article-count-min: int # Minimum Story article count. (e.g. 2)
  --article-count-max: int # Maximum Story article count. (e.g. 25)
  --qp-sort: string@sort-completer # `significance` is the default analyst ranking. Use `recent` when freshness matters more than importance. (default: significance, e.g. significance)
  --limit: int # Number of records to return. (default: 25, e.g. 25)
  --cursor: string # Pagination cursor from `pagination.next_cursor`.
]: nothing -> record<success: bool, pagination: record<limit: int, cursor: string, next_cursor: string>, data: table<id: string, url: string, title: string, image_url: string, story_date: string, category: string, subcategory: string, geo: record, geo_context: record, metrics: record, has_events: bool, has_fatalities: bool, fatalities: int, linked_events: list, entity_refs: list, top_articles: list, has_civilian_targeting: bool>, sort: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "admin1" $admin1 "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "story_category" $story_category "scalar") (serialize-qp "event_category" $event_category "scalar") (serialize-qp "subcategory" $subcategory "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "has_events" $has_events "scalar") (serialize-qp "has_fatalities" $has_fatalities "scalar") (serialize-qp "civilian_targeting" $civilian_targeting "scalar") (serialize-qp "article_count_min" $article_count_min "scalar") (serialize-qp "article_count_max" $article_count_max "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Story
#
# GET /api/v2/stories/{story_id}
# operationId: get-story-v2
export def "stories get-story-v2" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: string, url: string, title: string, image_url: string, story_date: string, category: string, subcategory: string, geo: record<country: string, region: string, continent: string, admin1: string, location: string, latitude: float, longitude: float>, geo_context: record<location_country: string, actor_origin_countries: list>, metrics: record<significance: float, article_count: int, linked_event_count: int, max_linked_event_significance: float, civilian_targeting_event_count: int>, has_events: bool, has_fatalities: bool, fatalities: int, linked_events: list<record>, entity_refs: list<record>, top_articles: list<record>, has_civilian_targeting: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/stories/($story_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Story Articles
#
# GET /api/v2/stories/{story_id}/articles
# operationId: get-story-articles-v2
export def "stories-articles get-story-articles-v2" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of records to return. (default: 25, e.g. 25)
  --cursor: string # Pagination cursor from `pagination.next_cursor`.
]: nothing -> record<success: bool, pagination: record<limit: int, cursor: string, next_cursor: string>, data: table<id: string, url: string, title: string, domain: string, domain_avatar_url: string, image_url: string, article_date: string, rank: int, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/stories/($story_id)/articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize Stories
#
# GET /api/v2/stories/summary
# operationId: summarize-stories-v2
@deprecated --flag event-category
@deprecated --flag domain
export def "stories-summary summarize-stories-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-by: string@group-by-completer # Summary grouping dimension. For Events, category is Conflict event type or CAMEO+ domain and subcategory is Conflict sub-event type or CAMEO+ event description/code. For Stories, category/subcategory grouping uses linked Event taxonomy; use story_category only as a Story-cluster filter. (e.g. date)
  --date-start: string # Inclusive start date in YYYY-MM-DD, matched against the event or story date. Alias `start_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-11)
  --date-end: string # Inclusive end date in YYYY-MM-DD, matched against the event or story date. Alias `end_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-17)
  --country: string # Documented input is a plain English country name. ISO-3 and legacy FIPS aliases are accepted; output normalizes to the country name. (e.g. Lebanon)
  --region: string # Plain English region such as `Middle East`, `Western Africa`, `South Asia`, or `Europe`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Middle East)
  --continent: string # Plain English continent such as `Africa`, `Asia`, `Europe`, `North America`, `South America`, or `Oceania`. The backend expands this value to an ISO-3 country list; Events match location and actor-origin countries, while Stories match linked Event primary location. (e.g. Africa)
  --admin1: string # Optional state/province/admin1 location filter. Discover valid values through `/api/v2/geo/admin1`. Filters Event or Story location only, not actor origin. (e.g. Beirut)
  --bbox: string # Geographic bounding box on event latitude/longitude, formatted as lat_min,lon_min,lat_max,lon_max. Use for sub-country precision (e.g. a strait or port area). Combine with country or use alone; lat must be in [-90,90] and lon in [-180,180]. (e.g. 11.5,42.5,13.5,44.5)
  --category: string # Stable linked Event product category. Use a Conflict event type such as `Battles`, `Protests`, or `Explosions/Remote violence`, or one CAMEO+ domain such as `POLITICAL`, `INFRASTRUCTURE`, or `CRIME`; values may be single or comma-separated. On Story endpoints this filters linked Event evidence. Use `story_category` only for legacy Story-cluster categories such as `conflict_security`. (e.g. Battles)
  --story-category: string # Legacy Story-cluster category filter such as `conflict_security` or `cameoplus_infrastructure`. Prefer linked Event `category`/`subcategory` for product taxonomy filtering. (e.g. conflict_security)
  --event-category: string # Deprecated alias for `category` on Story endpoints. Prefer `category=Battles` or a CAMEO+ domain such as `category=CRIME`. (DEPRECATED)
  --subcategory: string # More specific linked Event subtype, CAMEO+ event description, or CAMEO+ code. Requires parent `category` and must belong to at least one selected category. For Conflict categories, use sub-event types such as `Armed clash`, `Peaceful protest`, or `Air/drone strike`. Validation errors include accepted_values, nearest_values when practical, and a corrected example. (e.g. Armed clash)
  --domain: string@domain-completer # Deprecated legacy CAMEO+ domain enum. Prefer `category`/`categories` for new integrations; retained for backwards compatibility. (DEPRECATED)
  --has-events: oneof<nothing, bool> # For Stories, set `true` to require linked structured Events or `false` for Stories without linked Events. (e.g. true)
  --has-fatalities: oneof<nothing, bool> # Set `true` for fatality monitoring. v2 intentionally exposes only this boolean fatality filter. (e.g. true)
  --civilian-targeting: oneof<nothing, bool> # Filter Conflict-linked evidence by ACLED civilian_targeting. `true` keeps records where civilians are the primary target; `false` excludes those records.
  --article-count-min: int # Minimum Story article count. (e.g. 2)
  --article-count-max: int # Maximum Story article count. (e.g. 25)
  --limit: int # Number of summary buckets to return. (default: 50, e.g. 50)
]: nothing -> record<success: bool, data: table<key: string, group_by: string, story_count: int, article_count: int, avg_article_count: float, max_article_count: int, stories_with_events: int, linked_event_count: int, avg_linked_event_count: float, max_linked_event_count: int, stories_with_fatalities: int, fatalities: int, fatality_story_rate: float, avg_significance: float, max_significance: float, min_significance: float, metrics: record, metric_stats: record, min_article_count: int, story_only_count: int, min_linked_event_count: int, avg_linked_event_significance: float, min_linked_event_significance: float, max_linked_event_significance: float, avg_linked_event_goldstein_scale: float, min_linked_event_goldstein_scale: float, max_linked_event_goldstein_scale: float, avg_linked_event_goldstein_severity: float, min_linked_event_goldstein_severity: float, max_linked_event_goldstein_severity: float, avg_linked_event_magnitude: float, min_linked_event_magnitude: float, max_linked_event_magnitude: float, avg_linked_event_systemic_importance: float, min_linked_event_systemic_importance: float, max_linked_event_systemic_importance: float, avg_linked_event_propagation_potential: float, min_linked_event_propagation_potential: float, max_linked_event_propagation_potential: float, avg_linked_event_market_sensitivity: float, min_linked_event_market_sensitivity: float, max_linked_event_market_sensitivity: float, avg_linked_event_confidence: float, min_linked_event_confidence: float, max_linked_event_confidence: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "admin1" $admin1 "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "story_category" $story_category "scalar") (serialize-qp "event_category" $event_category "scalar") (serialize-qp "subcategory" $subcategory "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "has_events" $has_events "scalar") (serialize-qp "has_fatalities" $has_fatalities "scalar") (serialize-qp "civilian_targeting" $civilian_targeting "scalar") (serialize-qp "article_count_min" $article_count_min "scalar") (serialize-qp "article_count_max" $article_count_max "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/stories/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Entities
#
# GET /api/v2/entities
# operationId: search-entities-v2
@deprecated --flag event-family
@deprecated --flag domain
export def "entities search-entities-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Entity name or phrase to search for.
  --type: string@type-completer # Optional entity type filter.
  --date-start: string # Inclusive start date in YYYY-MM-DD, matched against the event or story date. Alias `start_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-11)
  --date-end: string # Inclusive end date in YYYY-MM-DD, matched against the event or story date. Alias `end_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-17)
  --event-family: string@event-family-completer # Deprecated legacy filter. Prefer `category`, which implies Conflict vs CAMEO+. Still accepted for backwards compatibility. (DEPRECATED)
  --category: string # Stable linked Event product category. Use a Conflict event type such as `Battles`, `Protests`, or `Explosions/Remote violence`, or one CAMEO+ domain such as `POLITICAL`, `INFRASTRUCTURE`, or `CRIME`; values may be single or comma-separated. On Story endpoints this filters linked Event evidence. Use `story_category` only for legacy Story-cluster categories such as `conflict_security`. (e.g. Battles)
  --subcategory: string # More specific linked Event subtype, CAMEO+ event description, or CAMEO+ code. Requires parent `category` and must belong to at least one selected category. For Conflict categories, use sub-event types such as `Armed clash`, `Peaceful protest`, or `Air/drone strike`. Validation errors include accepted_values, nearest_values when practical, and a corrected example. (e.g. Armed clash)
  --domain: string@domain-completer # Deprecated legacy CAMEO+ domain enum. Prefer `category`/`categories` for new integrations; retained for backwards compatibility. (DEPRECATED)
  --has-fatalities: oneof<nothing, bool> # Set `true` for fatality monitoring. v2 intentionally exposes only this boolean fatality filter. (e.g. true)
  --civilian-targeting: oneof<nothing, bool> # Filter Conflict-linked evidence by ACLED civilian_targeting. `true` keeps records where civilians are the primary target; `false` excludes those records.
  --qp-sort: string@sort-completer # `significance` is the default analyst ranking. Use `recent` when freshness matters more than importance. (default: significance, e.g. significance)
  --limit: int # Number of records to return. (default: 25, e.g. 25)
  --cursor: string # Pagination cursor from `pagination.next_cursor`.
]: nothing -> record<success: bool, pagination: record<limit: int, cursor: string, next_cursor: string>, data: table<id: string, url: string, name: string, type: string, wikipedia_url: string, latest_date: string, image_url: string, avatar_url: string, wikipedia: record, metrics: record, story_refs: list, event_refs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "event_family" $event_family "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "subcategory" $subcategory "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "has_fatalities" $has_fatalities "scalar") (serialize-qp "civilian_targeting" $civilian_targeting "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Entity
#
# GET /api/v2/entities/{entity_id}
# operationId: get-entity-v2
export def "entities get-entity-v2" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date-start: string # Inclusive start date in YYYY-MM-DD, matched against the event or story date. Alias `start_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-11)
  --date-end: string # Inclusive end date in YYYY-MM-DD, matched against the event or story date. Alias `end_date` is accepted for compatibility. Omit dates for the default recent window; explicit windows may not exceed 30 days. (format: date, e.g. 2026-04-17)
  --limit: int # Number of linked records to return. (default: 10, e.g. 10)
]: nothing -> record<success: bool, data: record<id: string, url: string, name: string, type: string, wikipedia_url: string, latest_date: string, image_url: string, avatar_url: string, wikipedia: record, metrics: record<article_count: int, story_count: int, event_count: int>, story_refs: list<record>, event_refs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/entities/($entity_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Admin1 Values
#
# GET /api/v2/geo/admin1
# operationId: list-admin1-v2
export def "geo-admin1 list-admin1-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # Plain English country name, for example `France` or `United States`. ISO-3 and legacy FIPS aliases are accepted. (e.g. France)
]: nothing -> record<success: bool, country: string, admin1: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/geo/admin1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Energy Assets
#
# GET /api/v2/energy/assets
# operationId: search-energy-assets-v2
export def "energy-assets search-energy-assets-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tracker: string # Comma-separated GEM trackers. Valid values: coal_plants, coal_mines, coal_terminals, oil_gas_plants, oil_gas_extraction, lng_terminals, nuclear, geothermal, bioenergy, hydropower, solar, wind, gas_pipelines, oil_pipelines, lng_carriers. Omit for all trackers. (e.g. coal_plants,solar)
  --country: string # Plain English country name, ISO-3, or legacy FIPS alias. Filters primary or secondary country for cross-border assets. (e.g. United States)
  --region: string # Plain English region. Expands to the same ISO-3 country list used by V2 Events. (e.g. Middle East)
  --continent: string # Plain English continent. Expands to the same ISO-3 country list used by V2 Events. (e.g. Asia)
  --status: string # Comma-separated GEM status values. Common values include operating, construction, pre-construction, permitted, announced, proposed, shelved, cancelled, retired, and mothballed. (e.g. operating,construction)
  --operating-only: oneof<nothing, bool> # Shorthand for status=operating. (default: false, e.g. true)
  --tier: string # Comma-separated within-tracker tier values such as main, utility, distributed, below_threshold, closed, or sub_threshold. (e.g. main,utility)
  --fuel: string # Comma-separated fuel values. Matches the tracker-native fuel string or normalized cross-tracker fuel where populated. (e.g. coal,solar)
  --capacity-mw-min: float # Minimum MW capacity. Meaningful for power-generation trackers only. (e.g. 100)
  --capacity-mw-max: float # Maximum MW capacity. Meaningful for power-generation trackers only. (e.g. 5000)
  --start-year-min: int # Minimum asset start year. (e.g. 2000)
  --start-year-max: int # Maximum asset start year. (e.g. 2030)
  --retired-year-min: int # Minimum asset retired year. (e.g. 2000)
  --retired-year-max: int # Maximum asset retired year. (e.g. 2030)
  --owner-search: string # Case-insensitive substring match against the raw owner string. (e.g. ExxonMobil)
  --owner-entity-id: string # GEM Entity ID. Returns assets where the entity appears in owners, operators, or parents. (e.g. E100002021305)
  --bbox: string # Viewport filter formatted as lat_min,lon_min,lat_max,lon_max. (e.g. 30,-105,33,-100)
  --near: string # Proximity filter formatted as lat,lon,radius_km. (e.g. 31.16,-102.9,50)
  --search: string # Case-insensitive substring match against asset name. (e.g. Ranch Energy)
  --asset-class: string@asset-class-completer # Asset class. The default fixed excludes mobile LNG carriers; use mobile or all for vessels. (default: fixed, e.g. fixed)
  --qp-sort: string@sort-completer-1 # List sort order. (default: capacity_desc, e.g. capacity_desc)
  --limit: int # Number of asset cards to return. (default: 25, e.g. 25)
  --cursor: string # Pagination cursor from pagination.next_cursor. (e.g. 25)
]: nothing -> record<success: bool, data: table<id: string, gem_id: string, tracker: string, tier: string, asset_class: string, name: string, name_local: string, name_other: string, status: string, status_detail: string, start_year: int, retired_year: int, fuel: string, capacity: record, geo: record, owners_raw: string, owners: list, operators_raw: string, operators: list, parents_raw: string, parents: list, wiki_url: string, last_updated: string, detail_url: string, api_url: string>, pagination: record<limit: int, cursor: string, next_cursor: string>, sort: string, filters_echo: record<tracker: list<string>, country_iso3: list<string>, status: list<string>, tier: list<string>, fuel: list<string>, capacity_mw_min: float, capacity_mw_max: float, start_year_min: float, start_year_max: float, owner_search: string, owner_entity_id: string, bbox: record<latMin: float, lonMin: float, latMax: float, lonMax: float>, near: record<lat: float, lon: float, radiusKm: float>, search: string, operating_only: bool, asset_class: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tracker" $tracker "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "operating_only" $operating_only "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "fuel" $fuel "scalar") (serialize-qp "capacity_mw_min" $capacity_mw_min "scalar") (serialize-qp "capacity_mw_max" $capacity_mw_max "scalar") (serialize-qp "start_year_min" $start_year_min "scalar") (serialize-qp "start_year_max" $start_year_max "scalar") (serialize-qp "retired_year_min" $retired_year_min "scalar") (serialize-qp "retired_year_max" $retired_year_max "scalar") (serialize-qp "owner_search" $owner_search "scalar") (serialize-qp "owner_entity_id" $owner_entity_id "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "near" $near "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "asset_class" $asset_class "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/energy/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize Energy Assets
#
# GET /api/v2/energy/assets/summary
# operationId: summarize-energy-assets-v2
export def "energy-assets-summary summarize-energy-assets-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group-by: string@group-by-completer-1 # Summary aggregation dimension. (default: tracker, e.g. tracker)
  --tracker: string # Comma-separated GEM trackers. Valid values: coal_plants, coal_mines, coal_terminals, oil_gas_plants, oil_gas_extraction, lng_terminals, nuclear, geothermal, bioenergy, hydropower, solar, wind, gas_pipelines, oil_pipelines, lng_carriers. Omit for all trackers. (e.g. coal_plants,solar)
  --country: string # Plain English country name, ISO-3, or legacy FIPS alias. Filters primary or secondary country for cross-border assets. (e.g. United States)
  --region: string # Plain English region. Expands to the same ISO-3 country list used by V2 Events. (e.g. Middle East)
  --continent: string # Plain English continent. Expands to the same ISO-3 country list used by V2 Events. (e.g. Asia)
  --status: string # Comma-separated GEM status values. Common values include operating, construction, pre-construction, permitted, announced, proposed, shelved, cancelled, retired, and mothballed. (e.g. operating,construction)
  --operating-only: oneof<nothing, bool> # Shorthand for status=operating. (default: false, e.g. true)
  --tier: string # Comma-separated within-tracker tier values such as main, utility, distributed, below_threshold, closed, or sub_threshold. (e.g. main,utility)
  --fuel: string # Comma-separated fuel values. Matches the tracker-native fuel string or normalized cross-tracker fuel where populated. (e.g. coal,solar)
  --capacity-mw-min: float # Minimum MW capacity. Meaningful for power-generation trackers only. (e.g. 100)
  --capacity-mw-max: float # Maximum MW capacity. Meaningful for power-generation trackers only. (e.g. 5000)
  --start-year-min: int # Minimum asset start year. (e.g. 2000)
  --start-year-max: int # Maximum asset start year. (e.g. 2030)
  --retired-year-min: int # Minimum asset retired year. (e.g. 2000)
  --retired-year-max: int # Maximum asset retired year. (e.g. 2030)
  --owner-search: string # Case-insensitive substring match against the raw owner string. (e.g. ExxonMobil)
  --owner-entity-id: string # GEM Entity ID. Returns assets where the entity appears in owners, operators, or parents. (e.g. E100002021305)
  --bbox: string # Viewport filter formatted as lat_min,lon_min,lat_max,lon_max. (e.g. 30,-105,33,-100)
  --near: string # Proximity filter formatted as lat,lon,radius_km. (e.g. 31.16,-102.9,50)
  --asset-class: string@asset-class-completer # Asset class. The default fixed excludes mobile LNG carriers; use mobile or all for vessels. (default: fixed, e.g. fixed)
  --summary-limit: int # Number of summary buckets to return. (default: 50, e.g. 50)
]: nothing -> record<success: bool, group_by: string, data: table<bucket: string, bucket_kind: string, asset_count: float, capacity_mw_total: float, capacity_mw_avg: float, capacity_mw_max: float, capacity_mw_min: float, status_counts: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_by" $group_by "scalar") (serialize-qp "tracker" $tracker "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "operating_only" $operating_only "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "fuel" $fuel "scalar") (serialize-qp "capacity_mw_min" $capacity_mw_min "scalar") (serialize-qp "capacity_mw_max" $capacity_mw_max "scalar") (serialize-qp "start_year_min" $start_year_min "scalar") (serialize-qp "start_year_max" $start_year_max "scalar") (serialize-qp "retired_year_min" $retired_year_min "scalar") (serialize-qp "retired_year_max" $retired_year_max "scalar") (serialize-qp "owner_search" $owner_search "scalar") (serialize-qp "owner_entity_id" $owner_entity_id "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "near" $near "scalar") (serialize-qp "asset_class" $asset_class "scalar") (serialize-qp "summary_limit" $summary_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/energy/assets/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Map Energy Assets
#
# GET /api/v2/energy/assets/map
# operationId: map-energy-assets-v2
export def "energy-assets-map map-energy-assets-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tracker: string # Comma-separated GEM trackers. Valid values: coal_plants, coal_mines, coal_terminals, oil_gas_plants, oil_gas_extraction, lng_terminals, nuclear, geothermal, bioenergy, hydropower, solar, wind, gas_pipelines, oil_pipelines, lng_carriers. Omit for all trackers. (e.g. coal_plants,solar)
  --country: string # Plain English country name, ISO-3, or legacy FIPS alias. Filters primary or secondary country for cross-border assets. (e.g. United States)
  --region: string # Plain English region. Expands to the same ISO-3 country list used by V2 Events. (e.g. Middle East)
  --continent: string # Plain English continent. Expands to the same ISO-3 country list used by V2 Events. (e.g. Asia)
  --status: string # Comma-separated GEM status values. Common values include operating, construction, pre-construction, permitted, announced, proposed, shelved, cancelled, retired, and mothballed. (e.g. operating,construction)
  --operating-only: oneof<nothing, bool> # Shorthand for status=operating. (default: false, e.g. true)
  --tier: string # Comma-separated within-tracker tier values such as main, utility, distributed, below_threshold, closed, or sub_threshold. (e.g. main,utility)
  --fuel: string # Comma-separated fuel values. Matches the tracker-native fuel string or normalized cross-tracker fuel where populated. (e.g. coal,solar)
  --capacity-mw-min: float # Minimum MW capacity. Meaningful for power-generation trackers only. (e.g. 100)
  --capacity-mw-max: float # Maximum MW capacity. Meaningful for power-generation trackers only. (e.g. 5000)
  --start-year-min: int # Minimum asset start year. (e.g. 2000)
  --start-year-max: int # Maximum asset start year. (e.g. 2030)
  --retired-year-min: int # Minimum asset retired year. (e.g. 2000)
  --retired-year-max: int # Maximum asset retired year. (e.g. 2030)
  --owner-search: string # Case-insensitive substring match against the raw owner string. (e.g. ExxonMobil)
  --owner-entity-id: string # GEM Entity ID. Returns assets where the entity appears in owners, operators, or parents. (e.g. E100002021305)
  --bbox: string # Viewport filter formatted as lat_min,lon_min,lat_max,lon_max. (e.g. 30,-105,33,-100)
  --near: string # Proximity filter formatted as lat,lon,radius_km. (e.g. 31.16,-102.9,50)
  --search: string # Case-insensitive substring match against asset name. (e.g. Ranch Energy)
  --asset-class: string@asset-class-completer # Asset class. The default fixed excludes mobile LNG carriers; use mobile or all for vessels. (default: fixed, e.g. fixed)
  --map-limit: int # Fine-mode pin limit. Alias of fine_grained_limit. (default: 300, e.g. 300)
  --fine-grained-limit: int # Fine-mode pin limit. Alias of map_limit. (default: 300, e.g. 300)
]: nothing -> record<success: bool, mode: string, data: list<any>, filters_echo: record<tracker: list<string>, country_iso3: list<string>, status: list<string>, tier: list<string>, fuel: list<string>, operating_only: bool, asset_class: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tracker" $tracker "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "operating_only" $operating_only "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "fuel" $fuel "scalar") (serialize-qp "capacity_mw_min" $capacity_mw_min "scalar") (serialize-qp "capacity_mw_max" $capacity_mw_max "scalar") (serialize-qp "start_year_min" $start_year_min "scalar") (serialize-qp "start_year_max" $start_year_max "scalar") (serialize-qp "retired_year_min" $retired_year_min "scalar") (serialize-qp "retired_year_max" $retired_year_max "scalar") (serialize-qp "owner_search" $owner_search "scalar") (serialize-qp "owner_entity_id" $owner_entity_id "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "near" $near "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "asset_class" $asset_class "scalar") (serialize-qp "map_limit" $map_limit "scalar") (serialize-qp "fine_grained_limit" $fine_grained_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/energy/assets/map" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Energy Asset
#
# GET /api/v2/energy/assets/{tracker}/{gem_id}
# operationId: get-energy-asset-v2
export def "energy-assets get-energy-asset-v2" [
  tracker: string
  gem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool, data: record<id: string, gem_id: string, tracker: string, tier: string, asset_class: string, name: string, name_local: string, name_other: string, status: string, status_detail: string, start_year: int, retired_year: int, fuel: string, capacity: record<value: float, unit: string, mw: float, mw_secondary: float>, geo: record<country: string, country_iso3: string, secondary_country_iso3: string, region: string, subregion: string, continent: string, state_province: string, city: string, lat: float, lon: float, location_accuracy: string>, owners_raw: string, owners: list<record>, operators_raw: string, operators: list<record>, parents_raw: string, parents: list<record>, wiki_url: string, last_updated: string, detail_url: string, api_url: string>, raw: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/energy/assets/($tracker)/($gem_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Brief
#
# POST /api/v2/briefs
# operationId: create-brief-v2
export def "briefs create-brief-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scope_text: string # One or two plain sentences: the situation, where it is, who/what is affected, and the decision it informs. (e.g. Monitor Red Sea maritime disruption risk to shipping across Yemen, the Red Sea, and the Gulf of Aden.)
  --time-window: string@time-window-completer # Recent window the Brief analyses. (default: 24h)
  --baseline-window: string@baseline-window-completer # Earlier comparison window for change detection.
  --audience: string@audience-completer # default: executive
  --depth: string@depth-completer # default: standard
  --countries: list # ISO-3 country codes to scope the Brief. (e.g. [YEM, SAU])
  --regions: list
  --sectors: list
  --search-topics: list # Free-text focus terms/phrases that bias retrieval. (e.g. [port congestion, tanker insurance])
  --actors: list # Named actors to emphasize. (e.g. [Houthi, Maersk])
  --entities: list # Named people or organizations to emphasize.
  --locations: list # Plain-English sub-country locations.
  --assets: list # Named facilities or infrastructure.
  --public-link: oneof<nothing, bool> # When true, also mint a public shareable report URL. (default: false)
  --title: string # Optional; auto-generated from scope_text when omitted.
  --brief-type: string # Optional; defaults to monitoring_brief, the only generally-available type. (default: monitoring_brief)
]: any -> record<id: string, status: string, brief_type: string, title: string, created_at: string, web_url: string, public_url: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/briefs")
  let body = {scope_text: $scope_text, time_window: $time_window, baseline_window: $baseline_window, audience: $audience, depth: $depth, countries: $countries, regions: $regions, sectors: $sectors, search_topics: $search_topics, actors: $actors, entities: $entities, locations: $locations, assets: $assets, public_link: $public_link, title: $title, brief_type: $brief_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Briefs
#
# GET /api/v2/briefs
# operationId: list-briefs-v2
export def "briefs list-briefs-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<briefs: table<id: string, title: string, brief_type: string, status: string, created_at: string, updated_at: string, error_message: string, public_url: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/briefs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Brief
#
# GET /api/v2/briefs/{id}
# operationId: get-brief-v2
export def "briefs get-brief-v2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, title: string, brief_type: string, status: string, created_at: string, updated_at: string, error_message: string, input: record, document: record, citations: list<record>, appendix: record, public_url: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/briefs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
