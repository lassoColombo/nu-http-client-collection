# Auto-generated client for Patchman-engine API vv1.15.3
# Source: https://api.apis.guru/v2/specs/redhat.local/patchman-engine/v1.15.3/openapi.json
# Auth: --token flag or $env.PATCHMAN_ENGINE_API_TOKEN

const BASE_URL = "http://redhat.local"
const DEFAULT_AUTH = "x-rh-identity"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PATCHMAN_ENGINE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-rh-identity" => { {headers: {x-rh-identity: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://redhat.local" "http://localhost"] }
def auth-scheme-completer [] { ["x-rh-identity"] }

# Completers for enum parameters
def sort-completer [] { ["advisory_type" "applicable_systems" "id" "name" "public_date" "synopsis"] }
def sort-completer-1 [] { ["display_name" "id" "last_evaluation" "last_upload" "other_count" "rhba_count" "rhea_count" "rhsa_count" "stale"] }
def accept-completer [] { ["application/json" "text/csv"] }
def sort-completer-2 [] { ["id" "name" "systems_installed" "systems_updatable"] }
def sort-completer-3 [] { ["display_name" "id" "last_evaluation" "last_upload" "other_count" "packages_installed" "packages_updatable" "rhba_count" "rhea_count" "rhsa_count" "stale"] }
def sort-completer-4 [] { ["id" "name" "public_date" "synopsis" "type"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "patch-advisories list" } } | get name | first)
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

# Show me all applicable advisories for all my systems
#
# GET /api/patch/v1/advisories
# operationId: listAdvisories
export def "patch-advisories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --qp-sort: string@sort-completer # Sort field
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-description: string # Filter
  --filter-public-date: string # Filter
  --filter-synopsis: string # Filter
  --filter-advisory-type: string # Filter
  --filter-severity: string # Filter
  --filter-applicable-systems: string # Filter
  --tags: list<string> # Tag filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[description]" $filter_description "scalar") (serialize-qp "filter[public_date]" $filter_public_date "scalar") (serialize-qp "filter[synopsis]" $filter_synopsis "scalar") (serialize-qp "filter[advisory_type]" $filter_advisory_type "scalar") (serialize-qp "filter[severity]" $filter_severity "scalar") (serialize-qp "filter[applicable_systems]" $filter_applicable_systems "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/advisories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details an advisory by given advisory name
