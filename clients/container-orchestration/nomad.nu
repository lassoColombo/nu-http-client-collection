# Auto-generated client for Nomad v1.1.4
# Source: https://raw.githubusercontent.com/hashicorp/nomad-openapi/main/v1/openapi.yaml
# Auth: --token flag or $env.NOMAD_TOKEN

const BASE_URL = "http://127.0.0.1:4646/v1"
const DEFAULT_AUTH = "x-nomad-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOMAD_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-nomad-token" => { {headers: {X-Nomad-Token: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://127.0.0.1:4646/v1" "https://127.0.0.1:4646/v1"] }
def auth-scheme-completer [] { ["x-nomad-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "acl-bootstrap PostACLBootstrap" } } | get name | first)
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

# POST /acl/bootstrap
#
# operationId: PostACLBootstrap
export def "acl-bootstrap PostACLBootstrap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acl/bootstrap" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /acl/policies
#
# operationId: GetACLPolicies
export def "acl-policies GetACLPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acl/policies" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /acl/policy/{policyName}
#
# operationId: DeleteACLPolicy
export def "acl-policy DeleteACLPolicy" [
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acl/policy/($policyName)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /acl/policy/{policyName}
#
# operationId: GetACLPolicy
export def "acl-policy GetACLPolicy" [
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acl/policy/($policyName)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /acl/policy/{policyName}
#
# operationId: PostACLPolicy
# --JobACL shape: {Group?: string, JobID?: string, Namespace?: string, Task?: string}
export def "acl-policy PostACLPolicy" [
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --Description: string
  --JobACL: record # shape: {Group?: string, JobID?: string, Namespace?: string, Task?: string}
  --ModifyIndex: int
  --Name: string
  --Rules: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acl/policy/($policyName)" $qp)
  let body = {CreateIndex: $CreateIndex, Description: $Description, JobACL: $JobACL, ModifyIndex: $ModifyIndex, Name: $Name, Rules: $Rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /acl/token
#
# operationId: GetACLTokenSelf
export def "acl-token GetACLTokenSelf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acl/token" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /acl/token/{tokenAccessor}
#
# operationId: DeleteACLToken
export def "acl-token DeleteACLToken" [
  tokenAccessor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acl/token/($tokenAccessor)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /acl/token/{tokenAccessor}
#
# operationId: GetACLToken
export def "acl-token GetACLToken" [
  tokenAccessor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acl/token/($tokenAccessor)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /acl/token/{tokenAccessor}
#
# operationId: PostACLToken
# --Roles item shape: {ID?: string, Name?: string}
export def "acl-token PostACLToken" [
  tokenAccessor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --AccessorID: string
  --CreateIndex: int
  --CreateTime: string # format: date-time
  --ExpirationTTL: int # format: int64
  --ExpirationTime: string # format: date-time
  --Global: string@bool-completer
  --ModifyIndex: int
  --Name: string
  --Policies: list
  --Roles: list # item shape: {ID?: string, Name?: string}
  --SecretID: string
  --Type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/acl/token/($tokenAccessor)" $qp)
  let body = {AccessorID: $AccessorID, CreateIndex: $CreateIndex, CreateTime: $CreateTime, ExpirationTTL: $ExpirationTTL, ExpirationTime: $ExpirationTime, Global: $Global, ModifyIndex: $ModifyIndex, Name: $Name, Policies: $Policies, Roles: $Roles, SecretID: $SecretID, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /acl/token/onetime
#
# operationId: PostACLTokenOnetime
export def "acl-token-onetime PostACLTokenOnetime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acl/token/onetime" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /acl/token/onetime/exchange
#
# operationId: PostACLTokenOnetimeExchange
export def "acl-token-onetime-exchange PostACLTokenOnetimeExchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --OneTimeSecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acl/token/onetime/exchange" $qp)
  let body = {OneTimeSecretID: $OneTimeSecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /acl/tokens
#
# operationId: GetACLTokens
export def "acl-tokens GetACLTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acl/tokens" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /allocation/{allocID}
#
# operationId: GetAllocation
export def "allocation GetAllocation" [
  allocID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/allocation/($allocID)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /allocation/{allocID}/services
#
# operationId: GetAllocationServices
export def "allocation-services GetAllocationServices" [
  allocID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/allocation/($allocID)/services" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /allocation/{allocID}/stop
#
# operationId: PostAllocationStop
export def "allocation-stop PostAllocationStop" [
  allocID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --no-shutdown-delay: string@bool-completer # Flag indicating whether to delay shutdown when requesting an allocation stop.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "no_shutdown_delay" $no_shutdown_delay "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/allocation/($allocID)/stop" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /allocations
#
# operationId: GetAllocations
export def "allocations GetAllocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --resources: string@bool-completer # Flag indicating whether to include resources in response.
  --task-states: string@bool-completer # Flag indicating whether to include task states in response.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "resources" $resources "scalar") (serialize-qp "task_states" $task_states "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/allocations" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /deployment/{deploymentID}
#
# operationId: GetDeployment
export def "deployment GetDeployment" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/($deploymentID)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /deployment/allocation-health/{deploymentID}
#
# operationId: PostDeploymentAllocationHealth
export def "deployment-allocation-health PostDeploymentAllocationHealth" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --DeploymentID: string
  --HealthyAllocationIDs: list
  --Namespace: string
  --Region: string
  --SecretID: string
  --UnhealthyAllocationIDs: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/allocation-health/($deploymentID)" $qp)
  let body = {DeploymentID: $DeploymentID, HealthyAllocationIDs: $HealthyAllocationIDs, Namespace: $Namespace, Region: $Region, SecretID: $SecretID, UnhealthyAllocationIDs: $UnhealthyAllocationIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /deployment/allocations/{deploymentID}
#
# operationId: GetDeploymentAllocations
export def "deployment-allocations GetDeploymentAllocations" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/allocations/($deploymentID)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /deployment/fail/{deploymentID}
#
# operationId: PostDeploymentFail
export def "deployment-fail PostDeploymentFail" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/fail/($deploymentID)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /deployment/pause/{deploymentID}
#
# operationId: PostDeploymentPause
export def "deployment-pause PostDeploymentPause" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --DeploymentID: string
  --Namespace: string
  --Pause: string@bool-completer
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/pause/($deploymentID)" $qp)
  let body = {DeploymentID: $DeploymentID, Namespace: $Namespace, Pause: $Pause, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /deployment/promote/{deploymentID}
#
# operationId: PostDeploymentPromote
export def "deployment-promote PostDeploymentPromote" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --All: string@bool-completer
  --DeploymentID: string
  --Groups: list
  --Namespace: string
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/promote/($deploymentID)" $qp)
  let body = {All: $All, DeploymentID: $DeploymentID, Groups: $Groups, Namespace: $Namespace, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /deployment/unblock/{deploymentID}
#
# operationId: PostDeploymentUnblock
export def "deployment-unblock PostDeploymentUnblock" [
  deploymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --DeploymentID: string
  --Namespace: string
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/deployment/unblock/($deploymentID)" $qp)
  let body = {DeploymentID: $DeploymentID, Namespace: $Namespace, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /deployments
#
# operationId: GetDeployments
export def "deployments GetDeployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deployments" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /evaluation/{evalID}
#
# operationId: GetEvaluation
export def "evaluation GetEvaluation" [
  evalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/evaluation/($evalID)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /evaluation/{evalID}/allocations
#
# operationId: GetEvaluationAllocations
export def "evaluation-allocations GetEvaluationAllocations" [
  evalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/evaluation/($evalID)/allocations" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /evaluations
#
# operationId: GetEvaluations
export def "evaluations GetEvaluations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/evaluations" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /job/{jobName}
#
# operationId: DeleteJob
export def "job DeleteJob" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --purge: string@bool-completer # Boolean flag indicating whether to purge allocations of the job after deleting.
  --global: string@bool-completer # Boolean flag indicating whether the operation should apply to all instances of the job globally.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "purge" $purge "scalar") (serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /job/{jobName}
#
# operationId: GetJob
export def "job GetJob" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /job/{jobName}
#
# operationId: PostJob
# --Job shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
export def "job PostJob" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --EnforceIndex: string@bool-completer
  --EvalPriority: int
  --Job: record # shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
  --JobModifyIndex: int
  --Namespace: string
  --PolicyOverride: string@bool-completer
  --PreserveCounts: string@bool-completer
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)" $qp)
  let body = {EnforceIndex: $EnforceIndex, EvalPriority: $EvalPriority, Job: $Job, JobModifyIndex: $JobModifyIndex, Namespace: $Namespace, PolicyOverride: $PolicyOverride, PreserveCounts: $PreserveCounts, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /job/{jobName}/allocations
#
# operationId: GetJobAllocations
export def "job-allocations GetJobAllocations" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --all: string@bool-completer # Specifies whether the list of allocations should include allocations from a previously registered job with the same ID. This is possible if the job is deregistered and reregistered.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/allocations" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /job/{jobName}/deployment
#
# operationId: GetJobDeployment
export def "job-deployment GetJobDeployment" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/deployment" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /job/{jobName}/deployments
#
# operationId: GetJobDeployments
export def "job-deployments GetJobDeployments" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --all: int # Flag indicating whether to constrain by job creation index or not.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/deployments" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /job/{jobName}/dispatch
#
# operationId: PostJobDispatch
export def "job-dispatch PostJobDispatch" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --JobID: string
  --Meta: record
  --Payload: string # format: byte
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/dispatch" $qp)
  let body = {JobID: $JobID, Meta: $Meta, Payload: $Payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /job/{jobName}/evaluate
#
# operationId: PostJobEvaluate
# --EvalOptions shape: {ForceReschedule?: bool}
export def "job-evaluate PostJobEvaluate" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --EvalOptions: record # shape: {ForceReschedule?: bool}
  --JobID: string
  --Namespace: string
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/evaluate" $qp)
  let body = {EvalOptions: $EvalOptions, JobID: $JobID, Namespace: $Namespace, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /job/{jobName}/evaluations
#
# operationId: GetJobEvaluations
export def "job-evaluations GetJobEvaluations" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/evaluations" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /job/{jobName}/periodic/force
#
# operationId: PostJobPeriodicForce
export def "job-periodic-force PostJobPeriodicForce" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/periodic/force" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /job/{jobName}/plan
#
# operationId: PostJobPlan
# --Job shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
export def "job-plan PostJobPlan" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Diff: string@bool-completer
  --Job: record # shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
  --Namespace: string
  --PolicyOverride: string@bool-completer
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/plan" $qp)
  let body = {Diff: $Diff, Job: $Job, Namespace: $Namespace, PolicyOverride: $PolicyOverride, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /job/{jobName}/revert
#
# operationId: PostJobRevert
export def "job-revert PostJobRevert" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --ConsulToken: string
  --EnforcePriorVersion: int
  --JobID: string
  --JobVersion: int
  --Namespace: string
  --Region: string
  --SecretID: string
  --VaultToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/revert" $qp)
  let body = {ConsulToken: $ConsulToken, EnforcePriorVersion: $EnforcePriorVersion, JobID: $JobID, JobVersion: $JobVersion, Namespace: $Namespace, Region: $Region, SecretID: $SecretID, VaultToken: $VaultToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /job/{jobName}/scale
#
# operationId: GetJobScaleStatus
export def "job-scale GetJobScaleStatus" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/scale" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /job/{jobName}/scale
#
# operationId: PostJobScalingRequest
export def "job-scale PostJobScalingRequest" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Count: int # format: int64
  --Error: string@bool-completer
  --Message: string
  --Meta: record
  --Namespace: string
  --PolicyOverride: string@bool-completer
  --Region: string
  --SecretID: string
  --Target: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/scale" $qp)
  let body = {Count: $Count, Error: $Error, Message: $Message, Meta: $Meta, Namespace: $Namespace, PolicyOverride: $PolicyOverride, Region: $Region, SecretID: $SecretID, Target: $Target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /job/{jobName}/stable
#
# operationId: PostJobStability
export def "job-stable PostJobStability" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --JobID: string
  --JobVersion: int
  --Namespace: string
  --Region: string
  --SecretID: string
  --Stable: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/stable" $qp)
  let body = {JobID: $JobID, JobVersion: $JobVersion, Namespace: $Namespace, Region: $Region, SecretID: $SecretID, Stable: $Stable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /job/{jobName}/summary
#
# operationId: GetJobSummary
export def "job-summary GetJobSummary" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/summary" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /job/{jobName}/versions
#
# operationId: GetJobVersions
export def "job-versions GetJobVersions" [
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --diffs: string@bool-completer # Boolean flag indicating whether to compute job diffs.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "diffs" $diffs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/job/($jobName)/versions" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /jobs
#
# operationId: GetJobs
export def "jobs GetJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /jobs
#
# operationId: RegisterJob
# --Job shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
export def "jobs RegisterJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --EnforceIndex: string@bool-completer
  --EvalPriority: int
  --Job: record # shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
  --JobModifyIndex: int
  --Namespace: string
  --PolicyOverride: string@bool-completer
  --PreserveCounts: string@bool-completer
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp)
  let body = {EnforceIndex: $EnforceIndex, EvalPriority: $EvalPriority, Job: $Job, JobModifyIndex: $JobModifyIndex, Namespace: $Namespace, PolicyOverride: $PolicyOverride, PreserveCounts: $PreserveCounts, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /jobs/parse
#
# operationId: PostJobParse
export def "jobs-parse PostJobParse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Canonicalize: string@bool-completer
  --JobHCL: string
  --hclv1: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/jobs/parse")
  let body = {Canonicalize: $Canonicalize, JobHCL: $JobHCL, hclv1: $hclv1} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /metrics
#
# operationId: GetMetricsSummary
export def "metrics GetMetricsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string # The format the user requested for the metrics summary (e.g. prometheus)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /namespace
#
# operationId: CreateNamespace
export def "namespace CreateNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/namespace" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /namespace/{namespaceName}
#
# operationId: DeleteNamespace
export def "namespace DeleteNamespace" [
  namespaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespace/($namespaceName)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /namespace/{namespaceName}
#
# operationId: GetNamespace
export def "namespace GetNamespace" [
  namespaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespace/($namespaceName)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /namespace/{namespaceName}
#
# operationId: PostNamespace
# --Capabilities shape: {DisabledTaskDrivers?: list, EnabledTaskDrivers?: list}
export def "namespace PostNamespace" [
  namespaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Capabilities: record # shape: {DisabledTaskDrivers?: list, EnabledTaskDrivers?: list}
  --CreateIndex: int
  --Description: string
  --Meta: record
  --ModifyIndex: int
  --Name: string
  --Quota: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespace/($namespaceName)" $qp)
  let body = {Capabilities: $Capabilities, CreateIndex: $CreateIndex, Description: $Description, Meta: $Meta, ModifyIndex: $ModifyIndex, Name: $Name, Quota: $Quota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /namespaces
#
# operationId: GetNamespaces
export def "namespaces GetNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/namespaces" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /node/{nodeId}
#
# operationId: GetNode
export def "node GetNode" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($nodeId)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /node/{nodeId}/allocations
#
# operationId: GetNodeAllocations
export def "node-allocations GetNodeAllocations" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($nodeId)/allocations" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /node/{nodeId}/drain
#
# operationId: UpdateNodeDrain
# --DrainSpec shape: {Deadline?: int, IgnoreSystemJobs?: bool}
export def "node-drain UpdateNodeDrain" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
  --DrainSpec: record # shape: {Deadline?: int, IgnoreSystemJobs?: bool}
  --MarkEligible: string@bool-completer
  --Meta: record
  --NodeID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($nodeId)/drain" $qp)
  let body = {DrainSpec: $DrainSpec, MarkEligible: $MarkEligible, Meta: $Meta, NodeID: $NodeID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /node/{nodeId}/eligibility
#
# operationId: UpdateNodeEligibility
export def "node-eligibility UpdateNodeEligibility" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Eligibility: string
  --NodeID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($nodeId)/eligibility" $qp)
  let body = {Eligibility: $Eligibility, NodeID: $NodeID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /node/{nodeId}/purge
#
# operationId: UpdateNodePurge
export def "node-purge UpdateNodePurge" [
  nodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($nodeId)/purge" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /nodes
#
# operationId: GetNodes
export def "nodes GetNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --resources: string@bool-completer # Whether or not to include the NodeResources and ReservedResources fields in the response.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "resources" $resources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /operator/autopilot/configuration
#
# operationId: GetOperatorAutopilotConfiguration
export def "operator-autopilot-configuration GetOperatorAutopilotConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/autopilot/configuration" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /operator/autopilot/configuration
#
# operationId: PutOperatorAutopilotConfiguration
export def "operator-autopilot-configuration PutOperatorAutopilotConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --CleanupDeadServers: string@bool-completer
  --CreateIndex: int
  --DisableUpgradeMigration: string@bool-completer
  --EnableCustomUpgrades: string@bool-completer
  --EnableRedundancyZones: string@bool-completer
  --LastContactThreshold: string
  --MaxTrailingLogs: int
  --MinQuorum: int
  --ModifyIndex: int
  --ServerStabilizationTime: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/autopilot/configuration" $qp)
  let body = {CleanupDeadServers: $CleanupDeadServers, CreateIndex: $CreateIndex, DisableUpgradeMigration: $DisableUpgradeMigration, EnableCustomUpgrades: $EnableCustomUpgrades, EnableRedundancyZones: $EnableRedundancyZones, LastContactThreshold: $LastContactThreshold, MaxTrailingLogs: $MaxTrailingLogs, MinQuorum: $MinQuorum, ModifyIndex: $ModifyIndex, ServerStabilizationTime: $ServerStabilizationTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /operator/autopilot/health
#
# operationId: GetOperatorAutopilotHealth
export def "operator-autopilot-health GetOperatorAutopilotHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/autopilot/health" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /operator/raft/configuration
#
# operationId: GetOperatorRaftConfiguration
export def "operator-raft-configuration GetOperatorRaftConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/raft/configuration" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /operator/raft/peer
#
# operationId: DeleteOperatorRaftPeer
export def "operator-raft-peer DeleteOperatorRaftPeer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/raft/peer" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /operator/scheduler/configuration
#
# operationId: GetOperatorSchedulerConfiguration
export def "operator-scheduler-configuration GetOperatorSchedulerConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/scheduler/configuration" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /operator/scheduler/configuration
#
# operationId: PostOperatorSchedulerConfiguration
# --PreemptionConfig shape: {BatchSchedulerEnabled?: bool, ServiceSchedulerEnabled?: bool, SysBatchSchedulerEnabled?: bool, SystemSchedulerEnabled?: bool}
export def "operator-scheduler-configuration PostOperatorSchedulerConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --MemoryOversubscriptionEnabled: string@bool-completer
  --ModifyIndex: int
  --PauseEvalBroker: string@bool-completer
  --PreemptionConfig: record # shape: {BatchSchedulerEnabled?: bool, ServiceSchedulerEnabled?: bool, SysBatchSchedulerEnabled?: bool, SystemSchedulerEnabled?: bool}
  --RejectJobRegistration: string@bool-completer
  --SchedulerAlgorithm: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operator/scheduler/configuration" $qp)
  let body = {CreateIndex: $CreateIndex, MemoryOversubscriptionEnabled: $MemoryOversubscriptionEnabled, ModifyIndex: $ModifyIndex, PauseEvalBroker: $PauseEvalBroker, PreemptionConfig: $PreemptionConfig, RejectJobRegistration: $RejectJobRegistration, SchedulerAlgorithm: $SchedulerAlgorithm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /plugin/csi/{pluginID}
#
# operationId: GetPluginCSI
export def "plugin-csi GetPluginCSI" [
  pluginID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugin/csi/($pluginID)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /plugins
#
# operationId: GetPlugins
export def "plugins GetPlugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /quota
#
# operationId: CreateQuotaSpec
# --Limits item shape: {Hash?: string, Region?: string, RegionLimit?: record, VariablesLimit?: int}
export def "quota CreateQuotaSpec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --Description: string
  --Limits: list # item shape: {Hash?: string, Region?: string, RegionLimit?: record, VariablesLimit?: int}
  --ModifyIndex: int
  --Name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quota" $qp)
  let body = {CreateIndex: $CreateIndex, Description: $Description, Limits: $Limits, ModifyIndex: $ModifyIndex, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /quota/{specName}
#
# operationId: DeleteQuotaSpec
export def "quota DeleteQuotaSpec" [
  specName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/quota/($specName)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /quota/{specName}
#
# operationId: GetQuotaSpec
export def "quota GetQuotaSpec" [
  specName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/quota/($specName)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /quota/{specName}
#
# operationId: PostQuotaSpec
# --Limits item shape: {Hash?: string, Region?: string, RegionLimit?: record, VariablesLimit?: int}
export def "quota PostQuotaSpec" [
  specName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --Description: string
  --Limits: list # item shape: {Hash?: string, Region?: string, RegionLimit?: record, VariablesLimit?: int}
  --ModifyIndex: int
  --Name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/quota/($specName)" $qp)
  let body = {CreateIndex: $CreateIndex, Description: $Description, Limits: $Limits, ModifyIndex: $ModifyIndex, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /quotas
#
# operationId: GetQuotas
export def "quotas GetQuotas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quotas" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /regions
#
# operationId: GetRegions
export def "regions GetRegions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /scaling/policies
#
# operationId: GetScalingPolicies
export def "scaling-policies GetScalingPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scaling/policies" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /scaling/policy/{policyID}
#
# operationId: GetScalingPolicy
export def "scaling-policy GetScalingPolicy" [
  policyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/scaling/policy/($policyID)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /search
#
# operationId: GetSearch
export def "search GetSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
  --AllowStale: string@bool-completer
  --AuthToken: string
  --Context: string
  --Filter: string
  --Headers: record
  --Namespace: string
  --NextToken: string
  --Params: record
  --PerPage: int # format: int32
  --Prefix: string
  --Region: string
  --Reverse: string@bool-completer
  --WaitIndex: int
  --WaitTime: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let body = {AllowStale: $AllowStale, AuthToken: $AuthToken, Context: $Context, Filter: $Filter, Headers: $Headers, Namespace: $Namespace, NextToken: $NextToken, Params: $Params, PerPage: $PerPage, Prefix: $Prefix, Region: $Region, Reverse: $Reverse, WaitIndex: $WaitIndex, WaitTime: $WaitTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /search/fuzzy
#
# operationId: GetFuzzySearch
export def "search-fuzzy GetFuzzySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
  --AllowStale: string@bool-completer
  --AuthToken: string
  --Context: string
  --Filter: string
  --Headers: record
  --Namespace: string
  --NextToken: string
  --Params: record
  --PerPage: int # format: int32
  --Prefix: string
  --Region: string
  --Reverse: string@bool-completer
  --Text: string
  --WaitIndex: int
  --WaitTime: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/fuzzy" $qp)
  let body = {AllowStale: $AllowStale, AuthToken: $AuthToken, Context: $Context, Filter: $Filter, Headers: $Headers, Namespace: $Namespace, NextToken: $NextToken, Params: $Params, PerPage: $PerPage, Prefix: $Prefix, Region: $Region, Reverse: $Reverse, Text: $Text, WaitIndex: $WaitIndex, WaitTime: $WaitTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /status/leader
#
# operationId: GetStatusLeader
export def "status-leader GetStatusLeader" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status/leader" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /status/peers
#
# operationId: GetStatusPeers
export def "status-peers GetStatusPeers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status/peers" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /system/gc
#
# operationId: PutSystemGC
export def "system-gc PutSystemGC" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/gc" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /system/reconcile/summaries
#
# operationId: PutSystemReconcileSummaries
export def "system-reconcile-summaries PutSystemReconcileSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/reconcile/summaries" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /validate/job
#
# operationId: PostJobValidateRequest
# --Job shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
export def "validate-job PostJobValidateRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Job: record # shape: {Affinities?: list, AllAtOnce?: bool, Constraints?: list, ConsulNamespace?: string, ConsulToken?: string, CreateIndex?: int, Datacenters?: list, DispatchIdempotencyToken?: string, Dispatched?: bool, ID?: string, JobModifyIndex?: int, Meta?: record, Migrate?: record, ModifyIndex?: int, Multiregion?: record, Name?: string, Namespace?: string, NomadTokenID?: string, ParameterizedJob?: record, ParentID?: string, Payload?: string, Periodic?: record, Priority?: int, Region?: string, Reschedule?: record, Spreads?: list, Stable?: bool, Status?: string, StatusDescription?: string, Stop?: bool, SubmitTime?: int, TaskGroups?: list, Type?: string, Update?: record, VaultNamespace?: string, VaultToken?: string, Version?: int}
  --Namespace: string
  --Region: string
  --SecretID: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/validate/job" $qp)
  let body = {Job: $Job, Namespace: $Namespace, Region: $Region, SecretID: $SecretID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /var/{path}
#
# operationId: DeleteVariable
export def "var DeleteVariable" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --cas: int # A compare-and-set parameter for Nomad Variables
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --CreateTime: int # format: int64
  --Items: record
  --ModifyIndex: int
  --ModifyTime: int # format: int64
  --Namespace: string
  --Path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "cas" $cas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/var/($path)" $qp)
  let body = {CreateIndex: $CreateIndex, CreateTime: $CreateTime, Items: $Items, ModifyIndex: $ModifyIndex, ModifyTime: $ModifyTime, Namespace: $Namespace, Path: $Path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /var/{path}
#
# operationId: GetVariableQuery
export def "var GetVariableQuery" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/var/($path)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /var/{path}
#
# operationId: PostVariable
export def "var PostVariable" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --cas: int # A compare-and-set parameter for Nomad Variables
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --CreateTime: int # format: int64
  --Items: record
  --ModifyIndex: int
  --ModifyTime: int # format: int64
  --Namespace: string
  --Path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "cas" $cas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/var/($path)" $qp)
  let body = {CreateIndex: $CreateIndex, CreateTime: $CreateTime, Items: $Items, ModifyIndex: $ModifyIndex, ModifyTime: $ModifyTime, Namespace: $Namespace, Path: $Path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /var/{path}
#
# operationId: PutVariable
export def "var PutVariable" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --cas: int # A compare-and-set parameter for Nomad Variables
  --X-Nomad-Token: string # A Nomad ACL token.
  --CreateIndex: int
  --CreateTime: int # format: int64
  --Items: record
  --ModifyIndex: int
  --ModifyTime: int # format: int64
  --Namespace: string
  --Path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "cas" $cas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/var/($path)" $qp)
  let body = {CreateIndex: $CreateIndex, CreateTime: $CreateTime, Items: $Items, ModifyIndex: $ModifyIndex, ModifyTime: $ModifyTime, Namespace: $Namespace, Path: $Path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /vars
#
# operationId: GetVariablesListRequest
export def "vars GetVariablesListRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vars" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /volume/csi/{volumeId}
#
# operationId: DeleteVolumeRegistration
export def "volume-csi DeleteVolumeRegistration" [
  volumeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --force: string # Used to force the de-registration of a volume.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volume/csi/($volumeId)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /volume/csi/{volumeId}
#
# operationId: GetVolume
export def "volume-csi GetVolume" [
  volumeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volume/csi/($volumeId)" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /volume/csi/{volumeId}
#
# operationId: PostVolumeRegistration
# --Volumes item shape: {AccessMode?: string, Allocations?: list, AttachmentMode?: string, Capacity?: int, CloneID?: string, Context?: record, ControllerRequired?: bool, ControllersExpected?: int, ControllersHealthy?: int, CreateIndex?: int, ExternalID?: string, ID?: string, ModifyIndex?: int, MountOptions?: record, Name?: string, Namespace?: string, NodesExpected?: int, NodesHealthy?: int, Parameters?: record, PluginID?: string, Provider?: string, ProviderVersion?: string, ReadAllocs?: record, RequestedCapabilities?: list, RequestedCapacityMax?: int, RequestedCapacityMin?: int, RequestedTopologies?: record, ResourceExhausted?: string, Schedulable?: bool, Secrets?: record, SnapshotID?: string, Topologies?: list, WriteAllocs?: record}
export def "volume-csi PostVolumeRegistration" [
  volumeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Namespace: string
  --Region: string
  --SecretID: string
  --Volumes: list # item shape: {AccessMode?: string, Allocations?: list, AttachmentMode?: string, Capacity?: int, CloneID?: string, Context?: record, ControllerRequired?: bool, ControllersExpected?: int, ControllersHealthy?: int, CreateIndex?: int, ExternalID?: string, ID?: string, ModifyIndex?: int, MountOptions?: record, Name?: string, Namespace?: string, NodesExpected?: int, NodesHealthy?: int, Parameters?: record, PluginID?: string, Provider?: string, ProviderVersion?: string, ReadAllocs?: record, RequestedCapabilities?: list, RequestedCapacityMax?: int, RequestedCapacityMin?: int, RequestedTopologies?: record, ResourceExhausted?: string, Schedulable?: bool, Secrets?: record, SnapshotID?: string, Topologies?: list, WriteAllocs?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volume/csi/($volumeId)" $qp)
  let body = {Namespace: $Namespace, Region: $Region, SecretID: $SecretID, Volumes: $Volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /volume/csi/{volumeId}/{action}
#
# operationId: DetachOrDeleteVolume
export def "volume-csi DetachOrDeleteVolume" [
  volumeId: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --node: string # Specifies node to target volume operation for.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "node" $node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volume/csi/($volumeId)/($action)" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /volume/csi/{volumeId}/{action}
#
# operationId: CreateVolume
# --Volumes item shape: {AccessMode?: string, Allocations?: list, AttachmentMode?: string, Capacity?: int, CloneID?: string, Context?: record, ControllerRequired?: bool, ControllersExpected?: int, ControllersHealthy?: int, CreateIndex?: int, ExternalID?: string, ID?: string, ModifyIndex?: int, MountOptions?: record, Name?: string, Namespace?: string, NodesExpected?: int, NodesHealthy?: int, Parameters?: record, PluginID?: string, Provider?: string, ProviderVersion?: string, ReadAllocs?: record, RequestedCapabilities?: list, RequestedCapacityMax?: int, RequestedCapacityMin?: int, RequestedTopologies?: record, ResourceExhausted?: string, Schedulable?: bool, Secrets?: record, SnapshotID?: string, Topologies?: list, WriteAllocs?: record}
export def "volume-csi CreateVolume" [
  volumeId: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Namespace: string
  --Region: string
  --SecretID: string
  --Volumes: list # item shape: {AccessMode?: string, Allocations?: list, AttachmentMode?: string, Capacity?: int, CloneID?: string, Context?: record, ControllerRequired?: bool, ControllersExpected?: int, ControllersHealthy?: int, CreateIndex?: int, ExternalID?: string, ID?: string, ModifyIndex?: int, MountOptions?: record, Name?: string, Namespace?: string, NodesExpected?: int, NodesHealthy?: int, Parameters?: record, PluginID?: string, Provider?: string, ProviderVersion?: string, ReadAllocs?: record, RequestedCapabilities?: list, RequestedCapacityMax?: int, RequestedCapacityMin?: int, RequestedTopologies?: record, ResourceExhausted?: string, Schedulable?: bool, Secrets?: record, SnapshotID?: string, Topologies?: list, WriteAllocs?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volume/csi/($volumeId)/($action)" $qp)
  let body = {Namespace: $Namespace, Region: $Region, SecretID: $SecretID, Volumes: $Volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /volumes
#
# operationId: GetVolumes
export def "volumes GetVolumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --node-id: string # Filters volume lists by node ID.
  --plugin-id: string # Filters volume lists by plugin ID.
  --type: string # Filters volume lists to a specific type.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "node_id" $node_id "scalar") (serialize-qp "plugin_id" $plugin_id "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /volumes
#
# operationId: PostVolume
# --Volumes item shape: {AccessMode?: string, Allocations?: list, AttachmentMode?: string, Capacity?: int, CloneID?: string, Context?: record, ControllerRequired?: bool, ControllersExpected?: int, ControllersHealthy?: int, CreateIndex?: int, ExternalID?: string, ID?: string, ModifyIndex?: int, MountOptions?: record, Name?: string, Namespace?: string, NodesExpected?: int, NodesHealthy?: int, Parameters?: record, PluginID?: string, Provider?: string, ProviderVersion?: string, ReadAllocs?: record, RequestedCapabilities?: list, RequestedCapacityMax?: int, RequestedCapacityMin?: int, RequestedTopologies?: record, ResourceExhausted?: string, Schedulable?: bool, Secrets?: record, SnapshotID?: string, Topologies?: list, WriteAllocs?: record}
export def "volumes PostVolume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Namespace: string
  --Region: string
  --SecretID: string
  --Volumes: list # item shape: {AccessMode?: string, Allocations?: list, AttachmentMode?: string, Capacity?: int, CloneID?: string, Context?: record, ControllerRequired?: bool, ControllersExpected?: int, ControllersHealthy?: int, CreateIndex?: int, ExternalID?: string, ID?: string, ModifyIndex?: int, MountOptions?: record, Name?: string, Namespace?: string, NodesExpected?: int, NodesHealthy?: int, Parameters?: record, PluginID?: string, Provider?: string, ProviderVersion?: string, ReadAllocs?: record, RequestedCapabilities?: list, RequestedCapacityMax?: int, RequestedCapacityMin?: int, RequestedTopologies?: record, ResourceExhausted?: string, Schedulable?: bool, Secrets?: record, SnapshotID?: string, Topologies?: list, WriteAllocs?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes" $qp)
  let body = {Namespace: $Namespace, Region: $Region, SecretID: $SecretID, Volumes: $Volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /volumes/external
#
# operationId: GetExternalVolumes
export def "volumes-external GetExternalVolumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --plugin-id: string # Filters volume lists by plugin ID.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "plugin_id" $plugin_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/external" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /volumes/snapshot
#
# operationId: DeleteSnapshot
export def "volumes-snapshot DeleteSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --plugin-id: string # Filters volume lists by plugin ID.
  --snapshot-id: string # The ID of the snapshot to target.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar") (serialize-qp "plugin_id" $plugin_id "scalar") (serialize-qp "snapshot_id" $snapshot_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/snapshot" $qp)
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /volumes/snapshot
#
# operationId: GetSnapshots
export def "volumes-snapshot GetSnapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --wait: string # Provided with IndexParam to wait for change.
  --stale: string # If present, results will include stale reads.
  --prefix: string # Constrains results to jobs that start with the defined prefix
  --per-page: int # Maximum number of results to return.
  --next-token: string # Indicates where to start paging for queries that support pagination.
  --plugin-id: string # Filters volume lists by plugin ID.
  --index: int # If set, wait until query exceeds given index. Must be provided with WaitParam.
  --X-Nomad-Token: string # A Nomad ACL token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "stale" $stale "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "next_token" $next_token "scalar") (serialize-qp "plugin_id" $plugin_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/snapshot" $qp)
  let extra_headers = {"index": $index, "X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /volumes/snapshot
#
# operationId: PostSnapshot
# --Snapshots item shape: {CreateTime?: int, ExternalSourceVolumeID?: string, ID?: string, IsReady?: bool, Name?: string, Parameters?: record, PluginID?: string, Secrets?: record, SizeBytes?: int, SourceVolumeID?: string}
export def "volumes-snapshot PostSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --region: string # Filters results based on the specified region.
  --namespace: string # Filters results based on the specified namespace.
  --idempotency-token: string # Can be used to ensure operations are only run once.
  --X-Nomad-Token: string # A Nomad ACL token.
  --Namespace: string
  --Region: string
  --SecretID: string
  --Snapshots: list # item shape: {CreateTime?: int, ExternalSourceVolumeID?: string, ID?: string, IsReady?: bool, Name?: string, Parameters?: record, PluginID?: string, Secrets?: record, SizeBytes?: int, SourceVolumeID?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-nomad-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "idempotency_token" $idempotency_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/snapshot" $qp)
  let body = {Namespace: $Namespace, Region: $Region, SecretID: $SecretID, Snapshots: $Snapshots} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Nomad-Token": $X_Nomad_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
