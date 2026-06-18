# Auto-generated client for Amazon CloudDirectory v2017-01-11
# Source: https://api.apis.guru/v2/specs/amazonaws.com/clouddirectory/2017-01-11/openapi.json
# Auth: --token flag or $env.AMAZON_CLOUDDIRECTORY_TOKEN

const BASE_URL = "http://clouddirectory.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CLOUDDIRECTORY_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://clouddirectory.us-east-1.amazonaws.com" "http://clouddirectory.us-east-2.amazonaws.com" "http://clouddirectory.us-west-1.amazonaws.com" "http://clouddirectory.us-west-2.amazonaws.com" "http://clouddirectory.us-gov-west-1.amazonaws.com" "http://clouddirectory.us-gov-east-1.amazonaws.com" "http://clouddirectory.ca-central-1.amazonaws.com" "http://clouddirectory.eu-north-1.amazonaws.com" "http://clouddirectory.eu-west-1.amazonaws.com" "http://clouddirectory.eu-west-2.amazonaws.com" "http://clouddirectory.eu-west-3.amazonaws.com" "http://clouddirectory.eu-central-1.amazonaws.com" "http://clouddirectory.eu-south-1.amazonaws.com" "http://clouddirectory.af-south-1.amazonaws.com" "http://clouddirectory.ap-northeast-1.amazonaws.com" "http://clouddirectory.ap-northeast-2.amazonaws.com" "http://clouddirectory.ap-northeast-3.amazonaws.com" "http://clouddirectory.ap-southeast-1.amazonaws.com" "http://clouddirectory.ap-southeast-2.amazonaws.com" "http://clouddirectory.ap-east-1.amazonaws.com" "http://clouddirectory.ap-south-1.amazonaws.com" "http://clouddirectory.sa-east-1.amazonaws.com" "http://clouddirectory.me-south-1.amazonaws.com" "https://clouddirectory.us-east-1.amazonaws.com" "https://clouddirectory.us-east-2.amazonaws.com" "https://clouddirectory.us-west-1.amazonaws.com" "https://clouddirectory.us-west-2.amazonaws.com" "https://clouddirectory.us-gov-west-1.amazonaws.com" "https://clouddirectory.us-gov-east-1.amazonaws.com" "https://clouddirectory.ca-central-1.amazonaws.com" "https://clouddirectory.eu-north-1.amazonaws.com" "https://clouddirectory.eu-west-1.amazonaws.com" "https://clouddirectory.eu-west-2.amazonaws.com" "https://clouddirectory.eu-west-3.amazonaws.com" "https://clouddirectory.eu-central-1.amazonaws.com" "https://clouddirectory.eu-south-1.amazonaws.com" "https://clouddirectory.af-south-1.amazonaws.com" "https://clouddirectory.ap-northeast-1.amazonaws.com" "https://clouddirectory.ap-northeast-2.amazonaws.com" "https://clouddirectory.ap-northeast-3.amazonaws.com" "https://clouddirectory.ap-southeast-1.amazonaws.com" "https://clouddirectory.ap-southeast-2.amazonaws.com" "https://clouddirectory.ap-east-1.amazonaws.com" "https://clouddirectory.ap-south-1.amazonaws.com" "https://clouddirectory.sa-east-1.amazonaws.com" "https://clouddirectory.me-south-1.amazonaws.com" "http://clouddirectory.cn-north-1.amazonaws.com.cn" "http://clouddirectory.cn-northwest-1.amazonaws.com.cn" "https://clouddirectory.cn-north-1.amazonaws.com.cn" "https://clouddirectory.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-consistency-level-completer [] { ["EVENTUAL" "SERIALIZABLE"] }
def object-type-completer [] { ["INDEX" "LEAF_NODE" "NODE" "POLICY"] }
def facet-style-completer [] { ["DYNAMIC" "STATIC"] }
def consistency-level-completer [] { ["EVENTUAL" "SERIALIZABLE"] }
def state-completer [] { ["DELETED" "DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "amazonclouddirectory-2017-01-11-object-facetsx-amz-data-partition create-facet" } } | get name | first)
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

# Adds a new Facet to an object. An object can have more than one facet applied on it.
#
# PUT /amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition
# operationId: AddFacetToObject
# --SchemaFacet shape: {SchemaArn?: any, FacetName?: any}
# --ObjectAttributeList item shape: {Key: any, Value: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-facetsx-amz-data-partition create-facet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns.
  schema_facet: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
  --object-attribute-list: list # Attributes on the facet that you are adding to the object. — item shape: {Key: any, Value: any}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition")
  let req_body = {"SchemaFacet": $schema_facet, "ObjectAttributeList": $object_attribute_list, "ObjectReference": $object_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Copies the input published schema, at the specified version, into the Directory with the same name and version as that of the published schema.
#
# PUT /amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition
# operationId: ApplySchema
export def "amazonclouddirectory-2017-01-11-schema-applyx-amz-data-partition update-apply" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory into which the schema is copied. For more information, see arns.
  published_schema_arn: string # Published schema Amazon Resource Name (ARN) that needs to be copied. For more information, see arns.
]: any -> record<AppliedSchemaArn: record, DirectoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition")
  let req_body = {"PublishedSchemaArn": $published_schema_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Attaches an existing object to another object. An object can be accessed in two ways: Using the path Using ObjectIdentifier
#
# PUT /amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition
# operationId: AttachObject
# --ParentReference shape: {Selector?: any}
# --ChildReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-attachx-amz-data-partition attach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # Amazon Resource Name (ARN) that is associated with the Directory where both objects reside. For more information, see arns.
  parent_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  child_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  link_name: string # The link name with which the child object is attached to the parent.
]: any -> record<AttachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition")
  let req_body = {"ParentReference": $parent_reference, "ChildReference": $child_reference, "LinkName": $link_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Attaches a policy object to a regular object. An object can have a limited number of attached policies.
#
# PUT /amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition
# operationId: AttachPolicy
# --PolicyReference shape: {Selector?: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-attachx-amz-data-partition attach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where both objects reside. For more information, see arns.
  policy_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition")
  let req_body = {"PolicyReference": $policy_reference, "ObjectReference": $object_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Attaches the specified object to the specified index.
#
# PUT /amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition
# operationId: AttachToIndex
# --IndexReference shape: {Selector?: any}
# --TargetReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-index-attachx-amz-data-partition attach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where the object and index exist.
  index_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  target_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record<AttachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition")
  let req_body = {"IndexReference": $index_reference, "TargetReference": $target_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Attaches a typed link to a specified source and target object. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition
# operationId: AttachTypedLink
# --SourceObjectReference shape: {Selector?: any}
# --TargetObjectReference shape: {Selector?: any}
# --TypedLinkFacet shape: {SchemaArn?: any, TypedLinkName?: any}
# --Attributes item shape: {AttributeName: any, Value: any}
export def "amazonclouddirectory-2017-01-11-typedlink-attachx-amz-data-partition attach-typed-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to attach the typed link.
  source_object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  target_object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  typed_link_facet: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: any, TypedLinkName?: any}
  attributes: list # A set of attributes that are associated with the typed link. — item shape: {AttributeName: any, Value: any}
]: any -> record<TypedLinkSpecifier: record<TypedLinkFacet: record<SchemaArn: record, TypedLinkName: record>, SourceObjectReference: record<Selector: record>, TargetObjectReference: record<Selector: record>, IdentityAttributeValues: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition")
  let req_body = {"SourceObjectReference": $source_object_reference, "TargetObjectReference": $target_object_reference, "TypedLinkFacet": $typed_link_facet, "Attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Performs all the read operations in a batch.
#
# POST /amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition
# operationId: BatchRead
# --Operations item shape: {ListObjectAttributes?: any, ListObjectChildren?: any, ListAttachedIndices?: any, ListObjectParentPaths?: any, GetObjectInformation?: any, GetObjectAttributes?: any, ListObjectParents?: any, ListObjectPolicies?: any, ListPolicyAttachments?: any, LookupPolicy?: any, ListIndex?: any, ListOutgoingTypedLinks?: any, ListIncomingTypedLinks?: any, GetLinkAttributes?: any}
export def "amazonclouddirectory-2017-01-11-batchreadx-amz-data-partition get-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory. For more information, see arns.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  operations: list # A list of operations that are part of the batch. — item shape: {ListObjectAttributes?: any, ListObjectChildren?: any, ListAttachedIndices?: any, ListObjectParentPaths?: any, GetObjectInformation?: any, GetObjectAttributes?: any, ListObjectParents?: any, ListObjectPolicies?: any, ListPolicyAttachments?: any, LookupPolicy?: any, ListIndex?: any, ListOutgoingTypedLinks?: any, ListIncomingTypedLinks?: any, GetLinkAttributes?: any}
]: any -> record<Responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition")
  let req_body = {"Operations": $operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Performs all the write operations in a batch. Either all the operations succeed or none.
#
# PUT /amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition
# operationId: BatchWrite
# --Operations item shape: {CreateObject?: any, AttachObject?: any, DetachObject?: any, UpdateObjectAttributes?: any, DeleteObject?: any, AddFacetToObject?: any, RemoveFacetFromObject?: any, AttachPolicy?: any, DetachPolicy?: any, CreateIndex?: any, AttachToIndex?: any, DetachFromIndex?: any, AttachTypedLink?: any, DetachTypedLink?: any, UpdateLinkAttributes?: any}
export def "amazonclouddirectory-2017-01-11-batchwritex-amz-data-partition update-batch-write" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory. For more information, see arns.
  operations: list # A list of operations that are part of the batch. — item shape: {CreateObject?: any, AttachObject?: any, DetachObject?: any, UpdateObjectAttributes?: any, DeleteObject?: any, AddFacetToObject?: any, RemoveFacetFromObject?: any, AttachPolicy?: any, DetachPolicy?: any, CreateIndex?: any, AttachToIndex?: any, DetachFromIndex?: any, AttachTypedLink?: any, DetachTypedLink?: any, UpdateLinkAttributes?: any}
]: any -> record<Responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition")
  let req_body = {"Operations": $operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a Directory by copying the published schema into the directory. A directory cannot be created without a schema. You can also quickly create a directory using a managed schema, called the QuickStartSchema. For more information, see Managed Schema (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html) in the Amazon Cloud Directory Developer Guide.
#
# PUT /amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition
# operationId: CreateDirectory
export def "amazonclouddirectory-2017-01-11-directory-createx-amz-data-partition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the published schema that will be copied into the data Directory. For more information, see arns.
  name: string # The name of the Directory. Should be unique per account, per region.
]: any -> record<DirectoryArn: record, Name: record, ObjectIdentifier: record, AppliedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a new Facet in a schema. Facet creation is allowed only in development or applied schemas.
#
# PUT /amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition
# operationId: CreateFacet
# --Attributes item shape: {Name: any, AttributeDefinition?: any, AttributeReference?: any, RequiredBehavior?: any}
export def "amazonclouddirectory-2017-01-11-facet-createx-amz-data-partition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The schema ARN in which the new Facet will be created. For more information, see arns.
  name: string # The name of the Facet, which is unique for a given schema.
  --attributes: list # The attributes that are associated with the Facet. — item shape: {Name: any, AttributeDefinition?: any, AttributeReference?: any, RequiredBehavior?: any}
  --object-type: string@object-type-completer # Specifies whether a given object created from this facet is of type node, leaf node, policy or index. Node: Can have multiple children but one parent. Leaf node: Cannot have children but can have multiple parents. Policy: Allows you to store a policy document and policy type. For more information, see Policies (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies). Index: Can be created with the Index API.
  --facet-style: string@facet-style-completer # There are two different styles that you can define on any given facet, Static and Dynamic. For static facets, all attributes must be defined in the schema. For dynamic facets, attributes can be defined during data plane operations.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition")
  let req_body = {"Name": $name, "Attributes": $attributes, "ObjectType": $object_type, "FacetStyle": $facet_style} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an index object. See Indexing and search (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html) for more information.
#
# PUT /amazonclouddirectory/2017-01-11/index#x-amz-data-partition
# operationId: CreateIndex
# --OrderedIndexedAttributeList item shape: {SchemaArn: any, FacetName: any, Name: any}
# --ParentReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-indexx-amz-data-partition create-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory where the index should be created.
  ordered_indexed_attribute_list: list # Specifies the attributes that should be indexed on. Currently only a single attribute is supported. — item shape: {SchemaArn: any, FacetName: any, Name: any}
  --is-unique: oneof<nothing, bool> # Indicates whether the attribute that is being indexed has unique values or not.
  --parent-reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --link-name: string # The name of the link between the parent object and the index object.
]: any -> record<ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition")
  let req_body = {"OrderedIndexedAttributeList": $ordered_indexed_attribute_list, "IsUnique": $is_unique, "ParentReference": $parent_reference, "LinkName": $link_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates an object in a Directory. Additionally attaches the object to a parent, if a parent reference and LinkName is specified. An object is simply a collection of Facet attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet.
#
# PUT /amazonclouddirectory/2017-01-11/object#x-amz-data-partition
# operationId: CreateObject
# --SchemaFacets item shape: {SchemaArn?: any, FacetName?: any}
# --ObjectAttributeList item shape: {Key: any, Value: any}
# --ParentReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-objectx-amz-data-partition create-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory in which the object will be created. For more information, see arns.
  schema_facets: list # A list of schema facets to be associated with the object. Do not provide minor version components. See SchemaFacet for details. — item shape: {SchemaArn?: any, FacetName?: any}
  --object-attribute-list: list # The attribute map whose attribute ARN contains the key and attribute value as the map value. — item shape: {Key: any, Value: any}
  --parent-reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --link-name: string # The name of link that is used to attach this object to a parent.
]: any -> record<ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition")
  let req_body = {"SchemaFacets": $schema_facets, "ObjectAttributeList": $object_attribute_list, "ParentReference": $parent_reference, "LinkName": $link_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a new schema in a development state. A schema can exist in three phases: Development: This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published. Published: Published schemas are immutable and have a version associated with them. Applied: Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories.
#
# PUT /amazonclouddirectory/2017-01-11/schema/create
# operationId: CreateSchema
export def "amazonclouddirectory-2017-01-11-schema-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name that is associated with the schema. This is unique to each account and in each region.
]: any -> record<SchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/create")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition
# operationId: CreateTypedLinkFacet
# --Facet shape: {Name?: any, Attributes?: any, IdentityAttributeOrder?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-facet-createx-amz-data-partition create-typed-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns.
  facet: record # Defines the typed links structure and its attributes. To create a typed link facet, use the CreateTypedLinkFacet API. — shape: {Name?: any, Attributes?: any, IdentityAttributeOrder?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition")
  let req_body = {"Facet": $facet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
#
# PUT /amazonclouddirectory/2017-01-11/directory#x-amz-data-partition
# operationId: DeleteDirectory
export def "amazonclouddirectory-2017-01-11-directoryx-amz-data-partition delete-directory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory to delete.
]: nothing -> record<DirectoryArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a given Facet. All attributes and Rules that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
#
# PUT /amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition
# operationId: DeleteFacet
export def "amazonclouddirectory-2017-01-11-facet-deletex-amz-data-partition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Facet. For more information, see arns.
  name: string # The name of the facet to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see Amazon Cloud Directory Limits (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html).
#
# PUT /amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition
# operationId: DeleteObject
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-deletex-amz-data-partition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition")
  let req_body = {"ObjectReference": $object_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a given schema. Schemas in a development and published state can only be deleted.
#
# PUT /amazonclouddirectory/2017-01-11/schema#x-amz-data-partition
# operationId: DeleteSchema
export def "amazonclouddirectory-2017-01-11-schemax-amz-data-partition delete-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the development schema. For more information, see arns.
]: nothing -> record<SchemaArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition
# operationId: DeleteTypedLinkFacet
export def "amazonclouddirectory-2017-01-11-typedlink-facet-deletex-amz-data-partition delete-typed-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns.
  name: string # The unique name of the typed link facet.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Detaches the specified object from the specified index.
#
# PUT /amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition
# operationId: DetachFromIndex
# --IndexReference shape: {Selector?: any}
# --TargetReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-index-detachx-amz-data-partition update-detach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory the index and object exist in.
  index_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  target_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record<DetachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition")
  let req_body = {"IndexReference": $index_reference, "TargetReference": $target_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
#
# PUT /amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition
# operationId: DetachObject
# --ParentReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-detachx-amz-data-partition update-detach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where objects reside. For more information, see arns.
  parent_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  link_name: string # The link name associated with the object that needs to be detached.
]: any -> record<DetachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition")
  let req_body = {"ParentReference": $parent_reference, "LinkName": $link_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Detaches a policy from an object.
#
# PUT /amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition
# operationId: DetachPolicy
# --PolicyReference shape: {Selector?: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-detachx-amz-data-partition update-detach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where both objects reside. For more information, see arns.
  policy_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition")
  let req_body = {"PolicyReference": $policy_reference, "ObjectReference": $object_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Detaches a typed link from a specified source and target object. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition
# operationId: DetachTypedLink
# --TypedLinkSpecifier shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-detachx-amz-data-partition update-detach-typed-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to detach the typed link.
  typed_link_specifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The AttachTypedLink API returns a typed link specifier while the DetachTypedLink API accepts one as input. Similarly, the ListIncomingTypedLinks and ListOutgoingTypedLinks API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition")
  let req_body = {"TypedLinkSpecifier": $typed_link_specifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
#
# PUT /amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition
# operationId: DisableDirectory
export def "amazonclouddirectory-2017-01-11-directory-disablex-amz-data-partition disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory to disable.
]: nothing -> record<DirectoryArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
#
# PUT /amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition
# operationId: EnableDirectory
export def "amazonclouddirectory-2017-01-11-directory-enablex-amz-data-partition enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory to enable.
]: nothing -> record<DirectoryArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns current applied schema version ARN, including the minor version in use.
#
# POST /amazonclouddirectory/2017-01-11/schema/getappliedschema
# operationId: GetAppliedSchemaVersion
export def "amazonclouddirectory-2017-01-11-schema-getappliedschema get-applied-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  schema_arn: string # The ARN of the applied schema.
]: any -> record<AppliedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/getappliedschema")
  let req_body = {"SchemaArn": $schema_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves metadata about a directory.
#
# POST /amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition
# operationId: GetDirectory
export def "amazonclouddirectory-2017-01-11-directory-getx-amz-data-partition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory.
]: nothing -> record<Directory: record<Name: record, DirectoryArn: record, State: record, CreationDateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets details of the Facet, such as facet name, attributes, Rules, or ObjectType. You can call this on all kinds of schema facets -- published, development, or applied.
#
# POST /amazonclouddirectory/2017-01-11/facet#x-amz-data-partition
# operationId: GetFacet
export def "amazonclouddirectory-2017-01-11-facetx-amz-data-partition get-facet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Facet. For more information, see arns.
  name: string # The name of the facet to retrieve.
]: any -> record<Facet: record<Name: record, ObjectType: record, FacetStyle: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Does the following: Adds new Attributes, Rules, or ObjectTypes. Updates existing Attributes, Rules, or ObjectTypes. Deletes existing Attributes, Rules, or ObjectTypes.
#
# PUT /amazonclouddirectory/2017-01-11/facet#x-amz-data-partition
# operationId: UpdateFacet
# --AttributeUpdates item shape: {Attribute?: any, Action?: any}
export def "amazonclouddirectory-2017-01-11-facetx-amz-data-partition update-facet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Facet. For more information, see arns.
  name: string # The name of the facet.
  --attribute-updates: list # List of attributes that need to be updated in a given schema Facet. Each attribute is followed by AttributeAction, which specifies the type of update operation to perform. — item shape: {Attribute?: any, Action?: any}
  --object-type: string@object-type-completer # The object type that is associated with the facet. See CreateFacetRequest$ObjectType for more details.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition")
  let req_body = {"Name": $name, "AttributeUpdates": $attribute_updates, "ObjectType": $object_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attributes that are associated with a typed link.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition
# operationId: GetLinkAttributes
# --TypedLinkSpecifier shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-attributes-getx-amz-data-partition get-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see arns or Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
  typed_link_specifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The AttachTypedLink API returns a typed link specifier while the DetachTypedLink API accepts one as input. Similarly, the ListIncomingTypedLinks and ListOutgoingTypedLinks API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
  attribute_names: list<string> # A list of attribute names whose values will be retrieved.
  --consistency-level: string@consistency-level-completer # The consistency level at which to retrieve the attributes on a typed link.
]: any -> record<Attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition")
  let req_body = {"TypedLinkSpecifier": $typed_link_specifier, "AttributeNames": $attribute_names, "ConsistencyLevel": $consistency_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attributes within a facet that are associated with an object.
#
# POST /amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition
# operationId: GetObjectAttributes
# --ObjectReference shape: {Selector?: any}
# --SchemaFacet shape: {SchemaArn?: any, FacetName?: any}
export def "amazonclouddirectory-2017-01-11-object-attributes-getx-amz-data-partition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level at which to retrieve the attributes on an object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  schema_facet: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
  attribute_names: list<string> # List of attribute names whose values will be retrieved.
]: any -> record<Attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition")
  let req_body = {"ObjectReference": $object_reference, "SchemaFacet": $schema_facet, "AttributeNames": $attribute_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves metadata about an object.
#
# POST /amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition
# operationId: GetObjectInformation
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-informationx-amz-data-partition get-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory being retrieved.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level at which to retrieve the object information.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record<SchemaFacets: record, ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition")
  let req_body = {"ObjectReference": $object_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a JSON representation of the schema. See JSON Schema Format (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json) for more information.
#
# POST /amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition
# operationId: GetSchemaAsJson
export def "amazonclouddirectory-2017-01-11-schema-jsonx-amz-data-partition get-as-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the schema to retrieve.
]: nothing -> record<Name: record, Document: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Allows a schema to be updated using JSON upload. Only available for development schemas. See JSON Schema Format (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json) for more information.
#
# PUT /amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition
# operationId: PutSchemaFromJson
export def "amazonclouddirectory-2017-01-11-schema-jsonx-amz-data-partition update-from-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the schema to update.
  document: string # The replacement JSON schema.
]: any -> record<Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition")
  let req_body = {"Document": $document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns the identity attribute order for a specific TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition
# operationId: GetTypedLinkFacetInformation
export def "amazonclouddirectory-2017-01-11-typedlink-facet-getx-amz-data-partition get-typed-link-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns.
  name: string # The unique name of the typed link facet.
]: any -> record<IdentityAttributeOrder: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists schema major versions applied to a directory. If SchemaArn is provided, lists the minor version.
#
# POST /amazonclouddirectory/2017-01-11/schema/applied
# operationId: ListAppliedSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-applied list-arns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  directory_arn: string # The ARN of the directory you are listing.
  --schema-arn: string # The response for ListAppliedSchemaArns when this parameter is used will list all minor version ARNs for a major version.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/applied" $qp)
  let req_body = {"DirectoryArn": $directory_arn, "SchemaArn": $schema_arn, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists indices attached to the specified object.
#
# POST /amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition
# operationId: ListAttachedIndices
# --TargetReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-indicesx-amz-data-partition list-attached-indices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level to use for this operation.
  target_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<IndexAttachments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition" $qp)
  let req_body = {"TargetReference": $target_reference, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
#
# POST /amazonclouddirectory/2017-01-11/schema/development
# operationId: ListDevelopmentSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-development list-arns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/development" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists directories created within an account.
#
# POST /amazonclouddirectory/2017-01-11/directory/list
# operationId: ListDirectories
export def "amazonclouddirectory-2017-01-11-directory-list list-directories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
  --state: string@state-completer # The state of the directories in the list. Can be either Enabled, Disabled, or Deleted.
]: any -> record<Directories: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/list" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attributes attached to the facet.
#
# POST /amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition
# operationId: ListFacetAttributes
export def "amazonclouddirectory-2017-01-11-facet-attributesx-amz-data-partition list-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the schema where the facet resides.
  name: string # The name of the facet whose attributes will be retrieved.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<Attributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition" $qp)
  let req_body = {"Name": $name, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves the names of facets that exist in a schema.
#
# POST /amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition
# operationId: ListFacetNames
export def "amazonclouddirectory-2017-01-11-facet-listx-amz-data-partition list-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) to retrieve facet names from.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<FacetNames: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of all the incoming TypedLinkSpecifier information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition
# operationId: ListIncomingTypedLinks
# --ObjectReference shape: {Selector?: any}
# --FilterAttributeRanges item shape: {AttributeName?: any, Range: any}
# --FilterTypedLink shape: {SchemaArn?: any, TypedLinkName?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-incomingx-amz-data-partition list-incoming-typed-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --filter-attribute-ranges: list # Provides range filters for multiple attributes. When providing ranges to typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. — item shape: {AttributeName?: any, Range: any}
  --filter-typed-link: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: any, TypedLinkName?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
  --consistency-level: string@consistency-level-completer # The consistency level to execute the request at.
]: any -> record<LinkSpecifiers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition")
  let req_body = {"ObjectReference": $object_reference, "FilterAttributeRanges": $filter_attribute_ranges, "FilterTypedLink": $filter_typed_link, "NextToken": $next_token, "MaxResults": $max_results, "ConsistencyLevel": $consistency_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists objects attached to the specified index.
#
# POST /amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition
# operationId: ListIndex
# --RangesOnIndexedValues item shape: {AttributeKey?: any, Range?: any}
# --IndexReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-index-targetsx-amz-data-partition list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory that the index exists in.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level to execute the request at.
  --ranges-on-indexed-values: list # Specifies the ranges of indexed values that you want to query. — item shape: {AttributeKey?: any, Range?: any}
  index_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --max-results: int # The maximum number of objects in a single page to retrieve from the index during a request. For more information, see Amazon Cloud Directory Limits (http://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html).
  --next-token: string # The pagination token.
]: any -> record<IndexAttachments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition" $qp)
  let req_body = {"RangesOnIndexedValues": $ranges_on_indexed_values, "IndexReference": $index_reference, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
#
# POST /amazonclouddirectory/2017-01-11/schema/managed
# operationId: ListManagedSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-managed list-arns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --schema-arn: string # The response for ListManagedSchemaArns. When this parameter is used, all minor version ARNs for a major version are listed.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/managed" $qp)
  let req_body = {"SchemaArn": $schema_arn, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all attributes that are associated with an object.
#
# POST /amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition
# operationId: ListObjectAttributes
# --ObjectReference shape: {Selector?: any}
# --FacetFilter shape: {SchemaArn?: any, FacetName?: any}
export def "amazonclouddirectory-2017-01-11-object-attributesx-amz-data-partition list-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
  --facet-filter: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
]: any -> record<Attributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition" $qp)
  let req_body = {"ObjectReference": $object_reference, "NextToken": $next_token, "MaxResults": $max_results, "FacetFilter": $facet_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of child objects that are associated with a given object.
#
# POST /amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition
# operationId: ListObjectChildren
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-childrenx-amz-data-partition list-children" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<Children: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition" $qp)
  let req_body = {"ObjectReference": $object_reference, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see Directory Structure (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html). Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined MaxResults, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.
#
# POST /amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition
# operationId: ListObjectParentPaths
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-parentpathsx-amz-data-partition list-parent-paths" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory to which the parent path applies.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<PathToObjectIdentifiersList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition" $qp)
  let req_body = {"ObjectReference": $object_reference, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists parent objects that are associated with a given object in pagination fashion.
#
# POST /amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition
# operationId: ListObjectParents
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-parentx-amz-data-partition list-parents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
  --include-all-links-to-each-parent: oneof<nothing, bool> # When set to True, returns all ListObjectParentsResponse$ParentLinks. There could be multiple links between a parent-child pair.
]: any -> record<Parents: record, NextToken: record, ParentLinks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition" $qp)
  let req_body = {"ObjectReference": $object_reference, "NextToken": $next_token, "MaxResults": $max_results, "IncludeAllLinksToEachParent": $include_all_links_to_each_parent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns policies attached to an object in pagination fashion.
#
# POST /amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition
# operationId: ListObjectPolicies
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-policyx-amz-data-partition list-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where objects reside. For more information, see arns.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<AttachedPolicyIds: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition" $qp)
  let req_body = {"ObjectReference": $object_reference, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of all the outgoing TypedLinkSpecifier information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition
# operationId: ListOutgoingTypedLinks
# --ObjectReference shape: {Selector?: any}
# --FilterAttributeRanges item shape: {AttributeName?: any, Range: any}
# --FilterTypedLink shape: {SchemaArn?: any, TypedLinkName?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-outgoingx-amz-data-partition list-outgoing-typed-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --filter-attribute-ranges: list # Provides range filters for multiple attributes. When providing ranges to typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. — item shape: {AttributeName?: any, Range: any}
  --filter-typed-link: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: any, TypedLinkName?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
  --consistency-level: string@consistency-level-completer # The consistency level to execute the request at.
]: any -> record<TypedLinkSpecifiers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition")
  let req_body = {"ObjectReference": $object_reference, "FilterAttributeRanges": $filter_attribute_ranges, "FilterTypedLink": $filter_typed_link, "NextToken": $next_token, "MaxResults": $max_results, "ConsistencyLevel": $consistency_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns all of the ObjectIdentifiers to which a given policy is attached.
#
# POST /amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition
# operationId: ListPolicyAttachments
# --PolicyReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-attachmentx-amz-data-partition list-attachments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where objects reside. For more information, see arns.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  policy_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<ObjectIdentifiers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition" $qp)
  let req_body = {"PolicyReference": $policy_reference, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the major version families of each published schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
#
# POST /amazonclouddirectory/2017-01-11/schema/published
# operationId: ListPublishedSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-published list-arns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --schema-arn: string # The response for ListPublishedSchemaArns when this parameter is used will list all minor version ARNs for a major version.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/published" $qp)
  let req_body = {"SchemaArn": $schema_arn, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
#
# POST /amazonclouddirectory/2017-01-11/tags
# operationId: ListTagsForResource
export def "amazonclouddirectory-2017-01-11-tags list-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  --next-token: string # The pagination token. This is for future use. Currently pagination is not supported for tagging.
  --max-results: int # The MaxResults parameter sets the maximum number of results returned in a single page. This is for future use and is not supported currently.
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/tags" $qp)
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of all attribute definitions for a particular TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition
# operationId: ListTypedLinkFacetAttributes
export def "amazonclouddirectory-2017-01-11-typedlink-facet-attributesx-amz-data-partition list-typed-link-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns.
  name: string # The unique name of the typed link facet.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<Attributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition" $qp)
  let req_body = {"Name": $name, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of TypedLink facet names for a particular schema. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition
# operationId: ListTypedLinkFacetNames
export def "amazonclouddirectory-2017-01-11-typedlink-facet-listx-amz-data-partition list-typed-link-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns.
  --next-token: string # The pagination token.
  --max-results: int # The maximum number of results to retrieve.
]: any -> record<FacetNames: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all policies from the root of the Directory to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the ObjectIdentifier for such objects. If policies are present, it returns ObjectIdentifier, policyId, and policyType. Paths that don't lead to the root from the target object are ignored. For more information, see Policies (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies).
#
# POST /amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition
# operationId: LookupPolicy
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-lookupx-amz-data-partition create-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory. For more information, see arns.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  --next-token: string # The token to request the next page of results.
  --max-results: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<PolicyToPathList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition" $qp)
  let req_body = {"ObjectReference": $object_reference, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publishes a development schema with a major version and a recommended minor version.
#
# PUT /amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition
# operationId: PublishSchema
export def "amazonclouddirectory-2017-01-11-schema-publishx-amz-data-partition publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the development schema. For more information, see arns.
  version: string # The major version under which the schema will be published. Schemas have both a major and minor version associated with them.
  --minor-version: string # The minor version under which the schema will be published. This parameter is recommended. Schemas have both a major and minor version associated with them.
  --name: string # The new name under which the schema will be published. If this is not provided, the development schema is considered.
]: any -> record<PublishedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition")
  let req_body = {"Version": $version, "MinorVersion": $minor_version, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes the specified facet from the specified object.
#
# PUT /amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition
# operationId: RemoveFacetFromObject
# --SchemaFacet shape: {SchemaArn?: any, FacetName?: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-facets-deletex-amz-data-partition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The ARN of the directory in which the object resides.
  schema_facet: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition")
  let req_body = {"SchemaFacet": $schema_facet, "ObjectReference": $object_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# An API operation for adding tags to a resource.
#
# PUT /amazonclouddirectory/2017-01-11/tags/add
# operationId: TagResource
# --Tags item shape: {Key?: any, Value?: any}
export def "amazonclouddirectory-2017-01-11-tags-add tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  tags: list # A list of tag key-value pairs. — item shape: {Key?: any, Value?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/tags/add")
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# An API operation for removing tags from a resource.
#
# PUT /amazonclouddirectory/2017-01-11/tags/remove
# operationId: UntagResource
export def "amazonclouddirectory-2017-01-11-tags-remove untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  resource_arn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  tag_keys: list<string> # Keys of the tag that need to be removed from the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/tags/remove")
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its IdentityAttributeOrder.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition
# operationId: UpdateLinkAttributes
# --TypedLinkSpecifier shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
# --AttributeUpdates item shape: {AttributeKey?: any, AttributeAction?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-attributes-updatex-amz-data-partition update-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see arns or Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
  typed_link_specifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The AttachTypedLink API returns a typed link specifier while the DetachTypedLink API accepts one as input. Similarly, the ListIncomingTypedLinks and ListOutgoingTypedLinks API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
  attribute_updates: list # The attributes update structure. — item shape: {AttributeKey?: any, AttributeAction?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition")
  let req_body = {"TypedLinkSpecifier": $typed_link_specifier, "AttributeUpdates": $attribute_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a given object's attributes.
#
# PUT /amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition
# operationId: UpdateObjectAttributes
# --ObjectReference shape: {Selector?: any}
# --AttributeUpdates item shape: {ObjectAttributeKey?: any, ObjectAttributeAction?: any}
export def "amazonclouddirectory-2017-01-11-object-updatex-amz-data-partition update-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the object resides. For more information, see arns.
  object_reference: record # The reference that identifies an object. — shape: {Selector?: any}
  attribute_updates: list # The attributes update structure. — item shape: {ObjectAttributeKey?: any, ObjectAttributeAction?: any}
]: any -> record<ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition")
  let req_body = {"ObjectReference": $object_reference, "AttributeUpdates": $attribute_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the schema name with a new name. Only development schema names can be updated.
#
# PUT /amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition
# operationId: UpdateSchema
export def "amazonclouddirectory-2017-01-11-schema-updatex-amz-data-partition update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the development schema. For more information, see arns.
  name: string # The name of the schema.
]: any -> record<SchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a TypedLinkFacet. For more information, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition
# operationId: UpdateTypedLinkFacet
# --AttributeUpdates item shape: {Attribute: any, Action: any}
export def "amazonclouddirectory-2017-01-11-typedlink-facetx-amz-data-partition update-typed-link-facet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see arns.
  name: string # The unique name of the typed link facet.
  attribute_updates: list # Attributes update structure. — item shape: {Attribute: any, Action: any}
  identity_attribute_order: list<string> # The order of identity attributes for the facet, from most significant to least significant. The ability to filter typed links considers the order that the attributes are defined on the typed link facet. When providing ranges to a typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. Filters are interpreted in the order of the attributes on the typed link facet, not the order in which they are supplied to any API calls. For more information about identity attributes, see Typed Links (https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition")
  let req_body = {"Name": $name, "AttributeUpdates": $attribute_updates, "IdentityAttributeOrder": $identity_attribute_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upgrades a single directory in-place using the PublishedSchemaArn with schema updates found in MinorVersion. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
#
# PUT /amazonclouddirectory/2017-01-11/schema/upgradeapplied
# operationId: UpgradeAppliedSchema
export def "amazonclouddirectory-2017-01-11-schema-upgradeapplied update-upgrade-applied" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  published_schema_arn: string # The revision of the published schema to upgrade the directory to.
  directory_arn: string # The ARN for the directory to which the upgraded schema will be applied.
  --body-dry-run: oneof<nothing, bool> # Used for testing whether the major version schemas are backward compatible or not. If schema compatibility fails, an exception would be thrown else the call would succeed but no changes will be saved. This parameter is optional.
]: any -> record<UpgradedSchemaArn: record, DirectoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/upgradeapplied")
  let req_body = {"PublishedSchemaArn": $published_schema_arn, "DirectoryArn": $directory_arn, "DryRun": $body_dry_run} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upgrades a published schema under a new minor version revision using the current contents of DevelopmentSchemaArn.
#
# PUT /amazonclouddirectory/2017-01-11/schema/upgradepublished
# operationId: UpgradePublishedSchema
export def "amazonclouddirectory-2017-01-11-schema-upgradepublished update-upgrade-published" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  development_schema_arn: string # The ARN of the development schema with the changes used for the upgrade.
  published_schema_arn: string # The ARN of the published schema to be upgraded.
  minor_version: string # Identifies the minor version of the published schema that will be created. This parameter is NOT optional.
  --body-dry-run: oneof<nothing, bool> # Used for testing whether the Development schema provided is backwards compatible, or not, with the publish schema provided by the user to be upgraded. If schema compatibility fails, an exception would be thrown else the call would succeed. This parameter is optional and defaults to false.
]: any -> record<UpgradedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/upgradepublished")
  let req_body = {"DevelopmentSchemaArn": $development_schema_arn, "PublishedSchemaArn": $published_schema_arn, "MinorVersion": $minor_version, "DryRun": $body_dry_run} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
