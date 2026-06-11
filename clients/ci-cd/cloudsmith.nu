# Auto-generated client for Cloudsmith API (v1) vv1
# Source: https://api.cloudsmith.io/openapi
# Auth: --token flag or $env.CLOUDSMITH_API_V1_TOKEN

const BASE_URL = "https://api.cloudsmith.io"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUDSMITH_API_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-Api-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.cloudsmith.io"] }
def auth-scheme-completer [] { ["x-api-key" "basic"] }

# Completers for enum parameters
def action-completer [] { ["Copy" "Delete" "Move" "Quarantine" "Rescan" "Resync" "Unquarantine"] }
def limit-bandwidth-unit-completer [] { ["Byte" "Exabyte" "Gigabyte" "Kilobyte" "Megabyte" "Petabyte" "Terabyte" "Yottabyte" "Zettabyte"] }
def scheduled-reset-period-completer [] { ["Annual" "Bi-Monthly" "Daily" "Every 6 months" "Fortnightly" "Monthly" "Never Reset" "Quarterly" "Weekly"] }
def method-completer [] { ["post" "presigned" "put" "put_parts" "unsigned_put"] }
def role-completer [] { ["Collaborator" "Manager" "Member" "Owner"] }
def visibility-completer [] { ["Private" "Public"] }
def role-completer-1 [] { ["Manager" "Member"] }
def visibility-completer-1 [] { ["Hidden" "Visible"] }
def min-severity-completer [] { ["Critical" "High" "Low" "Medium"] }
def action-completer-1 [] { ["Add" "Clear" "Remove" "Replace"] }
def action-completer-2 [] { ["Update"] }
def license-override-completer [] { ["Ignored" "None" "Purchased"] }
def action-completer-3 [] { ["hard_delete" "restore"] }
def broadcast-state-completer [] { ["Internal" "Off" "Open-Source" "Private" "Public"] }
def content-kind-completer [] { ["Distribution" "Standard" "Upstream"] }
def copy-packages-completer [] { ["Admin" "Read" "Write"] }
def default-privilege-completer [] { ["Admin" "None" "Read" "Write"] }
def delete-packages-completer [] { ["Admin" "Write"] }
def manage-entitlements-privilege-completer [] { ["Admin" "Read" "Write"] }
def move-packages-completer [] { ["Admin" "Read" "Write"] }
def replace-packages-completer [] { ["Admin" "Write"] }
def repository-type-str-completer [] { ["Open-Source" "Private" "Public"] }
def resync-packages-completer [] { ["Admin" "Write"] }
def scan-packages-completer [] { ["Admin" "Read" "Write"] }
def use-entitlements-privilege-completer [] { ["Admin" "Read" "Write"] }
def view-statistics-completer [] { ["Admin" "Read" "Write"] }
def auth-mode-completer [] { ["None" "Username and Password"] }
def mode-completer [] { ["Cache and Proxy" "Proxy Only"] }
def rsa-verification-completer [] { ["Allow All" "Reject Invalid" "Warn on Invalid"] }
def gpg-verification-completer [] { ["Allow All" "Reject Invalid" "Warn on Invalid"] }
def auth-mode-completer-1 [] { ["Certificate and Key" "None" "Username and Password"] }
def auth-mode-completer-2 [] { ["None" "Token" "Username and Password"] }
def auth-mode-completer-3 [] { ["None" "Token"] }
def mode-completer-1 [] { ["Cache Only" "Cache and Proxy" "Proxy Only"] }
def trust-level-completer [] { ["Trusted" "Untrusted"] }
def request-body-format-completer [] { ["0" "1" "2" "3"] }
def request-body-template-format-completer [] { ["0" "1" "2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "audit-log list" } } | get name | first)
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

# Lists audit log entries for a specific namespace.
#
# GET /audit-log/{owner}/
# operationId: audit_log_namespace_list
export def "audit-log list" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --qp-query: string # A search term for querying events, actors, or timestamps of log records.
]: nothing -> table<actor: string, actor_ip_address: string, actor_kind: string, actor_location: record<city: string, continent: string, country: string, country_code: string, latitude: string, longitude: string, postal_code: string>, actor_slug_perm: string, actor_url: string, context: string, event: string, event_at: string, object: string, object_kind: string, object_slug_perm: string, target: string, target_kind: string, target_slug_perm: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audit-log/($owner)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists audit log entries for a specific repository.
#
# GET /audit-log/{owner}/{repo}/
# operationId: audit_log_repo_list
export def "audit-log list-1" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --qp-query: string # A search term for querying events, actors, or timestamps of log records.
]: nothing -> table<actor: string, actor_ip_address: string, actor_kind: string, actor_location: record<city: string, continent: string, country: string, country_code: string, latitude: string, longitude: string, postal_code: string>, actor_slug_perm: string, actor_url: string, context: string, event: string, event_at: string, object: string, object_kind: string, object_slug_perm: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audit-log/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest package version for a package or package group.
#
# GET /badges/version/{owner}/{repo}/{package_format}/{package_name}/{package_version}/{package_identifiers}/
# operationId: badges_version_list
export def "badges-version list" [
  owner: string
  repo: string
  package_format: string
  package_name: string
  package_version: string
  package_identifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --badge-token: string # Badge token to authenticate for private packages (default: )
  --cacheSeconds: string # Override the shields.io badge cacheSeconds value. (default: 300)
  --color: string # Override the shields.io badge color value. (default: 12577E)
  --label: string # Override the shields.io badge label value. (default: cloudsmith)
  --labelColor: string # Override the shields.io badge labelColor value. (default: 021F2F)
  --logoColor: string # Override the shields.io badge logoColor value. (default: 45B6EE)
  --logoWidth: string # Override the shields.io badge logoWidth value. (default: 10)
  --render: string@bool-completer # If true, badge will be rendered (default: false)
  --shields: string@bool-completer # If true, a shields response will be generated (default: false)
  --show-latest: string@bool-completer # If true, for latest version badges a '(latest)' suffix is added (default: false)
  --style: string # Override the shields.io badge style value. (default: flat-square)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "badge_token" $badge_token "scalar") (serialize-qp "cacheSeconds" $cacheSeconds "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "labelColor" $labelColor "scalar") (serialize-qp "logoColor" $logoColor "scalar") (serialize-qp "logoWidth" $logoWidth "scalar") (serialize-qp "render" $render "scalar") (serialize-qp "shields" $shields "scalar") (serialize-qp "show_latest" $show_latest "scalar") (serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/badges/version/($owner)/($repo)/($package_format)/($package_name)/($package_version)/($package_identifiers)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a broadcast token.
#
# POST /broadcasts/{org}/broadcast-token/
# operationId: broadcasts_create_broadcast_token
export def "broadcasts-broadcast-token token" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entitlement_token: string # Repository entitlement token used to authorize the creation of a broadcast token
  --expires-in: int # Token expiry time in seconds (optional, defaults to 3600 seconds)
]: any -> record<expires_at: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/broadcasts/($org)/broadcast-token/")
  let body = {entitlement_token: $entitlement_token, expires_in: $expires_in} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Perform bulk operations on multiple packages within a repository or across all accessible repositories. If 'repository' is provided, actions are limited to that repository. If 'repository' is omitted, actions are performed across all repositories the user has access to within the workspace. Returns a list of successfully actioned packages and any packages that failed with error details. 
#
# POST /bulk-action/{owner}/
# operationId: bulk_action
export def "bulk-action action" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string@action-completer # The action to perform on the packages.
  identifiers: list # A list of package identifiers to apply the action to.
  --repository: string # The repository name to filter packages to. If not provided, the action will be performed across all accessible repositories in the workspace.
  --target-repository: string # The slug of the target repository
]: any -> record<action: string, packages_actioned: list<string>, packages_failed_to_action: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk-action/($owner)/")
  let body = {action: $action, identifiers: $identifiers, repository: $repository, target_repository: $target_repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of all supported distributions.
#
# GET /distros/
# operationId: distros_list
export def "distros list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<format: string, format_url: string, name: string, self_url: string, slug: string, variants: string, versions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/distros/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View for viewing/listing distributions.
#
# GET /distros/{slug}/
# operationId: distros_read
export def "distros read" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<format: string, format_url: string, name: string, self_url: string, slug: string, variants: string, versions: table<name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/distros/($slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all entitlements in a repository.
#
# GET /entitlements/{owner}/{repo}/
# operationId: entitlements_list
export def "entitlements list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
  --qp-query: string # A search term for querying names of entitlements.
  --active: string@bool-completer # If true, only include active tokens (default: false)
  --exclude-other-user-tokens: string@bool-completer # If true, exclude user tokens that belong to other users (default: false)
  --qp-sort: string # A field for sorting objects in ascending or descending order. Use `-` prefix for descending order (e.g., `-name`). Available options: name. (default: name)
]: nothing -> table<access_private_broadcasts: bool, clients: int, created_at: string, created_by: string, created_by_url: string, default: bool, disable_url: string, downloads: int, enable_url: string, eula_accepted: record<identifier: string, number: int>, eula_accepted_at: string, eula_accepted_from: string, eula_required: bool, has_limits: bool, identifier: int, is_active: bool, is_limited: bool, limit_bandwidth: int, limit_bandwidth_unit: string, limit_date_range_from: string, limit_date_range_to: string, limit_num_clients: int, limit_num_downloads: int, limit_package_query: string, limit_path_query: string, metadata: record, name: string, refresh_url: string, reset_url: string, scheduled_reset_at: string, scheduled_reset_period: string, self_url: string, slug_perm: string, token: string, updated_at: string, updated_by: string, updated_by_url: string, usage: string, user: string, user_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "show_tokens" $show_tokens "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "exclude_other_user_tokens" $exclude_other_user_tokens "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a specific entitlement in a repository.
#
# POST /entitlements/{owner}/{repo}/
# operationId: entitlements_create
export def "entitlements create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
  --eula-required: string@bool-completer # If checked, a EULA acceptance is required for this token.
  --is-active: string@bool-completer # If enabled, the token will allow downloads based on configured restrictions (if any).
  --limit-bandwidth: int # The maximum download bandwidth allowed for the token. Values are expressed as the selected unit of bandwidth. Please note that since downloads are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point. 
  --limit-bandwidth-unit: string@limit-bandwidth-unit-completer # default: Byte
  --limit-date-range-from: string # The starting date/time the token is allowed to be used from. (format: date-time)
  --limit-date-range-to: string # The ending date/time the token is allowed to be used until. (format: date-time)
  --limit-num-clients: int # The maximum number of unique clients allowed for the token. Please note that since clients are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point.
  --limit-num-downloads: int # The maximum number of downloads allowed for the token. Please note that since downloads are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point.
  --limit-package-query: string # The package-based search query to apply to restrict downloads to. This uses the same syntax as the standard search used for repositories, and also supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. This will still allow access to non-package files, such as metadata.
  --limit-path-query: string # THIS WILL SOON BE DEPRECATED, please use limit_package_query instead. The path-based search query to apply to restrict downloads to. This supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. The path evaluated does not include the domain name, the namespace, the entitlement code used, the package format, etc. and it always starts with a forward slash.
  --metadata: record
  name: string
  --scheduled-reset-at: string # The time at which the scheduled reset period has elapsed and the token limits were automatically reset to zero. (format: date-time)
  --scheduled-reset-period: string@scheduled-reset-period-completer # default: Never Reset
  --body-token: string
]: any -> record<access_private_broadcasts: bool, clients: int, created_at: string, created_by: string, created_by_url: string, default: bool, disable_url: string, downloads: int, enable_url: string, eula_accepted: record<identifier: string, number: int>, eula_accepted_at: string, eula_accepted_from: string, eula_required: bool, has_limits: bool, identifier: int, is_active: bool, is_limited: bool, limit_bandwidth: int, limit_bandwidth_unit: string, limit_date_range_from: string, limit_date_range_to: string, limit_num_clients: int, limit_num_downloads: int, limit_package_query: string, limit_path_query: string, metadata: record, name: string, refresh_url: string, reset_url: string, scheduled_reset_at: string, scheduled_reset_period: string, self_url: string, slug_perm: string, token: string, updated_at: string, updated_by: string, updated_by_url: string, usage: string, user: string, user_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_tokens" $show_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/" $qp)
  let body = {eula_required: $eula_required, is_active: $is_active, limit_bandwidth: $limit_bandwidth, limit_bandwidth_unit: $limit_bandwidth_unit, limit_date_range_from: $limit_date_range_from, limit_date_range_to: $limit_date_range_to, limit_num_clients: $limit_num_clients, limit_num_downloads: $limit_num_downloads, limit_package_query: $limit_package_query, limit_path_query: $limit_path_query, metadata: $metadata, name: $name, scheduled_reset_at: $scheduled_reset_at, scheduled_reset_period: $scheduled_reset_period, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Synchronise tokens from a source repository.
#
# POST /entitlements/{owner}/{repo}/sync/
# operationId: entitlements_sync
export def "entitlements-sync sync" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
  --body-source: string # The source repository slug (in the same owner namespace).
]: any -> record<tokens: table<access_private_broadcasts: bool, clients: int, created_at: string, created_by: string, created_by_url: string, default: bool, disable_url: string, downloads: int, enable_url: string, eula_accepted: record, eula_accepted_at: string, eula_accepted_from: string, eula_required: bool, has_limits: bool, identifier: int, is_active: bool, is_limited: bool, limit_bandwidth: int, limit_bandwidth_unit: string, limit_date_range_from: string, limit_date_range_to: string, limit_num_clients: int, limit_num_downloads: int, limit_package_query: string, limit_path_query: string, metadata: record, name: string, refresh_url: string, reset_url: string, scheduled_reset_at: string, scheduled_reset_period: string, self_url: string, slug_perm: string, token: string, updated_at: string, updated_by: string, updated_by_url: string, usage: string, user: string, user_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_tokens" $show_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/sync/" $qp)
  let body = {source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific entitlement in a repository.
#
# GET /entitlements/{owner}/{repo}/{identifier}/
# operationId: entitlements_read
export def "entitlements read" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fuzzy: string@bool-completer # If true, entitlement identifiers including name will be fuzzy matched. (default: false)
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
]: nothing -> record<access_private_broadcasts: bool, clients: int, created_at: string, created_by: string, created_by_url: string, default: bool, disable_url: string, downloads: int, enable_url: string, eula_accepted: record<identifier: string, number: int>, eula_accepted_at: string, eula_accepted_from: string, eula_required: bool, has_limits: bool, identifier: int, is_active: bool, is_limited: bool, limit_bandwidth: int, limit_bandwidth_unit: string, limit_date_range_from: string, limit_date_range_to: string, limit_num_clients: int, limit_num_downloads: int, limit_package_query: string, limit_path_query: string, metadata: record, name: string, refresh_url: string, reset_url: string, scheduled_reset_at: string, scheduled_reset_period: string, self_url: string, slug_perm: string, token: string, updated_at: string, updated_by: string, updated_by_url: string, usage: string, user: string, user_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fuzzy" $fuzzy "scalar") (serialize-qp "show_tokens" $show_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific entitlement in a repository.
#
# PATCH /entitlements/{owner}/{repo}/{identifier}/
# operationId: entitlements_partial_update
export def "entitlements patch" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
  --eula-required: string@bool-completer # If checked, a EULA acceptance is required for this token.
  --is-active: string@bool-completer # If enabled, the token will allow downloads based on configured restrictions (if any).
  --limit-bandwidth: int # The maximum download bandwidth allowed for the token. Values are expressed as the selected unit of bandwidth. Please note that since downloads are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point. 
  --limit-bandwidth-unit: string@limit-bandwidth-unit-completer # default: Byte
  --limit-date-range-from: string # The starting date/time the token is allowed to be used from. (format: date-time)
  --limit-date-range-to: string # The ending date/time the token is allowed to be used until. (format: date-time)
  --limit-num-clients: int # The maximum number of unique clients allowed for the token. Please note that since clients are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point.
  --limit-num-downloads: int # The maximum number of downloads allowed for the token. Please note that since downloads are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point.
  --limit-package-query: string # The package-based search query to apply to restrict downloads to. This uses the same syntax as the standard search used for repositories, and also supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. This will still allow access to non-package files, such as metadata.
  --limit-path-query: string # THIS WILL SOON BE DEPRECATED, please use limit_package_query instead. The path-based search query to apply to restrict downloads to. This supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. The path evaluated does not include the domain name, the namespace, the entitlement code used, the package format, etc. and it always starts with a forward slash.
  --metadata: record
  --name: string
  --scheduled-reset-at: string # The time at which the scheduled reset period has elapsed and the token limits were automatically reset to zero. (format: date-time)
  --scheduled-reset-period: string@scheduled-reset-period-completer # default: Never Reset
  --body-token: string
]: any -> record<access_private_broadcasts: bool, clients: int, created_at: string, created_by: string, created_by_url: string, default: bool, disable_url: string, downloads: int, enable_url: string, eula_accepted: record<identifier: string, number: int>, eula_accepted_at: string, eula_accepted_from: string, eula_required: bool, has_limits: bool, identifier: int, is_active: bool, is_limited: bool, limit_bandwidth: int, limit_bandwidth_unit: string, limit_date_range_from: string, limit_date_range_to: string, limit_num_clients: int, limit_num_downloads: int, limit_package_query: string, limit_path_query: string, metadata: record, name: string, refresh_url: string, reset_url: string, scheduled_reset_at: string, scheduled_reset_period: string, self_url: string, slug_perm: string, token: string, updated_at: string, updated_by: string, updated_by_url: string, usage: string, user: string, user_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_tokens" $show_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/" $qp)
  let body = {eula_required: $eula_required, is_active: $is_active, limit_bandwidth: $limit_bandwidth, limit_bandwidth_unit: $limit_bandwidth_unit, limit_date_range_from: $limit_date_range_from, limit_date_range_to: $limit_date_range_to, limit_num_clients: $limit_num_clients, limit_num_downloads: $limit_num_downloads, limit_package_query: $limit_package_query, limit_path_query: $limit_path_query, metadata: $metadata, name: $name, scheduled_reset_at: $scheduled_reset_at, scheduled_reset_period: $scheduled_reset_period, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific entitlement in a repository.
#
# DELETE /entitlements/{owner}/{repo}/{identifier}/
# operationId: entitlements_delete
export def "entitlements delete" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable an entitlement token in a repository.
#
# POST /entitlements/{owner}/{repo}/{identifier}/disable/
# operationId: entitlements_disable
export def "entitlements-disable disable" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/disable/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable an entitlement token in a repository.
#
# POST /entitlements/{owner}/{repo}/{identifier}/enable/
# operationId: entitlements_enable
export def "entitlements-enable enable" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/enable/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh an entitlement token in a repository.
#
# POST /entitlements/{owner}/{repo}/{identifier}/refresh/
# operationId: entitlements_refresh
export def "entitlements-refresh refresh" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
  --eula-required: string@bool-completer # If checked, a EULA acceptance is required for this token.
  --is-active: string@bool-completer # If enabled, the token will allow downloads based on configured restrictions (if any).
  --limit-bandwidth: int # The maximum download bandwidth allowed for the token. Values are expressed as the selected unit of bandwidth. Please note that since downloads are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point. 
  --limit-bandwidth-unit: string@limit-bandwidth-unit-completer # default: Byte
  --limit-date-range-from: string # The starting date/time the token is allowed to be used from. (format: date-time)
  --limit-date-range-to: string # The ending date/time the token is allowed to be used until. (format: date-time)
  --limit-num-clients: int # The maximum number of unique clients allowed for the token. Please note that since clients are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point.
  --limit-num-downloads: int # The maximum number of downloads allowed for the token. Please note that since downloads are calculated asynchronously (after the download happens), the limit may not be imposed immediately but at a later point.
  --limit-package-query: string # The package-based search query to apply to restrict downloads to. This uses the same syntax as the standard search used for repositories, and also supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. This will still allow access to non-package files, such as metadata.
  --limit-path-query: string # THIS WILL SOON BE DEPRECATED, please use limit_package_query instead. The path-based search query to apply to restrict downloads to. This supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. The path evaluated does not include the domain name, the namespace, the entitlement code used, the package format, etc. and it always starts with a forward slash.
  --metadata: record
  --scheduled-reset-at: string # The time at which the scheduled reset period has elapsed and the token limits were automatically reset to zero. (format: date-time)
  --scheduled-reset-period: string@scheduled-reset-period-completer # default: Never Reset
  --body-token: string
]: any -> record<access_private_broadcasts: bool, clients: int, created_at: string, created_by: string, created_by_url: string, default: bool, disable_url: string, downloads: int, enable_url: string, eula_accepted: record<identifier: string, number: int>, eula_accepted_at: string, eula_accepted_from: string, eula_required: bool, has_limits: bool, identifier: int, is_active: bool, is_limited: bool, limit_bandwidth: int, limit_bandwidth_unit: string, limit_date_range_from: string, limit_date_range_to: string, limit_num_clients: int, limit_num_downloads: int, limit_package_query: string, limit_path_query: string, metadata: record, name: string, refresh_url: string, reset_url: string, scheduled_reset_at: string, scheduled_reset_period: string, self_url: string, slug_perm: string, token: string, updated_at: string, updated_by: string, updated_by_url: string, usage: string, user: string, user_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_tokens" $show_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/refresh/" $qp)
  let body = {eula_required: $eula_required, is_active: $is_active, limit_bandwidth: $limit_bandwidth, limit_bandwidth_unit: $limit_bandwidth_unit, limit_date_range_from: $limit_date_range_from, limit_date_range_to: $limit_date_range_to, limit_num_clients: $limit_num_clients, limit_num_downloads: $limit_num_downloads, limit_package_query: $limit_package_query, limit_path_query: $limit_path_query, metadata: $metadata, scheduled_reset_at: $scheduled_reset_at, scheduled_reset_period: $scheduled_reset_period, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the statistics for an entitlement token in a repository.
#
# POST /entitlements/{owner}/{repo}/{identifier}/reset/
# operationId: entitlements_reset
export def "entitlements-reset reset" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-tokens: string@bool-completer # Show entitlement token strings in results (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_tokens" $show_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/reset/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set private broadcast access for an entitlement token in a repository.
#
# POST /entitlements/{owner}/{repo}/{identifier}/toggle-private-broadcasts/
# operationId: entitlements_toggle_private_broadcasts
export def "entitlements-toggle-private-broadcasts broadcasts" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-private-broadcasts: string@bool-completer # Whether the token should have access to private broadcasts.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entitlements/($owner)/($repo)/($identifier)/toggle-private-broadcasts/")
  let body = {access_private_broadcasts: $access_private_broadcasts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request URL(s) to upload new package file upload(s) to.
#
# POST /files/{owner}/{repo}/
# operationId: files_create
export def "files create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # Filename for the package file upload.
  --md5-checksum: string # MD5 checksum for a POST-based package file upload.
  --method: string@method-completer # The method to use for package file upload. (default: post)
  --sha256-checksum: string # SHA256 checksum for a PUT-based package file upload.
]: any -> record<identifier: string, upload_fields: record, upload_headers: record, upload_querystring: string, upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($owner)/($repo)/")
  let body = {filename: $filename, md5_checksum: $md5_checksum, method: $method, sha256_checksum: $sha256_checksum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters used for create.
#
# POST /files/{owner}/{repo}/validate/
# operationId: files_validate
export def "files-validate validate" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # Filename for the package file upload.
  --md5-checksum: string # MD5 checksum for a POST-based package file upload.
  --method: string@method-completer # The method to use for package file upload. (default: post)
  --sha256-checksum: string # SHA256 checksum for a PUT-based package file upload.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($owner)/($repo)/validate/")
  let body = {filename: $filename, md5_checksum: $md5_checksum, method: $method, sha256_checksum: $sha256_checksum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Abort a multipart file upload.
#
# POST /files/{owner}/{repo}/{identifier}/abort/
# operationId: files_abort
export def "files-abort abort" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # Filename for the package file upload.
  --md5-checksum: string # MD5 checksum for a POST-based package file upload.
  --method: string@method-completer # The method to use for package file upload. (default: post)
  --sha256-checksum: string # SHA256 checksum for a PUT-based package file upload.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($owner)/($repo)/($identifier)/abort/")
  let body = {filename: $filename, md5_checksum: $md5_checksum, method: $method, sha256_checksum: $sha256_checksum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete a multipart file upload.
#
# POST /files/{owner}/{repo}/{identifier}/complete/
# operationId: files_complete
export def "files-complete complete" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # Filename for the package file upload.
  --md5-checksum: string # MD5 checksum for a POST-based package file upload.
  --method: string@method-completer # The method to use for package file upload. (default: post)
  --sha256-checksum: string # SHA256 checksum for a PUT-based package file upload.
]: any -> record<identifier: string, upload_fields: record, upload_headers: record, upload_querystring: string, upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($owner)/($repo)/($identifier)/complete/")
  let body = {filename: $filename, md5_checksum: $md5_checksum, method: $method, sha256_checksum: $sha256_checksum} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get upload information to perform a multipart file upload.
#
# GET /files/{owner}/{repo}/{identifier}/info/
# operationId: files_info
export def "files-info info" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # The filename of the file being uploaded
  --part-number: int # The part number to be uploaded next
]: nothing -> record<identifier: string, upload_querystring: string, upload_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filename" $filename "scalar") (serialize-qp "part_number" $part_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($owner)/($repo)/($identifier)/info/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all supported package formats.
#
# GET /formats/
# operationId: formats_list
export def "formats list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<description: string, distributions: list<record>, extensions: list<string>, name: string, premium: bool, premium_plan_id: string, premium_plan_name: string, slug: string, supports: record<dependencies: bool, distributions: bool, file_lists: bool, filepaths: bool, metadata: bool, upstreams: record, versioning: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/formats/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific supported package format.
#
# GET /formats/{slug}/
# operationId: formats_read
export def "formats read" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, distributions: table<name: string, self_url: string, slug: string, variants: string>, extensions: list<string>, name: string, premium: bool, premium_plan_id: string, premium_plan_name: string, slug: string, supports: record<dependencies: bool, distributions: bool, file_lists: bool, filepaths: bool, metadata: bool, upstreams: record<auth_modes: list, caching: bool, indexing: bool, indexing_behavior: string, proxying: bool, signature_verification: string, trust: bool>, versioning: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/formats/($slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View for listing entitlement token metrics, across an account.
#
# GET /metrics/entitlements/{owner}/
# operationId: metrics_entitlements_account_list
export def "metrics-entitlements list" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --finish: string # Include metrics upto and including this UTC date or UTC datetime. For example '2020-12-31' or '2021-12-13T00:00:00Z'.
  --start: string # Include metrics from and including this UTC date or UTC datetime. For example '2020-12-31' or '2021-12-13T00:00:00Z'.
  --tokens: string # A comma seperated list of tokens (slug perm) to include in the results.
]: nothing -> record<tokens: record<active: int, bandwidth: record<average: record, highest: record, lowest: record, total: record>, downloads: record<average: record, highest: record, lowest: record, total: record>, inactive: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "finish" $finish "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "tokens" $tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metrics/entitlements/($owner)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View for listing entitlement token metrics, for a repository.
#
# GET /metrics/entitlements/{owner}/{repo}/
# operationId: metrics_entitlements_repo_list
export def "metrics-entitlements list-1" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --finish: string # Include metrics upto and including this UTC date or UTC datetime. For example '2020-12-31' or '2021-12-13T00:00:00Z'.
  --start: string # Include metrics from and including this UTC date or UTC datetime. For example '2020-12-31' or '2021-12-13T00:00:00Z'.
  --tokens: string # A comma seperated list of tokens (slug perm) to include in the results.
]: nothing -> record<tokens: record<active: int, bandwidth: record<average: record, highest: record, lowest: record, total: record>, downloads: record<average: record, highest: record, lowest: record, total: record>, inactive: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "finish" $finish "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "tokens" $tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metrics/entitlements/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# View for listing package usage metrics, for a repository.
#
# GET /metrics/packages/{owner}/{repo}/
# operationId: metrics_packages_list
export def "metrics-packages list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --finish: string # Include metrics upto and including this UTC date or UTC datetime. For example '2020-12-31' or '2021-12-13T00:00:00Z'.
  --packages: string # A comma seperated list of packages (slug perm) to include in the results.
  --start: string # Include metrics from and including this UTC date or UTC datetime. For example '2020-12-31' or '2021-12-13T00:00:00Z'.
]: nothing -> record<packages: record<active: int, bandwidth: record<average: record, highest: record, lowest: record, total: record>, downloads: record<average: record, highest: record, lowest: record, total: record>, inactive: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "finish" $finish "scalar") (serialize-qp "packages" $packages "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metrics/packages/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all namespaces the user belongs to.
#
# GET /namespaces/
# operationId: namespaces_list
export def "namespaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<name: string, slug: string, slug_perm: string, type_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/namespaces/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific namespace that the user belongs to.
#
# GET /namespaces/{slug}/
# operationId: namespaces_read
export def "namespaces read" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, slug: string, slug_perm: string, type_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all the organizations you are associated with.
#
# GET /orgs/
# operationId: orgs_list
export def "orgs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<country: string, created_at: string, location: string, name: string, slug: string, slug_perm: string, tagline: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details for the specific organization.
#
# GET /orgs/{org}/
# operationId: orgs_read
export def "orgs read" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<country: string, created_at: string, location: string, name: string, slug: string, slug_perm: string, tagline: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specified organization.
#
# DELETE /orgs/{org}/
# operationId: orgs_delete
export def "orgs delete" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details for all custom domains.
#
# GET /orgs/{org}/custom-domains/
# operationId: orgs_custom-domains_list
export def "orgs-custom-domains list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<backend_kind: int, created_at: string, created_by: int, dns_alias_value: string, dns_cert_name: string, dns_cert_value: string, domain_type: int, enabled: bool, host: string, namespace: int, primary: bool, redirect_root: bool, redirect_root_url: string, repository: record<name: string, slug: string>, repository_only: bool, slug_perm: string, validated: bool, validated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/custom-domains/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all package deny policies.
#
# GET /orgs/{org}/deny-policy/
# operationId: orgs_deny-policy_list
export def "orgs-deny-policy list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<action: string, created_at: string, description: string, enabled: bool, name: string, package_query_string: string, slug_perm: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/deny-policy/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a package deny policy.
#
# POST /orgs/{org}/deny-policy/
# operationId: orgs_deny-policy_create
export def "orgs-deny-policy create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --enabled: string@bool-completer # Whether this rule is enabled or disabled.
  --name: string
  package_query_string: string # Packages that match this query will trigger this deny rule.
]: any -> record<action: string, created_at: string, description: string, enabled: bool, name: string, package_query_string: string, slug_perm: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/deny-policy/")
  let body = {description: $description, enabled: $enabled, name: $name, package_query_string: $package_query_string} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a package deny policy.
