# Auto-generated client for Ory Keto API v
# Source: https://raw.githubusercontent.com/ory/keto/master/spec/api.json
# Auth: --token flag or $env.ORY_KETO_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORY_KETO_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-relation-tuples delete" } } | get name | first)
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

# Delete Relationships
#
# DELETE /admin/relation-tuples
# operationId: deleteRelationships
export def "admin-relation-tuples delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Namespace of the Relationship
  --object: string # Object of the Relationship
  --relation: string # Relation of the Relationship
  --subject-id: string # SubjectID of the Relationship
  --subject-setnamespace: string # Namespace of the Subject Set
  --subject-setobject: string # Object of the Subject Set
  --subject-setrelation: string # Relation of the Subject Set
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "subject_id" $subject_id "scalar") (serialize-qp "subject_set.namespace" $subject_setnamespace "scalar") (serialize-qp "subject_set.object" $subject_setobject "scalar") (serialize-qp "subject_set.relation" $subject_setrelation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/relation-tuples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Multiple Relationships
#
# PATCH /admin/relation-tuples
# operationId: patchRelationships
export def "admin-relation-tuples patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/relation-tuples")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Relationship
#
# PUT /admin/relation-tuples
# operationId: createRelationship
# --subject_set shape: {namespace: string, object: string, relation: string}
export def "admin-relation-tuples createRelationship" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Namespace to query
  --object: string # Object to query
  --relation: string # Relation to query
  --subject-id: string # SubjectID to query  Either SubjectSet or SubjectID can be provided.
  --subject-set: record # shape: {namespace: string, object: string, relation: string}
]: any -> record<namespace: string, object: string, relation: string, subject_id: string, subject_set: record<namespace: string, object: string, relation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/relation-tuples")
  let body = {namespace: $namespace, object: $object, relation: $relation, subject_id: $subject_id, subject_set: $subject_set} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check HTTP Server Status
#
# GET /health/alive
# operationId: isAlive
export def "health-alive isAlive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/alive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check HTTP Server and Database Status
#
# GET /health/ready
# operationId: isReady
export def "health-ready isReady" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/ready")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query namespaces
#
# GET /namespaces
# operationId: listRelationshipNamespaces
export def "namespaces listRelationshipNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<namespaces: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/namespaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check the syntax of an OPL file
#
# POST /opl/syntax/check
# operationId: checkOplSyntax
export def "opl-syntax-check checkOplSyntax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<errors: table<end: record, message: string, start: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/opl/syntax/check")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/plain" $body
}

# Query relationships
#
# GET /relation-tuples
# operationId: getRelationships
export def "relation-tuples get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Items per Page  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --namespace: string # Namespace of the Relationship
  --object: string # Object of the Relationship
  --relation: string # Relation of the Relationship
  --subject-id: string # SubjectID of the Relationship
  --subject-setnamespace: string # Namespace of the Subject Set
  --subject-setobject: string # Object of the Subject Set
  --subject-setrelation: string # Relation of the Subject Set
]: nothing -> record<next_page_token: string, relation_tuples: table<namespace: string, object: string, relation: string, subject_id: string, subject_set: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "subject_id" $subject_id "scalar") (serialize-qp "subject_set.namespace" $subject_setnamespace "scalar") (serialize-qp "subject_set.object" $subject_setobject "scalar") (serialize-qp "subject_set.relation" $subject_setrelation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch check permissions
#
# POST /relation-tuples/batch/check
# operationId: batchCheckPermission
# --tuples item shape: {namespace: string, object: string, relation: string, subject_id?: string, subject_set?: record}
export def "relation-tuples-batch-check batchCheckPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-depth: int # format: int64
  --tuples: list # item shape: {namespace: string, object: string, relation: string, subject_id?: string, subject_set?: record}
]: any -> record<results: table<allowed: bool, error: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max-depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples/batch/check" $qp)
  let body = {tuples: $tuples} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check a permission
#
# GET /relation-tuples/check
# operationId: checkPermissionOrError
export def "relation-tuples-check checkPermissionOrError" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Namespace of the Relationship
  --object: string # Object of the Relationship
  --relation: string # Relation of the Relationship
  --subject-id: string # SubjectID of the Relationship
  --subject-setnamespace: string # Namespace of the Subject Set
  --subject-setobject: string # Object of the Subject Set
  --subject-setrelation: string # Relation of the Subject Set
  --max-depth: int # format: int64
]: nothing -> record<allowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "subject_id" $subject_id "scalar") (serialize-qp "subject_set.namespace" $subject_setnamespace "scalar") (serialize-qp "subject_set.object" $subject_setobject "scalar") (serialize-qp "subject_set.relation" $subject_setrelation "scalar") (serialize-qp "max-depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples/check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check a permission
#
# POST /relation-tuples/check
# operationId: postCheckPermissionOrError
# --subject_set shape: {namespace: string, object: string, relation: string}
export def "relation-tuples-check post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-depth: int # format: int64
  --namespace: string # Namespace to query
  --object: string # Object to query
  --relation: string # Relation to query
  --subject-id: string # SubjectID to query  Either SubjectSet or SubjectID can be provided.
  --subject-set: record # shape: {namespace: string, object: string, relation: string}
]: any -> record<allowed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max-depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples/check" $qp)
  let body = {namespace: $namespace, object: $object, relation: $relation, subject_id: $subject_id, subject_set: $subject_set} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check a permission
#
# GET /relation-tuples/check/openapi
# operationId: checkPermission
export def "relation-tuples-check-openapi checkPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Namespace of the Relationship
  --object: string # Object of the Relationship
  --relation: string # Relation of the Relationship
  --subject-id: string # SubjectID of the Relationship
  --subject-setnamespace: string # Namespace of the Subject Set
  --subject-setobject: string # Object of the Subject Set
  --subject-setrelation: string # Relation of the Subject Set
  --max-depth: int # format: int64
]: nothing -> record<allowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "subject_id" $subject_id "scalar") (serialize-qp "subject_set.namespace" $subject_setnamespace "scalar") (serialize-qp "subject_set.object" $subject_setobject "scalar") (serialize-qp "subject_set.relation" $subject_setrelation "scalar") (serialize-qp "max-depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples/check/openapi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check a permission
#
# POST /relation-tuples/check/openapi
# operationId: postCheckPermission
# --subject_set shape: {namespace: string, object: string, relation: string}
export def "relation-tuples-check-openapi post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-depth: int # format: int64
  --namespace: string # Namespace to query
  --object: string # Object to query
  --relation: string # Relation to query
  --subject-id: string # SubjectID to query  Either SubjectSet or SubjectID can be provided.
  --subject-set: record # shape: {namespace: string, object: string, relation: string}
]: any -> record<allowed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max-depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples/check/openapi" $qp)
  let body = {namespace: $namespace, object: $object, relation: $relation, subject_id: $subject_id, subject_set: $subject_set} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Expand a Relationship into permissions.
#
# GET /relation-tuples/expand
# operationId: expandPermissions
export def "relation-tuples-expand expandPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string # Namespace of the Subject Set
  --object: string # Object of the Subject Set
  --relation: string # Relation of the Subject Set
  --max-depth: int # format: int64
]: nothing -> record<children: list<any>, tuple: record<namespace: string, object: string, relation: string, subject_id: string, subject_set: record<namespace: string, object: string, relation: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "relation" $relation "scalar") (serialize-qp "max-depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/relation-tuples/expand" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return Running Software Version.
#
# GET /version
# operationId: getVersion
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