#
# GET /api/patch/v1/advisories/{advisory_id}
# operationId: detailAdvisory
export def "patch-advisories get-detail" [
  advisory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<cves: list, description: string, fixes: string, modified_date: string, packages: record, public_date: string, references: list, severity: int, solution: string, synopsis: string, topic: string>, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({advisory_id: (encode-path-segment $advisory_id)} | format pattern "/api/patch/v1/advisories/{advisory_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me systems on which the given advisory is applicable
#
# GET /api/patch/v1/advisories/{advisory_id}/systems
# operationId: listAdvisorySystems
export def "patch-advisories-systems list" [
  advisory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --qp-sort: string@sort-completer-1 # Sort field
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-insights-id: string # Filter
  --filter-display-name: string # Filter
  --filter-last-evaluation: string # Filter
  --filter-last-upload: string # Filter
  --filter-rhsa-count: string # Filter
  --filter-rhba-count: string # Filter
  --filter-rhea-count: string # Filter
  --filter-other-count: string # Filter
  --filter-stale: string # Filter
  --filter-stale-timestamp: string # Filter
  --filter-stale-warning-timestamp: string # Filter
  --filter-culled-timestamp: string # Filter
  --filter-created: string # Filter
  --tags: list<string> # Tag filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[insights_id]" $filter_insights_id "scalar") (serialize-qp "filter[display_name]" $filter_display_name "scalar") (serialize-qp "filter[last_evaluation]" $filter_last_evaluation "scalar") (serialize-qp "filter[last_upload]" $filter_last_upload "scalar") (serialize-qp "filter[rhsa_count]" $filter_rhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filter_rhba_count "scalar") (serialize-qp "filter[rhea_count]" $filter_rhea_count "scalar") (serialize-qp "filter[other_count]" $filter_other_count "scalar") (serialize-qp "filter[stale]" $filter_stale "scalar") (serialize-qp "filter[stale_timestamp]" $filter_stale_timestamp "scalar") (serialize-qp "filter[stale_warning_timestamp]" $filter_stale_warning_timestamp "scalar") (serialize-qp "filter[culled_timestamp]" $filter_culled_timestamp "scalar") (serialize-qp "filter[created]" $filter_created "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({advisory_id: (encode-path-segment $advisory_id)} | format pattern "/api/patch/v1/advisories/{advisory_id}/systems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export applicable advisories for all my systems
#
# GET /api/patch/v1/export/advisories
# operationId: exportAdvisories
export def "patch-export-advisories export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-description: string # Filter
  --filter-public-date: string # Filter
  --filter-synopsis: string # Filter
  --filter-advisory-type: string # Filter
  --filter-severity: string # Filter
  --filter-applicable-systems: string # Filter
]: nothing -> table<advisory_type: int, applicable_systems: int, cve_count: int, description: string, id: string, public_date: string, severity: int, synopsis: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[description]" $filter_description "scalar") (serialize-qp "filter[public_date]" $filter_public_date "scalar") (serialize-qp "filter[synopsis]" $filter_synopsis "scalar") (serialize-qp "filter[advisory_type]" $filter_advisory_type "scalar") (serialize-qp "filter[severity]" $filter_severity "scalar") (serialize-qp "filter[applicable_systems]" $filter_applicable_systems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/export/advisories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export systems for my account
#
# GET /api/patch/v1/export/advisories/{advisory_id}/systems
# operationId: exportAdvisorySystems
export def "patch-export-advisories-systems export" [
  advisory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-display-name: string # Filter
  --filter-last-evaluation: string # Filter
  --filter-last-upload: string # Filter
  --filter-rhsa-count: string # Filter
  --filter-rhba-count: string # Filter
  --filter-rhea-count: string # Filter
  --filter-other-count: string # Filter
  --filter-stale: string # Filter
  --filter-packages-installed: string # Filter
  --filter-packages-updatable: string # Filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
  --tags: list<string> # Tag filter
]: nothing -> table<created: string, culled_timestamp: string, display_name: string, id: string, insights_id: string, last_evaluation: string, last_upload: string, os_major: string, os_minor: string, os_name: string, other_count: int, packages_installed: int, packages_updatable: int, rhba_count: int, rhea_count: int, rhsa_count: int, rhsm: string, stale: bool, stale_timestamp: string, stale_warning_timestamp: string, third_party: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[display_name]" $filter_display_name "scalar") (serialize-qp "filter[last_evaluation]" $filter_last_evaluation "scalar") (serialize-qp "filter[last_upload]" $filter_last_upload "scalar") (serialize-qp "filter[rhsa_count]" $filter_rhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filter_rhba_count "scalar") (serialize-qp "filter[rhea_count]" $filter_rhea_count "scalar") (serialize-qp "filter[other_count]" $filter_other_count "scalar") (serialize-qp "filter[stale]" $filter_stale "scalar") (serialize-qp "filter[packages_installed]" $filter_packages_installed "scalar") (serialize-qp "filter[packages_updatable]" $filter_packages_updatable "scalar") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({advisory_id: (encode-path-segment $advisory_id)} | format pattern "/api/patch/v1/export/advisories/{advisory_id}/systems") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all installed packages across my systems
#
# GET /api/patch/v1/export/packages
# operationId: exportPackages
export def "patch-export-packages export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-sort: string@sort-completer-2 # Sort field
  --search: string # Find matching text
  --filter-name: string # Filter
  --filter-systems-installed: string # Filter
  --filter-systems-updatable: string # Filter
  --filter-summary: string # Filter
]: nothing -> table<name: string, summary: string, systems_installed: int, systems_updatable: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[systems_installed]" $filter_systems_installed "scalar") (serialize-qp "filter[systems_updatable]" $filter_systems_updatable "scalar") (serialize-qp "filter[summary]" $filter_summary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/export/packages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all my systems which have a package installed
#
# GET /api/patch/v1/export/packages/{package_name}/systems
# operationId: exportPackageSystems
export def "patch-export-packages-systems export" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
  --tags: list<string> # Tag filter
]: nothing -> table<available_evra: string, display_name: string, id: string, installed_evra: string, updatable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({package_name: (encode-path-segment $package_name)} | format pattern "/api/patch/v1/export/packages/{package_name}/systems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export systems for my account
#
# GET /api/patch/v1/export/systems
# operationId: exportSystems
export def "patch-export-systems export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-display-name: string # Filter
  --filter-last-evaluation: string # Filter
  --filter-last-upload: string # Filter
  --filter-rhsa-count: string # Filter
  --filter-rhba-count: string # Filter
  --filter-rhea-count: string # Filter
  --filter-other-count: string # Filter
  --filter-stale: string # Filter
  --filter-packages-installed: string # Filter
  --filter-packages-updatable: string # Filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
  --tags: list<string> # Tag filter
]: nothing -> table<created: string, culled_timestamp: string, display_name: string, id: string, insights_id: string, last_evaluation: string, last_upload: string, os_major: string, os_minor: string, os_name: string, other_count: int, packages_installed: int, packages_updatable: int, rhba_count: int, rhea_count: int, rhsa_count: int, rhsm: string, stale: bool, stale_timestamp: string, stale_warning_timestamp: string, third_party: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[display_name]" $filter_display_name "scalar") (serialize-qp "filter[last_evaluation]" $filter_last_evaluation "scalar") (serialize-qp "filter[last_upload]" $filter_last_upload "scalar") (serialize-qp "filter[rhsa_count]" $filter_rhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filter_rhba_count "scalar") (serialize-qp "filter[rhea_count]" $filter_rhea_count "scalar") (serialize-qp "filter[other_count]" $filter_other_count "scalar") (serialize-qp "filter[stale]" $filter_stale "scalar") (serialize-qp "filter[packages_installed]" $filter_packages_installed "scalar") (serialize-qp "filter[packages_updatable]" $filter_packages_updatable "scalar") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/export/systems" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export applicable advisories for all my systems
#
# GET /api/patch/v1/export/systems/{inventory_id}/advisories
# operationId: exportSystemAdvisories
export def "patch-export-systems-advisories export" [
  inventory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-description: string # Filter
  --filter-public-date: string # Filter
  --filter-synopsis: string # Filter
  --filter-advisory-type: string # Filter
  --filter-severity: string # Filter
]: nothing -> table<advisory_type: int, cve_count: int, description: string, id: string, public_date: string, severity: int, synopsis: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[description]" $filter_description "scalar") (serialize-qp "filter[public_date]" $filter_public_date "scalar") (serialize-qp "filter[synopsis]" $filter_synopsis "scalar") (serialize-qp "filter[advisory_type]" $filter_advisory_type "scalar") (serialize-qp "filter[severity]" $filter_severity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_id: (encode-path-segment $inventory_id)} | format pattern "/api/patch/v1/export/systems/{inventory_id}/advisories") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details about a system packages by given inventory id
#
# GET /api/patch/v1/export/systems/{inventory_id}/packages
# operationId: exportSystemPackages
export def "patch-export-systems-packages export" [
  inventory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Find matching text
  --filter-name: string # Filter
  --filter-description: string # Filter
  --filter-evra: string # Filter
  --filter-summary: string # Filter
  --filter-updatable: oneof<nothing, bool> # Filter
]: nothing -> table<description: string, evra: string, latest_evra: string, name: string, summary: string, updatable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[description]" $filter_description "scalar") (serialize-qp "filter[evra]" $filter_evra "scalar") (serialize-qp "filter[summary]" $filter_summary "scalar") (serialize-qp "filter[updatable]" $filter_updatable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_id: (encode-path-segment $inventory_id)} | format pattern "/api/patch/v1/export/systems/{inventory_id}/packages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all installed packages across my systems
#
# GET /api/patch/v1/packages/
# operationId: listPackages
export def "patch-packages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --qp-sort: string@sort-completer-2 # Sort field
  --search: string # Find matching text
  --filter-name: string # Filter
  --filter-systems-installed: string # Filter
  --filter-systems-updatable: string # Filter
  --filter-summary: string # Filter
  --tags: list<string> # Tag filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
]: nothing -> record<data: table<name: string, summary: string, systems_installed: int, systems_updatable: int>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[systems_installed]" $filter_systems_installed "scalar") (serialize-qp "filter[systems_updatable]" $filter_systems_updatable "scalar") (serialize-qp "filter[summary]" $filter_summary "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/packages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me metadata of selected package
#
# GET /api/patch/v1/packages/{package_name}
# operationId: LatestPackage
export def "patch-packages get-latest" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<advisory_id: string, description: string, name: string, summary: string, version: string>, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({package_name: (encode-path-segment $package_name)} | format pattern "/api/patch/v1/packages/{package_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all my systems which have a package installed
#
# GET /api/patch/v1/packages/{package_name}/systems
# operationId: packageSystems
export def "patch-packages-systems get" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --tags: list<string> # Tag filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
]: nothing -> record<data: table<available_evra: string, display_name: string, id: string, installed_evra: string, updatable: bool>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({package_name: (encode-path-segment $package_name)} | format pattern "/api/patch/v1/packages/{package_name}/systems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all package versions installed on some system
#
# GET /api/patch/v1/packages/{package_name}/versions
# operationId: packageVersions
export def "patch-packages-versions get" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
]: nothing -> record<data: table<evra: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_name: (encode-path-segment $package_name)} | format pattern "/api/patch/v1/packages/{package_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all my systems
#
# GET /api/patch/v1/systems
# operationId: listSystems
export def "patch-systems list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --qp-sort: string@sort-completer-3 # Sort field
  --search: string # Find matching text
  --filter-insights-id: string # Filter
  --filter-id: string # Filter
  --filter-display-name: string # Filter
  --filter-last-evaluation: string # Filter
  --filter-last-upload: string # Filter
  --filter-rhsa-count: string # Filter
  --filter-rhba-count: string # Filter
  --filter-rhea-count: string # Filter
  --filter-other-count: string # Filter
  --filter-stale: string # Filter
  --filter-packages-installed: string # Filter
  --filter-packages-updatable: string # Filter
  --filter-stale-timestamp: string # Filter
  --filter-stale-warning-timestamp: string # Filter
  --filter-culled-timestamp: string # Filter
  --filter-created: string # Filter
  --tags: list<string> # Tag filter
  --filter-system-profile-sap-system: string # Filter only SAP systems
  --filter-system-profile-sap-sids-in: list<string> # Filter systems by their SAP SIDs
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[insights_id]" $filter_insights_id "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[display_name]" $filter_display_name "scalar") (serialize-qp "filter[last_evaluation]" $filter_last_evaluation "scalar") (serialize-qp "filter[last_upload]" $filter_last_upload "scalar") (serialize-qp "filter[rhsa_count]" $filter_rhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filter_rhba_count "scalar") (serialize-qp "filter[rhea_count]" $filter_rhea_count "scalar") (serialize-qp "filter[other_count]" $filter_other_count "scalar") (serialize-qp "filter[stale]" $filter_stale "scalar") (serialize-qp "filter[packages_installed]" $filter_packages_installed "scalar") (serialize-qp "filter[packages_updatable]" $filter_packages_updatable "scalar") (serialize-qp "filter[stale_timestamp]" $filter_stale_timestamp "scalar") (serialize-qp "filter[stale_warning_timestamp]" $filter_stale_warning_timestamp "scalar") (serialize-qp "filter[culled_timestamp]" $filter_culled_timestamp "scalar") (serialize-qp "filter[created]" $filter_created "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filter_system_profile_sap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filter_system_profile_sap_sids_in "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/systems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete system by inventory id
#
# DELETE /api/patch/v1/systems/{inventory_id}
# operationId: deletesystem
export def "patch-systems delete-deletesystem" [
  inventory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({inventory_id: (encode-path-segment $inventory_id)} | format pattern "/api/patch/v1/systems/{inventory_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details about a system by given inventory id
#
# GET /api/patch/v1/systems/{inventory_id}
# operationId: detailSystem
export def "patch-systems get-detail" [
  inventory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<created: string, culled_timestamp: string, display_name: string, insights_id: string, last_evaluation: string, last_upload: string, os_major: string, os_minor: string, os_name: string, other_count: int, packages_installed: int, packages_updatable: int, rhba_count: int, rhea_count: int, rhsa_count: int, rhsm: string, stale: bool, stale_timestamp: string, stale_warning_timestamp: string, third_party: bool>, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({inventory_id: (encode-path-segment $inventory_id)} | format pattern "/api/patch/v1/systems/{inventory_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me advisories for a system by given inventory id
#
# GET /api/patch/v1/systems/{inventory_id}/advisories
# operationId: listSystemAdvisories
export def "patch-systems-advisories list" [
  inventory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --qp-sort: string@sort-completer-4 # Sort field
  --search: string # Find matching text
  --filter-id: string # Filter
  --filter-description: string # Filter
  --filter-public-date: string # Filter
  --filter-synopsis: string # Filter
  --filter-advisory-type: string # Filter
  --filter-severity: string # Filter
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filter_id "scalar") (serialize-qp "filter[description]" $filter_description "scalar") (serialize-qp "filter[public_date]" $filter_public_date "scalar") (serialize-qp "filter[synopsis]" $filter_synopsis "scalar") (serialize-qp "filter[advisory_type]" $filter_advisory_type "scalar") (serialize-qp "filter[severity]" $filter_severity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_id: (encode-path-segment $inventory_id)} | format pattern "/api/patch/v1/systems/{inventory_id}/advisories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details about a system packages by given inventory id
#
# GET /api/patch/v1/systems/{inventory_id}/packages
# operationId: systemPackages
export def "patch-systems-packages get" [
  inventory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for paging, set -1 to return all
  --offset: int # Offset for paging
  --search: string # Find matching text
  --filter-name: string # Filter
  --filter-description: string # Filter
  --filter-evra: string # Filter
  --filter-summary: string # Filter
  --filter-updatable: oneof<nothing, bool> # Filter
]: nothing -> record<data: table<description: string, evra: string, name: string, summary: string, updatable: bool, updates: list>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[description]" $filter_description "scalar") (serialize-qp "filter[evra]" $filter_evra "scalar") (serialize-qp "filter[summary]" $filter_summary "scalar") (serialize-qp "filter[updatable]" $filter_updatable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_id: (encode-path-segment $inventory_id)} | format pattern "/api/patch/v1/systems/{inventory_id}/packages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View advisory-system pairs for selected systems and advisories
#
# POST /api/patch/v1/views/advisories/systems
# operationId: viewAdvisoriesSystems
export def "patch-views-advisories-systems create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advisories: list<string>
  --systems: list<string>
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/patch/v1/views/advisories/systems")
  let req_body = {"advisories": $advisories, "systems": $systems} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# View system-advisory pairs for selected systems and advisories
#
# POST /api/patch/v1/views/systems/advisories
# operationId: viewSystemsAdvisories
export def "patch-views-systems-advisories create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advisories: list<string>
  --systems: list<string>
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/patch/v1/views/systems/advisories")
  let req_body = {"advisories": $advisories, "systems": $systems} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