#
# GET /orgs/{org}/deny-policy/{slug_perm}/
# operationId: orgs_deny-policy_read
export def "orgs-deny-policy read" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: string, created_at: string, description: string, enabled: bool, name: string, package_query_string: string, slug_perm: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/deny-policy/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a package deny policy.
#
# PUT /orgs/{org}/deny-policy/{slug_perm}/
# operationId: orgs_deny-policy_update
export def "orgs-deny-policy update" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --enabled: string@bool-completer # Whether this rule is enabled or disabled.
  --name: string
  package_query_string: string # Packages that match this query will trigger this deny rule.
]: any -> record<action: string, created_at: string, description: string, enabled: bool, name: string, package_query_string: string, slug_perm: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/deny-policy/($slug_perm)/")
  let body = {description: $description, enabled: $enabled, name: $name, package_query_string: $package_query_string} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a package deny policy.
#
# PATCH /orgs/{org}/deny-policy/{slug_perm}/
# operationId: orgs_deny-policy_partial_update
export def "orgs-deny-policy patch" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --enabled: string@bool-completer # Whether this rule is enabled or disabled.
  --name: string
  --package-query-string: string # Packages that match this query will trigger this deny rule.
]: any -> record<action: string, created_at: string, description: string, enabled: bool, name: string, package_query_string: string, slug_perm: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/deny-policy/($slug_perm)/")
  let body = {description: $description, enabled: $enabled, name: $name, package_query_string: $package_query_string} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a package deny policy.
