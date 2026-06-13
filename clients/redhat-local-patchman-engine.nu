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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "patch-advisories listAdvisories" } } | get name | first)
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
export def "patch-advisories listAdvisories" [
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
  --filterid: string # Filter 
  --filterdescription: string # Filter
  --filterpublic-date: string # Filter
  --filtersynopsis: string # Filter
  --filteradvisory-type: string # Filter
  --filterseverity: string # Filter
  --filterapplicable-systems: string # Filter
  --tags: list # Tag filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[description]" $filterdescription "scalar") (serialize-qp "filter[public_date]" $filterpublic_date "scalar") (serialize-qp "filter[synopsis]" $filtersynopsis "scalar") (serialize-qp "filter[advisory_type]" $filteradvisory_type "scalar") (serialize-qp "filter[severity]" $filterseverity "scalar") (serialize-qp "filter[applicable_systems]" $filterapplicable_systems "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/advisories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details an advisory by given advisory name
#
# GET /api/patch/v1/advisories/{advisory_id}
# operationId: detailAdvisory
export def "patch-advisories detailAdvisory" [
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
  let full_url = (build-url $base $"/api/patch/v1/advisories/($advisory_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me systems on which the given advisory is applicable
#
# GET /api/patch/v1/advisories/{advisory_id}/systems
# operationId: listAdvisorySystems
export def "patch-advisories-systems listAdvisorySystems" [
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
  --filterid: string # Filter
  --filterinsights-id: string # Filter
  --filterdisplay-name: string # Filter
  --filterlast-evaluation: string # Filter
  --filterlast-upload: string # Filter
  --filterrhsa-count: string # Filter
  --filterrhba-count: string # Filter
  --filterrhea-count: string # Filter
  --filterother-count: string # Filter
  --filterstale: string # Filter
  --filterstale-timestamp: string # Filter
  --filterstale-warning-timestamp: string # Filter
  --filterculled-timestamp: string # Filter
  --filtercreated: string # Filter
  --tags: list # Tag filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[insights_id]" $filterinsights_id "scalar") (serialize-qp "filter[display_name]" $filterdisplay_name "scalar") (serialize-qp "filter[last_evaluation]" $filterlast_evaluation "scalar") (serialize-qp "filter[last_upload]" $filterlast_upload "scalar") (serialize-qp "filter[rhsa_count]" $filterrhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filterrhba_count "scalar") (serialize-qp "filter[rhea_count]" $filterrhea_count "scalar") (serialize-qp "filter[other_count]" $filterother_count "scalar") (serialize-qp "filter[stale]" $filterstale "scalar") (serialize-qp "filter[stale_timestamp]" $filterstale_timestamp "scalar") (serialize-qp "filter[stale_warning_timestamp]" $filterstale_warning_timestamp "scalar") (serialize-qp "filter[culled_timestamp]" $filterculled_timestamp "scalar") (serialize-qp "filter[created]" $filtercreated "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/advisories/($advisory_id)/systems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export applicable advisories for all my systems
#
# GET /api/patch/v1/export/advisories
# operationId: exportAdvisories
export def "patch-export-advisories exportAdvisories" [
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
  --filterid: string # Filter
  --filterdescription: string # Filter
  --filterpublic-date: string # Filter
  --filtersynopsis: string # Filter
  --filteradvisory-type: string # Filter
  --filterseverity: string # Filter
  --filterapplicable-systems: string # Filter
]: nothing -> table<advisory_type: int, applicable_systems: int, cve_count: int, description: string, id: string, public_date: string, severity: int, synopsis: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[description]" $filterdescription "scalar") (serialize-qp "filter[public_date]" $filterpublic_date "scalar") (serialize-qp "filter[synopsis]" $filtersynopsis "scalar") (serialize-qp "filter[advisory_type]" $filteradvisory_type "scalar") (serialize-qp "filter[severity]" $filterseverity "scalar") (serialize-qp "filter[applicable_systems]" $filterapplicable_systems "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/export/advisories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export systems for my account
#
# GET /api/patch/v1/export/advisories/{advisory_id}/systems
# operationId: exportAdvisorySystems
export def "patch-export-advisories-systems exportAdvisorySystems" [
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
  --filterid: string # Filter
  --filterdisplay-name: string # Filter
  --filterlast-evaluation: string # Filter
  --filterlast-upload: string # Filter
  --filterrhsa-count: string # Filter
  --filterrhba-count: string # Filter
  --filterrhea-count: string # Filter
  --filterother-count: string # Filter
  --filterstale: string # Filter
  --filterpackages-installed: string # Filter
  --filterpackages-updatable: string # Filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
  --tags: list # Tag filter
]: nothing -> table<created: string, culled_timestamp: string, display_name: string, id: string, insights_id: string, last_evaluation: string, last_upload: string, os_major: string, os_minor: string, os_name: string, other_count: int, packages_installed: int, packages_updatable: int, rhba_count: int, rhea_count: int, rhsa_count: int, rhsm: string, stale: bool, stale_timestamp: string, stale_warning_timestamp: string, third_party: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[display_name]" $filterdisplay_name "scalar") (serialize-qp "filter[last_evaluation]" $filterlast_evaluation "scalar") (serialize-qp "filter[last_upload]" $filterlast_upload "scalar") (serialize-qp "filter[rhsa_count]" $filterrhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filterrhba_count "scalar") (serialize-qp "filter[rhea_count]" $filterrhea_count "scalar") (serialize-qp "filter[other_count]" $filterother_count "scalar") (serialize-qp "filter[stale]" $filterstale "scalar") (serialize-qp "filter[packages_installed]" $filterpackages_installed "scalar") (serialize-qp "filter[packages_updatable]" $filterpackages_updatable "scalar") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/export/advisories/($advisory_id)/systems" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all installed packages across my systems
#
# GET /api/patch/v1/export/packages
# operationId: exportPackages
export def "patch-export-packages exportPackages" [
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
  --filtername: string # Filter
  --filtersystems-installed: string # Filter
  --filtersystems-updatable: string # Filter
  --filtersummary: string # Filter
]: nothing -> table<name: string, summary: string, systems_installed: int, systems_updatable: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "filter[systems_installed]" $filtersystems_installed "scalar") (serialize-qp "filter[systems_updatable]" $filtersystems_updatable "scalar") (serialize-qp "filter[summary]" $filtersummary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/export/packages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all my systems which have a package installed
#
# GET /api/patch/v1/export/packages/{package_name}/systems
# operationId: exportPackageSystems
export def "patch-export-packages-systems exportPackageSystems" [
  package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
  --tags: list # Tag filter
]: nothing -> table<available_evra: string, display_name: string, id: string, installed_evra: string, updatable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/export/packages/($package_name)/systems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export systems for my account
#
# GET /api/patch/v1/export/systems
# operationId: exportSystems
export def "patch-export-systems exportSystems" [
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
  --filterid: string # Filter
  --filterdisplay-name: string # Filter
  --filterlast-evaluation: string # Filter
  --filterlast-upload: string # Filter
  --filterrhsa-count: string # Filter
  --filterrhba-count: string # Filter
  --filterrhea-count: string # Filter
  --filterother-count: string # Filter
  --filterstale: string # Filter
  --filterpackages-installed: string # Filter
  --filterpackages-updatable: string # Filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
  --tags: list # Tag filter
]: nothing -> table<created: string, culled_timestamp: string, display_name: string, id: string, insights_id: string, last_evaluation: string, last_upload: string, os_major: string, os_minor: string, os_name: string, other_count: int, packages_installed: int, packages_updatable: int, rhba_count: int, rhea_count: int, rhsa_count: int, rhsm: string, stale: bool, stale_timestamp: string, stale_warning_timestamp: string, third_party: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[display_name]" $filterdisplay_name "scalar") (serialize-qp "filter[last_evaluation]" $filterlast_evaluation "scalar") (serialize-qp "filter[last_upload]" $filterlast_upload "scalar") (serialize-qp "filter[rhsa_count]" $filterrhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filterrhba_count "scalar") (serialize-qp "filter[rhea_count]" $filterrhea_count "scalar") (serialize-qp "filter[other_count]" $filterother_count "scalar") (serialize-qp "filter[stale]" $filterstale "scalar") (serialize-qp "filter[packages_installed]" $filterpackages_installed "scalar") (serialize-qp "filter[packages_updatable]" $filterpackages_updatable "scalar") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/export/systems" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export applicable advisories for all my systems
#
# GET /api/patch/v1/export/systems/{inventory_id}/advisories
# operationId: exportSystemAdvisories
export def "patch-export-systems-advisories exportSystemAdvisories" [
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
  --filterid: string # Filter
  --filterdescription: string # Filter
  --filterpublic-date: string # Filter
  --filtersynopsis: string # Filter
  --filteradvisory-type: string # Filter
  --filterseverity: string # Filter
]: nothing -> table<advisory_type: int, cve_count: int, description: string, id: string, public_date: string, severity: int, synopsis: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[description]" $filterdescription "scalar") (serialize-qp "filter[public_date]" $filterpublic_date "scalar") (serialize-qp "filter[synopsis]" $filtersynopsis "scalar") (serialize-qp "filter[advisory_type]" $filteradvisory_type "scalar") (serialize-qp "filter[severity]" $filterseverity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/export/systems/($inventory_id)/advisories" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details about a system packages by given inventory id
#
# GET /api/patch/v1/export/systems/{inventory_id}/packages
# operationId: exportSystemPackages
export def "patch-export-systems-packages exportSystemPackages" [
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
  --filtername: string # Filter
  --filterdescription: string # Filter
  --filterevra: string # Filter
  --filtersummary: string # Filter
  --filterupdatable: oneof<nothing, bool> # Filter
]: nothing -> table<description: string, evra: string, latest_evra: string, name: string, summary: string, updatable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "filter[description]" $filterdescription "scalar") (serialize-qp "filter[evra]" $filterevra "scalar") (serialize-qp "filter[summary]" $filtersummary "scalar") (serialize-qp "filter[updatable]" $filterupdatable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/export/systems/($inventory_id)/packages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all installed packages across my systems
#
# GET /api/patch/v1/packages/
# operationId: listPackages
export def "patch-packages listPackages" [
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
  --filtername: string # Filter
  --filtersystems-installed: string # Filter
  --filtersystems-updatable: string # Filter
  --filtersummary: string # Filter
  --tags: list # Tag filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
]: nothing -> record<data: table<name: string, summary: string, systems_installed: int, systems_updatable: int>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "filter[systems_installed]" $filtersystems_installed "scalar") (serialize-qp "filter[systems_updatable]" $filtersystems_updatable "scalar") (serialize-qp "filter[summary]" $filtersummary "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/packages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me metadata of selected package
#
# GET /api/patch/v1/packages/{package_name}
# operationId: LatestPackage
export def "patch-packages LatestPackage" [
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
  let full_url = (build-url $base $"/api/patch/v1/packages/($package_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all my systems which have a package installed
#
# GET /api/patch/v1/packages/{package_name}/systems
# operationId: packageSystems
export def "patch-packages-systems packageSystems" [
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
  --tags: list # Tag filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
]: nothing -> record<data: table<available_evra: string, display_name: string, id: string, installed_evra: string, updatable: bool>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/packages/($package_name)/systems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all package versions installed on some system
#
# GET /api/patch/v1/packages/{package_name}/versions
# operationId: packageVersions
export def "patch-packages-versions packageVersions" [
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
  let full_url = (build-url $base $"/api/patch/v1/packages/($package_name)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me all my systems
#
# GET /api/patch/v1/systems
# operationId: listSystems
export def "patch-systems listSystems" [
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
  --filterinsights-id: string # Filter
  --filterid: string # Filter
  --filterdisplay-name: string # Filter
  --filterlast-evaluation: string # Filter
  --filterlast-upload: string # Filter
  --filterrhsa-count: string # Filter
  --filterrhba-count: string # Filter
  --filterrhea-count: string # Filter
  --filterother-count: string # Filter
  --filterstale: string # Filter
  --filterpackages-installed: string # Filter
  --filterpackages-updatable: string # Filter
  --filterstale-timestamp: string # Filter
  --filterstale-warning-timestamp: string # Filter
  --filterculled-timestamp: string # Filter
  --filtercreated: string # Filter
  --tags: list # Tag filter
  --filtersystem-profilesap-system: string # Filter only SAP systems
  --filtersystem-profilesap-sidsin: list # Filter systems by their SAP SIDs
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[insights_id]" $filterinsights_id "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[display_name]" $filterdisplay_name "scalar") (serialize-qp "filter[last_evaluation]" $filterlast_evaluation "scalar") (serialize-qp "filter[last_upload]" $filterlast_upload "scalar") (serialize-qp "filter[rhsa_count]" $filterrhsa_count "scalar") (serialize-qp "filter[rhba_count]" $filterrhba_count "scalar") (serialize-qp "filter[rhea_count]" $filterrhea_count "scalar") (serialize-qp "filter[other_count]" $filterother_count "scalar") (serialize-qp "filter[stale]" $filterstale "scalar") (serialize-qp "filter[packages_installed]" $filterpackages_installed "scalar") (serialize-qp "filter[packages_updatable]" $filterpackages_updatable "scalar") (serialize-qp "filter[stale_timestamp]" $filterstale_timestamp "scalar") (serialize-qp "filter[stale_warning_timestamp]" $filterstale_warning_timestamp "scalar") (serialize-qp "filter[culled_timestamp]" $filterculled_timestamp "scalar") (serialize-qp "filter[created]" $filtercreated "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "filter[system_profile][sap_system]" $filtersystem_profilesap_system "scalar") (serialize-qp "filter[system_profile][sap_sids][in]" $filtersystem_profilesap_sidsin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patch/v1/systems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete system by inventory id
#
# DELETE /api/patch/v1/systems/{inventory_id}
# operationId: deletesystem
export def "patch-systems deletesystem" [
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
  let full_url = (build-url $base $"/api/patch/v1/systems/($inventory_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details about a system by given inventory id
#
# GET /api/patch/v1/systems/{inventory_id}
# operationId: detailSystem
export def "patch-systems detailSystem" [
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
  let full_url = (build-url $base $"/api/patch/v1/systems/($inventory_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me advisories for a system by given inventory id
#
# GET /api/patch/v1/systems/{inventory_id}/advisories
# operationId: listSystemAdvisories
export def "patch-systems-advisories listSystemAdvisories" [
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
  --filterid: string # Filter
  --filterdescription: string # Filter
  --filterpublic-date: string # Filter
  --filtersynopsis: string # Filter
  --filteradvisory-type: string # Filter
  --filterseverity: string # Filter
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[id]" $filterid "scalar") (serialize-qp "filter[description]" $filterdescription "scalar") (serialize-qp "filter[public_date]" $filterpublic_date "scalar") (serialize-qp "filter[synopsis]" $filtersynopsis "scalar") (serialize-qp "filter[advisory_type]" $filteradvisory_type "scalar") (serialize-qp "filter[severity]" $filterseverity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/systems/($inventory_id)/advisories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show me details about a system packages by given inventory id
#
# GET /api/patch/v1/systems/{inventory_id}/packages
# operationId: systemPackages
export def "patch-systems-packages systemPackages" [
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
  --filtername: string # Filter
  --filterdescription: string # Filter
  --filterevra: string # Filter
  --filtersummary: string # Filter
  --filterupdatable: oneof<nothing, bool> # Filter
]: nothing -> record<data: table<description: string, evra: string, name: string, summary: string, updatable: bool, updates: list>, links: record<first: string, last: string, next: string, previous: string>, meta: record<filter: record, limit: int, offset: int, search: string, sort: list<string>, subtotals: record, total_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filter[name]" $filtername "scalar") (serialize-qp "filter[description]" $filterdescription "scalar") (serialize-qp "filter[evra]" $filterevra "scalar") (serialize-qp "filter[summary]" $filtersummary "scalar") (serialize-qp "filter[updatable]" $filterupdatable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/patch/v1/systems/($inventory_id)/packages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View advisory-system pairs for selected systems and advisories
#
# POST /api/patch/v1/views/advisories/systems
# operationId: viewAdvisoriesSystems
export def "patch-views-advisories-systems viewAdvisoriesSystems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advisories: list
  --systems: list
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/patch/v1/views/advisories/systems")
  let body = {advisories: $advisories, systems: $systems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View system-advisory pairs for selected systems and advisories
#
# POST /api/patch/v1/views/systems/advisories
# operationId: viewSystemsAdvisories
export def "patch-views-systems-advisories viewSystemsAdvisories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advisories: list
  --systems: list
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-rh-identity"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/patch/v1/views/systems/advisories")
  let body = {advisories: $advisories, systems: $systems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
