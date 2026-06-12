# Auto-generated client for Account Management Service API v0.0.1
# Source: https://api.openshift.com/api/accounts_mgmt/v1/openapi
# Auth: --token flag or $env.ACCOUNT_MANAGEMENT_SERVICE_API_TOKEN

const BASE_URL = "http://localhost:14321"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_MANAGEMENT_SERVICE_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost:14321" "https://api.openshift.com" "https://api.stage.openshift.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def managed-by-completer [] { ["Config" "User"] }
def arch-completer [] { ["aarch64" "ia64" "ppc" "ppc64" "ppc64le" "s390" "s390x" "x86" "x86_64"] }
def type-completer [] { ["sca"] }
def resource-type-completer [] { ["addon" "cluster" "compute.node" "network.io" "network.loadbalancer" "pv.storage"] }
def product-category-completer [] { ["HostedControlPlane" "assistedInstall"] }
def product-id-completer [] { ["ARO" "MOA" "MOA-HostedControlPlane" "OCP" "OCP-AssistedInstall" "OSD" "OSDTrial" "RHACS" "RHACSTrial" "RHMI" "RHOIC" "RHOSAK" "RHOSAKTrial" "RHOSE" "RHOSETrial" "RHOSR" "RHOSRTrial"] }
def log-type-completer [] { ["Capacity Management" "Cluster Access" "Cluster Add-ons" "Cluster Configuration" "Cluster Lifecycle" "Cluster Networking" "Cluster Ownership" "Cluster Scaling" "Cluster Security" "Cluster Subscription" "Cluster Updates" "Customer Support" "General Notification" "cluster-state-updates" "cluster-transfer-recipient" "clustercreate-details" "clustercreate-high-level" "clusterremove-details" "clusterremove-high-level"] }
def managed-by-completer-1 [] { ["OCM" "RBAC"] }
def type-completer-1 [] { ["Config" "Manual" "Subscription"] }
def plan-id-completer [] { ["OCP"] }
def status-completer [] { ["Disconnected"] }
def cluster-billing-model-completer [] { ["marketplace" "marketplace-aws" "marketplace-azure" "marketplace-gcp" "marketplace-rhm" "standard"] }
def product-bundle-completer [] { ["IBM-CloudPak" "JBoss-Middleware" "Openshift"] }
def service-level-completer [] { ["L1-L3" "L3-only"] }
def support-level-completer [] { ["Eval" "None" "Premium" "Self-Support" "Standard" "SupportedByIBM"] }
def system-units-completer [] { ["Cores/vCPU" "Sockets"] }
def usage-completer [] { ["Academic" "Development/Test" "Disaster Recovery" "Production"] }
def billing-model-completer [] { ["marketplace" "marketplace-aws" "marketplace-azure" "marketplace-gcp" "marketplace-rhm" "standard"] }
def severity-completer [] { ["1 (Urgent)" "2 (High)" "3 (Normal)" "4 (Low)"] }
def action-completer [] { ["create" "delete" "get" "list" "update"] }
def resource-type-completer-1 [] { ["AccessReview" "AccessToken" "Account" "AccountPool" "AddOn" "CSLogs" "Cluster" "ClusterAuthorization" "ClusterCredential" "ClusterForcedUpgrade" "ClusterLog" "ClusterMetric" "ClusterProviderAndRegion" "ClusterRegistration" "ClusterSelfManaged" "ClusterSelfManagedAddon" "ClusterSelfManagedLabel" "ClusterSelfManagedStatus" "CurrentAccount" "Dashboard" "DeleteProtection" "DeletedCluster" "ExportControlReview" "Flavour" "InternalServiceLog" "ManifestWorkSync" "Organization" "OrganizationLabel" "OsdTrialProtectedCluster" "Permission" "Plan" "RedhatManagedCluster" "Registry" "RegistryCredential" "ReservedResource" "ResourceQuota" "ResourceReview" "Role" "RoleBinding" "SelfAccessReview" "SelfManagedCluster" "SelfResourceReview" "ServiceLog" "Subscription" "SubscriptionInternal" "SubscriptionLabel" "SubscriptionLabelInternal" "SubscriptionRoleBinding"] }
def capability-completer [] { ["manage_cluster_admin"] }
def type-completer-2 [] { ["Cluster"] }
def action-completer-1 [] { ["delete" "get" "update"] }
def resource-type-completer-2 [] { ["Cluster" "Subscription"] }
def resource-type-completer-3 [] { ["AccessRequestDecision" "AccessReview" "AccessToken" "Account" "AccountPool" "AddOn" "CSLogs" "Cluster" "ClusterAuthorization" "ClusterAutoscaler" "ClusterBreakGlassCredential" "ClusterCredential" "ClusterForcedUpgrade" "ClusterKubeletConfig" "ClusterLog" "ClusterMetric" "ClusterProviderAndRegion" "ClusterRegistration" "ClusterSelfManaged" "ClusterSelfManagedAddon" "ClusterSelfManagedLabel" "ClusterSelfManagedStatus" "CurrentAccount" "Dashboard" "DeleteProtection" "DeletedCluster" "ExportControlReview" "Flavour" "Idp" "InternalServiceLog" "MachinePool" "ManifestWorkSync" "Organization" "OrganizationLabel" "OsdTrialProtectedCluster" "Permission" "Plan" "RedhatManagedCluster" "Registry" "RegistryCredential" "ReservedResource" "ResourceQuota" "ResourceReview" "Role" "RoleBinding" "SelfAccessReview" "SelfManagedCluster" "SelfResourceReview" "ServiceLog" "Subscription" "SubscriptionInternal" "SubscriptionLabel" "SubscriptionLabelInternal" "SubscriptionRoleBinding"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-mgmt-access-token post" } } | get name | first)
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

# Return access token generated from registries in docker format
#
# POST /api/accounts_mgmt/v1/access_token
export def "accounts-mgmt-access-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auths: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/access_token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of accounts
#
# GET /api/accounts_mgmt/v1/accounts
export def "accounts-mgmt-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
  --qp-fields: string # Supplies a comma-separated list of fields to be returned. Fields of sub-structures and of arrays use <structure>.<field> notation. <stucture>.* means all field of a structure Example: For each Subscription to get id, href, plan(id and kind) and labels (all fields)  ``` ocm get subscriptions --parameter fields=id,href,plan.id,plan.kind,labels.* --parameter fetchLabels=true ```
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
  --fetchCapabilities: oneof<nothing, bool> # If true, includes the capabilities on a subscription in the output. Could slow request response time.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: list, created_at: string, email: string, first_name: string, labels: list, last_name: string, organization: record, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "fetchLabels" $fetchLabels "scalar") (serialize-qp "fetchCapabilities" $fetchCapabilities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new account
#
# POST /api/accounts_mgmt/v1/accounts
# --capabilities item shape: {href?: string, id?: string, kind?: string, inherited: bool, name: string, value: string}
# --labels item shape: {href?: string, id?: string, kind?: string, account_id?: string, created_at?: string, internal: bool, key: string, managed_by?: "Config"|"User", organization_id?: string, subscription_id?: string, type?: string, updated_at?: string, value: string}
export def "accounts-mgmt-accounts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dryRun: oneof<nothing, bool> # If true, instructs API to avoid making any changes, but rather run through validations only.
  --href: string
  --id: string
  --kind: string
  --ban-code: string
  --ban-description: string
  --banned: oneof<nothing, bool> # default: false
  --capabilities: list # item shape: {href?: string, id?: string, kind?: string, inherited: bool, name: string, value: string}
  --created-at: string # format: date-time
  --email: string # format: email
  --first-name: string
  --labels: list # item shape: {href?: string, id?: string, kind?: string, account_id?: string, created_at?: string, internal: bool, key: string, managed_by?: "Config"|"User", organization_id?: string, subscription_id?: string, type?: string, updated_at?: string, value: string}
  --last-name: string
  --organization: any
  --organization-id: string
  --rhit-account-id: string
  --rhit-web-user-id: string
  --service-account: oneof<nothing, bool> # default: false
  --updated-at: string # format: date-time
  username: string
]: any -> record<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, email: string, first_name: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, last_name: string, organization: record<href: string, id: string, kind: string, capabilities: list<record>, created_at: string, ebs_account_id: string, external_id: string, labels: list<record>, name: string, updated_at: string>, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dryRun" $dryRun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/accounts" $qp)
  let body = {href: $href, id: $id, kind: $kind, ban_code: $ban_code, ban_description: $ban_description, banned: $banned, capabilities: $capabilities, created_at: $created_at, email: $email, first_name: $first_name, labels: $labels, last_name: $last_name, organization: $organization, organization_id: $organization_id, rhit_account_id: $rhit_account_id, rhit_web_user_id: $rhit_web_user_id, service_account: $service_account, updated_at: $updated_at, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an account by id
#
# DELETE /api/accounts_mgmt/v1/accounts/{id}
export def "accounts-mgmt-accounts delete" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteAssociatedResources: oneof<nothing, bool> # If true, deletes the associated resources (e.g. role bindings) for an account along with the account itself
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteAssociatedResources" $deleteAssociatedResources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an account by id
#
# GET /api/accounts_mgmt/v1/accounts/{id}
export def "accounts-mgmt-accounts get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
  --fetchCapabilities: oneof<nothing, bool> # If true, includes the capabilities on a subscription in the output. Could slow request response time.
  --fetchRhit: oneof<nothing, bool> # If true, includes the RHIT account_id in the output. Could slow request response time.
]: nothing -> record<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, email: string, first_name: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, last_name: string, organization: record<href: string, id: string, kind: string, capabilities: list<record>, created_at: string, ebs_account_id: string, external_id: string, labels: list<record>, name: string, updated_at: string>, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetchLabels" $fetchLabels "scalar") (serialize-qp "fetchCapabilities" $fetchCapabilities "scalar") (serialize-qp "fetchRhit" $fetchRhit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an account
#
# PATCH /api/accounts_mgmt/v1/accounts/{id}
export def "accounts-mgmt-accounts patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ban-code: string
  --ban-description: string
  --banned: oneof<nothing, bool>
  --email: string # format: email
  --first-name: string
  --last-name: string
  --organization-id: string
  --service-account: oneof<nothing, bool>
]: any -> record<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, email: string, first_name: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, last_name: string, organization: record<href: string, id: string, kind: string, capabilities: list<record>, created_at: string, ebs_account_id: string, external_id: string, labels: list<record>, name: string, updated_at: string>, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)")
  let body = {ban_code: $ban_code, ban_description: $ban_description, banned: $banned, email: $email, first_name: $first_name, last_name: $last_name, organization_id: $organization_id, service_account: $service_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of labels
#
# GET /api/accounts_mgmt/v1/accounts/{id}/labels
export def "accounts-mgmt-accounts-labels list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label or update an existing label
#
# POST /api/accounts_mgmt/v1/accounts/{id}/labels
export def "accounts-mgmt-accounts-labels post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --account-id: string
  --created-at: string # format: date-time
  --internal: oneof<nothing, bool>
  key: string
  --managed-by: string@managed-by-completer
  --organization-id: string
  --subscription-id: string
  --type: string
  --updated-at: string # format: date-time
  value: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/labels")
  let body = {href: $href, id: $body_id, kind: $kind, account_id: $account_id, created_at: $created_at, internal: $internal, key: $key, managed_by: $managed_by, organization_id: $organization_id, subscription_id: $subscription_id, type: $type, updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /api/accounts_mgmt/v1/accounts/{id}/labels/{key}
export def "accounts-mgmt-accounts-labels delete" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/labels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account labels by label key
#
# GET /api/accounts_mgmt/v1/accounts/{id}/labels/{key}
export def "accounts-mgmt-accounts-labels get" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/labels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label or update an existing label
#
# PATCH /api/accounts_mgmt/v1/accounts/{id}/labels/{key}
export def "accounts-mgmt-accounts-labels patch" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --account-id: string
  --created-at: string # format: date-time
  --internal: oneof<nothing, bool>
  --body-key: string
  --managed-by: string@managed-by-completer
  --organization-id: string
  --subscription-id: string
  --type: string
  --updated-at: string # format: date-time
  value: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/labels/($key)")
  let body = {href: $href, id: $body_id, kind: $kind, account_id: $account_id, created_at: $created_at, internal: $internal, key: $body_key, managed_by: $managed_by, organization_id: $organization_id, subscription_id: $subscription_id, type: $type, updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of pull secrets rotation
#
# GET /api/accounts_mgmt/v1/accounts/{id}/pull_secret_rotation
export def "accounts-mgmt-accounts-pull-secret-rotation list" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account_id: string, created_at: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/pull_secret_rotation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate pull secret rotation for this account id
#
# POST /api/accounts_mgmt/v1/accounts/{id}/pull_secret_rotation
export def "accounts-mgmt-accounts-pull-secret-rotation post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/pull_secret_rotation")
  let body = {href: $href, id: $body_id, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single Pull Secret Rotation record
#
# DELETE /api/accounts_mgmt/v1/accounts/{id}/pull_secret_rotation/{rotationId}
export def "accounts-mgmt-accounts-pull-secret-rotation delete" [
  id: string
  rotationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/pull_secret_rotation/($rotationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a pull secret rotation by id for a specific account
#
# GET /api/accounts_mgmt/v1/accounts/{id}/pull_secret_rotation/{rotationId}
export def "accounts-mgmt-accounts-pull-secret-rotation get" [
  id: string
  rotationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account_id: string, created_at: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/accounts/($id)/pull_secret_rotation/($rotationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of available billing models
#
# GET /api/accounts_mgmt/v1/billing_models
export def "accounts-mgmt-billing-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, billing_model_type: string, description: string, display_name: string, marketplace: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/billing_models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a billing model
#
# GET /api/accounts_mgmt/v1/billing_models/{id}
export def "accounts-mgmt-billing-models get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, billing_model_type: string, description: string, display_name: string, marketplace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/billing_models/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of available capabilities
#
# GET /api/accounts_mgmt/v1/capabilities
export def "accounts-mgmt-capabilities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/capabilities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch certificates of a particular type
#
# POST /api/accounts_mgmt/v1/certificates
@deprecated --flag type
export def "accounts-mgmt-certificates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  arch: string@arch-completer
  --type: string@type-completer # DEPRECATED
]: any -> record<cert: string, id: string, key: string, metadata: record, organization_id: string, serial: record<created: string, expiration: string, id: int, serial: int, updated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/certificates")
  let body = {arch: $arch, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of cloud resources
#
# GET /api/accounts_mgmt/v1/cloud_resources
export def "accounts-mgmt-cloud-resources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, active: bool, category: string, category_pretty: string, ccs_only: bool, cloud_provider: string, cpu_cores: int, created_at: string, generic_name: string, hcp_only: bool, memory: int, memory_pretty: string, name_pretty: string, resource_type: string, size_pretty: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/cloud_resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new cloud resource
#
# POST /api/accounts_mgmt/v1/cloud_resources
export def "accounts-mgmt-cloud-resources post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --active: oneof<nothing, bool> # default: true
  --category: string
  --category-pretty: string
  --ccs-only: oneof<nothing, bool>
  --cloud-provider: string
  --cpu-cores: int
  --created-at: string # format: date-time
  --generic-name: string
  --hcp-only: oneof<nothing, bool>
  --memory: int # format: int64
  --memory-pretty: string
  --name-pretty: string
  --resource-type: string@resource-type-completer
  --size-pretty: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, active: bool, category: string, category_pretty: string, ccs_only: bool, cloud_provider: string, cpu_cores: int, created_at: string, generic_name: string, hcp_only: bool, memory: int, memory_pretty: string, name_pretty: string, resource_type: string, size_pretty: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/cloud_resources")
  let body = {href: $href, id: $id, kind: $kind, active: $active, category: $category, category_pretty: $category_pretty, ccs_only: $ccs_only, cloud_provider: $cloud_provider, cpu_cores: $cpu_cores, created_at: $created_at, generic_name: $generic_name, hcp_only: $hcp_only, memory: $memory, memory_pretty: $memory_pretty, name_pretty: $name_pretty, resource_type: $resource_type, size_pretty: $size_pretty, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a cloud resource
#
# DELETE /api/accounts_mgmt/v1/cloud_resources/{id}
export def "accounts-mgmt-cloud-resources delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/cloud_resources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a cloud resource
#
# GET /api/accounts_mgmt/v1/cloud_resources/{id}
export def "accounts-mgmt-cloud-resources get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, active: bool, category: string, category_pretty: string, ccs_only: bool, cloud_provider: string, cpu_cores: int, created_at: string, generic_name: string, hcp_only: bool, memory: int, memory_pretty: string, name_pretty: string, resource_type: string, size_pretty: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/cloud_resources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a cloud resource
#
# PATCH /api/accounts_mgmt/v1/cloud_resources/{id}
export def "accounts-mgmt-cloud-resources patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --active: oneof<nothing, bool> # default: true
  --category: string
  --category-pretty: string
  --ccs-only: oneof<nothing, bool>
  --cloud-provider: string
  --cpu-cores: int
  --created-at: string # format: date-time
  --generic-name: string
  --hcp-only: oneof<nothing, bool>
  --memory: int # format: int64
  --memory-pretty: string
  --name-pretty: string
  --resource-type: string@resource-type-completer
  --size-pretty: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, active: bool, category: string, category_pretty: string, ccs_only: bool, cloud_provider: string, cpu_cores: int, created_at: string, generic_name: string, hcp_only: bool, memory: int, memory_pretty: string, name_pretty: string, resource_type: string, size_pretty: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/cloud_resources/($id)")
  let body = {href: $href, id: $body_id, kind: $kind, active: $active, category: $category, category_pretty: $category_pretty, ccs_only: $ccs_only, cloud_provider: $cloud_provider, cpu_cores: $cpu_cores, created_at: $created_at, generic_name: $generic_name, hcp_only: $hcp_only, memory: $memory, memory_pretty: $memory_pretty, name_pretty: $name_pretty, resource_type: $resource_type, size_pretty: $size_pretty, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorizes new cluster creation against an exsiting RH Subscription.
#
# POST /api/accounts_mgmt/v1/cluster_authorizations
# --resources item shape: {href?: string, id?: string, kind?: string, availability_zone_type?: string, billing_marketplace_account?: string, billing_model?: "standard"|"marketplace"|"marketplace-aws"|"marketplace-rhm"|"marketplace-azure"|"marketplace-gcp", byoc: bool, cluster?: bool, count?: int, created_at?: string, resource_name?: string, resource_type?: "compute.node.aws"|"pv.storage.aws"|"cluster.aws"|"network.io.aws"|"network.loadbalancer.aws"|"compute.node.gcp"|"pv.storage.gcp"|"cluster.gcp"|"network.io.gcp"|"network-gcp.loadbalancer.gcp"|"addon"|"compute.node"|"pv.storage"|"cluster"|"network.io"|"network.loadbalancer", scope?: string, subscription?: record, updated_at?: string}
export def "accounts-mgmt-cluster-authorizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  --availability-zone: string
  --byoc: oneof<nothing, bool>
  --cloud-account-id: string
  --cloud-provider-id: string
  cluster_id: string
  --disconnected: oneof<nothing, bool>
  --display-name: string
  --external-cluster-id: string
  --managed: oneof<nothing, bool>
  --product-category: string@product-category-completer
  --product-id: string@product-id-completer # default: OSD
  --quota-version: string
  --reserve: oneof<nothing, bool>
  --resources: list # item shape: {href?: string, id?: string, kind?: string, availability_zone_type?: string, billing_marketplace_account?: string, billing_model?: "standard"|"marketplace"|"marketplace-aws"|"marketplace-rhm"|"marketplace-azure"|"marketplace-gcp", byoc: bool, cluster?: bool, count?: int, created_at?: string, resource_name?: string, resource_type?: "compute.node.aws"|"pv.storage.aws"|"cluster.aws"|"network.io.aws"|"network.loadbalancer.aws"|"compute.node.gcp"|"pv.storage.gcp"|"cluster.gcp"|"network.io.gcp"|"network-gcp.loadbalancer.gcp"|"addon"|"compute.node"|"pv.storage"|"cluster"|"network.io"|"network.loadbalancer", scope?: string, subscription?: record, updated_at?: string}
  --rh-region-id: string
  --scope: string
]: any -> record<allowed: bool, excess_resources: table<href: string, id: string, kind: string, availability_zone_type: string, billing_model: string, byoc: bool, count: int, resource_name: string, resource_type: string>, organization_id: string, subscription: record<href: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/cluster_authorizations")
  let body = {account_username: $account_username, availability_zone: $availability_zone, byoc: $byoc, cloud_account_id: $cloud_account_id, cloud_provider_id: $cloud_provider_id, cluster_id: $cluster_id, disconnected: $disconnected, display_name: $display_name, external_cluster_id: $external_cluster_id, managed: $managed, product_category: $product_category, product_id: $product_id, quota_version: $quota_version, reserve: $reserve, resources: $resources, rh_region_id: $rh_region_id, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Finds or creates a cluster registration with a registy credential token and cluster ID
#
# POST /api/accounts_mgmt/v1/cluster_registrations
export def "accounts-mgmt-cluster-registrations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-token: string
  --cluster-id: string
]: any -> record<account_id: string, authorization_token: string, cluster_id: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/cluster_registrations")
  let body = {authorization_token: $authorization_token, cluster_id: $cluster_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List cluster transfers - returns either an empty result set or a valid ClusterTransfer instance that is within a valid transfer window.
#
# GET /api/accounts_mgmt/v1/cluster_transfers
export def "accounts-mgmt-cluster-transfers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, cluster_uuid: string, created_at: string, expiration_date: string, owner: string, pull_secret_rotation_id: string, recipient: string, recipient_ebs_account_id: string, recipient_external_org_id: string, secret: string, status: string, status_description: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/cluster_transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate cluster transfer.
#
# POST /api/accounts_mgmt/v1/cluster_transfers
export def "accounts-mgmt-cluster-transfers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-uuid: string
  --owner: string
  --recipient: string
  --recipient-ebs-account-id: string
  --recipient-external-org-id: string
]: any -> record<href: string, id: string, kind: string, cluster_uuid: string, created_at: string, expiration_date: string, owner: string, pull_secret_rotation_id: string, recipient: string, recipient_ebs_account_id: string, recipient_external_org_id: string, secret: string, status: string, status_description: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/cluster_transfers")
  let body = {cluster_uuid: $cluster_uuid, owner: $owner, recipient: $recipient, recipient_ebs_account_id: $recipient_ebs_account_id, recipient_external_org_id: $recipient_external_org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update specific cluster transfer
#
# PATCH /api/accounts_mgmt/v1/cluster_transfers/{id}
export def "accounts-mgmt-cluster-transfers patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
]: any -> record<href: string, id: string, kind: string, cluster_uuid: string, created_at: string, expiration_date: string, owner: string, pull_secret_rotation_id: string, recipient: string, recipient_ebs_account_id: string, recipient_external_org_id: string, secret: string, status: string, status_description: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/cluster_transfers/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of skus
#
# GET /api/accounts_mgmt/v1/config/skus
export def "accounts-mgmt-config-skus list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, created_at: string, description: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/config/skus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new sku
#
# POST /api/accounts_mgmt/v1/config/skus
export def "accounts-mgmt-config-skus post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --created-at: string # format: date-time
  --description: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, created_at: string, description: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/config/skus")
  let body = {href: $href, id: $id, kind: $kind, created_at: $created_at, description: $description, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a sku
#
# DELETE /api/accounts_mgmt/v1/config/skus/{id}
export def "accounts-mgmt-config-skus delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/config/skus/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sku
#
# GET /api/accounts_mgmt/v1/config/skus/{id}
export def "accounts-mgmt-config-skus get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, created_at: string, description: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/config/skus/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Sku
#
# PATCH /api/accounts_mgmt/v1/config/skus/{id}
export def "accounts-mgmt-config-skus patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --created-at: string # format: date-time
  --description: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, created_at: string, description: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/config/skus/($id)")
  let body = {href: $href, id: $body_id, kind: $kind, created_at: $created_at, description: $description, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the authenticated account
#
# GET /api/accounts_mgmt/v1/current_account
export def "accounts-mgmt-current-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
]: nothing -> record<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, email: string, first_name: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, last_name: string, organization: record<href: string, id: string, kind: string, capabilities: list<record>, created_at: string, ebs_account_id: string, external_id: string, labels: list<record>, name: string, updated_at: string>, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetchLabels" $fetchLabels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/current_account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of default capabilities
#
# GET /api/accounts_mgmt/v1/default_capabilities
export def "accounts-mgmt-default-capabilities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, name: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/default_capabilities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new default capability or update an existing one
#
# POST /api/accounts_mgmt/v1/default_capabilities
export def "accounts-mgmt-default-capabilities post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  name: string
  value: string
]: any -> record<href: string, id: string, kind: string, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/default_capabilities")
  let body = {href: $href, id: $id, kind: $kind, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a default capability
#
# DELETE /api/accounts_mgmt/v1/default_capabilities/{name}
export def "accounts-mgmt-default-capabilities delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/default_capabilities/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default capability by label name
#
# GET /api/accounts_mgmt/v1/default_capabilities/{name}
export def "accounts-mgmt-default-capabilities get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/default_capabilities/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new default capability or update an existing one
#
# PATCH /api/accounts_mgmt/v1/default_capabilities/{name}
export def "accounts-mgmt-default-capabilities patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --body-name: string
  value: string
]: any -> record<href: string, id: string, kind: string, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/default_capabilities/($name)")
  let body = {href: $href, id: $id, kind: $kind, name: $body_name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of deleted subscriptions
#
# GET /api/accounts_mgmt/v1/deleted_subscriptions
export def "accounts-mgmt-deleted-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<created_at: string, id: string, metrics: string, original_id: string, query_timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/deleted_subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a deleted subscription by id
#
# GET /api/accounts_mgmt/v1/deleted_subscriptions/{id}
export def "accounts-mgmt-deleted-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, metrics: string, original_id: string, query_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/deleted_subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all certificates of a sca type based on the architectures
#
# POST /api/accounts_mgmt/v1/entitlement_certificates
@deprecated --flag type
export def "accounts-mgmt-entitlement-certificates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  arch: list # e.g. [x86, x86_64, ppc]
  --type: string@type-completer # DEPRECATED
]: any -> record<items: table<cert: string, id: string, key: string, metadata: record, organization_id: string, serial: record>, kind: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/entitlement_certificates")
  let body = {arch: $arch, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of errors
#
# GET /api/accounts_mgmt/v1/errors
export def "accounts-mgmt-errors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, code: string, operation_id: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/errors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an error by id
#
# GET /api/accounts_mgmt/v1/errors/{id}
export def "accounts-mgmt-errors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, code: string, operation_id: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/errors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query a feature toggle by id
#
# POST /api/accounts_mgmt/v1/feature_toggles/{id}/query
# DEPRECATED
@deprecated
export def "accounts-mgmt-feature-toggles-query post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organization_id: string
]: any -> record<href: string, id: string, kind: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/feature_toggles/($id)/query")
  let body = {organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of labels
#
# GET /api/accounts_mgmt/v1/labels
export def "accounts-mgmt-labels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a console.redhat.com landing page content JSON schema
#
# GET /api/accounts_mgmt/v1/landing_page/self_service
export def "accounts-mgmt-landing-page-self-service get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<configTryLearn: record<configure: list<record>, try: list<record>>, estate: record<items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/landing_page/self_service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of metrics
#
# GET /api/accounts_mgmt/v1/metrics
export def "accounts-mgmt-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, external_id: string, health_state: string, metrics: string, query_timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get and validate notification details
#
# POST /api/accounts_mgmt/v1/notify_details
export def "accounts-mgmt-notify-details post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-address: string
  --cluster-id: string
  --cluster-uuid: string
  --include-red-hat-associates: oneof<nothing, bool>
  --internal-only: oneof<nothing, bool> # The `internal_only` parameter is used for validation. Specifically to check if there is a discrepancy between the email address and the log type.
  --log-type: string@log-type-completer # The type of log for which the returned contacts will be used to send a notification. When informed it might influence the returned contacts.
  --org-id: string
  --subject: string
  --subscription-id: string
]: any -> record<associates: list<string>, items: table<href: string, id: string, kind: string, key: string, value: string>, recipients: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/notify_details")
  let body = {bcc_address: $bcc_address, cluster_id: $cluster_id, cluster_uuid: $cluster_uuid, include_red_hat_associates: $include_red_hat_associates, internal_only: $internal_only, log_type: $log_type, org_id: $org_id, subject: $subject, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of organizations
#
# GET /api/accounts_mgmt/v1/organizations
export def "accounts-mgmt-organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
  --fetchCapabilities: oneof<nothing, bool> # If true, includes the capabilities on a subscription in the output. Could slow request response time.
  --qp-fields: string # Supplies a comma-separated list of fields to be returned. Fields of sub-structures and of arrays use <structure>.<field> notation. <stucture>.* means all field of a structure Example: For each Subscription to get id, href, plan(id and kind) and labels (all fields)  ``` ocm get subscriptions --parameter fields=id,href,plan.id,plan.kind,labels.* --parameter fetchLabels=true ```
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, capabilities: list, created_at: string, ebs_account_id: string, external_id: string, labels: list, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "fetchLabels" $fetchLabels "scalar") (serialize-qp "fetchCapabilities" $fetchCapabilities "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new organization
#
# POST /api/accounts_mgmt/v1/organizations
# --capabilities item shape: {href?: string, id?: string, kind?: string, inherited: bool, name: string, value: string}
# --labels item shape: {href?: string, id?: string, kind?: string, account_id?: string, created_at?: string, internal: bool, key: string, managed_by?: "Config"|"User", organization_id?: string, subscription_id?: string, type?: string, updated_at?: string, value: string}
export def "accounts-mgmt-organizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --capabilities: list # item shape: {href?: string, id?: string, kind?: string, inherited: bool, name: string, value: string}
  --created-at: string # format: date-time
  --ebs-account-id: string
  --external-id: string
  --labels: list # item shape: {href?: string, id?: string, kind?: string, account_id?: string, created_at?: string, internal: bool, key: string, managed_by?: "Config"|"User", organization_id?: string, subscription_id?: string, type?: string, updated_at?: string, value: string}
  --name: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, ebs_account_id: string, external_id: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/organizations")
  let body = {href: $href, id: $id, kind: $kind, capabilities: $capabilities, created_at: $created_at, ebs_account_id: $ebs_account_id, external_id: $external_id, labels: $labels, name: $name, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an organization by id
#
# GET /api/accounts_mgmt/v1/organizations/{id}
export def "accounts-mgmt-organizations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
  --fetchCapabilities: oneof<nothing, bool> # If true, includes the capabilities on a subscription in the output. Could slow request response time.
]: nothing -> record<href: string, id: string, kind: string, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, ebs_account_id: string, external_id: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetchLabels" $fetchLabels "scalar") (serialize-qp "fetchCapabilities" $fetchCapabilities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /api/accounts_mgmt/v1/organizations/{id}
export def "accounts-mgmt-organizations patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ebs-account-id: string
  --external-id: string
  --name: string
]: any -> record<href: string, id: string, kind: string, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, ebs_account_id: string, external_id: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)")
  let body = {ebs_account_id: $ebs_account_id, external_id: $external_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of labels
#
# GET /api/accounts_mgmt/v1/organizations/{id}/labels
export def "accounts-mgmt-organizations-labels list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label or update an existing label
#
# POST /api/accounts_mgmt/v1/organizations/{id}/labels
export def "accounts-mgmt-organizations-labels post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --account-id: string
  --created-at: string # format: date-time
  --internal: oneof<nothing, bool>
  key: string
  --managed-by: string@managed-by-completer
  --organization-id: string
  --subscription-id: string
  --type: string
  --updated-at: string # format: date-time
  value: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)/labels")
  let body = {href: $href, id: $body_id, kind: $kind, account_id: $account_id, created_at: $created_at, internal: $internal, key: $key, managed_by: $managed_by, organization_id: $organization_id, subscription_id: $subscription_id, type: $type, updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /api/accounts_mgmt/v1/organizations/{id}/labels/{key}
export def "accounts-mgmt-organizations-labels delete" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)/labels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization labels by label key
#
# GET /api/accounts_mgmt/v1/organizations/{id}/labels/{key}
export def "accounts-mgmt-organizations-labels get" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)/labels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label or update an existing label
#
# PATCH /api/accounts_mgmt/v1/organizations/{id}/labels/{key}
export def "accounts-mgmt-organizations-labels patch" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --account-id: string
  --created-at: string # format: date-time
  --internal: oneof<nothing, bool>
  --body-key: string
  --managed-by: string@managed-by-completer
  --organization-id: string
  --subscription-id: string
  --type: string
  --updated-at: string # format: date-time
  value: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)/labels/($key)")
  let body = {href: $href, id: $body_id, kind: $kind, account_id: $account_id, created_at: $created_at, internal: $internal, key: $body_key, managed_by: $managed_by, organization_id: $organization_id, subscription_id: $subscription_id, type: $type, updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a summary of organizations clusters based on metrics
#
# GET /api/accounts_mgmt/v1/organizations/{id}/summary_dashboard
export def "accounts-mgmt-organizations-summary-dashboard get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, metrics: table<name: string, vector: list>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($id)/summary_dashboard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of account group assignments for the given org
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/account_group_assignments
export def "accounts-mgmt-organizations-account-group-assignments list" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account_group_id: string, account_id: string, created_at: string, managed_by: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_group_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new AccountGroupAssignment
#
# POST /api/accounts_mgmt/v1/organizations/{orgId}/account_group_assignments
export def "accounts-mgmt-organizations-account-group-assignments post" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  account_group_id: string
  account_id: string
  --created-at: string # format: date-time
  managed_by: string@managed-by-completer-1
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, account_group_id: string, account_id: string, created_at: string, managed_by: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_group_assignments")
  let body = {href: $href, id: $id, kind: $kind, account_group_id: $account_group_id, account_id: $account_id, created_at: $created_at, managed_by: $managed_by, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an account group assignment
#
# DELETE /api/accounts_mgmt/v1/organizations/{orgId}/account_group_assignments/{acctGrpAsgnId}
export def "accounts-mgmt-organizations-account-group-assignments delete" [
  orgId: string
  acctGrpAsgnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_group_assignments/($acctGrpAsgnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account group assignment by id
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/account_group_assignments/{acctGrpAsgnId}
export def "accounts-mgmt-organizations-account-group-assignments get" [
  orgId: string
  acctGrpAsgnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account_group_id: string, account_id: string, created_at: string, managed_by: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_group_assignments/($acctGrpAsgnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of account groups for the given org
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/account_groups
export def "accounts-mgmt-organizations-account-groups list" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, created_at: string, description: string, external_id: string, managed_by: string, name: string, organization_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new AccountGroup
#
# POST /api/accounts_mgmt/v1/organizations/{orgId}/account_groups
export def "accounts-mgmt-organizations-account-groups post" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  description: string
  name: string
]: any -> record<href: string, id: string, kind: string, created_at: string, description: string, external_id: string, managed_by: string, name: string, organization_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_groups")
  let body = {href: $href, id: $id, kind: $kind, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an account group
#
# DELETE /api/accounts_mgmt/v1/organizations/{orgId}/account_groups/{acctGrpId}
export def "accounts-mgmt-organizations-account-groups delete" [
  orgId: string
  acctGrpId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_groups/($acctGrpId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account group by id
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/account_groups/{acctGrpId}
export def "accounts-mgmt-organizations-account-groups get" [
  orgId: string
  acctGrpId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, created_at: string, description: string, external_id: string, managed_by: string, name: string, organization_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_groups/($acctGrpId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an account group
#
# PATCH /api/accounts_mgmt/v1/organizations/{orgId}/account_groups/{acctGrpId}
export def "accounts-mgmt-organizations-account-groups patch" [
  orgId: string
  acctGrpId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  description: string
  name: string
]: any -> record<href: string, id: string, kind: string, created_at: string, description: string, external_id: string, managed_by: string, name: string, organization_id: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/account_groups/($acctGrpId)")
  let body = {href: $href, id: $id, kind: $kind, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of consumed quota for an organization
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/consumed_quota
export def "accounts-mgmt-organizations-consumed-quota get" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceRecalc: oneof<nothing, bool> # If true, includes that ConsumedQuota should be recalculated.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, availability_zone_type: string, billing_model: string, byoc: bool, cloud_provider_id: string, count: int, organization_id: string, plan_id: string, resource_name: string, resource_type: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceRecalc" $forceRecalc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/consumed_quota" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a summary of quota cost
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/quota_cost
export def "accounts-mgmt-organizations-quota-cost get" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --fetchRelatedResources: oneof<nothing, bool> # If true, includes the related resources in the output. Could slow request response time.
  --forceRecalc: oneof<nothing, bool> # If true, includes that ConsumedQuota should be recalculated.
  --fetchCloudAccounts: oneof<nothing, bool> # If true, includes the marketplace cloud accounts in the output. Could slow request response time.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, allowed: int, cloud_accounts: list, consumed: int, organization_id: string, quota_id: string, related_resources: list, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "fetchRelatedResources" $fetchRelatedResources "scalar") (serialize-qp "forceRecalc" $forceRecalc "scalar") (serialize-qp "fetchCloudAccounts" $fetchCloudAccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/quota_cost" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of resource quota objects
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/resource_quota
export def "accounts-mgmt-organizations-resource-quota list" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, created_at: string, organization_id: string, sku: string, sku_count: int, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/resource_quota" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new resource quota
#
# POST /api/accounts_mgmt/v1/organizations/{orgId}/resource_quota
export def "accounts-mgmt-organizations-resource-quota post" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sku: string
  sku_count: int
  --type: string@type-completer-1
]: any -> record<href: string, id: string, kind: string, created_at: string, organization_id: string, sku: string, sku_count: int, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/resource_quota")
  let body = {sku: $sku, sku_count: $sku_count, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a resource quota
#
# DELETE /api/accounts_mgmt/v1/organizations/{orgId}/resource_quota/{quotaId}
export def "accounts-mgmt-organizations-resource-quota delete" [
  orgId: string
  quotaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/resource_quota/($quotaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a resource quota by id
#
# GET /api/accounts_mgmt/v1/organizations/{orgId}/resource_quota/{quotaId}
export def "accounts-mgmt-organizations-resource-quota get" [
  orgId: string
  quotaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, created_at: string, organization_id: string, sku: string, sku_count: int, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/resource_quota/($quotaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a resource quota
#
# PATCH /api/accounts_mgmt/v1/organizations/{orgId}/resource_quota/{quotaId}
export def "accounts-mgmt-organizations-resource-quota patch" [
  orgId: string
  quotaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sku: string
  sku_count: int
  --type: string@type-completer-1
]: any -> record<href: string, id: string, kind: string, created_at: string, organization_id: string, sku: string, sku_count: int, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/organizations/($orgId)/resource_quota/($quotaId)")
  let body = {sku: $sku, sku_count: $sku_count, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all plans
#
# GET /api/accounts_mgmt/v1/plans
export def "accounts-mgmt-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, category: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a plan by id
#
# GET /api/accounts_mgmt/v1/plans/{id}
export def "accounts-mgmt-plans get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, category: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/plans/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return access token generated from registries in docker format
#
# POST /api/accounts_mgmt/v1/pull_secrets
export def "accounts-mgmt-pull-secrets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  external_resource_id: string
]: any -> record<auths: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/pull_secrets")
  let body = {external_resource_id: $external_resource_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a pull secret
#
# DELETE /api/accounts_mgmt/v1/pull_secrets/{externalResourceId}
export def "accounts-mgmt-pull-secrets delete" [
  externalResourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/pull_secrets/($externalResourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authorizes a user to consume or release a single quantity of quota
#
# POST /api/accounts_mgmt/v1/quota_authorizations
# --resources item shape: {href?: string, id?: string, kind?: string, availability_zone_type?: string, billing_marketplace_account?: string, billing_model?: "standard"|"marketplace"|"marketplace-aws"|"marketplace-rhm"|"marketplace-azure"|"marketplace-gcp", byoc: bool, cluster?: bool, count?: int, created_at?: string, resource_name?: string, resource_type?: "compute.node.aws"|"pv.storage.aws"|"cluster.aws"|"network.io.aws"|"network.loadbalancer.aws"|"compute.node.gcp"|"pv.storage.gcp"|"cluster.gcp"|"network.io.gcp"|"network-gcp.loadbalancer.gcp"|"addon"|"compute.node"|"pv.storage"|"cluster"|"network.io"|"network.loadbalancer", scope?: string, subscription?: record, updated_at?: string}
export def "accounts-mgmt-quota-authorizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  --availability-zone: string
  --cloud-provider-id: string
  --display-name: string
  --product-id: string
  --quota-version: string
  --reserve: oneof<nothing, bool>
  --resource-id: string
  resources: list # item shape: {href?: string, id?: string, kind?: string, availability_zone_type?: string, billing_marketplace_account?: string, billing_model?: "standard"|"marketplace"|"marketplace-aws"|"marketplace-rhm"|"marketplace-azure"|"marketplace-gcp", byoc: bool, cluster?: bool, count?: int, created_at?: string, resource_name?: string, resource_type?: "compute.node.aws"|"pv.storage.aws"|"cluster.aws"|"network.io.aws"|"network.loadbalancer.aws"|"compute.node.gcp"|"pv.storage.gcp"|"cluster.gcp"|"network.io.gcp"|"network-gcp.loadbalancer.gcp"|"addon"|"compute.node"|"pv.storage"|"cluster"|"network.io"|"network.loadbalancer", scope?: string, subscription?: record, updated_at?: string}
  --subscription-id: string
]: any -> record<allowed: bool, excess_resources: table<href: string, id: string, kind: string, availability_zone_type: string, billing_model: string, byoc: bool, count: int, resource_name: string, resource_type: string>, organization_id: string, subscription: record<href: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/quota_authorizations")
  let body = {account_username: $account_username, availability_zone: $availability_zone, cloud_provider_id: $cloud_provider_id, display_name: $display_name, product_id: $product_id, quota_version: $quota_version, reserve: $reserve, resource_id: $resource_id, resources: $resources, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a summary of quota cost for the authenticated user
#
# GET /api/accounts_mgmt/v1/quota_cost
export def "accounts-mgmt-quota-cost get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --fetchRelatedResources: oneof<nothing, bool> # If true, includes the related resources in the output. Could slow request response time.
  --fetchCloudAccounts: oneof<nothing, bool> # If true, includes the marketplace cloud accounts in the output. Could slow request response time.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, allowed: int, cloud_accounts: list, consumed: int, organization_id: string, quota_id: string, related_resources: list, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "fetchRelatedResources" $fetchRelatedResources "scalar") (serialize-qp "fetchCloudAccounts" $fetchCloudAccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/quota_cost" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of UHC product Quota Rules
#
# GET /api/accounts_mgmt/v1/quota_rules
export def "accounts-mgmt-quota-rules get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, availability_zone: string, billing_model: string, byoc: string, cloud: string, cost: int, name: string, product: string, quota_id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/quota_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of quotas
#
# GET /api/accounts_mgmt/v1/quotas
export def "accounts-mgmt-quotas list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, created_at: string, description: string, resource_type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/quotas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new quota
#
# POST /api/accounts_mgmt/v1/quotas
export def "accounts-mgmt-quotas post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --created-at: string # format: date-time
  --description: string
  --resource-type: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, created_at: string, description: string, resource_type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/quotas")
  let body = {href: $href, id: $id, kind: $kind, created_at: $created_at, description: $description, resource_type: $resource_type, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a quota
#
# DELETE /api/accounts_mgmt/v1/quotas/{id}
export def "accounts-mgmt-quotas delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/quotas/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a quota
#
# GET /api/accounts_mgmt/v1/quotas/{id}
export def "accounts-mgmt-quotas get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, created_at: string, description: string, resource_type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/quotas/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a quota
#
# PATCH /api/accounts_mgmt/v1/quotas/{id}
export def "accounts-mgmt-quotas patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --created-at: string # format: date-time
  --description: string
  --resource-type: string
  --updated-at: string # format: date-time
]: any -> record<href: string, id: string, kind: string, created_at: string, description: string, resource_type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/quotas/($id)")
  let body = {href: $href, id: $body_id, kind: $kind, created_at: $created_at, description: $description, resource_type: $resource_type, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of regions to which a user has access
#
# GET /api/accounts_mgmt/v1/regions
export def "accounts-mgmt-regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, cloud_provider_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a summary of clusters by region
#
# GET /api/accounts_mgmt/v1/regions/summary
export def "accounts-mgmt-regions-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, cloud_provider_id: string, count: int, region_id: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/regions/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of registries
#
# GET /api/accounts_mgmt/v1/registries
export def "accounts-mgmt-registries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, cloudAlias: bool, created_at: string, name: string, org_name: string, team_name: string, type: string, updated_at: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/registries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an registry by id
#
# GET /api/accounts_mgmt/v1/registries/{id}
export def "accounts-mgmt-registries get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, cloudAlias: bool, created_at: string, name: string, org_name: string, team_name: string, type: string, updated_at: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/registries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Registry Credentials
#
# GET /api/accounts_mgmt/v1/registry_credentials
export def "accounts-mgmt-registry-credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account: record, created_at: string, external_resource_id: string, registry: record, token: string, updated_at: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/registry_credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request the creation of a registry credential
#
# POST /api/accounts_mgmt/v1/registry_credentials
# --account shape: {href?: string, id?: string, kind?: string}
# --registry shape: {href?: string, id?: string, kind?: string}
export def "accounts-mgmt-registry-credentials post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --account: record # shape: {href?: string, id?: string, kind?: string}
  --created-at: string # format: date-time
  --external-resource-id: string
  --registry: record # shape: {href?: string, id?: string, kind?: string}
  --body-token: string
  --updated-at: string # format: date-time
  --username: string
]: any -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string>, created_at: string, external_resource_id: string, registry: record<href: string, id: string, kind: string>, token: string, updated_at: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/registry_credentials")
  let body = {href: $href, id: $id, kind: $kind, account: $account, created_at: $created_at, external_resource_id: $external_resource_id, registry: $registry, token: $body_token, updated_at: $updated_at, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a registry credential by id
#
# DELETE /api/accounts_mgmt/v1/registry_credentials/{id}
export def "accounts-mgmt-registry-credentials delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/registry_credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a registry credentials by id
#
# GET /api/accounts_mgmt/v1/registry_credentials/{id}
export def "accounts-mgmt-registry-credentials get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string>, created_at: string, external_resource_id: string, registry: record<href: string, id: string, kind: string>, token: string, updated_at: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/registry_credentials/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a registry credential
#
# PATCH /api/accounts_mgmt/v1/registry_credentials/{id}
export def "accounts-mgmt-registry-credentials patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string
  --external-resource-id: string
  --registry-id: string
  --body-token: string
  --username: string
]: any -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string>, created_at: string, external_resource_id: string, registry: record<href: string, id: string, kind: string>, token: string, updated_at: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/registry_credentials/($id)")
  let body = {account_id: $account_id, external_resource_id: $external_resource_id, registry_id: $registry_id, token: $body_token, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of reserved resources
#
# GET /api/accounts_mgmt/v1/reserved_resources
export def "accounts-mgmt-reserved-resources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, availability_zone_type: string, billing_marketplace_account: string, billing_model: string, byoc: bool, cluster: bool, count: int, created_at: string, resource_name: string, resource_type: string, scope: string, subscription: record, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/reserved_resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of resource quota objects
#
# GET /api/accounts_mgmt/v1/resource_quota
export def "accounts-mgmt-resource-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, created_at: string, organization_id: string, sku: string, sku_count: int, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/resource_quota" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of role bindings
#
# GET /api/accounts_mgmt/v1/role_bindings
export def "accounts-mgmt-role-bindings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account: record, account_group: record, config_managed: bool, created_at: string, managed_by: string, organization: record, role: record, subscription: record, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/role_bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new role binding
#
# POST /api/accounts_mgmt/v1/role_bindings
export def "accounts-mgmt-role-bindings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-group-id: string
  --account-id: string
  --config-managed: oneof<nothing, bool>
  --managed-by: string
  --organization-id: string
  role_id: string
  --subscription-id: string
  type: string
]: any -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string>, account_group: record<href: string, id: string, kind: string>, config_managed: bool, created_at: string, managed_by: string, organization: record<href: string, id: string, kind: string>, role: record<href: string, id: string, kind: string>, subscription: record<href: string, id: string, kind: string>, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/role_bindings")
  let body = {account_group_id: $account_group_id, account_id: $account_id, config_managed: $config_managed, managed_by: $managed_by, organization_id: $organization_id, role_id: $role_id, subscription_id: $subscription_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role binding
#
# DELETE /api/accounts_mgmt/v1/role_bindings/{id}
export def "accounts-mgmt-role-bindings delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/role_bindings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a role binding
#
# GET /api/accounts_mgmt/v1/role_bindings/{id}
export def "accounts-mgmt-role-bindings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string>, account_group: record<href: string, id: string, kind: string>, config_managed: bool, created_at: string, managed_by: string, organization: record<href: string, id: string, kind: string>, role: record<href: string, id: string, kind: string>, subscription: record<href: string, id: string, kind: string>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/role_bindings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role binding
#
# PATCH /api/accounts_mgmt/v1/role_bindings/{id}
export def "accounts-mgmt-role-bindings patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-group-id: string
  --account-id: string
  --config-managed: oneof<nothing, bool>
  --managed-by: string
  --organization-id: string
  --role-id: string
  --subscription-id: string
  --type: string
]: any -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string>, account_group: record<href: string, id: string, kind: string>, config_managed: bool, created_at: string, managed_by: string, organization: record<href: string, id: string, kind: string>, role: record<href: string, id: string, kind: string>, subscription: record<href: string, id: string, kind: string>, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/role_bindings/($id)")
  let body = {account_group_id: $account_group_id, account_id: $account_id, config_managed: $config_managed, managed_by: $managed_by, organization_id: $organization_id, role_id: $role_id, subscription_id: $subscription_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of roles
#
# GET /api/accounts_mgmt/v1/roles
export def "accounts-mgmt-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a role by id
#
# GET /api/accounts_mgmt/v1/roles/{id}
export def "accounts-mgmt-roles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, name: string, permissions: table<action: string, resource: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or renew the entitlement to support a product for the user's organization.
#
# POST /api/accounts_mgmt/v1/self_entitlement/{product}
export def "accounts-mgmt-self-entitlement post" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<product: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/self_entitlement/($product)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of UHC product SKU Rules
#
# GET /api/accounts_mgmt/v1/sku_rules
export def "accounts-mgmt-sku-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, allowed: int, quota_id: string, sku: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/sku_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new sku rule
#
# POST /api/accounts_mgmt/v1/sku_rules
export def "accounts-mgmt-sku-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --id: string
  --kind: string
  --allowed: int
  --quota-id: string
  --sku: string
]: any -> record<href: string, id: string, kind: string, allowed: int, quota_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/sku_rules")
  let body = {href: $href, id: $id, kind: $kind, allowed: $allowed, quota_id: $quota_id, sku: $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a sku rule
#
# DELETE /api/accounts_mgmt/v1/sku_rules/{id}
export def "accounts-mgmt-sku-rules delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/sku_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sku rules by id
#
# GET /api/accounts_mgmt/v1/sku_rules/{id}
export def "accounts-mgmt-sku-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, allowed: int, quota_id: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/sku_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a sku rule
#
# PATCH /api/accounts_mgmt/v1/sku_rules/{id}
export def "accounts-mgmt-sku-rules patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --allowed: int
  --quota-id: string
  --sku: string
]: any -> record<href: string, id: string, kind: string, allowed: int, quota_id: string, sku: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/sku_rules/($id)")
  let body = {href: $href, id: $body_id, kind: $kind, allowed: $allowed, quota_id: $quota_id, sku: $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of UHC product SKUs
#
# GET /api/accounts_mgmt/v1/skus
# DEPRECATED
@deprecated
export def "accounts-mgmt-skus list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, created_at: string, description: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/skus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sku by id
#
# GET /api/accounts_mgmt/v1/skus/{id}
# DEPRECATED
@deprecated
export def "accounts-mgmt-skus get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, created_at: string, description: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/skus/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of subscriptions
#
# GET /api/accounts_mgmt/v1/subscriptions
export def "accounts-mgmt-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --fetchAccounts: oneof<nothing, bool> # If true, includes the account reference information in the output. Could slow request response time.
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
  --fetchCapabilities: oneof<nothing, bool> # If true, includes the capabilities on a subscription in the output. Could slow request response time.
  --fetchOrganization: oneof<nothing, bool> # If true, includes the organization object on a subscription in the output. Could slow request response time.
  --qp-fields: string # Supplies a comma-separated list of fields to be returned. Fields of sub-structures and of arrays use <structure>.<field> notation. <stucture>.* means all field of a structure Example: For each Subscription to get id, href, plan(id and kind) and labels (all fields)  ``` ocm get subscriptions --parameter fields=id,href,plan.id,plan.kind,labels.* --parameter fetchLabels=true ```
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
  --labels: string # Specifies the criteria to filter the subscription resource based on their labels. A label is represented as a `key=value` pair,  ``` labels = "foo=bar" ```  and multiple labels are separated by comma,  ``` labels = "foo=bar,fooz=barz" ```
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<capabilities: list, cluster_transfers: list, created_at: string, creator: record, eval_expiration_date: string, labels: list, metrics: list, notification_contacts: list, plan: record, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "fetchAccounts" $fetchAccounts "scalar") (serialize-qp "fetchLabels" $fetchLabels "scalar") (serialize-qp "fetchCapabilities" $fetchCapabilities "scalar") (serialize-qp "fetchOrganization" $fetchOrganization "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "labels" $labels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts_mgmt/v1/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new subscription
#
# POST /api/accounts_mgmt/v1/subscriptions
export def "accounts-mgmt-subscriptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cluster_uuid: string
  --console-url: string
  --display-name: string
  plan_id: string@plan-id-completer
  status: string@status-completer
]: any -> record<capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, cluster_transfers: table<href: string, id: string, kind: string, cluster_uuid: string, created_at: string, expiration_date: string, owner: string, pull_secret_rotation_id: string, recipient: string, recipient_ebs_account_id: string, recipient_external_org_id: string, secret: string, status: string, status_description: string, updated_at: string>, created_at: string, creator: record<href: string, id: string, kind: string, email: string, first_name: string, last_name: string, name: string, username: string>, eval_expiration_date: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, metrics: table<arch: string, channel_info: string, cloud_provider: string, cluster_type: string, compute_nodes_cpu: record, compute_nodes_memory: record, compute_nodes_sockets: record, console_url: string, cpu: record, critical_alerts_firing: float, health_state: string, memory: record, nodes: record, nodes_arch: list, non_virt_nodes: float, openshift_version: string, operating_system: string, operators_condition_failing: float, query_timestamp: string, region: string, sockets: record, state: string, state_description: string, storage: record, subscription_cpu_total: float, subscription_obligation_exists: float, subscription_socket_total: float, upgrade: record>, notification_contacts: table<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: list, created_at: string, email: string, first_name: string, labels: list, last_name: string, organization: record, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string>, plan: record<href: string, id: string, kind: string, category: string, name: string, type: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/subscriptions")
  let body = {cluster_uuid: $cluster_uuid, console_url: $console_url, display_name: $display_name, plan_id: $plan_id, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a subscription by id
#
# DELETE /api/accounts_mgmt/v1/subscriptions/{id}
export def "accounts-mgmt-subscriptions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a subscription by id
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}
export def "accounts-mgmt-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fetchAccounts: oneof<nothing, bool> # If true, includes the account reference information in the output. Could slow request response time.
  --fetchLabels: oneof<nothing, bool> # If true, includes the labels on a subscription/organization/account in the output. Could slow request response time.
  --fetchCapabilities: oneof<nothing, bool> # If true, includes the capabilities on a subscription in the output. Could slow request response time.
  --fetchClusterTransfers: oneof<nothing, bool> # If true, returns either an empty result set or a valid ClusterTransfer list on a subscription in the output. Could slow request response time.
  --fetchCpuAndSocket: oneof<nothing, bool> # If true, fetches, from the clusters service, the total numbers of CPU's and sockets under an obligation, and includes in the output. Could slow request response time.
]: nothing -> record<capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, cluster_transfers: table<href: string, id: string, kind: string, cluster_uuid: string, created_at: string, expiration_date: string, owner: string, pull_secret_rotation_id: string, recipient: string, recipient_ebs_account_id: string, recipient_external_org_id: string, secret: string, status: string, status_description: string, updated_at: string>, created_at: string, creator: record<href: string, id: string, kind: string, email: string, first_name: string, last_name: string, name: string, username: string>, eval_expiration_date: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, metrics: table<arch: string, channel_info: string, cloud_provider: string, cluster_type: string, compute_nodes_cpu: record, compute_nodes_memory: record, compute_nodes_sockets: record, console_url: string, cpu: record, critical_alerts_firing: float, health_state: string, memory: record, nodes: record, nodes_arch: list, non_virt_nodes: float, openshift_version: string, operating_system: string, operators_condition_failing: float, query_timestamp: string, region: string, sockets: record, state: string, state_description: string, storage: record, subscription_cpu_total: float, subscription_obligation_exists: float, subscription_socket_total: float, upgrade: record>, notification_contacts: table<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: list, created_at: string, email: string, first_name: string, labels: list, last_name: string, organization: record, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string>, plan: record<href: string, id: string, kind: string, category: string, name: string, type: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetchAccounts" $fetchAccounts "scalar") (serialize-qp "fetchLabels" $fetchLabels "scalar") (serialize-qp "fetchCapabilities" $fetchCapabilities "scalar") (serialize-qp "fetchClusterTransfers" $fetchClusterTransfers "scalar") (serialize-qp "fetchCpuAndSocket" $fetchCpuAndSocket "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a subscription
#
# PATCH /api/accounts_mgmt/v1/subscriptions/{id}
export def "accounts-mgmt-subscriptions patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-expiration-date: string # format: date-time
  --cloud-account-id: string
  --cloud-provider-id: string
  --cluster-billing-model: string@cluster-billing-model-completer
  --cluster-id: string
  --console-url: string
  --consumer-uuid: string
  --cpu-total: int
  --creator-id: string
  --display-name: string
  --external-cluster-id: string
  --managed: oneof<nothing, bool>
  --organization-id: string
  --plan-id: string
  --product-bundle: string@product-bundle-completer
  --provenance: string
  --region-id: string
  --released: oneof<nothing, bool>
  --service-level: string@service-level-completer
  --socket-total: int
  --status: string
  --support-level: string@support-level-completer
  --system-units: string@system-units-completer
  --trial-end-date: string # format: date-time
  --usage: string@usage-completer
]: any -> record<capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, cluster_transfers: table<href: string, id: string, kind: string, cluster_uuid: string, created_at: string, expiration_date: string, owner: string, pull_secret_rotation_id: string, recipient: string, recipient_ebs_account_id: string, recipient_external_org_id: string, secret: string, status: string, status_description: string, updated_at: string>, created_at: string, creator: record<href: string, id: string, kind: string, email: string, first_name: string, last_name: string, name: string, username: string>, eval_expiration_date: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, metrics: table<arch: string, channel_info: string, cloud_provider: string, cluster_type: string, compute_nodes_cpu: record, compute_nodes_memory: record, compute_nodes_sockets: record, console_url: string, cpu: record, critical_alerts_firing: float, health_state: string, memory: record, nodes: record, nodes_arch: list, non_virt_nodes: float, openshift_version: string, operating_system: string, operators_condition_failing: float, query_timestamp: string, region: string, sockets: record, state: string, state_description: string, storage: record, subscription_cpu_total: float, subscription_obligation_exists: float, subscription_socket_total: float, upgrade: record>, notification_contacts: table<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: list, created_at: string, email: string, first_name: string, labels: list, last_name: string, organization: record, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string>, plan: record<href: string, id: string, kind: string, category: string, name: string, type: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)")
  let body = {billing_expiration_date: $billing_expiration_date, cloud_account_id: $cloud_account_id, cloud_provider_id: $cloud_provider_id, cluster_billing_model: $cluster_billing_model, cluster_id: $cluster_id, console_url: $console_url, consumer_uuid: $consumer_uuid, cpu_total: $cpu_total, creator_id: $creator_id, display_name: $display_name, external_cluster_id: $external_cluster_id, managed: $managed, organization_id: $organization_id, plan_id: $plan_id, product_bundle: $product_bundle, provenance: $provenance, region_id: $region_id, released: $released, service_level: $service_level, socket_total: $socket_total, status: $status, support_level: $support_level, system_units: $system_units, trial_end_date: $trial_end_date, usage: $usage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of labels
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}/labels
export def "accounts-mgmt-subscriptions-labels list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label or update an existing label
#
# POST /api/accounts_mgmt/v1/subscriptions/{id}/labels
export def "accounts-mgmt-subscriptions-labels post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --account-id: string
  --created-at: string # format: date-time
  --internal: oneof<nothing, bool>
  key: string
  --managed-by: string@managed-by-completer
  --organization-id: string
  --subscription-id: string
  --type: string
  --updated-at: string # format: date-time
  value: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/labels")
  let body = {href: $href, id: $body_id, kind: $kind, account_id: $account_id, created_at: $created_at, internal: $internal, key: $key, managed_by: $managed_by, organization_id: $organization_id, subscription_id: $subscription_id, type: $type, updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /api/accounts_mgmt/v1/subscriptions/{id}/labels/{key}
export def "accounts-mgmt-subscriptions-labels delete" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/labels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subscription labels by label key
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}/labels/{key}
export def "accounts-mgmt-subscriptions-labels get" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/labels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label or update an existing label
#
# PATCH /api/accounts_mgmt/v1/subscriptions/{id}/labels/{key}
export def "accounts-mgmt-subscriptions-labels patch" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --href: string
  --body-id: string
  --kind: string
  --account-id: string
  --created-at: string # format: date-time
  --internal: oneof<nothing, bool>
  --body-key: string
  --managed-by: string@managed-by-completer
  --organization-id: string
  --subscription-id: string
  --type: string
  --updated-at: string # format: date-time
  value: string
]: any -> record<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/labels/($key)")
  let body = {href: $href, id: $body_id, kind: $kind, account_id: $account_id, created_at: $created_at, internal: $internal, key: $body_key, managed_by: $managed_by, organization_id: $organization_id, subscription_id: $subscription_id, type: $type, updated_at: $updated_at, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subscription's metrics by metric name
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}/metrics/{metric_name}
export def "accounts-mgmt-subscriptions-metrics get" [
  id: string
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The `search` paramter specifies the PromQL selector. The syntax is defined by Prometheus at https://prometheus.io/docs/prometheus/latest/querying/basics/#time-series-selectors. It only supports simple selections as shown in https://prometheus.io/docs/prometheus/latest/querying/examples/#simple-time-series-selection. For example, in order to retrieve subscription_sync_total with names starting with `managed` and with a channel = `production`:  ``` name=~'managed.*',channel='production' ```  If the parameter isn't provided, or if the value is empty, then all the records will be returned.
  --qp-fields: string # Supplies a comma-separated list of fields to be returned. Fields of sub-structures and of arrays use <structure>.<field> notation. <stucture>.* means all field of a structure Example: For each Subscription to get id, href, plan(id and kind) and labels (all fields)  ``` ocm get subscriptions --parameter fields=id,href,plan.id,plan.kind,labels.* --parameter fetchLabels=true ```
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/metrics/($metric_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an ondemand metrics of a subscription by id
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}/ondemand_metrics
export def "accounts-mgmt-subscriptions-ondemand-metrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alerts: table<name: string, severity: string>, cluster_operators: table<condition: string, name: string, reason: string, time: string, version: string>, nodes: table<name: string, severity: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/ondemand_metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of reserved resources
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}/reserved_resources
export def "accounts-mgmt-subscriptions-reserved-resources list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, availability_zone_type: string, billing_marketplace_account: string, billing_model: string, byoc: bool, cluster: bool, count: int, created_at: string, resource_name: string, resource_type: string, scope: string, subscription: record, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/reserved_resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of open support creates opened against the external cluster id of this subscrption
#
# GET /api/accounts_mgmt/v1/subscriptions/{id}/support_cases
export def "accounts-mgmt-subscriptions-support-cases get" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($id)/support_cases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of notification contacts for the given subscription
#
# GET /api/accounts_mgmt/v1/subscriptions/{subId}/notification_contacts
export def "accounts-mgmt-subscriptions-notification-contacts get" [
  subId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --qp-fields: string # Supplies a comma-separated list of fields to be returned. Fields of sub-structures and of arrays use <structure>.<field> notation. <stucture>.* means all field of a structure Example: For each Subscription to get id, href, plan(id and kind) and labels (all fields)  ``` ocm get subscriptions --parameter fields=id,href,plan.id,plan.kind,labels.* --parameter fetchLabels=true ```
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: list, created_at: string, email: string, first_name: string, labels: list, last_name: string, organization: record, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/notification_contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an account as a notification contact to this subscription
#
# POST /api/accounts_mgmt/v1/subscriptions/{subId}/notification_contacts
export def "accounts-mgmt-subscriptions-notification-contacts post" [
  subId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-identifier: string
]: any -> record<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: table<href: string, id: string, kind: string, inherited: bool, name: string, value: string>, created_at: string, email: string, first_name: string, labels: table<href: string, id: string, kind: string, account_id: string, created_at: string, internal: bool, key: string, managed_by: string, organization_id: string, subscription_id: string, type: string, updated_at: string, value: string>, last_name: string, organization: record<href: string, id: string, kind: string, capabilities: list<record>, created_at: string, ebs_account_id: string, external_id: string, labels: list<record>, name: string, updated_at: string>, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/notification_contacts")
  let body = {account_identifier: $account_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a notification contact by subscription and account id
#
# DELETE /api/accounts_mgmt/v1/subscriptions/{subId}/notification_contacts/{accountId}
export def "accounts-mgmt-subscriptions-notification-contacts delete" [
  subId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/notification_contacts/($accountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete reserved resources by id
#
# DELETE /api/accounts_mgmt/v1/subscriptions/{subId}/reserved_resources/{reservedResourceId}
export def "accounts-mgmt-subscriptions-reserved-resources delete" [
  subId: string
  reservedResourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/reserved_resources/($reservedResourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get reserved resources by id
#
# GET /api/accounts_mgmt/v1/subscriptions/{subId}/reserved_resources/{reservedResourceId}
export def "accounts-mgmt-subscriptions-reserved-resources get" [
  subId: string
  reservedResourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, availability_zone_type: string, billing_marketplace_account: string, billing_model: string, byoc: bool, cluster: bool, count: int, created_at: string, resource_name: string, resource_type: string, scope: string, subscription: record<href: string, id: string, kind: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/reserved_resources/($reservedResourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a reserved resource
#
# PATCH /api/accounts_mgmt/v1/subscriptions/{subId}/reserved_resources/{reservedResourceId}
export def "accounts-mgmt-subscriptions-reserved-resources patch" [
  subId: string
  reservedResourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-model: string@billing-model-completer
  --scope: string
]: any -> record<href: string, id: string, kind: string, availability_zone_type: string, billing_marketplace_account: string, billing_model: string, byoc: bool, cluster: bool, count: int, created_at: string, resource_name: string, resource_type: string, scope: string, subscription: record<href: string, id: string, kind: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/reserved_resources/($reservedResourceId)")
  let body = {billing_model: $billing_model, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subscription role bindings
#
# GET /api/accounts_mgmt/v1/subscriptions/{subId}/role_bindings
export def "accounts-mgmt-subscriptions-role-bindings list" [
  subId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of record list when record list exceeds specified page size (default: 1)
  --size: int # Maximum number of records to return (default: 100)
  --search: string # Specifies the search criteria. The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, using the names of the json attributes / column names of the account. For example, in order to retrieve all the accounts with a username starting with `my`:  ```sql username like 'my%' ```  > **Important Note**: Account Management Service uses **KSUID** as an **ID** field. KSUID contains a timestamp component that allows them to be sorted by generation time. As this field uses an index, please use it to sort by instead of `created_at` field.  The search criteria can also be applied on related resource. For example, in order to retrieve all the subscriptions labeled by `foo=bar`,  ```sql labels.key = 'foo' and labels.value = 'bar' ```  If the parameter isn't provided, or if the value is empty, then all the accounts that the user has permission to see will be returned.
  --orderBy: string # Specifies the order by criteria. The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the json attributes / column of the account. For example, in order to retrieve all accounts ordered by username:  ```sql username asc ```  Or in order to retrieve all accounts ordered by username _and_ first name:  ```sql username asc, firstName asc ```  If the parameter isn't provided, or if the value is empty, then no explicit ordering will be applied.
  --fetchAccounts: oneof<nothing, bool> # If true, includes the account reference information in the output. Could slow request response time.
]: nothing -> record<kind: string, page: int, size: int, total: int, items: table<href: string, id: string, kind: string, account: record, account_email: string, account_username: string, created_at: string, role: record, subscription: record, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "fetchAccounts" $fetchAccounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/role_bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new subscription role binding
#
# POST /api/accounts_mgmt/v1/subscriptions/{subId}/role_bindings
export def "accounts-mgmt-subscriptions-role-bindings post" [
  subId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  role_id: string
]: any -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string, email: string, first_name: string, last_name: string, name: string, username: string>, account_email: string, account_username: string, created_at: string, role: record<href: string, id: string, kind: string>, subscription: record<href: string, id: string, kind: string>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/role_bindings")
  let body = {account_username: $account_username, role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a subscription role binding
#
# DELETE /api/accounts_mgmt/v1/subscriptions/{subId}/role_bindings/{id}
export def "accounts-mgmt-subscriptions-role-bindings delete" [
  id: string
  subId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/role_bindings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Subscription Role Binding by id
#
# GET /api/accounts_mgmt/v1/subscriptions/{subId}/role_bindings/{id}
export def "accounts-mgmt-subscriptions-role-bindings get" [
  id: string
  subId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<href: string, id: string, kind: string, account: record<href: string, id: string, kind: string, email: string, first_name: string, last_name: string, name: string, username: string>, account_email: string, account_username: string, created_at: string, role: record<href: string, id: string, kind: string>, subscription: record<href: string, id: string, kind: string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/subscriptions/($subId)/role_bindings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create a support case for the subscription
#
# POST /api/accounts_mgmt/v1/support_cases
export def "accounts-mgmt-support-cases post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-number: string
  --case-language: string
  --cluster-id: string
  --cluster-uuid: string
  --contact-sso-name: string
  description: string
  --event-stream-id: string
  --openshift-cluster-id: string
  --product: string # default: OpenShift Container Platform
  severity: string@severity-completer
  --subscription-id: string
  summary: string
  --version: string # default: 4.10
]: any -> record<caseNumber: string, cluster_id: string, cluster_uuid: string, description: string, severity: string, status: string, subscription_id: string, summary: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/support_cases")
  let body = {account_number: $account_number, case_language: $case_language, cluster_id: $cluster_id, cluster_uuid: $cluster_uuid, contact_sso_name: $contact_sso_name, description: $description, event_stream_id: $event_stream_id, openshift_cluster_id: $openshift_cluster_id, product: $product, severity: $severity, subscription_id: $subscription_id, summary: $summary, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a support case
#
# DELETE /api/accounts_mgmt/v1/support_cases/{caseId}
export def "accounts-mgmt-support-cases delete" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts_mgmt/v1/support_cases/($caseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finds the account owner of the provided token
#
# POST /api/accounts_mgmt/v1/token_authorization
export def "accounts-mgmt-token-authorization post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-token: string
]: any -> record<account: record<href: string, id: string, kind: string, ban_code: string, ban_description: string, banned: bool, capabilities: list<record>, created_at: string, email: string, first_name: string, labels: list<record>, last_name: string, organization: record<href: string, id: string, kind: string, capabilities: list, created_at: string, ebs_account_id: string, external_id: string, labels: list, name: string, updated_at: string>, organization_id: string, rhit_account_id: string, rhit_web_user_id: string, service_account: bool, updated_at: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts_mgmt/v1/token_authorization")
  let body = {authorization_token: $authorization_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review an account's access to perform an action on a particular resource or resource type
#
# POST /api/authorizations/v1/access_review
export def "authorizations-access-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  action: string@action-completer
  --cluster-id: string
  --cluster-uuid: string
  --organization-id: string
  resource_type: string@resource-type-completer-1
  --subscription-id: string
]: any -> record<account_id: string, action: string, allowed: bool, cluster_id: string, cluster_uuid: string, is_ocm_internal: bool, organization_id: string, reason: string, resource_type: string, subscription_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/access_review")
  let body = {account_username: $account_username, action: $action, cluster_id: $cluster_id, cluster_uuid: $cluster_uuid, organization_id: $organization_id, resource_type: $resource_type, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review an account's capabilities
#
# POST /api/authorizations/v1/capability_review
export def "authorizations-capability-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  capability: string@capability-completer
  --cluster-id: string
  --organization-id: string
  --subscription-id: string
  type: string@type-completer-2
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/capability_review")
  let body = {account_username: $account_username, capability: $capability, cluster_id: $cluster_id, organization_id: $organization_id, subscription_id: $subscription_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Determine whether a user is restricted from downloading Red Hat software based on export control compliance.
#
# POST /api/authorizations/v1/export_control_review
export def "authorizations-export-control-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  --ignore-cache: oneof<nothing, bool>
]: any -> record<restricted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/export_control_review")
  let body = {account_username: $account_username, ignore_cache: $ignore_cache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review feature to perform an action on it such as toggle a feature on/off
#
# POST /api/authorizations/v1/feature_review
export def "authorizations-feature-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-username: string
  --cluster-id: string
  feature: string
  --organization-id: string
]: any -> record<enabled: bool, feature_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/feature_review")
  let body = {account_username: $account_username, cluster_id: $cluster_id, feature: $feature, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Obtain resource ids for resources an account may perform the specified action upon. Resource ids returned as ["*"] is shorthand for all ids.
#
# POST /api/authorizations/v1/resource_review
# DEPRECATED
@deprecated
export def "authorizations-resource-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reduceClusterList: oneof<nothing, bool> # If true, When returning a list of cluster_ids/cluster_uuids/subscription_ids, if those are already included in one of the organizations provided in organization_ids, do not include it in the list.
  --excludeSubscriptionStatuses: string # A comma-separated list of subscription statuses. Subscriptions with these statuses will be excluded from results. This options is mutually exclusive with includeSubscriptionStatuses.
  --includeSubscriptionStatuses: string # A comma-separated list of subscription statuses. Only subscriptions with these statuses will be included into results. This options is mutually exclusive with excludeSubscriptionStatuses.
  --account-username: string
  --action: string@action-completer-1
  --resource-type: string@resource-type-completer-2
]: any -> record<account_username: string, action: string, cluster_ids: list<string>, cluster_uuids: list<string>, organization_ids: list<string>, resource_type: string, subscription_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reduceClusterList" $reduceClusterList "scalar") (serialize-qp "excludeSubscriptionStatuses" $excludeSubscriptionStatuses "scalar") (serialize-qp "includeSubscriptionStatuses" $includeSubscriptionStatuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/authorizations/v1/resource_review" $qp)
  let body = {account_username: $account_username, action: $action, resource_type: $resource_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review your ability to perform an action on a particular resource or resource type
#
# POST /api/authorizations/v1/self_access_review
export def "authorizations-self-access-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer
  --cluster-id: string
  --cluster-uuid: string
  --organization-id: string
  resource_type: string@resource-type-completer-3
  --subscription-id: string
]: any -> record<account_id: string, action: string, allowed: bool, cluster_id: string, cluster_uuid: string, is_ocm_internal: bool, organization_id: string, reason: string, resource_type: string, subscription_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/self_access_review")
  let body = {action: $action, cluster_id: $cluster_id, cluster_uuid: $cluster_uuid, organization_id: $organization_id, resource_type: $resource_type, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review your ability to toggle a feature
#
# POST /api/authorizations/v1/self_feature_review
export def "authorizations-self-feature-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: string
]: any -> record<enabled: bool, feature_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/self_feature_review")
  let body = {feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Obtain resource ids for resources you may perform the specified action upon. Resource ids returned as ["*"] is shorthand for all ids.
#
# POST /api/authorizations/v1/self_resource_review
export def "authorizations-self-resource-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reduceClusterList: oneof<nothing, bool> # If true, When returning a list of cluster_ids/cluster_uuids/subscription_ids, if those are already included in one of the organizations provided in organization_ids, do not include it in the list.
  --excludeSubscriptionStatuses: string # A comma-separated list of subscription statuses. Subscriptions with these statuses will be excluded from results. This options is mutually exclusive with includeSubscriptionStatuses.
  --includeSubscriptionStatuses: string # A comma-separated list of subscription statuses. Only subscriptions with these statuses will be included into results. This options is mutually exclusive with excludeSubscriptionStatuses.
  --action: string@action-completer-1
  --resource-type: string@resource-type-completer-2
]: any -> record<action: string, cluster_ids: list<string>, cluster_uuids: list<string>, organization_ids: list<string>, resource_type: string, subscription_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reduceClusterList" $reduceClusterList "scalar") (serialize-qp "excludeSubscriptionStatuses" $excludeSubscriptionStatuses "scalar") (serialize-qp "includeSubscriptionStatuses" $includeSubscriptionStatuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/authorizations/v1/self_resource_review" $qp)
  let body = {action: $action, resource_type: $resource_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review your status of Terms
#
# POST /api/authorizations/v1/self_terms_review
export def "authorizations-self-terms-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-optional-terms: oneof<nothing, bool> # default: true
  --event-code: string
  --site-code: string
]: any -> record<account_id: string, organization_id: string, redirect_url: string, terms_available: bool, terms_required: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/self_terms_review")
  let body = {check_optional_terms: $check_optional_terms, event_code: $event_code, site_code: $site_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Review an account's status of Terms
#
# POST /api/authorizations/v1/terms_review
export def "authorizations-terms-review post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_username: string
  --check-optional-terms: oneof<nothing, bool> # default: true
  --event-code: string
  --site-code: string
]: any -> record<account_id: string, organization_id: string, redirect_url: string, terms_available: bool, terms_required: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/authorizations/v1/terms_review")
  let body = {account_username: $account_username, check_optional_terms: $check_optional_terms, event_code: $event_code, site_code: $site_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
