# Auto-generated client for Akamai: Global Traffic Management API v1
# Source: https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/config-gtm/v1/openapi.json
# Auth: --token flag or $env.AKAMAI_GLOBAL_TRAFFIC_MANAGEMENT_API_TOKEN

const BASE_URL = "https://{hostname}/config-gtm/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AKAMAI_GLOBAL_TRAFFIC_MANAGEMENT_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://{hostname}/config-gtm/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["domain-vnd-config-gtm.v1.0+json" "domain-vnd-config-gtm.v1.1+json" "domain-vnd-config-gtm.v1.2+json" "domain-vnd-config-gtm.v1.3+json" "domain-vnd-config-gtm.v1.4+json" "domain-vnd-config-gtm.v1.5+json"] }
def accept-completer-1 [] { ["datacenter-vnd-config-gtm.v1.0+json" "datacenter-vnd-config-gtm.v1.1+json" "datacenter-vnd-config-gtm.v1.2+json" "datacenter-vnd-config-gtm.v1.3+json" "datacenter-vnd-config-gtm.v1.4+json" "datacenter-vnd-config-gtm.v1.5+json"] }
def accept-completer-2 [] { ["application/property-vnd-config-gtm.v1.0+json" "application/property-vnd-config-gtm.v1.1+json" "application/property-vnd-config-gtm.v1.2+json" "application/property-vnd-config-gtm.v1.3+json" "application/property-vnd-config-gtm.v1.4+json" "application/property-vnd-config-gtm.v1.5+json"] }
def aggregationType-completer [] { ["latest" "median" "sum"] }
def type-completer [] { ["Download score" "Non-XML load object via HTTP" "Non-XML load object via HTTPS" "Push API" "XML load object via HTTP" "XML load object via HTTPS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains post-domain" } } | get name | first)
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

# Create a domain
#
# POST /domains
# Docs: https://techdocs.akamai.com/gtm/reference/post-domain — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: post-domain
export def "domains post-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --contractId: string # A unique identifier for the contract. If your GTM client credential has access to more than one contract, you need to specify under which contract to provision the domain. For more information, see [API concepts](https://techdocs.akamai.com/gtm/reference/api-concepts). (e.g. 1-1TJZFW)
  --gid: int # A unique identifier for the group. If your GTM client credential has access to more than one group, you need to specify which group to assign to the domain. For more information, see [API concepts](https://techdocs.akamai.com/gtm/reference/api-concepts). (e.g. 15166)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "gid" $gid "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "domain-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "domain-vnd-config-gtm.v1.0+json" $body
}

# List domains
#
# GET /domains
# Docs: https://techdocs.akamai.com/gtm/reference/get-domains — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-domains
export def "domains get-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<items: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a domain
#
# GET /domains/{domainName}
# Docs: https://techdocs.akamai.com/gtm/reference/get-domain — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-domain
export def "domains get-domain" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --contractId: string # A unique identifier for the contract. If your GTM client credential has access to more than one contract, you need to specify under which contract to provision the domain. For more information, see [API concepts](https://techdocs.akamai.com/gtm/reference/api-concepts). (e.g. 1-1TJZFW)
  --gid: int # A unique identifier for the group. If your GTM client credential has access to more than one group, you need to specify which group to assign to the domain. For more information, see [API concepts](https://techdocs.akamai.com/gtm/reference/api-concepts). (e.g. 15166)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "gid" $gid "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)" $qp)
  let accept_val = ($accept | default "domain-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a domain
#
# PUT /domains/{domainName}
# Docs: https://techdocs.akamai.com/gtm/reference/put-domain — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-domain
export def "domains put-domain" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --contractId: string # A unique identifier for the contract. If your GTM client credential has access to more than one contract, you need to specify under which contract to provision the domain. For more information, see [API concepts](https://techdocs.akamai.com/gtm/reference/api-concepts). (e.g. 1-1TJZFW)
  --gid: int # A unique identifier for the group. If your GTM client credential has access to more than one group, you need to specify which group to assign to the domain. For more information, see [API concepts](https://techdocs.akamai.com/gtm/reference/api-concepts). (e.g. 15166)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contractId" $contractId "scalar") (serialize-qp "gid" $gid "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "domain-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "domain-vnd-config-gtm.v1.0+json" $body
}

