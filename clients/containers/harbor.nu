# Auto-generated client for Harbor API v2.0
# Source: https://raw.githubusercontent.com/goharbor/harbor/main/api/v2.0/swagger.yaml
# Auth: --token flag or $env.HARBOR_API_TOKEN

const BASE_URL = "http://localhost/api/v2.0"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HARBOR_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost/api/v2.0" "https://localhost/api/v2.0"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def scan-type-completer [] { ["sbom" "vulnerability"] }
def action-completer [] { ["pause" "resume" "stop"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "health get" } } | get name | first)
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

# Check the status of Harbor components
#
# GET /health
# operationId: getHealth
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<status: string, components: table<name: string, status: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for projects and repositories
#
# GET /search
# operationId: search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search parameter for project and repository name.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<project: table<project_id: int, owner_id: int, name: string, registry_id: int, creation_time: string, update_time: string, deleted: bool, owner_name: string, togglable: bool, current_user_role_id: int, current_user_role_ids: list, repo_count: int, metadata: record, cve_allowlist: record>, repository: table<project_id: int, project_name: string, project_public: bool, repository_name: string, pull_count: int, artifact_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the statistic information about the projects and repositories
#
# GET /statistics
# operationId: getStatistic
export def "statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<private_project_count: int, private_repo_count: int, public_project_count: int, public_repo_count: int, total_project_count: int, total_repo_count: int, total_storage_consumption: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/statistics")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping available ldap service.
#
# POST /ldap/ping
# operationId: pingLdap
export def "ldap-ping pingLdap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --ldap-url: string # The url of ldap service.
  --ldap-search-dn: string # The search dn of ldap service.
  --ldap-search-password: string # The search password of ldap service.
  --ldap-base-dn: string # The base dn of ldap service.
  --ldap-filter: string # The serach filter of ldap service.
  --ldap-uid: string # The serach uid from ldap service attributes.
  --ldap-scope: int # The serach scope of ldap service. (format: int64)
  --ldap-connection-timeout: int # The connect timeout of ldap service(second). (format: int64)
  --ldap-verify-cert: oneof<nothing, bool> # Verify Ldap server certificate.
]: any -> record<success: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ldap/ping")
  let body = {ldap_url: $ldap_url, ldap_search_dn: $ldap_search_dn, ldap_search_password: $ldap_search_password, ldap_base_dn: $ldap_base_dn, ldap_filter: $ldap_filter, ldap_uid: $ldap_uid, ldap_scope: $ldap_scope, ldap_connection_timeout: $ldap_connection_timeout, ldap_verify_cert: $ldap_verify_cert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search available ldap users.
#
# GET /ldap/users/search
# operationId: searchLdapUser
export def "ldap-users-search searchLdapUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # Registered user ID
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<username: string, realname: string, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ldap/users/search" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import selected available ldap users.
#
# POST /ldap/users/import
# operationId: importLdapUser
export def "ldap-users-import importLdapUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --ldap-uid-list: list # selected uid list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ldap/users/import")
  let body = {ldap_uid_list: $ldap_uid_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search available ldap groups.
#
# GET /ldap/groups/search
# operationId: searchLdapGroup
export def "ldap-groups-search searchLdapGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupname: string # Ldap group name
  --groupdn: string # The LDAP group DN
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, group_name: string, group_type: int, ldap_group_dn: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupname" $groupname "scalar") (serialize-qp "groupdn" $groupdn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ldap/groups/search" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get internal configurations.
#
# GET /internalconfig
# operationId: getInternalconfig
export def "internalconfig get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/internalconfig")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get system configurations.
#
# GET /configurations
# operationId: getConfigurations
export def "configurations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<auth_mode: record<value: string, editable: bool>, primary_auth_mode: record<value: bool, editable: bool>, ldap_base_dn: record<value: string, editable: bool>, ldap_filter: record<value: string, editable: bool>, ldap_group_base_dn: record<value: string, editable: bool>, ldap_group_admin_dn: record<value: string, editable: bool>, ldap_group_attribute_name: record<value: string, editable: bool>, ldap_group_search_filter: record<value: string, editable: bool>, ldap_group_search_scope: record<value: int, editable: bool>, ldap_group_attach_parallel: record<value: bool, editable: bool>, ldap_scope: record<value: int, editable: bool>, ldap_search_dn: record<value: string, editable: bool>, ldap_timeout: record<value: int, editable: bool>, ldap_uid: record<value: string, editable: bool>, ldap_url: record<value: string, editable: bool>, ldap_verify_cert: record<value: bool, editable: bool>, ldap_group_membership_attribute: record<value: string, editable: bool>, project_creation_restriction: record<value: string, editable: bool>, read_only: record<value: bool, editable: bool>, self_registration: record<value: bool, editable: bool>, token_expiration: record<value: int, editable: bool>, uaa_client_id: record<value: string, editable: bool>, uaa_client_secret: record<value: string, editable: bool>, uaa_endpoint: record<value: string, editable: bool>, uaa_verify_cert: record<value: bool, editable: bool>, http_authproxy_endpoint: record<value: string, editable: bool>, http_authproxy_tokenreview_endpoint: record<value: string, editable: bool>, http_authproxy_admin_groups: record<value: string, editable: bool>, http_authproxy_admin_usernames: record<value: string, editable: bool>, http_authproxy_verify_cert: record<value: bool, editable: bool>, http_authproxy_skip_search: record<value: bool, editable: bool>, http_authproxy_server_certificate: record<value: string, editable: bool>, oidc_name: record<value: string, editable: bool>, oidc_endpoint: record<value: string, editable: bool>, oidc_client_id: record<value: string, editable: bool>, oidc_groups_claim: record<value: string, editable: bool>, oidc_admin_group: record<value: string, editable: bool>, oidc_group_filter: record<value: string, editable: bool>, oidc_scope: record<value: string, editable: bool>, oidc_user_claim: record<value: string, editable: bool>, oidc_verify_cert: record<value: bool, editable: bool>, oidc_auto_onboard: record<value: bool, editable: bool>, oidc_extra_redirect_parms: record<value: string, editable: bool>, oidc_logout: record<value: bool, editable: bool>, robot_token_duration: record<value: int, editable: bool>, robot_name_prefix: record<value: string, editable: bool>, notification_enable: record<value: bool, editable: bool>, quota_per_project_enable: record<value: bool, editable: bool>, storage_per_project: record<value: int, editable: bool>, audit_log_forward_endpoint: record<value: string, editable: bool>, skip_audit_log_database: record<value: bool, editable: bool>, scanner_skip_update_pulltime: record<value: bool, editable: bool>, scan_all_policy: record<type: string, parameter: record<daily_time: int>>, session_timeout: record<value: int, editable: bool>, banner_message: record<value: string, editable: bool>, disabled_audit_log_event_types: record<value: string, editable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configurations")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify system configurations.
#
# PUT /configurations
# operationId: updateConfigurations
export def "configurations updateConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --auth-mode: string # The auth mode of current system, such as "db_auth", "ldap_auth", "oidc_auth"
  --primary-auth-mode: oneof<nothing, bool> # The flag to indicate whether the current auth mode should consider as a primary one.
  --ldap-base-dn: string # The Base DN for LDAP binding.
  --ldap-filter: string # The filter for LDAP search
  --ldap-group-base-dn: string # The base DN to search LDAP group.
  --ldap-group-admin-dn: string # Specify the ldap group which have the same privilege with Harbor admin
  --ldap-group-attribute-name: string # The attribute which is used as identity of the LDAP group, default is cn.'
  --ldap-group-search-filter: string # The filter to search the ldap group
  --ldap-group-search-scope: int # The scope to search ldap group. ''0-LDAP_SCOPE_BASE, 1-LDAP_SCOPE_ONELEVEL, 2-LDAP_SCOPE_SUBTREE''
  --ldap-group-attach-parallel: oneof<nothing, bool> # Attach LDAP user group information in parallel, the parallel worker count is 5
  --ldap-scope: int # The scope to search ldap users,'0-LDAP_SCOPE_BASE, 1-LDAP_SCOPE_ONELEVEL, 2-LDAP_SCOPE_SUBTREE'
  --ldap-search-dn: string # The DN of the user to do the search.
  --ldap-search-password: string # The password of the ldap search dn
  --ldap-timeout: int # Timeout in seconds for connection to LDAP server
  --ldap-uid: string # The attribute which is used as identity for the LDAP binding, such as "CN" or "SAMAccountname"
  --ldap-url: string # The URL of LDAP server
  --ldap-verify-cert: oneof<nothing, bool> # Whether verify your OIDC server certificate, disable it if your OIDC server is hosted via self-hosted certificate.
  --ldap-group-membership-attribute: string # The user attribute to identify the group membership
  --project-creation-restriction: string # Indicate who can create projects, it could be ''adminonly'' or ''everyone''.
  --read-only: oneof<nothing, bool> # The flag to indicate whether Harbor is in readonly mode.
  --self-registration: oneof<nothing, bool> # Whether the Harbor instance supports self-registration.  If it''s set to false, admin need to add user to the instance.
  --token-expiration: int # The expiration time of the token for internal Registry, in minutes.
  --uaa-client-id: string # The client id of UAA
  --uaa-client-secret: string # The client secret of the UAA
  --uaa-endpoint: string # The endpoint of the UAA
  --uaa-verify-cert: oneof<nothing, bool> # Verify the certificate in UAA server
  --http-authproxy-endpoint: string # The endpoint of the HTTP auth
  --http-authproxy-tokenreview-endpoint: string # The token review endpoint
  --http-authproxy-admin-groups: string # The group which has the harbor admin privileges
  --http-authproxy-admin-usernames: string # The username which has the harbor admin privileges
  --http-authproxy-verify-cert: oneof<nothing, bool> # Verify the HTTP auth provider's certificate
  --http-authproxy-skip-search: oneof<nothing, bool> # Search user before onboard
  --http-authproxy-server-certificate: string # The certificate of the HTTP auth provider
  --oidc-name: string # The OIDC provider name
  --oidc-endpoint: string # The endpoint of the OIDC provider
  --oidc-client-id: string # The client ID of the OIDC provider
  --oidc-client-secret: string # The OIDC provider secret
  --oidc-groups-claim: string # The attribute claims the group name
  --oidc-admin-group: string # The OIDC group which has the harbor admin privileges
  --oidc-group-filter: string # The OIDC group filter which filters out the group name doesn't match the regular expression
  --oidc-scope: string # The scope of the OIDC provider
  --oidc-user-claim: string # The attribute claims the username
  --oidc-verify-cert: oneof<nothing, bool> # Verify the OIDC provider's certificate'
  --oidc-auto-onboard: oneof<nothing, bool> # Auto onboard the OIDC user
  --oidc-extra-redirect-parms: string # Extra parameters to add when redirect request to OIDC provider
  --oidc-logout: oneof<nothing, bool> # Logout OIDC user session
  --robot-token-duration: int # The robot account token duration in days
  --robot-name-prefix: string # The rebot account name prefix
  --notification-enable: oneof<nothing, bool> # Enable notification
  --quota-per-project-enable: oneof<nothing, bool> # Enable quota per project
  --storage-per-project: int # The storage quota per project
  --audit-log-forward-endpoint: string # The audit log forward endpoint
  --skip-audit-log-database: oneof<nothing, bool> # Skip audit log database
  --session-timeout: int # The session timeout for harbor, in minutes.
  --scanner-skip-update-pulltime: oneof<nothing, bool> # Whether or not to skip update pull time for scanner
  --banner-message: string # The banner message for the UI.It is the stringified result of the banner message object
  --disabled-audit-log-event-types: string # the list to disable log audit event types.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configurations")
  let body = {auth_mode: $auth_mode, primary_auth_mode: $primary_auth_mode, ldap_base_dn: $ldap_base_dn, ldap_filter: $ldap_filter, ldap_group_base_dn: $ldap_group_base_dn, ldap_group_admin_dn: $ldap_group_admin_dn, ldap_group_attribute_name: $ldap_group_attribute_name, ldap_group_search_filter: $ldap_group_search_filter, ldap_group_search_scope: $ldap_group_search_scope, ldap_group_attach_parallel: $ldap_group_attach_parallel, ldap_scope: $ldap_scope, ldap_search_dn: $ldap_search_dn, ldap_search_password: $ldap_search_password, ldap_timeout: $ldap_timeout, ldap_uid: $ldap_uid, ldap_url: $ldap_url, ldap_verify_cert: $ldap_verify_cert, ldap_group_membership_attribute: $ldap_group_membership_attribute, project_creation_restriction: $project_creation_restriction, read_only: $read_only, self_registration: $self_registration, token_expiration: $token_expiration, uaa_client_id: $uaa_client_id, uaa_client_secret: $uaa_client_secret, uaa_endpoint: $uaa_endpoint, uaa_verify_cert: $uaa_verify_cert, http_authproxy_endpoint: $http_authproxy_endpoint, http_authproxy_tokenreview_endpoint: $http_authproxy_tokenreview_endpoint, http_authproxy_admin_groups: $http_authproxy_admin_groups, http_authproxy_admin_usernames: $http_authproxy_admin_usernames, http_authproxy_verify_cert: $http_authproxy_verify_cert, http_authproxy_skip_search: $http_authproxy_skip_search, http_authproxy_server_certificate: $http_authproxy_server_certificate, oidc_name: $oidc_name, oidc_endpoint: $oidc_endpoint, oidc_client_id: $oidc_client_id, oidc_client_secret: $oidc_client_secret, oidc_groups_claim: $oidc_groups_claim, oidc_admin_group: $oidc_admin_group, oidc_group_filter: $oidc_group_filter, oidc_scope: $oidc_scope, oidc_user_claim: $oidc_user_claim, oidc_verify_cert: $oidc_verify_cert, oidc_auto_onboard: $oidc_auto_onboard, oidc_extra_redirect_parms: $oidc_extra_redirect_parms, oidc_logout: $oidc_logout, robot_token_duration: $robot_token_duration, robot_name_prefix: $robot_name_prefix, notification_enable: $notification_enable, quota_per_project_enable: $quota_per_project_enable, storage_per_project: $storage_per_project, audit_log_forward_endpoint: $audit_log_forward_endpoint, skip_audit_log_database: $skip_audit_log_database, session_timeout: $session_timeout, scanner_skip_update_pulltime: $scanner_skip_update_pulltime, banner_message: $banner_message, disabled_audit_log_event_types: $disabled_audit_log_event_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List projects
#
# GET /projects
# operationId: listProjects
export def "projects listProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --name: string # The name of project.
  --public: oneof<nothing, bool> # The project is public or private.
  --owner: string # The name of project owner.
  --with-detail: oneof<nothing, bool> # Bool value indicating whether return detailed information of the project (default: true)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<project_id: int, owner_id: int, name: string, registry_id: int, creation_time: string, update_time: string, deleted: bool, owner_name: string, togglable: bool, current_user_role_id: int, current_user_role_ids: list<int>, repo_count: int, metadata: record<public: string, enable_content_trust: string, enable_content_trust_cosign: string, prevent_vul: string, severity: string, auto_scan: string, auto_sbom_generation: string, reuse_sys_cve_allowlist: string, retention_id: string, proxy_speed_kb: string, max_upstream_conn: string, proxy_cache_local_on_not_found: string, proxy_referrer_api: string>, cve_allowlist: record<id: int, project_id: int, expires_at: int, items: list, creation_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "public" $public "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "with_detail" $with_detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the project name user provided already exists.
#
# HEAD /projects
# operationId: headProject
export def "projects headProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-name: string # Project name for checking exists.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_name" $project_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project.
#
# POST /projects
# operationId: createProject
# --metadata shape: {public?: string, enable_content_trust?: string, enable_content_trust_cosign?: string, prevent_vul?: string, severity?: string, auto_scan?: string, auto_sbom_generation?: string, reuse_sys_cve_allowlist?: string, retention_id?: string, proxy_speed_kb?: string, max_upstream_conn?: string, proxy_cache_local_on_not_found?: string, proxy_referrer_api?: string}
# --cve_allowlist shape: {id?: int, project_id?: int, expires_at?: int, items?: list, creation_time?: string, update_time?: string}
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Resource-Name-In-Location: oneof<nothing, bool> # The flag to indicate whether to return the name of the resource in Location. When X-Resource-Name-In-Location is true, the Location will return the name of the resource.
  --project-name: string # The name of the project.
  --public: oneof<nothing, bool> # deprecated, reserved for project creation in replication
  --metadata: record # shape: {public?: string, enable_content_trust?: string, enable_content_trust_cosign?: string, prevent_vul?: string, severity?: string, auto_scan?: string, auto_sbom_generation?: string, reuse_sys_cve_allowlist?: string, retention_id?: string, proxy_speed_kb?: string, max_upstream_conn?: string, proxy_cache_local_on_not_found?: string, proxy_referrer_api?: string}
  --cve-allowlist: record # The CVE Allowlist for system or project — shape: {id?: int, project_id?: int, expires_at?: int, items?: list, creation_time?: string, update_time?: string}
  --storage-limit: int # The storage quota of the project. (format: int64)
  --registry-id: int # The ID of referenced registry when creating the proxy cache project (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {project_name: $project_name, public: $public, metadata: $metadata, cve_allowlist: $cve_allowlist, storage_limit: $storage_limit, registry_id: $registry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Resource-Name-In-Location": $X_Resource_Name_In_Location} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return specific project detail information
#
# GET /projects/{project_name_or_id}
# operationId: getProject
export def "projects get" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<project_id: int, owner_id: int, name: string, registry_id: int, creation_time: string, update_time: string, deleted: bool, owner_name: string, togglable: bool, current_user_role_id: int, current_user_role_ids: list<int>, repo_count: int, metadata: record<public: string, enable_content_trust: string, enable_content_trust_cosign: string, prevent_vul: string, severity: string, auto_scan: string, auto_sbom_generation: string, reuse_sys_cve_allowlist: string, retention_id: string, proxy_speed_kb: string, max_upstream_conn: string, proxy_cache_local_on_not_found: string, proxy_referrer_api: string>, cve_allowlist: record<id: int, project_id: int, expires_at: int, items: list<record>, creation_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update properties for a selected project.
#
# PUT /projects/{project_name_or_id}
# operationId: updateProject
# --metadata shape: {public?: string, enable_content_trust?: string, enable_content_trust_cosign?: string, prevent_vul?: string, severity?: string, auto_scan?: string, auto_sbom_generation?: string, reuse_sys_cve_allowlist?: string, retention_id?: string, proxy_speed_kb?: string, max_upstream_conn?: string, proxy_cache_local_on_not_found?: string, proxy_referrer_api?: string}
# --cve_allowlist shape: {id?: int, project_id?: int, expires_at?: int, items?: list, creation_time?: string, update_time?: string}
export def "projects updateProject" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --project-name: string # The name of the project.
  --public: oneof<nothing, bool> # deprecated, reserved for project creation in replication
  --metadata: record # shape: {public?: string, enable_content_trust?: string, enable_content_trust_cosign?: string, prevent_vul?: string, severity?: string, auto_scan?: string, auto_sbom_generation?: string, reuse_sys_cve_allowlist?: string, retention_id?: string, proxy_speed_kb?: string, max_upstream_conn?: string, proxy_cache_local_on_not_found?: string, proxy_referrer_api?: string}
  --cve-allowlist: record # The CVE Allowlist for system or project — shape: {id?: int, project_id?: int, expires_at?: int, items?: list, creation_time?: string, update_time?: string}
  --storage-limit: int # The storage quota of the project. (format: int64)
  --registry-id: int # The ID of referenced registry when creating the proxy cache project (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)")
  let body = {project_name: $project_name, public: $public, metadata: $metadata, cve_allowlist: $cve_allowlist, storage_limit: $storage_limit, registry_id: $registry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project by projectID
#
# DELETE /projects/{project_name_or_id}
# operationId: deleteProject
export def "projects delete" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the deletable status of the project
#
# GET /projects/{project_name_or_id}/_deletable
# operationId: getProjectDeletable
export def "projects-deletable get" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<deletable: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/_deletable")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get summary of the project.
#
# GET /projects/{project_name_or_id}/summary
# operationId: getProjectSummary
export def "projects-summary get" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<repo_count: int, project_admin_count: int, maintainer_count: int, developer_count: int, guest_count: int, limited_guest_count: int, quota: record<hard: record, used: record>, registry: record<id: int, url: string, name: string, credential: record<type: string, access_key: string, access_secret: string>, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/summary")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all project member information
#
# GET /projects/{project_name_or_id}/members
# operationId: listProjectMembers
export def "projects-members listProjectMembers" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --entityname: string # The entity name to search.
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<id: int, project_id: int, entity_name: string, role_name: string, role_id: int, entity_id: int, entity_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "entityname" $entityname "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/members" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project member
#
# POST /projects/{project_name_or_id}/members
# operationId: createProjectMember
# --member_user shape: {user_id?: int, username?: string}
# --member_group shape: {id?: int, group_name?: string, group_type?: int, ldap_group_dn?: string}
export def "projects-members createProjectMember" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --role-id: int # The role id 1 for projectAdmin, 2 for developer, 3 for guest, 4 for maintainer
  --member-user: record # shape: {user_id?: int, username?: string}
  --member-group: record # shape: {id?: int, group_name?: string, group_type?: int, ldap_group_dn?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/members")
  let body = {role_id: $role_id, member_user: $member_user, member_group: $member_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the project member information
#
# GET /projects/{project_name_or_id}/members/{mid}
# operationId: getProjectMember
export def "projects-members get" [
  project_name_or_id: string
  mid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<id: int, project_id: int, entity_name: string, role_name: string, role_id: int, entity_id: int, entity_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/members/($mid)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project member
#
# PUT /projects/{project_name_or_id}/members/{mid}
# operationId: updateProjectMember
export def "projects-members updateProjectMember" [
  project_name_or_id: string
  mid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --role-id: int # The role id 1 for projectAdmin, 2 for developer, 3 for guest, 4 for maintainer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/members/($mid)")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project member
#
# DELETE /projects/{project_name_or_id}/members/{mid}
# operationId: deleteProjectMember
export def "projects-members delete" [
  project_name_or_id: string
  mid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/members/($mid)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the metadata of the specific project
#
# GET /projects/{project_name_or_id}/metadatas/
# operationId: listProjectMetadatas
export def "projects-metadatas listProjectMetadatas" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/metadatas/")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add metadata for the specific project
#
# POST /projects/{project_name_or_id}/metadatas/
# operationId: addProjectMetadatas
export def "projects-metadatas addProjectMetadatas" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/metadatas/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the specific metadata of the specific project
#
# GET /projects/{project_name_or_id}/metadatas/{meta_name}
# operationId: getProjectMetadata
export def "projects-metadatas get" [
  project_name_or_id: string
  meta_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/metadatas/($meta_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specific metadata for the specific project
#
# PUT /projects/{project_name_or_id}/metadatas/{meta_name}
# operationId: updateProjectMetadata
export def "projects-metadatas updateProjectMetadata" [
  project_name_or_id: string
  meta_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/metadatas/($meta_name)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the specific metadata for the specific project
#
# DELETE /projects/{project_name_or_id}/metadatas/{meta_name}
# operationId: deleteProjectMetadata
export def "projects-metadatas delete" [
  project_name_or_id: string
  meta_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/metadatas/($meta_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all authorized repositories
#
# GET /repositories
# operationId: listAllRepositories
export def "repositories listAllRepositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, project_id: int, name: string, description: string, artifact_count: int, pull_count: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repositories
#
# GET /projects/{project_name}/repositories
# operationId: listRepositories
export def "projects-repositories listRepositories" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, project_id: int, name: string, description: string, artifact_count: int, pull_count: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/repositories" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repository
#
# GET /projects/{project_name}/repositories/{repository_name}
# operationId: getRepository
export def "projects-repositories get" [
  project_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, project_id: int, name: string, description: string, artifact_count: int, pull_count: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update repository
#
# PUT /projects/{project_name}/repositories/{repository_name}
# operationId: updateRepository
export def "projects-repositories updateRepository" [
  project_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the repository (format: int64)
  --project-id: int # The ID of the project that the repository belongs to (format: int64)
  --name: string # The name of the repository
  --description: string # The description of the repository
  --artifact-count: int # The count of the artifacts inside the repository (format: int64)
  --pull-count: int # The count that the artifact inside the repository pulled (format: int64)
  --creation-time: string # The creation time of the repository (format: date-time)
  --update-time: string # The update time of the repository (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)")
  let body = {id: $id, project_id: $project_id, name: $name, description: $description, artifact_count: $artifact_count, pull_count: $pull_count, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete repository
#
# DELETE /projects/{project_name}/repositories/{repository_name}
# operationId: deleteRepository
export def "projects-repositories delete" [
  project_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List artifacts
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts
# operationId: listArtifacts
export def "projects-repositories-artifacts listArtifacts" [
  project_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --with-tag: oneof<nothing, bool> # Specify whether the tags are included inside the returning artifacts (default: true)
  --with-label: oneof<nothing, bool> # Specify whether the labels are included inside the returning artifacts (default: false)
  --with-scan-overview: oneof<nothing, bool> # Specify whether the scan overview is included inside the returning artifacts (default: false)
  --with-sbom-overview: oneof<nothing, bool> # Specify whether the SBOM overview is included in returning artifacts, when this option is true, the SBOM overview will be included in the response (default: false)
  --with-immutable-status: oneof<nothing, bool> # Specify whether the immutable status is included inside the tags of the returning artifacts. Only works when setting "with_immutable_status=true" (default: false)
  --with-accessory: oneof<nothing, bool> # Specify whether the accessories are included of the returning artifacts. Only works when setting "with_accessory=true" (default: false)
  --X-Request-Id: string # An unique ID for the request
  --X-Accept-Vulnerabilities: string # A comma-separated lists of MIME types for the scan report or scan summary. The first mime type will be used when the report found for it. Currently the mime type supports 'application/vnd.scanner.adapter.vuln.report.harbor+json; version=1.0' and 'application/vnd.security.vulnerability.report; version=1.1'
]: nothing -> table<id: int, type: string, media_type: string, manifest_media_type: string, artifact_type: string, project_id: int, repository_id: int, repository_name: string, digest: string, size: int, icon: string, push_time: string, pull_time: string, extra_attrs: record, annotations: record, references: list<record>, tags: list<record>, addition_links: record, labels: list<record>, scan_overview: record, sbom_overview: record<start_time: string, end_time: string, scan_status: string, sbom_digest: string, report_id: string, duration: int, scanner: record>, accessories: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "with_tag" $with_tag "scalar") (serialize-qp "with_label" $with_label "scalar") (serialize-qp "with_scan_overview" $with_scan_overview "scalar") (serialize-qp "with_sbom_overview" $with_sbom_overview "scalar") (serialize-qp "with_immutable_status" $with_immutable_status "scalar") (serialize-qp "with_accessory" $with_accessory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Accept-Vulnerabilities": $X_Accept_Vulnerabilities} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy artifact
#
# POST /projects/{project_name}/repositories/{repository_name}/artifacts
# operationId: CopyArtifact
export def "projects-repositories-artifacts CopyArtifact" [
  project_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # The artifact from which the new artifact is copied from, the format should be "project/repository:tag" or "project/repository@digest".
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the specific artifact
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}
# operationId: getArtifact
export def "projects-repositories-artifacts get" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --with-tag: oneof<nothing, bool> # Specify whether the tags are inclued inside the returning artifacts (default: true)
  --with-label: oneof<nothing, bool> # Specify whether the labels are inclued inside the returning artifacts (default: false)
  --with-scan-overview: oneof<nothing, bool> # Specify whether the scan overview is inclued inside the returning artifacts (default: false)
  --with-sbom-overview: oneof<nothing, bool> # Specify whether the SBOM overview is included in returning artifact, when this option is true, the SBOM overview will be included in the response (default: false)
  --with-accessory: oneof<nothing, bool> # Specify whether the accessories are included of the returning artifacts. (default: false)
  --with-signature: oneof<nothing, bool> # Specify whether the signature is inclued inside the returning artifacts (default: false)
  --with-immutable-status: oneof<nothing, bool> # Specify whether the immutable status is inclued inside the tags of the returning artifacts. (default: false)
  --X-Request-Id: string # An unique ID for the request
  --X-Accept-Vulnerabilities: string # A comma-separated lists of MIME types for the scan report or scan summary. The first mime type will be used when the report found for it. Currently the mime type supports 'application/vnd.scanner.adapter.vuln.report.harbor+json; version=1.0' and 'application/vnd.security.vulnerability.report; version=1.1'
]: nothing -> record<id: int, type: string, media_type: string, manifest_media_type: string, artifact_type: string, project_id: int, repository_id: int, repository_name: string, digest: string, size: int, icon: string, push_time: string, pull_time: string, extra_attrs: record, annotations: record, references: table<parent_id: int, child_id: int, child_digest: string, platform: record, annotations: record, urls: list>, tags: table<id: int, repository_id: int, artifact_id: int, name: string, push_time: string, pull_time: string, immutable: bool>, addition_links: record, labels: table<id: int, name: string, description: string, color: string, scope: string, project_id: int, creation_time: string, update_time: string>, scan_overview: record, sbom_overview: record<start_time: string, end_time: string, scan_status: string, sbom_digest: string, report_id: string, duration: int, scanner: record<name: string, vendor: string, version: string>>, accessories: table<id: int, artifact_id: int, subject_artifact_id: int, subject_artifact_digest: string, subject_artifact_repo: string, size: int, digest: string, type: string, icon: string, creation_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "with_tag" $with_tag "scalar") (serialize-qp "with_label" $with_label "scalar") (serialize-qp "with_scan_overview" $with_scan_overview "scalar") (serialize-qp "with_sbom_overview" $with_sbom_overview "scalar") (serialize-qp "with_accessory" $with_accessory "scalar") (serialize-qp "with_signature" $with_signature "scalar") (serialize-qp "with_immutable_status" $with_immutable_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Accept-Vulnerabilities": $X_Accept_Vulnerabilities} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specific artifact
#
# DELETE /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}
# operationId: deleteArtifact
export def "projects-repositories-artifacts delete" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Scan the artifact
#
# POST /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/scan
# operationId: scanArtifact
export def "projects-repositories-artifacts-scan scanArtifact" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --scan-type: string@scan-type-completer # The scan type for the scan request. Two options are currently supported, vulnerability and sbom
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/scan")
  let body = {scan_type: $scan_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancelling a scan job for a particular artifact
#
# POST /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/scan/stop
# operationId: stopScanArtifact
export def "projects-repositories-artifacts-scan-stop stopScanArtifact" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --scan-type: string@scan-type-completer # The scan type for the scan request. Two options are currently supported, vulnerability and sbom
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/scan/stop")
  let body = {scan_type: $scan_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the log of the scan report
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/scan/{report_id}/log
# operationId: getReportLog
export def "projects-repositories-artifacts-scan-log get" [
  project_name: string
  repository_name: string
  reference: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/scan/($report_id)/log")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tag
#
# POST /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/tags
# operationId: createTag
export def "projects-repositories-artifacts-tags createTag" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  name: string # The name of the tag
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/tags")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tags
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/tags
# operationId: listTags
export def "projects-repositories-artifacts-tags listTags" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --with-immutable-status: oneof<nothing, bool> # Specify whether the immutable status is included inside the returning tags (default: false)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, repository_id: int, artifact_id: int, name: string, push_time: string, pull_time: string, immutable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "with_immutable_status" $with_immutable_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/tags" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete tag
#
# DELETE /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/tags/{tag_name}
# operationId: deleteTag
export def "projects-repositories-artifacts-tags delete" [
  project_name: string
  repository_name: string
  reference: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/tags/($tag_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List accessories
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/accessories
# operationId: listAccessories
export def "projects-repositories-artifacts-accessories listAccessories" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, artifact_id: int, subject_artifact_id: int, subject_artifact_digest: string, subject_artifact_repo: string, size: int, digest: string, type: string, icon: string, creation_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/accessories" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the vulnerabilities addition of the specific artifact
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/additions/vulnerabilities
# operationId: getVulnerabilitiesAddition
export def "projects-repositories-artifacts-additions-vulnerabilities get" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Accept-Vulnerabilities: string # A comma-separated lists of MIME types for the scan report or scan summary. The first mime type will be used when the report found for it. Currently the mime type supports 'application/vnd.scanner.adapter.vuln.report.harbor+json; version=1.0' and 'application/vnd.security.vulnerability.report; version=1.1'
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/additions/vulnerabilities")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Accept-Vulnerabilities": $X_Accept_Vulnerabilities} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the addition of the specific artifact
#
# GET /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/additions/{addition}
# operationId: getAddition
export def "projects-repositories-artifacts-additions get" [
  project_name: string
  repository_name: string
  reference: string
  addition: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/additions/($addition)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add label to artifact
#
# POST /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/labels
# operationId: addLabel
export def "projects-repositories-artifacts-labels addLabel" [
  project_name: string
  repository_name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the label (format: int64)
  --name: string # The name the label
  --description: string # The description the label
  --color: string # The color the label
  --scope: string # The scope the label
  --project-id: int # The ID of project that the label belongs to (format: int64)
  --creation-time: string # The creation time the label (format: date-time)
  --update-time: string # The update time of the label (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/labels")
  let body = {id: $id, name: $name, description: $description, color: $color, scope: $scope, project_id: $project_id, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove label from artifact
#
# DELETE /projects/{project_name}/repositories/{repository_name}/artifacts/{reference}/labels/{label_id}
# operationId: removeLabel
export def "projects-repositories-artifacts-labels removeLabel" [
  project_name: string
  repository_name: string
  reference: string
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/repositories/($repository_name)/artifacts/($reference)/labels/($label_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List artifacts
#
# GET /projects/{project_name_or_id}/artifacts
# operationId: listArtifactsOfProject
export def "projects-artifacts listArtifactsOfProject" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --with-tag: oneof<nothing, bool> # Specify whether the tags are included inside the returning artifacts (default: true)
  --with-label: oneof<nothing, bool> # Specify whether the labels are included inside the returning artifacts (default: false)
  --with-scan-overview: oneof<nothing, bool> # Specify whether the scan overview is included inside the returning artifacts (default: false)
  --with-sbom-overview: oneof<nothing, bool> # Specify whether the SBOM overview is included in returning artifacts, when this option is true, the SBOM overview will be included in the response (default: false)
  --with-immutable-status: oneof<nothing, bool> # Specify whether the immutable status is included inside the tags of the returning artifacts. Only works when setting "with_immutable_status=true" (default: false)
  --with-accessory: oneof<nothing, bool> # Specify whether the accessories are included of the returning artifacts. Only works when setting "with_accessory=true" (default: false)
  --latest-in-repository: oneof<nothing, bool> # Specify whether only the latest pushed artifact of each repository is included inside the returning artifacts. Only works when either artifact_type or media_type is included in the query. (default: false)
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --X-Accept-Vulnerabilities: string # A comma-separated lists of MIME types for the scan report or scan summary. The first mime type will be used when the report found for it. Currently the mime type supports 'application/vnd.scanner.adapter.vuln.report.harbor+json; version=1.0' and 'application/vnd.security.vulnerability.report; version=1.1'
]: nothing -> table<id: int, type: string, media_type: string, manifest_media_type: string, artifact_type: string, project_id: int, repository_id: int, repository_name: string, digest: string, size: int, icon: string, push_time: string, pull_time: string, extra_attrs: record, annotations: record, references: list<record>, tags: list<record>, addition_links: record, labels: list<record>, scan_overview: record, sbom_overview: record<start_time: string, end_time: string, scan_status: string, sbom_digest: string, report_id: string, duration: int, scanner: record>, accessories: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "with_tag" $with_tag "scalar") (serialize-qp "with_label" $with_label "scalar") (serialize-qp "with_scan_overview" $with_scan_overview "scalar") (serialize-qp "with_sbom_overview" $with_sbom_overview "scalar") (serialize-qp "with_immutable_status" $with_immutable_status "scalar") (serialize-qp "with_accessory" $with_accessory "scalar") (serialize-qp "latest_in_repository" $latest_in_repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/artifacts" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name, "X-Accept-Vulnerabilities": $X_Accept_Vulnerabilities} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project level scanner
#
# GET /projects/{project_name_or_id}/scanner
# operationId: getScannerOfProject
export def "projects-scanner get" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<uuid: string, name: string, description: string, url: string, disabled: bool, is_default: bool, auth: string, access_credential: string, skip_certVerify: bool, use_internal_addr: bool, create_time: string, update_time: string, adapter: string, vendor: string, version: string, health: string, capabilities: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/scanner")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Configure scanner for the specified project
#
# PUT /projects/{project_name_or_id}/scanner
# operationId: setScannerOfProject
export def "projects-scanner setScannerOfProject" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  uuid: string # The identifier of the scanner registration
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/scanner")
  let body = {uuid: $uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get scanner registration candidates for configurating project level scanner
#
# GET /projects/{project_name_or_id}/scanner/candidates
# operationId: listScannerCandidatesOfProject
export def "projects-scanner-candidates listScannerCandidatesOfProject" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<uuid: string, name: string, description: string, url: string, disabled: bool, is_default: bool, auth: string, access_credential: string, skip_certVerify: bool, use_internal_addr: bool, create_time: string, update_time: string, adapter: string, vendor: string, version: string, health: string, capabilities: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/scanner/candidates" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recent logs of projects which the user is a member with project admin role, or return all audit logs for system admin user (deprecated)
#
# GET /audit-logs
# operationId: listAuditLogs
export def "audit-logs listAuditLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, username: string, resource: string, resource_type: string, operation: string, op_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audit-logs" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recent logs of the projects which the user is a member with project_admin role, or return all audit logs for system admin user
#
# GET /auditlog-exts
# operationId: listAuditLogExts
export def "auditlog-exts listAuditLogExts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, username: string, resource: string, resource_type: string, operation: string, operation_description: string, operation_result: bool, op_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auditlog-exts" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all event types of audit log
#
# GET /auditlog-exts/events
# operationId: listAuditLogEventTypes
export def "auditlog-exts-events listAuditLogEventTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<event_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auditlog-exts/events")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recent logs of the projects (deprecated)
#
# GET /projects/{project_name}/logs
# operationId: getLogs
export def "projects-logs get" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, username: string, resource: string, resource_type: string, operation: string, op_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/logs" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recent logs of the projects
#
# GET /projects/{project_name}/auditlog-exts
# operationId: getLogExts
export def "projects-auditlog-exts get" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, username: string, resource: string, resource_type: string, operation: string, operation_description: string, operation_result: bool, op_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/auditlog-exts" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List P2P providers
#
# GET /p2p/preheat/providers
# operationId: ListProviders
export def "p2p-preheat-providers ListProviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: string, name: string, icon: string, maintainers: list<string>, version: string, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/p2p/preheat/providers")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping status of a instance.
#
# POST /p2p/preheat/instances/ping
# operationId: PingInstances
export def "p2p-preheat-instances-ping PingInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # Unique ID
  --name: string # Instance name
  --description: string # Description of instance
  --vendor: string # Based on which driver, identified by ID
  --endpoint: string # The service endpoint of this instance
  --auth-mode: string # The authentication way supported
  --auth-info: record # The auth credential data if it exists.  When updating an instance (PUT `/p2p/preheat/instances/{preheat_instance_name}`), if this object is omitted or empty and `auth_mode` is not `NONE`, the previously stored credentials are kept.
  --status: string # The health status
  --enabled: oneof<nothing, bool> # Whether the instance is activated or not
  --default: oneof<nothing, bool> # Whether the instance is default or not
  --body-insecure: oneof<nothing, bool> # Whether the instance endpoint is insecure or not
  --setup-timestamp: int # The timestamp of instance setting up (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/p2p/preheat/instances/ping")
  let body = {id: $id, name: $name, description: $description, vendor: $vendor, endpoint: $endpoint, auth_mode: $auth_mode, auth_info: $auth_info, status: $status, enabled: $enabled, default: $default, insecure: $body_insecure, setup_timestamp: $setup_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List P2P provider instances
#
# GET /p2p/preheat/instances
# operationId: ListInstances
export def "p2p-preheat-instances ListInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, name: string, description: string, vendor: string, endpoint: string, auth_mode: string, auth_info: record, status: string, enabled: bool, default: bool, insecure: bool, setup_timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/p2p/preheat/instances" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create p2p provider instances
#
# POST /p2p/preheat/instances
# operationId: CreateInstance
export def "p2p-preheat-instances CreateInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # Unique ID
  --name: string # Instance name
  --description: string # Description of instance
  --vendor: string # Based on which driver, identified by ID
  --endpoint: string # The service endpoint of this instance
  --auth-mode: string # The authentication way supported
  --auth-info: record # The auth credential data if it exists.  When updating an instance (PUT `/p2p/preheat/instances/{preheat_instance_name}`), if this object is omitted or empty and `auth_mode` is not `NONE`, the previously stored credentials are kept.
  --status: string # The health status
  --enabled: oneof<nothing, bool> # Whether the instance is activated or not
  --default: oneof<nothing, bool> # Whether the instance is default or not
  --body-insecure: oneof<nothing, bool> # Whether the instance endpoint is insecure or not
  --setup-timestamp: int # The timestamp of instance setting up (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/p2p/preheat/instances")
  let body = {id: $id, name: $name, description: $description, vendor: $vendor, endpoint: $endpoint, auth_mode: $auth_mode, auth_info: $auth_info, status: $status, enabled: $enabled, default: $default, insecure: $body_insecure, setup_timestamp: $setup_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a P2P provider instance
#
# GET /p2p/preheat/instances/{preheat_instance_name}
# operationId: GetInstance
export def "p2p-preheat-instances GetInstance" [
  preheat_instance_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, name: string, description: string, vendor: string, endpoint: string, auth_mode: string, auth_info: record, status: string, enabled: bool, default: bool, insecure: bool, setup_timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/p2p/preheat/instances/($preheat_instance_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specified P2P provider instance
#
# DELETE /p2p/preheat/instances/{preheat_instance_name}
# operationId: DeleteInstance
export def "p2p-preheat-instances DeleteInstance" [
  preheat_instance_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/p2p/preheat/instances/($preheat_instance_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specified P2P provider instance
#
# PUT /p2p/preheat/instances/{preheat_instance_name}
# operationId: UpdateInstance
export def "p2p-preheat-instances UpdateInstance" [
  preheat_instance_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # Unique ID
  --name: string # Instance name
  --description: string # Description of instance
  --vendor: string # Based on which driver, identified by ID
  --endpoint: string # The service endpoint of this instance
  --auth-mode: string # The authentication way supported
  --auth-info: record # The auth credential data if it exists.  When updating an instance (PUT `/p2p/preheat/instances/{preheat_instance_name}`), if this object is omitted or empty and `auth_mode` is not `NONE`, the previously stored credentials are kept.
  --status: string # The health status
  --enabled: oneof<nothing, bool> # Whether the instance is activated or not
  --default: oneof<nothing, bool> # Whether the instance is default or not
  --body-insecure: oneof<nothing, bool> # Whether the instance endpoint is insecure or not
  --setup-timestamp: int # The timestamp of instance setting up (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/p2p/preheat/instances/($preheat_instance_name)")
  let body = {id: $id, name: $name, description: $description, vendor: $vendor, endpoint: $endpoint, auth_mode: $auth_mode, auth_info: $auth_info, status: $status, enabled: $enabled, default: $default, insecure: $body_insecure, setup_timestamp: $setup_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a preheat policy under a project
#
# POST /projects/{project_name}/preheat/policies
# operationId: CreatePolicy
export def "projects-preheat-policies CreatePolicy" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of preheat policy
  --name: string # The Name of preheat policy
  --description: string # The Description of preheat policy
  --project-id: int # The ID of preheat policy project
  --provider-id: int # The ID of preheat policy provider
  --provider-name: string # The Name of preheat policy provider
  --filters: string # The Filters of preheat policy
  --trigger: string # The Trigger of preheat policy
  --enabled: oneof<nothing, bool> # Whether the preheat policy enabled
  --extra-attrs: string # The extra attributes of preheat policy
  --creation-time: string # The Create Time of preheat policy (format: date-time)
  --update-time: string # The Update Time of preheat policy (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies")
  let body = {id: $id, name: $name, description: $description, project_id: $project_id, provider_id: $provider_id, provider_name: $provider_name, filters: $filters, trigger: $trigger, enabled: $enabled, extra_attrs: $extra_attrs, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List preheat policies
#
# GET /projects/{project_name}/preheat/policies
# operationId: ListPolicies
export def "projects-preheat-policies ListPolicies" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, name: string, description: string, project_id: int, provider_id: int, provider_name: string, filters: string, trigger: string, enabled: bool, extra_attrs: string, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a preheat policy
#
# GET /projects/{project_name}/preheat/policies/{preheat_policy_name}
# operationId: GetPolicy
export def "projects-preheat-policies GetPolicy" [
  project_name: string
  preheat_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, name: string, description: string, project_id: int, provider_id: int, provider_name: string, filters: string, trigger: string, enabled: bool, extra_attrs: string, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update preheat policy
#
# PUT /projects/{project_name}/preheat/policies/{preheat_policy_name}
# operationId: UpdatePolicy
export def "projects-preheat-policies UpdatePolicy" [
  project_name: string
  preheat_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of preheat policy
  --name: string # The Name of preheat policy
  --description: string # The Description of preheat policy
  --project-id: int # The ID of preheat policy project
  --provider-id: int # The ID of preheat policy provider
  --provider-name: string # The Name of preheat policy provider
  --filters: string # The Filters of preheat policy
  --trigger: string # The Trigger of preheat policy
  --enabled: oneof<nothing, bool> # Whether the preheat policy enabled
  --extra-attrs: string # The extra attributes of preheat policy
  --creation-time: string # The Create Time of preheat policy (format: date-time)
  --update-time: string # The Update Time of preheat policy (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)")
  let body = {id: $id, name: $name, description: $description, project_id: $project_id, provider_id: $provider_id, provider_name: $provider_name, filters: $filters, trigger: $trigger, enabled: $enabled, extra_attrs: $extra_attrs, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manual preheat
#
# POST /projects/{project_name}/preheat/policies/{preheat_policy_name}
# operationId: ManualPreheat
export def "projects-preheat-policies ManualPreheat" [
  project_name: string
  preheat_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of preheat policy
  --name: string # The Name of preheat policy
  --description: string # The Description of preheat policy
  --project-id: int # The ID of preheat policy project
  --provider-id: int # The ID of preheat policy provider
  --provider-name: string # The Name of preheat policy provider
  --filters: string # The Filters of preheat policy
  --trigger: string # The Trigger of preheat policy
  --enabled: oneof<nothing, bool> # Whether the preheat policy enabled
  --extra-attrs: string # The extra attributes of preheat policy
  --creation-time: string # The Create Time of preheat policy (format: date-time)
  --update-time: string # The Update Time of preheat policy (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)")
  let body = {id: $id, name: $name, description: $description, project_id: $project_id, provider_id: $provider_id, provider_name: $provider_name, filters: $filters, trigger: $trigger, enabled: $enabled, extra_attrs: $extra_attrs, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a preheat policy
#
# DELETE /projects/{project_name}/preheat/policies/{preheat_policy_name}
# operationId: DeletePolicy
export def "projects-preheat-policies DeletePolicy" [
  project_name: string
  preheat_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List executions for the given policy
#
# GET /projects/{project_name}/preheat/policies/{preheat_policy_name}/executions
# operationId: ListExecutions
export def "projects-preheat-policies-executions ListExecutions" [
  project_name: string
  preheat_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, vendor_type: string, vendor_id: int, status: string, status_message: string, metrics: record<task_count: int, success_task_count: int, error_task_count: int, pending_task_count: int, running_task_count: int, scheduled_task_count: int, stopped_task_count: int>, trigger: string, extra_attrs: record, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)/executions" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a execution detail by id
#
# GET /projects/{project_name}/preheat/policies/{preheat_policy_name}/executions/{execution_id}
# operationId: GetExecution
export def "projects-preheat-policies-executions GetExecution" [
  project_name: string
  preheat_policy_name: string
  execution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, vendor_type: string, vendor_id: int, status: string, status_message: string, metrics: record<task_count: int, success_task_count: int, error_task_count: int, pending_task_count: int, running_task_count: int, scheduled_task_count: int, stopped_task_count: int>, trigger: string, extra_attrs: record, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)/executions/($execution_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a execution
#
# PATCH /projects/{project_name}/preheat/policies/{preheat_policy_name}/executions/{execution_id}
# operationId: StopExecution
# --metrics shape: {task_count?: int, success_task_count?: int, error_task_count?: int, pending_task_count?: int, running_task_count?: int, scheduled_task_count?: int, stopped_task_count?: int}
export def "projects-preheat-policies-executions StopExecution" [
  project_name: string
  preheat_policy_name: string
  execution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of execution
  --vendor-type: string # The vendor type of execution
  --vendor-id: int # The vendor id of execution
  --status: string # The status of execution
  --status-message: string # The status message of execution
  --metrics: record # shape: {task_count?: int, success_task_count?: int, error_task_count?: int, pending_task_count?: int, running_task_count?: int, scheduled_task_count?: int, stopped_task_count?: int}
  --trigger: string # The trigger of execution
  --extra-attrs: record
  --start-time: string # The start time of execution
  --end-time: string # The end time of execution
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)/executions/($execution_id)")
  let body = {id: $id, vendor_type: $vendor_type, vendor_id: $vendor_id, status: $status, status_message: $status_message, metrics: $metrics, trigger: $trigger, extra_attrs: $extra_attrs, start_time: $start_time, end_time: $end_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all the related tasks for the given execution
#
# GET /projects/{project_name}/preheat/policies/{preheat_policy_name}/executions/{execution_id}/tasks
# operationId: ListTasks
export def "projects-preheat-policies-executions-tasks ListTasks" [
  project_name: string
  preheat_policy_name: string
  execution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, execution_id: int, status: string, status_message: string, run_count: int, extra_attrs: record, creation_time: string, update_time: string, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)/executions/($execution_id)/tasks" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the log text stream of the specified task for the given execution
#
# GET /projects/{project_name}/preheat/policies/{preheat_policy_name}/executions/{execution_id}/tasks/{task_id}/logs
# operationId: GetPreheatLog
export def "projects-preheat-policies-executions-tasks-logs GetPreheatLog" [
  project_name: string
  preheat_policy_name: string
  execution_id: int
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/policies/($preheat_policy_name)/executions/($execution_id)/tasks/($task_id)/logs")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all providers at project level
#
# GET /projects/{project_name}/preheat/providers
# operationId: ListProvidersUnderProject
export def "projects-preheat-providers ListProvidersUnderProject" [
  project_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, provider: string, enabled: bool, default: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name)/preheat/providers")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all immutable tag rules of current project
#
# GET /projects/{project_name_or_id}/immutabletagrules
# operationId: ListImmuRules
export def "projects-immutabletagrules ListImmuRules" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<id: int, priority: int, disabled: bool, action: string, template: string, params: record, tag_selectors: list<record>, scope_selectors: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/immutabletagrules" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an immutable tag rule to current project
#
# POST /projects/{project_name_or_id}/immutabletagrules
# operationId: CreateImmuRule
# --tag_selectors item shape: {kind?: string, decoration?: string, pattern?: string, extras?: string}
export def "projects-immutabletagrules CreateImmuRule" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --id: int
  --priority: int
  --disabled: oneof<nothing, bool>
  --action: string
  --template: string
  --params: record
  --tag-selectors: list # item shape: {kind?: string, decoration?: string, pattern?: string, extras?: string}
  --scope-selectors: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/immutabletagrules")
  let body = {id: $id, priority: $priority, disabled: $disabled, action: $action, template: $template, params: $params, tag_selectors: $tag_selectors, scope_selectors: $scope_selectors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the immutable tag rule or enable or disable the rule
#
# PUT /projects/{project_name_or_id}/immutabletagrules/{immutable_rule_id}
# operationId: UpdateImmuRule
# --tag_selectors item shape: {kind?: string, decoration?: string, pattern?: string, extras?: string}
export def "projects-immutabletagrules UpdateImmuRule" [
  project_name_or_id: string
  immutable_rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --id: int
  --priority: int
  --disabled: oneof<nothing, bool>
  --action: string
  --template: string
  --params: record
  --tag-selectors: list # item shape: {kind?: string, decoration?: string, pattern?: string, extras?: string}
  --scope-selectors: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/immutabletagrules/($immutable_rule_id)")
  let body = {id: $id, priority: $priority, disabled: $disabled, action: $action, template: $template, params: $params, tag_selectors: $tag_selectors, scope_selectors: $scope_selectors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the immutable tag rule.
#
# DELETE /projects/{project_name_or_id}/immutabletagrules/{immutable_rule_id}
# operationId: DeleteImmuRule
export def "projects-immutabletagrules DeleteImmuRule" [
  project_name_or_id: string
  immutable_rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/immutabletagrules/($immutable_rule_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List project webhook policies.
#
# GET /projects/{project_name_or_id}/webhook/policies
# operationId: ListWebhookPoliciesOfProject
export def "projects-webhook-policies ListWebhookPoliciesOfProject" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<id: int, name: string, description: string, project_id: int, targets: list<record>, event_types: list<string>, creator: string, creation_time: string, update_time: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project webhook policy.
#
# POST /projects/{project_name_or_id}/webhook/policies
# operationId: CreateWebhookPolicyOfProject
# --targets item shape: {type?: string, address?: string, auth_header?: string, skip_cert_verify?: bool, payload_format?: string}
export def "projects-webhook-policies CreateWebhookPolicyOfProject" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --id: int # The webhook policy ID. (format: int64)
  --name: string # The name of webhook policy.
  --description: string # The description of webhook policy.
  --project-id: int # The project ID of webhook policy.
  --targets: list # item shape: {type?: string, address?: string, auth_header?: string, skip_cert_verify?: bool, payload_format?: string}
  --event-types: list
  --creator: string # The creator of the webhook policy.
  --creation-time: string # The create time of the webhook policy. (format: date-time)
  --update-time: string # The update time of the webhook policy. (format: date-time)
  --enabled: oneof<nothing, bool> # Whether the webhook policy is enabled or not.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies")
  let body = {id: $id, name: $name, description: $description, project_id: $project_id, targets: $targets, event_types: $event_types, creator: $creator, creation_time: $creation_time, update_time: $update_time, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get project webhook policy
#
# GET /projects/{project_name_or_id}/webhook/policies/{webhook_policy_id}
# operationId: GetWebhookPolicyOfProject
export def "projects-webhook-policies GetWebhookPolicyOfProject" [
  project_name_or_id: string
  webhook_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<id: int, name: string, description: string, project_id: int, targets: table<type: string, address: string, auth_header: string, skip_cert_verify: bool, payload_format: string>, event_types: list<string>, creator: string, creation_time: string, update_time: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies/($webhook_policy_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update webhook policy of a project.
#
# PUT /projects/{project_name_or_id}/webhook/policies/{webhook_policy_id}
# operationId: UpdateWebhookPolicyOfProject
# --targets item shape: {type?: string, address?: string, auth_header?: string, skip_cert_verify?: bool, payload_format?: string}
export def "projects-webhook-policies UpdateWebhookPolicyOfProject" [
  project_name_or_id: string
  webhook_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
  --id: int # The webhook policy ID. (format: int64)
  --name: string # The name of webhook policy.
  --description: string # The description of webhook policy.
  --project-id: int # The project ID of webhook policy.
  --targets: list # item shape: {type?: string, address?: string, auth_header?: string, skip_cert_verify?: bool, payload_format?: string}
  --event-types: list
  --creator: string # The creator of the webhook policy.
  --creation-time: string # The create time of the webhook policy. (format: date-time)
  --update-time: string # The update time of the webhook policy. (format: date-time)
  --enabled: oneof<nothing, bool> # Whether the webhook policy is enabled or not.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies/($webhook_policy_id)")
  let body = {id: $id, name: $name, description: $description, project_id: $project_id, targets: $targets, event_types: $event_types, creator: $creator, creation_time: $creation_time, update_time: $update_time, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete webhook policy of a project
#
# DELETE /projects/{project_name_or_id}/webhook/policies/{webhook_policy_id}
# operationId: DeleteWebhookPolicyOfProject
export def "projects-webhook-policies DeleteWebhookPolicyOfProject" [
  project_name_or_id: string
  webhook_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies/($webhook_policy_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List executions for a specific webhook policy
#
# GET /projects/{project_name_or_id}/webhook/policies/{webhook_policy_id}/executions
# operationId: ListExecutionsOfWebhookPolicy
export def "projects-webhook-policies-executions ListExecutionsOfWebhookPolicy" [
  project_name_or_id: string
  webhook_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<id: int, vendor_type: string, vendor_id: int, status: string, status_message: string, metrics: record<task_count: int, success_task_count: int, error_task_count: int, pending_task_count: int, running_task_count: int, scheduled_task_count: int, stopped_task_count: int>, trigger: string, extra_attrs: record, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies/($webhook_policy_id)/executions" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tasks for a specific webhook execution
#
# GET /projects/{project_name_or_id}/webhook/policies/{webhook_policy_id}/executions/{execution_id}/tasks
# operationId: ListTasksOfWebhookExecution
export def "projects-webhook-policies-executions-tasks ListTasksOfWebhookExecution" [
  project_name_or_id: string
  webhook_policy_id: int
  execution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<id: int, execution_id: int, status: string, status_message: string, run_count: int, extra_attrs: record, creation_time: string, update_time: string, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies/($webhook_policy_id)/executions/($execution_id)/tasks" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get logs for a specific webhook task
#
# GET /projects/{project_name_or_id}/webhook/policies/{webhook_policy_id}/executions/{execution_id}/tasks/{task_id}/log
# operationId: GetLogsOfWebhookTask
export def "projects-webhook-policies-executions-tasks-log GetLogsOfWebhookTask" [
  project_name_or_id: string
  webhook_policy_id: int
  execution_id: int
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/policies/($webhook_policy_id)/executions/($execution_id)/tasks/($task_id)/log")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get project webhook policy last trigger info
#
# GET /projects/{project_name_or_id}/webhook/lasttrigger
# DEPRECATED
# operationId: LastTrigger
@deprecated
export def "projects-webhook-lasttrigger LastTrigger" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<policy_name: string, event_type: string, enabled: bool, creation_time: string, last_trigger_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/lasttrigger")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List project webhook jobs
#
# GET /projects/{project_name_or_id}/webhook/jobs
# DEPRECATED
# operationId: ListWebhookJobs
@deprecated
export def "projects-webhook-jobs ListWebhookJobs" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --policy-id: int # The policy ID. (format: int64)
  --status: list # The status of webhook job.
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> table<id: int, policy_id: int, event_type: string, notify_type: string, status: string, job_detail: string, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "status" $status "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/jobs" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get supported event types and notify types.
#
# GET /projects/{project_name_or_id}/webhook/events
# operationId: GetSupportedEventTypes
export def "projects-webhook-events GetSupportedEventTypes" [
  project_name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Is-Resource-Name: oneof<nothing, bool> # The flag to indicate whether the parameter which supports both name and id in the path is the name of the resource. When the X-Is-Resource-Name is false and the parameter can be converted to an integer, the parameter will be as an id, otherwise, it will be as a name.
]: nothing -> record<event_type: list<string>, notify_type: list<string>, payload_formats: table<notify_type: string, formats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_name_or_id)/webhook/events")
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Is-Resource-Name": $X_Is_Resource_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all user groups information
#
# GET /usergroups
# operationId: listUserGroups
export def "usergroups listUserGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --ldap-group-dn: string # search with ldap group DN
  --group-name: string # group name need to search, fuzzy matches
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, group_name: string, group_type: int, ldap_group_dn: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "ldap_group_dn" $ldap_group_dn "scalar") (serialize-qp "group_name" $group_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usergroups" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user group
#
# POST /usergroups
# operationId: createUserGroup
export def "usergroups createUserGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the user group
  --group-name: string # The name of the user group
  --group-type: int # The group type, 1 for LDAP group, 2 for HTTP group, 3 for OIDC group.
  --ldap-group-dn: string # The DN of the LDAP group if group type is 1 (LDAP group).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usergroups")
  let body = {id: $id, group_name: $group_name, group_type: $group_type, ldap_group_dn: $ldap_group_dn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search groups by groupname
#
# GET /usergroups/search
# operationId: searchUserGroups
export def "usergroups-search searchUserGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --groupname: string # Group name for filtering results.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, group_name: string, group_type: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "groupname" $groupname "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usergroups/search" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user group information
#
# GET /usergroups/{group_id}
# operationId: getUserGroup
export def "usergroups get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, group_name: string, group_type: int, ldap_group_dn: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usergroups/($group_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update group information
#
# PUT /usergroups/{group_id}
# operationId: updateUserGroup
export def "usergroups updateUserGroup" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the user group
  --group-name: string # The name of the user group
  --group-type: int # The group type, 1 for LDAP group, 2 for HTTP group, 3 for OIDC group.
  --ldap-group-dn: string # The DN of the LDAP group if group type is 1 (LDAP group).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usergroups/($group_id)")
  let body = {id: $id, group_name: $group_name, group_type: $group_type, ldap_group_dn: $ldap_group_dn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete user group
#
# DELETE /usergroups/{group_id}
# operationId: deleteUserGroup
export def "usergroups delete" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/usergroups/($group_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get artifact icon
#
# GET /icons/{digest}
# operationId: getIcon
export def "icons get" [
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<content_type: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/icons/($digest)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get robot account
#
# GET /robots
# operationId: ListRobot
export def "robots ListRobot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, name: string, description: string, secret: string, level: string, duration: int, editable: bool, disable: bool, expires_at: int, permissions: list<record>, creator_type: string, creator_ref: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/robots" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a robot account
#
# POST /robots
# operationId: CreateRobot
# --permissions item shape: {kind?: string, namespace?: string, access?: list}
export def "robots CreateRobot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --name: string # The name of the robot
  --description: string # The description of the robot
  --secret: string # The secret of the robot
  --level: string # The level of the robot, project or system
  --disable: oneof<nothing, bool> # The disable status of the robot
  --duration: int # The duration of the robot in days, duration must be either -1(Never) or a positive integer (format: int64)
  --permissions: list # item shape: {kind?: string, namespace?: string, access?: list}
]: any -> record<id: int, name: string, secret: string, creation_time: string, expires_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/robots")
  let body = {name: $name, description: $description, secret: $secret, level: $level, disable: $disable, duration: $duration, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List quotas
#
# GET /quotas
# operationId: listQuotas
export def "quotas listQuotas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --reference: string # The reference type of quota.
  --reference-id: string # The reference id of quota.
  --qp-sort: string # Sort method, valid values include: 'hard.resource_name', '-hard.resource_name', 'used.resource_name', '-used.resource_name'. Here '-' stands for descending order, resource_name should be the real resource name of the quota.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, ref: record, hard: record, used: record, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "reference_id" $reference_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quotas" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the specified quota
#
# GET /quotas/{id}
# operationId: getQuota
export def "quotas get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, ref: record, hard: record, used: record, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotas/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the specified quota
#
# PUT /quotas/{id}
# operationId: updateQuota
export def "quotas updateQuota" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --hard: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotas/($id)")
  let body = {hard: $hard} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a robot account
#
# GET /robots/{robot_id}
# operationId: GetRobotByID
export def "robots GetRobotByID" [
  robot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, name: string, description: string, secret: string, level: string, duration: int, editable: bool, disable: bool, expires_at: int, permissions: table<kind: string, namespace: string, access: list>, creator_type: string, creator_ref: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/robots/($robot_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a robot account
#
# PUT /robots/{robot_id}
# operationId: UpdateRobot
# --permissions item shape: {kind?: string, namespace?: string, access?: list}
export def "robots UpdateRobot" [
  robot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the robot (format: int64)
  --name: string # The name of the robot
  --description: string # The description of the robot
  --secret: string # The secret of the robot
  --level: string # The level of the robot, project or system
  --duration: int # The duration of the robot in days, duration must be either -1(Never) or a positive integer (format: int64)
  --editable: oneof<nothing, bool> # The editable status of the robot
  --disable: oneof<nothing, bool> # The disable status of the robot
  --expires-at: int # The expiration date of the robot (format: int64)
  --permissions: list # item shape: {kind?: string, namespace?: string, access?: list}
  --creator-type: string # The type of the robot creator, like local(harbor_user) or robot.
  --creator-ref: int # The reference of the robot creator, like the id of harbor user.
  --creation-time: string # The creation time of the robot. (format: date-time)
  --update-time: string # The update time of the robot. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/robots/($robot_id)")
  let body = {id: $id, name: $name, description: $description, secret: $secret, level: $level, duration: $duration, editable: $editable, disable: $disable, expires_at: $expires_at, permissions: $permissions, creator_type: $creator_type, creator_ref: $creator_ref, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh the robot secret
#
# PATCH /robots/{robot_id}
# operationId: RefreshSec
export def "robots RefreshSec" [
  robot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --secret: string # The secret of the robot
]: any -> record<secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/robots/($robot_id)")
  let body = {secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a robot account
#
# DELETE /robots/{robot_id}
# operationId: DeleteRobot
export def "robots DeleteRobot" [
  robot_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/robots/($robot_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List replication policies
#
# GET /replication/policies
# operationId: listReplicationPolicies
export def "replication-policies listReplicationPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --name: string # Deprecated, use "query" instead. The policy name.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, name: string, description: string, src_registry: record<id: int, url: string, name: string, credential: record, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string>, dest_registry: record<id: int, url: string, name: string, credential: record, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string>, dest_namespace: string, dest_namespace_replace_count: int, trigger: record<type: string, trigger_settings: record>, filters: list<record>, replicate_deletion: bool, deletion: bool, override: bool, enabled: bool, creation_time: string, update_time: string, speed: int, copy_by_chunk: bool, single_active_replication: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/replication/policies" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a replication policy
#
# POST /replication/policies
# operationId: createReplicationPolicy
# --src_registry shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
# --dest_registry shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
# --trigger shape: {type?: string, trigger_settings?: record}
# --filters item shape: {type?: string, value?: any, decoration?: string}
export def "replication-policies createReplicationPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The policy ID. (format: int64)
  --name: string # The policy name.
  --description: string # The description of the policy.
  --src-registry: record # shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
  --dest-registry: record # shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
  --dest-namespace: string # The destination namespace.
  --dest-namespace-replace-count: int # Specify how many path components will be replaced by the provided destination namespace. The default value is -1 in which case the legacy mode will be applied. (format: int8)
  --trigger: record # shape: {type?: string, trigger_settings?: record}
  --filters: list # The replication policy filter array. — item shape: {type?: string, value?: any, decoration?: string}
  --replicate-deletion: oneof<nothing, bool> # Whether to replicate the deletion operation.
  --deletion: oneof<nothing, bool> # Deprecated, use "replicate_deletion" instead. Whether to replicate the deletion operation.
  --override: oneof<nothing, bool> # Whether to override the resources on the destination registry.
  --enabled: oneof<nothing, bool> # Whether the policy is enabled or not.
  --creation-time: string # The create time of the policy. (format: date-time)
  --update-time: string # The update time of the policy. (format: date-time)
  --speed: int # speed limit for each task (format: int32)
  --copy-by-chunk: oneof<nothing, bool> # Whether to enable copy by chunk.
  --single-active-replication: oneof<nothing, bool> # Whether to skip execution until the previous active execution finishes, avoiding the execution of the same replication rules multiple times in parallel.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/policies")
  let body = {id: $id, name: $name, description: $description, src_registry: $src_registry, dest_registry: $dest_registry, dest_namespace: $dest_namespace, dest_namespace_replace_count: $dest_namespace_replace_count, trigger: $trigger, filters: $filters, replicate_deletion: $replicate_deletion, deletion: $deletion, override: $override, enabled: $enabled, creation_time: $creation_time, update_time: $update_time, speed: $speed, copy_by_chunk: $copy_by_chunk, single_active_replication: $single_active_replication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the specific replication policy
#
# GET /replication/policies/{id}
# operationId: getReplicationPolicy
export def "replication-policies get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, name: string, description: string, src_registry: record<id: int, url: string, name: string, credential: record<type: string, access_key: string, access_secret: string>, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string>, dest_registry: record<id: int, url: string, name: string, credential: record<type: string, access_key: string, access_secret: string>, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string>, dest_namespace: string, dest_namespace_replace_count: int, trigger: record<type: string, trigger_settings: record<cron: string>>, filters: table<type: string, value: any, decoration: string>, replicate_deletion: bool, deletion: bool, override: bool, enabled: bool, creation_time: string, update_time: string, speed: int, copy_by_chunk: bool, single_active_replication: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/replication/policies/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specific replication policy
#
# DELETE /replication/policies/{id}
# operationId: deleteReplicationPolicy
export def "replication-policies delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/replication/policies/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the replication policy
#
# PUT /replication/policies/{id}
# operationId: updateReplicationPolicy
# --src_registry shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
# --dest_registry shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
# --trigger shape: {type?: string, trigger_settings?: record}
# --filters item shape: {type?: string, value?: any, decoration?: string}
export def "replication-policies updateReplicationPolicy" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --body-id: int # The policy ID. (format: int64)
  --name: string # The policy name.
  --description: string # The description of the policy.
  --src-registry: record # shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
  --dest-registry: record # shape: {id?: int, url?: string, name?: string, credential?: record, type?: string, insecure?: bool, ca_certificate?: string, description?: string, status?: string, creation_time?: string, update_time?: string}
  --dest-namespace: string # The destination namespace.
  --dest-namespace-replace-count: int # Specify how many path components will be replaced by the provided destination namespace. The default value is -1 in which case the legacy mode will be applied. (format: int8)
  --trigger: record # shape: {type?: string, trigger_settings?: record}
  --filters: list # The replication policy filter array. — item shape: {type?: string, value?: any, decoration?: string}
  --replicate-deletion: oneof<nothing, bool> # Whether to replicate the deletion operation.
  --deletion: oneof<nothing, bool> # Deprecated, use "replicate_deletion" instead. Whether to replicate the deletion operation.
  --override: oneof<nothing, bool> # Whether to override the resources on the destination registry.
  --enabled: oneof<nothing, bool> # Whether the policy is enabled or not.
  --creation-time: string # The create time of the policy. (format: date-time)
  --update-time: string # The update time of the policy. (format: date-time)
  --speed: int # speed limit for each task (format: int32)
  --copy-by-chunk: oneof<nothing, bool> # Whether to enable copy by chunk.
  --single-active-replication: oneof<nothing, bool> # Whether to skip execution until the previous active execution finishes, avoiding the execution of the same replication rules multiple times in parallel.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/replication/policies/($id)")
  let body = {id: $body_id, name: $name, description: $description, src_registry: $src_registry, dest_registry: $dest_registry, dest_namespace: $dest_namespace, dest_namespace_replace_count: $dest_namespace_replace_count, trigger: $trigger, filters: $filters, replicate_deletion: $replicate_deletion, deletion: $deletion, override: $override, enabled: $enabled, creation_time: $creation_time, update_time: $update_time, speed: $speed, copy_by_chunk: $copy_by_chunk, single_active_replication: $single_active_replication} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List replication executions
#
# GET /replication/executions
# operationId: listReplicationExecutions
export def "replication-executions listReplicationExecutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --policy-id: int # The ID of the policy that the executions belong to.
  --status: string # The execution status.
  --trigger: string # The trigger mode.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, policy_id: int, status: string, trigger: string, start_time: string, end_time: string, status_text: string, total: int, failed: int, succeed: int, in_progress: int, stopped: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "policy_id" $policy_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "trigger" $trigger "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/replication/executions" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start one replication execution
#
# POST /replication/executions
# operationId: startReplication
export def "replication-executions startReplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --policy-id: int # The ID of policy that the execution belongs to. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/executions")
  let body = {policy_id: $policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the specific replication execution
#
# GET /replication/executions/{id}
# operationId: getReplicationExecution
export def "replication-executions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, policy_id: int, status: string, trigger: string, start_time: string, end_time: string, status_text: string, total: int, failed: int, succeed: int, in_progress: int, stopped: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/replication/executions/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop the specific replication execution
#
# PUT /replication/executions/{id}
# operationId: stopReplication
export def "replication-executions stopReplication" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/replication/executions/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List replication tasks for a specific execution
#
# GET /replication/executions/{id}/tasks
# operationId: listReplicationTasks
export def "replication-executions-tasks listReplicationTasks" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --status: string # The task status.
  --resource-type: string # The resource type.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, execution_id: int, status: string, job_id: string, operation: string, resource_type: string, src_resource: string, dst_resource: string, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/replication/executions/($id)/tasks" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the log of the specific replication task
#
# GET /replication/executions/{id}/tasks/{task_id}/log
# operationId: getReplicationLog
export def "replication-executions-tasks-log get" [
  id: int
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/replication/executions/($id)/tasks/($task_id)/log")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List registry adapters
#
# GET /replication/adapters
# operationId: listRegistryProviderTypes
export def "replication-adapters listRegistryProviderTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/adapters")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all registered registry provider information
#
# GET /replication/adapterinfos
# operationId: listRegistryProviderInfos
export def "replication-adapterinfos listRegistryProviderInfos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/adapterinfos")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a registry
#
# POST /registries
# operationId: createRegistry
# --credential shape: {type?: string, access_key?: string, access_secret?: string}
export def "registries createRegistry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The registry ID. (format: int64)
  --body-url: string # The registry URL string.
  --name: string # The registry name.
  --credential: record # shape: {type?: string, access_key?: string, access_secret?: string}
  --type: string # Type of the registry, e.g. 'harbor'.
  --body-insecure: oneof<nothing, bool> # Whether or not the certificate will be verified when Harbor tries to access the server.
  --ca-certificate: string # The PEM-encoded CA certificate for this registry endpoint. If provided, this CA will be used to verify the registry's certificate instead of the system CA pool.
  --description: string # Description of the registry.
  --status: string # Health status of the registry.
  --creation-time: string # The create time of the policy. (format: date-time)
  --update-time: string # The update time of the policy. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registries")
  let body = {id: $id, url: $body_url, name: $name, credential: $credential, type: $type, insecure: $body_insecure, ca_certificate: $ca_certificate, description: $description, status: $status, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the registries
#
# GET /registries
# operationId: listRegistries
export def "registries listRegistries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --name: string # Deprecated, use `q` instead.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, url: string, name: string, credential: record<type: string, access_key: string, access_secret: string>, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registries" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check status of a registry
#
# POST /registries/ping
# operationId: pingRegistry
export def "registries-ping pingRegistry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The registry ID. (format: int64)
  --type: string # Type of the registry, e.g. 'harbor'.
  --body-url: string # The registry URL.
  --credential-type: string # Credential type of the registry, e.g. 'basic'.
  --access-key: string # The registry access key.
  --access-secret: string # The registry access secret.
  --body-insecure: oneof<nothing, bool> # Whether or not the certificate will be verified when Harbor tries to access the server.
  --ca-certificate: string # The PEM-encoded CA certificate for this registry endpoint.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registries/ping")
  let body = {id: $id, type: $type, url: $body_url, credential_type: $credential_type, access_key: $access_key, access_secret: $access_secret, insecure: $body_insecure, ca_certificate: $ca_certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the specific registry
#
# GET /registries/{id}
# operationId: getRegistry
export def "registries get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, url: string, name: string, credential: record<type: string, access_key: string, access_secret: string>, type: string, insecure: bool, ca_certificate: string, description: string, status: string, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the specific registry
#
# DELETE /registries/{id}
# operationId: deleteRegistry
export def "registries delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the registry
#
# PUT /registries/{id}
# operationId: updateRegistry
export def "registries updateRegistry" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --name: string # The registry name.
  --description: string # Description of the registry.
  --body-url: string # The registry URL.
  --credential-type: string # Credential type of the registry, e.g. 'basic'.
  --access-key: string # The registry access key.
  --access-secret: string # The registry access secret.
  --body-insecure: oneof<nothing, bool> # Whether or not the certificate will be verified when Harbor tries to access the server.
  --ca-certificate: string # The PEM-encoded CA certificate for this registry endpoint.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)")
  let body = {name: $name, description: $description, url: $body_url, credential_type: $credential_type, access_key: $access_key, access_secret: $access_secret, insecure: $body_insecure, ca_certificate: $ca_certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the registry info
#
# GET /registries/{id}/info
# operationId: getRegistryInfo
export def "registries-info get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<type: string, description: string, supported_resource_filters: table<type: string, style: string, values: list>, supported_triggers: list<string>, supported_copy_by_chunk: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registries/($id)/info")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the metrics of the latest scan all process
#
# GET /scans/all/metrics
# operationId: getLatestScanAllMetrics
export def "scans-all-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<total: int, completed: int, metrics: record, ongoing: bool, trigger: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scans/all/metrics")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the metrics of the latest scheduled scan all process
#
# GET /scans/schedule/metrics
# DEPRECATED
# operationId: getLatestScheduledScanAllMetrics
@deprecated
export def "scans-schedule-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<total: int, completed: int, metrics: record, ongoing: bool, trigger: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scans/schedule/metrics")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get general system info
#
# GET /systeminfo
# operationId: getSystemInfo
export def "systeminfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<banner_message: string, current_time: string, registry_url: string, external_url: string, auth_mode: string, primary_auth_mode: bool, project_creation_restriction: string, self_registration: bool, has_ca_root: bool, harbor_version: string, registry_storage_provider_name: string, read_only: bool, notification_enable: bool, authproxy_settings: record<endpoint: string, tokenreivew_endpoint: string, skip_search: bool, verify_cert: bool, server_certificate: string>, oidc_provider_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/systeminfo")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get system volume info (total/free size).
#
# GET /systeminfo/volumes
# operationId: getVolumes
export def "systeminfo-volumes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<storage: table<total: int, free: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/systeminfo/volumes")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default root certificate.
#
# GET /systeminfo/getcert
# operationId: getCert
export def "systeminfo-getcert get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/systeminfo/getcert")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test the OIDC endpoint.
#
# POST /system/oidc/ping
# operationId: pingOIDC
export def "system-oidc-ping pingOIDC" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --body-url: string # The URL of OIDC endpoint to be tested.
  --verify-cert: oneof<nothing, bool> # Whether the certificate should be verified
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/oidc/ping")
  let body = {url: $body_url, verify_cert: $verify_cert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get gc results.
#
# GET /system/gc
# operationId: getGCHistory
export def "system-gc list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, job_name: string, job_kind: string, job_parameters: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, job_status: string, deleted: bool, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/gc" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get gc status.
#
# GET /system/gc/{gc_id}
# operationId: getGC
export def "system-gc get" [
  gc_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, job_name: string, job_kind: string, job_parameters: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, job_status: string, deleted: bool, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/gc/($gc_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop the specific GC execution
#
# PUT /system/gc/{gc_id}
# operationId: stopGC
export def "system-gc stopGC" [
  gc_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/gc/($gc_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get gc job log.
#
# GET /system/gc/{gc_id}/log
# operationId: getGCLog
export def "system-gc-log get" [
  gc_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/gc/($gc_id)/log")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get gc's schedule.
#
# GET /system/gc/schedule
# operationId: getGCSchedule
export def "system-gc-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, job_name: string, job_kind: string, job_parameters: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, job_status: string, deleted: bool, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/gc/schedule")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a gc schedule.
#
# POST /system/gc/schedule
# operationId: createGCSchedule
# --schedule shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
export def "system-gc-schedule createGCSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --schedule: record # shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
  --parameters: record # The parameters of schedule job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/gc/schedule")
  let body = {schedule: $schedule, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update gc's schedule.
#
# PUT /system/gc/schedule
# operationId: updateGCSchedule
# --schedule shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
export def "system-gc-schedule updateGCSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --schedule: record # shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
  --parameters: record # The parameters of schedule job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/gc/schedule")
  let body = {schedule: $schedule, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get purge job results.
#
# GET /system/purgeaudit
# operationId: getPurgeHistory
export def "system-purgeaudit list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, job_name: string, job_kind: string, job_parameters: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, job_status: string, deleted: bool, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/purgeaudit" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get purge job status.
#
# GET /system/purgeaudit/{purge_id}
# operationId: getPurgeJob
export def "system-purgeaudit get" [
  purge_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, job_name: string, job_kind: string, job_parameters: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, job_status: string, deleted: bool, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/purgeaudit/($purge_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop the specific purge audit log execution
#
# PUT /system/purgeaudit/{purge_id}
# operationId: stopPurge
export def "system-purgeaudit stopPurge" [
  purge_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/purgeaudit/($purge_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get purge job log.
#
# GET /system/purgeaudit/{purge_id}/log
# operationId: getPurgeJobLog
export def "system-purgeaudit-log get" [
  purge_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/purgeaudit/($purge_id)/log")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get purge's schedule.
#
# GET /system/purgeaudit/schedule
# operationId: getPurgeSchedule
export def "system-purgeaudit-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, job_name: string, job_kind: string, job_parameters: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, job_status: string, deleted: bool, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/purgeaudit/schedule")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a purge job schedule.
#
# POST /system/purgeaudit/schedule
# operationId: createPurgeSchedule
# --schedule shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
export def "system-purgeaudit-schedule createPurgeSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --schedule: record # shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
  --parameters: record # The parameters of schedule job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/purgeaudit/schedule")
  let body = {schedule: $schedule, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update purge job's schedule.
#
# PUT /system/purgeaudit/schedule
# operationId: updatePurgeSchedule
# --schedule shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
export def "system-purgeaudit-schedule updatePurgeSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --schedule: record # shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
  --parameters: record # The parameters of schedule job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/purgeaudit/schedule")
  let body = {schedule: $schedule, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the system level allowlist of CVE.
#
# GET /system/CVEAllowlist
# operationId: getSystemCVEAllowlist
export def "system-cve-allowlist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, project_id: int, expires_at: int, items: table<cve_id: string>, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/CVEAllowlist")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the system level allowlist of CVE.
#
# PUT /system/CVEAllowlist
# operationId: putSystemCVEAllowlist
# --items item shape: {cve_id?: string}
export def "system-cve-allowlist put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # ID of the allowlist
  --project-id: int # ID of the project which the allowlist belongs to.  For system level allowlist this attribute is zero.
  --expires-at: int # the time for expiration of the allowlist, in the form of seconds since epoch.  This is an optional attribute, if it's not set the CVE allowlist does not expire.
  --items: list # item shape: {cve_id?: string}
  --creation-time: string # The creation time of the allowlist. (format: date-time)
  --update-time: string # The update time of the allowlist. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/CVEAllowlist")
  let body = {id: $id, project_id: $project_id, expires_at: $expires_at, items: $items, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get scan all's schedule.
#
# GET /system/scanAll/schedule
# operationId: getScanAllSchedule
export def "system-scan-all-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, status: string, creation_time: string, update_time: string, schedule: record<type: string, cron: string, next_scheduled_time: string>, parameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/scanAll/schedule")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update scan all's schedule.
#
# PUT /system/scanAll/schedule
# operationId: updateScanAllSchedule
# --schedule shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
export def "system-scan-all-schedule updateScanAllSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --schedule: record # shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
  --parameters: record # The parameters of schedule job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/scanAll/schedule")
  let body = {schedule: $schedule, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a schedule or a manual trigger for the scan all job.
#
# POST /system/scanAll/schedule
# operationId: createScanAllSchedule
# --schedule shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
export def "system-scan-all-schedule createScanAllSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --schedule: record # shape: {type?: "Hourly"|"Daily"|"Weekly"|"Custom"|"Manual"|"None"|"Schedule", cron?: string, next_scheduled_time?: string}
  --parameters: record # The parameters of schedule job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/scanAll/schedule")
  let body = {schedule: $schedule, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop scanAll job execution
#
# POST /system/scanAll/stop
# operationId: stopScanAll
export def "system-scan-all-stop stopScanAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/scanAll/stop")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get worker pools
#
# GET /jobservice/pools
# operationId: getWorkerPools
export def "jobservice-pools get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<pid: int, worker_pool_id: string, start_at: string, heartbeat_at: string, concurrency: int, host: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobservice/pools")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workers
#
# GET /jobservice/pools/{pool_id}/workers
# operationId: getWorkers
export def "jobservice-pools-workers get" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: string, pool_id: string, job_name: string, job_id: string, start_at: string, check_in: string, checkin_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobservice/pools/($pool_id)/workers")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop running job
#
# PUT /jobservice/jobs/{job_id}
# operationId: stopRunningJob
export def "jobservice-jobs stopRunningJob" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobservice/jobs/($job_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get job log by job id
#
# GET /jobservice/jobs/{job_id}/log
# operationId: actionGetJobLog
export def "jobservice-jobs-log actionGetJobLog" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobservice/jobs/($job_id)/log")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list job queues
#
# GET /jobservice/queues
# operationId: listJobQueues
export def "jobservice-queues listJobQueues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<job_type: string, count: int, latency: int, paused: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobservice/queues")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# stop and clean, pause, resume pending jobs in the queue
#
# PUT /jobservice/queues/{job_type}
# operationId: actionPendingJobs
export def "jobservice-queues actionPendingJobs" [
  job_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --action: string@action-completer # The action of the request, should be stop, pause or resume
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobservice/queues/($job_type)")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List schedules
#
# GET /schedules
# operationId: listSchedules
export def "schedules listSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, vendor_type: string, vendor_id: int, cron: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scheduler paused status
#
# GET /schedules/{job_type}/paused
# operationId: getSchedulePaused
export def "schedules-paused get" [
  job_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<paused: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedules/($job_type)/paused")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping Harbor to check if the API server is alive.
#
# GET /ping
# operationId: getPing
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Retention Metadatas
#
# GET /retentions/metadatas
# operationId: getRentenitionMetadata
export def "retentions-metadatas get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<templates: table<rule_template: string, display_text: string, action: string, params: list>, scope_selectors: table<display_text: string, kind: string, decorations: list>, tag_selectors: table<display_text: string, kind: string, decorations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retentions/metadatas")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Retention Policy
#
# POST /retentions
# operationId: createRetention
# --rules item shape: {id?: int, priority?: int, disabled?: bool, action?: string, template?: string, params?: record, tag_selectors?: list, scope_selectors?: record}
# --trigger shape: {kind?: string, settings?: record, references?: record}
# --scope shape: {level?: string, ref?: int}
export def "retentions createRetention" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # format: int64
  --algorithm: string
  --rules: list # item shape: {id?: int, priority?: int, disabled?: bool, action?: string, template?: string, params?: record, tag_selectors?: list, scope_selectors?: record}
  --trigger: record # shape: {kind?: string, settings?: record, references?: record}
  --scope: record # shape: {level?: string, ref?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retentions")
  let body = {id: $id, algorithm: $algorithm, rules: $rules, trigger: $trigger, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Retention Policy
#
# GET /retentions/{id}
# operationId: getRetention
export def "retentions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, algorithm: string, rules: table<id: int, priority: int, disabled: bool, action: string, template: string, params: record, tag_selectors: list, scope_selectors: record>, trigger: record<kind: string, settings: record, references: record>, scope: record<level: string, ref: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retentions/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Retention Policy
#
# PUT /retentions/{id}
# operationId: updateRetention
# --rules item shape: {id?: int, priority?: int, disabled?: bool, action?: string, template?: string, params?: record, tag_selectors?: list, scope_selectors?: record}
# --trigger shape: {kind?: string, settings?: record, references?: record}
# --scope shape: {level?: string, ref?: int}
export def "retentions updateRetention" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --body-id: int # format: int64
  --algorithm: string
  --rules: list # item shape: {id?: int, priority?: int, disabled?: bool, action?: string, template?: string, params?: record, tag_selectors?: list, scope_selectors?: record}
  --trigger: record # shape: {kind?: string, settings?: record, references?: record}
  --scope: record # shape: {level?: string, ref?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retentions/($id)")
  let body = {id: $body_id, algorithm: $algorithm, rules: $rules, trigger: $trigger, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Retention Policy
#
# DELETE /retentions/{id}
# operationId: deleteRetention
export def "retentions delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retentions/($id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a Retention Execution
#
# POST /retentions/{id}/executions
# operationId: triggerRetentionExecution
export def "retentions-executions triggerRetentionExecution" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --dry-run: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retentions/($id)/executions")
  let body = {dry_run: $dry_run} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Retention executions
#
# GET /retentions/{id}/executions
# operationId: listRetentionExecutions
export def "retentions-executions listRetentionExecutions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number. (format: int64)
  --page-size: int # The size of per page. (format: int64)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, policy_id: int, start_time: string, end_time: string, status: string, trigger: string, dry_run: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retentions/($id)/executions" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a Retention execution
#
# PATCH /retentions/{id}/executions/{eid}
# operationId: operateRetentionExecution
export def "retentions-executions operateRetentionExecution" [
  id: int
  eid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --action: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retentions/($id)/executions/($eid)")
  let body = {action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Retention tasks
#
# GET /retentions/{id}/executions/{eid}/tasks
# operationId: listRetentionTasks
export def "retentions-executions-tasks listRetentionTasks" [
  id: int
  eid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number. (format: int64)
  --page-size: int # The size of per page. (format: int64)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, execution_id: int, repository: string, job_id: string, status: string, status_code: int, status_revision: int, start_time: string, end_time: string, total: int, retained: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retentions/($id)/executions/($eid)/tasks" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Retention job task log
#
# GET /retentions/{id}/executions/{eid}/tasks/{tid}
# operationId: getRetentionTaskLog
export def "retentions-executions-tasks get" [
  id: int
  eid: int
  tid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retentions/($id)/executions/($eid)/tasks/($tid)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List scanner registrations
#
# GET /scanners
# operationId: listScanners
export def "scanners listScanners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<uuid: string, name: string, description: string, url: string, disabled: bool, is_default: bool, auth: string, access_credential: string, skip_certVerify: bool, use_internal_addr: bool, create_time: string, update_time: string, adapter: string, vendor: string, version: string, health: string, capabilities: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scanners" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a scanner registration
#
# POST /scanners
# operationId: createScanner
export def "scanners createScanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  name: string # The name of this registration (e.g. Trivy)
  --description: string # An optional description of this registration. (e.g. A free-to-use tool that scans container images for package vulnerabilities. )
  --body-url: string # A base URL of the scanner adapter. (format: uri, e.g. http://harbor-scanner-trivy:8080)
  --body-auth: string # Specify what authentication approach is adopted for the HTTP communications. Supported types Basic", "Bearer" and api key header "X-ScannerAdapter-API-Key"  (e.g. Bearer)
  --access-credential: string # An optional value of the HTTP Authorization header sent with each request to the Scanner Adapter API.  When updating a registration (PUT `/scanners/{registration_id}`), if this field is omitted or empty and `auth` is still one of Basic, Bearer, or APIKey, the previously stored credential is kept unchanged. Provide a non-empty value to set or rotate the credential. Clearing `auth` removes the need for a credential; in that case an empty `access_credential` does not restore the old secret.  (e.g. Bearer: JWTTOKENGOESHERE)
  --skip-certVerify: oneof<nothing, bool> # Indicate if skip the certificate verification when sending HTTP requests (default: false)
  --use-internal-addr: oneof<nothing, bool> # Indicate whether use internal registry addr for the scanner to pull content or not (default: false)
  --disabled: oneof<nothing, bool> # Indicate whether the registration is enabled or not (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scanners")
  let body = {name: $name, description: $description, url: $body_url, auth: $body_auth, access_credential: $access_credential, skip_certVerify: $skip_certVerify, use_internal_addr: $use_internal_addr, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tests scanner registration settings
#
# POST /scanners/ping
# operationId: pingScanner
export def "scanners-ping pingScanner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  name: string # The name of this registration (e.g. Trivy)
  --body-url: string # A base URL of the scanner adapter. (format: uri, e.g. http://harbor-scanner-trivy:8080)
  --body-auth: string # Specify what authentication approach is adopted for the HTTP communications. Supported types Basic", "Bearer" and api key header "X-ScannerAdapter-API-Key"  (default: )
  --access-credential: string # An optional value of the HTTP Authorization header sent with each request to the Scanner Adapter API.  (e.g. Bearer: JWTTOKENGOESHERE)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scanners/ping")
  let body = {name: $name, url: $body_url, auth: $body_auth, access_credential: $access_credential} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a scanner registration details
#
# GET /scanners/{registration_id}
# operationId: getScanner
export def "scanners get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<uuid: string, name: string, description: string, url: string, disabled: bool, is_default: bool, auth: string, access_credential: string, skip_certVerify: bool, use_internal_addr: bool, create_time: string, update_time: string, adapter: string, vendor: string, version: string, health: string, capabilities: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scanners/($registration_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a scanner registration
#
# PUT /scanners/{registration_id}
# operationId: updateScanner
export def "scanners updateScanner" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  name: string # The name of this registration (e.g. Trivy)
  --description: string # An optional description of this registration. (e.g. A free-to-use tool that scans container images for package vulnerabilities. )
  --body-url: string # A base URL of the scanner adapter. (format: uri, e.g. http://harbor-scanner-trivy:8080)
  --body-auth: string # Specify what authentication approach is adopted for the HTTP communications. Supported types Basic", "Bearer" and api key header "X-ScannerAdapter-API-Key"  (e.g. Bearer)
  --access-credential: string # An optional value of the HTTP Authorization header sent with each request to the Scanner Adapter API.  When updating a registration (PUT `/scanners/{registration_id}`), if this field is omitted or empty and `auth` is still one of Basic, Bearer, or APIKey, the previously stored credential is kept unchanged. Provide a non-empty value to set or rotate the credential. Clearing `auth` removes the need for a credential; in that case an empty `access_credential` does not restore the old secret.  (e.g. Bearer: JWTTOKENGOESHERE)
  --skip-certVerify: oneof<nothing, bool> # Indicate if skip the certificate verification when sending HTTP requests (default: false)
  --use-internal-addr: oneof<nothing, bool> # Indicate whether use internal registry addr for the scanner to pull content or not (default: false)
  --disabled: oneof<nothing, bool> # Indicate whether the registration is enabled or not (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scanners/($registration_id)")
  let body = {name: $name, description: $description, url: $body_url, auth: $body_auth, access_credential: $access_credential, skip_certVerify: $skip_certVerify, use_internal_addr: $use_internal_addr, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a scanner registration
#
# DELETE /scanners/{registration_id}
# operationId: deleteScanner
export def "scanners delete" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<uuid: string, name: string, description: string, url: string, disabled: bool, is_default: bool, auth: string, access_credential: string, skip_certVerify: bool, use_internal_addr: bool, create_time: string, update_time: string, adapter: string, vendor: string, version: string, health: string, capabilities: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scanners/($registration_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set system default scanner registration
#
# PATCH /scanners/{registration_id}
# operationId: setScannerAsDefault
export def "scanners setScannerAsDefault" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --is-default: oneof<nothing, bool> # A flag indicating whether a scanner registration is default.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scanners/($registration_id)")
  let body = {is_default: $is_default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the metadata of the specified scanner registration
#
# GET /scanners/{registration_id}/metadata
# operationId: getScannerMetadata
export def "scanners-metadata get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<scanner: record<name: string, vendor: string, version: string>, capabilities: table<type: string, consumes_mime_types: list, produces_mime_types: list>, properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scanners/($registration_id)/metadata")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<email: string, realname: string, comment: string, user_id: int, username: string, sysadmin_flag: bool, admin_role_in_auth: bool, oidc_user_meta: record<id: int, user_id: int, subiss: string, secret: string, creation_time: string, update_time: string>, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a local user.
#
# POST /users
# operationId: createUser
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --email: string
  --realname: string
  --comment: string
  --password: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {email: $email, realname: $realname, comment: $comment, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get current user info.
#
# GET /users/current
# operationId: getCurrentUserInfo
export def "users-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<email: string, realname: string, comment: string, user_id: int, username: string, sysadmin_flag: bool, admin_role_in_auth: bool, oidc_user_meta: record<id: int, user_id: int, subiss: string, secret: string, creation_time: string, update_time: string>, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/current")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search users by username
#
# GET /users/search
# operationId: searchUsers
export def "users-search searchUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --username: string # Username for filtering results.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<user_id: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's profile.
#
# GET /users/{user_id}
# operationId: getUser
export def "users get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<email: string, realname: string, comment: string, user_id: int, username: string, sysadmin_flag: bool, admin_role_in_auth: bool, oidc_user_meta: record<id: int, user_id: int, subiss: string, secret: string, creation_time: string, update_time: string>, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user's profile.
#
# PUT /users/{user_id}
# operationId: updateUserProfile
export def "users updateUserProfile" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --email: string
  --realname: string
  --comment: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let body = {email: $email, realname: $realname, comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark a registered user as be removed.
#
# DELETE /users/{user_id}
# operationId: deleteUser
export def "users delete" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a registered user to change to be an administrator of Harbor.
#
# PUT /users/{user_id}/sysadmin
# operationId: setUserSysAdmin
export def "users-sysadmin setUserSysAdmin" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --sysadmin-flag: oneof<nothing, bool> # true-admin, false-not admin.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/sysadmin")
  let body = {sysadmin_flag: $sysadmin_flag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change the password on a user that already exists.
#
# PUT /users/{user_id}/password
# operationId: updateUserPassword
export def "users-password updateUserPassword" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --old-password: string # The user's existing password.
  --new-password: string # New password for marking as to be updated.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/password")
  let body = {old_password: $old_password, new_password: $new_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get current user permissions.
#
# GET /users/current/permissions
# operationId: getCurrentUserPermissions
export def "users-current-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # The scope for the permission
  --relative: oneof<nothing, bool> # If true, the resources in the response are relative to the scope, eg for resource '/project/1/repository' if relative is 'true' then the resource in response will be 'repository'.
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<resource: string, action: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "relative" $relative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/current/permissions" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set CLI secret for a user.
#
# PUT /users/{user_id}/cli_secret
# operationId: setCliSecret
export def "users-cli-secret setCliSecret" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --secret: string # The new secret
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/cli_secret")
  let body = {secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List labels according to the query strings.
#
# GET /labels
# operationId: ListLabels
export def "labels ListLabels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --qp-sort: string # Sort the resource list in ascending or descending order. e.g. sort by field1 in ascending order and field2 in descending order with "sort=field1,-field2"
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --name: string # The label name.
  --scope: string # The label scope. Valid values are g and p. g for global labels and p for project labels.
  --project-id: int # Relevant project ID, required when scope is p. (format: int64)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<id: int, name: string, description: string, color: string, scope: string, project_id: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/labels" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post creates a label
#
# POST /labels
# operationId: CreateLabel
export def "labels CreateLabel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the label (format: int64)
  --name: string # The name the label
  --description: string # The description the label
  --color: string # The color the label
  --scope: string # The scope the label
  --project-id: int # The ID of project that the label belongs to (format: int64)
  --creation-time: string # The creation time the label (format: date-time)
  --update-time: string # The update time of the label (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/labels")
  let body = {id: $id, name: $name, description: $description, color: $color, scope: $scope, project_id: $project_id, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the label specified by ID.
#
# GET /labels/{label_id}
# operationId: GetLabelByID
export def "labels GetLabelByID" [
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, name: string, description: string, color: string, scope: string, project_id: int, creation_time: string, update_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($label_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the label properties.
#
# PUT /labels/{label_id}
# operationId: UpdateLabel
export def "labels UpdateLabel" [
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --id: int # The ID of the label (format: int64)
  --name: string # The name the label
  --description: string # The description the label
  --color: string # The color the label
  --scope: string # The scope the label
  --project-id: int # The ID of project that the label belongs to (format: int64)
  --creation-time: string # The creation time the label (format: date-time)
  --update-time: string # The update time of the label (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($label_id)")
  let body = {id: $id, name: $name, description: $description, color: $color, scope: $scope, project_id: $project_id, creation_time: $creation_time, update_time: $update_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the label specified by ID.
#
# DELETE /labels/{label_id}
# operationId: DeleteLabel
export def "labels DeleteLabel" [
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/labels/($label_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export scan data for selected projects
#
# POST /export/cve
# operationId: exportScanData
export def "export-cve exportScanData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
  --X-Scan-Data-Type: string # The type of scan data to export
  --job-name: string # Name of the scan data export job
  --projects: list # A list of one or more projects for which to export the scan data, currently only one project is supported due to performance concerns, but define as array for extension in the future.
  --labels: list # A list of one or more labels for which to export the scan data, defaults to all if empty
  --repositories: string # A list of repositories for which to export the scan data, defaults to all if empty
  --cveIds: string # CVE-IDs for which to export data. Multiple CVE-IDs can be specified by separating using ',' and enclosed between '{}'. Defaults to all if empty
  --tags: string # A list of tags enclosed within '{}'. Defaults to all if empty
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/cve")
  let body = {job_name: $job_name, projects: $projects, labels: $labels, repositories: $repositories, cveIds: $cveIds, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Request-Id": $X_Request_Id, "X-Scan-Data-Type": $X_Scan_Data_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the specific scan data export execution
#
# GET /export/cve/execution/{execution_id}
# operationId: getScanDataExportExecution
export def "export-cve-execution get" [
  execution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<id: int, user_id: int, status: string, trigger: string, start_time: string, end_time: string, status_text: string, user_name: string, file_present: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/export/cve/execution/($execution_id)")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of specific scan data export execution jobs for a specified user
#
# GET /export/cve/executions
# operationId: getScanDataExportExecutionList
export def "export-cve-executions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<items: table<id: int, user_id: int, status: string, trigger: string, start_time: string, end_time: string, status_text: string, user_name: string, file_present: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/cve/executions")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download the scan data export file
#
# GET /export/cve/download/{execution_id}
# operationId: downloadScanData
export def "export-cve-download downloadScanData" [
  execution_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string # The format of the data to be exported. e.g. CSV or PDF
  --X-Request-Id: string # An unique ID for the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/export/cve/download/($execution_id)" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vulnerability system summary
#
# GET /security/summary
# operationId: getSecuritySummary
export def "security-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-dangerous-cve: oneof<nothing, bool> # Specify whether the dangerous CVEs are included inside summary information (default: false)
  --with-dangerous-artifact: oneof<nothing, bool> # Specify whether the dangerous Artifact are included inside summary information (default: false)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<critical_cnt: int, high_cnt: int, medium_cnt: int, low_cnt: int, none_cnt: int, unknown_cnt: int, total_vuls: int, scanned_cnt: int, total_artifact: int, fixable_cnt: int, dangerous_cves: table<cve_id: string, severity: string, cvss_score_v3: float, desc: string, package: string, version: string>, dangerous_artifacts: table<project_id: int, repository_name: string, digest: string, critical_cnt: int, high_cnt: int, medium_cnt: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_dangerous_cve" $with_dangerous_cve "scalar") (serialize-qp "with_dangerous_artifact" $with_dangerous_artifact "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/security/summary" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the vulnerability list.
#
# GET /security/vul
# operationId: ListVulnerabilities
export def "security-vul ListVulnerabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to query resources. Supported query patterns are "exact match(k=v)", "fuzzy match(k=~v)", "range(k=[min~max])", "list with union releationship(k={v1 v2 v3})" and "list with intersetion relationship(k=(v1 v2 v3))". The value of range and list can be string(enclosed by " or '), integer or time(in format "2020-04-09 02:36:00"). All of these query patterns should be put in the query string "q=xxx" and splitted by ",". e.g. q=k1=v1,k2=~v2,k3=[min~max]
  --page: int # The page number (format: int64, default: 1)
  --page-size: int # The size of per page (format: int64, default: 10)
  --tune-count: oneof<nothing, bool> # Enable to ignore X-Total-Count when the total count > 1000, if the total count is less than 1000, the real total count is returned, else -1. (default: false)
  --with-tag: oneof<nothing, bool> # Specify whether the tag information is included inside vulnerability information (default: false)
  --X-Request-Id: string # An unique ID for the request
]: nothing -> table<project_id: int, repository_name: string, digest: string, tags: list<string>, cve_id: string, severity: string, status: string, cvss_v3_score: float, package: string, version: string, fixed_version: string, desc: string, links: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "tune_count" $tune_count "scalar") (serialize-qp "with_tag" $with_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/security/vul" $qp)
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get system or project level permissions info.
#
# GET /permissions
# operationId: getPermissions
export def "permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Request-Id: string # An unique ID for the request
]: nothing -> record<system: table<resource: string, action: string>, project: table<resource: string, action: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let extra_headers = {"X-Request-Id": $X_Request_Id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
