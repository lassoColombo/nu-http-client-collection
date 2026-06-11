# Auto-generated client for clusters_mgmt vv1
# Source: https://api.openshift.com/api/clusters_mgmt/v1/openapi
# Auth: --token flag or $env.CLUSTERS_MGMT_TOKEN

const BASE_URL = "https://api.openshift.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLUSTERS_MGMT_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.openshift.com" "https://api.stage.openshift.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def install-mode-completer [] { ["all_namespaces" "own_namespace"] }
def ec2-metadata-http-tokens-completer [] { ["optional" "required"] }
def billing-model-completer [] { ["marketplace" "marketplace-aws" "marketplace-azure" "marketplace-gcp" "marketplace-rhm" "standard"] }
def health-state-completer [] { ["healthy" "unhealthy" "unknown"] }
def state-completer [] { ["error" "hibernating" "installing" "pending" "powering_down" "ready" "resuming" "uninstalling" "unknown" "updating" "validating" "waiting"] }
def value-completer [] { ["cancelled" "completed" "delayed" "failed" "pending" "scheduled" "started"] }
def state-completer-1 [] { ["deleting" "failed" "installing" "pending" "ready"] }
def state-completer-2 [] { ["deleting" "failed" "pending" "ready" "removed"] }
def status-completer [] { ["awaiting_revocation" "created" "expired" "failed" "issued" "revoked"] }
def schedule-type-completer [] { ["automatic" "manual"] }
def upgrade-type-completer [] { ["ADDON" "ControlPlane" "ControlPlaneCVE" "NodePool" "OSD"] }
def mapping-method-completer [] { ["add" "claim" "generate" "lookup"] }
def type-completer [] { ["GithubIdentityProvider" "GitlabIdentityProvider" "GoogleIdentityProvider" "HTPasswdIdentityProvider" "LDAPIdentityProvider" "OpenIDIdentityProvider"] }
def listening-completer [] { ["external" "internal"] }
def load-balancer-type-completer [] { ["classic" "nlb"] }
def route-namespace-ownership-policy-completer [] { ["InterNamespaceAllowed" "Strict"] }
def route-wildcard-policy-completer [] { ["WildcardsAllowed" "WildcardsDisallowed"] }
def detection-type-completer [] { ["auto" "manual"] }
def type-completer-1 [] { ["sdnToOvn"] }
def image-type-completer [] { ["Default" "Windows"] }
def cloud-provider-completer [] { ["aws" "gcp"] }
def cluster-arch-completer [] { ["classic" "hcp"] }
def platform-completer [] { ["aws" "aws-classic" "aws-hosted-cp" "gcp" "hostedcluster"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "clusters-mgmt get" } } | get name | first)
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