# List AS maps
#
# GET /domains/{domainName}/as-maps
# Docs: https://techdocs.akamai.com/gtm/reference/get-as-maps — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-as-maps
export def "domains-as-maps get-as-maps" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<items: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/as-maps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an AS map
#
# GET /domains/{domainName}/as-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/get-as-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-as-map
export def "domains-as-maps get-as-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<assignments: table<asNumbers: list, datacenterId: int, nickname: string>, defaultDatacenter: record<datacenterId: int, nickname: string>, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/as-maps/($mapName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update an AS map
#
# PUT /domains/{domainName}/as-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/put-as-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-as-map
# --assignments item shape: {asNumbers: list, datacenterId: int, nickname: string}
# --defaultDatacenter shape: {datacenterId: int, nickname: string}
# --links item shape: {href?: string, rel?: string}
export def "domains-as-maps put-as-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domainModificationComments: string # Specifies change descriptions for audit trail and domain's change history. The maximum is 4000 characters. (nullable, e.g. Load balancer policy change)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  assignments: list # Contains information about the AS zone groupings of AS IDs. — item shape: {asNumbers: list, datacenterId: int, nickname: string}
  defaultDatacenter: record # A placeholder for all other AS zones, AS IDs not found in these AS zones. Note that an AS map can't have the same AS ID in multiple AS zones. — shape: {datacenterId: int, nickname: string}
  --links: list # Specifies the URL path that allows direct navigation to the As map. — item shape: {href?: string, rel?: string}
  name: string # A descriptive label for the AS map. Properties set up for asmapping can use this as reference. (e.g. {{name}})
]: any -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainModificationComments" $domainModificationComments "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/as-maps/($mapName)" $qp)
  let body = {assignments: $assignments, defaultDatacenter: $defaultDatacenter, links: $links, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an AS map
#
# DELETE /domains/{domainName}/as-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/delete-as-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: delete-as-map
export def "domains-as-maps delete-as-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/as-maps/($mapName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List CIDR maps
#
# GET /domains/{domainName}/cidr-maps
# Docs: https://techdocs.akamai.com/gtm/reference/get-cidr-maps — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-cidr-maps
export def "domains-cidr-maps get-cidr-maps" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<items: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/cidr-maps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a CIDR map
#
# GET /domains/{domainName}/cidr-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/get-cidr-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-cidr-map
export def "domains-cidr-maps get-cidr-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<assignments: table<blocks: list, datacenterId: int, nickname: string>, defaultDatacenter: record<datacenterId: int, nickname: string>, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/cidr-maps/($mapName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a CIDR map
#
# PUT /domains/{domainName}/cidr-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/put-cidr-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-cidr-map
# --assignments item shape: {blocks?: list, datacenterId?: int, nickname?: string}
# --defaultDatacenter shape: {datacenterId?: int, nickname?: string}
# --links item shape: {href?: string, rel?: string}
export def "domains-cidr-maps put-cidr-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domainModificationComments: string # Specifies change descriptions for audit trail and domain's change history. The maximum is 4000 characters. (nullable, e.g. Load balancer policy change)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --assignments: list # Contains information about the CIDR zone groupings of CIDR blocks. — item shape: {blocks?: list, datacenterId?: int, nickname?: string}
  --defaultDatacenter: record # A placeholder for all other CIDR zones, CIDR blocks not found in these CIDR zones. Note that a CIDR map can't have the same CIDR block in multiple CIDR zones. — shape: {datacenterId?: int, nickname?: string}
  --links: list # Specifies the URL path that allows direct navigation to the CIDR map. — item shape: {href?: string, rel?: string}
  --name: string # A descriptive label for the CIDR map, up to 255 characters. (e.g. {{name}})
]: any -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainModificationComments" $domainModificationComments "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/cidr-maps/($mapName)" $qp)
  let body = {assignments: $assignments, defaultDatacenter: $defaultDatacenter, links: $links, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a CIDR map
#
# DELETE /domains/{domainName}/cidr-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/delete-cidr-maps — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: delete-cidr-maps
export def "domains-cidr-maps delete-cidr-maps" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/cidr-maps/($mapName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a data center
#
# POST /domains/{domainName}/datacenters
# Docs: https://techdocs.akamai.com/gtm/reference/post-datacenter — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: post-datacenter
export def "domains-datacenters post-datacenter" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "datacenter-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "datacenter-vnd-config-gtm.v1.0+json" $body
}

# List data centers
#
# GET /domains/{domainName}/datacenters
# Docs: https://techdocs.akamai.com/gtm/reference/get-datacenters — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-datacenters
export def "domains-datacenters get-datacenters" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<items: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an IPv4 datacenter for ip-version-selector
#
# POST /domains/{domainName}/datacenters/datacenter-for-ip-version-selector-ipv4
# Docs: https://techdocs.akamai.com/gtm/reference/post-datacenter-for-ipv — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: post-datacenter-for-ipv
export def "domains-datacenters-datacenter-for-ip-version-selector-ipv4 post-datacenter-for-ipv" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters/datacenter-for-ip-version-selector-ipv4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an IPv6 datacenter for ip-version-selector
#
# POST /domains/{domainName}/datacenters/datacenter-for-ip-version-selector-ipv6
# Docs: https://techdocs.akamai.com/gtm/reference/post-datacenter-for-ipv6 — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: post-datacenter-for-ipv6
export def "domains-datacenters-datacenter-for-ip-version-selector-ipv6 post-datacenter-for-ipv6" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters/datacenter-for-ip-version-selector-ipv6" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a default data center
#
# POST /domains/{domainName}/datacenters/default-datacenter-for-maps
# Docs: https://techdocs.akamai.com/gtm/reference/post-default-datacenter-for-maps — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: post-default-datacenter-for-maps
export def "domains-datacenters-default-datacenter-for-maps post-default-datacenter-for-maps" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters/default-datacenter-for-maps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a data center
#
# GET /domains/{domainName}/datacenters/{datacenterId}
# Docs: https://techdocs.akamai.com/gtm/reference/get-datacenter — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-datacenter
export def "domains-datacenters get-datacenter" [
  datacenterId: int
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters/($datacenterId)" $qp)
  let accept_val = ($accept | default "datacenter-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a data center
#
# PUT /domains/{domainName}/datacenters/{datacenterId}
# Docs: https://techdocs.akamai.com/gtm/reference/put-datacenter — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-datacenter
export def "domains-datacenters put-datacenter" [
  datacenterId: int
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --domainModificationComments: string # Specifies change descriptions for audit trail and domain's change history. The maximum is 4000 characters. (nullable, e.g. Load balancer policy change)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainModificationComments" $domainModificationComments "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters/($datacenterId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "datacenter-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "datacenter-vnd-config-gtm.v1.0+json" $body
}

# Remove a data center
#
# DELETE /domains/{domainName}/datacenters/{datacenterId}
# Docs: https://techdocs.akamai.com/gtm/reference/delete-datacenter — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: delete-datacenter
export def "domains-datacenters delete-datacenter" [
  datacenterId: int
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/datacenters/($datacenterId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List geographic maps
#
# GET /domains/{domainName}/geographic-maps
# Docs: https://techdocs.akamai.com/gtm/reference/get-geographic-maps — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-geographic-maps
export def "domains-geographic-maps get-geographic-maps" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<items: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/geographic-maps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a geographic map
#
# GET /domains/{domainName}/geographic-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/get-geographic-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-geographic-map
export def "domains-geographic-maps get-geographic-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<assignments: table<countries: list, datacenterId: int, nickname: string>, defaultDatacenter: record<datacenterId: int, nickname: string>, links: table<href: string, rel: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/geographic-maps/($mapName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a geographic map
#
# PUT /domains/{domainName}/geographic-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/put-geographic-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-geographic-map
# --assignments item shape: {countries?: list, datacenterId?: int, nickname?: string}
# --defaultDatacenter shape: {datacenterId?: int, nickname?: string}
# --links item shape: {href?: string, rel?: string}
export def "domains-geographic-maps put-geographic-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domainModificationComments: string # Specifies change descriptions for audit trail and domain's change history. The maximum is 4000 characters. (nullable, e.g. Load balancer policy change)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --assignments: list # Contains information about the geographic zone groupings of countries. — item shape: {countries?: list, datacenterId?: int, nickname?: string}
  --defaultDatacenter: record # A placeholder for all other geographic zones, countries not found in these geographic zones. Note that a geographic map cannot have the same countries in multiple geographic zones. — shape: {datacenterId?: int, nickname?: string}
  --links: list # Specifies the URL path that allows direct navigation to the geographic map. — item shape: {href?: string, rel?: string}
  --name: string # A descriptive label for the geographic map, up to 128 characters. (e.g. {{name}})
]: any -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainModificationComments" $domainModificationComments "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/geographic-maps/($mapName)" $qp)
  let body = {assignments: $assignments, defaultDatacenter: $defaultDatacenter, links: $links, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a geographic map
#
# DELETE /domains/{domainName}/geographic-maps/{mapName}
# Docs: https://techdocs.akamai.com/gtm/reference/delete-geographic-map — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: delete-geographic-map
export def "domains-geographic-maps delete-geographic-map" [
  mapName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/geographic-maps/($mapName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List domain history
#
# GET /domains/{domainName}/history
# Docs: https://techdocs.akamai.com/gtm/reference/get-domain-history — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-domain-history
export def "domains-history get-domain-history" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page number to return. The first is page 1. (e.g. 1)
  --pageSize: int # The number of elements to return per page. The default is 25. (default: 25, e.g. 20)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<changes: table<changes: string, comments: string, domain: string, domainVersionId: string, modificationDate: string, modifiedBy: string, modifiedByClientId: string, modifiedByClientName: string>, links: table<href: string, rel: string>, metadata: record<lastPage: int, page: int, pageSize: int, totalElements: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List properties
#
# GET /domains/{domainName}/properties
# Docs: https://techdocs.akamai.com/gtm/reference/get-properties — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-properties
export def "domains-properties get-properties" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<items: table<backupCName: string, backupIp: string, balanceByDownloadScore: bool, cname: string, comments: string, dynamicTTL: int, failbackDelay: int, failoverDelay: int, handoutMode: string, healthMax: float, healthMultiplier: float, healthThreshold: float, ipv6: bool, lastModified: string, links: list, livenessTests: list, loadImbalancePercentage: float, mapName: string, maxUnreachablePenalty: float, mxRecords: list, name: string, scoreAggregationType: string, staticTTL: int, stickinessBonusConstant: int, stickinessBonusPercentage: int, trafficTargets: list, type: string, unreachableThreshold: float, useComputedTargets: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a property
#
# GET /domains/{domainName}/properties/{propertyName}
# Docs: https://techdocs.akamai.com/gtm/reference/get-property — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-property
export def "domains-properties get-property" [
  propertyName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/properties/($propertyName)" $qp)
  let accept_val = ($accept | default "application/property-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a property
#
# PUT /domains/{domainName}/properties/{propertyName}
# Docs: https://techdocs.akamai.com/gtm/reference/put-property — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-property
export def "domains-properties put-property" [
  propertyName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --domainModificationComments: string # Specifies change descriptions for audit trail and domain's change history. The maximum is 4000 characters. (nullable, e.g. Load balancer policy change)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainModificationComments" $domainModificationComments "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/properties/($propertyName)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/property-vnd-config-gtm.v1.0+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/property-vnd-config-gtm.v1.0+json" $body
}

# Remove a property
#
# DELETE /domains/{domainName}/properties/{propertyName}
# Docs: https://techdocs.akamai.com/gtm/reference/delete-property — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: delete-property
export def "domains-properties delete-property" [
  propertyName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: string, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/properties/($propertyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List resources
#
# GET /domains/{domainName}/resources
# Docs: https://techdocs.akamai.com/gtm/reference/get-resources — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-resources
export def "domains-resources get-resources" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: table<href: string, rel: string>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: table<datacenterId: int, loadObject: string, loadObjectPort: int, loadServers: list, useDefaultLoadObject: bool>, type: string, upperBound: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a resource
#
# GET /domains/{domainName}/resources/{resourceName}
# Docs: https://techdocs.akamai.com/gtm/reference/get-resource — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-resource
export def "domains-resources get-resource" [
  resourceName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: table<href: string, rel: string>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: table<datacenterId: int, loadObject: string, loadObjectPort: int, loadServers: list, useDefaultLoadObject: bool>, type: string, upperBound: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/resources/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a resource
#
# PUT /domains/{domainName}/resources/{resourceName}
# Docs: https://techdocs.akamai.com/gtm/reference/put-resource — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: put-resource
# --links item shape: {href?: string, rel?: string}
# --resourceInstances item shape: {datacenterId: int, loadObject?: string, loadObjectPort?: int, loadServers?: list, useDefaultLoadObject?: bool}
export def "domains-resources put-resource" [
  resourceName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domainModificationComments: string # Specifies change descriptions for audit trail and domain's change history. The maximum is 4000 characters. (nullable, e.g. Load balancer policy change)
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
  aggregationType: string@aggregationType-completer # Specifies how GTM handles different load numbers when multiple load servers are used for a data center or property. Either `sum`, `median`, or `latest`. For test time load feedback, consider `median`. (Akamai conducts tests from multiple locations, so you can ignore outlying values.) For load feedback with manual targets or dynamic targets, consider `latest` because all load servers normally report similar numbers. (e.g. {{aggregationType}})
  --comments: string # Provides information about the purpose of the property. (nullable, e.g. {{comments}})
  --constrainedProperty: string # Specifies the name of the property that this resource constrains, or `**` to constrain all properties. (nullable, e.g. {{constrainedProperty}})
  --decayRate: float # For internal use only. Unless Akamai indicates otherwise, omit the value or set it to `null`. (nullable, e.g. {{decayRate}})
  --description: string # A descriptive note to help you track what the resource constrains. For example, `aggregate bandwidth for all properties`. A maximum of 256 characters. (nullable, e.g. {{description}})
  --hostHeader: string # Optionally specifies the host header used when fetching the load object. (nullable, e.g. {{hostHeader}})
  --leaderString: string # Specifies the text that comes before the `loadObject`. GTM assumes that the current load is the first number to appear after this text, minus any white space. The value is a maximum of 256 characters. The default is `null`. For example, suppose your `loadObject` file contains, _This is a load object. TheLoadIs:497. This is the end of the load object_. Then GTM reads the current load as _497_ if the `leaderString` is set to _TheLoadIs_. (nullable, e.g. {{leaderString}})
  --leastSquaresDecay: float # For internal use only. Unless Akamai indicates otherwise, omit the value or set it to `null`. (nullable, e.g. {{leastSquaresDecay}})
  --links: list # Specifies the URL path that allows direct navigation to the resource. — item shape: {href?: string, rel?: string}
  --loadImbalancePercentage: float # Indicates the percent of load imbalance factor (LIF) for the domain. It lets GTM exceed the value configured for traffic distribution. For example, if the data center's traffic allocation is 25 percent and the LIF is 1.5, the demand can grow to 37.5 percent (25% &times; 1.5) before the load balancer starts shifting load away from it. If the LIF is `0`, no load imbalance is allowed. However, internally, GTM adds one to the LIF to allow its use as a multiplier. The default LIF is 1.1, which is displayed as `10.0` percent. The value ranges from `0` to `1000000` percent. (nullable, e.g. {{loadImbalancePercentage}})
  --maxUMultiplicativeIncrement: float # For internal use only. Unless Akamai indicates otherwise, omit the value or set it to `null`. (nullable, e.g. {{maxUMultiplicativeIncrement}})
  name: string # A descriptive label for the resource. A maximum 150 non-space characters. (e.g. {{name}})
  --resourceInstances: list # Contains information about the `resources` that constrain the `properties` within the data center. — item shape: {datacenterId: int, loadObject?: string, loadObjectPort?: int, loadServers?: list, useDefaultLoadObject?: bool}
  type: string@type-completer # Indicates the kind of `loadObject` format used to determine the load on the resource. Either `XML load object via HTTP`, `XML load object via HTTPS`, `Non-XML load object via HTTP`, `Non-XML load object via HTTPS`, `Download score`, or `Push API`. (e.g. {{type}})
  --upperBound: int # An optional sanity check that specifies the maximum allowed value for any component of the load object. If the `loadObject` contains a number that exceeds this value, it rejects the entire load object as invalid and GTM continues to use the load values from the most recently acquired `loadObject`. To receive an alert when a load object is rejected, log in to [Control Center](https://control.akamai.com), select Alerts from the Common Services category, then create a Load Object File Invalid or Cannot be Fetched alert. [Learn more](https://techdocs.akamai.com/alerts-app/docs). (nullable, e.g. {{upperBound}})
]: any -> record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: table<href: string, rel: string>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: table<datacenterId: int, loadObject: string, loadObjectPort: int, loadServers: list, useDefaultLoadObject: bool>, type: string, upperBound: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domainModificationComments" $domainModificationComments "scalar") (serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/resources/($resourceName)" $qp)
  let body = {aggregationType: $aggregationType, comments: $comments, constrainedProperty: $constrainedProperty, decayRate: $decayRate, description: $description, hostHeader: $hostHeader, leaderString: $leaderString, leastSquaresDecay: $leastSquaresDecay, links: $links, loadImbalancePercentage: $loadImbalancePercentage, maxUMultiplicativeIncrement: $maxUMultiplicativeIncrement, name: $name, resourceInstances: $resourceInstances, type: $type, upperBound: $upperBound} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a resource
#
# DELETE /domains/{domainName}/resources/{resourceName}
# Docs: https://techdocs.akamai.com/gtm/reference/delete-resource — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: delete-resource
export def "domains-resources delete-resource" [
  resourceName: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<resource: record<aggregationType: string, comments: string, constrainedProperty: string, decayRate: float, description: string, hostHeader: string, leaderString: string, leastSquaresDecay: float, links: list<record>, loadImbalancePercentage: float, maxUMultiplicativeIncrement: float, name: string, resourceInstances: list<record>, type: string, upperBound: int>, status: record<changeId: string, links: list<record>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/resources/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current status
#
# GET /domains/{domainName}/status/current
# Docs: https://techdocs.akamai.com/gtm/reference/get-status-current — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-status-current
export def "domains-status-current get-status-current" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<changeId: string, links: table<href: string, rel: string>, message: string, passingValidation: bool, propagationStatus: string, propagationStatusDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domains/($domainName)/status/current" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get identity
#
# GET /identity
# Docs: https://techdocs.akamai.com/gtm/reference/get-identity — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-identity
export def "identity get-identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<accountId: string, active: bool, contracts: table<contractId: string, features: list, permissions: list>, email: string, firstName: string, lastName: string, locale: string, userName: string, userTimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List contracts
#
# GET /identity/contracts
# Docs: https://techdocs.akamai.com/gtm/reference/get-identity-contracts — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-identity-contracts
export def "identity-contracts get-identity-contracts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<accountId: string, contracts: table<contractId: string, contractName: string, contractTypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identity/contracts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups
#
# GET /identity/groups
# Docs: https://techdocs.akamai.com/gtm/reference/get-identity-groups — See documentation for this operation in Akamai's Global Traffic Management API
# operationId: get-identity-groups
export def "identity-groups get-identity-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountSwitchKey: string # For customers who manage more than one account, this [runs the operation from another account](https://techdocs.akamai.com/developer/docs/manage-many-accounts-with-one-api-client). The Identity and Access Management API provides a [list of available account switch keys](https://techdocs.akamai.com/iam-api/reference/get-client-account-switch-keys). (e.g. 1-5C0YLB:1-8BYUX)
]: nothing -> record<groups: table<contractIds: list, groupId: int, groupName: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountSwitchKey" $accountSwitchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/identity/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