#
# DELETE /orgs/{org}/deny-policy/{slug_perm}/
# operationId: orgs_deny-policy_delete
export def "orgs-deny-policy delete" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/deny-policy/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all invites for an organization.
#
# GET /orgs/{org}/invites/
# operationId: orgs_invites_list
export def "orgs-invites list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<email: string, expires_at: string, inviter: string, inviter_url: string, org: string, role: string, slug_perm: string, teams: list<record>, user: string, user_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/invites/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization invite for a specific user
#
# POST /orgs/{org}/invites/
# operationId: orgs_invites_create
# --teams item shape: {role?: "Manager"|"Member", team: string}
export def "orgs-invites create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email of the user to be invited. (format: email)
  --role: string@role-completer # The role to be assigned to the invited user. (default: Member)
  --teams: list # item shape: {role?: "Manager"|"Member", team: string}
  --user: string # The slug of the user to be invited.
]: any -> record<email: string, expires_at: string, inviter: string, inviter_url: string, org: string, role: string, slug_perm: string, teams: table<role: string, team: string>, user: string, user_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/invites/")
  let body = {email: $email, role: $role, teams: $teams, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a specific organization invite.
#
# PATCH /orgs/{org}/invites/{slug_perm}/
# operationId: orgs_invites_partial_update
export def "orgs-invites patch" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer # The role to be assigned to the invited user. (default: Member)
]: any -> record<email: string, expires_at: string, inviter: string, inviter_url: string, org: string, role: string, slug_perm: string, teams: table<role: string, team: string>, user: string, user_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/invites/($slug_perm)/")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific organization invite
#
# DELETE /orgs/{org}/invites/{slug_perm}/
# operationId: orgs_invites_delete
export def "orgs-invites delete" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/invites/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extend an organization invite.
#
# POST /orgs/{org}/invites/{slug_perm}/extend/
# operationId: orgs_invites_extend
export def "orgs-invites-extend extend" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, expires_at: string, inviter: string, inviter_url: string, org: string, role: string, slug_perm: string, teams: table<role: string, team: string>, user: string, user_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/invites/($slug_perm)/extend/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend an organization invite.
#
# POST /orgs/{org}/invites/{slug_perm}/resend/
# operationId: orgs_invites_resend
export def "orgs-invites-resend resend" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, expires_at: string, inviter: string, inviter_url: string, org: string, role: string, slug_perm: string, teams: table<role: string, team: string>, user: string, user_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/invites/($slug_perm)/resend/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all current license policy violations for this Organization.
#
# GET /orgs/{org}/license-policy-violation/
# operationId: orgs_license-policy-violation_list
export def "orgs-license-policy-violation list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The pagination cursor value.
  --page-size: int # Number of results to return per page.
]: nothing -> record<next: string, previous: string, results: table<event_at: string, package: record, policy: record, reasons: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/license-policy-violation/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all package license policies.
#
# GET /orgs/{org}/license-policy/
# operationId: orgs_license-policy_list
export def "orgs-license-policy list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/license-policy/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a package license policy.
#
# POST /orgs/{org}/license-policy/
# operationId: orgs_license-policy_create
export def "orgs-license-policy create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-unknown-licenses: string@bool-completer
  --description: string
  name: string
  --on-violation-quarantine: string@bool-completer
  --package-query-string: string
  spdx_identifiers: list
]: any -> record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/")
  let body = {allow_unknown_licenses: $allow_unknown_licenses, description: $description, name: $name, on_violation_quarantine: $on_violation_quarantine, package_query_string: $package_query_string, spdx_identifiers: $spdx_identifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List evaluation requests for this policy.
#
# GET /orgs/{org}/license-policy/{policy_slug_perm}/evaluation/
# operationId: orgs_license-policy_evaluation_list
export def "orgs-license-policy-evaluation list" [
  org: string
  policy_slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<created_at: string, evaluation_count: int, policy: record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list, updated_at: string, url: string>, slug_perm: string, status: string, updated_at: string, violation_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($policy_slug_perm)/evaluation/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an evaluation request for this policy.
#
# POST /orgs/{org}/license-policy/{policy_slug_perm}/evaluation/
# operationId: orgs_license-policy_evaluation_create
export def "orgs-license-policy-evaluation create" [
  org: string
  policy_slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<created_at: string, evaluation_count: int, policy: record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string, url: string>, slug_perm: string, status: string, updated_at: string, violation_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($policy_slug_perm)/evaluation/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an evaluation request for this policy.
#
# GET /orgs/{org}/license-policy/{policy_slug_perm}/evaluation/{slug_perm}/
# operationId: orgs_license-policy_evaluation_read
export def "orgs-license-policy-evaluation read" [
  org: string
  policy_slug_perm: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, evaluation_count: int, policy: record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string, url: string>, slug_perm: string, status: string, updated_at: string, violation_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($policy_slug_perm)/evaluation/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package license policy.
#
# GET /orgs/{org}/license-policy/{slug_perm}/
# operationId: orgs_license-policy_read
export def "orgs-license-policy read" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a package license policy.
#
# PUT /orgs/{org}/license-policy/{slug_perm}/
# operationId: orgs_license-policy_update
export def "orgs-license-policy update" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-unknown-licenses: string@bool-completer
  --description: string
  name: string
  --on-violation-quarantine: string@bool-completer
  --package-query-string: string
  spdx_identifiers: list
]: any -> record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($slug_perm)/")
  let body = {allow_unknown_licenses: $allow_unknown_licenses, description: $description, name: $name, on_violation_quarantine: $on_violation_quarantine, package_query_string: $package_query_string, spdx_identifiers: $spdx_identifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a package license policy.
#
# PATCH /orgs/{org}/license-policy/{slug_perm}/
# operationId: orgs_license-policy_partial_update
export def "orgs-license-policy patch" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-unknown-licenses: string@bool-completer
  --description: string
  --name: string
  --on-violation-quarantine: string@bool-completer
  --package-query-string: string
  --spdx-identifiers: list
]: any -> record<allow_unknown_licenses: bool, created_at: string, description: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, spdx_identifiers: list<string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($slug_perm)/")
  let body = {allow_unknown_licenses: $allow_unknown_licenses, description: $description, name: $name, on_violation_quarantine: $on_violation_quarantine, package_query_string: $package_query_string, spdx_identifiers: $spdx_identifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a package license policy.
#
# DELETE /orgs/{org}/license-policy/{slug_perm}/
# operationId: orgs_license-policy_delete
export def "orgs-license-policy delete" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/license-policy/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details for all organization members.
#
# GET /orgs/{org}/members/
# operationId: orgs_members_list
export def "orgs-members list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --is-active: string@bool-completer # Filter for active/inactive users. (default: false)
  --qp-query: string # A search term for querying of members within an Organization.Available options are: email, org, user, userslug, inactive, user_name, role (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. Use `-` prefix for descending order (e.g., `-user_name`). Available options: user_name, role. (default: user_name)
]: nothing -> table<email: string, has_two_factor: bool, is_active: bool, joined_at: string, last_login_at: string, last_login_method: string, role: string, teams: list<record>, user: string, user_id: string, user_name: string, user_url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/members/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details for a specific organization member.
#
# GET /orgs/{org}/members/{member}/
# operationId: orgs_members_read
export def "orgs-members read" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, has_two_factor: bool, is_active: bool, joined_at: string, last_login_at: string, last_login_method: string, role: string, teams: table<name: string, role: string, slug: string>, user: string, user_id: string, user_name: string, user_url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Views for working with organization members.
#
# PATCH /orgs/{org}/members/{member}/
# operationId: orgs_members_partial_update
export def "orgs-members patch" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<email: string, has_two_factor: bool, is_active: bool, joined_at: string, last_login_at: string, last_login_method: string, role: string, teams: table<name: string, role: string, slug: string>, user: string, user_id: string, user_name: string, user_url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a member from the organization.
#
# DELETE /orgs/{org}/members/{member}/
# operationId: orgs_members_delete
export def "orgs-members delete" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh a member of the organization's API key.
#
# POST /orgs/{org}/members/{member}/refresh/
# operationId: orgs_members_refresh
export def "orgs-members-refresh refresh" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/refresh/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes a member from the organization (deprecated, use DELETE instead).
#
# GET /orgs/{org}/members/{member}/remove/
# operationId: orgs_members_remove
export def "orgs-members-remove remove" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/remove/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a member's role in the organization.
#
# PATCH /orgs/{org}/members/{member}/update-role/
# operationId: orgs_members_update_role
export def "orgs-members-update-role role" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer # default: Owner
]: any -> record<email: string, has_two_factor: bool, joined_at: string, last_login_at: string, last_login_method: string, role: string, user: string, user_id: string, user_name: string, user_url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/update-role/")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a member's visibility in the organization.
#
# PATCH /orgs/{org}/members/{member}/update-visibility/
# operationId: orgs_members_update_visibility
export def "orgs-members-update-visibility visibility" [
  org: string
  member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string@visibility-completer # default: Public
]: any -> record<email: string, has_two_factor: bool, joined_at: string, last_login_at: string, last_login_method: string, role: string, user: string, user_id: string, user_name: string, user_url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($member)/update-visibility/")
  let body = {visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the list of OpenID Connect provider settings for the org.
#
# GET /orgs/{org}/openid-connect/
# operationId: orgs_openid-connect_list
export def "orgs-openid-connect list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --qp-query: string # A search term for querying of OpenID Connect (OIDC) provider settings.Available options are: name, provider_url, service_account (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. Use `-` prefix for descending order (e.g., `-name`). Available options: name. (default: name)
]: nothing -> table<claims: record, enabled: bool, mapping_claim: string, name: string, provider_url: string, service_accounts: list<string>, slug: string, slug_perm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create the OpenID Connect provider settings for the org.
#
# POST /orgs/{org}/openid-connect/
# operationId: orgs_openid-connect_create
# --dynamic_mappings item shape: {claim_value: string, service_account: string}
export def "orgs-openid-connect create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  claims: record # The set of claims that any received tokens from the provider must contain to authenticate as the configured service account.
  --dynamic-mappings: list # The dynamic mappings of `mapping_claim` values to service accounts. Cannot be provided if `service_accounts` is also set.  Note: This field and the dynamic mappings feature are still in early access. Breaking changes are possible as we receive feedback on this feature. — item shape: {claim_value: string, service_account: string}
  --enabled: string@bool-completer # Whether the provider settings should be used for incoming OIDC requests.
  --mapping-claim: string # The OIDC claim to use for mapping to service accounts in dynamic_mappings. Cannot be provided if `service_accounts` is also set.  Note: This field and the dynamic mappings feature are still in early access. Breaking changes are possible as we receive feedback on this feature.
  name: string # The name of the provider settings are being configured for
  provider_url: string # The URL from the provider that serves as the base for the OpenID configuration. For example, if the OpenID configuration is available at https://token.actions.githubusercontent.com/.well-known/openid-configuration, the provider URL would be https://token.actions.githubusercontent.com/ (format: uri)
  --service-accounts: list # The service accounts associated with these provider settings. Cannot be provided if `mapping_claim` or `dynamic_mappings` are specified.
]: any -> record<claims: record, dynamic_mappings: table<claim_value: string, service_account: string>, enabled: bool, mapping_claim: string, name: string, provider_url: string, service_accounts: list<string>, slug: string, slug_perm: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/")
  let body = {claims: $claims, dynamic_mappings: $dynamic_mappings, enabled: $enabled, mapping_claim: $mapping_claim, name: $name, provider_url: $provider_url, service_accounts: $service_accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the list of OpenID Connect dynamic mappings for the provider setting.
#
# GET /orgs/{org}/openid-connect/{provider_setting}/dynamic-mappings/
# operationId: orgs_openid-connect_dynamic-mappings_list
export def "orgs-openid-connect-dynamic-mappings list" [
  org: string
  provider_setting: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<claim_value: string, service_account: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/($provider_setting)/dynamic-mappings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific OpenID Connect dynamic mapping for the provider setting.
#
# GET /orgs/{org}/openid-connect/{provider_setting}/dynamic-mappings/{claim_value}/
# operationId: orgs_openid-connect_dynamic-mappings_read
export def "orgs-openid-connect-dynamic-mappings read" [
  org: string
  provider_setting: string
  claim_value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<claim_value: string, service_account: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/($provider_setting)/dynamic-mappings/($claim_value)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a specific OpenID Connect provider setting for the org.
#
# GET /orgs/{org}/openid-connect/{slug_perm}/
# operationId: orgs_openid-connect_read
export def "orgs-openid-connect read" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<claims: record, enabled: bool, mapping_claim: string, name: string, provider_url: string, service_accounts: list<string>, slug: string, slug_perm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific OpenID Connect provider setting for the org.
#
# PUT /orgs/{org}/openid-connect/{slug_perm}/
# operationId: orgs_openid-connect_update
# --dynamic_mappings item shape: {claim_value: string, service_account: string}
export def "orgs-openid-connect update" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  claims: record # The set of claims that any received tokens from the provider must contain to authenticate as the configured service account.
  --dynamic-mappings: list # The dynamic mappings of `mapping_claim` values to service accounts. Cannot be provided if `service_accounts` is also set.  Note: This field and the dynamic mappings feature are still in early access. Breaking changes are possible as we receive feedback on this feature. — item shape: {claim_value: string, service_account: string}
  --enabled: string@bool-completer # Whether the provider settings should be used for incoming OIDC requests.
  --mapping-claim: string # The OIDC claim to use for mapping to service accounts in dynamic_mappings. Cannot be provided if `service_accounts` is also set.  Note: This field and the dynamic mappings feature are still in early access. Breaking changes are possible as we receive feedback on this feature.
  name: string # The name of the provider settings are being configured for
  provider_url: string # The URL from the provider that serves as the base for the OpenID configuration. For example, if the OpenID configuration is available at https://token.actions.githubusercontent.com/.well-known/openid-configuration, the provider URL would be https://token.actions.githubusercontent.com/ (format: uri)
  --service-accounts: list # The service accounts associated with these provider settings. Cannot be provided if `mapping_claim` or `dynamic_mappings` are specified.
]: any -> record<claims: record, dynamic_mappings: table<claim_value: string, service_account: string>, enabled: bool, mapping_claim: string, name: string, provider_url: string, service_accounts: list<string>, slug: string, slug_perm: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/($slug_perm)/")
  let body = {claims: $claims, dynamic_mappings: $dynamic_mappings, enabled: $enabled, mapping_claim: $mapping_claim, name: $name, provider_url: $provider_url, service_accounts: $service_accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a specific OpenID Connect provider setting for the org.
#
# PATCH /orgs/{org}/openid-connect/{slug_perm}/
# operationId: orgs_openid-connect_partial_update
# --dynamic_mappings item shape: {claim_value: string, service_account: string}
export def "orgs-openid-connect patch" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --claims: record # The set of claims that any received tokens from the provider must contain to authenticate as the configured service account.
  --dynamic-mappings: list # The dynamic mappings of `mapping_claim` values to service accounts. Cannot be provided if `service_accounts` is also set.  Note: This field and the dynamic mappings feature are still in early access. Breaking changes are possible as we receive feedback on this feature. — item shape: {claim_value: string, service_account: string}
  --enabled: string@bool-completer # Whether the provider settings should be used for incoming OIDC requests.
  --mapping-claim: string # The OIDC claim to use for mapping to service accounts in dynamic_mappings. Cannot be provided if `service_accounts` is also set.  Note: This field and the dynamic mappings feature are still in early access. Breaking changes are possible as we receive feedback on this feature.
  --name: string # The name of the provider settings are being configured for
  --provider-url: string # The URL from the provider that serves as the base for the OpenID configuration. For example, if the OpenID configuration is available at https://token.actions.githubusercontent.com/.well-known/openid-configuration, the provider URL would be https://token.actions.githubusercontent.com/ (format: uri)
  --service-accounts: list # The service accounts associated with these provider settings. Cannot be provided if `mapping_claim` or `dynamic_mappings` are specified.
]: any -> record<claims: record, dynamic_mappings: table<claim_value: string, service_account: string>, enabled: bool, mapping_claim: string, name: string, provider_url: string, service_accounts: list<string>, slug: string, slug_perm: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/($slug_perm)/")
  let body = {claims: $claims, dynamic_mappings: $dynamic_mappings, enabled: $enabled, mapping_claim: $mapping_claim, name: $name, provider_url: $provider_url, service_accounts: $service_accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific OpenID Connect provider setting for the org.
#
# DELETE /orgs/{org}/openid-connect/{slug_perm}/
# operationId: orgs_openid-connect_delete
export def "orgs-openid-connect delete" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/openid-connect/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the SAML Authentication settings for this Organization.
#
# GET /orgs/{org}/saml-authentication
# operationId: orgs_saml-authentication_read
export def "orgs-saml-authentication read" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<saml_auth_enabled: bool, saml_auth_enforced: bool, saml_metadata_inline: string, saml_metadata_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-authentication")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the SAML Authentication settings for this Organization.
#
# PATCH /orgs/{org}/saml-authentication
# operationId: orgs_saml-authentication_partial_update
export def "orgs-saml-authentication patch" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --saml-auth-enabled: string@bool-completer
  --saml-auth-enforced: string@bool-completer
  --saml-metadata-inline: string # If configured, SAML metadata will be used as entered instead of retrieved from a remote URL.
  --saml-metadata-url: string # If configured, SAML metadata be retrieved from a remote URL. (format: uri)
]: any -> record<saml_auth_enabled: bool, saml_auth_enforced: bool, saml_metadata_inline: string, saml_metadata_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-authentication")
  let body = {saml_auth_enabled: $saml_auth_enabled, saml_auth_enforced: $saml_auth_enforced, saml_metadata_inline: $saml_metadata_inline, saml_metadata_url: $saml_metadata_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the details of all SAML Group Sync mapping within an organization.
#
# GET /orgs/{org}/saml-group-sync/
# operationId: orgs_saml-group-sync_list
export def "orgs-saml-group-sync list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<idp_key: string, idp_value: string, role: string, slug_perm: string, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/saml-group-sync/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new SAML Group Sync mapping within an organization.
#
# POST /orgs/{org}/saml-group-sync/
# operationId: orgs_saml-group-sync_create
export def "orgs-saml-group-sync create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  idp_key: string
  idp_value: string
  organization: string
  --role: string@role-completer-1 # default: Member
  team: string # format: slug
]: any -> record<idp_key: string, idp_value: string, role: string, slug_perm: string, team: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-group-sync/")
  let body = {idp_key: $idp_key, idp_value: $idp_value, organization: $organization, role: $role, team: $team} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable SAML Group Sync for this organization.
#
# POST /orgs/{org}/saml-group-sync/disable/
# operationId: orgs_saml-group-sync_disable
export def "orgs-saml-group-sync-disable disable" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-group-sync/disable/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable SAML Group Sync for this organization.
#
# POST /orgs/{org}/saml-group-sync/enable/
# operationId: orgs_saml-group-sync_enable
export def "orgs-saml-group-sync-enable enable" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-group-sync/enable/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the SAML Group Sync status for this organization.
#
# GET /orgs/{org}/saml-group-sync/status/
# operationId: orgs_saml-group-sync_status
export def "orgs-saml-group-sync-status status" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<saml_group_sync_status: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-group-sync/status/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a SAML Group Sync mapping from an organization.
#
# DELETE /orgs/{org}/saml-group-sync/{slug_perm}/
# operationId: orgs_saml-group-sync_delete
export def "orgs-saml-group-sync delete" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/saml-group-sync/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all services within an organization.
#
# GET /orgs/{org}/services/
# operationId: orgs_services_list
export def "orgs-services list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --qp-query: string # A search term for querying of services within an Organization.Available options are: name, role (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. Use `-` prefix for descending order (e.g., `-created_at`). Available options: created_at, name, role. (default: created_at)
]: nothing -> table<created_at: string, created_by: string, created_by_url: string, description: string, key: string, key_expires_at: string, name: string, role: string, slug: string, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service within an organization.
#
# POST /orgs/{org}/services/
# operationId: orgs_services_create
# --teams item shape: {role?: "Manager"|"Member", slug: string}
export def "orgs-services create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description of the service
  name: string # The name of the service
  --role: string@role-completer-1 # The role of the service. (default: Member)
  --teams: list # item shape: {role?: "Manager"|"Member", slug: string}
]: any -> record<created_at: string, created_by: string, created_by_url: string, description: string, key: string, key_expires_at: string, name: string, role: string, slug: string, teams: table<name: string, role: string, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/services/")
  let body = {description: $description, name: $name, role: $role, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve details of a single service within an organization.
#
# GET /orgs/{org}/services/{service}/
# operationId: orgs_services_read
export def "orgs-services read" [
  org: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, created_by_url: string, description: string, key: string, key_expires_at: string, name: string, role: string, slug: string, teams: table<name: string, role: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/services/($service)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service within an organization.
#
# PATCH /orgs/{org}/services/{service}/
# operationId: orgs_services_partial_update
# --teams item shape: {role?: "Manager"|"Member", slug: string}
export def "orgs-services patch" [
  org: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description of the service
  --name: string # The name of the service
  --role: string@role-completer-1 # The role of the service. (default: Member)
  --teams: list # item shape: {role?: "Manager"|"Member", slug: string}
]: any -> record<created_at: string, created_by: string, created_by_url: string, description: string, key: string, key_expires_at: string, name: string, role: string, slug: string, teams: table<name: string, role: string, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/services/($service)/")
  let body = {description: $description, name: $name, role: $role, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific service
#
# DELETE /orgs/{org}/services/{service}/
# operationId: orgs_services_delete
export def "orgs-services delete" [
  org: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/services/($service)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh service API token.
#
# POST /orgs/{org}/services/{service}/refresh/
# operationId: orgs_services_refresh
export def "orgs-services-refresh refresh" [
  org: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, created_by_url: string, description: string, key: string, key_expires_at: string, name: string, role: string, slug: string, teams: table<name: string, role: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/services/($service)/refresh/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of all teams within an organization.
#
# GET /orgs/{org}/teams/
# operationId: orgs_teams_list
export def "orgs-teams list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --for-user: string@bool-completer # Filter for teams that you are a member of. (default: false)
  --qp-query: string # A search term for querying of teams within an Organization.Available options are: name, slug, user, userslug (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. Use `-` prefix for descending order (e.g., `-name`). Available options: name, members. (default: name)
]: nothing -> table<description: string, name: string, slug: string, slug_perm: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "for_user" $for_user "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/teams/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team for this organization.
#
# POST /orgs/{org}/teams/
# operationId: orgs_teams_create
export def "orgs-teams create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A detailed description of the team.
  name: string # A descriptive name for the team.
  --slug: string # format: slug
  --visibility: string@visibility-completer-1 # default: Visible
]: any -> record<description: string, name: string, slug: string, slug_perm: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams/")
  let body = {description: $description, name: $name, slug: $slug, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the details of a specific team within an organization.
#
# GET /orgs/{org}/teams/{team}/
# operationId: orgs_teams_read
export def "orgs-teams read" [
  org: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, name: string, slug: string, slug_perm: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams/($team)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific team in a organization.
#
# PATCH /orgs/{org}/teams/{team}/
# operationId: orgs_teams_partial_update
export def "orgs-teams patch" [
  org: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A detailed description of the team.
  --name: string # A descriptive name for the team.
  --slug: string # format: slug
  --visibility: string@visibility-completer-1 # default: Visible
]: any -> record<description: string, name: string, slug: string, slug_perm: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams/($team)/")
  let body = {description: $description, name: $name, slug: $slug, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific team in a organization.
#
# DELETE /orgs/{org}/teams/{team}/
# operationId: orgs_teams_delete
export def "orgs-teams delete" [
  org: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams/($team)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all members for the team.
#
# GET /orgs/{org}/teams/{team}/members
# operationId: orgs_teams_members_list
export def "orgs-teams-members list" [
  org: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-kind: string # Filter accounts by type. Possible values are 'user' and 'service'. If not provided, only users are returned. (default: )
]: nothing -> record<members: table<role: string, user: string, user_kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_kind" $user_kind "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/teams/($team)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add users to a team.
#
# POST /orgs/{org}/teams/{team}/members
# operationId: orgs_teams_members_create
# --members item shape: {role: "Manager"|"Member", user: string, user_kind?: "User"|"Service"}
export def "orgs-teams-members create" [
  org: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # The team members — item shape: {role: "Manager"|"Member", user: string, user_kind?: "User"|"Service"}
]: any -> record<members: table<role: string, user: string, user_kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams/($team)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace all team members.
#
# PUT /orgs/{org}/teams/{team}/members
# operationId: orgs_teams_members_update
# --members item shape: {role: "Manager"|"Member", user: string, user_kind?: "User"|"Service"}
export def "orgs-teams-members update" [
  org: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # The team members — item shape: {role: "Manager"|"Member", user: string, user_kind?: "User"|"Service"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams/($team)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all current vulnerability policy violations for this Organization.
#
# GET /orgs/{org}/vulnerability-policy-violation/
# operationId: orgs_vulnerability-policy-violation_list
export def "orgs-vulnerability-policy-violation list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The pagination cursor value.
  --page-size: int # Number of results to return per page.
]: nothing -> record<next: string, previous: string, results: table<event_at: string, package: record, policy: record, reasons: list, vulnerability_scan_results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy-violation/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all package vulnerability policies.
#
# GET /orgs/{org}/vulnerability-policy/
# operationId: orgs_vulnerability-policy_list
export def "orgs-vulnerability-policy list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a package vulnerability policy.
#
# POST /orgs/{org}/vulnerability-policy/
# operationId: orgs_vulnerability-policy_create
export def "orgs-vulnerability-policy create" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-unknown-severity: string@bool-completer # Denotes whether vulnerabilities detected by a security scan with an unknown severity are permitted by this policy.
  --description: string
  --min-severity: string@min-severity-completer # default: Critical
  name: string
  --on-violation-quarantine: string@bool-completer
  --package-query-string: string
]: any -> record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/")
  let body = {allow_unknown_severity: $allow_unknown_severity, description: $description, min_severity: $min_severity, name: $name, on_violation_quarantine: $on_violation_quarantine, package_query_string: $package_query_string} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List evaluation requests for this policy.
#
# GET /orgs/{org}/vulnerability-policy/{policy_slug_perm}/evaluation/
# operationId: orgs_vulnerability-policy_evaluation_list
export def "orgs-vulnerability-policy-evaluation list" [
  org: string
  policy_slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<created_at: string, evaluation_count: int, policy: record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string, url: string>, slug_perm: string, status: string, updated_at: string, violation_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($policy_slug_perm)/evaluation/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an evaluation request for this policy.
#
# POST /orgs/{org}/vulnerability-policy/{policy_slug_perm}/evaluation/
# operationId: orgs_vulnerability-policy_evaluation_create
export def "orgs-vulnerability-policy-evaluation create" [
  org: string
  policy_slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<created_at: string, evaluation_count: int, policy: record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string, url: string>, slug_perm: string, status: string, updated_at: string, violation_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($policy_slug_perm)/evaluation/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an evaluation request for this policy.
#
# GET /orgs/{org}/vulnerability-policy/{policy_slug_perm}/evaluation/{slug_perm}/
# operationId: orgs_vulnerability-policy_evaluation_read
export def "orgs-vulnerability-policy-evaluation read" [
  org: string
  policy_slug_perm: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, evaluation_count: int, policy: record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string, url: string>, slug_perm: string, status: string, updated_at: string, violation_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($policy_slug_perm)/evaluation/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a package vulnerability policy.
#
# GET /orgs/{org}/vulnerability-policy/{slug_perm}/
# operationId: orgs_vulnerability-policy_read
export def "orgs-vulnerability-policy read" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a package vulnerability policy.
#
# PUT /orgs/{org}/vulnerability-policy/{slug_perm}/
# operationId: orgs_vulnerability-policy_update
export def "orgs-vulnerability-policy update" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-unknown-severity: string@bool-completer # Denotes whether vulnerabilities detected by a security scan with an unknown severity are permitted by this policy.
  --description: string
  --min-severity: string@min-severity-completer # default: Critical
  name: string
  --on-violation-quarantine: string@bool-completer
  --package-query-string: string
]: any -> record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($slug_perm)/")
  let body = {allow_unknown_severity: $allow_unknown_severity, description: $description, min_severity: $min_severity, name: $name, on_violation_quarantine: $on_violation_quarantine, package_query_string: $package_query_string} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a package vulnerability policy.
#
# PATCH /orgs/{org}/vulnerability-policy/{slug_perm}/
# operationId: orgs_vulnerability-policy_partial_update
export def "orgs-vulnerability-policy patch" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-unknown-severity: string@bool-completer # Denotes whether vulnerabilities detected by a security scan with an unknown severity are permitted by this policy.
  --description: string
  --min-severity: string@min-severity-completer # default: Critical
  --name: string
  --on-violation-quarantine: string@bool-completer
  --package-query-string: string
]: any -> record<allow_unknown_severity: bool, created_at: string, description: string, min_severity: string, name: string, on_violation_quarantine: bool, package_query_string: string, slug_perm: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($slug_perm)/")
  let body = {allow_unknown_severity: $allow_unknown_severity, description: $description, min_severity: $min_severity, name: $name, on_violation_quarantine: $on_violation_quarantine, package_query_string: $package_query_string} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a package vulnerability policy.
#
# DELETE /orgs/{org}/vulnerability-policy/{slug_perm}/
# operationId: orgs_vulnerability-policy_delete
export def "orgs-vulnerability-policy delete" [
  org: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/vulnerability-policy/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all packages associated with repository.
#
# GET /packages/{owner}/{repo}/
# operationId: packages_list
export def "packages list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --include-connected-repositories: string@bool-completer # If true, include packages from active connected target repositories in addition to packages from this repository. Has no effect if the repository has no active connections. Defaults to false. Note: download-related URLs on returned packages (e.g. cdn_url, signature_url) are rewritten to point at the requesting repository, not the connected target repository the package physically lives in. (default: false)
  --qp-query: string # A search term for querying names, filenames, versions, distributions, architectures, formats or statuses of packages. (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. (default: -date)
]: nothing -> table<architectures: list<record>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: list<record>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "include_connected_repositories" $include_connected_repositories "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of Package Groups in a repository.
#
# GET /packages/{owner}/{repo}/groups/
# operationId: packages_groups_list
export def "packages-groups list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --group-by: string # A field to group packages by. Available options: name, backend_kind. (default: name)
  --hide-subcomponents: string@bool-completer # Whether to hide packages which are subcomponents of another package in the results (default: false)
  --include-connected-repositories: string@bool-completer # If true, include packages from active connected target repositories in addition to packages from this repository. Has no effect if the repository has no active connections. Defaults to false. (default: false)
  --qp-query: string # A search term for querying names, filenames, versions, distributions, architectures, formats, or statuses of packages. (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. Use `-` prefix for descending order (e.g., `-name`). Available options: name, count, num_downloads, size, last_push, backend_kind. (default: name)
]: nothing -> record<results: table<backend_kind: int, count: int, last_push: string, name: string, num_downloads: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "hide_subcomponents" $hide_subcomponents "scalar") (serialize-qp "include_connected_repositories" $include_connected_repositories "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)/($repo)/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Alpine package
#
# POST /packages/{owner}/{repo}/upload/alpine/
# operationId: packages_upload_alpine
export def "packages-upload-alpine alpine" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  distribution: string # The distribution to store the package for.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/alpine/")
  let body = {distribution: $distribution, package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Cargo package
#
# POST /packages/{owner}/{repo}/upload/cargo/
# operationId: packages_upload_cargo
export def "packages-upload-cargo cargo" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/cargo/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new CocoaPods package
#
# POST /packages/{owner}/{repo}/upload/cocoapods/
# operationId: packages_upload_cocoapods
export def "packages-upload-cocoapods cocoapods" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/cocoapods/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Composer package
#
# POST /packages/{owner}/{repo}/upload/composer/
# operationId: packages_upload_composer
export def "packages-upload-composer composer" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/composer/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Conan package
#
# POST /packages/{owner}/{repo}/upload/conan/
# operationId: packages_upload_conan
export def "packages-upload-conan conan" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --conan-channel: string # Conan channel.
  --conan-prefix: string # Conan prefix (User).
  info_file: string # The info file is an python file containing the package metadata.
  manifest_file: string # The info file is an python file containing the package metadata.
  metadata_file: string # The conan file is an python file containing the package metadata.
  --name: string # The name of this package.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, conan_channel: string, conan_prefix: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/conan/")
  let body = {conan_channel: $conan_channel, conan_prefix: $conan_prefix, info_file: $info_file, manifest_file: $manifest_file, metadata_file: $metadata_file, name: $name, package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Conda package
#
# POST /packages/{owner}/{repo}/upload/conda/
# operationId: packages_upload_conda
export def "packages-upload-conda conda" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/conda/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new CRAN package
#
# POST /packages/{owner}/{repo}/upload/cran/
# operationId: packages_upload_cran
export def "packages-upload-cran cran" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --architecture: string # Binary package uploads for macOS should specify the architecture they were built for.
  package_file: string # The primary file for the package.
  --r-version: string # Binary package uploads should specify the version of R they were built for.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, r_version: string, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/cran/")
  let body = {architecture: $architecture, package_file: $package_file, r_version: $r_version, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Dart package
#
# POST /packages/{owner}/{repo}/upload/dart/
# operationId: packages_upload_dart
export def "packages-upload-dart dart" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/dart/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Debian package
#
# POST /packages/{owner}/{repo}/upload/deb/
# operationId: packages_upload_deb
export def "packages-upload-deb deb" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changes-file: string # The changes archive containing the changes made to the source and debian packaging files
  --component: string # The component (channel) for the package (e.g. 'main', 'unstable', etc.) (default: main)
  distribution: string # The distribution to store the package for.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --sources-file: string # The sources archive containing the source code for the binary
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/deb/")
  let body = {changes_file: $changes_file, component: $component, distribution: $distribution, package_file: $package_file, republish: $republish, sources_file: $sources_file, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Docker package
#
# POST /packages/{owner}/{repo}/upload/docker/
# operationId: packages_upload_docker
export def "packages-upload-docker docker" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/docker/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Generic package
#
# POST /packages/{owner}/{repo}/upload/generic/
# operationId: packages_upload_generic
export def "packages-upload-generic generic" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filepath: string # The full filepath of the package including filename.
  --name: string # The name of this package.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/generic/")
  let body = {filepath: $filepath, name: $name, package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Go package
#
# POST /packages/{owner}/{repo}/upload/go/
# operationId: packages_upload_go
export def "packages-upload-go go" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/go/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Helm package
#
# POST /packages/{owner}/{repo}/upload/helm/
# operationId: packages_upload_helm
export def "packages-upload-helm helm" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --provenance-file: string # The provenance file containing the signature for the chart. If one is not provided, it will be generated automatically.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/helm/")
  let body = {package_file: $package_file, provenance_file: $provenance_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Hex package
#
# POST /packages/{owner}/{repo}/upload/hex/
# operationId: packages_upload_hex
export def "packages-upload-hex hex" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/hex/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new HuggingFace package
#
# POST /packages/{owner}/{repo}/upload/huggingface/
# operationId: packages_upload_huggingface
export def "packages-upload-huggingface huggingface" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/huggingface/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new LuaRocks package
#
# POST /packages/{owner}/{repo}/upload/luarocks/
# operationId: packages_upload_luarocks
export def "packages-upload-luarocks luarocks" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/luarocks/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Maven package
#
# POST /packages/{owner}/{repo}/upload/maven/
# operationId: packages_upload_maven
export def "packages-upload-maven maven" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --artifact-id: string # The ID of the artifact.
  --extra-files: list # Extra files to include in the package. This can be a single file or multiple files.
  --group-id: string # Artifact's group ID.
  --ivy-file: string # The ivy file is an XML file describing the dependencies of the project.
  --javadoc-file: string # Adds bundled Java documentation to the Maven package
  package_file: string # The primary file for the package.
  --packaging: string # Artifact's Maven packaging type.
  --pom-file: string # The POM file is an XML file containing the Maven coordinates.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --sbt-version: string
  --scala-version: string
  --sources-file: string # Adds bundled Java source code to the Maven package.
  --tags: string # A comma-separated values list of tags to add to the package.
  --tests-file: string # Adds bundled Java tests to the Maven package.
  --version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, artifact_id: string, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, group_id: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, packaging: string, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, sbt_version: string, scala_version: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/maven/")
  let body = {artifact_id: $artifact_id, extra_files: $extra_files, group_id: $group_id, ivy_file: $ivy_file, javadoc_file: $javadoc_file, package_file: $package_file, packaging: $packaging, pom_file: $pom_file, republish: $republish, sbt_version: $sbt_version, scala_version: $scala_version, sources_file: $sources_file, tags: $tags, tests_file: $tests_file, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new MCP package
#
# POST /packages/{owner}/{repo}/upload/mcp/
# operationId: packages_upload_mcp
export def "packages-upload-mcp mcp" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/mcp/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new npm package
#
# POST /packages/{owner}/{repo}/upload/npm/
# operationId: packages_upload_npm
export def "packages-upload-npm npm" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --npm-dist-tag: string # The default npm dist-tag for this package/version - This will replace any other package/version if they are using the same tag. (default: latest)
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/npm/")
  let body = {npm_dist_tag: $npm_dist_tag, package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new NuGet package
#
# POST /packages/{owner}/{repo}/upload/nuget/
# operationId: packages_upload_nuget
export def "packages-upload-nuget nuget" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --symbols-file: string # Uploads a symbols file as a separate package
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/nuget/")
  let body = {package_file: $package_file, republish: $republish, symbols_file: $symbols_file, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new P2 package
#
# POST /packages/{owner}/{repo}/upload/p2/
# operationId: packages_upload_p2
export def "packages-upload-p2 p2" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/p2/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Python package
#
# POST /packages/{owner}/{repo}/upload/python/
# operationId: packages_upload_python
export def "packages-upload-python python" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/python/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Raw package
#
# POST /packages/{owner}/{repo}/upload/raw/
# operationId: packages_upload_raw
export def "packages-upload-raw raw" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content-type: string # A custom content/media (also known as MIME) type to be sent when downloading this file. By default Cloudsmith will attempt to detect the type, but if you need to override it, you can specify it here.
  --description: string # A textual description of this package.
  --name: string # The name of this package.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --summary: string # A one-liner synopsis of this package.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/raw/")
  let body = {content_type: $content_type, description: $description, name: $name, package_file: $package_file, republish: $republish, summary: $summary, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new RedHat package
#
# POST /packages/{owner}/{repo}/upload/rpm/
# operationId: packages_upload_rpm
export def "packages-upload-rpm rpm" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  distribution: string # The distribution to store the package for.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/rpm/")
  let body = {distribution: $distribution, package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Ruby package
#
# POST /packages/{owner}/{repo}/upload/ruby/
# operationId: packages_upload_ruby
export def "packages-upload-ruby ruby" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/ruby/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Swift package
#
# POST /packages/{owner}/{repo}/upload/swift/
# operationId: packages_upload_swift
export def "packages-upload-swift swift" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author-name: string # The name of the author of the package.
  --author-org: string # The organization of the author.
  --license-url: string # The license URL of this package. (format: uri)
  name: string # The name of this package.
  package_file: string # The primary file for the package.
  --readme-url: string # The URL of the readme for the package. (format: uri)
  --repository-url: string # The URL of the SCM repository for the package. (format: uri)
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  scope: string # A scope provides a namespace for related packages within the package registry.
  --tags: string # A comma-separated values list of tags to add to the package.
  version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, author_name: string, author_org: string, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, license_url: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, readme_url: string, release: string, repository: string, repository_url: string, scope: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/swift/")
  let body = {author_name: $author_name, author_org: $author_org, license_url: $license_url, name: $name, package_file: $package_file, readme_url: $readme_url, repository_url: $repository_url, republish: $republish, scope: $scope, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Terraform package
#
# POST /packages/{owner}/{repo}/upload/terraform/
# operationId: packages_upload_terraform
export def "packages-upload-terraform terraform" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/terraform/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Vagrant package
#
# POST /packages/{owner}/{repo}/upload/vagrant/
# operationId: packages_upload_vagrant
export def "packages-upload-vagrant vagrant" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of this package.
  package_file: string # The primary file for the package.
  provider: string # The virtual machine provider for the box.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  version: string # The raw version for this package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, provider: string, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/vagrant/")
  let body = {name: $name, package_file: $package_file, provider: $provider, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new VSX package
#
# POST /packages/{owner}/{repo}/upload/vsx/
# operationId: packages_upload_vsx
export def "packages-upload-vsx vsx" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/upload/vsx/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Alpine package
#
# POST /packages/{owner}/{repo}/validate-upload/alpine/
# operationId: packages_validate-upload_alpine
export def "packages-validate-upload-alpine alpine" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  distribution: string # The distribution to store the package for.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/alpine/")
  let body = {distribution: $distribution, package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Cargo package
#
# POST /packages/{owner}/{repo}/validate-upload/cargo/
# operationId: packages_validate-upload_cargo
export def "packages-validate-upload-cargo cargo" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/cargo/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create CocoaPods package
#
# POST /packages/{owner}/{repo}/validate-upload/cocoapods/
# operationId: packages_validate-upload_cocoapods
export def "packages-validate-upload-cocoapods cocoapods" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/cocoapods/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Composer package
#
# POST /packages/{owner}/{repo}/validate-upload/composer/
# operationId: packages_validate-upload_composer
export def "packages-validate-upload-composer composer" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/composer/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Conan package
#
# POST /packages/{owner}/{repo}/validate-upload/conan/
# operationId: packages_validate-upload_conan
export def "packages-validate-upload-conan conan" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --conan-channel: string # Conan channel.
  --conan-prefix: string # Conan prefix (User).
  info_file: string # The info file is an python file containing the package metadata.
  manifest_file: string # The info file is an python file containing the package metadata.
  metadata_file: string # The conan file is an python file containing the package metadata.
  --name: string # The name of this package.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/conan/")
  let body = {conan_channel: $conan_channel, conan_prefix: $conan_prefix, info_file: $info_file, manifest_file: $manifest_file, metadata_file: $metadata_file, name: $name, package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Conda package
#
# POST /packages/{owner}/{repo}/validate-upload/conda/
# operationId: packages_validate-upload_conda
export def "packages-validate-upload-conda conda" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/conda/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create CRAN package
#
# POST /packages/{owner}/{repo}/validate-upload/cran/
# operationId: packages_validate-upload_cran
export def "packages-validate-upload-cran cran" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --architecture: string # Binary package uploads for macOS should specify the architecture they were built for.
  package_file: string # The primary file for the package.
  --r-version: string # Binary package uploads should specify the version of R they were built for.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/cran/")
  let body = {architecture: $architecture, package_file: $package_file, r_version: $r_version, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Dart package
#
# POST /packages/{owner}/{repo}/validate-upload/dart/
# operationId: packages_validate-upload_dart
export def "packages-validate-upload-dart dart" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/dart/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Debian package
#
# POST /packages/{owner}/{repo}/validate-upload/deb/
# operationId: packages_validate-upload_deb
export def "packages-validate-upload-deb deb" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changes-file: string # The changes archive containing the changes made to the source and debian packaging files
  --component: string # The component (channel) for the package (e.g. 'main', 'unstable', etc.) (default: main)
  distribution: string # The distribution to store the package for.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --sources-file: string # The sources archive containing the source code for the binary
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/deb/")
  let body = {changes_file: $changes_file, component: $component, distribution: $distribution, package_file: $package_file, republish: $republish, sources_file: $sources_file, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Docker package
#
# POST /packages/{owner}/{repo}/validate-upload/docker/
# operationId: packages_validate-upload_docker
export def "packages-validate-upload-docker docker" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/docker/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Generic package
#
# POST /packages/{owner}/{repo}/validate-upload/generic/
# operationId: packages_validate-upload_generic
export def "packages-validate-upload-generic generic" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filepath: string # The full filepath of the package including filename.
  --name: string # The name of this package.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/generic/")
  let body = {filepath: $filepath, name: $name, package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Go package
#
# POST /packages/{owner}/{repo}/validate-upload/go/
# operationId: packages_validate-upload_go
export def "packages-validate-upload-go go" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/go/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Helm package
#
# POST /packages/{owner}/{repo}/validate-upload/helm/
# operationId: packages_validate-upload_helm
export def "packages-validate-upload-helm helm" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --provenance-file: string # The provenance file containing the signature for the chart. If one is not provided, it will be generated automatically.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/helm/")
  let body = {package_file: $package_file, provenance_file: $provenance_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Hex package
#
# POST /packages/{owner}/{repo}/validate-upload/hex/
# operationId: packages_validate-upload_hex
export def "packages-validate-upload-hex hex" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/hex/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create HuggingFace package
#
# POST /packages/{owner}/{repo}/validate-upload/huggingface/
# operationId: packages_validate-upload_huggingface
export def "packages-validate-upload-huggingface huggingface" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/huggingface/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create LuaRocks package
#
# POST /packages/{owner}/{repo}/validate-upload/luarocks/
# operationId: packages_validate-upload_luarocks
export def "packages-validate-upload-luarocks luarocks" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/luarocks/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Maven package
#
# POST /packages/{owner}/{repo}/validate-upload/maven/
# operationId: packages_validate-upload_maven
export def "packages-validate-upload-maven maven" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --artifact-id: string # The ID of the artifact.
  --extra-files: list # Extra files to include in the package. This can be a single file or multiple files.
  --group-id: string # Artifact's group ID.
  --ivy-file: string # The ivy file is an XML file describing the dependencies of the project.
  --javadoc-file: string # Adds bundled Java documentation to the Maven package
  package_file: string # The primary file for the package.
  --packaging: string # Artifact's Maven packaging type.
  --pom-file: string # The POM file is an XML file containing the Maven coordinates.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --sbt-version: string
  --scala-version: string
  --sources-file: string # Adds bundled Java source code to the Maven package.
  --tags: string # A comma-separated values list of tags to add to the package.
  --tests-file: string # Adds bundled Java tests to the Maven package.
  --version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/maven/")
  let body = {artifact_id: $artifact_id, extra_files: $extra_files, group_id: $group_id, ivy_file: $ivy_file, javadoc_file: $javadoc_file, package_file: $package_file, packaging: $packaging, pom_file: $pom_file, republish: $republish, sbt_version: $sbt_version, scala_version: $scala_version, sources_file: $sources_file, tags: $tags, tests_file: $tests_file, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create MCP package
#
# POST /packages/{owner}/{repo}/validate-upload/mcp/
# operationId: packages_validate-upload_mcp
export def "packages-validate-upload-mcp mcp" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/mcp/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create npm package
#
# POST /packages/{owner}/{repo}/validate-upload/npm/
# operationId: packages_validate-upload_npm
export def "packages-validate-upload-npm npm" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --npm-dist-tag: string # The default npm dist-tag for this package/version - This will replace any other package/version if they are using the same tag. (default: latest)
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/npm/")
  let body = {npm_dist_tag: $npm_dist_tag, package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create NuGet package
#
# POST /packages/{owner}/{repo}/validate-upload/nuget/
# operationId: packages_validate-upload_nuget
export def "packages-validate-upload-nuget nuget" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --symbols-file: string # Uploads a symbols file as a separate package
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/nuget/")
  let body = {package_file: $package_file, republish: $republish, symbols_file: $symbols_file, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create P2 package
#
# POST /packages/{owner}/{repo}/validate-upload/p2/
# operationId: packages_validate-upload_p2
export def "packages-validate-upload-p2 p2" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/p2/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Python package
#
# POST /packages/{owner}/{repo}/validate-upload/python/
# operationId: packages_validate-upload_python
export def "packages-validate-upload-python python" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/python/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Raw package
#
# POST /packages/{owner}/{repo}/validate-upload/raw/
# operationId: packages_validate-upload_raw
export def "packages-validate-upload-raw raw" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content-type: string # A custom content/media (also known as MIME) type to be sent when downloading this file. By default Cloudsmith will attempt to detect the type, but if you need to override it, you can specify it here.
  --description: string # A textual description of this package.
  --name: string # The name of this package.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --summary: string # A one-liner synopsis of this package.
  --tags: string # A comma-separated values list of tags to add to the package.
  --version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/raw/")
  let body = {content_type: $content_type, description: $description, name: $name, package_file: $package_file, republish: $republish, summary: $summary, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create RedHat package
#
# POST /packages/{owner}/{repo}/validate-upload/rpm/
# operationId: packages_validate-upload_rpm
export def "packages-validate-upload-rpm rpm" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  distribution: string # The distribution to store the package for.
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/rpm/")
  let body = {distribution: $distribution, package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Ruby package
#
# POST /packages/{owner}/{repo}/validate-upload/ruby/
# operationId: packages_validate-upload_ruby
export def "packages-validate-upload-ruby ruby" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/ruby/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Swift package
#
# POST /packages/{owner}/{repo}/validate-upload/swift/
# operationId: packages_validate-upload_swift
export def "packages-validate-upload-swift swift" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author-name: string # The name of the author of the package.
  --author-org: string # The organization of the author.
  --license-url: string # The license URL of this package. (format: uri)
  name: string # The name of this package.
  package_file: string # The primary file for the package.
  --readme-url: string # The URL of the readme for the package. (format: uri)
  --repository-url: string # The URL of the SCM repository for the package. (format: uri)
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  scope: string # A scope provides a namespace for related packages within the package registry.
  --tags: string # A comma-separated values list of tags to add to the package.
  version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/swift/")
  let body = {author_name: $author_name, author_org: $author_org, license_url: $license_url, name: $name, package_file: $package_file, readme_url: $readme_url, repository_url: $repository_url, republish: $republish, scope: $scope, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Terraform package
#
# POST /packages/{owner}/{repo}/validate-upload/terraform/
# operationId: packages_validate-upload_terraform
export def "packages-validate-upload-terraform terraform" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/terraform/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create Vagrant package
#
# POST /packages/{owner}/{repo}/validate-upload/vagrant/
# operationId: packages_validate-upload_vagrant
export def "packages-validate-upload-vagrant vagrant" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of this package.
  package_file: string # The primary file for the package.
  provider: string # The virtual machine provider for the box.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
  version: string # The raw version for this package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/vagrant/")
  let body = {name: $name, package_file: $package_file, provider: $provider, republish: $republish, tags: $tags, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate parameters for create VSX package
#
# POST /packages/{owner}/{repo}/validate-upload/vsx/
# operationId: packages_validate-upload_vsx
export def "packages-validate-upload-vsx vsx" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  package_file: string # The primary file for the package.
  --republish: string@bool-completer # If true, the uploaded package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
  --tags: string # A comma-separated values list of tags to add to the package.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/validate-upload/vsx/")
  let body = {package_file: $package_file, republish: $republish, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific package in a repository.
#
# GET /packages/{owner}/{repo}/{identifier}/
# operationId: packages_read
export def "packages read" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-connected-repositories: string@bool-completer # If true, include packages from active connected target repositories in addition to packages from this repository. Has no effect if the repository has no active connections. Defaults to false. Note: download-related URLs on returned packages (e.g. cdn_url, signature_url) are rewritten to point at the requesting repository, not the connected target repository the package physically lives in. (default: false)
]: nothing -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_connected_repositories" $include_connected_repositories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific package in a repository.
#
# DELETE /packages/{owner}/{repo}/{identifier}/
# operationId: packages_delete
export def "packages delete" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy a package to another repository.
#
# POST /packages/{owner}/{repo}/{identifier}/copy/
# operationId: packages_copy
export def "packages-copy copy" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination: string # The name of the destination repository without the namespace.
  --republish: string@bool-completer # If true, the package will overwrite any others with the same attributes (e.g. same version); otherwise, it will be flagged as a duplicate.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/copy/")
  let body = {destination: $destination, republish: $republish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of dependencies for a package. Transitive dependencies are included where supported.
#
# GET /packages/{owner}/{repo}/{identifier}/dependencies/
# operationId: packages_dependencies
export def "packages-dependencies dependencies" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-connected-repositories: string@bool-completer # If true, include packages from active connected target repositories in addition to packages from this repository. Has no effect if the repository has no active connections. Defaults to false. Note: download-related URLs on returned packages (e.g. cdn_url, signature_url) are rewritten to point at the requesting repository, not the connected target repository the package physically lives in. (default: false)
]: nothing -> record<dependencies: table<dep_type: string, name: string, operator: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_connected_repositories" $include_connected_repositories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/dependencies/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move a package to another repository.
#
# POST /packages/{owner}/{repo}/{identifier}/move/
# operationId: packages_move
export def "packages-move move" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination: string # The name of the destination repository without the namespace.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/move/")
  let body = {destination: $destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Quarantine or release a package.
#
# POST /packages/{owner}/{repo}/{identifier}/quarantine/
# operationId: packages_quarantine
export def "packages-quarantine quarantine" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --release: string@bool-completer # If true, the package is released from quarantine.
  --restore: string@bool-completer # If true, the package is released from quarantine. Note: This field is deprecated, please use 'release' instead.
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/quarantine/")
  let body = {release: $release, restore: $restore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule a package for resynchronisation.
#
# POST /packages/{owner}/{repo}/{identifier}/resync/
# operationId: packages_resync
export def "packages-resync resync" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/resync/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a package for scanning.
#
# POST /packages/{owner}/{repo}/{identifier}/scan/
# operationId: packages_scan
export def "packages-scan scan" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/scan/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the synchronization status for a package.
#
# GET /packages/{owner}/{repo}/{identifier}/status/
# operationId: packages_status
export def "packages-status status" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-connected-repositories: string@bool-completer # If true, include packages from active connected target repositories in addition to packages from this repository. Has no effect if the repository has no active connections. Defaults to false. Note: download-related URLs on returned packages (e.g. cdn_url, signature_url) are rewritten to point at the requesting repository, not the connected target repository the package physically lives in. (default: false)
]: nothing -> record<is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, self_url: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, sync_finished_at: string, sync_progress: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_connected_repositories" $include_connected_repositories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add/Replace/Remove tags for a package.
#
# POST /packages/{owner}/{repo}/{identifier}/tag/
# operationId: packages_tag
export def "packages-tag tag" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-1 # default: Add
  --is-immutable: string@bool-completer # If true, created tags will be immutable. An immutable flag is a tag that cannot be removed from a package. (default: false)
  --tags: list # A list of tags to apply the action to. Not required for clears. (default: [])
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/tag/")
  let body = {action: $action, is_immutable: $is_immutable, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the license for a package.
#
# PATCH /packages/{owner}/{repo}/{identifier}/update-license/
# operationId: packages_update_license
export def "packages-update-license license" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-2 # default: Update
  --license-notes: string
  --license-override: string@license-override-completer # default: None
  --license-url: string # format: uri
  --spdx-license: string
]: any -> record<architectures: table<description: string, name: string>, cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, dependencies_checksum_md5: string, dependencies_url: string, description: string, display_name: string, distro: record<name: string, self_url: string, slug: string, variants: string>, distro_version: record<name: string, slug: string>, downloads: int, epoch: int, extension: string, filename: string, filepath: string, files: table<cdn_url: string, checksum_md5: string, checksum_sha1: string, checksum_sha256: string, checksum_sha512: string, downloads: int, filename: string, is_downloadable: bool, is_primary: bool, is_synchronised: bool, signature_url: string, size: int, slug_perm: string, tag: string>, format: string, format_url: string, freeable_storage: int, fully_qualified_name: string, identifier_perm: string, identifiers: record, indexed: bool, is_cancellable: bool, is_copyable: bool, is_deleteable: bool, is_downloadable: bool, is_hidden: bool, is_moveable: bool, is_quarantinable: bool, is_quarantined: bool, is_resyncable: bool, is_security_scannable: bool, is_sync_awaiting: bool, is_sync_completed: bool, is_sync_failed: bool, is_sync_in_flight: bool, is_sync_in_progress: bool, license: string, name: string, namespace: string, namespace_url: string, num_files: int, origin_repository: string, origin_repository_url: string, osi_approved: bool, package_type: int, policy_violated: bool, raw_license: string, release: string, repository: string, repository_url: string, security_scan_completed_at: string, security_scan_started_at: string, security_scan_status: string, security_scan_status_updated_at: string, self_html_url: string, self_url: string, self_webapp_url: string, signature_url: string, size: int, slug: string, slug_perm: string, spdx_license: string, stage: int, stage_str: string, stage_updated_at: string, status: int, status_reason: string, status_str: string, status_updated_at: string, status_url: string, subtype: string, summary: string, sync_finished_at: string, sync_progress: int, tags: record, tags_automatic: record, tags_immutable: record, type_display: string, uploaded_at: string, uploader: string, uploader_url: string, version: string, version_orig: string, vulnerability_scan_results_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($repo)/($identifier)/update-license/")
  let body = {action: $action, license_notes: $license_notes, license_override: $license_override, license_url: $license_url, spdx_license: $spdx_license} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Quota history for a given namespace.
#
# GET /quota/history/{owner}/
# operationId: quota_history_read
export def "quota-history read" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<history: table<days: int, display: record, end: string, plan: string, raw: record, start: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quota/history/($owner)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Open-source Quota history for a given namespace.
#
# GET /quota/oss/history/{owner}/
# operationId: quota_oss_history_read
export def "quota-oss-history read" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<history: table<days: int, display: record, end: string, plan: string, raw: record, start: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quota/oss/history/($owner)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Open-source Quota usage for a given namespace.
#
# GET /quota/oss/{owner}/
# operationId: quota_oss_read
export def "quota-oss read" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: record<display: record<bandwidth: record, storage: record>, raw: record<bandwidth: record, storage: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quota/oss/($owner)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quota usage for a given namespace.
#
# GET /quota/{owner}/
# operationId: quota_read
export def "quota read" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: record<display: record<bandwidth: record, storage: record>, raw: record<bandwidth: record, storage: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quota/($owner)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Endpoint to check rate limits for current user.
#
# GET /rates/limits/
# operationId: rates_limits_list
export def "rates-limits list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resources: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rates/limits/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List soft-deleted packages in recycle bin
#
# GET /recycle-bin/{owner}/
# operationId: recycle-bin_list
export def "recycle-bin list" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --repository: string # Filter packages by repository slug
]: nothing -> table<action_by: string, downloads: int, filename: string, format: string, fully_qualified_name: string, identifiers: record, invoked_retention_rule: record, is_deleteable: bool, is_quarantined: bool, is_restorable: bool, name: string, policy_violated: bool, repository: string, security_scan_completed_at: string, security_scan_status: string, size: int, slug_perm: string, status: int, status_updated_at: string, tags: record, type_display: string, uploaded_at: string, uploader: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/recycle-bin/($owner)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform actions on soft-deleted packages in the recycle bin. Supported actions: permanently delete (hard delete), restore. Returns a list of successfully actioned packages and any packages that failed with error details. 
#
# POST /recycle-bin/{owner}/action/
# operationId: recycle-bin_action
export def "recycle-bin-action action" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string@action-completer-3 # The action to perform on soft-deleted packages.
  identifiers: list # A list of soft-deleted package identifiers to action.
  --repository: string # The repository name to filter packages to. If not provided, the action will be performed across all accessible repositories in the workspace.
]: any -> record<action: string, packages_actioned: list<string>, packages_failed_to_action: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recycle-bin/($owner)/action/")
  let body = {action: $action, identifiers: $identifiers, repository: $repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of all repositories associated with current user.
#
# GET /repos/
# operationId: repos_user_list
export def "repos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<active_connection_count: int, broadcast_state: string, cdn_url: string, content_kind: string, contextual_auth_realm: bool, copy_own: bool, copy_packages: string, cosign_signing_enabled: bool, created_at: string, default_privilege: string, delete_own: bool, delete_packages: string, deleted_at: string, description: string, distributes: list<string>, docker_refresh_tokens_enabled: bool, ecdsa_keys: list<record>, enforce_eula: bool, generic_package_index_enabled: bool, gpg_keys: list<record>, index_files: bool, is_open_source: bool, is_private: bool, is_public: bool, is_public_hidden: bool, manage_entitlements_privilege: string, move_own: bool, move_packages: string, name: string, namespace: string, namespace_url: string, npm_upstream_tags_take_precedence: bool, nuget_native_signing_enabled: bool, num_downloads: int, num_policy_violated_packages: int, num_quarantined_packages: int, open_source_license: string, open_source_project_url: string, package_count: int, package_count_excl_subcomponents: int, package_group_count: int, proxy_npmjs: bool, proxy_pypi: bool, raw_package_index_enabled: bool, raw_package_index_signatures_enabled: bool, replace_packages: string, replace_packages_by_default: bool, repository_type: int, repository_type_str: string, resync_own: bool, resync_packages: string, scan_own: bool, scan_packages: string, self_html_url: string, self_url: string, self_webapp_url: string, show_setup_all: bool, size: int, size_str: string, slug: string, slug_perm: string, storage_region: string, strict_npm_validation: bool, tag_pre_releases_as_latest: bool, use_debian_labels: bool, use_default_cargo_upstream: bool, use_entitlements_privilege: string, use_noarch_packages: bool, use_source_packages: bool, use_vulnerability_scanning: bool, user_entitlements_enabled: bool, view_statistics: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repos/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all repositories within a namespace.
#
# GET /repos/{owner}/
# operationId: repos_namespace_list
export def "repos list-1" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --qp-query: string # A search term for querying repositories. Available options are: name, slug. Explicit filters: broadcast_state, repository_type. (default: )
  --qp-sort: string # A field for sorting objects in ascending or descending order. (default: -created_at)
]: nothing -> table<active_connection_count: int, broadcast_state: string, cdn_url: string, content_kind: string, contextual_auth_realm: bool, copy_own: bool, copy_packages: string, cosign_signing_enabled: bool, created_at: string, default_privilege: string, delete_own: bool, delete_packages: string, deleted_at: string, description: string, distributes: list<string>, docker_refresh_tokens_enabled: bool, ecdsa_keys: list<record>, enforce_eula: bool, generic_package_index_enabled: bool, gpg_keys: list<record>, index_files: bool, is_open_source: bool, is_private: bool, is_public: bool, is_public_hidden: bool, manage_entitlements_privilege: string, move_own: bool, move_packages: string, name: string, namespace: string, namespace_url: string, npm_upstream_tags_take_precedence: bool, nuget_native_signing_enabled: bool, num_downloads: int, num_policy_violated_packages: int, num_quarantined_packages: int, open_source_license: string, open_source_project_url: string, package_count: int, package_count_excl_subcomponents: int, package_group_count: int, proxy_npmjs: bool, proxy_pypi: bool, raw_package_index_enabled: bool, raw_package_index_signatures_enabled: bool, replace_packages: string, replace_packages_by_default: bool, repository_type: int, repository_type_str: string, resync_own: bool, resync_packages: string, scan_own: bool, scan_packages: string, self_html_url: string, self_url: string, self_webapp_url: string, show_setup_all: bool, size: int, size_str: string, slug: string, slug_perm: string, storage_region: string, strict_npm_validation: bool, tag_pre_releases_as_latest: bool, use_debian_labels: bool, use_default_cargo_upstream: bool, use_entitlements_privilege: string, use_noarch_packages: bool, use_source_packages: bool, use_vulnerability_scanning: bool, user_entitlements_enabled: bool, view_statistics: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new repository in a given namespace.
#
# POST /repos/{owner}/
# operationId: repos_create
export def "repos create" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --broadcast-state: string@broadcast-state-completer # Broadcasting status of a repository. (default: Off)
  --content-kind: string@content-kind-completer # The repository content kind determines whether this repository contains packages, or provides a distribution of packages from other repositories. You can only select the content kind at repository creation time. (default: Standard)
  --contextual-auth-realm: string@bool-completer # If checked, missing credentials for this repository where basic authentication is required shall present an enriched value in the 'WWW-Authenticate' header containing the namespace and repository. This can be useful for tooling such as SBT where the authentication realm is used to distinguish and disambiguate credentials.
  --copy-own: string@bool-completer # If checked, users can copy any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --copy-packages: string@copy-packages-completer # This defines the minimum level of privilege required for a user to copy packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific copy setting. (default: Read)
  --cosign-signing-enabled: string@bool-completer # When enabled, all pushed (or pulled from upstream) OCI packages and artifacts will be signed using cosign with the repository's ECDSA key. This generates a distinct cosign signature artifact per artifact.
  --default-privilege: string@default-privilege-completer # This defines the default level of privilege that all of your organization members have for this repository. This does not include collaborators, but applies to any member of the org regardless of their own membership role (i.e. it applies to owners, managers and members). Be careful if setting this to admin, because any member will be able to change settings. (default: None)
  --delete-own: string@bool-completer # If checked, users can delete any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --delete-packages: string@delete-packages-completer # This defines the minimum level of privilege required for a user to delete packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific delete setting. (default: Admin)
  --description: string # A description of the repository's purpose/contents.
  --distributes: list # The repositories distributed through this repo. Adding repos here is only valid if the content_kind is DISTRIBUTION.
  --docker-refresh-tokens-enabled: string@bool-completer # If checked, refresh tokens will be issued in addition to access tokens for Docker authentication. This allows unlimited extension of the lifetime of access tokens.
  --enforce-eula: string@bool-completer # If checked, downloads will explicitly require acceptance of an EULA.
  --generic-package-index-enabled: string@bool-completer # If checked, HTML indexes will be generated that list all available generic packages in the repository.
  --index-files: string@bool-completer # If checked, files contained in packages will be indexed, which increase the synchronisation time required for packages. Note that it is recommended you keep this enabled unless the synchronisation time is significantly impacted.
  --is-public-hidden: string@bool-completer # If checked, this repository will be hidden from the list of public broadcasts for the workspace.
  --manage-entitlements-privilege: string@manage-entitlements-privilege-completer # This defines the minimum level of privilege required for a user to manage entitlement tokens with private repositories. Management is the ability to create, alter, enable, disable or delete all tokens without a repository. (default: Admin)
  --move-own: string@bool-completer # If checked, users can move any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --move-packages: string@move-packages-completer # This defines the minimum level of privilege required for a user to move packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific move setting. (default: Admin)
  name: string # A descriptive name for the repository.
  --npm-upstream-tags-take-precedence: string@bool-completer # If checked, npm distribution tags from configured upstreams will take precedence over matching local tags. When both upstream and local repositories have the same tag name (e.g., 'latest'), the upstream tag will be used instead of the local one, even if the local repository has a semantically higher version.
  --nuget-native-signing-enabled: string@bool-completer # When enabled, all pushed (or pulled from upstream) nuget packages and artifacts will be signed using the repository's X.509 RSA certificate. Additionally, the nuget RepositorySignature index will list all of the repository's signing certificates including the ones from configured upstreams.
  --open-source-license: string # The SPDX identifier of the open source license.
  --open-source-project-url: string # The URL to the Open-Source project, used for validating that the project meets the requirements for Open-Source. (format: uri)
  --proxy-npmjs: string@bool-completer # If checked, Npm packages that are not in the repository when requested by clients will automatically be proxied from the public npmjs.org registry. If there is at least one version for a package, others will not be proxied.
  --proxy-pypi: string@bool-completer # If checked, Python packages that are not in the repository when requested by clients will automatically be proxied from the public pypi.python.org registry. If there is at least one version for a package, others will not be proxied.
  --raw-package-index-enabled: string@bool-completer # If checked, HTML and JSON indexes will be generated that list all available raw packages in the repository.
  --raw-package-index-signatures-enabled: string@bool-completer # If checked, the HTML and JSON indexes will display raw package GPG signatures alongside the index packages.
  --replace-packages: string@replace-packages-completer # This defines the minimum level of privilege required for a user to republish packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific republish setting. Please note that the user still requires the privilege to delete packages that will be replaced by the new package; otherwise the republish will fail. (default: Write)
  --replace-packages-by-default: string@bool-completer # If checked, uploaded packages will overwrite/replace any others with the same attributes (e.g. same version) by default. This only applies if the user has the required privilege for the republishing AND has the required privilege to delete existing packages that they don't own.
  --repository-type-str: string@repository-type-str-completer # The repository type changes how it is accessed and billed. Private repositories are visible only to you or authorized delegates. Public repositories are visible to all Cloudsmith users. (default: Public)
  --resync-own: string@bool-completer # If checked, users can resync any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --resync-packages: string@resync-packages-completer # This defines the minimum level of privilege required for a user to resync packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific resync setting. (default: Admin)
  --scan-own: string@bool-completer # If checked, users can scan any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --scan-packages: string@scan-packages-completer # This defines the minimum level of privilege required for a user to scan packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific scan setting. (default: Read)
  --show-setup-all: string@bool-completer # If checked, the Set Me Up help for all formats will always be shown, even if you don't have packages of that type uploaded. Otherwise, help will only be shown for packages that are in the repository. For example, if you have uploaded only NuGet packages, then the Set Me Up help for NuGet packages will be shown only.
  --slug: string # The slug identifies the repository in URIs.
  --storage-region: string # The Cloudsmith region in which package files are stored. (default: default)
  --strict-npm-validation: string@bool-completer # If checked, npm packages will be validated strictly to ensure the package matches specifcation. You can turn this on if you want to guarantee that the packages will work with npm-cli and other tools correctly.
  --tag-pre-releases-as-latest: string@bool-completer # If checked, packages pushed with a pre-release component on that version will be marked with the 'latest' tag. Note that if unchecked, a repository containing ONLY pre-release versions, will have no version marked latest which may cause incompatibility with native tools 
  --use-debian-labels: string@bool-completer # If checked, a 'Label' field will be present in Debian-based repositories. It will contain a string that identifies the entitlement token used to authenticate the repository, in the form of 'source=t-<identifier>'; or 'source=none' if no token was used. You can use this to help with pinning.
  --use-default-cargo-upstream: string@bool-completer # If checked, dependencies of uploaded Cargo crates which do not set an explicit value for "registry" will be assumed to be available from crates.io. If unchecked, dependencies with unspecified "registry" values will be assumed to be available in the registry being uploaded to. Uncheck this if you want to ensure that dependencies are only ever installed from Cloudsmith unless explicitly specified as belong to another registry.
  --use-entitlements-privilege: string@use-entitlements-privilege-completer # This defines the minimum level of privilege required for a user to see/use entitlement tokens with private repositories. If a user does not have the permission, they will only be able to download packages using other credentials, such as email/password via basic authentication. Use this if you want to force users to only use their user-based token, which is tied to their access (if removed, they can't use it). (default: Read)
  --use-noarch-packages: string@bool-completer # If checked, noarch packages (if supported) are enabled in installations/configurations. A noarch package is one that is not tied to specific system architecture (like i686).
  --use-source-packages: string@bool-completer # If checked, source packages (if supported) are enabled in installations/configurations. A source package is one that contains source code rather than built binaries.
  --use-vulnerability-scanning: string@bool-completer # If checked, vulnerability scanning will be enabled for all supported packages within this repository.
  --user-entitlements-enabled: string@bool-completer # If checked, users can use and manage their own user-specific entitlement token for the repository (if private). Otherwise, user-specific entitlements are disabled for all users.
  --view-statistics: string@view-statistics-completer # This defines the minimum level of privilege required for a user to view repository statistics, to include entitlement-based usage, if applicable. If a user does not have the permission, they won't be able to view any statistics, either via the UI, API or CLI. (default: Read)
]: any -> record<active_connection_count: int, broadcast_state: string, cdn_url: string, content_kind: string, contextual_auth_realm: bool, copy_own: bool, copy_packages: string, cosign_signing_enabled: bool, created_at: string, default_privilege: string, delete_own: bool, delete_packages: string, deleted_at: string, description: string, distributes: list<string>, docker_refresh_tokens_enabled: bool, ecdsa_keys: table<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string>, enforce_eula: bool, generic_package_index_enabled: bool, gpg_keys: table<active: bool, comment: string, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string>, index_files: bool, is_open_source: bool, is_private: bool, is_public: bool, is_public_hidden: bool, manage_entitlements_privilege: string, move_own: bool, move_packages: string, name: string, namespace: string, namespace_url: string, npm_upstream_tags_take_precedence: bool, nuget_native_signing_enabled: bool, num_downloads: int, num_policy_violated_packages: int, num_quarantined_packages: int, open_source_license: string, open_source_project_url: string, package_count: int, package_count_excl_subcomponents: int, package_group_count: int, proxy_npmjs: bool, proxy_pypi: bool, raw_package_index_enabled: bool, raw_package_index_signatures_enabled: bool, replace_packages: string, replace_packages_by_default: bool, repository_type: int, repository_type_str: string, resync_own: bool, resync_packages: string, scan_own: bool, scan_packages: string, self_html_url: string, self_url: string, self_webapp_url: string, show_setup_all: bool, size: int, size_str: string, slug: string, slug_perm: string, storage_region: string, strict_npm_validation: bool, tag_pre_releases_as_latest: bool, use_debian_labels: bool, use_default_cargo_upstream: bool, use_entitlements_privilege: string, use_noarch_packages: bool, use_source_packages: bool, use_vulnerability_scanning: bool, user_entitlements_enabled: bool, view_statistics: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/")
  let body = {broadcast_state: $broadcast_state, content_kind: $content_kind, contextual_auth_realm: $contextual_auth_realm, copy_own: $copy_own, copy_packages: $copy_packages, cosign_signing_enabled: $cosign_signing_enabled, default_privilege: $default_privilege, delete_own: $delete_own, delete_packages: $delete_packages, description: $description, distributes: $distributes, docker_refresh_tokens_enabled: $docker_refresh_tokens_enabled, enforce_eula: $enforce_eula, generic_package_index_enabled: $generic_package_index_enabled, index_files: $index_files, is_public_hidden: $is_public_hidden, manage_entitlements_privilege: $manage_entitlements_privilege, move_own: $move_own, move_packages: $move_packages, name: $name, npm_upstream_tags_take_precedence: $npm_upstream_tags_take_precedence, nuget_native_signing_enabled: $nuget_native_signing_enabled, open_source_license: $open_source_license, open_source_project_url: $open_source_project_url, proxy_npmjs: $proxy_npmjs, proxy_pypi: $proxy_pypi, raw_package_index_enabled: $raw_package_index_enabled, raw_package_index_signatures_enabled: $raw_package_index_signatures_enabled, replace_packages: $replace_packages, replace_packages_by_default: $replace_packages_by_default, repository_type_str: $repository_type_str, resync_own: $resync_own, resync_packages: $resync_packages, scan_own: $scan_own, scan_packages: $scan_packages, show_setup_all: $show_setup_all, slug: $slug, storage_region: $storage_region, strict_npm_validation: $strict_npm_validation, tag_pre_releases_as_latest: $tag_pre_releases_as_latest, use_debian_labels: $use_debian_labels, use_default_cargo_upstream: $use_default_cargo_upstream, use_entitlements_privilege: $use_entitlements_privilege, use_noarch_packages: $use_noarch_packages, use_source_packages: $use_source_packages, use_vulnerability_scanning: $use_vulnerability_scanning, user_entitlements_enabled: $user_entitlements_enabled, view_statistics: $view_statistics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific repository.
#
# GET /repos/{owner}/{identifier}/
# operationId: repos_read
export def "repos read" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_connection_count: int, broadcast_state: string, cdn_url: string, content_kind: string, contextual_auth_realm: bool, copy_own: bool, copy_packages: string, cosign_signing_enabled: bool, created_at: string, default_privilege: string, delete_own: bool, delete_packages: string, deleted_at: string, description: string, distributes: list<string>, docker_refresh_tokens_enabled: bool, ecdsa_keys: table<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string>, enforce_eula: bool, generic_package_index_enabled: bool, gpg_keys: table<active: bool, comment: string, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string>, index_files: bool, is_open_source: bool, is_private: bool, is_public: bool, is_public_hidden: bool, manage_entitlements_privilege: string, move_own: bool, move_packages: string, name: string, namespace: string, namespace_url: string, npm_upstream_tags_take_precedence: bool, nuget_native_signing_enabled: bool, num_downloads: int, num_policy_violated_packages: int, num_quarantined_packages: int, open_source_license: string, open_source_project_url: string, package_count: int, package_count_excl_subcomponents: int, package_group_count: int, proxy_npmjs: bool, proxy_pypi: bool, raw_package_index_enabled: bool, raw_package_index_signatures_enabled: bool, replace_packages: string, replace_packages_by_default: bool, repository_type: int, repository_type_str: string, resync_own: bool, resync_packages: string, scan_own: bool, scan_packages: string, self_html_url: string, self_url: string, self_webapp_url: string, show_setup_all: bool, size: int, size_str: string, slug: string, slug_perm: string, storage_region: string, strict_npm_validation: bool, tag_pre_releases_as_latest: bool, use_debian_labels: bool, use_default_cargo_upstream: bool, use_entitlements_privilege: string, use_noarch_packages: bool, use_source_packages: bool, use_vulnerability_scanning: bool, user_entitlements_enabled: bool, view_statistics: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update details about a repository in a given namespace.
#
# PATCH /repos/{owner}/{identifier}/
# operationId: repos_partial_update
export def "repos patch" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --broadcast-state: string@broadcast-state-completer # Broadcasting status of a repository. (default: Off)
  --content-kind: string@content-kind-completer # The repository content kind determines whether this repository contains packages, or provides a distribution of packages from other repositories. You can only select the content kind at repository creation time. (default: Standard)
  --contextual-auth-realm: string@bool-completer # If checked, missing credentials for this repository where basic authentication is required shall present an enriched value in the 'WWW-Authenticate' header containing the namespace and repository. This can be useful for tooling such as SBT where the authentication realm is used to distinguish and disambiguate credentials.
  --copy-own: string@bool-completer # If checked, users can copy any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --copy-packages: string@copy-packages-completer # This defines the minimum level of privilege required for a user to copy packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific copy setting. (default: Read)
  --cosign-signing-enabled: string@bool-completer # When enabled, all pushed (or pulled from upstream) OCI packages and artifacts will be signed using cosign with the repository's ECDSA key. This generates a distinct cosign signature artifact per artifact.
  --default-privilege: string@default-privilege-completer # This defines the default level of privilege that all of your organization members have for this repository. This does not include collaborators, but applies to any member of the org regardless of their own membership role (i.e. it applies to owners, managers and members). Be careful if setting this to admin, because any member will be able to change settings. (default: None)
  --delete-own: string@bool-completer # If checked, users can delete any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --delete-packages: string@delete-packages-completer # This defines the minimum level of privilege required for a user to delete packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific delete setting. (default: Admin)
  --description: string # A description of the repository's purpose/contents.
  --distributes: list # The repositories distributed through this repo. Adding repos here is only valid if the content_kind is DISTRIBUTION.
  --docker-refresh-tokens-enabled: string@bool-completer # If checked, refresh tokens will be issued in addition to access tokens for Docker authentication. This allows unlimited extension of the lifetime of access tokens.
  --enforce-eula: string@bool-completer # If checked, downloads will explicitly require acceptance of an EULA.
  --generic-package-index-enabled: string@bool-completer # If checked, HTML indexes will be generated that list all available generic packages in the repository.
  --index-files: string@bool-completer # If checked, files contained in packages will be indexed, which increase the synchronisation time required for packages. Note that it is recommended you keep this enabled unless the synchronisation time is significantly impacted.
  --is-public-hidden: string@bool-completer # If checked, this repository will be hidden from the list of public broadcasts for the workspace.
  --manage-entitlements-privilege: string@manage-entitlements-privilege-completer # This defines the minimum level of privilege required for a user to manage entitlement tokens with private repositories. Management is the ability to create, alter, enable, disable or delete all tokens without a repository. (default: Admin)
  --move-own: string@bool-completer # If checked, users can move any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --move-packages: string@move-packages-completer # This defines the minimum level of privilege required for a user to move packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific move setting. (default: Admin)
  --name: string # A descriptive name for the repository.
  --npm-upstream-tags-take-precedence: string@bool-completer # If checked, npm distribution tags from configured upstreams will take precedence over matching local tags. When both upstream and local repositories have the same tag name (e.g., 'latest'), the upstream tag will be used instead of the local one, even if the local repository has a semantically higher version.
  --nuget-native-signing-enabled: string@bool-completer # When enabled, all pushed (or pulled from upstream) nuget packages and artifacts will be signed using the repository's X.509 RSA certificate. Additionally, the nuget RepositorySignature index will list all of the repository's signing certificates including the ones from configured upstreams.
  --open-source-license: string # The SPDX identifier of the open source license.
  --open-source-project-url: string # The URL to the Open-Source project, used for validating that the project meets the requirements for Open-Source. (format: uri)
  --proxy-npmjs: string@bool-completer # If checked, Npm packages that are not in the repository when requested by clients will automatically be proxied from the public npmjs.org registry. If there is at least one version for a package, others will not be proxied.
  --proxy-pypi: string@bool-completer # If checked, Python packages that are not in the repository when requested by clients will automatically be proxied from the public pypi.python.org registry. If there is at least one version for a package, others will not be proxied.
  --raw-package-index-enabled: string@bool-completer # If checked, HTML and JSON indexes will be generated that list all available raw packages in the repository.
  --raw-package-index-signatures-enabled: string@bool-completer # If checked, the HTML and JSON indexes will display raw package GPG signatures alongside the index packages.
  --replace-packages: string@replace-packages-completer # This defines the minimum level of privilege required for a user to republish packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific republish setting. Please note that the user still requires the privilege to delete packages that will be replaced by the new package; otherwise the republish will fail. (default: Write)
  --replace-packages-by-default: string@bool-completer # If checked, uploaded packages will overwrite/replace any others with the same attributes (e.g. same version) by default. This only applies if the user has the required privilege for the republishing AND has the required privilege to delete existing packages that they don't own.
  --repository-type-str: string@repository-type-str-completer # The repository type changes how it is accessed and billed. Private repositories are visible only to you or authorized delegates. Public repositories are visible to all Cloudsmith users. (default: Public)
  --resync-own: string@bool-completer # If checked, users can resync any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --resync-packages: string@resync-packages-completer # This defines the minimum level of privilege required for a user to resync packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific resync setting. (default: Admin)
  --scan-own: string@bool-completer # If checked, users can scan any of their own packages that they have uploaded, assuming that they still have write privilege for the repository. This takes precedence over privileges configured in the 'Access Controls' section of the repository, and any inherited from the org.
  --scan-packages: string@scan-packages-completer # This defines the minimum level of privilege required for a user to scan packages. Unless the package was uploaded by that user, in which the permission may be overridden by the user-specific scan setting. (default: Read)
  --show-setup-all: string@bool-completer # If checked, the Set Me Up help for all formats will always be shown, even if you don't have packages of that type uploaded. Otherwise, help will only be shown for packages that are in the repository. For example, if you have uploaded only NuGet packages, then the Set Me Up help for NuGet packages will be shown only.
  --slug: string # The slug identifies the repository in URIs.
  --strict-npm-validation: string@bool-completer # If checked, npm packages will be validated strictly to ensure the package matches specifcation. You can turn this on if you want to guarantee that the packages will work with npm-cli and other tools correctly.
  --tag-pre-releases-as-latest: string@bool-completer # If checked, packages pushed with a pre-release component on that version will be marked with the 'latest' tag. Note that if unchecked, a repository containing ONLY pre-release versions, will have no version marked latest which may cause incompatibility with native tools 
  --use-debian-labels: string@bool-completer # If checked, a 'Label' field will be present in Debian-based repositories. It will contain a string that identifies the entitlement token used to authenticate the repository, in the form of 'source=t-<identifier>'; or 'source=none' if no token was used. You can use this to help with pinning.
  --use-default-cargo-upstream: string@bool-completer # If checked, dependencies of uploaded Cargo crates which do not set an explicit value for "registry" will be assumed to be available from crates.io. If unchecked, dependencies with unspecified "registry" values will be assumed to be available in the registry being uploaded to. Uncheck this if you want to ensure that dependencies are only ever installed from Cloudsmith unless explicitly specified as belong to another registry.
  --use-entitlements-privilege: string@use-entitlements-privilege-completer # This defines the minimum level of privilege required for a user to see/use entitlement tokens with private repositories. If a user does not have the permission, they will only be able to download packages using other credentials, such as email/password via basic authentication. Use this if you want to force users to only use their user-based token, which is tied to their access (if removed, they can't use it). (default: Read)
  --use-noarch-packages: string@bool-completer # If checked, noarch packages (if supported) are enabled in installations/configurations. A noarch package is one that is not tied to specific system architecture (like i686).
  --use-source-packages: string@bool-completer # If checked, source packages (if supported) are enabled in installations/configurations. A source package is one that contains source code rather than built binaries.
  --use-vulnerability-scanning: string@bool-completer # If checked, vulnerability scanning will be enabled for all supported packages within this repository.
  --user-entitlements-enabled: string@bool-completer # If checked, users can use and manage their own user-specific entitlement token for the repository (if private). Otherwise, user-specific entitlements are disabled for all users.
  --view-statistics: string@view-statistics-completer # This defines the minimum level of privilege required for a user to view repository statistics, to include entitlement-based usage, if applicable. If a user does not have the permission, they won't be able to view any statistics, either via the UI, API or CLI. (default: Read)
]: any -> record<active_connection_count: int, broadcast_state: string, cdn_url: string, content_kind: string, contextual_auth_realm: bool, copy_own: bool, copy_packages: string, cosign_signing_enabled: bool, created_at: string, default_privilege: string, delete_own: bool, delete_packages: string, deleted_at: string, description: string, distributes: list<string>, docker_refresh_tokens_enabled: bool, ecdsa_keys: table<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string>, enforce_eula: bool, generic_package_index_enabled: bool, gpg_keys: table<active: bool, comment: string, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string>, index_files: bool, is_open_source: bool, is_private: bool, is_public: bool, is_public_hidden: bool, manage_entitlements_privilege: string, move_own: bool, move_packages: string, name: string, namespace: string, namespace_url: string, npm_upstream_tags_take_precedence: bool, nuget_native_signing_enabled: bool, num_downloads: int, num_policy_violated_packages: int, num_quarantined_packages: int, open_source_license: string, open_source_project_url: string, package_count: int, package_count_excl_subcomponents: int, package_group_count: int, proxy_npmjs: bool, proxy_pypi: bool, raw_package_index_enabled: bool, raw_package_index_signatures_enabled: bool, replace_packages: string, replace_packages_by_default: bool, repository_type: int, repository_type_str: string, resync_own: bool, resync_packages: string, scan_own: bool, scan_packages: string, self_html_url: string, self_url: string, self_webapp_url: string, show_setup_all: bool, size: int, size_str: string, slug: string, slug_perm: string, storage_region: string, strict_npm_validation: bool, tag_pre_releases_as_latest: bool, use_debian_labels: bool, use_default_cargo_upstream: bool, use_entitlements_privilege: string, use_noarch_packages: bool, use_source_packages: bool, use_vulnerability_scanning: bool, user_entitlements_enabled: bool, view_statistics: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/")
  let body = {broadcast_state: $broadcast_state, content_kind: $content_kind, contextual_auth_realm: $contextual_auth_realm, copy_own: $copy_own, copy_packages: $copy_packages, cosign_signing_enabled: $cosign_signing_enabled, default_privilege: $default_privilege, delete_own: $delete_own, delete_packages: $delete_packages, description: $description, distributes: $distributes, docker_refresh_tokens_enabled: $docker_refresh_tokens_enabled, enforce_eula: $enforce_eula, generic_package_index_enabled: $generic_package_index_enabled, index_files: $index_files, is_public_hidden: $is_public_hidden, manage_entitlements_privilege: $manage_entitlements_privilege, move_own: $move_own, move_packages: $move_packages, name: $name, npm_upstream_tags_take_precedence: $npm_upstream_tags_take_precedence, nuget_native_signing_enabled: $nuget_native_signing_enabled, open_source_license: $open_source_license, open_source_project_url: $open_source_project_url, proxy_npmjs: $proxy_npmjs, proxy_pypi: $proxy_pypi, raw_package_index_enabled: $raw_package_index_enabled, raw_package_index_signatures_enabled: $raw_package_index_signatures_enabled, replace_packages: $replace_packages, replace_packages_by_default: $replace_packages_by_default, repository_type_str: $repository_type_str, resync_own: $resync_own, resync_packages: $resync_packages, scan_own: $scan_own, scan_packages: $scan_packages, show_setup_all: $show_setup_all, slug: $slug, strict_npm_validation: $strict_npm_validation, tag_pre_releases_as_latest: $tag_pre_releases_as_latest, use_debian_labels: $use_debian_labels, use_default_cargo_upstream: $use_default_cargo_upstream, use_entitlements_privilege: $use_entitlements_privilege, use_noarch_packages: $use_noarch_packages, use_source_packages: $use_source_packages, use_vulnerability_scanning: $use_vulnerability_scanning, user_entitlements_enabled: $user_entitlements_enabled, view_statistics: $view_statistics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a repository in a given namespace.  Note: Repositories are soft-deleted and can be restored within a retention period. During this time, the repository's slug remains reserved and cannot be reused for new repositories.
#
# DELETE /repos/{owner}/{identifier}/
# operationId: repos_delete
export def "repos delete" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List connected repositories for this repository.
#
# GET /repos/{owner}/{identifier}/connected/
# operationId: repos_connected_list
export def "repos-connected list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<results: table<created_at: string, is_active: bool, priority: int, slug_perm: string, target_repository: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/connected/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a connected repository for this repository.
#
# POST /repos/{owner}/{identifier}/connected/
# operationId: repos_connected_create
export def "repos-connected create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-active: string@bool-completer # default: true
  --priority: int # Repositories are checked in ascending order (starting at 1). If multiple repositories have the same priority, the oldest one is used first.
  target_repository: string # The slug of the target repository to connect to. (format: slug)
]: any -> record<created_at: string, is_active: bool, priority: int, slug_perm: string, target_repository: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/connected/")
  let body = {is_active: $is_active, priority: $priority, target_repository: $target_repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a connected repository for this repository.
#
# GET /repos/{owner}/{identifier}/connected/{slug_perm}/
# operationId: repos_connected_read
export def "repos-connected read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, is_active: bool, priority: int, slug_perm: string, target_repository: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/connected/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a connected repository for this repository.
#
# PUT /repos/{owner}/{identifier}/connected/{slug_perm}/
# operationId: repos_connected_update
export def "repos-connected update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-active: string@bool-completer # default: true
  --priority: int # Repositories are checked in ascending order (starting at 1). If multiple repositories have the same priority, the oldest one is used first.
  target_repository: string # The slug of the target repository to connect to. (format: slug)
]: any -> record<created_at: string, is_active: bool, priority: int, slug_perm: string, target_repository: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/connected/($slug_perm)/")
  let body = {is_active: $is_active, priority: $priority, target_repository: $target_repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a connected repository for this repository.
#
# PATCH /repos/{owner}/{identifier}/connected/{slug_perm}/
# operationId: repos_connected_partial_update
export def "repos-connected patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-active: string@bool-completer # default: true
  --priority: int # Repositories are checked in ascending order (starting at 1). If multiple repositories have the same priority, the oldest one is used first.
  --target-repository: string # The slug of the target repository to connect to. (format: slug)
]: any -> record<created_at: string, is_active: bool, priority: int, slug_perm: string, target_repository: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/connected/($slug_perm)/")
  let body = {is_active: $is_active, priority: $priority, target_repository: $target_repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a connected repository for this repository.
#
# DELETE /repos/{owner}/{identifier}/connected/{slug_perm}/
# operationId: repos_connected_delete
export def "repos-connected delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/connected/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the active ECDSA key for the Repository.
#
# GET /repos/{owner}/{identifier}/ecdsa/
# operationId: repos_ecdsa_list
export def "repos-ecdsa list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/ecdsa/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the active ECDSA key for the Repository.
#
# POST /repos/{owner}/{identifier}/ecdsa/
# operationId: repos_ecdsa_create
export def "repos-ecdsa create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ecdsa-passphrase: string # The ECDSA passphrase used for signing.
  ecdsa_private_key: string # The ECDSA private key.
]: any -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/ecdsa/")
  let body = {ecdsa_passphrase: $ecdsa_passphrase, ecdsa_private_key: $ecdsa_private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerate ECDSA Key for the Repository.
#
# POST /repos/{owner}/{identifier}/ecdsa/regenerate/
# operationId: repos_ecdsa_regenerate
export def "repos-ecdsa-regenerate regenerate" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/ecdsa/regenerate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the active Ed25519 key for the Repository.
#
# GET /repos/{owner}/{identifier}/ed25519/
# operationId: repos_ed25519_list
export def "repos-ed25519 list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, public_key_wire: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/ed25519/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the active Ed25519 key for the Repository.
#
# POST /repos/{owner}/{identifier}/ed25519/
# operationId: repos_ed25519_create
export def "repos-ed25519 create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ed25519-passphrase: string # The Ed25519 passphrase used for signing.
  ed25519_private_key: string # The Ed25519 private key.
]: any -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, public_key_wire: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/ed25519/")
  let body = {ed25519_passphrase: $ed25519_passphrase, ed25519_private_key: $ed25519_private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerate Ed25519 Key for the Repository.
#
# POST /repos/{owner}/{identifier}/ed25519/regenerate/
# operationId: repos_ed25519_regenerate
export def "repos-ed25519-regenerate regenerate" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, public_key_wire: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/ed25519/regenerate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all repository geoip rules.
#
# GET /repos/{owner}/{identifier}/geoip
# operationId: repos_geoip_read
export def "repos-geoip read" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cidr: record<allow: list<string>, deny: list<string>>, country_code: record<allow: list<string>, deny: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace repository geoip rules.
#
# PUT /repos/{owner}/{identifier}/geoip
# operationId: repos_geoip_update
# --cidr shape: {allow: list, deny: list}
# --country_code shape: {allow: list, deny: list}
export def "repos-geoip update" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cidr: record # shape: {allow: list, deny: list}
  country_code: record # shape: {allow: list, deny: list}
]: any -> record<cidr: record<allow: list<string>, deny: list<string>>, country_code: record<allow: list<string>, deny: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip")
  let body = {cidr: $cidr, country_code: $country_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update repository geoip rules.
#
# PATCH /repos/{owner}/{identifier}/geoip
# operationId: repos_geoip_partial_update
# --cidr shape: {allow: list, deny: list}
# --country_code shape: {allow: list, deny: list}
export def "repos-geoip patch" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cidr: record # shape: {allow: list, deny: list}
  --country-code: record # shape: {allow: list, deny: list}
]: any -> record<cidr: record<allow: list<string>, deny: list<string>>, country_code: record<allow: list<string>, deny: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip")
  let body = {cidr: $cidr, country_code: $country_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable GeoIP for this repository.
#
# POST /repos/{owner}/{identifier}/geoip/disable/
# operationId: repos_geoip_disable
export def "repos-geoip-disable disable" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip/disable/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable GeoIP for this repository.
#
# POST /repos/{owner}/{identifier}/geoip/enable/
# operationId: repos_geoip_enable
export def "repos-geoip-enable enable" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip/enable/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the GeoIP status for this repository.
#
# GET /repos/{owner}/{identifier}/geoip/status/
# operationId: api_repos_geoip_status
export def "repos-geoip-status status" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<geoip_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip/status/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test a list of IP addresses against the repository's current GeoIP rules.
#
# POST /repos/{owner}/{identifier}/geoip/test/
# operationId: repos_geoip_test
export def "repos-geoip-test test" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  addresses: list # The IP addresses to test against this repository
]: any -> record<addresses: table<allowed: bool, country_code: string, ip_address: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/geoip/test/")
  let body = {addresses: $addresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the active GPG key for the Repository.
#
# GET /repos/{owner}/{identifier}/gpg/
# operationId: repos_gpg_list
export def "repos-gpg list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, comment: string, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/gpg/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the active GPG key for the Repository.
#
# POST /repos/{owner}/{identifier}/gpg/
# operationId: repos_gpg_create
export def "repos-gpg create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gpg-passphrase: string # The GPG passphrase used for signing.
  gpg_private_key: string # The GPG private key.
]: any -> record<active: bool, comment: string, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/gpg/")
  let body = {gpg_passphrase: $gpg_passphrase, gpg_private_key: $gpg_private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerate GPG Key for the Repository.
#
# POST /repos/{owner}/{identifier}/gpg/regenerate/
# operationId: repos_gpg_regenerate
export def "repos-gpg-regenerate regenerate" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, comment: string, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/gpg/regenerate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all explicity created privileges for the repository.
#
# GET /repos/{owner}/{identifier}/privileges
# operationId: repos_privileges_list
export def "repos-privileges list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<privileges: table<privilege: string, service: string, team: string, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/privileges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace all existing repository privileges with those specified.
#
# PUT /repos/{owner}/{identifier}/privileges
# operationId: repos_privileges_update
# --privileges item shape: {privilege: "Admin"|"Write"|"Read", service?: string, team?: string, user?: string}
export def "repos-privileges update" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  privileges: list # List of objects with explicit privileges to the repository. — item shape: {privilege: "Admin"|"Write"|"Read", service?: string, team?: string, user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/privileges")
  let body = {privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modify privileges for the repository.
#
# PATCH /repos/{owner}/{identifier}/privileges
# operationId: repos_privileges_partial_update
# --privileges item shape: {privilege: "Admin"|"Write"|"Read", service?: string, team?: string, user?: string}
export def "repos-privileges patch" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --privileges: list # List of objects with explicit privileges to the repository. — item shape: {privilege: "Admin"|"Write"|"Read", service?: string, team?: string, user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/privileges")
  let body = {privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the active RSA key for the Repository.
#
# GET /repos/{owner}/{identifier}/rsa/
# operationId: repos_rsa_list
export def "repos-rsa list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/rsa/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the active RSA key for the Repository.
#
# POST /repos/{owner}/{identifier}/rsa/
# operationId: repos_rsa_create
export def "repos-rsa create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rsa-passphrase: string # The RSA passphrase used for signing.
  rsa_private_key: string # The RSA private key.
]: any -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/rsa/")
  let body = {rsa_passphrase: $rsa_passphrase, rsa_private_key: $rsa_private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerate RSA Key for the Repository.
#
# POST /repos/{owner}/{identifier}/rsa/regenerate/
# operationId: repos_rsa_regenerate
export def "repos-rsa-regenerate regenerate" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created_at: string, default: bool, fingerprint: string, fingerprint_short: string, public_key: string, ssh_fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/rsa/regenerate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Alpine upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/alpine/
# operationId: repos_upstream_alpine_list
export def "repos-upstream-alpine list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, rsa_key_inline: string, rsa_key_url: string, rsa_verification: string, rsa_verification_status: string, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/alpine/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Alpine upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/alpine/
# operationId: repos_upstream_alpine_create
export def "repos-upstream-alpine create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --rsa-key-url: string # When provided, Cloudsmith will fetch and validate the RSA public key at this URL and use it to verify package signatures from this upstream. (format: uri)
  --rsa-verification: string@rsa-verification-completer # The RSA signature verification mode for this upstream. (default: Allow All)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, rsa_key_inline: string, rsa_key_url: string, rsa_verification: string, rsa_verification_status: string, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/alpine/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, rsa_key_url: $rsa_key_url, rsa_verification: $rsa_verification, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an Alpine upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/alpine/{slug_perm}/
# operationId: repos_upstream_alpine_read
export def "repos-upstream-alpine read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, rsa_key_inline: string, rsa_key_url: string, rsa_verification: string, rsa_verification_status: string, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/alpine/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Alpine upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/alpine/{slug_perm}/
# operationId: repos_upstream_alpine_update
export def "repos-upstream-alpine update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --rsa-key-url: string # When provided, Cloudsmith will fetch and validate the RSA public key at this URL and use it to verify package signatures from this upstream. (format: uri)
  --rsa-verification: string@rsa-verification-completer # The RSA signature verification mode for this upstream. (default: Allow All)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, rsa_key_inline: string, rsa_key_url: string, rsa_verification: string, rsa_verification_status: string, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/alpine/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, rsa_key_url: $rsa_key_url, rsa_verification: $rsa_verification, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update an Alpine upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/alpine/{slug_perm}/
# operationId: repos_upstream_alpine_partial_update
export def "repos-upstream-alpine patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --rsa-key-url: string # When provided, Cloudsmith will fetch and validate the RSA public key at this URL and use it to verify package signatures from this upstream. (format: uri)
  --rsa-verification: string@rsa-verification-completer # The RSA signature verification mode for this upstream. (default: Allow All)
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, rsa_key_inline: string, rsa_key_url: string, rsa_verification: string, rsa_verification_status: string, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/alpine/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, rsa_key_url: $rsa_key_url, rsa_verification: $rsa_verification, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Alpine upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/alpine/{slug_perm}/
# operationId: repos_upstream_alpine_delete
export def "repos-upstream-alpine delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/alpine/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Cargo upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/cargo/
# operationId: repos_upstream_cargo_list
export def "repos-upstream-cargo list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cargo/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Cargo upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/cargo/
# operationId: repos_upstream_cargo_create
export def "repos-upstream-cargo create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cargo/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Cargo upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/cargo/{slug_perm}/
# operationId: repos_upstream_cargo_read
export def "repos-upstream-cargo read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cargo/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Cargo upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/cargo/{slug_perm}/
# operationId: repos_upstream_cargo_update
export def "repos-upstream-cargo update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cargo/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Cargo upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/cargo/{slug_perm}/
# operationId: repos_upstream_cargo_partial_update
export def "repos-upstream-cargo patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cargo/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Cargo upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/cargo/{slug_perm}/
# operationId: repos_upstream_cargo_delete
export def "repos-upstream-cargo delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cargo/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Composer upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/composer/
# operationId: repos_upstream_composer_list
export def "repos-upstream-composer list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/composer/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Composer upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/composer/
# operationId: repos_upstream_composer_create
export def "repos-upstream-composer create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/composer/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Composer upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/composer/{slug_perm}/
# operationId: repos_upstream_composer_read
export def "repos-upstream-composer read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/composer/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Composer upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/composer/{slug_perm}/
# operationId: repos_upstream_composer_update
export def "repos-upstream-composer update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/composer/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Composer upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/composer/{slug_perm}/
# operationId: repos_upstream_composer_partial_update
export def "repos-upstream-composer patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/composer/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Composer upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/composer/{slug_perm}/
# operationId: repos_upstream_composer_delete
export def "repos-upstream-composer delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/composer/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Conda upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/conda/
# operationId: repos_upstream_conda_list
export def "repos-upstream-conda list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/conda/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Conda upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/conda/
# operationId: repos_upstream_conda_create
export def "repos-upstream-conda create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/conda/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Conda upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/conda/{slug_perm}/
# operationId: repos_upstream_conda_read
export def "repos-upstream-conda read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/conda/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Conda upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/conda/{slug_perm}/
# operationId: repos_upstream_conda_update
export def "repos-upstream-conda update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/conda/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Conda upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/conda/{slug_perm}/
# operationId: repos_upstream_conda_partial_update
export def "repos-upstream-conda patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/conda/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Conda upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/conda/{slug_perm}/
# operationId: repos_upstream_conda_delete
export def "repos-upstream-conda delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/conda/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List CRAN upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/cran/
# operationId: repos_upstream_cran_list
export def "repos-upstream-cran list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cran/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a CRAN upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/cran/
# operationId: repos_upstream_cran_create
export def "repos-upstream-cran create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cran/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a CRAN upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/cran/{slug_perm}/
# operationId: repos_upstream_cran_read
export def "repos-upstream-cran read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cran/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a CRAN upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/cran/{slug_perm}/
# operationId: repos_upstream_cran_update
export def "repos-upstream-cran update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cran/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a CRAN upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/cran/{slug_perm}/
# operationId: repos_upstream_cran_partial_update
export def "repos-upstream-cran patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cran/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a CRAN upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/cran/{slug_perm}/
# operationId: repos_upstream_cran_delete
export def "repos-upstream-cran delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/cran/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Dart upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/dart/
# operationId: repos_upstream_dart_list
export def "repos-upstream-dart list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/dart/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Dart upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/dart/
# operationId: repos_upstream_dart_create
export def "repos-upstream-dart create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/dart/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Dart upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/dart/{slug_perm}/
# operationId: repos_upstream_dart_read
export def "repos-upstream-dart read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/dart/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Dart upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/dart/{slug_perm}/
# operationId: repos_upstream_dart_update
export def "repos-upstream-dart update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/dart/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Dart upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/dart/{slug_perm}/
# operationId: repos_upstream_dart_partial_update
export def "repos-upstream-dart patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/dart/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Dart upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/dart/{slug_perm}/
# operationId: repos_upstream_dart_delete
export def "repos-upstream-dart delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/dart/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Debian upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/deb/
# operationId: repos_upstream_deb_list
export def "repos-upstream-deb list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, component: string, created_at: string, disable_reason: string, disable_reason_text: string, distro_versions: list<string>, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_distribution: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/deb/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Debian upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/deb/
# operationId: repos_upstream_deb_create
export def "repos-upstream-deb create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --component: string # The component to fetch from the upstream
  distro_versions: list # The distribution version that packages found on this upstream could be associated with.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --include-sources: string@bool-completer # When true, source packages will be available from this upstream.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-distribution: string # The distribution to fetch from the upstream
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, component: string, created_at: string, disable_reason: string, disable_reason_text: string, distro_versions: list<string>, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_distribution: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/deb/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, component: $component, distro_versions: $distro_versions, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, include_sources: $include_sources, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_distribution: $upstream_distribution, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Debian upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/deb/{slug_perm}/
# operationId: repos_upstream_deb_read
export def "repos-upstream-deb read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, component: string, created_at: string, disable_reason: string, disable_reason_text: string, distro_versions: list<string>, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_distribution: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/deb/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Debian upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/deb/{slug_perm}/
# operationId: repos_upstream_deb_update
export def "repos-upstream-deb update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --component: string # The component to fetch from the upstream
  distro_versions: list # The distribution version that packages found on this upstream could be associated with.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --include-sources: string@bool-completer # When true, source packages will be available from this upstream.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-distribution: string # The distribution to fetch from the upstream
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, component: string, created_at: string, disable_reason: string, disable_reason_text: string, distro_versions: list<string>, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_distribution: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/deb/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, component: $component, distro_versions: $distro_versions, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, include_sources: $include_sources, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_distribution: $upstream_distribution, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Debian upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/deb/{slug_perm}/
# operationId: repos_upstream_deb_partial_update
export def "repos-upstream-deb patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --component: string # The component to fetch from the upstream
  --distro-versions: list # The distribution version that packages found on this upstream could be associated with.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --include-sources: string@bool-completer # When true, source packages will be available from this upstream.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-distribution: string # The distribution to fetch from the upstream
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, component: string, created_at: string, disable_reason: string, disable_reason_text: string, distro_versions: list<string>, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_distribution: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/deb/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, component: $component, distro_versions: $distro_versions, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, include_sources: $include_sources, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_distribution: $upstream_distribution, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Debian upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/deb/{slug_perm}/
# operationId: repos_upstream_deb_delete
export def "repos-upstream-deb delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/deb/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Docker upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/docker/
# operationId: repos_upstream_docker_list
export def "repos-upstream-docker list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, is_active: bool, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/docker/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Docker upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/docker/
# operationId: repos_upstream_docker_create
export def "repos-upstream-docker create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-certificate: string # X.509 Certificate to use for mTLS authentication against the upstream
  --auth-certificate-key: string # Certificate key to use for mTLS authentication against the upstream
  --auth-mode: string@auth-mode-completer-1 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, is_active: bool, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/docker/")
  let body = {auth_certificate: $auth_certificate, auth_certificate_key: $auth_certificate_key, auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Docker upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/docker/{slug_perm}/
# operationId: repos_upstream_docker_read
export def "repos-upstream-docker read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, is_active: bool, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/docker/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Docker upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/docker/{slug_perm}/
# operationId: repos_upstream_docker_update
export def "repos-upstream-docker update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-certificate: string # X.509 Certificate to use for mTLS authentication against the upstream
  --auth-certificate-key: string # Certificate key to use for mTLS authentication against the upstream
  --auth-mode: string@auth-mode-completer-1 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, is_active: bool, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/docker/($slug_perm)/")
  let body = {auth_certificate: $auth_certificate, auth_certificate_key: $auth_certificate_key, auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Docker upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/docker/{slug_perm}/
# operationId: repos_upstream_docker_partial_update
export def "repos-upstream-docker patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-certificate: string # X.509 Certificate to use for mTLS authentication against the upstream
  --auth-certificate-key: string # Certificate key to use for mTLS authentication against the upstream
  --auth-mode: string@auth-mode-completer-1 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, is_active: bool, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/docker/($slug_perm)/")
  let body = {auth_certificate: $auth_certificate, auth_certificate_key: $auth_certificate_key, auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Docker upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/docker/{slug_perm}/
# operationId: repos_upstream_docker_delete
export def "repos-upstream-docker delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/docker/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Generic upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/generic/
# operationId: repos_upstream_generic_list
export def "repos-upstream-generic list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_prefix: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/generic/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Generic upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/generic/
# operationId: repos_upstream_generic_create
export def "repos-upstream-generic create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-2 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-prefix: string # A unique prefix used to distinguish this upstream source within the repository. Generic upstreams can represent entirely different file servers, and we do not attempt to blend them. The prefix ensures each source remains separate, and requests including this prefix are routed to the correct upstream.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_prefix: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/generic/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_prefix: $upstream_prefix, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Generic upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/generic/{slug_perm}/
# operationId: repos_upstream_generic_read
export def "repos-upstream-generic read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_prefix: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/generic/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Generic upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/generic/{slug_perm}/
# operationId: repos_upstream_generic_update
export def "repos-upstream-generic update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-2 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-prefix: string # A unique prefix used to distinguish this upstream source within the repository. Generic upstreams can represent entirely different file servers, and we do not attempt to blend them. The prefix ensures each source remains separate, and requests including this prefix are routed to the correct upstream.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_prefix: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/generic/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_prefix: $upstream_prefix, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Generic upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/generic/{slug_perm}/
# operationId: repos_upstream_generic_partial_update
export def "repos-upstream-generic patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-2 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-prefix: string # A unique prefix used to distinguish this upstream source within the repository. Generic upstreams can represent entirely different file servers, and we do not attempt to blend them. The prefix ensures each source remains separate, and requests including this prefix are routed to the correct upstream.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_prefix: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/generic/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_prefix: $upstream_prefix, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Generic upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/generic/{slug_perm}/
# operationId: repos_upstream_generic_delete
export def "repos-upstream-generic delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/generic/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Go upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/go/
# operationId: repos_upstream_go_list
export def "repos-upstream-go list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/go/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Go upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/go/
# operationId: repos_upstream_go_create
export def "repos-upstream-go create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/go/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Go upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/go/{slug_perm}/
# operationId: repos_upstream_go_read
export def "repos-upstream-go read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/go/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Go upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/go/{slug_perm}/
# operationId: repos_upstream_go_update
export def "repos-upstream-go update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/go/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Go upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/go/{slug_perm}/
# operationId: repos_upstream_go_partial_update
export def "repos-upstream-go patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/go/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Go upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/go/{slug_perm}/
# operationId: repos_upstream_go_delete
export def "repos-upstream-go delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/go/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Helm upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/helm/
# operationId: repos_upstream_helm_list
export def "repos-upstream-helm list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/helm/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Helm upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/helm/
# operationId: repos_upstream_helm_create
export def "repos-upstream-helm create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/helm/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Helm upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/helm/{slug_perm}/
# operationId: repos_upstream_helm_read
export def "repos-upstream-helm read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/helm/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Helm upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/helm/{slug_perm}/
# operationId: repos_upstream_helm_update
export def "repos-upstream-helm update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/helm/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Helm upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/helm/{slug_perm}/
# operationId: repos_upstream_helm_partial_update
export def "repos-upstream-helm patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/helm/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Helm upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/helm/{slug_perm}/
# operationId: repos_upstream_helm_delete
export def "repos-upstream-helm delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/helm/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Hex upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/hex/
# operationId: repos_upstream_hex_list
export def "repos-upstream-hex list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/hex/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Hex upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/hex/
# operationId: repos_upstream_hex_create
export def "repos-upstream-hex create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/hex/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Hex upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/hex/{slug_perm}/
# operationId: repos_upstream_hex_read
export def "repos-upstream-hex read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/hex/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Hex upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/hex/{slug_perm}/
# operationId: repos_upstream_hex_update
export def "repos-upstream-hex update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/hex/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Hex upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/hex/{slug_perm}/
# operationId: repos_upstream_hex_partial_update
export def "repos-upstream-hex patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/hex/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Hex upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/hex/{slug_perm}/
# operationId: repos_upstream_hex_delete
export def "repos-upstream-hex delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/hex/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List HuggingFace upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/huggingface/
# operationId: repos_upstream_huggingface_list
export def "repos-upstream-huggingface list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/huggingface/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a HuggingFace upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/huggingface/
# operationId: repos_upstream_huggingface_create
export def "repos-upstream-huggingface create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-3 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/huggingface/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a HuggingFace upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/huggingface/{slug_perm}/
# operationId: repos_upstream_huggingface_read
export def "repos-upstream-huggingface read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/huggingface/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a HuggingFace upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/huggingface/{slug_perm}/
# operationId: repos_upstream_huggingface_update
export def "repos-upstream-huggingface update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-3 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/huggingface/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a HuggingFace upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/huggingface/{slug_perm}/
# operationId: repos_upstream_huggingface_partial_update
export def "repos-upstream-huggingface patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-3 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/huggingface/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a HuggingFace upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/huggingface/{slug_perm}/
# operationId: repos_upstream_huggingface_delete
export def "repos-upstream-huggingface delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/huggingface/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Maven upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/maven/
# operationId: repos_upstream_maven_list
export def "repos-upstream-maven list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/maven/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Maven upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/maven/
# operationId: repos_upstream_maven_create
export def "repos-upstream-maven create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer-1 # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/maven/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Maven upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/maven/{slug_perm}/
# operationId: repos_upstream_maven_read
export def "repos-upstream-maven read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/maven/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Maven upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/maven/{slug_perm}/
# operationId: repos_upstream_maven_update
export def "repos-upstream-maven update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer-1 # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/maven/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Maven upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/maven/{slug_perm}/
# operationId: repos_upstream_maven_partial_update
export def "repos-upstream-maven patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer-1 # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/maven/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Maven upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/maven/{slug_perm}/
# operationId: repos_upstream_maven_delete
export def "repos-upstream-maven delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/maven/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List npm upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/npm/
# operationId: repos_upstream_npm_list
export def "repos-upstream-npm list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/npm/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a npm upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/npm/
# operationId: repos_upstream_npm_create
export def "repos-upstream-npm create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-2 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/npm/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a npm upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/npm/{slug_perm}/
# operationId: repos_upstream_npm_read
export def "repos-upstream-npm read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/npm/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a npm upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/npm/{slug_perm}/
# operationId: repos_upstream_npm_update
export def "repos-upstream-npm update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-2 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/npm/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a npm upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/npm/{slug_perm}/
# operationId: repos_upstream_npm_partial_update
export def "repos-upstream-npm patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer-2 # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/npm/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a npm upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/npm/{slug_perm}/
# operationId: repos_upstream_npm_delete
export def "repos-upstream-npm delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/npm/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List NuGet upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/nuget/
# operationId: repos_upstream_nuget_list
export def "repos-upstream-nuget list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/nuget/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a NuGet upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/nuget/
# operationId: repos_upstream_nuget_create
export def "repos-upstream-nuget create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/nuget/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a NuGet upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/nuget/{slug_perm}/
# operationId: repos_upstream_nuget_read
export def "repos-upstream-nuget read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/nuget/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a NuGet upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/nuget/{slug_perm}/
# operationId: repos_upstream_nuget_update
export def "repos-upstream-nuget update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/nuget/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a NuGet upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/nuget/{slug_perm}/
# operationId: repos_upstream_nuget_partial_update
export def "repos-upstream-nuget patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/nuget/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a NuGet upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/nuget/{slug_perm}/
# operationId: repos_upstream_nuget_delete
export def "repos-upstream-nuget delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/nuget/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Python upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/python/
# operationId: repos_upstream_python_list
export def "repos-upstream-python list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/python/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Python upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/python/
# operationId: repos_upstream_python_create
export def "repos-upstream-python create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/python/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Python upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/python/{slug_perm}/
# operationId: repos_upstream_python_read
export def "repos-upstream-python read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/python/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Python upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/python/{slug_perm}/
# operationId: repos_upstream_python_update
export def "repos-upstream-python update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/python/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Python upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/python/{slug_perm}/
# operationId: repos_upstream_python_partial_update
export def "repos-upstream-python patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --trust-level: string@trust-level-completer # Trust level allows for control of the visibility of upstream artifacts to native package managers. Where supported by formats, the default level (untrusted) is recommended for all upstreams, and helps to safeguard against common dependency confusion attack vectors. (default: Trusted)
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, trust_level: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/python/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, trust_level: $trust_level, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Python upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/python/{slug_perm}/
# operationId: repos_upstream_python_delete
export def "repos-upstream-python delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/python/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List RedHat upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/rpm/
# operationId: repos_upstream_rpm_list
export def "repos-upstream-rpm list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, distro_version: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/rpm/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a RedHat upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/rpm/
# operationId: repos_upstream_rpm_create
export def "repos-upstream-rpm create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  distro_version: string # The distribution version that packages found on this upstream will be associated with.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --include-sources: string@bool-completer # When checked, source packages will be available from this upstream.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, distro_version: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/rpm/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, distro_version: $distro_version, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, include_sources: $include_sources, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a RedHat upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/rpm/{slug_perm}/
# operationId: repos_upstream_rpm_read
export def "repos-upstream-rpm read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, distro_version: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/rpm/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a RedHat upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/rpm/{slug_perm}/
# operationId: repos_upstream_rpm_update
export def "repos-upstream-rpm update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  distro_version: string # The distribution version that packages found on this upstream will be associated with.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --include-sources: string@bool-completer # When checked, source packages will be available from this upstream.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, distro_version: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/rpm/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, distro_version: $distro_version, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, include_sources: $include_sources, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a RedHat upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/rpm/{slug_perm}/
# operationId: repos_upstream_rpm_partial_update
export def "repos-upstream-rpm patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --distro-version: string # The distribution version that packages found on this upstream will be associated with.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --gpg-key-inline: string # A public GPG key to associate with packages found on this upstream. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install.
  --gpg-key-url: string # When provided, Cloudsmith will fetch, validate, and associate a public GPG key found at the provided URL. When using the Cloudsmith setup script, this GPG key will be automatically imported on your deployment machines to allow upstream packages to validate and install. (format: uri)
  --gpg-verification: string@gpg-verification-completer # The GPG signature verification mode for this upstream. (default: Allow All)
  --include-sources: string@bool-completer # When checked, source packages will be available from this upstream.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, distro_version: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, gpg_key_fingerprint_short: string, gpg_key_inline: string, gpg_key_url: string, gpg_verification: string, has_failed_signature_verification: bool, include_sources: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verification_status: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/rpm/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, distro_version: $distro_version, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, gpg_key_inline: $gpg_key_inline, gpg_key_url: $gpg_key_url, gpg_verification: $gpg_verification, include_sources: $include_sources, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a RedHat upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/rpm/{slug_perm}/
# operationId: repos_upstream_rpm_delete
export def "repos-upstream-rpm delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/rpm/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Ruby upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/ruby/
# operationId: repos_upstream_ruby_list
export def "repos-upstream-ruby list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/ruby/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Ruby upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/ruby/
# operationId: repos_upstream_ruby_create
export def "repos-upstream-ruby create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/ruby/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Ruby upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/ruby/{slug_perm}/
# operationId: repos_upstream_ruby_read
export def "repos-upstream-ruby read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/ruby/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Ruby upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/ruby/{slug_perm}/
# operationId: repos_upstream_ruby_update
export def "repos-upstream-ruby update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/ruby/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Ruby upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/ruby/{slug_perm}/
# operationId: repos_upstream_ruby_partial_update
export def "repos-upstream-ruby patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/ruby/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Ruby upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/ruby/{slug_perm}/
# operationId: repos_upstream_ruby_delete
export def "repos-upstream-ruby delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/ruby/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Swift upstream configs for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/swift/
# operationId: repos_upstream_swift_list
export def "repos-upstream-swift list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/swift/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Swift upstream config for this repository.
#
# POST /repos/{owner}/{identifier}/upstream/swift/
# operationId: repos_upstream_swift_create
export def "repos-upstream-swift create" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/swift/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Swift upstream config for this repository.
#
# GET /repos/{owner}/{identifier}/upstream/swift/{slug_perm}/
# operationId: repos_upstream_swift_read
export def "repos-upstream-swift read" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/swift/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Swift upstream config for this repository.
#
# PUT /repos/{owner}/{identifier}/upstream/swift/{slug_perm}/
# operationId: repos_upstream_swift_update
export def "repos-upstream-swift update" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  upstream_url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/swift/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a Swift upstream config for this repository.
#
# PATCH /repos/{owner}/{identifier}/upstream/swift/{slug_perm}/
# operationId: repos_upstream_swift_partial_update
export def "repos-upstream-swift patch" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-mode: string@auth-mode-completer # The authentication mode to use when accessing this upstream.  (default: None)
  --auth-secret: string # Secret to provide with requests to upstream.
  --auth-username: string # Username to provide with requests to upstream.
  --extra-header-1: string # The key for extra header #1 to send to upstream.
  --extra-header-2: string # The key for extra header #2 to send to upstream.
  --extra-value-1: string # The value for extra header #1 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --extra-value-2: string # The value for extra header #2 to send to upstream. This is stored as plaintext, and is NOT encrypted.
  --is-active: string@bool-completer # Whether or not this upstream is active and ready for requests.
  --mode: string@mode-completer # The mode that this upstream should operate in. Upstream sources can be used to proxy resolved packages, as well as operate in a proxy/cache or cache only mode. (default: Proxy Only)
  --name: string # A descriptive name for this upstream source. A shortened version of this name will be used for tagging cached packages retrieved from this upstream.
  --priority: int # Upstream sources are selected for resolving requests by sequential order (1..n), followed by creation date.
  --upstream-url: string # The URL for this upstream source. This must be a fully qualified URL including any path elements required to reach the root of the repository.  (format: uri)
  --verify-ssl: string@bool-completer # If enabled, SSL certificates are verified when requests are made to this upstream. It's recommended to leave this enabled for all public sources to help mitigate Man-In-The-Middle (MITM) attacks. Please note this only applies to HTTPS upstreams.
]: any -> record<auth_mode: string, auth_secret: string, auth_username: string, available: bool, can_reindex: bool, created_at: string, disable_reason: string, disable_reason_text: string, extra_header_1: string, extra_header_2: string, extra_value_1: string, extra_value_2: string, has_failed_signature_verification: bool, index_package_count: int, index_status: string, is_active: bool, last_indexed: string, mode: string, name: string, pending_validation: bool, priority: int, slug_perm: string, updated_at: string, upstream_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/swift/($slug_perm)/")
  let body = {auth_mode: $auth_mode, auth_secret: $auth_secret, auth_username: $auth_username, extra_header_1: $extra_header_1, extra_header_2: $extra_header_2, extra_value_1: $extra_value_1, extra_value_2: $extra_value_2, is_active: $is_active, mode: $mode, name: $name, priority: $priority, upstream_url: $upstream_url, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Swift upstream config for this repository.
#
# DELETE /repos/{owner}/{identifier}/upstream/swift/{slug_perm}/
# operationId: repos_upstream_swift_delete
export def "repos-upstream-swift delete" [
  owner: string
  identifier: string
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/upstream/swift/($slug_perm)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the active X.509 ECDSA certificate for the Repository.
#
# GET /repos/{owner}/{identifier}/x509-ecdsa/
# operationId: repos_x509_ecdsa_list
export def "repos-x509-ecdsa list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, certificate: string, certificate_chain: string, certificate_chain_fingerprint: string, certificate_chain_fingerprint_short: string, certificate_fingerprint: string, certificate_fingerprint_short: string, created_at: string, default: bool, issuing_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/x509-ecdsa/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the active X.509 RSA certificate for the Repository.
#
# GET /repos/{owner}/{identifier}/x509-rsa/
# operationId: repos_x509_rsa_list
export def "repos-x509-rsa list" [
  owner: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, certificate: string, certificate_chain: string, certificate_chain_fingerprint: string, certificate_chain_fingerprint_short: string, certificate_fingerprint: string, certificate_fingerprint_short: string, created_at: string, default: bool, issuing_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($identifier)/x509-rsa/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the retention rules for the repository.
#
# GET /repos/{owner}/{repo}/retention/
# operationId: repo_retention_read
export def "repos-retention read" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<retention_count_limit: int, retention_days_limit: int, retention_enabled: bool, retention_group_by_format: bool, retention_group_by_name: bool, retention_group_by_package_type: bool, retention_package_query_string: string, retention_size_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/retention/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the retention rules for the repository.
#
# PATCH /repos/{owner}/{repo}/retention/
# operationId: repo_retention_partial_update
export def "repos-retention patch" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --retention-count-limit: int # The maximum X number of packages to retain.
  --retention-days-limit: int # The X number of days of packages to retain.
  --retention-enabled: string@bool-completer # If checked, the retention lifecycle rules will be activated for the repository. Any packages that don't match will be deleted automatically, and the rest are retained.
  --retention-group-by-format: string@bool-completer # If checked, retention will apply to packages by package formats rather than across all package formats.For example, when retaining by a limit of 1 and you upload PythonPkg 1.0 and RubyPkg 1.0, no packages are deleted because they are different formats.
  --retention-group-by-name: string@bool-completer # If checked, retention will apply to groups of packages by name rather than all packages.<br>For example, when retaining by a limit of 1 and you upload PkgA 1.0, PkgB 1.0 and PkgB 1.1; only PkgB 1.0 is deleted because there are two (2) PkgBs and one (1) PkgA.
  --retention-group-by-package-type: string@bool-completer # If checked, retention will apply to packages by package type (e.g. by binary, by source, etc.), rather than across all package types for one or more formats. <br>For example, when retaining by a limit of 1 and you upload DebPackage 1.0 and DebSourcePackage 1.0, no packages are deleted because they are different package types, binary and source respectively.
  --retention-package-query-string: string # A package search expression which, if provided, filters the packages to be deleted.<br>For example, a search expression of `name:foo` will result in only packages called 'foo' being deleted, or a search expression of `tag:~latest` will prevent any packages tagged 'latest' from being deleted.<br>Refer to the Cloudsmith documentation for package query syntax.
  --retention-size-limit: int # The maximum X total size (in bytes) of packages to retain.
]: any -> record<retention_count_limit: int, retention_days_limit: int, retention_enabled: bool, retention_group_by_format: bool, retention_group_by_name: bool, retention_group_by_package_type: bool, retention_package_query_string: string, retention_size_limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/retention/")
  let body = {retention_count_limit: $retention_count_limit, retention_days_limit: $retention_days_limit, retention_enabled: $retention_enabled, retention_group_by_format: $retention_group_by_format, retention_group_by_name: $retention_group_by_name, retention_group_by_package_type: $retention_group_by_package_type, retention_package_query_string: $retention_package_query_string, retention_size_limit: $retention_size_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer a repository to a different region.
#
# POST /repos/{owner}/{repo}/transfer-region/
# operationId: repos_transfer_region
export def "repos-transfer-region region" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --storage-region: string # The Cloudsmith region in which package files are stored. (default: default)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/transfer-region/")
  let body = {storage_region: $storage_region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Endpoint to check basic API connectivity.
#
# GET /status/check/basic/
# operationId: status_check_basic
export def "status-check-basic basic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<detail: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status/check/basic/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all available storage regions.
#
# GET /storage-regions/
# operationId: storage-regions_list
export def "storage-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<label: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storage-regions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific storage region.
#
# GET /storage-regions/{slug}/
# operationId: storage-regions_read
export def "storage-regions read" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<label: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storage-regions/($slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provide a brief for the current user (if any).
#
# GET /user/self/
# operationId: user_self
export def "user-self self" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authenticated: bool, email: string, name: string, profile_url: string, self_url: string, slug: string, slug_perm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/self/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or retrieve API token for a user.
#
# POST /user/token/
# operationId: user_token_create
export def "user-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email address to authenticate with (format: email)
  --password: string # Password to authenticate with
  --totp-token: string # Two-factor authentication code
]: any -> record<token: string, two_factor_required: bool, two_factor_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/token/")
  let body = {email: $email, password: $password, totp_token: $totp_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the API key assigned to the user that is currently authenticated.
#
# GET /user/tokens/
# operationId: user_tokens_list
export def "user-tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<results: table<created: string, key: string, slug_perm: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/tokens/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API key for the user that is currently authenticated.
#
# POST /user/tokens/
# operationId: user_tokens_create
export def "user-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created: string, key: string, slug_perm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/tokens/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh the specified API key for the user that is currently authenticated.
#
# PUT /user/tokens/{slug_perm}/refresh/
# operationId: user_tokens_refresh
export def "user-tokens-refresh refresh" [
  slug_perm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created: string, key: string, slug_perm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/tokens/($slug_perm)/refresh/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provide a brief for the specified user (if any).
#
# GET /users/profile/{slug}/
# operationId: users_profile_read
export def "users-profile read" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<company: string, first_name: string, job_title: string, joined_at: string, last_name: string, name: string, slug: string, slug_perm: string, tagline: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/profile/($slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists scan results for a specific namespace.
#
# GET /vulnerabilities/{owner}/
# operationId: vulnerabilities_namespace_list
export def "vulnerabilities list-by-owner" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<created_at: string, has_vulnerabilities: bool, identifier: string, max_severity: string, num_vulnerabilities: int, package: record<identifier: string, name: string, url: string, version: string>, scan_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vulnerabilities/($owner)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists scan results for a specific repository.
#
# GET /vulnerabilities/{owner}/{repo}/
# operationId: vulnerabilities_repo_list
export def "vulnerabilities list-by-owner-repo" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<created_at: string, has_vulnerabilities: bool, identifier: string, max_severity: string, num_vulnerabilities: int, package: record<identifier: string, name: string, url: string, version: string>, scan_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vulnerabilities/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists scan results for a specific package.
#
# GET /vulnerabilities/{owner}/{repo}/{package}/
# operationId: vulnerabilities_package_list
export def "vulnerabilities list-by-owner-repo-package" [
  owner: string
  repo: string
  package: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<created_at: string, has_vulnerabilities: bool, identifier: string, max_severity: string, num_vulnerabilities: int, package: record<identifier: string, name: string, url: string, version: string>, scan_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vulnerabilities/($owner)/($repo)/($package)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a scan result.
#
# GET /vulnerabilities/{owner}/{repo}/{package}/{identifier}/
# operationId: vulnerabilities_read
export def "vulnerabilities read" [
  owner: string
  repo: string
  package: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, has_vulnerabilities: bool, identifier: string, max_severity: string, num_vulnerabilities: int, package: record<identifier: string, name: string, url: string, version: string>, scan_id: int, scans: table<results: list, target: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vulnerabilities/($owner)/($repo)/($package)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all webhooks in a repository.
#
# GET /webhooks/{owner}/{repo}/
# operationId: webhooks_list
export def "webhooks list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> table<created_at: string, created_by: string, created_by_url: string, disable_reason: int, disable_reason_str: string, events: list<string>, identifier: int, is_active: bool, is_last_response_bad: bool, last_response_status: int, last_response_status_str: string, num_sent: int, package_query: string, request_body_format: int, request_body_format_str: string, request_body_template_format: int, request_body_template_format_str: string, request_content_type: string, secret_header: string, self_url: string, slug_perm: string, target_url: string, templates: list<record>, updated_at: string, updated_by: string, updated_by_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($owner)/($repo)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a specific webhook in a repository.
#
# POST /webhooks/{owner}/{repo}/
# operationId: webhooks_create
# --templates item shape: {event: string, template?: string}
export def "webhooks create" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list
  --is-active: string@bool-completer # If enabled, the webhook will trigger on subscribed events and send payloads to the configured target URL.
  --package-query: string # The package-based search query for webhooks to fire. This uses the same syntax as the standard search used for repositories, and also supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. If a package does not match, the webhook will not fire.
  --request-body-format: int@request-body-format-completer # The format of the payloads for webhook requests. Valid options are: (0) JSON, (1) JSON array, (2) form encoded JSON and (3) Handlebars template.
  --request-body-template-format: int@request-body-template-format-completer # The format of the payloads for webhook requests. Valid options are: (0) Generic/user defined, (1) JSON and (2) XML.
  --request-content-type: string # The value that will be sent for the 'Content Type' header. 
  --secret-header: string # The header to send the predefined secret in. This must be unique from existing headers or it won't be sent. You can use this as a form of authentication on the endpoint side.
  --secret-value: string # The value for the predefined secret (note: this is treated as a passphrase and is encrypted when we store it). You can use this as a form of authentication on the endpoint side.
  --signature-key: string # The value for the signature key - This is used to generate an HMAC-based hex digest of the request body, which we send as the X-Cloudsmith-Signature header so that you can ensure that the request wasn't modified by a malicious party (note: this is treated as a passphrase and is encrypted when we store it).
  target_url: string # The destination URL that webhook payloads will be POST'ed to. (format: uri)
  templates: list # item shape: {event: string, template?: string}
  --verify-ssl: string@bool-completer # If enabled, SSL certificates is verified when webhooks are sent. It's recommended to leave this enabled as not verifying the integrity of SSL certificates leaves you susceptible to Man-in-the-Middle (MITM) attacks.
]: any -> record<created_at: string, created_by: string, created_by_url: string, disable_reason: int, disable_reason_str: string, events: list<string>, identifier: int, is_active: bool, is_last_response_bad: bool, last_response_status: int, last_response_status_str: string, num_sent: int, package_query: string, request_body_format: int, request_body_format_str: string, request_body_template_format: int, request_body_template_format_str: string, request_content_type: string, secret_header: string, self_url: string, slug_perm: string, target_url: string, templates: table<event: string, template: string>, updated_at: string, updated_by: string, updated_by_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($owner)/($repo)/")
  let body = {events: $events, is_active: $is_active, package_query: $package_query, request_body_format: $request_body_format, request_body_template_format: $request_body_template_format, request_content_type: $request_content_type, secret_header: $secret_header, secret_value: $secret_value, signature_key: $signature_key, target_url: $target_url, templates: $templates, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Views for working with repository webhooks.
#
# GET /webhooks/{owner}/{repo}/{identifier}/
# operationId: webhooks_read
export def "webhooks read" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, created_by: string, created_by_url: string, disable_reason: int, disable_reason_str: string, events: list<string>, identifier: int, is_active: bool, is_last_response_bad: bool, last_response_status: int, last_response_status_str: string, num_sent: int, package_query: string, request_body_format: int, request_body_format_str: string, request_body_template_format: int, request_body_template_format_str: string, request_content_type: string, secret_header: string, self_url: string, slug_perm: string, target_url: string, templates: table<event: string, template: string>, updated_at: string, updated_by: string, updated_by_url: string, verify_ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($owner)/($repo)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific webhook in a repository.
#
# PATCH /webhooks/{owner}/{repo}/{identifier}/
# operationId: webhooks_partial_update
# --templates item shape: {event: string, template?: string}
export def "webhooks patch" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --events: list
  --is-active: string@bool-completer # If enabled, the webhook will trigger on subscribed events and send payloads to the configured target URL.
  --package-query: string # The package-based search query for webhooks to fire. This uses the same syntax as the standard search used for repositories, and also supports boolean logic operators such as OR/AND/NOT and parentheses for grouping. If a package does not match, the webhook will not fire.
  --request-body-format: int@request-body-format-completer # The format of the payloads for webhook requests. Valid options are: (0) JSON, (1) JSON array, (2) form encoded JSON and (3) Handlebars template.
  --request-body-template-format: int@request-body-template-format-completer # The format of the payloads for webhook requests. Valid options are: (0) Generic/user defined, (1) JSON and (2) XML.
  --request-content-type: string # The value that will be sent for the 'Content Type' header. 
  --secret-header: string # The header to send the predefined secret in. This must be unique from existing headers or it won't be sent. You can use this as a form of authentication on the endpoint side.
  --secret-value: string # The value for the predefined secret (note: this is treated as a passphrase and is encrypted when we store it). You can use this as a form of authentication on the endpoint side.
  --signature-key: string # The value for the signature key - This is used to generate an HMAC-based hex digest of the request body, which we send as the X-Cloudsmith-Signature header so that you can ensure that the request wasn't modified by a malicious party (note: this is treated as a passphrase and is encrypted when we store it).
  --target-url: string # The destination URL that webhook payloads will be POST'ed to. (format: uri)
  --templates: list # item shape: {event: string, template?: string}
  --verify-ssl: string@bool-completer # If enabled, SSL certificates is verified when webhooks are sent. It's recommended to leave this enabled as not verifying the integrity of SSL certificates leaves you susceptible to Man-in-the-Middle (MITM) attacks.
]: any -> record<created_at: string, created_by: string, created_by_url: string, disable_reason: int, disable_reason_str: string, events: list<string>, identifier: int, is_active: bool, is_last_response_bad: bool, last_response_status: int, last_response_status_str: string, num_sent: int, package_query: string, request_body_format: int, request_body_format_str: string, request_body_template_format: int, request_body_template_format_str: string, request_content_type: string, secret_header: string, self_url: string, slug_perm: string, target_url: string, templates: table<event: string, template: string>, updated_at: string, updated_by: string, updated_by_url: string, verify_ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($owner)/($repo)/($identifier)/")
  let body = {events: $events, is_active: $is_active, package_query: $package_query, request_body_format: $request_body_format, request_body_template_format: $request_body_template_format, request_content_type: $request_content_type, secret_header: $secret_header, secret_value: $secret_value, signature_key: $signature_key, target_url: $target_url, templates: $templates, verify_ssl: $verify_ssl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific webhook in a repository.
#
# DELETE /webhooks/{owner}/{repo}/{identifier}/
# operationId: webhooks_delete
export def "webhooks delete" [
  owner: string
  repo: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($owner)/($repo)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