# Retrieves the version metadata.
#
# GET /api/clusters_mgmt/v1
export def "clusters-mgmt get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<server_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new add-on and add it to the collection of add-ons.
#
# POST /api/clusters_mgmt/v1/addons
# --config shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
# --credentials_requests item shape: {name?: string, namespace?: string, policy_permissions?: list, service_account?: string}
# --namespaces item shape: {kind?: string, id?: string, href?: string, annotations?: record, labels?: record, name?: string}
# --parameters item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
# --requirements item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
# --sub_operators item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
# --version shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
export def "clusters-mgmt-addons post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddOn' if this is a complete object or 'AddOnLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --common-annotations: record # Common annotations to be applied to all resources created by this addon.
  --common-labels: record # Common labels to be applied to all resources created by this addon.
  --config: any # Representation of an add-on config. The attributes under it are to be used by the addon once its installed in the cluster. — shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
  --credentials-requests: list # List of credentials requests to authenticate operators to access cloud resources. — item shape: {name?: string, namespace?: string, policy_permissions?: list, service_account?: string}
  --description: string # Description of the add-on.
  --docs-link: string # Link to documentation about the add-on.
  --enabled: string@bool-completer # Indicates if this add-on can be added to clusters.
  --has-external-resources: string@bool-completer # Indicates if this add-on has external resources associated with it
  --hidden: string@bool-completer # Indicates if this add-on is hidden.
  --icon: string # Base64-encoded icon representing an add-on. The icon should be in PNG format.
  --install-mode: string@install-mode-completer # Representation of an add-on InstallMode field.
  --label: string # Label used to attach to a cluster deployment when add-on is installed.
  --managed-service: string@bool-completer # Indicates if add-on is part of a managed service
  --name: string # Name of the add-on.
  --namespaces: list # Namespaces which are required by this addon. — item shape: {kind?: string, id?: string, href?: string, annotations?: record, labels?: record, name?: string}
  --operator-name: string # The name of the operator installed by this add-on.
  --parameters: list # List of parameters for this add-on. — item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
  --requirements: list # List of requirements for this add-on. — item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
  --resource-cost: float # Used to determine how many units of quota an add-on consumes per resource name. (format: float)
  --resource-name: string # Used to determine from where to reserve quota for this add-on.
  --sub-operators: list # List of sub operators for this add-on. — item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
  --target-namespace: string # The namespace in which the addon CRD exists.
  --version: any # Representation of an add-on version. — shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
]: any -> record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, credentials_requests: table<name: string, namespace: string, policy_permissions: list, service_account: string>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: table<kind: string, id: string, href: string, annotations: record, labels: record, name: string>, operator_name: string, parameters: table<kind: string, id: string, href: string, addon: any, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, resource_cost: float, resource_name: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/addons")
  let body = {kind: $kind, id: $id, href: $href, common_annotations: $common_annotations, common_labels: $common_labels, config: $config, credentials_requests: $credentials_requests, description: $description, docs_link: $docs_link, enabled: $enabled, has_external_resources: $has_external_resources, hidden: $hidden, icon: $icon, install_mode: $install_mode, label: $label, managed_service: $managed_service, name: $name, namespaces: $namespaces, operator_name: $operator_name, parameters: $parameters, requirements: $requirements, resource_cost: $resource_cost, resource_name: $resource_name, sub_operators: $sub_operators, target_namespace: $target_namespace, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of add-ons.
#
# GET /api/clusters_mgmt/v1/addons
export def "clusters-mgmt-addons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the add-on instead of the names of the columns of a table. For example, in order to sort the add-ons descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the add-on instead of the names of the columns of a table. For example, in order to retrieve all the add-ons with a name starting with `my` the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the add-ons that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record, credentials_requests: list, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: list, operator_name: string, parameters: list, requirements: list, resource_cost: float, resource_name: string, sub_operators: list, target_namespace: string, version: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/addons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the add-on.
#
# DELETE /api/clusters_mgmt/v1/addons/{addon_id}
export def "clusters-mgmt-addons delete" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the add-on.
#
# GET /api/clusters_mgmt/v1/addons/{addon_id}
export def "clusters-mgmt-addons get" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, credentials_requests: table<name: string, namespace: string, policy_permissions: list, service_account: string>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: table<kind: string, id: string, href: string, annotations: record, labels: record, name: string>, operator_name: string, parameters: table<kind: string, id: string, href: string, addon: any, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, resource_cost: float, resource_name: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the add-on.
#
# PATCH /api/clusters_mgmt/v1/addons/{addon_id}
# --config shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
# --credentials_requests item shape: {name?: string, namespace?: string, policy_permissions?: list, service_account?: string}
# --namespaces item shape: {kind?: string, id?: string, href?: string, annotations?: record, labels?: record, name?: string}
# --parameters item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
# --requirements item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
# --sub_operators item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
# --version shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
export def "clusters-mgmt-addons patch" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddOn' if this is a complete object or 'AddOnLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --common-annotations: record # Common annotations to be applied to all resources created by this addon.
  --common-labels: record # Common labels to be applied to all resources created by this addon.
  --config: any # Representation of an add-on config. The attributes under it are to be used by the addon once its installed in the cluster. — shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
  --credentials-requests: list # List of credentials requests to authenticate operators to access cloud resources. — item shape: {name?: string, namespace?: string, policy_permissions?: list, service_account?: string}
  --description: string # Description of the add-on.
  --docs-link: string # Link to documentation about the add-on.
  --enabled: string@bool-completer # Indicates if this add-on can be added to clusters.
  --has-external-resources: string@bool-completer # Indicates if this add-on has external resources associated with it
  --hidden: string@bool-completer # Indicates if this add-on is hidden.
  --icon: string # Base64-encoded icon representing an add-on. The icon should be in PNG format.
  --install-mode: string@install-mode-completer # Representation of an add-on InstallMode field.
  --label: string # Label used to attach to a cluster deployment when add-on is installed.
  --managed-service: string@bool-completer # Indicates if add-on is part of a managed service
  --name: string # Name of the add-on.
  --namespaces: list # Namespaces which are required by this addon. — item shape: {kind?: string, id?: string, href?: string, annotations?: record, labels?: record, name?: string}
  --operator-name: string # The name of the operator installed by this add-on.
  --parameters: list # List of parameters for this add-on. — item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
  --requirements: list # List of requirements for this add-on. — item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
  --resource-cost: float # Used to determine how many units of quota an add-on consumes per resource name. (format: float)
  --resource-name: string # Used to determine from where to reserve quota for this add-on.
  --sub-operators: list # List of sub operators for this add-on. — item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
  --target-namespace: string # The namespace in which the addon CRD exists.
  --version: any # Representation of an add-on version. — shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
]: any -> record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, credentials_requests: table<name: string, namespace: string, policy_permissions: list, service_account: string>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: table<kind: string, id: string, href: string, annotations: record, labels: record, name: string>, operator_name: string, parameters: table<kind: string, id: string, href: string, addon: any, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, resource_cost: float, resource_name: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)")
  let body = {kind: $kind, id: $id, href: $href, common_annotations: $common_annotations, common_labels: $common_labels, config: $config, credentials_requests: $credentials_requests, description: $description, docs_link: $docs_link, enabled: $enabled, has_external_resources: $has_external_resources, hidden: $hidden, icon: $icon, install_mode: $install_mode, label: $label, managed_service: $managed_service, name: $name, namespaces: $namespaces, operator_name: $operator_name, parameters: $parameters, requirements: $requirements, resource_cost: $resource_cost, resource_name: $resource_name, sub_operators: $sub_operators, target_namespace: $target_namespace, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new add-on version and add it to the collection of add-ons.
#
# POST /api/clusters_mgmt/v1/addons/{addon_id}/versions
# --additional_catalog_sources item shape: {id?: string, enabled?: bool, image?: string, name?: string}
# --config shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
# --parameters item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
# --requirements item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
# --sub_operators item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
export def "clusters-mgmt-addons-versions post" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddOnVersion' if this is a complete object or 'AddOnVersionLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --additional-catalog-sources: list # Additional catalog sources associated with this addon version — item shape: {id?: string, enabled?: bool, image?: string, name?: string}
  --available-upgrades: list # AvailableUpgrades is the list of versions this version can be upgraded to.
  --channel: string # The specific addon catalog source channel of packages
  --config: any # Representation of an add-on config. The attributes under it are to be used by the addon once its installed in the cluster. — shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
  --enabled: string@bool-completer # Indicates if this add-on version can be added to clusters.
  --package-image: string # The package image for this addon version
  --parameters: list # List of parameters for this add-on version. — item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
  --pull-secret-name: string # The pull secret name used for this addon version.
  --requirements: list # List of requirements for this add-on version. — item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
  --source-image: string # The catalog source image for this add-on version.
  --sub-operators: list # List of sub operators for this add-on version. — item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
]: any -> record<kind: string, id: string, href: string, additional_catalog_sources: table<id: string, enabled: bool, image: string, name: string>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, enabled: bool, package_image: string, parameters: table<kind: string, id: string, href: string, addon: record, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, pull_secret_name: string, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, source_image: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)/versions")
  let body = {kind: $kind, id: $id, href: $href, additional_catalog_sources: $additional_catalog_sources, available_upgrades: $available_upgrades, channel: $channel, config: $config, enabled: $enabled, package_image: $package_image, parameters: $parameters, pull_secret_name: $pull_secret_name, requirements: $requirements, source_image: $source_image, sub_operators: $sub_operators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of add-on versions.
#
# GET /api/clusters_mgmt/v1/addons/{addon_id}/versions
export def "clusters-mgmt-addons-versions list" [
  addon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the add-on instead of the names of the columns of a table. For example, in order to sort the add-on versions descending by id the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the add-on version instead of the names of the columns of a table. For example, in order to retrieve all the add-on versions with an id starting with `0.1` the value should be:  ```sql id like '0.1.%' ```  If the parameter isn't provided, or if the value is empty, then all the add-on versions that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, additional_catalog_sources: list, available_upgrades: list, channel: string, config: record, enabled: bool, package_image: string, parameters: list, pull_secret_name: string, requirements: list, source_image: string, sub_operators: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the add-on version.
#
# DELETE /api/clusters_mgmt/v1/addons/{addon_id}/versions/{version_id}
export def "clusters-mgmt-addons-versions delete" [
  addon_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the add-on version.
#
# GET /api/clusters_mgmt/v1/addons/{addon_id}/versions/{version_id}
export def "clusters-mgmt-addons-versions get" [
  addon_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, additional_catalog_sources: table<id: string, enabled: bool, image: string, name: string>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, enabled: bool, package_image: string, parameters: table<kind: string, id: string, href: string, addon: record, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, pull_secret_name: string, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, source_image: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the add-on version.
#
# PATCH /api/clusters_mgmt/v1/addons/{addon_id}/versions/{version_id}
# --additional_catalog_sources item shape: {id?: string, enabled?: bool, image?: string, name?: string}
# --config shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
# --parameters item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
# --requirements item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
# --sub_operators item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
export def "clusters-mgmt-addons-versions patch" [
  addon_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddOnVersion' if this is a complete object or 'AddOnVersionLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --additional-catalog-sources: list # Additional catalog sources associated with this addon version — item shape: {id?: string, enabled?: bool, image?: string, name?: string}
  --available-upgrades: list # AvailableUpgrades is the list of versions this version can be upgraded to.
  --channel: string # The specific addon catalog source channel of packages
  --config: any # Representation of an add-on config. The attributes under it are to be used by the addon once its installed in the cluster. — shape: {kind?: string, id?: string, href?: string, add_on_environment_variables?: list, secret_propagations?: list}
  --enabled: string@bool-completer # Indicates if this add-on version can be added to clusters.
  --package-image: string # The package image for this addon version
  --parameters: list # List of parameters for this add-on version. — item shape: {kind?: string, id?: string, href?: string, addon?: any, conditions?: list, default_value?: string, description?: string, editable?: bool, editable_direction?: string, enabled?: bool, name?: string, options?: list, required?: bool, validation?: string, validation_err_msg?: string, value_type?: string}
  --pull-secret-name: string # The pull secret name used for this addon version.
  --requirements: list # List of requirements for this add-on version. — item shape: {id?: string, data?: record, enabled?: bool, resource?: string, status?: any}
  --source-image: string # The catalog source image for this add-on version.
  --sub-operators: list # List of sub operators for this add-on version. — item shape: {enabled?: bool, operator_name?: string, operator_namespace?: string}
]: any -> record<kind: string, id: string, href: string, additional_catalog_sources: table<id: string, enabled: bool, image: string, name: string>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, enabled: bool, package_image: string, parameters: table<kind: string, id: string, href: string, addon: record, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, pull_secret_name: string, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, source_image: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/addons/($addon_id)/versions/($version_id)")
  let body = {kind: $kind, id: $id, href: $href, additional_catalog_sources: $additional_catalog_sources, available_upgrades: $available_upgrades, channel: $channel, config: $config, enabled: $enabled, package_image: $package_image, parameters: $parameters, pull_secret_name: $pull_secret_name, requirements: $requirements, source_image: $source_image, sub_operators: $sub_operators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/aws_infrastructure_access_roles
export def "clusters-mgmt-aws-infrastructure-access-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the role instead of the names of the columns of a table. For example, in order to sort the roles descending by dislay_name the value should be:  ```sql display_name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the role instead of the names of the columns of a table. For example, in order to retrieve all the role with a name starting with `my`the value should be:  ```sql display_name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the roles that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, description: string, display_name: string, state: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_infrastructure_access_roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the aws infrastructure access role.
#
# GET /api/clusters_mgmt/v1/aws_infrastructure_access_roles/{aws_infrastructure_access_role_id}
export def "clusters-mgmt-aws-infrastructure-access-roles get" [
  aws_infrastructure_access_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, description: string, display_name: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/aws_infrastructure_access_roles/($aws_infrastructure_access_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of machine types in the provided region.
#
# POST /api/clusters_mgmt/v1/aws_inquiries/machine_types
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-aws-inquiries-machine-types post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/machine_types" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetches/creates an OIDC Config Thumbprint from either a cluster ID, or an oidc config ID.
#
# POST /api/clusters_mgmt/v1/aws_inquiries/oidc_thumbprint
export def "clusters-mgmt-aws-inquiries-oidc-thumbprint post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster-id: string # ClusterId is the for the cluster used, exclusive from OidcConfigId.
  --oidc-config-id: string # OidcConfigId is the ID for the oidc config used, exclusive from ClusterId.
]: any -> record<href: string, cluster_id: string, kind: string, oidc_config_id: string, thumbprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/oidc_thumbprint")
  let body = {cluster_id: $cluster_id, oidc_config_id: $oidc_config_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of available regions of the cloud provider. IMPORTANT: This list doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available regions of the provider.
#
# POST /api/clusters_mgmt/v1/aws_inquiries/regions
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-aws-inquiries-regions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of regions of the provider. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/regions" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/clusters_mgmt/v1/aws_inquiries/sts_account_roles
#
# --sts shape: {oidc_endpoint_url?: string, auto_mode?: bool, enabled?: bool, external_id?: string, instance_iam_roles?: any, managed_policies?: bool, oidc_config?: any, operator_iam_roles?: list, operator_role_prefix?: string, permission_boundary?: string, role_arn?: string, support_role_arn?: string}
# --audit_log shape: {role_arn?: string}
# --auto_node shape: {role_arn?: string}
# --etcd_encryption shape: {kms_key_arn?: string}
# --private_link_configuration shape: {principals?: list}
# --zero_egress shape: {enabled?: bool, no_proxy_default_domains?: list}
export def "clusters-mgmt-aws-inquiries-sts-account-roles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of be the total number of STS account roles. (format: int32)
  --kms-key-arn: string # Customer Managed Key to encrypt EBS Volume
  --sts: any # Contains the necessary attributes to support role-based authentication on AWS. — shape: {oidc_endpoint_url?: string, auto_mode?: bool, enabled?: bool, external_id?: string, instance_iam_roles?: any, managed_policies?: bool, oidc_config?: any, operator_iam_roles?: list, operator_role_prefix?: string, permission_boundary?: string, role_arn?: string, support_role_arn?: string}
  --access-key-id: string # AWS access key identifier.
  --account-id: string # AWS account identifier.
  --additional-allowed-principals: list # Additional allowed principal ARNs to be added to the hosted control plane's VPC Endpoint Service.
  --additional-compute-security-group-ids: list # Additional AWS Security Groups to be added to default worker (compute) machine pool.
  --additional-control-plane-security-group-ids: list # Additional AWS Security Groups to be added to default control plane machine pool.
  --additional-infra-security-group-ids: list # Additional AWS Security Groups to be added to default infra machine pool.
  --audit-log: any # Contains the necessary attributes to support audit log forwarding — shape: {role_arn?: string}
  --auto-node: any # AWS provider configuration settings when using AutoNode on a ROSA HCP Cluster — shape: {role_arn?: string}
  --billing-account-id: string # BillingAccountID is the account used for billing subscriptions purchased via the marketplace
  --ec2-metadata-http-tokens: string@ec2-metadata-http-tokens-completer # Which Ec2MetadataHttpTokens to use for metadata service interaction options for EC2 instances
  --etcd-encryption: any # Contains the necessary attributes to support etcd encryption for AWS based clusters. — shape: {kms_key_arn?: string}
  --hcp-internal-communication-hosted-zone-id: string # ID of local private hosted zone for hypershift internal communication.
  --private-hosted-zone-id: string # ID of private hosted zone.
  --private-hosted-zone-role-arn: string # Role ARN for private hosted zone.
  --private-link: string@bool-completer # Sets cluster to be inaccessible externally.
  --private-link-configuration: any # Manages the configuration for the Private Links. — shape: {principals?: list}
  --secret-access-key: string # AWS secret access key.
  --subnet-ids: list # The subnet ids to be used when installing the cluster.
  --tags: record # Optional keys and values that the installer will add as tags to all AWS resources it creates
  --vpc-endpoint-role-arn: string # Role ARN for VPC Endpoint Service cross account role.
  --zero-egress: any # Zero egress configuration. — shape: {enabled?: bool, no_proxy_default_domains?: list}
]: any -> record<aws_account_id: string, items: table<items: list, prefix: string>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/sts_account_roles" $qp)
  let body = {kms_key_arn: $kms_key_arn, sts: $sts, access_key_id: $access_key_id, account_id: $account_id, additional_allowed_principals: $additional_allowed_principals, additional_compute_security_group_ids: $additional_compute_security_group_ids, additional_control_plane_security_group_ids: $additional_control_plane_security_group_ids, additional_infra_security_group_ids: $additional_infra_security_group_ids, audit_log: $audit_log, auto_node: $auto_node, billing_account_id: $billing_account_id, ec2_metadata_http_tokens: $ec2_metadata_http_tokens, etcd_encryption: $etcd_encryption, hcp_internal_communication_hosted_zone_id: $hcp_internal_communication_hosted_zone_id, private_hosted_zone_id: $private_hosted_zone_id, private_hosted_zone_role_arn: $private_hosted_zone_role_arn, private_link: $private_link, private_link_configuration: $private_link_configuration, secret_access_key: $secret_access_key, subnet_ids: $subnet_ids, tags: $tags, vpc_endpoint_role_arn: $vpc_endpoint_role_arn, zero_egress: $zero_egress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of policies.
#
# GET /api/clusters_mgmt/v1/aws_inquiries/sts_credential_requests
export def "clusters-mgmt-aws-inquiries-sts-credential-requests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<name: string, operator: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/sts_credential_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of policies.
#
# GET /api/clusters_mgmt/v1/aws_inquiries/sts_policies
export def "clusters-mgmt-aws-inquiries-sts-policies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the awsstspolicies instead of the names of the columns of a table. For example, in order to sort the policies descending by operator type identifier the value should be:  ```sql orderBy id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the awsstspolicies instead of the names of the columns of a table. For example, in order to retrieve all the policies of type  `operatorrole` should be:  ```sql policy_type like 'OperatorRole%' ```  If the parameter isn't provided, or if the value is empty, then all the policies  will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<arn: string, id: string, details: string, type: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/sts_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manages aws creds validation.
#
# POST /api/clusters_mgmt/v1/aws_inquiries/validate_credentials
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-aws-inquiries-validate-credentials post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<aws: record<kms_key_arn: string, sts: record<oidc_endpoint_url: string, auto_mode: bool, enabled: bool, external_id: string, instance_iam_roles: record, managed_policies: bool, oidc_config: record, operator_iam_roles: list, operator_role_prefix: string, permission_boundary: string, role_arn: string, support_role_arn: string>, access_key_id: string, account_id: string, additional_allowed_principals: list<string>, additional_compute_security_group_ids: list<string>, additional_control_plane_security_group_ids: list<string>, additional_infra_security_group_ids: list<string>, audit_log: record<role_arn: string>, auto_node: record<role_arn: string>, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record<kms_key_arn: string>, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record<principals: list>, secret_access_key: string, subnet_ids: list<string>, tags: record, vpc_endpoint_role_arn: string, zero_egress: record<enabled: bool, no_proxy_default_domains: list>>, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record<href: string, id: string, kind: string>, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record<service_attachment_subnet: string>, project_id: string, security: record<secure_boot: bool>, token_uri: string, type: string>, availability_zones: list<string>, key_location: string, key_ring_name: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, subnets: list<string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>, vpc_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/validate_credentials")
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of available vpcs of the cloud provider for specific region. IMPORTANT: This collection doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available vpcs of the provider.
#
# POST /api/clusters_mgmt/v1/aws_inquiries/vpcs
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-aws-inquiries-vpcs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of vpcs of the provider. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<aws_security_groups: list, aws_subnets: list, cidr_block: string, id: string, name: string, red_hat_managed: bool, subnets: list>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/aws_inquiries/vpcs" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of cloud providers.
#
# GET /api/clusters_mgmt/v1/cloud_providers
export def "clusters-mgmt-cloud-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fetchRegions: string@bool-completer # If true, includes the regions on each provider in the output. Could slow request response time.
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the cloud provider instead of the names of the columns of a table. For example, in order to sort the clusters descending by name identifier the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the cloud provider instead of the names of the columns of a table. For example, in order to retrieve all the cloud providers with a name starting with `A` the value should be:  ```sql name like 'A%' ```  If the parameter isn't provided, or if the value is empty, then all the clusters that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetchRegions" $fetchRegions "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/cloud_providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the cloud provider.
#
# GET /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}
export def "clusters-mgmt-cloud-providers get" [
  cloud_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, display_name: string, name: string, regions: table<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: any, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of available regions of the cloud provider.  IMPORTANT: This collection doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available regions of the provider.
#
# POST /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}/available_regions
# --sts shape: {oidc_endpoint_url?: string, auto_mode?: bool, enabled?: bool, external_id?: string, instance_iam_roles?: any, managed_policies?: bool, oidc_config?: any, operator_iam_roles?: list, operator_role_prefix?: string, permission_boundary?: string, role_arn?: string, support_role_arn?: string}
# --audit_log shape: {role_arn?: string}
# --auto_node shape: {role_arn?: string}
# --etcd_encryption shape: {kms_key_arn?: string}
# --private_link_configuration shape: {principals?: list}
# --zero_egress shape: {enabled?: bool, no_proxy_default_domains?: list}
export def "clusters-mgmt-cloud-providers-available-regions post" [
  cloud_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of regions of the provider. (format: int32)
  --kms-key-arn: string # Customer Managed Key to encrypt EBS Volume
  --sts: any # Contains the necessary attributes to support role-based authentication on AWS. — shape: {oidc_endpoint_url?: string, auto_mode?: bool, enabled?: bool, external_id?: string, instance_iam_roles?: any, managed_policies?: bool, oidc_config?: any, operator_iam_roles?: list, operator_role_prefix?: string, permission_boundary?: string, role_arn?: string, support_role_arn?: string}
  --access-key-id: string # AWS access key identifier.
  --account-id: string # AWS account identifier.
  --additional-allowed-principals: list # Additional allowed principal ARNs to be added to the hosted control plane's VPC Endpoint Service.
  --additional-compute-security-group-ids: list # Additional AWS Security Groups to be added to default worker (compute) machine pool.
  --additional-control-plane-security-group-ids: list # Additional AWS Security Groups to be added to default control plane machine pool.
  --additional-infra-security-group-ids: list # Additional AWS Security Groups to be added to default infra machine pool.
  --audit-log: any # Contains the necessary attributes to support audit log forwarding — shape: {role_arn?: string}
  --auto-node: any # AWS provider configuration settings when using AutoNode on a ROSA HCP Cluster — shape: {role_arn?: string}
  --billing-account-id: string # BillingAccountID is the account used for billing subscriptions purchased via the marketplace
  --ec2-metadata-http-tokens: string@ec2-metadata-http-tokens-completer # Which Ec2MetadataHttpTokens to use for metadata service interaction options for EC2 instances
  --etcd-encryption: any # Contains the necessary attributes to support etcd encryption for AWS based clusters. — shape: {kms_key_arn?: string}
  --hcp-internal-communication-hosted-zone-id: string # ID of local private hosted zone for hypershift internal communication.
  --private-hosted-zone-id: string # ID of private hosted zone.
  --private-hosted-zone-role-arn: string # Role ARN for private hosted zone.
  --private-link: string@bool-completer # Sets cluster to be inaccessible externally.
  --private-link-configuration: any # Manages the configuration for the Private Links. — shape: {principals?: list}
  --secret-access-key: string # AWS secret access key.
  --subnet-ids: list # The subnet ids to be used when installing the cluster.
  --tags: record # Optional keys and values that the installer will add as tags to all AWS resources it creates
  --vpc-endpoint-role-arn: string # Role ARN for VPC Endpoint Service cross account role.
  --zero-egress: any # Zero egress configuration. — shape: {enabled?: bool, no_proxy_default_domains?: list}
]: any -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)/available_regions" $qp)
  let body = {kms_key_arn: $kms_key_arn, sts: $sts, access_key_id: $access_key_id, account_id: $account_id, additional_allowed_principals: $additional_allowed_principals, additional_compute_security_group_ids: $additional_compute_security_group_ids, additional_control_plane_security_group_ids: $additional_control_plane_security_group_ids, additional_infra_security_group_ids: $additional_infra_security_group_ids, audit_log: $audit_log, auto_node: $auto_node, billing_account_id: $billing_account_id, ec2_metadata_http_tokens: $ec2_metadata_http_tokens, etcd_encryption: $etcd_encryption, hcp_internal_communication_hosted_zone_id: $hcp_internal_communication_hosted_zone_id, private_hosted_zone_id: $private_hosted_zone_id, private_hosted_zone_role_arn: $private_hosted_zone_role_arn, private_link: $private_link, private_link_configuration: $private_link_configuration, secret_access_key: $secret_access_key, subnet_ids: $subnet_ids, tags: $tags, vpc_endpoint_role_arn: $vpc_endpoint_role_arn, zero_egress: $zero_egress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a cloud region to the database.
#
# POST /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}/regions
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
export def "clusters-mgmt-cloud-providers-regions post" [
  cloud_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'CloudRegion' if this is a complete object or 'CloudRegionLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --ccs-only: string@bool-completer # 'true' if the region is supported only for CCS clusters, 'false' otherwise.
  --kms-location-id: string # (GCP only) Comma-separated list of KMS location IDs that can be used with this region. E.g. "global,nam4,us". Order is not guaranteed.
  --kms-location-name: string # (GCP only) Comma-separated list of display names corresponding to KMSLocationID. E.g. "Global,nam4 (Iowa, South Carolina, and Oklahoma),US". Order is not guaranteed but will match KMSLocationID. Unfortunately, this API doesn't allow robust splitting - Contact ocm-feedback@redhat.com if you want to rely on this.
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --display-name: string # Name of the region for display purposes, for example `N. Virginia`.
  --enabled: string@bool-completer # Whether the region is enabled for deploying a managed cluster.
  --govcloud: string@bool-completer # Whether the region is an AWS GovCloud region.
  --name: string # Human friendly identifier of the region, for example `us-east-1`.  NOTE: Currently for all cloud providers and all regions `id` and `name` have exactly the same values.
  --supports-hypershift: string@bool-completer # 'true' if the region is supported for Hypershift deployments, 'false' otherwise.
  --supports-multi-az: string@bool-completer # Whether the region supports multiple availability zones.
]: any -> record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<any>>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)/regions")
  let body = {kind: $kind, id: $id, href: $href, ccs_only: $ccs_only, kms_location_id: $kms_location_id, kms_location_name: $kms_location_name, cloud_provider: $cloud_provider, display_name: $display_name, enabled: $enabled, govcloud: $govcloud, name: $name, supports_hypershift: $supports_hypershift, supports_multi_az: $supports_multi_az} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of regions of the cloud provider.  IMPORTANT: This collection doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of regions of the provider.
#
# GET /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}/regions
export def "clusters-mgmt-cloud-providers-regions list" [
  cloud_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of regions of the provider. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the region.
#
# DELETE /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}/regions/{region_id}
export def "clusters-mgmt-cloud-providers-regions delete" [
  cloud_provider_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)/regions/($region_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the region.
#
# GET /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}/regions/{region_id}
export def "clusters-mgmt-cloud-providers-regions get" [
  cloud_provider_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<any>>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)/regions/($region_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the region.
#
# PATCH /api/clusters_mgmt/v1/cloud_providers/{cloud_provider_id}/regions/{region_id}
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
export def "clusters-mgmt-cloud-providers-regions patch" [
  cloud_provider_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'CloudRegion' if this is a complete object or 'CloudRegionLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --ccs-only: string@bool-completer # 'true' if the region is supported only for CCS clusters, 'false' otherwise.
  --kms-location-id: string # (GCP only) Comma-separated list of KMS location IDs that can be used with this region. E.g. "global,nam4,us". Order is not guaranteed.
  --kms-location-name: string # (GCP only) Comma-separated list of display names corresponding to KMSLocationID. E.g. "Global,nam4 (Iowa, South Carolina, and Oklahoma),US". Order is not guaranteed but will match KMSLocationID. Unfortunately, this API doesn't allow robust splitting - Contact ocm-feedback@redhat.com if you want to rely on this.
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --display-name: string # Name of the region for display purposes, for example `N. Virginia`.
  --enabled: string@bool-completer # Whether the region is enabled for deploying a managed cluster.
  --govcloud: string@bool-completer # Whether the region is an AWS GovCloud region.
  --name: string # Human friendly identifier of the region, for example `us-east-1`.  NOTE: Currently for all cloud providers and all regions `id` and `name` have exactly the same values.
  --supports-hypershift: string@bool-completer # 'true' if the region is supported for Hypershift deployments, 'false' otherwise.
  --supports-multi-az: string@bool-completer # Whether the region supports multiple availability zones.
]: any -> record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<any>>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/cloud_providers/($cloud_provider_id)/regions/($region_id)")
  let body = {kind: $kind, id: $id, href: $href, ccs_only: $ccs_only, kms_location_id: $kms_location_id, kms_location_name: $kms_location_name, cloud_provider: $cloud_provider, display_name: $display_name, enabled: $enabled, govcloud: $govcloud, name: $name, supports_hypershift: $supports_hypershift, supports_multi_az: $supports_multi_az} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Provision a new cluster and add it to the collection of clusters.  See the `register_cluster` method for adding an existing cluster.
#
# POST /api/clusters_mgmt/v1/clusters
# --api shape: {cidr_block_access?: any, url?: string, listening?: "external"|"internal"}
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --aws_infrastructure_access_role_grants item shape: {kind?: string, id?: string, href?: string, console_url?: string, role?: any, state?: "deleting"|"failed"|"pending"|"ready"|"removed", state_description?: string, user_arn?: string}
# --ccs shape: {kind?: string, id?: string, href?: string, disable_scp_checks?: bool, enabled?: bool}
# --dns shape: {base_domain?: string}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --gcp_encryption_key shape: {kms_key_service_account?: string, key_location?: string, key_name?: string, key_ring?: string}
# --gcp_network shape: {vpc_name?: string, vpc_project_id?: string, compute_subnet?: string, control_plane_subnet?: string}
# --addons item shape: {kind?: string, id?: string, href?: string, addon?: any, addon_version?: any, billing?: any, creation_timestamp?: string, operator_version?: string, parameters?: list, state?: "deleting"|"failed"|"installing"|"pending"|"ready", state_description?: string, updated_timestamp?: string}
# --auto_node shape: {mode?: string, status?: any}
# --autoscaler shape: {kind?: string, id?: string, href?: string, balance_similar_node_groups?: bool, balancing_ignored_labels?: list, ignore_daemonsets_utilization?: bool, log_verbosity?: int, max_node_provision_time?: string, max_pod_grace_period?: int, pod_priority_threshold?: int, resource_limits?: any, scale_down?: any, skip_nodes_with_local_storage?: bool}
# --azure shape: {etcd_encryption?: any, managed_resource_group_name?: string, network_security_group_resource_id?: string, nodes_outbound_connectivity?: any, operators_authentication?: any, resource_group_name?: string, resource_name?: string, subnet_resource_id?: string, subscription_id?: string, tenant_id?: string}
# --byo_oidc shape: {enabled?: bool}
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
# --console shape: {url?: string}
# --control_plane shape: {backup?: any, log_forwarders?: list}
# --delete_protection shape: {enabled?: bool}
# --external_auth_config shape: {kind?: string, id?: string, href?: string, enabled?: bool, external_auths?: list, state?: "disabled"|"enabled"}
# --external_configuration shape: {labels?: list, manifests?: list, syncsets?: list}
# --flavour shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, name?: string, network?: any, nodes?: any}
# --groups item shape: {kind?: string, id?: string, href?: string, users?: list}
# --htpasswd shape: {password?: string, username?: string, users?: list}
# --hypershift shape: {enabled?: bool}
# --identity_providers item shape: {kind?: string, id?: string, href?: string, ldap?: any, challenge?: bool, github?: any, gitlab?: any, google?: any, htpasswd?: any, login?: bool, mapping_method?: "add"|"claim"|"generate"|"lookup", name?: string, open_id?: any, type?: "LDAPIdentityProvider"|"GithubIdentityProvider"|"GitlabIdentityProvider"|"GoogleIdentityProvider"|"HTPasswdIdentityProvider"|"OpenIDIdentityProvider"}
# --image_registry shape: {state?: string}
# --inflight_checks item shape: {kind?: string, id?: string, href?: string, details?: record, ended_at?: string, name?: string, restarts?: int, started_at?: string, state?: "failed"|"passed"|"pending"|"running"}
# --ingresses item shape: {kind?: string, id?: string, href?: string, dns_name?: string, cluster_routes_hostname?: string, cluster_routes_tls_secret_ref?: string, component_routes?: record, default?: bool, excluded_namespace_selectors?: list, excluded_namespaces?: list, listening?: "external"|"internal", load_balancer_type?: "classic"|"nlb", route_namespace_ownership_policy?: "InterNamespaceAllowed"|"Strict", route_selectors?: record, route_wildcard_policy?: "WildcardsAllowed"|"WildcardsDisallowed"}
# --kubelet_config shape: {kind?: string, id?: string, href?: string, name?: string, pod_pids_limit?: int}
# --machine_pools item shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, autoscaling?: any, availability_zones?: list, instance_type?: string, labels?: record, replicas?: int, root_volume?: any, security_group_filters?: list, subnets?: list, taints?: list}
# --managed_service shape: {enabled?: bool}
# --network shape: {host_prefix?: int, machine_cidr?: string, pod_cidr?: string, service_cidr?: string, type?: string}
# --node_drain_grace_period shape: {unit?: string, value?: float}
# --node_pools item shape: {kind?: string, id?: string, href?: string, aws_node_pool?: any, auto_repair?: bool, autoscaling?: any, availability_zone?: string, azure_node_pool?: any, image_type?: "Default"|"Windows", kubelet_configs?: list, labels?: record, management_upgrade?: any, node_drain_grace_period?: any, replicas?: int, status?: any, subnet?: string, taints?: list, tuning_configs?: list, version?: any}
# --nodes shape: {autoscale_compute?: any, availability_zones?: list, compute?: int, compute_labels?: record, compute_machine_type?: any, compute_root_volume?: any, infra?: int, infra_machine_type?: any, master?: int, master_machine_type?: any, security_group_filters?: list, total?: int}
# --product shape: {kind?: string, id?: string, href?: string, name?: string}
# --provision_shard shape: {kind?: string, id?: string, href?: string, aws_account_operator_config?: any, aws_base_domain?: string, gcp_base_domain?: string, gcp_project_operator?: any, cloud_provider?: any, creation_timestamp?: string, hive_config?: any, hypershift_config?: any, last_update_timestamp?: string, management_cluster?: string, region?: any, status?: string}
# --proxy shape: {http_proxy?: string, https_proxy?: string, no_proxy?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --registry_config shape: {additional_trusted_ca?: record, allowed_registries_for_import?: list, platform_allowlist?: any, registry_sources?: any}
# --status shape: {kind?: string, id?: string, href?: string, dns_ready?: bool, oidc_ready?: bool, configuration_mode?: "full"|"read_only", current_compute?: int, description?: string, limited_support_reason_count?: int, provision_error_code?: string, provision_error_message?: string, state?: "error"|"hibernating"|"installing"|"pending"|"powering_down"|"ready"|"resuming"|"uninstalling"|"unknown"|"updating"|"validating"|"waiting"}
# --storage_quota shape: {unit?: string, value?: float}
# --subscription shape: {kind?: string, id?: string, href?: string}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-clusters post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Cluster' if this is a complete object or 'ClusterLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --api: any # Information about the API of a cluster. — shape: {cidr_block_access?: any, url?: string, listening?: "external"|"internal"}
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --aws-infrastructure-access-role-grants: list # List of AWS infrastructure access role grants on this cluster. — item shape: {kind?: string, id?: string, href?: string, console_url?: string, role?: any, state?: "deleting"|"failed"|"pending"|"ready"|"removed", state_description?: string, user_arn?: string}
  --ccs: any # shape: {kind?: string, id?: string, href?: string, disable_scp_checks?: bool, enabled?: bool}
  --dns: any # DNS settings of the cluster. — shape: {base_domain?: string}
  --fips: string@bool-completer # Create cluster that uses FIPS Validated / Modules in Process cryptographic libraries.
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --gcp-encryption-key: any # GCP Encryption Key for CCS clusters. — shape: {kms_key_service_account?: string, key_location?: string, key_name?: string, key_ring?: string}
  --gcp-network: any # GCP Network configuration of a cluster. — shape: {vpc_name?: string, vpc_project_id?: string, compute_subnet?: string, control_plane_subnet?: string}
  --additional-trust-bundle: string # Additional trust bundle.
  --addons: list # List of add-ons on this cluster. — item shape: {kind?: string, id?: string, href?: string, addon?: any, addon_version?: any, billing?: any, creation_timestamp?: string, operator_version?: string, parameters?: list, state?: "deleting"|"failed"|"installing"|"pending"|"ready", state_description?: string, updated_timestamp?: string}
  --auto-node: any # The AutoNode configuration for the Cluster. — shape: {mode?: string, status?: any}
  --autoscaler: any # Cluster-wide autoscaling configuration. — shape: {kind?: string, id?: string, href?: string, balance_similar_node_groups?: bool, balancing_ignored_labels?: list, ignore_daemonsets_utilization?: bool, log_verbosity?: int, max_node_provision_time?: string, max_pod_grace_period?: int, pod_priority_threshold?: int, resource_limits?: any, scale_down?: any, skip_nodes_with_local_storage?: bool}
  --azure: any # Microsoft Azure settings of a cluster. — shape: {etcd_encryption?: any, managed_resource_group_name?: string, network_security_group_resource_id?: string, nodes_outbound_connectivity?: any, operators_authentication?: any, resource_group_name?: string, resource_name?: string, subnet_resource_id?: string, subscription_id?: string, tenant_id?: string}
  --billing-model: string@billing-model-completer # Billing model for cluster resources.
  --byo-oidc: any # ByoOidc configuration. — shape: {enabled?: bool}
  --channel: string # Channel is the Y-stream update channel for the cluster (e.g., "stable-4.16", "eus-4.16"). This field allows specifying the update channel independently from the version.
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --console: any # Information about the console of a cluster. — shape: {url?: string}
  --control-plane: any # Representation of a Control Plane — shape: {backup?: any, log_forwarders?: list}
  --creation-timestamp: string # Date and time when the cluster was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --delete-protection: any # DeleteProtection configuration. — shape: {enabled?: bool}
  --disable-user-workload-monitoring: string@bool-completer # Indicates whether the User workload monitoring is enabled or not It is enabled by default This field is deprecated for ROSA Hosted Control Plane clusters and will be removed
  --domain-prefix: string # DomainPrefix of the cluster. This prefix is optionally assigned by the user when the cluster is created. It will appear in the Cluster's domain when the cluster is provisioned.
  --etcd-encryption: string@bool-completer # Indicates whether that etcd is encrypted or not. This is set only during cluster creation. For ROSA-HCP Clusters, etcd is always encrypted, if not set/false, or kms user's key not set,  defaults true indicates 'encrypted by internal key'. For ARO-HCP Clusters, this is a readonly attribute, always set to true.
  --expiration-timestamp: string # Date and time when the cluster will be automatically deleted, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). If no timestamp is provided, the cluster will never expire.  This option is unsupported. (format: date-time)
  --external-id: string # External identifier of the cluster, generated by the installer.
  --external-auth-config: any # Represents an external authentication configuration — shape: {kind?: string, id?: string, href?: string, enabled?: bool, external_auths?: list, state?: "disabled"|"enabled"}
  --external-configuration: any # Representation of cluster external configuration. — shape: {labels?: list, manifests?: list, syncsets?: list}
  --flavour: any # Set of predefined properties of a cluster. For example, a _huge_ flavour can be a cluster with 10 infra nodes and 1000 compute nodes. — shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, name?: string, network?: any, nodes?: any}
  --groups: list # Link to the collection of groups of user of the cluster. — item shape: {kind?: string, id?: string, href?: string, users?: list}
  --health-state: string@health-state-completer # ClusterHealthState indicates the health of a cluster.
  --htpasswd: any # Details for `htpasswd` identity providers. — shape: {password?: string, username?: string, users?: list}
  --hypershift: any # Hypershift configuration. — shape: {enabled?: bool}
  --identity-providers: list # Link to the collection of identity providers of the cluster. — item shape: {kind?: string, id?: string, href?: string, ldap?: any, challenge?: bool, github?: any, gitlab?: any, google?: any, htpasswd?: any, login?: bool, mapping_method?: "add"|"claim"|"generate"|"lookup", name?: string, open_id?: any, type?: "LDAPIdentityProvider"|"GithubIdentityProvider"|"GitlabIdentityProvider"|"GoogleIdentityProvider"|"HTPasswdIdentityProvider"|"OpenIDIdentityProvider"}
  --image-registry: any # ClusterImageRegistry represents the configuration for the cluster's internal image registry. — shape: {state?: string}
  --inflight-checks: list # List of inflight checks on this cluster. — item shape: {kind?: string, id?: string, href?: string, details?: record, ended_at?: string, name?: string, restarts?: int, started_at?: string, state?: "failed"|"passed"|"pending"|"running"}
  --infra-id: string # InfraID is used for example to name the VPCs.
  --ingresses: list # List of ingresses on this cluster. — item shape: {kind?: string, id?: string, href?: string, dns_name?: string, cluster_routes_hostname?: string, cluster_routes_tls_secret_ref?: string, component_routes?: record, default?: bool, excluded_namespace_selectors?: list, excluded_namespaces?: list, listening?: "external"|"internal", load_balancer_type?: "classic"|"nlb", route_namespace_ownership_policy?: "InterNamespaceAllowed"|"Strict", route_selectors?: record, route_wildcard_policy?: "WildcardsAllowed"|"WildcardsDisallowed"}
  --kubelet-config: any # OCM representation of KubeletConfig, exposing the fields of Kubernetes KubeletConfig that can be managed by users — shape: {kind?: string, id?: string, href?: string, name?: string, pod_pids_limit?: int}
  --load-balancer-quota: int # Load Balancer quota to be assigned to the cluster. (format: int32)
  --machine-pools: list # List of machine pools on this cluster. — item shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, autoscaling?: any, availability_zones?: list, instance_type?: string, labels?: record, replicas?: int, root_volume?: any, security_group_filters?: list, subnets?: list, taints?: list}
  --managed: string@bool-completer # Flag indicating if the cluster is managed (by Red Hat) or self-managed by the user.
  --managed-service: any # Contains the necessary attributes to support role-based authentication on AWS. — shape: {enabled?: bool}
  --multi-az: string@bool-completer # Flag indicating if the cluster should be created with nodes in different availability zones or all the nodes in a single one randomly selected. For ARO-HCP Clusters, this attribute is unused, and the control plane is deployed in multiple availability zones when the Azure region where it is deployed supports multiple availability zones.
  --multi-arch-enabled: string@bool-completer # Indicate whether the cluster is enabled for multi arch workers
  --name: string # Name of the cluster. This name is assigned by the user when the cluster is created. This is used to uniquely identify the cluster
  --network: any # Network configuration of a cluster. — shape: {host_prefix?: int, machine_cidr?: string, pod_cidr?: string, service_cidr?: string, type?: string}
  --node-drain-grace-period: any # Numeric value and the unit used to measure it.  Units are not mandatory, and they're not specified for some resources. For resources that use bytes, the accepted units are:  - 1 B = 1 byte - 1 KB = 10^3 bytes - 1 MB = 10^6 bytes - 1 GB = 10^9 bytes - 1 TB = 10^12 bytes - 1 PB = 10^15 bytes  - 1 B = 1 byte - 1 KiB = 2^10 bytes - 1 MiB = 2^20 bytes - 1 GiB = 2^30 bytes - 1 TiB = 2^40 bytes - 1 PiB = 2^50 bytes — shape: {unit?: string, value?: float}
  --node-pools: list # List of node pools on this cluster. NodePool is a scalable set of worker nodes attached to a hosted cluster. — item shape: {kind?: string, id?: string, href?: string, aws_node_pool?: any, auto_repair?: bool, autoscaling?: any, availability_zone?: string, azure_node_pool?: any, image_type?: "Default"|"Windows", kubelet_configs?: list, labels?: record, management_upgrade?: any, node_drain_grace_period?: any, replicas?: int, status?: any, subnet?: string, taints?: list, tuning_configs?: list, version?: any}
  --nodes: any # Counts of different classes of nodes inside a cluster. — shape: {autoscale_compute?: any, availability_zones?: list, compute?: int, compute_labels?: record, compute_machine_type?: any, compute_root_volume?: any, infra?: int, infra_machine_type?: any, master?: int, master_machine_type?: any, security_group_filters?: list, total?: int}
  --openshift-version: string # Version of _OpenShift_ installed in the cluster, for example `4.0.0-0.2`.  When retrieving a cluster this will always be reported.  When provisioning a cluster this will be ignored, as the version to deploy will be determined internally.
  --product: any # Representation of an product that can be selected as a cluster type. — shape: {kind?: string, id?: string, href?: string, name?: string}
  --properties: record # User defined properties for tagging and querying.
  --provision-shard: any # Contains the properties of the provision shard, including AWS and GCP related configurations — shape: {kind?: string, id?: string, href?: string, aws_account_operator_config?: any, aws_base_domain?: string, gcp_base_domain?: string, gcp_project_operator?: any, cloud_provider?: any, creation_timestamp?: string, hive_config?: any, hypershift_config?: any, last_update_timestamp?: string, management_cluster?: string, region?: any, status?: string}
  --proxy: any # Proxy configuration of a cluster. — shape: {http_proxy?: string, https_proxy?: string, no_proxy?: string}
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --registry-config: any # ClusterRegistryConfig describes the configuration of registries for the cluster. Its format reflects the OpenShift Image Configuration, for which docs are available on [docs.openshift.com](https://docs.openshift.com/container-platform/4.16/openshift_images/image-configuration.html) ```json {    "registry_config": {      "registry_sources": {        "blocked_registries": [          "badregistry.io",          "badregistry8.io"        ]      }    } } ``` — shape: {additional_trusted_ca?: record, allowed_registries_for_import?: list, platform_allowlist?: any, registry_sources?: any}
  --state: string@state-completer # Overall state of a cluster.
  --status: any # Detailed status of a cluster. — shape: {kind?: string, id?: string, href?: string, dns_ready?: bool, oidc_ready?: bool, configuration_mode?: "full"|"read_only", current_compute?: int, description?: string, limited_support_reason_count?: int, provision_error_code?: string, provision_error_message?: string, state?: "error"|"hibernating"|"installing"|"pending"|"powering_down"|"ready"|"resuming"|"uninstalling"|"unknown"|"updating"|"validating"|"waiting"}
  --storage-quota: any # Numeric value and the unit used to measure it.  Units are not mandatory, and they're not specified for some resources. For resources that use bytes, the accepted units are:  - 1 B = 1 byte - 1 KB = 10^3 bytes - 1 MB = 10^6 bytes - 1 GB = 10^9 bytes - 1 TB = 10^12 bytes - 1 PB = 10^15 bytes  - 1 B = 1 byte - 1 KiB = 2^10 bytes - 1 MiB = 2^20 bytes - 1 GiB = 2^30 bytes - 1 TiB = 2^40 bytes - 1 PiB = 2^50 bytes — shape: {unit?: string, value?: float}
  --subscription: any # Definition of a subscription. — shape: {kind?: string, id?: string, href?: string}
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
]: any -> record<kind: string, id: string, href: string, api: record<cidr_block_access: record<allow: record>, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record<oidc_endpoint_url: string, auto_mode: bool, enabled: bool, external_id: string, instance_iam_roles: record, managed_policies: bool, oidc_config: record, operator_iam_roles: list, operator_role_prefix: string, permission_boundary: string, role_arn: string, support_role_arn: string>, access_key_id: string, account_id: string, additional_allowed_principals: list<string>, additional_compute_security_group_ids: list<string>, additional_control_plane_security_group_ids: list<string>, additional_infra_security_group_ids: list<string>, audit_log: record<role_arn: string>, auto_node: record<role_arn: string>, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record<kms_key_arn: string>, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record<principals: list>, secret_access_key: string, subnet_ids: list<string>, tags: record, vpc_endpoint_role_arn: string, zero_egress: record<enabled: bool, no_proxy_default_domains: list>>, aws_infrastructure_access_role_grants: table<kind: string, id: string, href: string, console_url: string, role: record, state: string, state_description: string, user_arn: string>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record<href: string, id: string, kind: string>, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record<service_attachment_subnet: string>, project_id: string, security: record<secure_boot: bool>, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: table<kind: string, id: string, href: string, addon: record, addon_version: record, billing: record, creation_timestamp: string, operator_version: string, parameters: list, state: string, state_description: string, updated_timestamp: string>, auto_node: record<mode: string, status: record<message: string, node_count: int>>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list, cores: record, max_nodes_total: int, memory: record>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record<data_encryption: record>, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record<outbound_type: string>, operators_authentication: record<managed_identities: record>, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, console: record<url: string>, control_plane: record<backup: record<state: string>, log_forwarders: list<record>>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list<record>, state: string>, external_configuration: record<labels: list<record>, manifests: list<record>, syncsets: list<record>>, flavour: record<kind: string, id: string, href: string, aws: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, gcp: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, nodes: record<master: int>>, groups: table<kind: string, id: string, href: string, users: list>, health_state: string, htpasswd: record<password: string, username: string, users: list<record>>, hypershift: record<enabled: bool>, identity_providers: table<kind: string, id: string, href: string, ldap: record, challenge: bool, github: record, gitlab: record, google: record, htpasswd: record, login: bool, mapping_method: string, name: string, open_id: record, type: string>, image_registry: record<state: string>, inflight_checks: table<kind: string, id: string, href: string, details: record, ended_at: string, name: string, restarts: int, started_at: string, state: string>, infra_id: string, ingresses: table<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: list, excluded_namespaces: list, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: table<kind: string, id: string, href: string, aws: record, gcp: record, autoscaling: record, availability_zones: list, instance_type: string, labels: record, replicas: int, root_volume: record, security_group_filters: list, subnets: list, taints: list>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: table<kind: string, id: string, href: string, aws_node_pool: record, auto_repair: bool, autoscaling: record, availability_zone: string, azure_node_pool: record, image_type: string, kubelet_configs: list, labels: record, management_upgrade: record, node_drain_grace_period: record, replicas: int, status: record, subnet: string, taints: list, tuning_configs: list, version: record>, nodes: record<autoscale_compute: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, compute: int, compute_labels: record, compute_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, compute_root_volume: record<aws: record, gcp: record>, infra: int, infra_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, master: int, master_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, security_group_filters: list<record>, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list<record>, platform_allowlist: record<kind: string, id: string, href: string, cloud_provider: record, creation_timestamp: string, registries: list>, registry_sources: record<allowed_registries: list, blocked_registries: list, insecure_registries: list>>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/clusters")
  let body = {kind: $kind, id: $id, href: $href, api: $api, aws: $aws, aws_infrastructure_access_role_grants: $aws_infrastructure_access_role_grants, ccs: $ccs, dns: $dns, fips: $fips, gcp: $gcp, gcp_encryption_key: $gcp_encryption_key, gcp_network: $gcp_network, additional_trust_bundle: $additional_trust_bundle, addons: $addons, auto_node: $auto_node, autoscaler: $autoscaler, azure: $azure, billing_model: $billing_model, byo_oidc: $byo_oidc, channel: $channel, cloud_provider: $cloud_provider, console: $console, control_plane: $control_plane, creation_timestamp: $creation_timestamp, delete_protection: $delete_protection, disable_user_workload_monitoring: $disable_user_workload_monitoring, domain_prefix: $domain_prefix, etcd_encryption: $etcd_encryption, expiration_timestamp: $expiration_timestamp, external_id: $external_id, external_auth_config: $external_auth_config, external_configuration: $external_configuration, flavour: $flavour, groups: $groups, health_state: $health_state, htpasswd: $htpasswd, hypershift: $hypershift, identity_providers: $identity_providers, image_registry: $image_registry, inflight_checks: $inflight_checks, infra_id: $infra_id, ingresses: $ingresses, kubelet_config: $kubelet_config, load_balancer_quota: $load_balancer_quota, machine_pools: $machine_pools, managed: $managed, managed_service: $managed_service, multi_az: $multi_az, multi_arch_enabled: $multi_arch_enabled, name: $name, network: $network, node_drain_grace_period: $node_drain_grace_period, node_pools: $node_pools, nodes: $nodes, openshift_version: $openshift_version, product: $product, properties: $properties, provision_shard: $provision_shard, proxy: $proxy, region: $region, registry_config: $registry_config, state: $state, status: $status, storage_quota: $storage_quota, subscription: $subscription, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of clusters.
#
# GET /api/clusters_mgmt/v1/clusters
export def "clusters-mgmt-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the cluster instead of the names of the columns of a table. For example, in order to sort the clusters descending by region identifier the value should be:  ```sql region.id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the cluster instead of the names of the columns of a table. For example, in order to retrieve all the clusters with a name starting with `my` in the `us-east-1` region the value should be:  ```sql name like 'my%' and region.id = 'us-east-1' ```  If the parameter isn't provided, or if the value is empty, then all the clusters that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, api: record, aws: record, aws_infrastructure_access_role_grants: list, ccs: record, dns: record, fips: bool, gcp: record, gcp_encryption_key: record, gcp_network: record, additional_trust_bundle: string, addons: list, auto_node: record, autoscaler: record, azure: record, billing_model: string, byo_oidc: record, channel: string, cloud_provider: record, console: record, control_plane: record, creation_timestamp: string, delete_protection: record, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record, external_configuration: record, flavour: record, groups: list, health_state: string, htpasswd: record, hypershift: record, identity_providers: list, image_registry: record, inflight_checks: list, infra_id: string, ingresses: list, kubelet_config: record, load_balancer_quota: int, machine_pools: list, managed: bool, managed_service: record, multi_az: bool, multi_arch_enabled: bool, name: string, network: record, node_drain_grace_period: record, node_pools: list, nodes: record, openshift_version: string, product: record, properties: record, provision_shard: record, proxy: record, region: record, registry_config: record, state: string, status: record, storage_quota: record, subscription: record, version: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the cluster.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}
export def "clusters-mgmt-clusters delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --best-effort: string@bool-completer # BestEffort flag is used to check if the cluster deletion should be best-effort mode or not.
  --deprovision: string@bool-completer # If false it will only delete from OCM but not the actual cluster resources. false is only allowed for OCP clusters. true by default.
  --dry-run: string@bool-completer # Dry run flag is used to check if the operation can be completed, but won't delete.
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "best_effort" $best_effort "scalar") (serialize-qp "deprovision" $deprovision "scalar") (serialize-qp "dry_run" $dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the cluster.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}
export def "clusters-mgmt-clusters get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, api: record<cidr_block_access: record<allow: record>, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record<oidc_endpoint_url: string, auto_mode: bool, enabled: bool, external_id: string, instance_iam_roles: record, managed_policies: bool, oidc_config: record, operator_iam_roles: list, operator_role_prefix: string, permission_boundary: string, role_arn: string, support_role_arn: string>, access_key_id: string, account_id: string, additional_allowed_principals: list<string>, additional_compute_security_group_ids: list<string>, additional_control_plane_security_group_ids: list<string>, additional_infra_security_group_ids: list<string>, audit_log: record<role_arn: string>, auto_node: record<role_arn: string>, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record<kms_key_arn: string>, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record<principals: list>, secret_access_key: string, subnet_ids: list<string>, tags: record, vpc_endpoint_role_arn: string, zero_egress: record<enabled: bool, no_proxy_default_domains: list>>, aws_infrastructure_access_role_grants: table<kind: string, id: string, href: string, console_url: string, role: record, state: string, state_description: string, user_arn: string>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record<href: string, id: string, kind: string>, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record<service_attachment_subnet: string>, project_id: string, security: record<secure_boot: bool>, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: table<kind: string, id: string, href: string, addon: record, addon_version: record, billing: record, creation_timestamp: string, operator_version: string, parameters: list, state: string, state_description: string, updated_timestamp: string>, auto_node: record<mode: string, status: record<message: string, node_count: int>>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list, cores: record, max_nodes_total: int, memory: record>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record<data_encryption: record>, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record<outbound_type: string>, operators_authentication: record<managed_identities: record>, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, console: record<url: string>, control_plane: record<backup: record<state: string>, log_forwarders: list<record>>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list<record>, state: string>, external_configuration: record<labels: list<record>, manifests: list<record>, syncsets: list<record>>, flavour: record<kind: string, id: string, href: string, aws: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, gcp: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, nodes: record<master: int>>, groups: table<kind: string, id: string, href: string, users: list>, health_state: string, htpasswd: record<password: string, username: string, users: list<record>>, hypershift: record<enabled: bool>, identity_providers: table<kind: string, id: string, href: string, ldap: record, challenge: bool, github: record, gitlab: record, google: record, htpasswd: record, login: bool, mapping_method: string, name: string, open_id: record, type: string>, image_registry: record<state: string>, inflight_checks: table<kind: string, id: string, href: string, details: record, ended_at: string, name: string, restarts: int, started_at: string, state: string>, infra_id: string, ingresses: table<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: list, excluded_namespaces: list, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: table<kind: string, id: string, href: string, aws: record, gcp: record, autoscaling: record, availability_zones: list, instance_type: string, labels: record, replicas: int, root_volume: record, security_group_filters: list, subnets: list, taints: list>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: table<kind: string, id: string, href: string, aws_node_pool: record, auto_repair: bool, autoscaling: record, availability_zone: string, azure_node_pool: record, image_type: string, kubelet_configs: list, labels: record, management_upgrade: record, node_drain_grace_period: record, replicas: int, status: record, subnet: string, taints: list, tuning_configs: list, version: record>, nodes: record<autoscale_compute: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, compute: int, compute_labels: record, compute_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, compute_root_volume: record<aws: record, gcp: record>, infra: int, infra_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, master: int, master_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, security_group_filters: list<record>, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list<record>, platform_allowlist: record<kind: string, id: string, href: string, cloud_provider: record, creation_timestamp: string, registries: list>, registry_sources: record<allowed_registries: list, blocked_registries: list, insecure_registries: list>>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the cluster.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}
# --api shape: {cidr_block_access?: any, url?: string, listening?: "external"|"internal"}
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --aws_infrastructure_access_role_grants item shape: {kind?: string, id?: string, href?: string, console_url?: string, role?: any, state?: "deleting"|"failed"|"pending"|"ready"|"removed", state_description?: string, user_arn?: string}
# --ccs shape: {kind?: string, id?: string, href?: string, disable_scp_checks?: bool, enabled?: bool}
# --dns shape: {base_domain?: string}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --gcp_encryption_key shape: {kms_key_service_account?: string, key_location?: string, key_name?: string, key_ring?: string}
# --gcp_network shape: {vpc_name?: string, vpc_project_id?: string, compute_subnet?: string, control_plane_subnet?: string}
# --addons item shape: {kind?: string, id?: string, href?: string, addon?: any, addon_version?: any, billing?: any, creation_timestamp?: string, operator_version?: string, parameters?: list, state?: "deleting"|"failed"|"installing"|"pending"|"ready", state_description?: string, updated_timestamp?: string}
# --auto_node shape: {mode?: string, status?: any}
# --autoscaler shape: {kind?: string, id?: string, href?: string, balance_similar_node_groups?: bool, balancing_ignored_labels?: list, ignore_daemonsets_utilization?: bool, log_verbosity?: int, max_node_provision_time?: string, max_pod_grace_period?: int, pod_priority_threshold?: int, resource_limits?: any, scale_down?: any, skip_nodes_with_local_storage?: bool}
# --azure shape: {etcd_encryption?: any, managed_resource_group_name?: string, network_security_group_resource_id?: string, nodes_outbound_connectivity?: any, operators_authentication?: any, resource_group_name?: string, resource_name?: string, subnet_resource_id?: string, subscription_id?: string, tenant_id?: string}
# --byo_oidc shape: {enabled?: bool}
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
# --console shape: {url?: string}
# --control_plane shape: {backup?: any, log_forwarders?: list}
# --delete_protection shape: {enabled?: bool}
# --external_auth_config shape: {kind?: string, id?: string, href?: string, enabled?: bool, external_auths?: list, state?: "disabled"|"enabled"}
# --external_configuration shape: {labels?: list, manifests?: list, syncsets?: list}
# --flavour shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, name?: string, network?: any, nodes?: any}
# --groups item shape: {kind?: string, id?: string, href?: string, users?: list}
# --htpasswd shape: {password?: string, username?: string, users?: list}
# --hypershift shape: {enabled?: bool}
# --identity_providers item shape: {kind?: string, id?: string, href?: string, ldap?: any, challenge?: bool, github?: any, gitlab?: any, google?: any, htpasswd?: any, login?: bool, mapping_method?: "add"|"claim"|"generate"|"lookup", name?: string, open_id?: any, type?: "LDAPIdentityProvider"|"GithubIdentityProvider"|"GitlabIdentityProvider"|"GoogleIdentityProvider"|"HTPasswdIdentityProvider"|"OpenIDIdentityProvider"}
# --image_registry shape: {state?: string}
# --inflight_checks item shape: {kind?: string, id?: string, href?: string, details?: record, ended_at?: string, name?: string, restarts?: int, started_at?: string, state?: "failed"|"passed"|"pending"|"running"}
# --ingresses item shape: {kind?: string, id?: string, href?: string, dns_name?: string, cluster_routes_hostname?: string, cluster_routes_tls_secret_ref?: string, component_routes?: record, default?: bool, excluded_namespace_selectors?: list, excluded_namespaces?: list, listening?: "external"|"internal", load_balancer_type?: "classic"|"nlb", route_namespace_ownership_policy?: "InterNamespaceAllowed"|"Strict", route_selectors?: record, route_wildcard_policy?: "WildcardsAllowed"|"WildcardsDisallowed"}
# --kubelet_config shape: {kind?: string, id?: string, href?: string, name?: string, pod_pids_limit?: int}
# --machine_pools item shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, autoscaling?: any, availability_zones?: list, instance_type?: string, labels?: record, replicas?: int, root_volume?: any, security_group_filters?: list, subnets?: list, taints?: list}
# --managed_service shape: {enabled?: bool}
# --network shape: {host_prefix?: int, machine_cidr?: string, pod_cidr?: string, service_cidr?: string, type?: string}
# --node_drain_grace_period shape: {unit?: string, value?: float}
# --node_pools item shape: {kind?: string, id?: string, href?: string, aws_node_pool?: any, auto_repair?: bool, autoscaling?: any, availability_zone?: string, azure_node_pool?: any, image_type?: "Default"|"Windows", kubelet_configs?: list, labels?: record, management_upgrade?: any, node_drain_grace_period?: any, replicas?: int, status?: any, subnet?: string, taints?: list, tuning_configs?: list, version?: any}
# --nodes shape: {autoscale_compute?: any, availability_zones?: list, compute?: int, compute_labels?: record, compute_machine_type?: any, compute_root_volume?: any, infra?: int, infra_machine_type?: any, master?: int, master_machine_type?: any, security_group_filters?: list, total?: int}
# --product shape: {kind?: string, id?: string, href?: string, name?: string}
# --provision_shard shape: {kind?: string, id?: string, href?: string, aws_account_operator_config?: any, aws_base_domain?: string, gcp_base_domain?: string, gcp_project_operator?: any, cloud_provider?: any, creation_timestamp?: string, hive_config?: any, hypershift_config?: any, last_update_timestamp?: string, management_cluster?: string, region?: any, status?: string}
# --proxy shape: {http_proxy?: string, https_proxy?: string, no_proxy?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --registry_config shape: {additional_trusted_ca?: record, allowed_registries_for_import?: list, platform_allowlist?: any, registry_sources?: any}
# --status shape: {kind?: string, id?: string, href?: string, dns_ready?: bool, oidc_ready?: bool, configuration_mode?: "full"|"read_only", current_compute?: int, description?: string, limited_support_reason_count?: int, provision_error_code?: string, provision_error_message?: string, state?: "error"|"hibernating"|"installing"|"pending"|"powering_down"|"ready"|"resuming"|"uninstalling"|"unknown"|"updating"|"validating"|"waiting"}
# --storage_quota shape: {unit?: string, value?: float}
# --subscription shape: {kind?: string, id?: string, href?: string}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-clusters patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Cluster' if this is a complete object or 'ClusterLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --api: any # Information about the API of a cluster. — shape: {cidr_block_access?: any, url?: string, listening?: "external"|"internal"}
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --aws-infrastructure-access-role-grants: list # List of AWS infrastructure access role grants on this cluster. — item shape: {kind?: string, id?: string, href?: string, console_url?: string, role?: any, state?: "deleting"|"failed"|"pending"|"ready"|"removed", state_description?: string, user_arn?: string}
  --ccs: any # shape: {kind?: string, id?: string, href?: string, disable_scp_checks?: bool, enabled?: bool}
  --dns: any # DNS settings of the cluster. — shape: {base_domain?: string}
  --fips: string@bool-completer # Create cluster that uses FIPS Validated / Modules in Process cryptographic libraries.
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --gcp-encryption-key: any # GCP Encryption Key for CCS clusters. — shape: {kms_key_service_account?: string, key_location?: string, key_name?: string, key_ring?: string}
  --gcp-network: any # GCP Network configuration of a cluster. — shape: {vpc_name?: string, vpc_project_id?: string, compute_subnet?: string, control_plane_subnet?: string}
  --additional-trust-bundle: string # Additional trust bundle.
  --addons: list # List of add-ons on this cluster. — item shape: {kind?: string, id?: string, href?: string, addon?: any, addon_version?: any, billing?: any, creation_timestamp?: string, operator_version?: string, parameters?: list, state?: "deleting"|"failed"|"installing"|"pending"|"ready", state_description?: string, updated_timestamp?: string}
  --auto-node: any # The AutoNode configuration for the Cluster. — shape: {mode?: string, status?: any}
  --autoscaler: any # Cluster-wide autoscaling configuration. — shape: {kind?: string, id?: string, href?: string, balance_similar_node_groups?: bool, balancing_ignored_labels?: list, ignore_daemonsets_utilization?: bool, log_verbosity?: int, max_node_provision_time?: string, max_pod_grace_period?: int, pod_priority_threshold?: int, resource_limits?: any, scale_down?: any, skip_nodes_with_local_storage?: bool}
  --azure: any # Microsoft Azure settings of a cluster. — shape: {etcd_encryption?: any, managed_resource_group_name?: string, network_security_group_resource_id?: string, nodes_outbound_connectivity?: any, operators_authentication?: any, resource_group_name?: string, resource_name?: string, subnet_resource_id?: string, subscription_id?: string, tenant_id?: string}
  --billing-model: string@billing-model-completer # Billing model for cluster resources.
  --byo-oidc: any # ByoOidc configuration. — shape: {enabled?: bool}
  --channel: string # Channel is the Y-stream update channel for the cluster (e.g., "stable-4.16", "eus-4.16"). This field allows specifying the update channel independently from the version.
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --console: any # Information about the console of a cluster. — shape: {url?: string}
  --control-plane: any # Representation of a Control Plane — shape: {backup?: any, log_forwarders?: list}
  --creation-timestamp: string # Date and time when the cluster was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --delete-protection: any # DeleteProtection configuration. — shape: {enabled?: bool}
  --disable-user-workload-monitoring: string@bool-completer # Indicates whether the User workload monitoring is enabled or not It is enabled by default This field is deprecated for ROSA Hosted Control Plane clusters and will be removed
  --domain-prefix: string # DomainPrefix of the cluster. This prefix is optionally assigned by the user when the cluster is created. It will appear in the Cluster's domain when the cluster is provisioned.
  --etcd-encryption: string@bool-completer # Indicates whether that etcd is encrypted or not. This is set only during cluster creation. For ROSA-HCP Clusters, etcd is always encrypted, if not set/false, or kms user's key not set,  defaults true indicates 'encrypted by internal key'. For ARO-HCP Clusters, this is a readonly attribute, always set to true.
  --expiration-timestamp: string # Date and time when the cluster will be automatically deleted, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). If no timestamp is provided, the cluster will never expire.  This option is unsupported. (format: date-time)
  --external-id: string # External identifier of the cluster, generated by the installer.
  --external-auth-config: any # Represents an external authentication configuration — shape: {kind?: string, id?: string, href?: string, enabled?: bool, external_auths?: list, state?: "disabled"|"enabled"}
  --external-configuration: any # Representation of cluster external configuration. — shape: {labels?: list, manifests?: list, syncsets?: list}
  --flavour: any # Set of predefined properties of a cluster. For example, a _huge_ flavour can be a cluster with 10 infra nodes and 1000 compute nodes. — shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, name?: string, network?: any, nodes?: any}
  --groups: list # Link to the collection of groups of user of the cluster. — item shape: {kind?: string, id?: string, href?: string, users?: list}
  --health-state: string@health-state-completer # ClusterHealthState indicates the health of a cluster.
  --htpasswd: any # Details for `htpasswd` identity providers. — shape: {password?: string, username?: string, users?: list}
  --hypershift: any # Hypershift configuration. — shape: {enabled?: bool}
  --identity-providers: list # Link to the collection of identity providers of the cluster. — item shape: {kind?: string, id?: string, href?: string, ldap?: any, challenge?: bool, github?: any, gitlab?: any, google?: any, htpasswd?: any, login?: bool, mapping_method?: "add"|"claim"|"generate"|"lookup", name?: string, open_id?: any, type?: "LDAPIdentityProvider"|"GithubIdentityProvider"|"GitlabIdentityProvider"|"GoogleIdentityProvider"|"HTPasswdIdentityProvider"|"OpenIDIdentityProvider"}
  --image-registry: any # ClusterImageRegistry represents the configuration for the cluster's internal image registry. — shape: {state?: string}
  --inflight-checks: list # List of inflight checks on this cluster. — item shape: {kind?: string, id?: string, href?: string, details?: record, ended_at?: string, name?: string, restarts?: int, started_at?: string, state?: "failed"|"passed"|"pending"|"running"}
  --infra-id: string # InfraID is used for example to name the VPCs.
  --ingresses: list # List of ingresses on this cluster. — item shape: {kind?: string, id?: string, href?: string, dns_name?: string, cluster_routes_hostname?: string, cluster_routes_tls_secret_ref?: string, component_routes?: record, default?: bool, excluded_namespace_selectors?: list, excluded_namespaces?: list, listening?: "external"|"internal", load_balancer_type?: "classic"|"nlb", route_namespace_ownership_policy?: "InterNamespaceAllowed"|"Strict", route_selectors?: record, route_wildcard_policy?: "WildcardsAllowed"|"WildcardsDisallowed"}
  --kubelet-config: any # OCM representation of KubeletConfig, exposing the fields of Kubernetes KubeletConfig that can be managed by users — shape: {kind?: string, id?: string, href?: string, name?: string, pod_pids_limit?: int}
  --load-balancer-quota: int # Load Balancer quota to be assigned to the cluster. (format: int32)
  --machine-pools: list # List of machine pools on this cluster. — item shape: {kind?: string, id?: string, href?: string, aws?: any, gcp?: any, autoscaling?: any, availability_zones?: list, instance_type?: string, labels?: record, replicas?: int, root_volume?: any, security_group_filters?: list, subnets?: list, taints?: list}
  --managed: string@bool-completer # Flag indicating if the cluster is managed (by Red Hat) or self-managed by the user.
  --managed-service: any # Contains the necessary attributes to support role-based authentication on AWS. — shape: {enabled?: bool}
  --multi-az: string@bool-completer # Flag indicating if the cluster should be created with nodes in different availability zones or all the nodes in a single one randomly selected. For ARO-HCP Clusters, this attribute is unused, and the control plane is deployed in multiple availability zones when the Azure region where it is deployed supports multiple availability zones.
  --multi-arch-enabled: string@bool-completer # Indicate whether the cluster is enabled for multi arch workers
  --name: string # Name of the cluster. This name is assigned by the user when the cluster is created. This is used to uniquely identify the cluster
  --network: any # Network configuration of a cluster. — shape: {host_prefix?: int, machine_cidr?: string, pod_cidr?: string, service_cidr?: string, type?: string}
  --node-drain-grace-period: any # Numeric value and the unit used to measure it.  Units are not mandatory, and they're not specified for some resources. For resources that use bytes, the accepted units are:  - 1 B = 1 byte - 1 KB = 10^3 bytes - 1 MB = 10^6 bytes - 1 GB = 10^9 bytes - 1 TB = 10^12 bytes - 1 PB = 10^15 bytes  - 1 B = 1 byte - 1 KiB = 2^10 bytes - 1 MiB = 2^20 bytes - 1 GiB = 2^30 bytes - 1 TiB = 2^40 bytes - 1 PiB = 2^50 bytes — shape: {unit?: string, value?: float}
  --node-pools: list # List of node pools on this cluster. NodePool is a scalable set of worker nodes attached to a hosted cluster. — item shape: {kind?: string, id?: string, href?: string, aws_node_pool?: any, auto_repair?: bool, autoscaling?: any, availability_zone?: string, azure_node_pool?: any, image_type?: "Default"|"Windows", kubelet_configs?: list, labels?: record, management_upgrade?: any, node_drain_grace_period?: any, replicas?: int, status?: any, subnet?: string, taints?: list, tuning_configs?: list, version?: any}
  --nodes: any # Counts of different classes of nodes inside a cluster. — shape: {autoscale_compute?: any, availability_zones?: list, compute?: int, compute_labels?: record, compute_machine_type?: any, compute_root_volume?: any, infra?: int, infra_machine_type?: any, master?: int, master_machine_type?: any, security_group_filters?: list, total?: int}
  --openshift-version: string # Version of _OpenShift_ installed in the cluster, for example `4.0.0-0.2`.  When retrieving a cluster this will always be reported.  When provisioning a cluster this will be ignored, as the version to deploy will be determined internally.
  --product: any # Representation of an product that can be selected as a cluster type. — shape: {kind?: string, id?: string, href?: string, name?: string}
  --properties: record # User defined properties for tagging and querying.
  --provision-shard: any # Contains the properties of the provision shard, including AWS and GCP related configurations — shape: {kind?: string, id?: string, href?: string, aws_account_operator_config?: any, aws_base_domain?: string, gcp_base_domain?: string, gcp_project_operator?: any, cloud_provider?: any, creation_timestamp?: string, hive_config?: any, hypershift_config?: any, last_update_timestamp?: string, management_cluster?: string, region?: any, status?: string}
  --proxy: any # Proxy configuration of a cluster. — shape: {http_proxy?: string, https_proxy?: string, no_proxy?: string}
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --registry-config: any # ClusterRegistryConfig describes the configuration of registries for the cluster. Its format reflects the OpenShift Image Configuration, for which docs are available on [docs.openshift.com](https://docs.openshift.com/container-platform/4.16/openshift_images/image-configuration.html) ```json {    "registry_config": {      "registry_sources": {        "blocked_registries": [          "badregistry.io",          "badregistry8.io"        ]      }    } } ``` — shape: {additional_trusted_ca?: record, allowed_registries_for_import?: list, platform_allowlist?: any, registry_sources?: any}
  --state: string@state-completer # Overall state of a cluster.
  --status: any # Detailed status of a cluster. — shape: {kind?: string, id?: string, href?: string, dns_ready?: bool, oidc_ready?: bool, configuration_mode?: "full"|"read_only", current_compute?: int, description?: string, limited_support_reason_count?: int, provision_error_code?: string, provision_error_message?: string, state?: "error"|"hibernating"|"installing"|"pending"|"powering_down"|"ready"|"resuming"|"uninstalling"|"unknown"|"updating"|"validating"|"waiting"}
  --storage-quota: any # Numeric value and the unit used to measure it.  Units are not mandatory, and they're not specified for some resources. For resources that use bytes, the accepted units are:  - 1 B = 1 byte - 1 KB = 10^3 bytes - 1 MB = 10^6 bytes - 1 GB = 10^9 bytes - 1 TB = 10^12 bytes - 1 PB = 10^15 bytes  - 1 B = 1 byte - 1 KiB = 2^10 bytes - 1 MiB = 2^20 bytes - 1 GiB = 2^30 bytes - 1 TiB = 2^40 bytes - 1 PiB = 2^50 bytes — shape: {unit?: string, value?: float}
  --subscription: any # Definition of a subscription. — shape: {kind?: string, id?: string, href?: string}
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
]: any -> record<kind: string, id: string, href: string, api: record<cidr_block_access: record<allow: record>, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record<oidc_endpoint_url: string, auto_mode: bool, enabled: bool, external_id: string, instance_iam_roles: record, managed_policies: bool, oidc_config: record, operator_iam_roles: list, operator_role_prefix: string, permission_boundary: string, role_arn: string, support_role_arn: string>, access_key_id: string, account_id: string, additional_allowed_principals: list<string>, additional_compute_security_group_ids: list<string>, additional_control_plane_security_group_ids: list<string>, additional_infra_security_group_ids: list<string>, audit_log: record<role_arn: string>, auto_node: record<role_arn: string>, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record<kms_key_arn: string>, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record<principals: list>, secret_access_key: string, subnet_ids: list<string>, tags: record, vpc_endpoint_role_arn: string, zero_egress: record<enabled: bool, no_proxy_default_domains: list>>, aws_infrastructure_access_role_grants: table<kind: string, id: string, href: string, console_url: string, role: record, state: string, state_description: string, user_arn: string>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record<href: string, id: string, kind: string>, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record<service_attachment_subnet: string>, project_id: string, security: record<secure_boot: bool>, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: table<kind: string, id: string, href: string, addon: record, addon_version: record, billing: record, creation_timestamp: string, operator_version: string, parameters: list, state: string, state_description: string, updated_timestamp: string>, auto_node: record<mode: string, status: record<message: string, node_count: int>>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list, cores: record, max_nodes_total: int, memory: record>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record<data_encryption: record>, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record<outbound_type: string>, operators_authentication: record<managed_identities: record>, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, console: record<url: string>, control_plane: record<backup: record<state: string>, log_forwarders: list<record>>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list<record>, state: string>, external_configuration: record<labels: list<record>, manifests: list<record>, syncsets: list<record>>, flavour: record<kind: string, id: string, href: string, aws: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, gcp: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, nodes: record<master: int>>, groups: table<kind: string, id: string, href: string, users: list>, health_state: string, htpasswd: record<password: string, username: string, users: list<record>>, hypershift: record<enabled: bool>, identity_providers: table<kind: string, id: string, href: string, ldap: record, challenge: bool, github: record, gitlab: record, google: record, htpasswd: record, login: bool, mapping_method: string, name: string, open_id: record, type: string>, image_registry: record<state: string>, inflight_checks: table<kind: string, id: string, href: string, details: record, ended_at: string, name: string, restarts: int, started_at: string, state: string>, infra_id: string, ingresses: table<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: list, excluded_namespaces: list, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: table<kind: string, id: string, href: string, aws: record, gcp: record, autoscaling: record, availability_zones: list, instance_type: string, labels: record, replicas: int, root_volume: record, security_group_filters: list, subnets: list, taints: list>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: table<kind: string, id: string, href: string, aws_node_pool: record, auto_repair: bool, autoscaling: record, availability_zone: string, azure_node_pool: record, image_type: string, kubelet_configs: list, labels: record, management_upgrade: record, node_drain_grace_period: record, replicas: int, status: record, subnet: string, taints: list, tuning_configs: list, version: record>, nodes: record<autoscale_compute: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, compute: int, compute_labels: record, compute_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, compute_root_volume: record<aws: record, gcp: record>, infra: int, infra_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, master: int, master_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, security_group_filters: list<record>, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list<record>, platform_allowlist: record<kind: string, id: string, href: string, cloud_provider: record, creation_timestamp: string, registries: list>, registry_sources: record<allowed_registries: list, blocked_registries: list, insecure_registries: list>>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)")
  let body = {kind: $kind, id: $id, href: $href, api: $api, aws: $aws, aws_infrastructure_access_role_grants: $aws_infrastructure_access_role_grants, ccs: $ccs, dns: $dns, fips: $fips, gcp: $gcp, gcp_encryption_key: $gcp_encryption_key, gcp_network: $gcp_network, additional_trust_bundle: $additional_trust_bundle, addons: $addons, auto_node: $auto_node, autoscaler: $autoscaler, azure: $azure, billing_model: $billing_model, byo_oidc: $byo_oidc, channel: $channel, cloud_provider: $cloud_provider, console: $console, control_plane: $control_plane, creation_timestamp: $creation_timestamp, delete_protection: $delete_protection, disable_user_workload_monitoring: $disable_user_workload_monitoring, domain_prefix: $domain_prefix, etcd_encryption: $etcd_encryption, expiration_timestamp: $expiration_timestamp, external_id: $external_id, external_auth_config: $external_auth_config, external_configuration: $external_configuration, flavour: $flavour, groups: $groups, health_state: $health_state, htpasswd: $htpasswd, hypershift: $hypershift, identity_providers: $identity_providers, image_registry: $image_registry, inflight_checks: $inflight_checks, infra_id: $infra_id, ingresses: $ingresses, kubelet_config: $kubelet_config, load_balancer_quota: $load_balancer_quota, machine_pools: $machine_pools, managed: $managed, managed_service: $managed_service, multi_az: $multi_az, multi_arch_enabled: $multi_arch_enabled, name: $name, network: $network, node_drain_grace_period: $node_drain_grace_period, node_pools: $node_pools, nodes: $nodes, openshift_version: $openshift_version, product: $product, properties: $properties, provision_shard: $provision_shard, proxy: $proxy, region: $region, registry_config: $registry_config, state: $state, status: $status, storage_quota: $storage_quota, subscription: $subscription, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initiates cluster hibernation. While hibernating a cluster will not consume any cloud provider infrastructure but will be counted for quota.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/hibernate
export def "clusters-mgmt-clusters-hibernate post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/hibernate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resumes from Hibernation.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/resume
export def "clusters-mgmt-clusters-resume post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_inquiries
export def "clusters-mgmt-clusters-addon-inquiries list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the add-on instead of the names of the columns of a table. For example, in order to sort the add-ons descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the add-on instead of the names of the columns of a table. For example, in order to retrieve all the add-ons with a name starting with `my` the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the add-ons that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record, credentials_requests: list, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: list, operator_name: string, parameters: list, requirements: list, resource_cost: float, resource_name: string, sub_operators: list, target_namespace: string, version: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_inquiries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_inquiries/{addon_inquiry_id}
export def "clusters-mgmt-clusters-addon-inquiries get" [
  cluster_id: string
  addon_inquiry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list<record>, secret_propagations: list<record>>, credentials_requests: table<name: string, namespace: string, policy_permissions: list, service_account: string>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: table<kind: string, id: string, href: string, annotations: record, labels: record, name: string>, operator_name: string, parameters: table<kind: string, id: string, href: string, addon: any, conditions: list, default_value: string, description: string, editable: bool, editable_direction: string, enabled: bool, name: string, options: list, required: bool, validation: string, validation_err_msg: string, value_type: string>, requirements: table<id: string, data: record, enabled: bool, resource: string, status: record>, resource_cost: float, resource_name: string, sub_operators: table<enabled: bool, operator_name: string, operator_namespace: string>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_inquiries/($addon_inquiry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new addon upgrade policy to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies
export def "clusters-mgmt-clusters-addon-upgrade-policies post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddonUpgradePolicy' if this is a complete object or 'AddonUpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --addon-id: string # Addon ID this upgrade policy is defined for
  --body-cluster-id: string # Cluster ID this upgrade policy is defined for.
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string # Schedule type can be either "manual" (single execution) or "automatic" (re-occurring).
  --upgrade-type: string # Upgrade type specify the type of the upgrade. Must be "ADDON".
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, addon_id: string, cluster_id: string, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies")
  let body = {kind: $kind, id: $id, href: $href, addon_id: $addon_id, cluster_id: $body_cluster_id, next_run: $next_run, schedule: $schedule, schedule_type: $schedule_type, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of addon upgrade policies.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies
export def "clusters-mgmt-clusters-addon-upgrade-policies list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, addon_id: string, cluster_id: string, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the addon upgrade policy.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies/{addon_upgrade_policy_id}
export def "clusters-mgmt-clusters-addon-upgrade-policies delete" [
  cluster_id: string
  addon_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies/($addon_upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the addon upgrade policy.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies/{addon_upgrade_policy_id}
export def "clusters-mgmt-clusters-addon-upgrade-policies get" [
  cluster_id: string
  addon_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, addon_id: string, cluster_id: string, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies/($addon_upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the addon upgrade policy.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies/{addon_upgrade_policy_id}
export def "clusters-mgmt-clusters-addon-upgrade-policies patch" [
  cluster_id: string
  addon_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddonUpgradePolicy' if this is a complete object or 'AddonUpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --addon-id: string # Addon ID this upgrade policy is defined for
  --body-cluster-id: string # Cluster ID this upgrade policy is defined for.
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string # Schedule type can be either "manual" (single execution) or "automatic" (re-occurring).
  --upgrade-type: string # Upgrade type specify the type of the upgrade. Must be "ADDON".
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, addon_id: string, cluster_id: string, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies/($addon_upgrade_policy_id)")
  let body = {kind: $kind, id: $id, href: $href, addon_id: $addon_id, cluster_id: $body_cluster_id, next_run: $next_run, schedule: $schedule, schedule_type: $schedule_type, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of the upgrade policy state.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies/{addon_upgrade_policy_id}/state
export def "clusters-mgmt-clusters-addon-upgrade-policies-state get" [
  cluster_id: string
  addon_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, description: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies/($addon_upgrade_policy_id)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the upgrade policy state.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/addon_upgrade_policies/{addon_upgrade_policy_id}/state
export def "clusters-mgmt-clusters-addon-upgrade-policies-state patch" [
  cluster_id: string
  addon_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddonUpgradePolicyState' if this is a complete object or 'AddonUpgradePolicyStateLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --description: string # Description of the state.
  --value: string@value-completer # Overall state of a cluster upgrade policy.
]: any -> record<kind: string, id: string, href: string, description: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addon_upgrade_policies/($addon_upgrade_policy_id)/state")
  let body = {kind: $kind, id: $id, href: $href, description: $description, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new add-on installation and add it to the collection of add-on installations on the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/addons
# --addon shape: {kind?: string, id?: string, href?: string, common_annotations?: record, common_labels?: record, config?: any, credentials_requests?: list, description?: string, docs_link?: string, enabled?: bool, has_external_resources?: bool, hidden?: bool, icon?: string, install_mode?: "all_namespaces"|"own_namespace", label?: string, managed_service?: bool, name?: string, namespaces?: list, operator_name?: string, parameters?: list, requirements?: list, resource_cost?: float, resource_name?: string, sub_operators?: list, target_namespace?: string, version?: any}
# --addon_version shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
# --billing shape: {kind?: string, id?: string, href?: string, billing_marketplace_account?: string, billing_model?: "marketplace"|"marketplace-aws"|"marketplace-gcp"|"marketplace-rhm"|"marketplace-azure"|"standard"}
# --parameters item shape: {kind?: string, id?: string, href?: string, value?: string}
export def "clusters-mgmt-clusters-addons post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddOnInstallation' if this is a complete object or 'AddOnInstallationLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --addon: any # Representation of an add-on that can be installed in a cluster. — shape: {kind?: string, id?: string, href?: string, common_annotations?: record, common_labels?: record, config?: any, credentials_requests?: list, description?: string, docs_link?: string, enabled?: bool, has_external_resources?: bool, hidden?: bool, icon?: string, install_mode?: "all_namespaces"|"own_namespace", label?: string, managed_service?: bool, name?: string, namespaces?: list, operator_name?: string, parameters?: list, requirements?: list, resource_cost?: float, resource_name?: string, sub_operators?: list, target_namespace?: string, version?: any}
  --addon-version: any # Representation of an add-on version. — shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
  --billing: any # Representation of an add-on installation billing. — shape: {kind?: string, id?: string, href?: string, billing_marketplace_account?: string, billing_model?: "marketplace"|"marketplace-aws"|"marketplace-gcp"|"marketplace-rhm"|"marketplace-azure"|"standard"}
  --creation-timestamp: string # Date and time when the add-on was initially installed in the cluster. (format: date-time)
  --operator-version: string # Version of the operator installed by the add-on.
  --parameters: list # List of add-on parameters for this add-on installation. — item shape: {kind?: string, id?: string, href?: string, value?: string}
  --state: string@state-completer-1 # Representation of an add-on installation State field.
  --state-description: string # Reason for the current State.
  --updated-timestamp: string # Date and time when the add-on installation information was last updated. (format: date-time)
]: any -> record<kind: string, id: string, href: string, addon: record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, credentials_requests: list<record>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: list<record>, operator_name: string, parameters: list<record>, requirements: list<record>, resource_cost: float, resource_name: string, sub_operators: list<record>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list, available_upgrades: list, channel: string, config: record, enabled: bool, package_image: string, parameters: list, pull_secret_name: string, requirements: list, source_image: string, sub_operators: list>>, addon_version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>, billing: record<kind: string, id: string, href: string, billing_marketplace_account: string, billing_model: string>, creation_timestamp: string, operator_version: string, parameters: table<kind: string, id: string, href: string, value: string>, state: string, state_description: string, updated_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addons")
  let body = {kind: $kind, id: $id, href: $href, addon: $addon, addon_version: $addon_version, billing: $billing, creation_timestamp: $creation_timestamp, operator_version: $operator_version, parameters: $parameters, state: $state, state_description: $state_description, updated_timestamp: $updated_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of add-on installations.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addons
export def "clusters-mgmt-clusters-addons list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the add-on installation instead of the names of the columns of a table. For example, in order to sort the add-on installations descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the add-on installation instead of the names of the columns of a table. For example, in order to retrieve all the add-on installations with a name starting with `my` the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the add-on installations that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, addon: record, addon_version: record, billing: record, creation_timestamp: string, operator_version: string, parameters: list, state: string, state_description: string, updated_timestamp: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an add-on installation and remove it from the collection of add-on installations on the cluster.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/addons/{addoninstallation_id}
export def "clusters-mgmt-clusters-addons delete" [
  cluster_id: string
  addoninstallation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addons/($addoninstallation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the add-on installation.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/addons/{addoninstallation_id}
export def "clusters-mgmt-clusters-addons get" [
  cluster_id: string
  addoninstallation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, addon: record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, credentials_requests: list<record>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: list<record>, operator_name: string, parameters: list<record>, requirements: list<record>, resource_cost: float, resource_name: string, sub_operators: list<record>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list, available_upgrades: list, channel: string, config: record, enabled: bool, package_image: string, parameters: list, pull_secret_name: string, requirements: list, source_image: string, sub_operators: list>>, addon_version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>, billing: record<kind: string, id: string, href: string, billing_marketplace_account: string, billing_model: string>, creation_timestamp: string, operator_version: string, parameters: table<kind: string, id: string, href: string, value: string>, state: string, state_description: string, updated_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addons/($addoninstallation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the add-on installation.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/addons/{addoninstallation_id}
# --addon shape: {kind?: string, id?: string, href?: string, common_annotations?: record, common_labels?: record, config?: any, credentials_requests?: list, description?: string, docs_link?: string, enabled?: bool, has_external_resources?: bool, hidden?: bool, icon?: string, install_mode?: "all_namespaces"|"own_namespace", label?: string, managed_service?: bool, name?: string, namespaces?: list, operator_name?: string, parameters?: list, requirements?: list, resource_cost?: float, resource_name?: string, sub_operators?: list, target_namespace?: string, version?: any}
# --addon_version shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
# --billing shape: {kind?: string, id?: string, href?: string, billing_marketplace_account?: string, billing_model?: "marketplace"|"marketplace-aws"|"marketplace-gcp"|"marketplace-rhm"|"marketplace-azure"|"standard"}
# --parameters item shape: {kind?: string, id?: string, href?: string, value?: string}
export def "clusters-mgmt-clusters-addons patch" [
  cluster_id: string
  addoninstallation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AddOnInstallation' if this is a complete object or 'AddOnInstallationLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --addon: any # Representation of an add-on that can be installed in a cluster. — shape: {kind?: string, id?: string, href?: string, common_annotations?: record, common_labels?: record, config?: any, credentials_requests?: list, description?: string, docs_link?: string, enabled?: bool, has_external_resources?: bool, hidden?: bool, icon?: string, install_mode?: "all_namespaces"|"own_namespace", label?: string, managed_service?: bool, name?: string, namespaces?: list, operator_name?: string, parameters?: list, requirements?: list, resource_cost?: float, resource_name?: string, sub_operators?: list, target_namespace?: string, version?: any}
  --addon-version: any # Representation of an add-on version. — shape: {kind?: string, id?: string, href?: string, additional_catalog_sources?: list, available_upgrades?: list, channel?: string, config?: any, enabled?: bool, package_image?: string, parameters?: list, pull_secret_name?: string, requirements?: list, source_image?: string, sub_operators?: list}
  --billing: any # Representation of an add-on installation billing. — shape: {kind?: string, id?: string, href?: string, billing_marketplace_account?: string, billing_model?: "marketplace"|"marketplace-aws"|"marketplace-gcp"|"marketplace-rhm"|"marketplace-azure"|"standard"}
  --creation-timestamp: string # Date and time when the add-on was initially installed in the cluster. (format: date-time)
  --operator-version: string # Version of the operator installed by the add-on.
  --parameters: list # List of add-on parameters for this add-on installation. — item shape: {kind?: string, id?: string, href?: string, value?: string}
  --state: string@state-completer-1 # Representation of an add-on installation State field.
  --state-description: string # Reason for the current State.
  --updated-timestamp: string # Date and time when the add-on installation information was last updated. (format: date-time)
]: any -> record<kind: string, id: string, href: string, addon: record<kind: string, id: string, href: string, common_annotations: record, common_labels: record, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, credentials_requests: list<record>, description: string, docs_link: string, enabled: bool, has_external_resources: bool, hidden: bool, icon: string, install_mode: string, label: string, managed_service: bool, name: string, namespaces: list<record>, operator_name: string, parameters: list<record>, requirements: list<record>, resource_cost: float, resource_name: string, sub_operators: list<record>, target_namespace: string, version: record<kind: string, id: string, href: string, additional_catalog_sources: list, available_upgrades: list, channel: string, config: record, enabled: bool, package_image: string, parameters: list, pull_secret_name: string, requirements: list, source_image: string, sub_operators: list>>, addon_version: record<kind: string, id: string, href: string, additional_catalog_sources: list<record>, available_upgrades: list<string>, channel: string, config: record<kind: string, id: string, href: string, add_on_environment_variables: list, secret_propagations: list>, enabled: bool, package_image: string, parameters: list<record>, pull_secret_name: string, requirements: list<record>, source_image: string, sub_operators: list<record>>, billing: record<kind: string, id: string, href: string, billing_marketplace_account: string, billing_model: string>, creation_timestamp: string, operator_version: string, parameters: table<kind: string, id: string, href: string, value: string>, state: string, state_description: string, updated_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/addons/($addoninstallation_id)")
  let body = {kind: $kind, id: $id, href: $href, addon: $addon, addon_version: $addon_version, billing: $billing, creation_timestamp: $creation_timestamp, operator_version: $operator_version, parameters: $parameters, state: $state, state_description: $state_description, updated_timestamp: $updated_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the cluster autoscaler.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/autoscaler
export def "clusters-mgmt-clusters-autoscaler delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/autoscaler")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the autoscaler of a cluster.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/autoscaler
export def "clusters-mgmt-clusters-autoscaler get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list<record>, cores: record<max: int, min: int>, max_nodes_total: int, memory: record<max: int, min: int>>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/autoscaler")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new cluster autoscaler object.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/autoscaler
# --resource_limits shape: {gpus?: list, cores?: any, max_nodes_total?: int, memory?: any}
# --scale_down shape: {delay_after_add?: string, delay_after_delete?: string, delay_after_failure?: string, enabled?: bool, unneeded_time?: string, utilization_threshold?: string}
export def "clusters-mgmt-clusters-autoscaler post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ClusterAutoscaler' if this is a complete object or 'ClusterAutoscalerLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --balance-similar-node-groups: string@bool-completer # BalanceSimilarNodeGroups enables/disables the `--balance-similar-node-groups` cluster-autoscaler feature. This feature will automatically identify node groups with the same instance type and the same set of labels and try to keep the respective sizes of those node groups balanced.
  --balancing-ignored-labels: list # This option specifies labels that cluster autoscaler should ignore when considering node group similarity. For example, if you have nodes with "topology.ebs.csi.aws.com/zone" label, you can add name of this label here to prevent cluster autoscaler from splitting nodes into different node groups based on its value.
  --ignore-daemonsets-utilization: string@bool-completer # Should CA ignore DaemonSet pods when calculating resource utilization for scaling down. false by default.
  --log-verbosity: int # Sets the autoscaler log level. Default value is 1, level 4 is recommended for DEBUGGING and level 6 will enable almost everything. (format: int32)
  --max-node-provision-time: string # Maximum time CA waits for node to be provisioned.
  --max-pod-grace-period: int # Gives pods graceful termination time before scaling down. (format: int32)
  --pod-priority-threshold: int # To allow users to schedule "best-effort" pods, which shouldn't trigger Cluster Autoscaler actions, but only run when there are spare resources available, More info: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-cluster-autoscaler-work-with-pod-priority-and-preemption. (format: int32)
  --resource-limits: any # shape: {gpus?: list, cores?: any, max_nodes_total?: int, memory?: any}
  --scale-down: any # shape: {delay_after_add?: string, delay_after_delete?: string, delay_after_failure?: string, enabled?: bool, unneeded_time?: string, utilization_threshold?: string}
  --skip-nodes-with-local-storage: string@bool-completer # Enables/Disables `--skip-nodes-with-local-storage` CA feature flag. If true cluster autoscaler will never delete nodes with pods with local storage, e.g. EmptyDir or HostPath. true by default at autoscaler.
]: any -> record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list<record>, cores: record<max: int, min: int>, max_nodes_total: int, memory: record<max: int, min: int>>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/autoscaler")
  let body = {kind: $kind, id: $id, href: $href, balance_similar_node_groups: $balance_similar_node_groups, balancing_ignored_labels: $balancing_ignored_labels, ignore_daemonsets_utilization: $ignore_daemonsets_utilization, log_verbosity: $log_verbosity, max_node_provision_time: $max_node_provision_time, max_pod_grace_period: $max_pod_grace_period, pod_priority_threshold: $pod_priority_threshold, resource_limits: $resource_limits, scale_down: $scale_down, skip_nodes_with_local_storage: $skip_nodes_with_local_storage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the cluster autoscaler.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/autoscaler
# --resource_limits shape: {gpus?: list, cores?: any, max_nodes_total?: int, memory?: any}
# --scale_down shape: {delay_after_add?: string, delay_after_delete?: string, delay_after_failure?: string, enabled?: bool, unneeded_time?: string, utilization_threshold?: string}
export def "clusters-mgmt-clusters-autoscaler patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ClusterAutoscaler' if this is a complete object or 'ClusterAutoscalerLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --balance-similar-node-groups: string@bool-completer # BalanceSimilarNodeGroups enables/disables the `--balance-similar-node-groups` cluster-autoscaler feature. This feature will automatically identify node groups with the same instance type and the same set of labels and try to keep the respective sizes of those node groups balanced.
  --balancing-ignored-labels: list # This option specifies labels that cluster autoscaler should ignore when considering node group similarity. For example, if you have nodes with "topology.ebs.csi.aws.com/zone" label, you can add name of this label here to prevent cluster autoscaler from splitting nodes into different node groups based on its value.
  --ignore-daemonsets-utilization: string@bool-completer # Should CA ignore DaemonSet pods when calculating resource utilization for scaling down. false by default.
  --log-verbosity: int # Sets the autoscaler log level. Default value is 1, level 4 is recommended for DEBUGGING and level 6 will enable almost everything. (format: int32)
  --max-node-provision-time: string # Maximum time CA waits for node to be provisioned.
  --max-pod-grace-period: int # Gives pods graceful termination time before scaling down. (format: int32)
  --pod-priority-threshold: int # To allow users to schedule "best-effort" pods, which shouldn't trigger Cluster Autoscaler actions, but only run when there are spare resources available, More info: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-cluster-autoscaler-work-with-pod-priority-and-preemption. (format: int32)
  --resource-limits: any # shape: {gpus?: list, cores?: any, max_nodes_total?: int, memory?: any}
  --scale-down: any # shape: {delay_after_add?: string, delay_after_delete?: string, delay_after_failure?: string, enabled?: bool, unneeded_time?: string, utilization_threshold?: string}
  --skip-nodes-with-local-storage: string@bool-completer # Enables/Disables `--skip-nodes-with-local-storage` CA feature flag. If true cluster autoscaler will never delete nodes with pods with local storage, e.g. EmptyDir or HostPath. true by default at autoscaler.
]: any -> record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list<record>, cores: record<max: int, min: int>, max_nodes_total: int, memory: record<max: int, min: int>>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/autoscaler")
  let body = {kind: $kind, id: $id, href: $href, balance_similar_node_groups: $balance_similar_node_groups, balancing_ignored_labels: $balancing_ignored_labels, ignore_daemonsets_utilization: $ignore_daemonsets_utilization, log_verbosity: $log_verbosity, max_node_provision_time: $max_node_provision_time, max_pod_grace_period: $max_pod_grace_period, pod_priority_threshold: $pod_priority_threshold, resource_limits: $resource_limits, scale_down: $scale_down, skip_nodes_with_local_storage: $skip_nodes_with_local_storage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of the configuration for the Private Link.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/aws/private_link_configuration
export def "clusters-mgmt-clusters-aws-private-link-configuration get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<principals: record<kind: string, id: string, href: string, principals: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws/private_link_configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new principal for the Private Link.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/aws/private_link_configuration/principals
export def "clusters-mgmt-clusters-aws-private-link-configuration-principals post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'PrivateLinkPrincipal' if this is a complete object or 'PrivateLinkPrincipalLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --principal: string # ARN for a principal that is allowed for this Private Link.
]: any -> record<kind: string, id: string, href: string, principal: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws/private_link_configuration/principals")
  let body = {kind: $kind, id: $id, href: $href, principal: $principal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of principals.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/aws/private_link_configuration/principals
export def "clusters-mgmt-clusters-aws-private-link-configuration-principals list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the role binding instead of the names of the columns of a table. For example, in order to retrieve role bindings with role_id AuthenticatedUser:  ```sql role_id = 'AuthenticatedUser' ```  If the parameter isn't provided, or if the value is empty, then all the items that the user has permission to see will be returned.
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, principal: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws/private_link_configuration/principals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the principal.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/aws/private_link_configuration/principals/{principal_id}
export def "clusters-mgmt-clusters-aws-private-link-configuration-principals delete" [
  cluster_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws/private_link_configuration/principals/($principal_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the principal.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/aws/private_link_configuration/principals/{principal_id}
export def "clusters-mgmt-clusters-aws-private-link-configuration-principals get" [
  cluster_id: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, principal: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws/private_link_configuration/principals/($principal_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/aws/role_policy_bindings
export def "clusters-mgmt-clusters-aws-role-policy-bindings get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fetchCurrent: string@bool-completer # If true, retrieves role policy binding states from AWS.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<arn: string, creation_timestamp: string, last_update_timestamp: string, name: string, policies: list, status: record, type: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetchCurrent" $fetchCurrent "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws/role_policy_bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new AWS infrastructure access role grant and add it to the collection of AWS infrastructure access role grants on the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/aws_infrastructure_access_role_grants
# --role shape: {kind?: string, id?: string, href?: string, description?: string, display_name?: string, state?: "invalid"|"removed"|"valid"}
export def "clusters-mgmt-clusters-aws-infrastructure-access-role-grants post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'AWSInfrastructureAccessRoleGrant' if this is a complete object or 'AWSInfrastructureAccessRoleGrantLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --console-url: string # URL to switch to the role in AWS console.
  --role: any # A set of acces permissions for AWS resources — shape: {kind?: string, id?: string, href?: string, description?: string, display_name?: string, state?: "invalid"|"removed"|"valid"}
  --state: string@state-completer-2 # State of an AWS infrastructure access role grant.
  --state-description: string # Description of the state. Will be empty unless state is 'Failed'.
  --user-arn: string # The user AWS IAM ARN we want to grant the role.
]: any -> record<kind: string, id: string, href: string, console_url: string, role: record<kind: string, id: string, href: string, description: string, display_name: string, state: string>, state: string, state_description: string, user_arn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws_infrastructure_access_role_grants")
  let body = {kind: $kind, id: $id, href: $href, console_url: $console_url, role: $role, state: $state, state_description: $state_description, user_arn: $user_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of AWS infrastructure access role grants.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/aws_infrastructure_access_role_grants
export def "clusters-mgmt-clusters-aws-infrastructure-access-role-grants list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the AWS infrastructure access role grant instead of the names of the columns of a table. For example, in order to sort the AWS infrastructure access role grants descending by user ARN the value should be:  ```sql user_arn desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the AWS infrastructure access role grant instead of the names of the columns of a table. For example, in order to retrieve all the AWS infrastructure access role grants with a user ARN starting with `user` the value should be:  ```sql user_arn like '%user' ```  If the parameter isn't provided, or if the value is empty, then all the AWS infrastructure access role grants that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, console_url: string, role: record, state: string, state_description: string, user_arn: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws_infrastructure_access_role_grants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the AWS infrastructure access role grant.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/aws_infrastructure_access_role_grants/{aws_infrastructure_access_role_grant_id}
export def "clusters-mgmt-clusters-aws-infrastructure-access-role-grants delete" [
  cluster_id: string
  aws_infrastructure_access_role_grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws_infrastructure_access_role_grants/($aws_infrastructure_access_role_grant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the AWS infrastructure access role grant.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/aws_infrastructure_access_role_grants/{aws_infrastructure_access_role_grant_id}
export def "clusters-mgmt-clusters-aws-infrastructure-access-role-grants get" [
  cluster_id: string
  aws_infrastructure_access_role_grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, console_url: string, role: record<kind: string, id: string, href: string, description: string, display_name: string, state: string>, state: string, state_description: string, user_arn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/aws_infrastructure_access_role_grants/($aws_infrastructure_access_role_grant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new break glass credential to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/break_glass_credentials
export def "clusters-mgmt-clusters-break-glass-credentials post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'BreakGlassCredential' if this is a complete object or 'BreakGlassCredentialLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --expiration-timestamp: string # ExpirationTimestamp is the date and time when the credential will expire. (format: date-time)
  --kubeconfig: string # Kubeconfig is the generated kubeconfig for this credential. It is only stored in memory
  --revocation-timestamp: string # RevocationTimestamp is the date and time when the credential has been revoked. (format: date-time)
  --status: string@status-completer # Status of the break glass credential.
  --username: string # Username is the user which will be used for this credential.
]: any -> record<kind: string, id: string, href: string, expiration_timestamp: string, kubeconfig: string, revocation_timestamp: string, status: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/break_glass_credentials")
  let body = {kind: $kind, id: $id, href: $href, expiration_timestamp: $expiration_timestamp, kubeconfig: $kubeconfig, revocation_timestamp: $revocation_timestamp, status: $status, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revokes all the break glass certificates signed by a specific signer.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/break_glass_credentials
export def "clusters-mgmt-clusters-break-glass-credentials delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/break_glass_credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of break glass credentials.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/break_glass_credentials
export def "clusters-mgmt-clusters-break-glass-credentials list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the break glass credentials instead of the the names of the columns of a table. For example, in order to sort the credentials descending by identifier the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the break glass credentials instead of the names of the columns of a table. For example, in order to retrieve all the credentials with a specific username and status the following is required:  ```sql username='user1' AND status='expired' ```  If the parameter isn't provided, or if the value is empty, then all the break glass credentials that the user has permission to see will be returned.
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, expiration_timestamp: string, kubeconfig: string, revocation_timestamp: string, status: string, username: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/break_glass_credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the break glass credential.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/break_glass_credentials/{break_glass_credential_id}
export def "clusters-mgmt-clusters-break-glass-credentials get" [
  cluster_id: string
  break_glass_credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, expiration_timestamp: string, kubeconfig: string, revocation_timestamp: string, status: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/break_glass_credentials/($break_glass_credential_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the clusterdeployment.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/clusterdeployment
export def "clusters-mgmt-clusters-clusterdeployment delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/clusterdeployment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the control plane
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane
export def "clusters-mgmt-clusters-control-plane get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<backup: record<state: string>, log_forwarders: table<kind: string, id: string, href: string, s3: record, applications: list, cloudwatch: record, cluster_id: string, groups: list, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the control plane
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane
# --backup shape: {state?: string}
# --log_forwarders item shape: {kind?: string, id?: string, href?: string, s3?: any, applications?: list, cloudwatch?: any, cluster_id?: string, groups?: list, status?: any}
export def "clusters-mgmt-clusters-control-plane patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backup: any # Representation of a Backup. — shape: {state?: string}
  --log-forwarders: list # Control plane log forwarders configuration. This can be set during cluster creation to configure control plane log forwarders. — item shape: {kind?: string, id?: string, href?: string, s3?: any, applications?: list, cloudwatch?: any, cluster_id?: string, groups?: list, status?: any}
]: any -> record<backup: record<state: string>, log_forwarders: table<kind: string, id: string, href: string, s3: record, applications: list, cloudwatch: record, cluster_id: string, groups: list, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane")
  let body = {backup: $backup, log_forwarders: $log_forwarders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new log forwarder.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/log_forwarders
# --s3 shape: {bucket_name?: string, bucket_prefix?: string}
# --cloudwatch shape: {log_distribution_role_arn?: string, log_group_name?: string}
# --groups item shape: {id?: string, version?: string}
# --status shape: {message?: string, resolved_applications?: list, state?: string}
export def "clusters-mgmt-clusters-control-plane-log-forwarders post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'LogForwarder' if this is a complete object or 'LogForwarderLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --s3: any # S3 configuration for log forwarding. — shape: {bucket_name?: string, bucket_prefix?: string}
  --applications: list # List of additional applications to forward logs for.
  --cloudwatch: any # CloudWatch configuration for log forwarding. — shape: {log_distribution_role_arn?: string, log_group_name?: string}
  --body-cluster-id: string # Identifier of the cluster.
  --groups: list # List of log forwarder groups. — item shape: {id?: string, version?: string}
  --status: any # Represents the status of a log forwarder. — shape: {message?: string, resolved_applications?: list, state?: string}
]: any -> record<kind: string, id: string, href: string, s3: record<bucket_name: string, bucket_prefix: string>, applications: list<string>, cloudwatch: record<log_distribution_role_arn: string, log_group_name: string>, cluster_id: string, groups: table<id: string, version: string>, status: record<message: string, resolved_applications: list<string>, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/log_forwarders")
  let body = {kind: $kind, id: $id, href: $href, s3: $s3, applications: $applications, cloudwatch: $cloudwatch, cluster_id: $body_cluster_id, groups: $groups, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of log forwarders.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/log_forwarders
export def "clusters-mgmt-clusters-control-plane-log-forwarders list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, s3: record, applications: list, cloudwatch: record, cluster_id: string, groups: list, status: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/log_forwarders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the log forwarder.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/log_forwarders/{log_forwarder_id}
export def "clusters-mgmt-clusters-control-plane-log-forwarders delete" [
  cluster_id: string
  log_forwarder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/log_forwarders/($log_forwarder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the log forwarder.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/log_forwarders/{log_forwarder_id}
export def "clusters-mgmt-clusters-control-plane-log-forwarders get" [
  cluster_id: string
  log_forwarder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, s3: record<bucket_name: string, bucket_prefix: string>, applications: list<string>, cloudwatch: record<log_distribution_role_arn: string, log_group_name: string>, cluster_id: string, groups: table<id: string, version: string>, status: record<message: string, resolved_applications: list<string>, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/log_forwarders/($log_forwarder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the log forwarder.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/log_forwarders/{log_forwarder_id}
# --s3 shape: {bucket_name?: string, bucket_prefix?: string}
# --cloudwatch shape: {log_distribution_role_arn?: string, log_group_name?: string}
# --groups item shape: {id?: string, version?: string}
# --status shape: {message?: string, resolved_applications?: list, state?: string}
export def "clusters-mgmt-clusters-control-plane-log-forwarders patch" [
  cluster_id: string
  log_forwarder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'LogForwarder' if this is a complete object or 'LogForwarderLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --s3: any # S3 configuration for log forwarding. — shape: {bucket_name?: string, bucket_prefix?: string}
  --applications: list # List of additional applications to forward logs for.
  --cloudwatch: any # CloudWatch configuration for log forwarding. — shape: {log_distribution_role_arn?: string, log_group_name?: string}
  --body-cluster-id: string # Identifier of the cluster.
  --groups: list # List of log forwarder groups. — item shape: {id?: string, version?: string}
  --status: any # Represents the status of a log forwarder. — shape: {message?: string, resolved_applications?: list, state?: string}
]: any -> record<kind: string, id: string, href: string, s3: record<bucket_name: string, bucket_prefix: string>, applications: list<string>, cloudwatch: record<log_distribution_role_arn: string, log_group_name: string>, cluster_id: string, groups: table<id: string, version: string>, status: record<message: string, resolved_applications: list<string>, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/log_forwarders/($log_forwarder_id)")
  let body = {kind: $kind, id: $id, href: $href, s3: $s3, applications: $applications, cloudwatch: $cloudwatch, cluster_id: $body_cluster_id, groups: $groups, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new upgrade policy to the control plane of the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/upgrade_policies
# --state shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
export def "clusters-mgmt-clusters-control-plane-upgrade-policies post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ControlPlaneUpgradePolicy' if this is a complete object or 'ControlPlaneUpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Cluster ID this upgrade policy for control plane is defined for.
  --creation-timestamp: string # Timestamp for creation of resource. (format: date-time)
  --enable-minor-version-upgrades: string@bool-completer # Indicates if minor version upgrades are allowed for automatic upgrades (for manual it's always allowed).
  --last-update-timestamp: string # Timestamp for last update that happened to resource. (format: date-time)
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string@schedule-type-completer # ScheduleType defines which type of scheduling should be used for the upgrade policy.
  --state: any # Representation of an upgrade policy state that that is set for a cluster. — shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
  --upgrade-type: string@upgrade-type-completer # UpgradeType defines which type of upgrade should be used.
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, schedule: string, schedule_type: string, state: record<kind: string, id: string, href: string, description: string, value: string>, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/upgrade_policies")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, creation_timestamp: $creation_timestamp, enable_minor_version_upgrades: $enable_minor_version_upgrades, last_update_timestamp: $last_update_timestamp, next_run: $next_run, schedule: $schedule, schedule_type: $schedule_type, state: $state, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of upgrade policies for the control plane.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/upgrade_policies
export def "clusters-mgmt-clusters-control-plane-upgrade-policies list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, schedule: string, schedule_type: string, state: record, upgrade_type: string, version: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/upgrade_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the upgrade policy for the control plane.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/upgrade_policies/{control_plane_upgrade_policy_id}
export def "clusters-mgmt-clusters-control-plane-upgrade-policies delete" [
  cluster_id: string
  control_plane_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/upgrade_policies/($control_plane_upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the upgrade policy for the control plane.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/upgrade_policies/{control_plane_upgrade_policy_id}
export def "clusters-mgmt-clusters-control-plane-upgrade-policies get" [
  cluster_id: string
  control_plane_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, schedule: string, schedule_type: string, state: record<kind: string, id: string, href: string, description: string, value: string>, upgrade_type: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/upgrade_policies/($control_plane_upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the upgrade policy for the control plane.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/control_plane/upgrade_policies/{control_plane_upgrade_policy_id}
# --state shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
export def "clusters-mgmt-clusters-control-plane-upgrade-policies patch" [
  cluster_id: string
  control_plane_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ControlPlaneUpgradePolicy' if this is a complete object or 'ControlPlaneUpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Cluster ID this upgrade policy for control plane is defined for.
  --creation-timestamp: string # Timestamp for creation of resource. (format: date-time)
  --enable-minor-version-upgrades: string@bool-completer # Indicates if minor version upgrades are allowed for automatic upgrades (for manual it's always allowed).
  --last-update-timestamp: string # Timestamp for last update that happened to resource. (format: date-time)
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string@schedule-type-completer # ScheduleType defines which type of scheduling should be used for the upgrade policy.
  --state: any # Representation of an upgrade policy state that that is set for a cluster. — shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
  --upgrade-type: string@upgrade-type-completer # UpgradeType defines which type of upgrade should be used.
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, schedule: string, schedule_type: string, state: record<kind: string, id: string, href: string, description: string, value: string>, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/control_plane/upgrade_policies/($control_plane_upgrade_policy_id)")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, creation_timestamp: $creation_timestamp, enable_minor_version_upgrades: $enable_minor_version_upgrades, last_update_timestamp: $last_update_timestamp, next_run: $next_run, schedule: $schedule, schedule_type: $schedule_type, state: $state, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of the credentials of a cluster.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/credentials
export def "clusters-mgmt-clusters-credentials get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, kubeconfig: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/delete_protection
export def "clusters-mgmt-clusters-delete-protection get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/delete_protection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/delete_protection
export def "clusters-mgmt-clusters-delete-protection patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Boolean flag indicating if the cluster should be be using _DeleteProtection_.  By default this is `false`.  To enable it a SREP needs to patch the value through OCM API
]: any -> record<enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/delete_protection")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_auth_config
export def "clusters-mgmt-clusters-external-auth-config get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, enabled: bool, external_auths: table<kind: string, id: string, href: string, claim: record, clients: list, issuer: record, status: record>, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_auth_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new authentication to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/external_auth_config/external_auths
# --claim shape: {mappings?: any, validation_rules?: list}
# --clients item shape: {id?: string, component?: any, extra_scopes?: list, secret?: string, type?: "confidential"|"public"}
# --issuer shape: {ca?: string, url?: string, audiences?: list}
# --status shape: {message?: string, state?: any}
export def "clusters-mgmt-clusters-external-auth-config-external-auths post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ExternalAuth' if this is a complete object or 'ExternalAuthLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --claim: any # The claims and validation rules used in the configuration of the external authentication. — shape: {mappings?: any, validation_rules?: list}
  --clients: list # The list of the platform's clients that need to request tokens from the issuer. — item shape: {id?: string, component?: any, extra_scopes?: list, secret?: string, type?: "confidential"|"public"}
  --issuer: any # Representation of a token issuer used in an external authentication. — shape: {ca?: string, url?: string, audiences?: list}
  --status: any # Representation of the status of an external authentication provider. — shape: {message?: string, state?: any}
]: any -> record<kind: string, id: string, href: string, claim: record<mappings: record<groups: record, username: record>, validation_rules: list<record>>, clients: table<id: string, component: record, extra_scopes: list, secret: string, type: string>, issuer: record<ca: string, url: string, audiences: list<string>>, status: record<message: string, state: record<last_updated_timestamp: string, value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_auth_config/external_auths")
  let body = {kind: $kind, id: $id, href: $href, claim: $claim, clients: $clients, issuer: $issuer, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_auth_config/external_auths
export def "clusters-mgmt-clusters-external-auth-config-external-auths list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, claim: record, clients: list, issuer: record, status: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_auth_config/external_auths" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the external authentication.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/external_auth_config/external_auths/{external_auth_id}
export def "clusters-mgmt-clusters-external-auth-config-external-auths delete" [
  cluster_id: string
  external_auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_auth_config/external_auths/($external_auth_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of an external authentication.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_auth_config/external_auths/{external_auth_id}
export def "clusters-mgmt-clusters-external-auth-config-external-auths get" [
  cluster_id: string
  external_auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, claim: record<mappings: record<groups: record, username: record>, validation_rules: list<record>>, clients: table<id: string, component: record, extra_scopes: list, secret: string, type: string>, issuer: record<ca: string, url: string, audiences: list<string>>, status: record<message: string, state: record<last_updated_timestamp: string, value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_auth_config/external_auths/($external_auth_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the external authentication.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/external_auth_config/external_auths/{external_auth_id}
# --claim shape: {mappings?: any, validation_rules?: list}
# --clients item shape: {id?: string, component?: any, extra_scopes?: list, secret?: string, type?: "confidential"|"public"}
# --issuer shape: {ca?: string, url?: string, audiences?: list}
# --status shape: {message?: string, state?: any}
export def "clusters-mgmt-clusters-external-auth-config-external-auths patch" [
  cluster_id: string
  external_auth_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ExternalAuth' if this is a complete object or 'ExternalAuthLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --claim: any # The claims and validation rules used in the configuration of the external authentication. — shape: {mappings?: any, validation_rules?: list}
  --clients: list # The list of the platform's clients that need to request tokens from the issuer. — item shape: {id?: string, component?: any, extra_scopes?: list, secret?: string, type?: "confidential"|"public"}
  --issuer: any # Representation of a token issuer used in an external authentication. — shape: {ca?: string, url?: string, audiences?: list}
  --status: any # Representation of the status of an external authentication provider. — shape: {message?: string, state?: any}
]: any -> record<kind: string, id: string, href: string, claim: record<mappings: record<groups: record, username: record>, validation_rules: list<record>>, clients: table<id: string, component: record, extra_scopes: list, secret: string, type: string>, issuer: record<ca: string, url: string, audiences: list<string>>, status: record<message: string, state: record<last_updated_timestamp: string, value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_auth_config/external_auths/($external_auth_id)")
  let body = {kind: $kind, id: $id, href: $href, claim: $claim, clients: $clients, issuer: $issuer, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of the external configuration.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration
export def "clusters-mgmt-clusters-external-configuration get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<labels: table<kind: string, id: string, href: string, key: string, value: string>, manifests: table<kind: string, id: string, href: string, creation_timestamp: string, live_resource: record, spec: record, updated_timestamp: string, workloads: list>, syncsets: table<kind: string, id: string, href: string, resources: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new label to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/labels
export def "clusters-mgmt-clusters-external-configuration-labels post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Label' if this is a complete object or 'LabelLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --key: string # the key of the label
  --value: string # the value to set in the label
]: any -> record<kind: string, id: string, href: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/labels")
  let body = {kind: $kind, id: $id, href: $href, key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of labels.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/labels
export def "clusters-mgmt-clusters-external-configuration-labels list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, key: string, value: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the label.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/labels/{label_id}
export def "clusters-mgmt-clusters-external-configuration-labels delete" [
  cluster_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/labels/($label_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the label.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/labels/{label_id}
export def "clusters-mgmt-clusters-external-configuration-labels get" [
  cluster_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/labels/($label_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the label.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/labels/{label_id}
export def "clusters-mgmt-clusters-external-configuration-labels patch" [
  cluster_id: string
  label_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Label' if this is a complete object or 'LabelLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --key: string # the key of the label
  --value: string # the value to set in the label
]: any -> record<kind: string, id: string, href: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/labels/($label_id)")
  let body = {kind: $kind, id: $id, href: $href, key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new manifest to a cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/manifests
export def "clusters-mgmt-clusters-external-configuration-manifests post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Manifest' if this is a complete object or 'ManifestLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --creation-timestamp: string # Date and time when the manifest got created in OCM database. (format: date-time)
  --live-resource: record # Transient value to represent the underlying live resource.
  --spec: record # Spec of Manifest Work object from open cluster management For more info please check https://open-cluster-management.io/concepts/manifestwork.
  --updated-timestamp: string # Date and time when the manifest got updated in OCM database. (format: date-time)
  --workloads: list # List of k8s objects to deploy on a hosted cluster.
]: any -> record<kind: string, id: string, href: string, creation_timestamp: string, live_resource: record, spec: record, updated_timestamp: string, workloads: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/manifests")
  let body = {kind: $kind, id: $id, href: $href, creation_timestamp: $creation_timestamp, live_resource: $live_resource, spec: $spec, updated_timestamp: $updated_timestamp, workloads: $workloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of manifests.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/manifests
export def "clusters-mgmt-clusters-external-configuration-manifests list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, creation_timestamp: string, live_resource: record, spec: record, updated_timestamp: string, workloads: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/manifests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the manifest.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/manifests/{manifest_id}
export def "clusters-mgmt-clusters-external-configuration-manifests delete" [
  cluster_id: string
  manifest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/manifests/($manifest_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the manifest.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/manifests/{manifest_id}
export def "clusters-mgmt-clusters-external-configuration-manifests get" [
  cluster_id: string
  manifest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, creation_timestamp: string, live_resource: record, spec: record, updated_timestamp: string, workloads: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/manifests/($manifest_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the manifest.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/manifests/{manifest_id}
export def "clusters-mgmt-clusters-external-configuration-manifests patch" [
  cluster_id: string
  manifest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Manifest' if this is a complete object or 'ManifestLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --creation-timestamp: string # Date and time when the manifest got created in OCM database. (format: date-time)
  --live-resource: record # Transient value to represent the underlying live resource.
  --spec: record # Spec of Manifest Work object from open cluster management For more info please check https://open-cluster-management.io/concepts/manifestwork.
  --updated-timestamp: string # Date and time when the manifest got updated in OCM database. (format: date-time)
  --workloads: list # List of k8s objects to deploy on a hosted cluster.
]: any -> record<kind: string, id: string, href: string, creation_timestamp: string, live_resource: record, spec: record, updated_timestamp: string, workloads: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/manifests/($manifest_id)")
  let body = {kind: $kind, id: $id, href: $href, creation_timestamp: $creation_timestamp, live_resource: $live_resource, spec: $spec, updated_timestamp: $updated_timestamp, workloads: $workloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new syncset to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/syncsets
export def "clusters-mgmt-clusters-external-configuration-syncsets post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Syncset' if this is a complete object or 'SyncsetLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --resources: list # List of k8s objects to configure for the cluster.
]: any -> record<kind: string, id: string, href: string, resources: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/syncsets")
  let body = {kind: $kind, id: $id, href: $href, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of syncsets.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/syncsets
export def "clusters-mgmt-clusters-external-configuration-syncsets list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, resources: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/syncsets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the syncset.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/syncsets/{syncset_id}
export def "clusters-mgmt-clusters-external-configuration-syncsets delete" [
  cluster_id: string
  syncset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/syncsets/($syncset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the syncset.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/syncsets/{syncset_id}
export def "clusters-mgmt-clusters-external-configuration-syncsets get" [
  cluster_id: string
  syncset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, resources: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/syncsets/($syncset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the syncset.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/external_configuration/syncsets/{syncset_id}
export def "clusters-mgmt-clusters-external-configuration-syncsets patch" [
  cluster_id: string
  syncset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Syncset' if this is a complete object or 'SyncsetLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --resources: list # List of k8s objects to configure for the cluster.
]: any -> record<kind: string, id: string, href: string, resources: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/external_configuration/syncsets/($syncset_id)")
  let body = {kind: $kind, id: $id, href: $href, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new agreed version gate to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/gate_agreements
# --version_gate shape: {kind?: string, id?: string, href?: string, sts_only?: bool, cluster_condition?: string, creation_timestamp?: string, description?: string, documentation_url?: string, label?: string, value?: string, version_raw_id_prefix?: string, warning_message?: string}
export def "clusters-mgmt-clusters-gate-agreements post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'VersionGateAgreement' if this is a complete object or 'VersionGateAgreementLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --agreed-timestamp: string # The time the user agreed to the version gate (format: date-time)
  --version-gate: any # Representation of an _OpenShift_ version gate. — shape: {kind?: string, id?: string, href?: string, sts_only?: bool, cluster_condition?: string, creation_timestamp?: string, description?: string, documentation_url?: string, label?: string, value?: string, version_raw_id_prefix?: string, warning_message?: string}
]: any -> record<kind: string, id: string, href: string, agreed_timestamp: string, version_gate: record<kind: string, id: string, href: string, sts_only: bool, cluster_condition: string, creation_timestamp: string, description: string, documentation_url: string, label: string, value: string, version_raw_id_prefix: string, warning_message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/gate_agreements")
  let body = {kind: $kind, id: $id, href: $href, agreed_timestamp: $agreed_timestamp, version_gate: $version_gate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of reasons.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/gate_agreements
export def "clusters-mgmt-clusters-gate-agreements list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, agreed_timestamp: string, version_gate: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/gate_agreements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the version gate agreement.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/gate_agreements/{version_gate_agreement_id}
export def "clusters-mgmt-clusters-gate-agreements delete" [
  cluster_id: string
  version_gate_agreement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/gate_agreements/($version_gate_agreement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the version gate agreement.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/gate_agreements/{version_gate_agreement_id}
export def "clusters-mgmt-clusters-gate-agreements get" [
  cluster_id: string
  version_gate_agreement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, agreed_timestamp: string, version_gate: record<kind: string, id: string, href: string, sts_only: bool, cluster_condition: string, creation_timestamp: string, description: string, documentation_url: string, label: string, value: string, version_raw_id_prefix: string, warning_message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/gate_agreements/($version_gate_agreement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of groups.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/groups
export def "clusters-mgmt-clusters-groups list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, users: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the group.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/groups/{group_id}
export def "clusters-mgmt-clusters-groups get" [
  cluster_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, users: table<kind: string, id: string, href: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new user to the group.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/groups/{group_id}/users
export def "clusters-mgmt-clusters-groups-users post" [
  cluster_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'User' if this is a complete object or 'UserLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
]: any -> record<kind: string, id: string, href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/groups/($group_id)/users")
  let body = {kind: $kind, id: $id, href: $href} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of users.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/groups/{group_id}/users
export def "clusters-mgmt-clusters-groups-users list" [
  cluster_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/groups/($group_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the user.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/groups/{group_id}/users/{user_id}
export def "clusters-mgmt-clusters-groups-users delete" [
  cluster_id: string
  group_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/groups/($group_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the user.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/groups/{group_id}/users/{user_id}
export def "clusters-mgmt-clusters-groups-users get" [
  cluster_id: string
  group_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/groups/($group_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the Hypershift details for a single cluster.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/hypershift
export def "clusters-mgmt-clusters-hypershift get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<hcp_namespace: string, enabled: bool, management_cluster: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/hypershift")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the Hypershift details for a single cluster.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/hypershift
export def "clusters-mgmt-clusters-hypershift patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hcp-namespace: string # Contains the name of the hcp namespace for this Hypershift cluster. Empty for non Hypershift clusters.
  --enabled: string@bool-completer # Boolean flag indicating if the cluster should be creating using _Hypershift_.  By default this is `false`.  To enable it the cluster needs to be ROSA cluster and the organization of the user needs to have the `hypershift` capability enabled.
  --management-cluster: string # Contains the name of the current management cluster for this Hypershift cluster. Empty for non Hypershift clusters.
]: any -> record<hcp_namespace: string, enabled: bool, management_cluster: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/hypershift")
  let body = {hcp_namespace: $hcp_namespace, enabled: $enabled, management_cluster: $management_cluster} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new identity provider to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers
# --ldap shape: {ca?: string, url?: string, attributes?: any, bind_dn?: string, bind_password?: string, insecure?: bool}
# --github shape: {ca?: string, client_id?: string, client_secret?: string, hostname?: string, organizations?: list, teams?: list}
# --gitlab shape: {ca?: string, url?: string, client_id?: string, client_secret?: string}
# --google shape: {client_id?: string, client_secret?: string, hosted_domain?: string}
# --htpasswd shape: {password?: string, username?: string, users?: list}
# --open_id shape: {ca?: string, claims?: any, client_id?: string, client_secret?: string, extra_authorize_parameters?: record, extra_scopes?: list, issuer?: string}
export def "clusters-mgmt-clusters-identity-providers post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'IdentityProvider' if this is a complete object or 'IdentityProviderLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --ldap: any # Details for `ldap` identity providers. — shape: {ca?: string, url?: string, attributes?: any, bind_dn?: string, bind_password?: string, insecure?: bool}
  --challenge: string@bool-completer # When `true` unauthenticated token requests from non-web clients (like the CLI) are sent a `WWW-Authenticate` challenge header for this provider.
  --github: any # Details for `github` identity providers. — shape: {ca?: string, client_id?: string, client_secret?: string, hostname?: string, organizations?: list, teams?: list}
  --gitlab: any # Details for `gitlab` identity providers. — shape: {ca?: string, url?: string, client_id?: string, client_secret?: string}
  --google: any # Details for `google` identity providers. — shape: {client_id?: string, client_secret?: string, hosted_domain?: string}
  --htpasswd: any # Details for `htpasswd` identity providers. — shape: {password?: string, username?: string, users?: list}
  --login: string@bool-completer # When `true` unauthenticated token requests from web clients (like the web console) are redirected to the authorize URL to log in.
  --mapping-method: string@mapping-method-completer # Controls how mappings are established between provider identities and user objects.
  --name: string # The name of the identity provider.
  --open-id: any # Details for `openid` identity providers. — shape: {ca?: string, claims?: any, client_id?: string, client_secret?: string, extra_authorize_parameters?: record, extra_scopes?: list, issuer?: string}
  --type: string@type-completer # Type of identity provider.
]: any -> record<kind: string, id: string, href: string, ldap: record<ca: string, url: string, attributes: record<id: list, email: list, name: list, preferred_username: list>, bind_dn: string, bind_password: string, insecure: bool>, challenge: bool, github: record<ca: string, client_id: string, client_secret: string, hostname: string, organizations: list<string>, teams: list<string>>, gitlab: record<ca: string, url: string, client_id: string, client_secret: string>, google: record<client_id: string, client_secret: string, hosted_domain: string>, htpasswd: record<password: string, username: string, users: list<record>>, login: bool, mapping_method: string, name: string, open_id: record<ca: string, claims: record<email: list, groups: list, name: list, preferred_username: list>, client_id: string, client_secret: string, extra_authorize_parameters: record, extra_scopes: list<string>, issuer: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers")
  let body = {kind: $kind, id: $id, href: $href, ldap: $ldap, challenge: $challenge, github: $github, gitlab: $gitlab, google: $google, htpasswd: $htpasswd, login: $login, mapping_method: $mapping_method, name: $name, open_id: $open_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of identity providers.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers
export def "clusters-mgmt-clusters-identity-providers list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, ldap: record, challenge: bool, github: record, gitlab: record, google: record, htpasswd: record, login: bool, mapping_method: string, name: string, open_id: record, type: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the identity provider.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}
export def "clusters-mgmt-clusters-identity-providers delete" [
  cluster_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the identity provider.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}
export def "clusters-mgmt-clusters-identity-providers get" [
  cluster_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, ldap: record<ca: string, url: string, attributes: record<id: list, email: list, name: list, preferred_username: list>, bind_dn: string, bind_password: string, insecure: bool>, challenge: bool, github: record<ca: string, client_id: string, client_secret: string, hostname: string, organizations: list<string>, teams: list<string>>, gitlab: record<ca: string, url: string, client_id: string, client_secret: string>, google: record<client_id: string, client_secret: string, hosted_domain: string>, htpasswd: record<password: string, username: string, users: list<record>>, login: bool, mapping_method: string, name: string, open_id: record<ca: string, claims: record<email: list, groups: list, name: list, preferred_username: list>, client_id: string, client_secret: string, extra_authorize_parameters: record, extra_scopes: list<string>, issuer: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update identity provider in the cluster.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}
# --ldap shape: {ca?: string, url?: string, attributes?: any, bind_dn?: string, bind_password?: string, insecure?: bool}
# --github shape: {ca?: string, client_id?: string, client_secret?: string, hostname?: string, organizations?: list, teams?: list}
# --gitlab shape: {ca?: string, url?: string, client_id?: string, client_secret?: string}
# --google shape: {client_id?: string, client_secret?: string, hosted_domain?: string}
# --htpasswd shape: {password?: string, username?: string, users?: list}
# --open_id shape: {ca?: string, claims?: any, client_id?: string, client_secret?: string, extra_authorize_parameters?: record, extra_scopes?: list, issuer?: string}
export def "clusters-mgmt-clusters-identity-providers patch" [
  cluster_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'IdentityProvider' if this is a complete object or 'IdentityProviderLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --ldap: any # Details for `ldap` identity providers. — shape: {ca?: string, url?: string, attributes?: any, bind_dn?: string, bind_password?: string, insecure?: bool}
  --challenge: string@bool-completer # When `true` unauthenticated token requests from non-web clients (like the CLI) are sent a `WWW-Authenticate` challenge header for this provider.
  --github: any # Details for `github` identity providers. — shape: {ca?: string, client_id?: string, client_secret?: string, hostname?: string, organizations?: list, teams?: list}
  --gitlab: any # Details for `gitlab` identity providers. — shape: {ca?: string, url?: string, client_id?: string, client_secret?: string}
  --google: any # Details for `google` identity providers. — shape: {client_id?: string, client_secret?: string, hosted_domain?: string}
  --htpasswd: any # Details for `htpasswd` identity providers. — shape: {password?: string, username?: string, users?: list}
  --login: string@bool-completer # When `true` unauthenticated token requests from web clients (like the web console) are redirected to the authorize URL to log in.
  --mapping-method: string@mapping-method-completer # Controls how mappings are established between provider identities and user objects.
  --name: string # The name of the identity provider.
  --open-id: any # Details for `openid` identity providers. — shape: {ca?: string, claims?: any, client_id?: string, client_secret?: string, extra_authorize_parameters?: record, extra_scopes?: list, issuer?: string}
  --type: string@type-completer # Type of identity provider.
]: any -> record<kind: string, id: string, href: string, ldap: record<ca: string, url: string, attributes: record<id: list, email: list, name: list, preferred_username: list>, bind_dn: string, bind_password: string, insecure: bool>, challenge: bool, github: record<ca: string, client_id: string, client_secret: string, hostname: string, organizations: list<string>, teams: list<string>>, gitlab: record<ca: string, url: string, client_id: string, client_secret: string>, google: record<client_id: string, client_secret: string, hosted_domain: string>, htpasswd: record<password: string, username: string, users: list<record>>, login: bool, mapping_method: string, name: string, open_id: record<ca: string, claims: record<email: list, groups: list, name: list, preferred_username: list>, client_id: string, client_secret: string, extra_authorize_parameters: record, extra_scopes: list<string>, issuer: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)")
  let body = {kind: $kind, id: $id, href: $href, ldap: $ldap, challenge: $challenge, github: $github, gitlab: $gitlab, google: $google, htpasswd: $htpasswd, login: $login, mapping_method: $mapping_method, name: $name, open_id: $open_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new user to the _HTPasswd_ file.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}/htpasswd_users
export def "clusters-mgmt-clusters-identity-providers-htpasswd-users post" [
  cluster_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # ID for a secondary user in the _HTPasswd_ data file.
  --hashed-password: string # HTPasswd Hashed Password for a user in the _HTPasswd_ data file. The value of this field is set as-is in the _HTPasswd_ data file for the HTPasswd IDP
  --password: string # Password in plain-text for a  user in the _HTPasswd_ data file. The value of this field is hashed before setting it in the  _HTPasswd_ data file for the HTPasswd IDP
  --username: string # Username for a secondary user in the _HTPasswd_ data file.
]: any -> record<id: string, hashed_password: string, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)/htpasswd_users")
  let body = {id: $id, hashed_password: $hashed_password, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of _HTPasswd_ IDP users.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}/htpasswd_users
export def "clusters-mgmt-clusters-identity-providers-htpasswd-users list" [
  cluster_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<id: string, hashed_password: string, password: string, username: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)/htpasswd_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds multiple new users to the _HTPasswd_ file.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}/htpasswd_users/import
# --items item shape: {id?: string, hashed_password?: string, password?: string, username?: string}
export def "clusters-mgmt-clusters-identity-providers-htpasswd-users-import post" [
  cluster_id: string
  identity_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --items: list # List of users to add to the IDP. — item shape: {id?: string, hashed_password?: string, password?: string, username?: string}
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: any -> record<items: table<id: string, hashed_password: string, password: string, username: string>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)/htpasswd_users/import")
  let body = {items: $items, page: $page, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the user.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}/htpasswd_users/{htpasswd_user_id}
export def "clusters-mgmt-clusters-identity-providers-htpasswd-users delete" [
  cluster_id: string
  identity_provider_id: string
  htpasswd_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)/htpasswd_users/($htpasswd_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the user.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}/htpasswd_users/{htpasswd_user_id}
export def "clusters-mgmt-clusters-identity-providers-htpasswd-users get" [
  cluster_id: string
  identity_provider_id: string
  htpasswd_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, hashed_password: string, password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)/htpasswd_users/($htpasswd_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the user's password. The username is not editable
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/identity_providers/{identity_provider_id}/htpasswd_users/{htpasswd_user_id}
export def "clusters-mgmt-clusters-identity-providers-htpasswd-users patch" [
  cluster_id: string
  identity_provider_id: string
  htpasswd_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # ID for a secondary user in the _HTPasswd_ data file.
  --hashed-password: string # HTPasswd Hashed Password for a user in the _HTPasswd_ data file. The value of this field is set as-is in the _HTPasswd_ data file for the HTPasswd IDP
  --password: string # Password in plain-text for a  user in the _HTPasswd_ data file. The value of this field is hashed before setting it in the  _HTPasswd_ data file for the HTPasswd IDP
  --username: string # Username for a secondary user in the _HTPasswd_ data file.
]: any -> record<id: string, hashed_password: string, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/identity_providers/($identity_provider_id)/htpasswd_users/($htpasswd_user_id)")
  let body = {id: $id, hashed_password: $hashed_password, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new image mirror configuration for the cluster. Cluster must be in ready state for this operation to succeed.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/image_mirrors
export def "clusters-mgmt-clusters-image-mirrors post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ImageMirror' if this is a complete object or 'ImageMirrorLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --creation-timestamp: string # CreationTimestamp indicates when the image mirror was created. (format: date-time)
  --last-update-timestamp: string # LastUpdateTimestamp indicates when the image mirror was last updated. (format: date-time)
  --mirrors: list # Mirrors is the list of mirror registries that will serve content for the source. Mirrors array cannot be empty (must contain at least one mirror registry). Each mirror registry URL must conform to OpenShift's ImageDigestMirrorSet format specifications.
  --body-source: string # Source is the source registry that will be mirrored. Source registry must be unique per cluster and is immutable after creation. Source is used to identify mirror entries in HostedCluster imageContentSources.
  --type: string # Type specifies the mirror type, currently only "digest" is supported.
]: any -> record<kind: string, id: string, href: string, creation_timestamp: string, last_update_timestamp: string, mirrors: list<string>, source: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/image_mirrors")
  let body = {kind: $kind, id: $id, href: $href, creation_timestamp: $creation_timestamp, last_update_timestamp: $last_update_timestamp, mirrors: $mirrors, source: $body_source, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of image mirrors for the cluster.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/image_mirrors
export def "clusters-mgmt-clusters-image-mirrors list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria for sorting results.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria for filtering results. Searchable fields: id, name, cluster_id, source, type All searchable fields can be ordered with asc/desc direction, default order by id
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, creation_timestamp: string, last_update_timestamp: string, mirrors: list, source: string, type: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/image_mirrors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the image mirror configuration.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/image_mirrors/{image_mirror_id}
export def "clusters-mgmt-clusters-image-mirrors delete" [
  cluster_id: string
  image_mirror_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/image_mirrors/($image_mirror_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the image mirror.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/image_mirrors/{image_mirror_id}
export def "clusters-mgmt-clusters-image-mirrors get" [
  cluster_id: string
  image_mirror_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, creation_timestamp: string, last_update_timestamp: string, mirrors: list<string>, source: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/image_mirrors/($image_mirror_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the image mirror configuration. Note: Id and Source fields are immutable and cannot be updated. The mirrors array is completely replaced, not merged.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/image_mirrors/{image_mirror_id}
export def "clusters-mgmt-clusters-image-mirrors patch" [
  cluster_id: string
  image_mirror_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ImageMirror' if this is a complete object or 'ImageMirrorLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --creation-timestamp: string # CreationTimestamp indicates when the image mirror was created. (format: date-time)
  --last-update-timestamp: string # LastUpdateTimestamp indicates when the image mirror was last updated. (format: date-time)
  --mirrors: list # Mirrors is the list of mirror registries that will serve content for the source. Mirrors array cannot be empty (must contain at least one mirror registry). Each mirror registry URL must conform to OpenShift's ImageDigestMirrorSet format specifications.
  --body-source: string # Source is the source registry that will be mirrored. Source registry must be unique per cluster and is immutable after creation. Source is used to identify mirror entries in HostedCluster imageContentSources.
  --type: string # Type specifies the mirror type, currently only "digest" is supported.
]: any -> record<kind: string, id: string, href: string, creation_timestamp: string, last_update_timestamp: string, mirrors: list<string>, source: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/image_mirrors/($image_mirror_id)")
  let body = {kind: $kind, id: $id, href: $href, creation_timestamp: $creation_timestamp, last_update_timestamp: $last_update_timestamp, mirrors: $mirrors, source: $body_source, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of inflight checks.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/inflight_checks
export def "clusters-mgmt-clusters-inflight-checks list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, details: record, ended_at: string, name: string, restarts: int, started_at: string, state: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/inflight_checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the inflight check.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/inflight_checks/{inflight_check_id}
export def "clusters-mgmt-clusters-inflight-checks get" [
  cluster_id: string
  inflight_check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, details: record, ended_at: string, name: string, restarts: int, started_at: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/inflight_checks/($inflight_check_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new ingress to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/ingresses
# --excluded_namespace_selectors item shape: {key?: string, values?: list}
export def "clusters-mgmt-clusters-ingresses post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Ingress' if this is a complete object or 'IngressLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --dns-name: string # DNS Name of the ingress.
  --cluster-routes-hostname: string # Cluster routes hostname.
  --cluster-routes-tls-secret-ref: string # Cluster routes TLS Secret reference.
  --component-routes: record # Component Routes settings.
  --default: string@bool-completer # Indicates if this is the default ingress.
  --excluded-namespace-selectors: list # A set of excluded exclude namespaces via labels for ingress. — item shape: {key?: string, values?: list}
  --excluded-namespaces: list # A set of excluded namespaces for the ingress.
  --listening: string@listening-completer # Cluster components listening method.
  --load-balancer-type: string@load-balancer-type-completer # Type of load balancer for AWS cloud provider parameters.
  --route-namespace-ownership-policy: string@route-namespace-ownership-policy-completer # Type of Namespace Ownership Policy.
  --route-selectors: record # A set of labels for the ingress. 
  --route-wildcard-policy: string@route-wildcard-policy-completer # Type of wildcard policy.
]: any -> record<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: table<key: string, values: list>, excluded_namespaces: list<string>, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/ingresses")
  let body = {kind: $kind, id: $id, href: $href, dns_name: $dns_name, cluster_routes_hostname: $cluster_routes_hostname, cluster_routes_tls_secret_ref: $cluster_routes_tls_secret_ref, component_routes: $component_routes, default: $default, excluded_namespace_selectors: $excluded_namespace_selectors, excluded_namespaces: $excluded_namespaces, listening: $listening, load_balancer_type: $load_balancer_type, route_namespace_ownership_policy: $route_namespace_ownership_policy, route_selectors: $route_selectors, route_wildcard_policy: $route_wildcard_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of ingresses.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/ingresses
export def "clusters-mgmt-clusters-ingresses list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: list, excluded_namespaces: list, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/ingresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates all ingresses
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/ingresses
export def "clusters-mgmt-clusters-ingresses patch-by-cluster_id" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: list<record>, excluded_namespaces: list<string>, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/ingresses")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the ingress.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/ingresses/{ingress_id}
export def "clusters-mgmt-clusters-ingresses delete" [
  cluster_id: string
  ingress_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/ingresses/($ingress_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the ingress.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/ingresses/{ingress_id}
export def "clusters-mgmt-clusters-ingresses get" [
  cluster_id: string
  ingress_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: table<key: string, values: list>, excluded_namespaces: list<string>, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/ingresses/($ingress_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the ingress.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/ingresses/{ingress_id}
# --excluded_namespace_selectors item shape: {key?: string, values?: list}
export def "clusters-mgmt-clusters-ingresses patch-by-cluster_id-ingress_id" [
  cluster_id: string
  ingress_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Ingress' if this is a complete object or 'IngressLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --dns-name: string # DNS Name of the ingress.
  --cluster-routes-hostname: string # Cluster routes hostname.
  --cluster-routes-tls-secret-ref: string # Cluster routes TLS Secret reference.
  --component-routes: record # Component Routes settings.
  --default: string@bool-completer # Indicates if this is the default ingress.
  --excluded-namespace-selectors: list # A set of excluded exclude namespaces via labels for ingress. — item shape: {key?: string, values?: list}
  --excluded-namespaces: list # A set of excluded namespaces for the ingress.
  --listening: string@listening-completer # Cluster components listening method.
  --load-balancer-type: string@load-balancer-type-completer # Type of load balancer for AWS cloud provider parameters.
  --route-namespace-ownership-policy: string@route-namespace-ownership-policy-completer # Type of Namespace Ownership Policy.
  --route-selectors: record # A set of labels for the ingress. 
  --route-wildcard-policy: string@route-wildcard-policy-completer # Type of wildcard policy.
]: any -> record<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: table<key: string, values: list>, excluded_namespaces: list<string>, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/ingresses/($ingress_id)")
  let body = {kind: $kind, id: $id, href: $href, dns_name: $dns_name, cluster_routes_hostname: $cluster_routes_hostname, cluster_routes_tls_secret_ref: $cluster_routes_tls_secret_ref, component_routes: $component_routes, default: $default, excluded_namespace_selectors: $excluded_namespace_selectors, excluded_namespaces: $excluded_namespaces, listening: $listening, load_balancer_type: $load_balancer_type, route_namespace_ownership_policy: $route_namespace_ownership_policy, route_selectors: $route_selectors, route_wildcard_policy: $route_wildcard_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the cluster KubeletConfig
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_config
export def "clusters-mgmt-clusters-kubelet-config delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the KubeletConfig for a cluster
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_config
export def "clusters-mgmt-clusters-kubelet-config get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, name: string, pod_pids_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new cluster KubeletConfig
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_config
export def "clusters-mgmt-clusters-kubelet-config post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'KubeletConfig' if this is a complete object or 'KubeletConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --name: string # Allows the user to specify the name to be used to identify this KubeletConfig. Optional. A name will be generated if not provided.
  --pod-pids-limit: int # Allows the user to specify the podPidsLimit to be applied via KubeletConfig. Useful if workloads have greater PIDs limit requirements than the OCP default. (format: int32)
]: any -> record<kind: string, id: string, href: string, name: string, pod_pids_limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_config")
  let body = {kind: $kind, id: $id, href: $href, name: $name, pod_pids_limit: $pod_pids_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the existing cluster KubeletConfig
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_config
export def "clusters-mgmt-clusters-kubelet-config patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'KubeletConfig' if this is a complete object or 'KubeletConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --name: string # Allows the user to specify the name to be used to identify this KubeletConfig. Optional. A name will be generated if not provided.
  --pod-pids-limit: int # Allows the user to specify the podPidsLimit to be applied via KubeletConfig. Useful if workloads have greater PIDs limit requirements than the OCP default. (format: int32)
]: any -> record<kind: string, id: string, href: string, name: string, pod_pids_limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_config")
  let body = {kind: $kind, id: $id, href: $href, name: $name, pod_pids_limit: $pod_pids_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new KubeletConfig to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_configs
export def "clusters-mgmt-clusters-kubelet-configs post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'KubeletConfig' if this is a complete object or 'KubeletConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --name: string # Allows the user to specify the name to be used to identify this KubeletConfig. Optional. A name will be generated if not provided.
  --pod-pids-limit: int # Allows the user to specify the podPidsLimit to be applied via KubeletConfig. Useful if workloads have greater PIDs limit requirements than the OCP default. (format: int32)
]: any -> record<kind: string, id: string, href: string, name: string, pod_pids_limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_configs")
  let body = {kind: $kind, id: $id, href: $href, name: $name, pod_pids_limit: $pod_pids_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of KubeletConfigs for the cluster.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_configs
export def "clusters-mgmt-clusters-kubelet-configs list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the KubeletConfig specified by the id.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_configs/{kubelet_config_id}
export def "clusters-mgmt-clusters-kubelet-configs delete" [
  cluster_id: string
  kubelet_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_configs/($kubelet_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the KubeletConfig specified by the id.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_configs/{kubelet_config_id}
export def "clusters-mgmt-clusters-kubelet-configs get" [
  cluster_id: string
  kubelet_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, name: string, pod_pids_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_configs/($kubelet_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the KubeletConfig specified by the id.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/kubelet_configs/{kubelet_config_id}
export def "clusters-mgmt-clusters-kubelet-configs patch" [
  cluster_id: string
  kubelet_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'KubeletConfig' if this is a complete object or 'KubeletConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --name: string # Allows the user to specify the name to be used to identify this KubeletConfig. Optional. A name will be generated if not provided.
  --pod-pids-limit: int # Allows the user to specify the podPidsLimit to be applied via KubeletConfig. Useful if workloads have greater PIDs limit requirements than the OCP default. (format: int32)
]: any -> record<kind: string, id: string, href: string, name: string, pod_pids_limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/kubelet_configs/($kubelet_config_id)")
  let body = {kind: $kind, id: $id, href: $href, name: $name, pod_pids_limit: $pod_pids_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new reason to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/limited_support_reasons
# --override shape: {kind?: string, id?: string, href?: string, enabled?: bool}
# --template shape: {kind?: string, id?: string, href?: string, details?: string, summary?: string}
export def "clusters-mgmt-clusters-limited-support-reasons post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'LimitedSupportReason' if this is a complete object or 'LimitedSupportReasonLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --creation-timestamp: string # The time the reason was detected. (format: date-time)
  --details: string # URL with a link to a detailed description of the reason.
  --detection-type: string@detection-type-completer
  --override: any # Representation of the limited support reason override. — shape: {kind?: string, id?: string, href?: string, enabled?: bool}
  --summary: string # Summary of the reason.
  --template: any # A template for cluster limited support reason. — shape: {kind?: string, id?: string, href?: string, details?: string, summary?: string}
]: any -> record<kind: string, id: string, href: string, creation_timestamp: string, details: string, detection_type: string, override: record<kind: string, id: string, href: string, enabled: bool>, summary: string, template: record<kind: string, id: string, href: string, details: string, summary: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/limited_support_reasons")
  let body = {kind: $kind, id: $id, href: $href, creation_timestamp: $creation_timestamp, details: $details, detection_type: $detection_type, override: $override, summary: $summary, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of reasons.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/limited_support_reasons
export def "clusters-mgmt-clusters-limited-support-reasons list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, creation_timestamp: string, details: string, detection_type: string, override: record, summary: string, template: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/limited_support_reasons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the reason.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/limited_support_reasons/{limited_support_reason_id}
export def "clusters-mgmt-clusters-limited-support-reasons delete" [
  cluster_id: string
  limited_support_reason_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/limited_support_reasons/($limited_support_reason_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the reason.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/limited_support_reasons/{limited_support_reason_id}
export def "clusters-mgmt-clusters-limited-support-reasons get" [
  cluster_id: string
  limited_support_reason_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, creation_timestamp: string, details: string, detection_type: string, override: record<kind: string, id: string, href: string, enabled: bool>, summary: string, template: record<kind: string, id: string, href: string, details: string, summary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/limited_support_reasons/($limited_support_reason_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of log links.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/logs
export def "clusters-mgmt-clusters-logs get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, content: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the log.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/logs/install
export def "clusters-mgmt-clusters-logs-install get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Line offset to start logs from. if 0 retreive entire log. If offset > #lines return an empty log. (format: int32)
  --tail: int # Returns the number of tail lines from the end of the log. If there are no line breaks or the number of lines < tail return the entire log. Either 'tail' or 'offset' can be set. Not both.  (format: int32)
]: nothing -> record<kind: string, id: string, href: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/logs/install" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the log.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/logs/uninstall
export def "clusters-mgmt-clusters-logs-uninstall get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Line offset to start logs from. if 0 retreive entire log. If offset > #lines return an empty log. (format: int32)
  --tail: int # Returns the number of tail lines from the end of the log. If there are no line breaks or the number of lines < tail return the entire log. Either 'tail' or 'offset' can be set. Not both.  (format: int32)
]: nothing -> record<kind: string, id: string, href: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/logs/uninstall" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new machine pool to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/machine_pools
# --aws shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, spot_market_options?: any, subnet_outposts?: record, tags?: record}
# --gcp shape: {secure_boot?: bool}
# --autoscaling shape: {kind?: string, id?: string, href?: string, max_replicas?: int, min_replicas?: int}
# --root_volume shape: {aws?: any, gcp?: any}
# --security_group_filters item shape: {name?: string, value?: string}
# --taints item shape: {effect?: string, key?: string, value?: string}
export def "clusters-mgmt-clusters-machine-pools post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'MachinePool' if this is a complete object or 'MachinePoolLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws: any # Representation of aws machine pool specific parameters. — shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, spot_market_options?: any, subnet_outposts?: record, tags?: record}
  --gcp: any # Representation of gcp machine pool specific parameters. — shape: {secure_boot?: bool}
  --autoscaling: any # Representation of a autoscaling in a machine pool. — shape: {kind?: string, id?: string, href?: string, max_replicas?: int, min_replicas?: int}
  --availability-zones: list # The availability zones upon which the nodes are created.
  --instance-type: string # The instance type of Nodes to create.
  --labels: record # The labels set on the Nodes created.
  --replicas: int # The number of Machines (and Nodes) to create. Replicas and autoscaling cannot be used together. (format: int32)
  --root-volume: any # Root volume capabilities. — shape: {aws?: any, gcp?: any}
  --security-group-filters: list # List of security groups to be applied to MachinePool (Optional) — item shape: {name?: string, value?: string}
  --subnets: list # The subnets upon which the nodes are created.
  --taints: list # The taints set on the Nodes created. — item shape: {effect?: string, key?: string, value?: string}
]: any -> record<kind: string, id: string, href: string, aws: record<kind: string, id: string, href: string, additional_security_group_ids: list<string>, availability_zone_types: record, spot_market_options: record<kind: string, id: string, href: string, max_price: float>, subnet_outposts: record, tags: record>, gcp: record<secure_boot: bool>, autoscaling: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, instance_type: string, labels: record, replicas: int, root_volume: record<aws: record<iops: int, size: int>, gcp: record<size: int>>, security_group_filters: table<name: string, value: string>, subnets: list<string>, taints: table<effect: string, key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/machine_pools")
  let body = {kind: $kind, id: $id, href: $href, aws: $aws, gcp: $gcp, autoscaling: $autoscaling, availability_zones: $availability_zones, instance_type: $instance_type, labels: $labels, replicas: $replicas, root_volume: $root_volume, security_group_filters: $security_group_filters, subnets: $subnets, taints: $taints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of machine pools.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/machine_pools
export def "clusters-mgmt-clusters-machine-pools list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, aws: record, gcp: record, autoscaling: record, availability_zones: list, instance_type: string, labels: record, replicas: int, root_volume: record, security_group_filters: list, subnets: list, taints: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/machine_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the machine pool.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/machine_pools/{machine_pool_id}
export def "clusters-mgmt-clusters-machine-pools delete" [
  cluster_id: string
  machine_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/machine_pools/($machine_pool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the machine pool.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/machine_pools/{machine_pool_id}
export def "clusters-mgmt-clusters-machine-pools get" [
  cluster_id: string
  machine_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, aws: record<kind: string, id: string, href: string, additional_security_group_ids: list<string>, availability_zone_types: record, spot_market_options: record<kind: string, id: string, href: string, max_price: float>, subnet_outposts: record, tags: record>, gcp: record<secure_boot: bool>, autoscaling: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, instance_type: string, labels: record, replicas: int, root_volume: record<aws: record<iops: int, size: int>, gcp: record<size: int>>, security_group_filters: table<name: string, value: string>, subnets: list<string>, taints: table<effect: string, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/machine_pools/($machine_pool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the machine pool.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/machine_pools/{machine_pool_id}
# --aws shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, spot_market_options?: any, subnet_outposts?: record, tags?: record}
# --gcp shape: {secure_boot?: bool}
# --autoscaling shape: {kind?: string, id?: string, href?: string, max_replicas?: int, min_replicas?: int}
# --root_volume shape: {aws?: any, gcp?: any}
# --security_group_filters item shape: {name?: string, value?: string}
# --taints item shape: {effect?: string, key?: string, value?: string}
export def "clusters-mgmt-clusters-machine-pools patch" [
  cluster_id: string
  machine_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'MachinePool' if this is a complete object or 'MachinePoolLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws: any # Representation of aws machine pool specific parameters. — shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, spot_market_options?: any, subnet_outposts?: record, tags?: record}
  --gcp: any # Representation of gcp machine pool specific parameters. — shape: {secure_boot?: bool}
  --autoscaling: any # Representation of a autoscaling in a machine pool. — shape: {kind?: string, id?: string, href?: string, max_replicas?: int, min_replicas?: int}
  --availability-zones: list # The availability zones upon which the nodes are created.
  --instance-type: string # The instance type of Nodes to create.
  --labels: record # The labels set on the Nodes created.
  --replicas: int # The number of Machines (and Nodes) to create. Replicas and autoscaling cannot be used together. (format: int32)
  --root-volume: any # Root volume capabilities. — shape: {aws?: any, gcp?: any}
  --security-group-filters: list # List of security groups to be applied to MachinePool (Optional) — item shape: {name?: string, value?: string}
  --subnets: list # The subnets upon which the nodes are created.
  --taints: list # The taints set on the Nodes created. — item shape: {effect?: string, key?: string, value?: string}
]: any -> record<kind: string, id: string, href: string, aws: record<kind: string, id: string, href: string, additional_security_group_ids: list<string>, availability_zone_types: record, spot_market_options: record<kind: string, id: string, href: string, max_price: float>, subnet_outposts: record, tags: record>, gcp: record<secure_boot: bool>, autoscaling: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, instance_type: string, labels: record, replicas: int, root_volume: record<aws: record<iops: int, size: int>, gcp: record<size: int>>, security_group_filters: table<name: string, value: string>, subnets: list<string>, taints: table<effect: string, key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/machine_pools/($machine_pool_id)")
  let body = {kind: $kind, id: $id, href: $href, aws: $aws, gcp: $gcp, autoscaling: $autoscaling, availability_zones: $availability_zones, instance_type: $instance_type, labels: $labels, replicas: $replicas, root_volume: $root_volume, security_group_filters: $security_group_filters, subnets: $subnets, taints: $taints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/metric_queries/alerts
export def "clusters-mgmt-clusters-metric-queries-alerts get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alerts: table<name: string, severity: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/metric_queries/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/metric_queries/cluster_operators
export def "clusters-mgmt-clusters-metric-queries-cluster-operators get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<operators: table<condition: string, name: string, reason: string, time: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/metric_queries/cluster_operators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the metrics.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/metric_queries/cpu_total_by_node_roles_os
export def "clusters-mgmt-clusters-metric-queries-cpu-total-by-node-roles-os get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cpu_totals: table<cpu_total: float, node_roles: list, operating_system: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/metric_queries/cpu_total_by_node_roles_os")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/metric_queries/nodes
export def "clusters-mgmt-clusters-metric-queries-nodes get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<nodes: table<amount: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/metric_queries/nodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the metrics.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/metric_queries/socket_total_by_node_roles_os
export def "clusters-mgmt-clusters-metric-queries-socket-total-by-node-roles-os get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<socket_totals: table<node_roles: list, operating_system: string, socket_total: float, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/metric_queries/socket_total_by_node_roles_os")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a cluster migration to the database.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/migrations
# --sdn_to_ovn shape: {join_ipv4?: string, masquerade_ipv4?: string, transit_ipv4?: string}
# --state shape: {description?: string, value?: "completed"|"in progress"|"scheduled"}
export def "clusters-mgmt-clusters-migrations post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ClusterMigration' if this is a complete object or 'ClusterMigrationLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Internal cluster ID.
  --creation-timestamp: string # Date and time when the cluster migration was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --sdn-to-ovn: any # Details for `SdnToOvn` cluster migrations. — shape: {join_ipv4?: string, masquerade_ipv4?: string, transit_ipv4?: string}
  --state: any # Representation of a cluster migration state. — shape: {description?: string, value?: "completed"|"in progress"|"scheduled"}
  --type: string@type-completer-1 # Type of cluster migration.
  --updated-timestamp: string # Date and time when the cluster migration was last updated, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
]: any -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, sdn_to_ovn: record<join_ipv4: string, masquerade_ipv4: string, transit_ipv4: string>, state: record<description: string, value: string>, type: string, updated_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/migrations")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, creation_timestamp: $creation_timestamp, sdn_to_ovn: $sdn_to_ovn, state: $state, type: $type, updated_timestamp: $updated_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/migrations
export def "clusters-mgmt-clusters-migrations list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, sdn_to_ovn: record, state: record, type: string, updated_timestamp: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/migrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the cluster migration.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/migrations/{migration_id}
export def "clusters-mgmt-clusters-migrations get" [
  cluster_id: string
  migration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, sdn_to_ovn: record<join_ipv4: string, masquerade_ipv4: string, transit_ipv4: string>, state: record<description: string, value: string>, type: string, updated_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/migrations/($migration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new node pool to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools
# --aws_node_pool shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, capacity_reservation?: any, ec2_metadata_http_tokens?: "optional"|"required", instance_profile?: string, instance_type?: string, root_volume?: any, subnet_outposts?: record, tags?: record}
# --autoscaling shape: {kind?: string, id?: string, href?: string, max_replica?: int, min_replica?: int}
# --azure_node_pool shape: {vm_size?: string, encryption_at_host?: any, os_disk?: any, resource_name?: string}
# --management_upgrade shape: {kind?: string, id?: string, href?: string, max_surge?: string, max_unavailable?: string, type?: string}
# --node_drain_grace_period shape: {unit?: string, value?: float}
# --status shape: {kind?: string, id?: string, href?: string, current_replicas?: int, message?: string, state?: any}
# --taints item shape: {effect?: string, key?: string, value?: string}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-clusters-node-pools post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'NodePool' if this is a complete object or 'NodePoolLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws-node-pool: any # Representation of aws node pool specific parameters. — shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, capacity_reservation?: any, ec2_metadata_http_tokens?: "optional"|"required", instance_profile?: string, instance_type?: string, root_volume?: any, subnet_outposts?: record, tags?: record}
  --auto-repair: string@bool-completer # Specifies whether health checks should be enabled for machines in the NodePool.
  --autoscaling: any # Representation of a autoscaling in a node pool. — shape: {kind?: string, id?: string, href?: string, max_replica?: int, min_replica?: int}
  --availability-zone: string # The availability zone upon which the node is created.
  --azure-node-pool: any # Representation of azure node pool specific parameters. — shape: {vm_size?: string, encryption_at_host?: any, os_disk?: any, resource_name?: string}
  --image-type: string@image-type-completer # Image Type (AMI) to use for running the associated NodePool
  --kubelet-configs: list # The names of the KubeletConfigs for this node pool.
  --labels: record # The labels set on the Nodes created.
  --management-upgrade: any # Representation of node pool management. — shape: {kind?: string, id?: string, href?: string, max_surge?: string, max_unavailable?: string, type?: string}
  --node-drain-grace-period: any # Numeric value and the unit used to measure it.  Units are not mandatory, and they're not specified for some resources. For resources that use bytes, the accepted units are:  - 1 B = 1 byte - 1 KB = 10^3 bytes - 1 MB = 10^6 bytes - 1 GB = 10^9 bytes - 1 TB = 10^12 bytes - 1 PB = 10^15 bytes  - 1 B = 1 byte - 1 KiB = 2^10 bytes - 1 MiB = 2^20 bytes - 1 GiB = 2^30 bytes - 1 TiB = 2^40 bytes - 1 PiB = 2^50 bytes — shape: {unit?: string, value?: float}
  --replicas: int # The number of Machines (and Nodes) to create. Replicas and autoscaling cannot be used together. (format: int32)
  --status: any # Representation of the status of a node pool. — shape: {kind?: string, id?: string, href?: string, current_replicas?: int, message?: string, state?: any}
  --subnet: string # The subnet upon which the nodes are created.
  --taints: list # The taints set on the Nodes created. — item shape: {effect?: string, key?: string, value?: string}
  --tuning-configs: list # The names of the tuning configs for this node pool.
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
]: any -> record<kind: string, id: string, href: string, aws_node_pool: record<kind: string, id: string, href: string, additional_security_group_ids: list<string>, availability_zone_types: record, capacity_reservation: record<id: string, market_type: string, preference: string>, ec2_metadata_http_tokens: string, instance_profile: string, instance_type: string, root_volume: record<iops: int, size: int>, subnet_outposts: record, tags: record>, auto_repair: bool, autoscaling: record<kind: string, id: string, href: string, max_replica: int, min_replica: int>, availability_zone: string, azure_node_pool: record<vm_size: string, encryption_at_host: record<state: string>, os_disk: record<persistence: string, size_gibibytes: int, sse_encryption_set_resource_id: string, storage_account_type: string>, resource_name: string>, image_type: string, kubelet_configs: list<string>, labels: record, management_upgrade: record<kind: string, id: string, href: string, max_surge: string, max_unavailable: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, replicas: int, status: record<kind: string, id: string, href: string, current_replicas: int, message: string, state: record<kind: string, id: string, href: string, last_updated_timestamp: string, value: string>>, subnet: string, taints: table<effect: string, key: string, value: string>, tuning_configs: list<string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools")
  let body = {kind: $kind, id: $id, href: $href, aws_node_pool: $aws_node_pool, auto_repair: $auto_repair, autoscaling: $autoscaling, availability_zone: $availability_zone, azure_node_pool: $azure_node_pool, image_type: $image_type, kubelet_configs: $kubelet_configs, labels: $labels, management_upgrade: $management_upgrade, node_drain_grace_period: $node_drain_grace_period, replicas: $replicas, status: $status, subnet: $subnet, taints: $taints, tuning_configs: $tuning_configs, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of node pools.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools
export def "clusters-mgmt-clusters-node-pools list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the node pools instead of the names of the columns of a table. For example, in order to sort the node pools descending by identifier the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the node pools instead of the names of the columns of a table. For example, in order to retrieve all the node pools with replicas of two the following is required:  ```sql replicas = 2 ```  If the parameter isn't provided, or if the value is empty, then all the node pools that the user has permission to see will be returned.
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, aws_node_pool: record, auto_repair: bool, autoscaling: record, availability_zone: string, azure_node_pool: record, image_type: string, kubelet_configs: list, labels: record, management_upgrade: record, node_drain_grace_period: record, replicas: int, status: record, subnet: string, taints: list, tuning_configs: list, version: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the node pool.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}
export def "clusters-mgmt-clusters-node-pools delete" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the node pool.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}
export def "clusters-mgmt-clusters-node-pools get" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, aws_node_pool: record<kind: string, id: string, href: string, additional_security_group_ids: list<string>, availability_zone_types: record, capacity_reservation: record<id: string, market_type: string, preference: string>, ec2_metadata_http_tokens: string, instance_profile: string, instance_type: string, root_volume: record<iops: int, size: int>, subnet_outposts: record, tags: record>, auto_repair: bool, autoscaling: record<kind: string, id: string, href: string, max_replica: int, min_replica: int>, availability_zone: string, azure_node_pool: record<vm_size: string, encryption_at_host: record<state: string>, os_disk: record<persistence: string, size_gibibytes: int, sse_encryption_set_resource_id: string, storage_account_type: string>, resource_name: string>, image_type: string, kubelet_configs: list<string>, labels: record, management_upgrade: record<kind: string, id: string, href: string, max_surge: string, max_unavailable: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, replicas: int, status: record<kind: string, id: string, href: string, current_replicas: int, message: string, state: record<kind: string, id: string, href: string, last_updated_timestamp: string, value: string>>, subnet: string, taints: table<effect: string, key: string, value: string>, tuning_configs: list<string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the node pool.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}
# --aws_node_pool shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, capacity_reservation?: any, ec2_metadata_http_tokens?: "optional"|"required", instance_profile?: string, instance_type?: string, root_volume?: any, subnet_outposts?: record, tags?: record}
# --autoscaling shape: {kind?: string, id?: string, href?: string, max_replica?: int, min_replica?: int}
# --azure_node_pool shape: {vm_size?: string, encryption_at_host?: any, os_disk?: any, resource_name?: string}
# --management_upgrade shape: {kind?: string, id?: string, href?: string, max_surge?: string, max_unavailable?: string, type?: string}
# --node_drain_grace_period shape: {unit?: string, value?: float}
# --status shape: {kind?: string, id?: string, href?: string, current_replicas?: int, message?: string, state?: any}
# --taints item shape: {effect?: string, key?: string, value?: string}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-clusters-node-pools patch" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'NodePool' if this is a complete object or 'NodePoolLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws-node-pool: any # Representation of aws node pool specific parameters. — shape: {kind?: string, id?: string, href?: string, additional_security_group_ids?: list, availability_zone_types?: record, capacity_reservation?: any, ec2_metadata_http_tokens?: "optional"|"required", instance_profile?: string, instance_type?: string, root_volume?: any, subnet_outposts?: record, tags?: record}
  --auto-repair: string@bool-completer # Specifies whether health checks should be enabled for machines in the NodePool.
  --autoscaling: any # Representation of a autoscaling in a node pool. — shape: {kind?: string, id?: string, href?: string, max_replica?: int, min_replica?: int}
  --availability-zone: string # The availability zone upon which the node is created.
  --azure-node-pool: any # Representation of azure node pool specific parameters. — shape: {vm_size?: string, encryption_at_host?: any, os_disk?: any, resource_name?: string}
  --image-type: string@image-type-completer # Image Type (AMI) to use for running the associated NodePool
  --kubelet-configs: list # The names of the KubeletConfigs for this node pool.
  --labels: record # The labels set on the Nodes created.
  --management-upgrade: any # Representation of node pool management. — shape: {kind?: string, id?: string, href?: string, max_surge?: string, max_unavailable?: string, type?: string}
  --node-drain-grace-period: any # Numeric value and the unit used to measure it.  Units are not mandatory, and they're not specified for some resources. For resources that use bytes, the accepted units are:  - 1 B = 1 byte - 1 KB = 10^3 bytes - 1 MB = 10^6 bytes - 1 GB = 10^9 bytes - 1 TB = 10^12 bytes - 1 PB = 10^15 bytes  - 1 B = 1 byte - 1 KiB = 2^10 bytes - 1 MiB = 2^20 bytes - 1 GiB = 2^30 bytes - 1 TiB = 2^40 bytes - 1 PiB = 2^50 bytes — shape: {unit?: string, value?: float}
  --replicas: int # The number of Machines (and Nodes) to create. Replicas and autoscaling cannot be used together. (format: int32)
  --status: any # Representation of the status of a node pool. — shape: {kind?: string, id?: string, href?: string, current_replicas?: int, message?: string, state?: any}
  --subnet: string # The subnet upon which the nodes are created.
  --taints: list # The taints set on the Nodes created. — item shape: {effect?: string, key?: string, value?: string}
  --tuning-configs: list # The names of the tuning configs for this node pool.
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
]: any -> record<kind: string, id: string, href: string, aws_node_pool: record<kind: string, id: string, href: string, additional_security_group_ids: list<string>, availability_zone_types: record, capacity_reservation: record<id: string, market_type: string, preference: string>, ec2_metadata_http_tokens: string, instance_profile: string, instance_type: string, root_volume: record<iops: int, size: int>, subnet_outposts: record, tags: record>, auto_repair: bool, autoscaling: record<kind: string, id: string, href: string, max_replica: int, min_replica: int>, availability_zone: string, azure_node_pool: record<vm_size: string, encryption_at_host: record<state: string>, os_disk: record<persistence: string, size_gibibytes: int, sse_encryption_set_resource_id: string, storage_account_type: string>, resource_name: string>, image_type: string, kubelet_configs: list<string>, labels: record, management_upgrade: record<kind: string, id: string, href: string, max_surge: string, max_unavailable: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, replicas: int, status: record<kind: string, id: string, href: string, current_replicas: int, message: string, state: record<kind: string, id: string, href: string, last_updated_timestamp: string, value: string>>, subnet: string, taints: table<effect: string, key: string, value: string>, tuning_configs: list<string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)")
  let body = {kind: $kind, id: $id, href: $href, aws_node_pool: $aws_node_pool, auto_repair: $auto_repair, autoscaling: $autoscaling, availability_zone: $availability_zone, azure_node_pool: $azure_node_pool, image_type: $image_type, kubelet_configs: $kubelet_configs, labels: $labels, management_upgrade: $management_upgrade, node_drain_grace_period: $node_drain_grace_period, replicas: $replicas, status: $status, subnet: $subnet, taints: $taints, tuning_configs: $tuning_configs, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new upgrade policy to the node pool of the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}/upgrade_policies
# --state shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
export def "clusters-mgmt-clusters-node-pools-upgrade-policies post" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'NodePoolUpgradePolicy' if this is a complete object or 'NodePoolUpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Cluster ID this upgrade policy for node pool is defined for.
  --creation-timestamp: string # Timestamp for creation of resource. (format: date-time)
  --enable-minor-version-upgrades: string@bool-completer # Indicates if minor version upgrades are allowed for automatic upgrades (for manual it's always allowed).
  --last-update-timestamp: string # Timestamp for last update that happened to resource. (format: date-time)
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --body-node-pool-id: string # Node Pool ID this upgrade policy is defined for.
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string@schedule-type-completer # ScheduleType defines which type of scheduling should be used for the upgrade policy.
  --state: any # Representation of an upgrade policy state that that is set for a cluster. — shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
  --upgrade-type: string@upgrade-type-completer # UpgradeType defines which type of upgrade should be used.
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, node_pool_id: string, schedule: string, schedule_type: string, state: record<kind: string, id: string, href: string, description: string, value: string>, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)/upgrade_policies")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, creation_timestamp: $creation_timestamp, enable_minor_version_upgrades: $enable_minor_version_upgrades, last_update_timestamp: $last_update_timestamp, next_run: $next_run, node_pool_id: $body_node_pool_id, schedule: $schedule, schedule_type: $schedule_type, state: $state, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of upgrade policies for the node pool.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}/upgrade_policies
export def "clusters-mgmt-clusters-node-pools-upgrade-policies list" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, node_pool_id: string, schedule: string, schedule_type: string, state: record, upgrade_type: string, version: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)/upgrade_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the upgrade policy for the node pool.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}/upgrade_policies/{node_pool_upgrade_policy_id}
export def "clusters-mgmt-clusters-node-pools-upgrade-policies delete" [
  cluster_id: string
  node_pool_id: string
  node_pool_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)/upgrade_policies/($node_pool_upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the upgrade policy for the node pool.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}/upgrade_policies/{node_pool_upgrade_policy_id}
export def "clusters-mgmt-clusters-node-pools-upgrade-policies get" [
  cluster_id: string
  node_pool_id: string
  node_pool_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, node_pool_id: string, schedule: string, schedule_type: string, state: record<kind: string, id: string, href: string, description: string, value: string>, upgrade_type: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)/upgrade_policies/($node_pool_upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the upgrade policy for the node pool.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/node_pools/{node_pool_id}/upgrade_policies/{node_pool_upgrade_policy_id}
# --state shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
export def "clusters-mgmt-clusters-node-pools-upgrade-policies patch" [
  cluster_id: string
  node_pool_id: string
  node_pool_upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'NodePoolUpgradePolicy' if this is a complete object or 'NodePoolUpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Cluster ID this upgrade policy for node pool is defined for.
  --creation-timestamp: string # Timestamp for creation of resource. (format: date-time)
  --enable-minor-version-upgrades: string@bool-completer # Indicates if minor version upgrades are allowed for automatic upgrades (for manual it's always allowed).
  --last-update-timestamp: string # Timestamp for last update that happened to resource. (format: date-time)
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --body-node-pool-id: string # Node Pool ID this upgrade policy is defined for.
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string@schedule-type-completer # ScheduleType defines which type of scheduling should be used for the upgrade policy.
  --state: any # Representation of an upgrade policy state that that is set for a cluster. — shape: {kind?: string, id?: string, href?: string, description?: string, value?: "cancelled"|"completed"|"delayed"|"failed"|"pending"|"scheduled"|"started"}
  --upgrade-type: string@upgrade-type-completer # UpgradeType defines which type of upgrade should be used.
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, enable_minor_version_upgrades: bool, last_update_timestamp: string, next_run: string, node_pool_id: string, schedule: string, schedule_type: string, state: record<kind: string, id: string, href: string, description: string, value: string>, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/node_pools/($node_pool_id)/upgrade_policies/($node_pool_upgrade_policy_id)")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, creation_timestamp: $creation_timestamp, enable_minor_version_upgrades: $enable_minor_version_upgrades, last_update_timestamp: $last_update_timestamp, next_run: $next_run, node_pool_id: $body_node_pool_id, schedule: $schedule, schedule_type: $schedule_type, state: $state, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the provision shard.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/provision_shard
export def "clusters-mgmt-clusters-provision-shard delete" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/provision_shard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the provision shard.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/provision_shard
export def "clusters-mgmt-clusters-provision-shard get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/provision_shard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the details of the provision shard.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/provision_shard
# --aws_account_operator_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --gcp_project_operator shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
# --hive_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --hypershift_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
export def "clusters-mgmt-clusters-provision-shard patch" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ProvisionShard' if this is a complete object or 'ProvisionShardLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws-account-operator-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --aws-base-domain: string # Contains the AWS base domain.
  --gcp-base-domain: string # Contains the GCP base domain.
  --gcp-project-operator: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --creation-timestamp: string # Date and time when the provision shard was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --hive-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --hypershift-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --last-update-timestamp: string # Date and time when the provision shard was last updated, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --management-cluster: string # Contains the name of the management cluster for Hypershift clusters that are assigned to this shard. This field is populated by OCM, and must not be overwritten via API.
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --status: string # Status of the provision shard. Possible values: active/maintenance/offline.
]: any -> record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/provision_shard")
  let body = {kind: $kind, id: $id, href: $href, aws_account_operator_config: $aws_account_operator_config, aws_base_domain: $aws_base_domain, gcp_base_domain: $gcp_base_domain, gcp_project_operator: $gcp_project_operator, cloud_provider: $cloud_provider, creation_timestamp: $creation_timestamp, hive_config: $hive_config, hypershift_config: $hypershift_config, last_update_timestamp: $last_update_timestamp, management_cluster: $management_cluster, region: $region, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of resources for a cluster in error state
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/resources
export def "clusters-mgmt-clusters-resources get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, resources: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves currently available cluster resources
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/resources/live
export def "clusters-mgmt-clusters-resources-live get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster_id: string, creation_timestamp: string, resources: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/resources/live")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/status
export def "clusters-mgmt-clusters-status get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new operator role to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/sts_operator_roles
export def "clusters-mgmt-clusters-sts-operator-roles post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Randomly-generated ID to identify the operator role
  --name: string # Name of the credentials secret used to access cloud resources
  --namespace: string # Namespace where the credentials secret lives in the cluster
  --role-arn: string # Role to assume when accessing AWS resources
  --service-account: string # Service account name to use when authenticating
]: any -> record<id: string, name: string, namespace: string, role_arn: string, service_account: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/sts_operator_roles")
  let body = {id: $id, name: $name, namespace: $namespace, role_arn: $role_arn, service_account: $service_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of operator roles.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/sts_operator_roles
export def "clusters-mgmt-clusters-sts-operator-roles get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<id: string, name: string, namespace: string, role_arn: string, service_account: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/sts_operator_roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the operator role.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/sts_operator_roles/{operator_iam_role_id}
export def "clusters-mgmt-clusters-sts-operator-roles delete" [
  cluster_id: string
  operator_iam_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/sts_operator_roles/($operator_iam_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/sts_support_jump_role
export def "clusters-mgmt-clusters-sts-support-jump-role get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<role_arn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/sts_support_jump_role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new tuning config to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/tuning_configs
export def "clusters-mgmt-clusters-tuning-configs post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'TuningConfig' if this is a complete object or 'TuningConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --name: string # Name of the tuning config.
  --spec: record # Spec of the tuning config.
]: any -> record<kind: string, id: string, href: string, name: string, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/tuning_configs")
  let body = {kind: $kind, id: $id, href: $href, name: $name, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of tuning configs.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/tuning_configs
export def "clusters-mgmt-clusters-tuning-configs list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, name: string, spec: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/tuning_configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the tuning config.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/tuning_configs/{tuning_config_id}
export def "clusters-mgmt-clusters-tuning-configs delete" [
  cluster_id: string
  tuning_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/tuning_configs/($tuning_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the tuning config.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/tuning_configs/{tuning_config_id}
export def "clusters-mgmt-clusters-tuning-configs get" [
  cluster_id: string
  tuning_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, name: string, spec: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/tuning_configs/($tuning_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the tuning config.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/tuning_configs/{tuning_config_id}
export def "clusters-mgmt-clusters-tuning-configs patch" [
  cluster_id: string
  tuning_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'TuningConfig' if this is a complete object or 'TuningConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --name: string # Name of the tuning config.
  --spec: record # Spec of the tuning config.
]: any -> record<kind: string, id: string, href: string, name: string, spec: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/tuning_configs/($tuning_config_id)")
  let body = {kind: $kind, id: $id, href: $href, name: $name, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new upgrade policy to the cluster.
#
# POST /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies
export def "clusters-mgmt-clusters-upgrade-policies post" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'UpgradePolicy' if this is a complete object or 'UpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Cluster ID this upgrade policy is defined for.
  --enable-minor-version-upgrades: string@bool-completer # Indicates if minor version upgrades are allowed for automatic upgrades (for manual it's always allowed).
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string@schedule-type-completer # ScheduleType defines which type of scheduling should be used for the upgrade policy.
  --upgrade-type: string@upgrade-type-completer # UpgradeType defines which type of upgrade should be used.
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, cluster_id: string, enable_minor_version_upgrades: bool, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, enable_minor_version_upgrades: $enable_minor_version_upgrades, next_run: $next_run, schedule: $schedule, schedule_type: $schedule_type, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of upgrade policies.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies
export def "clusters-mgmt-clusters-upgrade-policies list" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cluster_id: string, enable_minor_version_upgrades: bool, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the upgrade policy.
#
# DELETE /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies/{upgrade_policy_id}
export def "clusters-mgmt-clusters-upgrade-policies delete" [
  cluster_id: string
  upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies/($upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the upgrade policy.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies/{upgrade_policy_id}
export def "clusters-mgmt-clusters-upgrade-policies get" [
  cluster_id: string
  upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster_id: string, enable_minor_version_upgrades: bool, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies/($upgrade_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the upgrade policy.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies/{upgrade_policy_id}
export def "clusters-mgmt-clusters-upgrade-policies patch" [
  cluster_id: string
  upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'UpgradePolicy' if this is a complete object or 'UpgradePolicyLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --body-cluster-id: string # Cluster ID this upgrade policy is defined for.
  --enable-minor-version-upgrades: string@bool-completer # Indicates if minor version upgrades are allowed for automatic upgrades (for manual it's always allowed).
  --next-run: string # Next time the upgrade should run. (format: date-time)
  --schedule: string # Schedule cron expression that defines automatic upgrade scheduling.
  --schedule-type: string@schedule-type-completer # ScheduleType defines which type of scheduling should be used for the upgrade policy.
  --upgrade-type: string@upgrade-type-completer # UpgradeType defines which type of upgrade should be used.
  --version: string # Version is the desired upgrade version.
]: any -> record<kind: string, id: string, href: string, cluster_id: string, enable_minor_version_upgrades: bool, next_run: string, schedule: string, schedule_type: string, upgrade_type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies/($upgrade_policy_id)")
  let body = {kind: $kind, id: $id, href: $href, cluster_id: $body_cluster_id, enable_minor_version_upgrades: $enable_minor_version_upgrades, next_run: $next_run, schedule: $schedule, schedule_type: $schedule_type, upgrade_type: $upgrade_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of the upgrade policy state.
#
# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies/{upgrade_policy_id}/state
export def "clusters-mgmt-clusters-upgrade-policies-state get" [
  cluster_id: string
  upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, description: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies/($upgrade_policy_id)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the upgrade policy state.
#
# PATCH /api/clusters_mgmt/v1/clusters/{cluster_id}/upgrade_policies/{upgrade_policy_id}/state
export def "clusters-mgmt-clusters-upgrade-policies-state patch" [
  cluster_id: string
  upgrade_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'UpgradePolicyState' if this is a complete object or 'UpgradePolicyStateLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --description: string # Description of the state.
  --value: string@value-completer # Overall state of a cluster upgrade policy.
]: any -> record<kind: string, id: string, href: string, description: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/upgrade_policies/($upgrade_policy_id)/state")
  let body = {kind: $kind, id: $id, href: $href, description: $description, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/clusters/{cluster_id}/vpc
export def "clusters-mgmt-clusters-vpc get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aws_security_groups: table<id: string, name: string, red_hat_managed: bool>, aws_subnets: table<cidr_block: string, availability_zone: string, name: string, public: bool, red_hat_managed: bool, subnet_id: string>, cidr_block: string, id: string, name: string, red_hat_managed: bool, subnets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/clusters/($cluster_id)/vpc")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of deleted clusters
#
# GET /api/clusters_mgmt/v1/deleted_clusters
export def "clusters-mgmt-deleted-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cluster: record, deleted_timestamp: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/deleted_clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a specific deleted cluster
#
# GET /api/clusters_mgmt/v1/deleted_clusters/{deleted_cluster_id}
export def "clusters-mgmt-deleted-clusters get" [
  deleted_cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cluster: record<kind: string, id: string, href: string, api: record<cidr_block_access: record, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record, access_key_id: string, account_id: string, additional_allowed_principals: list, additional_compute_security_group_ids: list, additional_control_plane_security_group_ids: list, additional_infra_security_group_ids: list, audit_log: record, auto_node: record, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record, secret_access_key: string, subnet_ids: list, tags: record, vpc_endpoint_role_arn: string, zero_egress: record>, aws_infrastructure_access_role_grants: list<record>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record, project_id: string, security: record, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: list<record>, auto_node: record<mode: string, status: record>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record, scale_down: record, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record, operators_authentication: record, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, console: record<url: string>, control_plane: record<backup: record, log_forwarders: list>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list, state: string>, external_configuration: record<labels: list, manifests: list, syncsets: list>, flavour: record<kind: string, id: string, href: string, aws: record, gcp: record, name: string, network: record, nodes: record>, groups: list<record>, health_state: string, htpasswd: record<password: string, username: string, users: list>, hypershift: record<enabled: bool>, identity_providers: list<record>, image_registry: record<state: string>, inflight_checks: list<record>, infra_id: string, ingresses: list<record>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: list<record>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: list<record>, nodes: record<autoscale_compute: record, availability_zones: list, compute: int, compute_labels: record, compute_machine_type: record, compute_root_volume: record, infra: int, infra_machine_type: record, master: int, master_machine_type: record, security_group_filters: list, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record, cloud_provider: record, creation_timestamp: string, hive_config: record, hypershift_config: record, last_update_timestamp: string, management_cluster: string, region: record, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list, platform_allowlist: record, registry_sources: record>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list, available_upgrades: list, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record, raw_id: string, release_image: string, release_images: record, wif_enabled: bool>>, deleted_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/deleted_clusters/($deleted_cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a DNS domain.
#
# POST /api/clusters_mgmt/v1/dns_domains
# --cluster shape: {href?: string, id?: string}
# --gcp shape: {domain_prefix?: string, network_id?: string, project_id?: string}
# --organization shape: {href?: string, id?: string}
export def "clusters-mgmt-dns-domains post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'DNSDomain' if this is a complete object or 'DNSDomainLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --cloud-provider: string@cloud-provider-completer
  --cluster: any # Definition of a cluster link. — shape: {href?: string, id?: string}
  --cluster-arch: string@cluster-arch-completer # Possible cluster architectures.
  --gcp: any # GcpDnsDomain represents configuration for Google Cloud Platform DNS domain settings used in cluster DNS configuration for GCP-hosted clusters. — shape: {domain_prefix?: string, network_id?: string, project_id?: string}
  --organization: any # Definition of an organization link. — shape: {href?: string, id?: string}
  --reserved-at-timestamp: string # Date and time when the DNS domain was reserved. (format: date-time)
  --user-defined: string@bool-completer # Indicates if this dns domain is user defined.
]: any -> record<kind: string, id: string, href: string, cloud_provider: string, cluster: record<href: string, id: string>, cluster_arch: string, gcp: record<domain_prefix: string, network_id: string, project_id: string>, organization: record<href: string, id: string>, reserved_at_timestamp: string, user_defined: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/dns_domains")
  let body = {kind: $kind, id: $id, href: $href, cloud_provider: $cloud_provider, cluster: $cluster, cluster_arch: $cluster_arch, gcp: $gcp, organization: $organization, reserved_at_timestamp: $reserved_at_timestamp, user_defined: $user_defined} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/dns_domains
export def "clusters-mgmt-dns-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the dns domain instead of the names of the columns of a table. For example, in order to retrieve all the dns domains with a ID starting with `02a5` should be:  ```sql id like '02a5%' ```  If the parameter isn't provided, or if the value is empty, then all the dns domains that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cloud_provider: string, cluster: record, cluster_arch: string, gcp: record, organization: record, reserved_at_timestamp: string, user_defined: bool>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/dns_domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the DNS domain.
#
# DELETE /api/clusters_mgmt/v1/dns_domains/{dns_domain_id}
export def "clusters-mgmt-dns-domains delete" [
  dns_domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/dns_domains/($dns_domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the DNS domain.
#
# GET /api/clusters_mgmt/v1/dns_domains/{dns_domain_id}
export def "clusters-mgmt-dns-domains get" [
  dns_domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cloud_provider: string, cluster: record<href: string, id: string>, cluster_arch: string, gcp: record<domain_prefix: string, network_id: string, project_id: string>, organization: record<href: string, id: string>, reserved_at_timestamp: string, user_defined: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/dns_domains/($dns_domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the environment.
#
# GET /api/clusters_mgmt/v1/environment
export def "clusters-mgmt-environment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<backplane_url: string, last_cluster_imageset_sync: string, last_hibernation_check: string, last_limited_support_check: string, last_limited_support_override_check: string, last_upgrade_available_check: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/environment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the environment.  Attributes that can be updated are:  - `last_upgrade_available_check` - `last_limited_support_check`
#
# PATCH /api/clusters_mgmt/v1/environment
export def "clusters-mgmt-environment patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backplane-url: string # the backplane url for the environment
  --last-cluster-imageset-sync: string # last time that the cluster imageset sync worker checked for version updates (format: date-time)
  --last-hibernation-check: string # last time that the hibernation worker checked for hibernating clusters (format: date-time)
  --last-limited-support-check: string # last time that the worker checked for limited support clusters (format: date-time)
  --last-limited-support-override-check: string # last time that the limited support override worker checked for clusters (format: date-time)
  --last-upgrade-available-check: string # last time that the worker checked for available upgrades (format: date-time)
  --name: string # environment name
]: any -> record<backplane_url: string, last_cluster_imageset_sync: string, last_hibernation_check: string, last_limited_support_check: string, last_limited_support_override_check: string, last_upgrade_available_check: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/environment")
  let body = {backplane_url: $backplane_url, last_cluster_imageset_sync: $last_cluster_imageset_sync, last_hibernation_check: $last_hibernation_check, last_limited_support_check: $last_limited_support_check, last_limited_support_override_check: $last_limited_support_override_check, last_upgrade_available_check: $last_upgrade_available_check, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new event to be tracked. When sending a new event request, it gets tracked in Prometheus, Pendo, CloudWatch, or whichever analytics client is configured as part of clusters service. This allows for reporting on events that happen outside of a regular API request, but are found to be useful for understanding customer needs and possible blockers.
#
# POST /api/clusters_mgmt/v1/events
export def "clusters-mgmt-events post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: record # Body of the event to track the details of the tracking event as Key value pair
  --key: string # Key of the event to be tracked. This key should start with an uppercase letter followed by alphanumeric characters or underscores. The entire key needs to be smaller than 64 characters.
]: any -> record<body: record, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/events")
  let body = {body: $body_body, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/flavours
export def "clusters-mgmt-flavours list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the flavour instead of the names of the columns of a table. For example, in order to sort the flavours descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the flavour instead of the names of the columns of a table. For example, in order to retrieve all the flavours with a name starting with `my`the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the flavours that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, aws: record, gcp: record, name: string, network: record, nodes: record>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/flavours" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the cluster flavour.
#
# GET /api/clusters_mgmt/v1/flavours/{flavour_id}
export def "clusters-mgmt-flavours get" [
  flavour_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, aws: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record<iops: int, size: int>, master_instance_type: string, master_volume: record<iops: int, size: int>, worker_volume: record<iops: int, size: int>>, gcp: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record<size: int>, master_instance_type: string, master_volume: record<size: int>, worker_volume: record<size: int>>, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, nodes: record<master: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/flavours/($flavour_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the flavour.  Attributes that can be updated are:  - `aws.infra_volume` - `aws.infra_instance_type` - `gcp.infra_instance_type`
#
# PATCH /api/clusters_mgmt/v1/flavours/{flavour_id}
# --aws shape: {compute_instance_type?: string, infra_instance_type?: string, infra_volume?: any, master_instance_type?: string, master_volume?: any, worker_volume?: any}
# --gcp shape: {compute_instance_type?: string, infra_instance_type?: string, infra_volume?: any, master_instance_type?: string, master_volume?: any, worker_volume?: any}
# --network shape: {host_prefix?: int, machine_cidr?: string, pod_cidr?: string, service_cidr?: string, type?: string}
# --nodes shape: {master?: int}
export def "clusters-mgmt-flavours patch" [
  flavour_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'Flavour' if this is a complete object or 'FlavourLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws: any # Specification for different classes of nodes inside a flavour. — shape: {compute_instance_type?: string, infra_instance_type?: string, infra_volume?: any, master_instance_type?: string, master_volume?: any, worker_volume?: any}
  --gcp: any # Specification for different classes of nodes inside a flavour. — shape: {compute_instance_type?: string, infra_instance_type?: string, infra_volume?: any, master_instance_type?: string, master_volume?: any, worker_volume?: any}
  --name: string # Human friendly identifier of the cluster, for example `4`.  NOTE: Currently for all flavours the `id` and `name` attributes have exactly the same values.
  --network: any # Network configuration of a cluster. — shape: {host_prefix?: int, machine_cidr?: string, pod_cidr?: string, service_cidr?: string, type?: string}
  --nodes: any # Counts of different classes of nodes inside a flavour. — shape: {master?: int}
]: any -> record<kind: string, id: string, href: string, aws: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record<iops: int, size: int>, master_instance_type: string, master_volume: record<iops: int, size: int>, worker_volume: record<iops: int, size: int>>, gcp: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record<size: int>, master_instance_type: string, master_volume: record<size: int>, worker_volume: record<size: int>>, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, nodes: record<master: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/flavours/($flavour_id)")
  let body = {kind: $kind, id: $id, href: $href, aws: $aws, gcp: $gcp, name: $name, network: $network, nodes: $nodes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Provision a new wif_config resource and add it to the collection of wif_configs.
#
# POST /api/clusters_mgmt/v1/gcp/wif_configs
# --gcp shape: {federated_project_id?: string, federated_project_number?: string, impersonator_email?: string, project_id?: string, project_number?: string, role_prefix?: string, service_accounts?: list, support?: any, workload_identity_pool?: any}
# --organization shape: {href?: string, id?: string}
export def "clusters-mgmt-gcp-wif-configs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'WifConfig' if this is a complete object or 'WifConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --display-name: string # The name OCM clients will display for this wif_config.
  --gcp: any # shape: {federated_project_id?: string, federated_project_number?: string, impersonator_email?: string, project_id?: string, project_number?: string, role_prefix?: string, service_accounts?: list, support?: any, workload_identity_pool?: any}
  --organization: any # Definition of an organization link. — shape: {href?: string, id?: string}
  --wif-templates: list # Wif template(s) used to configure IAM resources
]: any -> record<kind: string, id: string, href: string, display_name: string, gcp: record<federated_project_id: string, federated_project_number: string, impersonator_email: string, project_id: string, project_number: string, role_prefix: string, service_accounts: list<record>, support: record<principal: string, roles: list>, workload_identity_pool: record<identity_provider: record, pool_id: string, pool_name: string>>, organization: record<href: string, id: string>, wif_templates: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp/wif_configs")
  let body = {kind: $kind, id: $id, href: $href, display_name: $display_name, gcp: $gcp, organization: $organization, wif_templates: $wif_templates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of wif_configs
#
# GET /api/clusters_mgmt/v1/gcp/wif_configs
export def "clusters-mgmt-gcp-wif-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the cluster instead of the names of the columns of a table. For example, in order to sort the clusters descending by region identifier the value should be:  ```sql region.id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the cluster instead of the names of the columns of a table. For example, in order to retrieve all the clusters with a name starting with `my` in the `us-east-1` region the value should be:  ```sql name like 'my%' and region.id = 'us-east-1' ```  If the parameter isn't provided, or if the value is empty, then all the wif_configs that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, display_name: string, gcp: record, organization: record, wif_templates: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp/wif_configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the wif_config.
#
# DELETE /api/clusters_mgmt/v1/gcp/wif_configs/{wif_config_id}
export def "clusters-mgmt-gcp-wif-configs delete" [
  wif_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run: string@bool-completer # Dry run flag is used to check if the operation can be completed, but won't delete.
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dry_run" $dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/gcp/wif_configs/($wif_config_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the WifConfig.
#
# GET /api/clusters_mgmt/v1/gcp/wif_configs/{wif_config_id}
export def "clusters-mgmt-gcp-wif-configs get" [
  wif_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, display_name: string, gcp: record<federated_project_id: string, federated_project_number: string, impersonator_email: string, project_id: string, project_number: string, role_prefix: string, service_accounts: list<record>, support: record<principal: string, roles: list>, workload_identity_pool: record<identity_provider: record, pool_id: string, pool_name: string>>, organization: record<href: string, id: string>, wif_templates: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/gcp/wif_configs/($wif_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the WifConfig.
#
# PATCH /api/clusters_mgmt/v1/gcp/wif_configs/{wif_config_id}
# --gcp shape: {federated_project_id?: string, federated_project_number?: string, impersonator_email?: string, project_id?: string, project_number?: string, role_prefix?: string, service_accounts?: list, support?: any, workload_identity_pool?: any}
# --organization shape: {href?: string, id?: string}
export def "clusters-mgmt-gcp-wif-configs patch" [
  wif_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'WifConfig' if this is a complete object or 'WifConfigLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --display-name: string # The name OCM clients will display for this wif_config.
  --gcp: any # shape: {federated_project_id?: string, federated_project_number?: string, impersonator_email?: string, project_id?: string, project_number?: string, role_prefix?: string, service_accounts?: list, support?: any, workload_identity_pool?: any}
  --organization: any # Definition of an organization link. — shape: {href?: string, id?: string}
  --wif-templates: list # Wif template(s) used to configure IAM resources
]: any -> record<kind: string, id: string, href: string, display_name: string, gcp: record<federated_project_id: string, federated_project_number: string, impersonator_email: string, project_id: string, project_number: string, role_prefix: string, service_accounts: list<record>, support: record<principal: string, roles: list>, workload_identity_pool: record<identity_provider: record, pool_id: string, pool_name: string>>, organization: record<href: string, id: string>, wif_templates: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/gcp/wif_configs/($wif_config_id)")
  let body = {kind: $kind, id: $id, href: $href, display_name: $display_name, gcp: $gcp, organization: $organization, wif_templates: $wif_templates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/gcp/wif_configs/{wif_config_id}/status
export def "clusters-mgmt-gcp-wif-configs-status get" [
  wif_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<configured: bool, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/gcp/wif_configs/($wif_config_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of encryption keys. IMPORTANT: This collection doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available regions of the provider.
#
# POST /api/clusters_mgmt/v1/gcp_inquiries/encryption_keys
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-gcp-inquiries-encryption-keys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of regions of the provider. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<kind: string, id: string, href: string, name: string>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp_inquiries/encryption_keys" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of available key rings of the cloud provider. IMPORTANT: This collection doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available regions of the provider.
#
# POST /api/clusters_mgmt/v1/gcp_inquiries/key_rings
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-gcp-inquiries-key-rings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of key rings of the provider. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<kind: string, id: string, href: string, name: string>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp_inquiries/key_rings" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of machine types in the provided region.
#
# POST /api/clusters_mgmt/v1/gcp_inquiries/machine_types
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-gcp-inquiries-machine-types post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp_inquiries/machine_types" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of available regions of the cloud provider. IMPORTANT: This list doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available regions of the provider.
#
# POST /api/clusters_mgmt/v1/gcp_inquiries/regions
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-gcp-inquiries-regions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of regions of the provider. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp_inquiries/regions" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of available vpcs of the cloud provider for specific region. IMPORTANT: This collection doesn't currently support paging or searching, so the returned `page` will always be 1 and `size` and `total` will always be the total number of available vpcs of the provider.
#
# POST /api/clusters_mgmt/v1/gcp_inquiries/vpcs
# --aws shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
# --gcp shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
# --version shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
export def "clusters-mgmt-gcp-inquiries-vpcs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the returned page, where one corresponds to the first page. As this collection doesn't support paging the result will always be `1`. (format: int32)
  --size: int # Number of items that will be contained in the returned page. As this collection doesn't support paging or searching the result will always be the total number of vpcs of the provider. (format: int32)
  --aws: any # _Amazon Web Services_ specific settings of a cluster. — shape: {kms_key_arn?: string, sts?: any, access_key_id?: string, account_id?: string, additional_allowed_principals?: list, additional_compute_security_group_ids?: list, additional_control_plane_security_group_ids?: list, additional_infra_security_group_ids?: list, audit_log?: any, auto_node?: any, billing_account_id?: string, ec2_metadata_http_tokens?: "optional"|"required", etcd_encryption?: any, hcp_internal_communication_hosted_zone_id?: string, private_hosted_zone_id?: string, private_hosted_zone_role_arn?: string, private_link?: bool, private_link_configuration?: any, secret_access_key?: string, subnet_ids?: list, tags?: record, vpc_endpoint_role_arn?: string, zero_egress?: any}
  --gcp: any # Google cloud platform settings of a cluster. — shape: {auth_uri?: string, auth_provider_x509_cert_url?: string, authentication?: any, client_id?: string, client_x509_cert_url?: string, client_email?: string, private_key?: string, private_key_id?: string, private_service_connect?: any, project_id?: string, security?: any, token_uri?: string, type?: string}
  --availability-zones: list # Availability zone
  --key-location: string # Key location
  --key-ring-name: string # Key ring name
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --subnets: list # Subnets
  --version: any # Representation of an _OpenShift_ version. — shape: {kind?: string, id?: string, href?: string, gcp_marketplace_enabled?: bool, rosa_enabled?: bool, available_channels?: list, available_upgrades?: list, channel_group?: string, default?: bool, enabled?: bool, end_of_life_timestamp?: string, hosted_control_plane_default?: bool, hosted_control_plane_enabled?: bool, image_overrides?: any, raw_id?: string, release_image?: string, release_images?: any, wif_enabled?: bool}
  --vpc-ids: list # VPC ids
]: any -> record<items: table<aws_security_groups: list, aws_subnets: list, cidr_block: string, id: string, name: string, red_hat_managed: bool, subnets: list>, page: int, size: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/gcp_inquiries/vpcs" $qp)
  let body = {aws: $aws, gcp: $gcp, availability_zones: $availability_zones, key_location: $key_location, key_ring_name: $key_ring_name, region: $region, subnets: $subnets, version: $version, vpc_ids: $vpc_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of templates.
#
# GET /api/clusters_mgmt/v1/limited_support_reason_templates
export def "clusters-mgmt-limited-support-reason-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, details: string, summary: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/limited_support_reason_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the template.
#
# GET /api/clusters_mgmt/v1/limited_support_reason_templates/{limited_support_reason_template_id}
export def "clusters-mgmt-limited-support-reason-templates get" [
  limited_support_reason_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, details: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/limited_support_reason_templates/($limited_support_reason_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of Load Balancer Quota Values.
#
# GET /api/clusters_mgmt/v1/load_balancer_quota_values
export def "clusters-mgmt-load-balancer-quota-values get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: list<int>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/load_balancer_quota_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of available applications for log forwarding.
#
# GET /api/clusters_mgmt/v1/log_forwarding/applications
export def "clusters-mgmt-log-forwarding-applications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the log forwarder application instead of the names of the columns of a table. For example, in order to sort the applications descending by id the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the log forwarder application instead of the names of the columns of a table. For example, in order to retrieve all the applications with an id starting with `kube` the value should be:  ```sql id like 'kube%' ```  If the parameter isn't provided, or if the value is empty, then all the log forwarder applications that the user has permission to see will be returned.
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<enabled: bool, name: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/log_forwarding/applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of available log forwarder group versions.
#
# GET /api/clusters_mgmt/v1/log_forwarding/groups
export def "clusters-mgmt-log-forwarding-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the log forwarder group instead of the names of the columns of a table. For example, in order to sort the groups descending by id the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the log forwarder group instead of the names of the columns of a table. For example, in order to retrieve all the groups with an id starting with `auth` the value should be:  ```sql id like 'auth%' ```  If the parameter isn't provided, or if the value is empty, then all the log forwarder groups that the user has permission to see will be returned.
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<enabled: bool, name: string, versions: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/log_forwarding/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of machine types.
#
# GET /api/clusters_mgmt/v1/machine_types
export def "clusters-mgmt-machine-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the machine type instead of the names of the columns of a table. For example, in order to sort the machine types descending by name identifier the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the machine type instead of the names of the columns of a table. For example, in order to retrieve all the machine types with a name starting with `A` the value should be:  ```sql name like 'A%' ```  If the parameter isn't provided, or if the value is empty, then all the machine types that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/machine_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the machine type.
#
# GET /api/clusters_mgmt/v1/machine_types/{machine_type_id}
export def "clusters-mgmt-machine-types get" [
  machine_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, ccs_only: bool, cpu: record<unit: string, value: float>, architecture: string, category: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, features: record<win_li: bool>, generic_name: string, memory: record<unit: string, value: float>, name: string, size: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/machine_types/($machine_type_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an entry for a network verification for each subnet supplied setting then to initial state.
#
# POST /api/clusters_mgmt/v1/network_verifications
# --cloud_provider_data shape: {aws?: any, gcp?: any, availability_zones?: list, key_location?: string, key_ring_name?: string, region?: any, subnets?: list, version?: any, vpc_ids?: list}
# --items item shape: {kind?: string, id?: string, href?: string, details?: list, platform?: "aws"|"aws-classic"|"aws-hosted-cp"|"gcp"|"hostedcluster", state?: string, tags?: record}
export def "clusters-mgmt-network-verifications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cloud-provider-data: any # Description of a cloud provider data used for cloud provider inquiries. — shape: {aws?: any, gcp?: any, availability_zones?: list, key_location?: string, key_ring_name?: string, region?: any, subnets?: list, version?: any, vpc_ids?: list}
  --cluster-id: string # Cluster ID needed to execute the network verification.
  --items: list # Details about each subnet network verification. — item shape: {kind?: string, id?: string, href?: string, details?: list, platform?: "aws"|"aws-classic"|"aws-hosted-cp"|"gcp"|"hostedcluster", state?: string, tags?: record}
  --platform: string@platform-completer # Representation of an platform type field.
  --total: int # Amount of network verifier executions started. (format: int32)
]: any -> record<cloud_provider_data: record<aws: record<kms_key_arn: string, sts: record, access_key_id: string, account_id: string, additional_allowed_principals: list, additional_compute_security_group_ids: list, additional_control_plane_security_group_ids: list, additional_infra_security_group_ids: list, audit_log: record, auto_node: record, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record, secret_access_key: string, subnet_ids: list, tags: record, vpc_endpoint_role_arn: string, zero_egress: record>, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record, project_id: string, security: record, token_uri: string, type: string>, availability_zones: list<string>, key_location: string, key_ring_name: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, subnets: list<string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list, available_upgrades: list, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record, raw_id: string, release_image: string, release_images: record, wif_enabled: bool>, vpc_ids: list<string>>, cluster_id: string, items: table<kind: string, id: string, href: string, details: list, platform: string, state: string, tags: record>, platform: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/network_verifications")
  let body = {cloud_provider_data: $cloud_provider_data, cluster_id: $cluster_id, items: $items, platform: $platform, total: $total} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of a subnet network verification.
#
# GET /api/clusters_mgmt/v1/network_verifications/{network_verification_id}
export def "clusters-mgmt-network-verifications get" [
  network_verification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, details: list<string>, platform: string, state: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/network_verifications/($network_verification_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a hosting under Red Hat's S3 bucket for byo oidc configuration.
#
# POST /api/clusters_mgmt/v1/oidc_configs
export def "clusters-mgmt-oidc-configs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --href: string # HREF for the oidc config, filled in response.
  --id: string # ID for the oidc config, filled in response.
  --creation-timestamp: string # Creation timestamp, filled in response. (format: date-time)
  --installer-role-arn: string # ARN of the AWS role to assume when installing the cluster as to reveal the secret, supplied in request. It is only to be used in Unmanaged Oidc Config.
  --issuer-url: string # Issuer URL, filled in response when Managed and supplied in Unmanaged.
  --last-update-timestamp: string # Last update timestamp, filled when patching a valid attribute of this oidc config. (format: date-time)
  --last-used-timestamp: string # Last used timestamp, filled by the latest cluster that used this oidc config. (format: date-time)
  --managed: string@bool-completer # Indicates whether it is Managed or Unmanaged (Customer hosted).
  --organization-id: string # Organization ID, filled in response respecting token provided.
  --reusable: string@bool-completer # Indicates whether the Oidc Config can be reused.
  --secret-arn: string # Secrets Manager ARN for the OIDC private key, supplied in request. It is only to be used in Unmanaged Oidc Config.
]: any -> record<href: string, id: string, creation_timestamp: string, installer_role_arn: string, issuer_url: string, last_update_timestamp: string, last_used_timestamp: string, managed: bool, organization_id: string, reusable: bool, secret_arn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/oidc_configs")
  let body = {href: $href, id: $id, creation_timestamp: $creation_timestamp, installer_role_arn: $installer_role_arn, issuer_url: $issuer_url, last_update_timestamp: $last_update_timestamp, last_used_timestamp: $last_used_timestamp, managed: $managed, organization_id: $organization_id, reusable: $reusable, secret_arn: $secret_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of oidc configs.
#
# GET /api/clusters_mgmt/v1/oidc_configs
export def "clusters-mgmt-oidc-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<href: string, id: string, creation_timestamp: string, installer_role_arn: string, issuer_url: string, last_update_timestamp: string, last_used_timestamp: string, managed: bool, organization_id: string, reusable: bool, secret_arn: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/oidc_configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the OidcConfig.
#
# DELETE /api/clusters_mgmt/v1/oidc_configs/{oidc_config_id}
export def "clusters-mgmt-oidc-configs delete" [
  oidc_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/oidc_configs/($oidc_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of an OidcConfig.
#
# GET /api/clusters_mgmt/v1/oidc_configs/{oidc_config_id}
export def "clusters-mgmt-oidc-configs get" [
  oidc_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<href: string, id: string, creation_timestamp: string, installer_role_arn: string, issuer_url: string, last_update_timestamp: string, last_used_timestamp: string, managed: bool, organization_id: string, reusable: bool, secret_arn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/oidc_configs/($oidc_config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates attributes of an OidcConfig.
#
# PATCH /api/clusters_mgmt/v1/oidc_configs/{oidc_config_id}
export def "clusters-mgmt-oidc-configs patch" [
  oidc_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --href: string # HREF for the oidc config, filled in response.
  --id: string # ID for the oidc config, filled in response.
  --creation-timestamp: string # Creation timestamp, filled in response. (format: date-time)
  --installer-role-arn: string # ARN of the AWS role to assume when installing the cluster as to reveal the secret, supplied in request. It is only to be used in Unmanaged Oidc Config.
  --issuer-url: string # Issuer URL, filled in response when Managed and supplied in Unmanaged.
  --last-update-timestamp: string # Last update timestamp, filled when patching a valid attribute of this oidc config. (format: date-time)
  --last-used-timestamp: string # Last used timestamp, filled by the latest cluster that used this oidc config. (format: date-time)
  --managed: string@bool-completer # Indicates whether it is Managed or Unmanaged (Customer hosted).
  --organization-id: string # Organization ID, filled in response respecting token provided.
  --reusable: string@bool-completer # Indicates whether the Oidc Config can be reused.
  --secret-arn: string # Secrets Manager ARN for the OIDC private key, supplied in request. It is only to be used in Unmanaged Oidc Config.
]: any -> record<href: string, id: string, creation_timestamp: string, installer_role_arn: string, issuer_url: string, last_update_timestamp: string, last_used_timestamp: string, managed: bool, organization_id: string, reusable: bool, secret_arn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/oidc_configs/($oidc_config_id)")
  let body = {href: $href, id: $id, creation_timestamp: $creation_timestamp, installer_role_arn: $installer_role_arn, issuer_url: $issuer_url, last_update_timestamp: $last_update_timestamp, last_used_timestamp: $last_used_timestamp, managed: $managed, organization_id: $organization_id, reusable: $reusable, secret_arn: $secret_arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of pending delete clusters.
#
# GET /api/clusters_mgmt/v1/pending_delete_clusters
export def "clusters-mgmt-pending-delete-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the pending delete cluster instead of the names of the columns of a table. For example, in order to sort the pending delete clusters descending by creation timestamp (i.e. their deletion time) the value should be:  ```sql creation_timestamp desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the pending delete cluster instead of the names of the columns of a table. For example, in order to retrieve all the pending delete clusters with creation time later than 2023-03-01T00:00:00Z the following is required:  ```sql creation_timestamp > '2023-03-01T00:00:00Z' ```  If the parameter isn't provided, or if the value is empty, then all the pending delete clusters that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, best_effort: bool, cluster: record, creation_timestamp: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/pending_delete_clusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the pending delete cluster.
#
# GET /api/clusters_mgmt/v1/pending_delete_clusters/{pending_delete_cluster_id}
export def "clusters-mgmt-pending-delete-clusters get" [
  pending_delete_cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, best_effort: bool, cluster: record<kind: string, id: string, href: string, api: record<cidr_block_access: record, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record, access_key_id: string, account_id: string, additional_allowed_principals: list, additional_compute_security_group_ids: list, additional_control_plane_security_group_ids: list, additional_infra_security_group_ids: list, audit_log: record, auto_node: record, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record, secret_access_key: string, subnet_ids: list, tags: record, vpc_endpoint_role_arn: string, zero_egress: record>, aws_infrastructure_access_role_grants: list<record>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record, project_id: string, security: record, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: list<record>, auto_node: record<mode: string, status: record>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record, scale_down: record, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record, operators_authentication: record, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, console: record<url: string>, control_plane: record<backup: record, log_forwarders: list>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list, state: string>, external_configuration: record<labels: list, manifests: list, syncsets: list>, flavour: record<kind: string, id: string, href: string, aws: record, gcp: record, name: string, network: record, nodes: record>, groups: list<record>, health_state: string, htpasswd: record<password: string, username: string, users: list>, hypershift: record<enabled: bool>, identity_providers: list<record>, image_registry: record<state: string>, inflight_checks: list<record>, infra_id: string, ingresses: list<record>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: list<record>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: list<record>, nodes: record<autoscale_compute: record, availability_zones: list, compute: int, compute_labels: record, compute_machine_type: record, compute_root_volume: record, infra: int, infra_machine_type: record, master: int, master_machine_type: record, security_group_filters: list, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record, cloud_provider: record, creation_timestamp: string, hive_config: record, hypershift_config: record, last_update_timestamp: string, management_cluster: string, region: record, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list, platform_allowlist: record, registry_sources: record>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list, available_upgrades: list, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record, raw_id: string, release_image: string, release_images: record, wif_enabled: bool>>, creation_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/pending_delete_clusters/($pending_delete_cluster_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the pending delete cluster entry.
#
# PATCH /api/clusters_mgmt/v1/pending_delete_clusters/{pending_delete_cluster_id}
# --cluster shape: {kind?: string, id?: string, href?: string, api?: any, aws?: any, aws_infrastructure_access_role_grants?: list, ccs?: any, dns?: any, fips?: bool, gcp?: any, gcp_encryption_key?: any, gcp_network?: any, additional_trust_bundle?: string, addons?: list, auto_node?: any, autoscaler?: any, azure?: any, billing_model?: "marketplace"|"marketplace-aws"|"marketplace-gcp"|"marketplace-rhm"|"marketplace-azure"|"standard", byo_oidc?: any, channel?: string, cloud_provider?: any, console?: any, control_plane?: any, creation_timestamp?: string, delete_protection?: any, disable_user_workload_monitoring?: bool, domain_prefix?: string, etcd_encryption?: bool, expiration_timestamp?: string, external_id?: string, external_auth_config?: any, external_configuration?: any, flavour?: any, groups?: list, health_state?: "healthy"|"unhealthy"|"unknown", htpasswd?: any, hypershift?: any, identity_providers?: list, image_registry?: any, inflight_checks?: list, infra_id?: string, ingresses?: list, kubelet_config?: any, load_balancer_quota?: int, machine_pools?: list, managed?: bool, managed_service?: any, multi_az?: bool, multi_arch_enabled?: bool, name?: string, network?: any, node_drain_grace_period?: any, node_pools?: list, nodes?: any, openshift_version?: string, product?: any, properties?: record, provision_shard?: any, proxy?: any, region?: any, registry_config?: any, state?: "error"|"hibernating"|"installing"|"pending"|"powering_down"|"ready"|"resuming"|"uninstalling"|"unknown"|"updating"|"validating"|"waiting", status?: any, storage_quota?: any, subscription?: any, version?: any}
export def "clusters-mgmt-pending-delete-clusters patch" [
  pending_delete_cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'PendingDeleteCluster' if this is a complete object or 'PendingDeleteClusterLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --best-effort: string@bool-completer # Flag indicating if the cluster deletion should be best-effort mode or not.
  --cluster: any # Definition of an _OpenShift_ cluster.  The `cloud_provider` attribute is a reference to the cloud provider. When a cluster is retrieved it will be a link to the cloud provider, containing only the kind, id and href attributes:  ```json {   "cloud_provider": {     "kind": "CloudProviderLink",     "id": "123",     "href": "/api/clusters_mgmt/v1/cloud_providers/123"   } } ```  When a cluster is created this is optional, and if used it should contain the identifier of the cloud provider to use:  ```json {   "cloud_provider": {     "id": "123",   } } ```  If not included, then the cluster will be created using the default cloud provider, which is currently Amazon Web Services.  The region attribute is mandatory when a cluster is created.  The `aws.access_key_id`, `aws.secret_access_key` and `dns.base_domain` attributes are mandatory when creation a cluster with your own Amazon Web Services account. — shape: {kind?: string, id?: string, href?: string, api?: any, aws?: any, aws_infrastructure_access_role_grants?: list, ccs?: any, dns?: any, fips?: bool, gcp?: any, gcp_encryption_key?: any, gcp_network?: any, additional_trust_bundle?: string, addons?: list, auto_node?: any, autoscaler?: any, azure?: any, billing_model?: "marketplace"|"marketplace-aws"|"marketplace-gcp"|"marketplace-rhm"|"marketplace-azure"|"standard", byo_oidc?: any, channel?: string, cloud_provider?: any, console?: any, control_plane?: any, creation_timestamp?: string, delete_protection?: any, disable_user_workload_monitoring?: bool, domain_prefix?: string, etcd_encryption?: bool, expiration_timestamp?: string, external_id?: string, external_auth_config?: any, external_configuration?: any, flavour?: any, groups?: list, health_state?: "healthy"|"unhealthy"|"unknown", htpasswd?: any, hypershift?: any, identity_providers?: list, image_registry?: any, inflight_checks?: list, infra_id?: string, ingresses?: list, kubelet_config?: any, load_balancer_quota?: int, machine_pools?: list, managed?: bool, managed_service?: any, multi_az?: bool, multi_arch_enabled?: bool, name?: string, network?: any, node_drain_grace_period?: any, node_pools?: list, nodes?: any, openshift_version?: string, product?: any, properties?: record, provision_shard?: any, proxy?: any, region?: any, registry_config?: any, state?: "error"|"hibernating"|"installing"|"pending"|"powering_down"|"ready"|"resuming"|"uninstalling"|"unknown"|"updating"|"validating"|"waiting", status?: any, storage_quota?: any, subscription?: any, version?: any}
  --creation-timestamp: string # Date and time when the cluster was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
]: any -> record<kind: string, id: string, href: string, best_effort: bool, cluster: record<kind: string, id: string, href: string, api: record<cidr_block_access: record, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record, access_key_id: string, account_id: string, additional_allowed_principals: list, additional_compute_security_group_ids: list, additional_control_plane_security_group_ids: list, additional_infra_security_group_ids: list, audit_log: record, auto_node: record, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record, secret_access_key: string, subnet_ids: list, tags: record, vpc_endpoint_role_arn: string, zero_egress: record>, aws_infrastructure_access_role_grants: list<record>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record, project_id: string, security: record, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: list<record>, auto_node: record<mode: string, status: record>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record, scale_down: record, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record, operators_authentication: record, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, console: record<url: string>, control_plane: record<backup: record, log_forwarders: list>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list, state: string>, external_configuration: record<labels: list, manifests: list, syncsets: list>, flavour: record<kind: string, id: string, href: string, aws: record, gcp: record, name: string, network: record, nodes: record>, groups: list<record>, health_state: string, htpasswd: record<password: string, username: string, users: list>, hypershift: record<enabled: bool>, identity_providers: list<record>, image_registry: record<state: string>, inflight_checks: list<record>, infra_id: string, ingresses: list<record>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: list<record>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: list<record>, nodes: record<autoscale_compute: record, availability_zones: list, compute: int, compute_labels: record, compute_machine_type: record, compute_root_volume: record, infra: int, infra_machine_type: record, master: int, master_machine_type: record, security_group_filters: list, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record, cloud_provider: record, creation_timestamp: string, hive_config: record, hypershift_config: record, last_update_timestamp: string, management_cluster: string, region: record, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list, platform_allowlist: record, registry_sources: record>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list, available_upgrades: list, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record, raw_id: string, release_image: string, release_images: record, wif_enabled: bool>>, creation_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/pending_delete_clusters/($pending_delete_cluster_id)")
  let body = {kind: $kind, id: $id, href: $href, best_effort: $best_effort, cluster: $cluster, creation_timestamp: $creation_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of products.
#
# GET /api/clusters_mgmt/v1/products
export def "clusters-mgmt-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the product instead of the names of the columns of a table. For example, in order to sort the products descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the product instead of the names of the columns of a table. For example, in order to retrieve all the products with a name starting with `my` the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the products that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, name: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the product.
#
# GET /api/clusters_mgmt/v1/products/{product_id}
export def "clusters-mgmt-products get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/products/($product_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of product minimal versions.
#
# GET /api/clusters_mgmt/v1/products/{product_id}/minimal_versions
export def "clusters-mgmt-products-minimal-versions list" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the product instead of the names of the columns of a table. For example, in order to sort the products descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the product instead of the names of the columns of a table. For example, in order to retrieve all the products with a name starting with `my` the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the products that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, rosa_cli: string, start_date: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/products/($product_id)/minimal_versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the product minimal version.
#
# GET /api/clusters_mgmt/v1/products/{product_id}/minimal_versions/{minimal_version_id}
export def "clusters-mgmt-products-minimal-versions get" [
  product_id: string
  minimal_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, rosa_cli: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/products/($product_id)/minimal_versions/($minimal_version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of product technology previews.
#
# GET /api/clusters_mgmt/v1/products/{product_id}/technology_previews
export def "clusters-mgmt-products-technology-previews list" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the product instead of the names of the columns of a table. For example, in order to sort the products descending by name the value should be:  ```sql name desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the product instead of the names of the columns of a table. For example, in order to retrieve all the products with a name starting with `my` the value should be:  ```sql name like 'my%' ```  If the parameter isn't provided, or if the value is empty, then all the products that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, additional_text: string, end_date: string, start_date: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/products/($product_id)/technology_previews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the product technology preview.
#
# GET /api/clusters_mgmt/v1/products/{product_id}/technology_previews/{technology_preview_id}
export def "clusters-mgmt-products-technology-previews get" [
  product_id: string
  technology_preview_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, additional_text: string, end_date: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/products/($product_id)/technology_previews/($technology_preview_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a provision shard.
#
# POST /api/clusters_mgmt/v1/provision_shards
# --aws_account_operator_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --gcp_project_operator shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
# --hive_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --hypershift_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
export def "clusters-mgmt-provision-shards post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ProvisionShard' if this is a complete object or 'ProvisionShardLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws-account-operator-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --aws-base-domain: string # Contains the AWS base domain.
  --gcp-base-domain: string # Contains the GCP base domain.
  --gcp-project-operator: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --creation-timestamp: string # Date and time when the provision shard was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --hive-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --hypershift-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --last-update-timestamp: string # Date and time when the provision shard was last updated, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --management-cluster: string # Contains the name of the management cluster for Hypershift clusters that are assigned to this shard. This field is populated by OCM, and must not be overwritten via API.
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --status: string # Status of the provision shard. Possible values: active/maintenance/offline.
]: any -> record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/provision_shards")
  let body = {kind: $kind, id: $id, href: $href, aws_account_operator_config: $aws_account_operator_config, aws_base_domain: $aws_base_domain, gcp_base_domain: $gcp_base_domain, gcp_project_operator: $gcp_project_operator, cloud_provider: $cloud_provider, creation_timestamp: $creation_timestamp, hive_config: $hive_config, hypershift_config: $hypershift_config, last_update_timestamp: $last_update_timestamp, management_cluster: $management_cluster, region: $region, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/clusters_mgmt/v1/provision_shards
export def "clusters-mgmt-provision-shards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the cluster instead of the names of the columns of a table. For example, in order to retrieve all the clusters with a name starting with `my` in the `us-east-1` region the value should be:  ```sql name like 'my%' and region.id = 'us-east-1' ```  If the parameter isn't provided, or if the value is empty, then all the provision shards that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, aws_account_operator_config: record, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record, cloud_provider: record, creation_timestamp: string, hive_config: record, hypershift_config: record, last_update_timestamp: string, management_cluster: string, region: record, status: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/provision_shards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the provision shard.
#
# DELETE /api/clusters_mgmt/v1/provision_shards/{provision_shard_id}
export def "clusters-mgmt-provision-shards delete" [
  provision_shard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/provision_shards/($provision_shard_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the provision shard.
#
# GET /api/clusters_mgmt/v1/provision_shards/{provision_shard_id}
export def "clusters-mgmt-provision-shards get" [
  provision_shard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/provision_shards/($provision_shard_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the details of the provision shard.
#
# PATCH /api/clusters_mgmt/v1/provision_shards/{provision_shard_id}
# --aws_account_operator_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --gcp_project_operator shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
# --hive_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --hypershift_config shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
# --region shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
export def "clusters-mgmt-provision-shards patch" [
  provision_shard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'ProvisionShard' if this is a complete object or 'ProvisionShardLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --aws-account-operator-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --aws-base-domain: string # Contains the AWS base domain.
  --gcp-base-domain: string # Contains the GCP base domain.
  --gcp-project-operator: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --creation-timestamp: string # Date and time when the provision shard was initially created, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --hive-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --hypershift-config: any # Representation of a server config — shape: {kind?: string, id?: string, href?: string, aws_shard?: any, kubeconfig?: string, server?: string, topology?: "dedicated"}
  --last-update-timestamp: string # Date and time when the provision shard was last updated, using the format defined in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt). (format: date-time)
  --management-cluster: string # Contains the name of the management cluster for Hypershift clusters that are assigned to this shard. This field is populated by OCM, and must not be overwritten via API.
  --region: any # Description of a region of a cloud provider. — shape: {kind?: string, id?: string, href?: string, ccs_only?: bool, kms_location_id?: string, kms_location_name?: string, cloud_provider?: any, display_name?: string, enabled?: bool, govcloud?: bool, name?: string, supports_hypershift?: bool, supports_multi_az?: bool}
  --status: string # Status of the provision shard. Possible values: active/maintenance/offline.
]: any -> record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record<ecr_repository_urls: list, backup_configs: list>, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/provision_shards/($provision_shard_id)")
  let body = {kind: $kind, id: $id, href: $href, aws_account_operator_config: $aws_account_operator_config, aws_base_domain: $aws_base_domain, gcp_base_domain: $gcp_base_domain, gcp_project_operator: $gcp_project_operator, cloud_provider: $cloud_provider, creation_timestamp: $creation_timestamp, hive_config: $hive_config, hypershift_config: $hypershift_config, last_update_timestamp: $last_update_timestamp, management_cluster: $management_cluster, region: $region, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds an existing cluster to the collection.
#
# POST /api/clusters_mgmt/v1/register_cluster
export def "clusters-mgmt-register-cluster post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --console-url: string # Optional Console URL of the cluster.
  --external-id: string # Identifier of the cluster generated by the installer.
  --organization-id: string # Organization identifier of the cluster generated by the account manager.
  --subscription-id: string # Subscription identifier of the cluster generated by the account manager.
]: any -> record<kind: string, id: string, href: string, api: record<cidr_block_access: record<allow: record>, url: string, listening: string>, aws: record<kms_key_arn: string, sts: record<oidc_endpoint_url: string, auto_mode: bool, enabled: bool, external_id: string, instance_iam_roles: record, managed_policies: bool, oidc_config: record, operator_iam_roles: list, operator_role_prefix: string, permission_boundary: string, role_arn: string, support_role_arn: string>, access_key_id: string, account_id: string, additional_allowed_principals: list<string>, additional_compute_security_group_ids: list<string>, additional_control_plane_security_group_ids: list<string>, additional_infra_security_group_ids: list<string>, audit_log: record<role_arn: string>, auto_node: record<role_arn: string>, billing_account_id: string, ec2_metadata_http_tokens: string, etcd_encryption: record<kms_key_arn: string>, hcp_internal_communication_hosted_zone_id: string, private_hosted_zone_id: string, private_hosted_zone_role_arn: string, private_link: bool, private_link_configuration: record<principals: list>, secret_access_key: string, subnet_ids: list<string>, tags: record, vpc_endpoint_role_arn: string, zero_egress: record<enabled: bool, no_proxy_default_domains: list>>, aws_infrastructure_access_role_grants: table<kind: string, id: string, href: string, console_url: string, role: record, state: string, state_description: string, user_arn: string>, ccs: record<kind: string, id: string, href: string, disable_scp_checks: bool, enabled: bool>, dns: record<base_domain: string>, fips: bool, gcp: record<auth_uri: string, auth_provider_x509_cert_url: string, authentication: record<href: string, id: string, kind: string>, client_id: string, client_x509_cert_url: string, client_email: string, private_key: string, private_key_id: string, private_service_connect: record<service_attachment_subnet: string>, project_id: string, security: record<secure_boot: bool>, token_uri: string, type: string>, gcp_encryption_key: record<kms_key_service_account: string, key_location: string, key_name: string, key_ring: string>, gcp_network: record<vpc_name: string, vpc_project_id: string, compute_subnet: string, control_plane_subnet: string>, additional_trust_bundle: string, addons: table<kind: string, id: string, href: string, addon: record, addon_version: record, billing: record, creation_timestamp: string, operator_version: string, parameters: list, state: string, state_description: string, updated_timestamp: string>, auto_node: record<mode: string, status: record<message: string, node_count: int>>, autoscaler: record<kind: string, id: string, href: string, balance_similar_node_groups: bool, balancing_ignored_labels: list<string>, ignore_daemonsets_utilization: bool, log_verbosity: int, max_node_provision_time: string, max_pod_grace_period: int, pod_priority_threshold: int, resource_limits: record<gpus: list, cores: record, max_nodes_total: int, memory: record>, scale_down: record<delay_after_add: string, delay_after_delete: string, delay_after_failure: string, enabled: bool, unneeded_time: string, utilization_threshold: string>, skip_nodes_with_local_storage: bool>, azure: record<etcd_encryption: record<data_encryption: record>, managed_resource_group_name: string, network_security_group_resource_id: string, nodes_outbound_connectivity: record<outbound_type: string>, operators_authentication: record<managed_identities: record>, resource_group_name: string, resource_name: string, subnet_resource_id: string, subscription_id: string, tenant_id: string>, billing_model: string, byo_oidc: record<enabled: bool>, channel: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, console: record<url: string>, control_plane: record<backup: record<state: string>, log_forwarders: list<record>>, creation_timestamp: string, delete_protection: record<enabled: bool>, disable_user_workload_monitoring: bool, domain_prefix: string, etcd_encryption: bool, expiration_timestamp: string, external_id: string, external_auth_config: record<kind: string, id: string, href: string, enabled: bool, external_auths: list<record>, state: string>, external_configuration: record<labels: list<record>, manifests: list<record>, syncsets: list<record>>, flavour: record<kind: string, id: string, href: string, aws: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, gcp: record<compute_instance_type: string, infra_instance_type: string, infra_volume: record, master_instance_type: string, master_volume: record, worker_volume: record>, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, nodes: record<master: int>>, groups: table<kind: string, id: string, href: string, users: list>, health_state: string, htpasswd: record<password: string, username: string, users: list<record>>, hypershift: record<enabled: bool>, identity_providers: table<kind: string, id: string, href: string, ldap: record, challenge: bool, github: record, gitlab: record, google: record, htpasswd: record, login: bool, mapping_method: string, name: string, open_id: record, type: string>, image_registry: record<state: string>, inflight_checks: table<kind: string, id: string, href: string, details: record, ended_at: string, name: string, restarts: int, started_at: string, state: string>, infra_id: string, ingresses: table<kind: string, id: string, href: string, dns_name: string, cluster_routes_hostname: string, cluster_routes_tls_secret_ref: string, component_routes: record, default: bool, excluded_namespace_selectors: list, excluded_namespaces: list, listening: string, load_balancer_type: string, route_namespace_ownership_policy: string, route_selectors: record, route_wildcard_policy: string>, kubelet_config: record<kind: string, id: string, href: string, name: string, pod_pids_limit: int>, load_balancer_quota: int, machine_pools: table<kind: string, id: string, href: string, aws: record, gcp: record, autoscaling: record, availability_zones: list, instance_type: string, labels: record, replicas: int, root_volume: record, security_group_filters: list, subnets: list, taints: list>, managed: bool, managed_service: record<enabled: bool>, multi_az: bool, multi_arch_enabled: bool, name: string, network: record<host_prefix: int, machine_cidr: string, pod_cidr: string, service_cidr: string, type: string>, node_drain_grace_period: record<unit: string, value: float>, node_pools: table<kind: string, id: string, href: string, aws_node_pool: record, auto_repair: bool, autoscaling: record, availability_zone: string, azure_node_pool: record, image_type: string, kubelet_configs: list, labels: record, management_upgrade: record, node_drain_grace_period: record, replicas: int, status: record, subnet: string, taints: list, tuning_configs: list, version: record>, nodes: record<autoscale_compute: record<kind: string, id: string, href: string, max_replicas: int, min_replicas: int>, availability_zones: list<string>, compute: int, compute_labels: record, compute_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, compute_root_volume: record<aws: record, gcp: record>, infra: int, infra_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, master: int, master_machine_type: record<kind: string, id: string, href: string, ccs_only: bool, cpu: record, architecture: string, category: string, cloud_provider: record, features: record, generic_name: string, memory: record, name: string, size: string>, security_group_filters: list<record>, total: int>, openshift_version: string, product: record<kind: string, id: string, href: string, name: string>, properties: record, provision_shard: record<kind: string, id: string, href: string, aws_account_operator_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, aws_base_domain: string, gcp_base_domain: string, gcp_project_operator: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, creation_timestamp: string, hive_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, hypershift_config: record<kind: string, id: string, href: string, aws_shard: record, kubeconfig: string, server: string, topology: string>, last_update_timestamp: string, management_cluster: string, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, status: string>, proxy: record<http_proxy: string, https_proxy: string, no_proxy: string>, region: record<kind: string, id: string, href: string, ccs_only: bool, kms_location_id: string, kms_location_name: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list>, display_name: string, enabled: bool, govcloud: bool, name: string, supports_hypershift: bool, supports_multi_az: bool>, registry_config: record<additional_trusted_ca: record, allowed_registries_for_import: list<record>, platform_allowlist: record<kind: string, id: string, href: string, cloud_provider: record, creation_timestamp: string, registries: list>, registry_sources: record<allowed_registries: list, blocked_registries: list, insecure_registries: list>>, state: string, status: record<kind: string, id: string, href: string, dns_ready: bool, oidc_ready: bool, configuration_mode: string, current_compute: int, description: string, limited_support_reason_count: int, provision_error_code: string, provision_error_message: string, state: string>, storage_quota: record<unit: string, value: float>, subscription: record<kind: string, id: string, href: string>, version: record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list, gcp: list>, raw_id: string, release_image: string, release_images: record<arm64: record, multi: record>, wif_enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/register_cluster")
  let body = {console_url: $console_url, external_id: $external_id, organization_id: $organization_id, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a new break registry allowlist.
#
# POST /api/clusters_mgmt/v1/registry_allowlists
# --cloud_provider shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
export def "clusters-mgmt-registry-allowlists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'RegistryAllowlist' if this is a complete object or 'RegistryAllowlistLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --cloud-provider: any # Cloud provider. — shape: {kind?: string, id?: string, href?: string, display_name?: string, name?: string, regions?: list}
  --creation-timestamp: string # CreationTimestamp is the date and time when the allow list has been created. (format: date-time)
  --registries: list # Registries is the list of registries contained in this Allowlist.
]: any -> record<kind: string, id: string, href: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, registries: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/registry_allowlists")
  let body = {kind: $kind, id: $id, href: $href, cloud_provider: $cloud_provider, creation_timestamp: $creation_timestamp, registries: $registries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the list of registry allowlists.
#
# GET /api/clusters_mgmt/v1/registry_allowlists
export def "clusters-mgmt-registry-allowlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the registry allowlists instead of the the names of the columns of a table. For example, in order to sort the allowlists descending by identifier the value should be:  ```sql creation_timestamp desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the registry allowlists instead of the names of the columns of a table. For example, in order to retrieve all the allowlists with a specific cloud provider and creation time the following is required:  ```sql cloud_provider.id='aws' and creation_timestamp > '2023-03-01T00:00:00Z' ```  If the parameter isn't provided, or if the value is empty, then all the registry allowlists that the user has permission to see will be returned.
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, cloud_provider: record, creation_timestamp: string, registries: list>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/registry_allowlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the allowlist.
#
# DELETE /api/clusters_mgmt/v1/registry_allowlists/{registry_allowlist_id}
export def "clusters-mgmt-registry-allowlists delete" [
  registry_allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/registry_allowlists/($registry_allowlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the allowlist.
#
# GET /api/clusters_mgmt/v1/registry_allowlists/{registry_allowlist_id}
export def "clusters-mgmt-registry-allowlists get" [
  registry_allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, cloud_provider: record<kind: string, id: string, href: string, display_name: string, name: string, regions: list<record>>, creation_timestamp: string, registries: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/registry_allowlists/($registry_allowlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of Storage Quota Values.
#
# GET /api/clusters_mgmt/v1/storage_quota_values
export def "clusters-mgmt-storage-quota-values get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<unit: string, value: float>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/storage_quota_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of trusted ip addresses.
#
# GET /api/clusters_mgmt/v1/trusted_ip_addresses
export def "clusters-mgmt-trusted-ip-addresses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --size: int # Number of items contained in the returned page. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, enabled: bool>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/trusted_ip_addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a new version gate
#
# POST /api/clusters_mgmt/v1/version_gates
export def "clusters-mgmt-version-gates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'VersionGate' if this is a complete object or 'VersionGateLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --sts-only: string@bool-completer # STSOnly indicates if this version gate is for STS clusters only, deprecated: to be replaced with ClusterCondition
  --cluster-condition: string # ClusterCondition aims at selecting the clusters targeted by this version gate, ignored if STSOnly is true
  --creation-timestamp: string # CreationTimestamp is the date and time when the version gate was created, format defined in https://www.ietf.org/rfc/rfc3339.txt[RC3339]. (format: date-time)
  --description: string # Description of the version gate.
  --documentation-url: string # DocumentationURL is the URL for the documentation of the version gate.
  --label: string # Label representing the version gate in OpenShift.
  --value: string # Value represents the required value of the label.
  --version-raw-id-prefix: string # VersionRawIDPrefix represents the versions prefix that the gate applies to.
  --warning-message: string # WarningMessage is a warning that will be displayed to the user before they acknowledge the gate
]: any -> record<kind: string, id: string, href: string, sts_only: bool, cluster_condition: string, creation_timestamp: string, description: string, documentation_url: string, label: string, value: string, version_raw_id_prefix: string, warning_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/clusters_mgmt/v1/version_gates")
  let body = {kind: $kind, id: $id, href: $href, sts_only: $sts_only, cluster_condition: $cluster_condition, creation_timestamp: $creation_timestamp, description: $description, documentation_url: $documentation_url, label: $label, value: $value, version_raw_id_prefix: $version_raw_id_prefix, warning_message: $warning_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of version gates.
#
# GET /api/clusters_mgmt/v1/version_gates
export def "clusters-mgmt-version-gates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of an SQL statement, but using the names of the attributes of the version gate instead of the names of the columns of a table. For example, in order to sort the version gates descending by identifier the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of an SQL statement, but using the names of the attributes of the version gate instead of the names of the columns of a table.  If the parameter isn't provided, or if the value is empty, then all the version gates that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page.  Default value is `100`. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, sts_only: bool, cluster_condition: string, creation_timestamp: string, description: string, documentation_url: string, label: string, value: string, version_raw_id_prefix: string, warning_message: string>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/version_gates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the version gate.
#
# DELETE /api/clusters_mgmt/v1/version_gates/{version_gate_id}
export def "clusters-mgmt-version-gates delete" [
  version_gate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: int, href: string, code: string, reason: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/version_gates/($version_gate_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the version gate.
#
# GET /api/clusters_mgmt/v1/version_gates/{version_gate_id}
export def "clusters-mgmt-version-gates get" [
  version_gate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, sts_only: bool, cluster_condition: string, creation_timestamp: string, description: string, documentation_url: string, label: string, value: string, version_raw_id_prefix: string, warning_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/version_gates/($version_gate_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the version gate.
#
# PATCH /api/clusters_mgmt/v1/version_gates/{version_gate_id}
export def "clusters-mgmt-version-gates patch" [
  version_gate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Indicates the type of this object. Will be 'VersionGate' if this is a complete object or 'VersionGateLink' if it is just a link.
  --id: string # Unique identifier of the object.
  --href: string # Self link.
  --sts-only: string@bool-completer # STSOnly indicates if this version gate is for STS clusters only, deprecated: to be replaced with ClusterCondition
  --cluster-condition: string # ClusterCondition aims at selecting the clusters targeted by this version gate, ignored if STSOnly is true
  --creation-timestamp: string # CreationTimestamp is the date and time when the version gate was created, format defined in https://www.ietf.org/rfc/rfc3339.txt[RC3339]. (format: date-time)
  --description: string # Description of the version gate.
  --documentation-url: string # DocumentationURL is the URL for the documentation of the version gate.
  --label: string # Label representing the version gate in OpenShift.
  --value: string # Value represents the required value of the label.
  --version-raw-id-prefix: string # VersionRawIDPrefix represents the versions prefix that the gate applies to.
  --warning-message: string # WarningMessage is a warning that will be displayed to the user before they acknowledge the gate
]: any -> record<kind: string, id: string, href: string, sts_only: bool, cluster_condition: string, creation_timestamp: string, description: string, documentation_url: string, label: string, value: string, version_raw_id_prefix: string, warning_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/version_gates/($version_gate_id)")
  let body = {kind: $kind, id: $id, href: $href, sts_only: $sts_only, cluster_condition: $cluster_condition, creation_timestamp: $creation_timestamp, description: $description, documentation_url: $documentation_url, label: $label, value: $value, version_raw_id_prefix: $version_raw_id_prefix, warning_message: $warning_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of versions.
#
# GET /api/clusters_mgmt/v1/versions
export def "clusters-mgmt-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string # Order criteria.  The syntax of this parameter is similar to the syntax of the _order by_ clause of a SQL statement, but using the names of the attributes of the version instead of the names of the columns of a table. For example, in order to sort the versions descending by identifier the value should be:  ```sql id desc ```  If the parameter isn't provided, or if the value is empty, then the order of the results is undefined.
  --page: int # Index of the requested page, where one corresponds to the first page. (format: int32)
  --search: string # Search criteria.  The syntax of this parameter is similar to the syntax of the _where_ clause of a SQL statement, but using the names of the attributes of the version instead of the names of the columns of a table. For example, in order to retrieve all the versions that are enabled:  ```sql enabled = 't' ```  If the parameter isn't provided, or if the value is empty, then all the versions that the user has permission to see will be returned.
  --size: int # Maximum number of items that will be contained in the returned page.  Default value is `100`. (format: int32)
]: nothing -> record<items: table<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list, available_upgrades: list, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record, raw_id: string, release_image: string, release_images: record, wif_enabled: bool>, page: int, size: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clusters_mgmt/v1/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of the version.
#
# GET /api/clusters_mgmt/v1/versions/{version_id}
export def "clusters-mgmt-versions get" [
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<kind: string, id: string, href: string, gcp_marketplace_enabled: bool, rosa_enabled: bool, available_channels: list<string>, available_upgrades: list<string>, channel_group: string, default: bool, enabled: bool, end_of_life_timestamp: string, hosted_control_plane_default: bool, hosted_control_plane_enabled: bool, image_overrides: record<kind: string, id: string, href: string, aws: list<record>, gcp: list<record>>, raw_id: string, release_image: string, release_images: record<arm64: record<available_upgrades: list, release_image: string>, multi: record<available_upgrades: list, release_image: string>>, wif_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/clusters_mgmt/v1/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
