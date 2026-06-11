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
def base-url-completer [] { ["http://clouddirectory.us-east-1.amazonaws.com" "http://clouddirectory.us-east-2.amazonaws.com" "http://clouddirectory.us-west-1.amazonaws.com" "http://clouddirectory.us-west-2.amazonaws.com" "http://clouddirectory.us-gov-west-1.amazonaws.com" "http://clouddirectory.us-gov-east-1.amazonaws.com" "http://clouddirectory.ca-central-1.amazonaws.com" "http://clouddirectory.eu-north-1.amazonaws.com" "http://clouddirectory.eu-west-1.amazonaws.com" "http://clouddirectory.eu-west-2.amazonaws.com" "http://clouddirectory.eu-west-3.amazonaws.com" "http://clouddirectory.eu-central-1.amazonaws.com" "http://clouddirectory.eu-south-1.amazonaws.com" "http://clouddirectory.af-south-1.amazonaws.com" "http://clouddirectory.ap-northeast-1.amazonaws.com" "http://clouddirectory.ap-northeast-2.amazonaws.com" "http://clouddirectory.ap-northeast-3.amazonaws.com" "http://clouddirectory.ap-southeast-1.amazonaws.com" "http://clouddirectory.ap-southeast-2.amazonaws.com" "http://clouddirectory.ap-east-1.amazonaws.com" "http://clouddirectory.ap-south-1.amazonaws.com" "http://clouddirectory.sa-east-1.amazonaws.com" "http://clouddirectory.me-south-1.amazonaws.com" "https://clouddirectory.us-east-1.amazonaws.com" "https://clouddirectory.us-east-2.amazonaws.com" "https://clouddirectory.us-west-1.amazonaws.com" "https://clouddirectory.us-west-2.amazonaws.com" "https://clouddirectory.us-gov-west-1.amazonaws.com" "https://clouddirectory.us-gov-east-1.amazonaws.com" "https://clouddirectory.ca-central-1.amazonaws.com" "https://clouddirectory.eu-north-1.amazonaws.com" "https://clouddirectory.eu-west-1.amazonaws.com" "https://clouddirectory.eu-west-2.amazonaws.com" "https://clouddirectory.eu-west-3.amazonaws.com" "https://clouddirectory.eu-central-1.amazonaws.com" "https://clouddirectory.eu-south-1.amazonaws.com" "https://clouddirectory.af-south-1.amazonaws.com" "https://clouddirectory.ap-northeast-1.amazonaws.com" "https://clouddirectory.ap-northeast-2.amazonaws.com" "https://clouddirectory.ap-northeast-3.amazonaws.com" "https://clouddirectory.ap-southeast-1.amazonaws.com" "https://clouddirectory.ap-southeast-2.amazonaws.com" "https://clouddirectory.ap-east-1.amazonaws.com" "https://clouddirectory.ap-south-1.amazonaws.com" "https://clouddirectory.sa-east-1.amazonaws.com" "https://clouddirectory.me-south-1.amazonaws.com" "http://clouddirectory.cn-north-1.amazonaws.com.cn" "http://clouddirectory.cn-northwest-1.amazonaws.com.cn" "https://clouddirectory.cn-north-1.amazonaws.com.cn" "https://clouddirectory.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-consistency-level-completer [] { ["EVENTUAL" "SERIALIZABLE"] }
def ObjectType-completer [] { ["INDEX" "LEAF_NODE" "NODE" "POLICY"] }
def FacetStyle-completer [] { ["DYNAMIC" "STATIC"] }
def ConsistencyLevel-completer [] { ["EVENTUAL" "SERIALIZABLE"] }
def state-completer [] { ["DELETED" "DISABLED" "ENABLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "amazonclouddirectory-2017-01-11-object-facetsx-amz-data-partition AddFacetToObject" } } | get name | first)
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

# Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
#
# PUT /amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition
# operationId: AddFacetToObject
# --SchemaFacet shape: {SchemaArn?: any, FacetName?: any}
# --ObjectAttributeList item shape: {Key: any, Value: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-facetsx-amz-data-partition AddFacetToObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  SchemaFacet: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
  --ObjectAttributeList: list # Attributes on the facet that you are adding to the object. — item shape: {Key: any, Value: any}
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition")
  let body = {SchemaFacet: $SchemaFacet, ObjectAttributeList: $ObjectAttributeList, ObjectReference: $ObjectReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
#
# PUT /amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition
# operationId: ApplySchema
export def "amazonclouddirectory-2017-01-11-schema-applyx-amz-data-partition ApplySchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> into which the schema is copied. For more information, see <a>arns</a>.
  PublishedSchemaArn: string # Published schema Amazon Resource Name (ARN) that needs to be copied. For more information, see <a>arns</a>.
]: any -> record<AppliedSchemaArn: record, DirectoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition")
  let body = {PublishedSchemaArn: $PublishedSchemaArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
#
# PUT /amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition
# operationId: AttachObject
# --ParentReference shape: {Selector?: any}
# --ChildReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-attachx-amz-data-partition AttachObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ParentReference: record # The reference that identifies an object. — shape: {Selector?: any}
  ChildReference: record # The reference that identifies an object. — shape: {Selector?: any}
  LinkName: string # The link name with which the child object is attached to the parent.
]: any -> record<AttachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition")
  let body = {ParentReference: $ParentReference, ChildReference: $ChildReference, LinkName: $LinkName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attaches a policy object to a regular object. An object can have a limited number of attached policies.
#
# PUT /amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition
# operationId: AttachPolicy
# --PolicyReference shape: {Selector?: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-attachx-amz-data-partition AttachPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  PolicyReference: record # The reference that identifies an object. — shape: {Selector?: any}
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition")
  let body = {PolicyReference: $PolicyReference, ObjectReference: $ObjectReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attaches the specified object to the specified index.
#
# PUT /amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition
# operationId: AttachToIndex
# --IndexReference shape: {Selector?: any}
# --TargetReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-index-attachx-amz-data-partition AttachToIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where the object and index exist.
  IndexReference: record # The reference that identifies an object. — shape: {Selector?: any}
  TargetReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record<AttachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition")
  let body = {IndexReference: $IndexReference, TargetReference: $TargetReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition
# operationId: AttachTypedLink
# --SourceObjectReference shape: {Selector?: any}
# --TargetObjectReference shape: {Selector?: any}
# --TypedLinkFacet shape: {SchemaArn?: any, TypedLinkName?: any}
# --Attributes item shape: {AttributeName: any, Value: any}
export def "amazonclouddirectory-2017-01-11-typedlink-attachx-amz-data-partition AttachTypedLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to attach the typed link.
  SourceObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  TargetObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  TypedLinkFacet: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: any, TypedLinkName?: any}
  Attributes: list # A set of attributes that are associated with the typed link. — item shape: {AttributeName: any, Value: any}
]: any -> record<TypedLinkSpecifier: record<TypedLinkFacet: record<SchemaArn: record, TypedLinkName: record>, SourceObjectReference: record<Selector: record>, TargetObjectReference: record<Selector: record>, IdentityAttributeValues: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition")
  let body = {SourceObjectReference: $SourceObjectReference, TargetObjectReference: $TargetObjectReference, TypedLinkFacet: $TypedLinkFacet, Attributes: $Attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Performs all the read operations in a batch. 
#
# POST /amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition
# operationId: BatchRead
# --Operations item shape: {ListObjectAttributes?: any, ListObjectChildren?: any, ListAttachedIndices?: any, ListObjectParentPaths?: any, GetObjectInformation?: any, GetObjectAttributes?: any, ListObjectParents?: any, ListObjectPolicies?: any, ListPolicyAttachments?: any, LookupPolicy?: any, ListIndex?: any, ListOutgoingTypedLinks?: any, ListIncomingTypedLinks?: any, GetLinkAttributes?: any}
export def "amazonclouddirectory-2017-01-11-batchreadx-amz-data-partition BatchRead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  Operations: list # A list of operations that are part of the batch. — item shape: {ListObjectAttributes?: any, ListObjectChildren?: any, ListAttachedIndices?: any, ListObjectParentPaths?: any, GetObjectInformation?: any, GetObjectAttributes?: any, ListObjectParents?: any, ListObjectPolicies?: any, ListPolicyAttachments?: any, LookupPolicy?: any, ListIndex?: any, ListOutgoingTypedLinks?: any, ListIncomingTypedLinks?: any, GetLinkAttributes?: any}
]: any -> record<Responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition")
  let body = {Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Performs all the write operations in a batch. Either all the operations succeed or none.
#
# PUT /amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition
# operationId: BatchWrite
# --Operations item shape: {CreateObject?: any, AttachObject?: any, DetachObject?: any, UpdateObjectAttributes?: any, DeleteObject?: any, AddFacetToObject?: any, RemoveFacetFromObject?: any, AttachPolicy?: any, DetachPolicy?: any, CreateIndex?: any, AttachToIndex?: any, DetachFromIndex?: any, AttachTypedLink?: any, DetachTypedLink?: any, UpdateLinkAttributes?: any}
export def "amazonclouddirectory-2017-01-11-batchwritex-amz-data-partition BatchWrite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  Operations: list # A list of operations that are part of the batch. — item shape: {CreateObject?: any, AttachObject?: any, DetachObject?: any, UpdateObjectAttributes?: any, DeleteObject?: any, AddFacetToObject?: any, RemoveFacetFromObject?: any, AttachPolicy?: any, DetachPolicy?: any, CreateIndex?: any, AttachToIndex?: any, DetachFromIndex?: any, AttachTypedLink?: any, DetachTypedLink?: any, UpdateLinkAttributes?: any}
]: any -> record<Responses: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition")
  let body = {Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
#
# PUT /amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition
# operationId: CreateDirectory
export def "amazonclouddirectory-2017-01-11-directory-createx-amz-data-partition CreateDirectory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the published schema that will be copied into the data <a>Directory</a>. For more information, see <a>arns</a>.
  Name: string # The name of the <a>Directory</a>. Should be unique per account, per region.
]: any -> record<DirectoryArn: record, Name: record, ObjectIdentifier: record, AppliedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
#
# PUT /amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition
# operationId: CreateFacet
# --Attributes item shape: {Name: any, AttributeDefinition?: any, AttributeReference?: any, RequiredBehavior?: any}
export def "amazonclouddirectory-2017-01-11-facet-createx-amz-data-partition CreateFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The schema ARN in which the new <a>Facet</a> will be created. For more information, see <a>arns</a>.
  Name: string # The name of the <a>Facet</a>, which is unique for a given schema.
  --Attributes: list # The attributes that are associated with the <a>Facet</a>. — item shape: {Name: any, AttributeDefinition?: any, AttributeReference?: any, RequiredBehavior?: any}
  --ObjectType: string@ObjectType-completer # <p>Specifies whether a given object created from this facet is of type node, leaf node, policy or index.</p> <ul> <li> <p>Node: Can have multiple children but one parent.</p> </li> </ul> <ul> <li> <p>Leaf node: Cannot have children but can have multiple parents.</p> </li> </ul> <ul> <li> <p>Policy: Allows you to store a policy document and policy type. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.</p> </li> </ul> <ul> <li> <p>Index: Can be created with the Index API.</p> </li> </ul>
  --FacetStyle: string@FacetStyle-completer # There are two different styles that you can define on any given facet, <code>Static</code> and <code>Dynamic</code>. For static facets, all attributes must be defined in the schema. For dynamic facets, attributes can be defined during data plane operations.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition")
  let body = {Name: $Name, Attributes: $Attributes, ObjectType: $ObjectType, FacetStyle: $FacetStyle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
#
# PUT /amazonclouddirectory/2017-01-11/index#x-amz-data-partition
# operationId: CreateIndex
# --OrderedIndexedAttributeList item shape: {SchemaArn: any, FacetName: any, Name: any}
# --ParentReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-indexx-amz-data-partition CreateIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory where the index should be created.
  OrderedIndexedAttributeList: list # Specifies the attributes that should be indexed on. Currently only a single attribute is supported. — item shape: {SchemaArn: any, FacetName: any, Name: any}
  --IsUnique: string@bool-completer # Indicates whether the attribute that is being indexed has unique values or not.
  --ParentReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --LinkName: string # The name of the link between the parent object and the index object.
]: any -> record<ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition")
  let body = {OrderedIndexedAttributeList: $OrderedIndexedAttributeList, IsUnique: $IsUnique, ParentReference: $ParentReference, LinkName: $LinkName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
#
# PUT /amazonclouddirectory/2017-01-11/object#x-amz-data-partition
# operationId: CreateObject
# --SchemaFacets item shape: {SchemaArn?: any, FacetName?: any}
# --ObjectAttributeList item shape: {Key: any, Value: any}
# --ParentReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-objectx-amz-data-partition CreateObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> in which the object will be created. For more information, see <a>arns</a>.
  SchemaFacets: list # A list of schema facets to be associated with the object. Do not provide minor version components. See <a>SchemaFacet</a> for details. — item shape: {SchemaArn?: any, FacetName?: any}
  --ObjectAttributeList: list # The attribute map whose attribute ARN contains the key and attribute value as the map value. — item shape: {Key: any, Value: any}
  --ParentReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --LinkName: string # The name of link that is used to attach this object to a parent.
]: any -> record<ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition")
  let body = {SchemaFacets: $SchemaFacets, ObjectAttributeList: $ObjectAttributeList, ParentReference: $ParentReference, LinkName: $LinkName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
#
# PUT /amazonclouddirectory/2017-01-11/schema/create
# operationId: CreateSchema
export def "amazonclouddirectory-2017-01-11-schema-create CreateSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  Name: string # The name that is associated with the schema. This is unique to each account and in each region.
]: any -> record<SchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/create")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition
# operationId: CreateTypedLinkFacet
# --Facet shape: {Name?: any, Attributes?: any, IdentityAttributeOrder?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-facet-createx-amz-data-partition CreateTypedLinkFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  Facet: record # Defines the typed links structure and its attributes. To create a typed link facet, use the <a>CreateTypedLinkFacet</a> API. — shape: {Name?: any, Attributes?: any, IdentityAttributeOrder?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition")
  let body = {Facet: $Facet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
#
# PUT /amazonclouddirectory/2017-01-11/directory#x-amz-data-partition
# operationId: DeleteDirectory
export def "amazonclouddirectory-2017-01-11-directoryx-amz-data-partition DeleteDirectory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory to delete.
]: nothing -> record<DirectoryArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
#
# PUT /amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition
# operationId: DeleteFacet
export def "amazonclouddirectory-2017-01-11-facet-deletex-amz-data-partition DeleteFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  Name: string # The name of the facet to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
#
# PUT /amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition
# operationId: DeleteObject
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-deletex-amz-data-partition DeleteObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition")
  let body = {ObjectReference: $ObjectReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a given schema. Schemas in a development and published state can only be deleted. 
#
# PUT /amazonclouddirectory/2017-01-11/schema#x-amz-data-partition
# operationId: DeleteSchema
export def "amazonclouddirectory-2017-01-11-schemax-amz-data-partition DeleteSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
]: nothing -> record<SchemaArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition
# operationId: DeleteTypedLinkFacet
export def "amazonclouddirectory-2017-01-11-typedlink-facet-deletex-amz-data-partition DeleteTypedLinkFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  Name: string # The unique name of the typed link facet.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detaches the specified object from the specified index.
#
# PUT /amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition
# operationId: DetachFromIndex
# --IndexReference shape: {Selector?: any}
# --TargetReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-index-detachx-amz-data-partition DetachFromIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory the index and object exist in.
  IndexReference: record # The reference that identifies an object. — shape: {Selector?: any}
  TargetReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record<DetachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition")
  let body = {IndexReference: $IndexReference, TargetReference: $TargetReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
#
# PUT /amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition
# operationId: DetachObject
# --ParentReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-detachx-amz-data-partition DetachObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  ParentReference: record # The reference that identifies an object. — shape: {Selector?: any}
  LinkName: string # The link name associated with the object that needs to be detached.
]: any -> record<DetachedObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition")
  let body = {ParentReference: $ParentReference, LinkName: $LinkName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detaches a policy from an object.
#
# PUT /amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition
# operationId: DetachPolicy
# --PolicyReference shape: {Selector?: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-detachx-amz-data-partition DetachPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  PolicyReference: record # The reference that identifies an object. — shape: {Selector?: any}
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition")
  let body = {PolicyReference: $PolicyReference, ObjectReference: $ObjectReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition
# operationId: DetachTypedLink
# --TypedLinkSpecifier shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-detachx-amz-data-partition DetachTypedLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to detach the typed link.
  TypedLinkSpecifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The <a>AttachTypedLink</a> API returns a typed link specifier while the <a>DetachTypedLink</a> API accepts one as input. Similarly, the <a>ListIncomingTypedLinks</a> and <a>ListOutgoingTypedLinks</a> API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition")
  let body = {TypedLinkSpecifier: $TypedLinkSpecifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
#
# PUT /amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition
# operationId: DisableDirectory
export def "amazonclouddirectory-2017-01-11-directory-disablex-amz-data-partition DisableDirectory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory to disable.
]: nothing -> record<DirectoryArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
#
# PUT /amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition
# operationId: EnableDirectory
export def "amazonclouddirectory-2017-01-11-directory-enablex-amz-data-partition EnableDirectory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory to enable.
]: nothing -> record<DirectoryArn: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns current applied schema version ARN, including the minor version in use.
#
# POST /amazonclouddirectory/2017-01-11/schema/getappliedschema
# operationId: GetAppliedSchemaVersion
export def "amazonclouddirectory-2017-01-11-schema-getappliedschema GetAppliedSchemaVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  SchemaArn: string # The ARN of the applied schema.
]: any -> record<AppliedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/getappliedschema")
  let body = {SchemaArn: $SchemaArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves metadata about a directory.
#
# POST /amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition
# operationId: GetDirectory
export def "amazonclouddirectory-2017-01-11-directory-getx-amz-data-partition GetDirectory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory.
]: nothing -> record<Directory: record<Name: record, DirectoryArn: record, State: record, CreationDateTime: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
#
# POST /amazonclouddirectory/2017-01-11/facet#x-amz-data-partition
# operationId: GetFacet
export def "amazonclouddirectory-2017-01-11-facetx-amz-data-partition GetFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  Name: string # The name of the facet to retrieve.
]: any -> record<Facet: record<Name: record, ObjectType: record, FacetStyle: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
#
# PUT /amazonclouddirectory/2017-01-11/facet#x-amz-data-partition
# operationId: UpdateFacet
# --AttributeUpdates item shape: {Attribute?: any, Action?: any}
export def "amazonclouddirectory-2017-01-11-facetx-amz-data-partition UpdateFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  Name: string # The name of the facet.
  --AttributeUpdates: list # List of attributes that need to be updated in a given schema <a>Facet</a>. Each attribute is followed by <code>AttributeAction</code>, which specifies the type of update operation to perform.  — item shape: {Attribute?: any, Action?: any}
  --ObjectType: string@ObjectType-completer # The object type that is associated with the facet. See <a>CreateFacetRequest$ObjectType</a> for more details.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition")
  let body = {Name: $Name, AttributeUpdates: $AttributeUpdates, ObjectType: $ObjectType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves attributes that are associated with a typed link.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition
# operationId: GetLinkAttributes
# --TypedLinkSpecifier shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-attributes-getx-amz-data-partition GetLinkAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see <a>arns</a> or <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  TypedLinkSpecifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The <a>AttachTypedLink</a> API returns a typed link specifier while the <a>DetachTypedLink</a> API accepts one as input. Similarly, the <a>ListIncomingTypedLinks</a> and <a>ListOutgoingTypedLinks</a> API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
  AttributeNames: list # A list of attribute names whose values will be retrieved.
  --ConsistencyLevel: string@ConsistencyLevel-completer # The consistency level at which to retrieve the attributes on a typed link.
]: any -> record<Attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition")
  let body = {TypedLinkSpecifier: $TypedLinkSpecifier, AttributeNames: $AttributeNames, ConsistencyLevel: $ConsistencyLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves attributes within a facet that are associated with an object.
#
# POST /amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition
# operationId: GetObjectAttributes
# --ObjectReference shape: {Selector?: any}
# --SchemaFacet shape: {SchemaArn?: any, FacetName?: any}
export def "amazonclouddirectory-2017-01-11-object-attributes-getx-amz-data-partition GetObjectAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level at which to retrieve the attributes on an object.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  SchemaFacet: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
  AttributeNames: list # List of attribute names whose values will be retrieved.
]: any -> record<Attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition")
  let body = {ObjectReference: $ObjectReference, SchemaFacet: $SchemaFacet, AttributeNames: $AttributeNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves metadata about an object.
#
# POST /amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition
# operationId: GetObjectInformation
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-informationx-amz-data-partition GetObjectInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory being retrieved.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level at which to retrieve the object information.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record<SchemaFacets: record, ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition")
  let body = {ObjectReference: $ObjectReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
#
# POST /amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition
# operationId: GetSchemaAsJson
export def "amazonclouddirectory-2017-01-11-schema-jsonx-amz-data-partition GetSchemaAsJson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the schema to retrieve.
]: nothing -> record<Name: record, Document: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
#
# PUT /amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition
# operationId: PutSchemaFromJson
export def "amazonclouddirectory-2017-01-11-schema-jsonx-amz-data-partition PutSchemaFromJson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the schema to update.
  Document: string # The replacement JSON schema.
]: any -> record<Arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition")
  let body = {Document: $Document} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition
# operationId: GetTypedLinkFacetInformation
export def "amazonclouddirectory-2017-01-11-typedlink-facet-getx-amz-data-partition GetTypedLinkFacetInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  Name: string # The unique name of the typed link facet.
]: any -> record<IdentityAttributeOrder: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
#
# POST /amazonclouddirectory/2017-01-11/schema/applied
# operationId: ListAppliedSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-applied ListAppliedSchemaArns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DirectoryArn: string # The ARN of the directory you are listing.
  --SchemaArn: string # The response for <code>ListAppliedSchemaArns</code> when this parameter is used will list all minor version ARNs for a major version.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/applied" $qp)
  let body = {DirectoryArn: $DirectoryArn, SchemaArn: $SchemaArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists indices attached to the specified object.
#
# POST /amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition
# operationId: ListAttachedIndices
# --TargetReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-indicesx-amz-data-partition ListAttachedIndices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level to use for this operation.
  TargetReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<IndexAttachments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition" $qp)
  let body = {TargetReference: $TargetReference, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
#
# POST /amazonclouddirectory/2017-01-11/schema/development
# operationId: ListDevelopmentSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-development ListDevelopmentSchemaArns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/development" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists directories created within an account.
#
# POST /amazonclouddirectory/2017-01-11/directory/list
# operationId: ListDirectories
export def "amazonclouddirectory-2017-01-11-directory-list ListDirectories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
  --state: string@state-completer # The state of the directories in the list. Can be either Enabled, Disabled, or Deleted.
]: any -> record<Directories: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/directory/list" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves attributes attached to the facet.
#
# POST /amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition
# operationId: ListFacetAttributes
export def "amazonclouddirectory-2017-01-11-facet-attributesx-amz-data-partition ListFacetAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the schema where the facet resides.
  Name: string # The name of the facet whose attributes will be retrieved.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<Attributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition" $qp)
  let body = {Name: $Name, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the names of facets that exist in a schema.
#
# POST /amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition
# operationId: ListFacetNames
export def "amazonclouddirectory-2017-01-11-facet-listx-amz-data-partition ListFacetNames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) to retrieve facet names from.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<FacetNames: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition
# operationId: ListIncomingTypedLinks
# --ObjectReference shape: {Selector?: any}
# --FilterAttributeRanges item shape: {AttributeName?: any, Range: any}
# --FilterTypedLink shape: {SchemaArn?: any, TypedLinkName?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-incomingx-amz-data-partition ListIncomingTypedLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --FilterAttributeRanges: list # Provides range filters for multiple attributes. When providing ranges to typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. — item shape: {AttributeName?: any, Range: any}
  --FilterTypedLink: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: any, TypedLinkName?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
  --ConsistencyLevel: string@ConsistencyLevel-completer # The consistency level to execute the request at.
]: any -> record<LinkSpecifiers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition")
  let body = {ObjectReference: $ObjectReference, FilterAttributeRanges: $FilterAttributeRanges, FilterTypedLink: $FilterTypedLink, NextToken: $NextToken, MaxResults: $MaxResults, ConsistencyLevel: $ConsistencyLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists objects attached to the specified index.
#
# POST /amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition
# operationId: ListIndex
# --RangesOnIndexedValues item shape: {AttributeKey?: any, Range?: any}
# --IndexReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-index-targetsx-amz-data-partition ListIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory that the index exists in.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # The consistency level to execute the request at.
  --RangesOnIndexedValues: list # Specifies the ranges of indexed values that you want to query. — item shape: {AttributeKey?: any, Range?: any}
  IndexReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --MaxResults: int # The maximum number of objects in a single page to retrieve from the index during a request. For more information, see <a href="http://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  --NextToken: string # The pagination token.
]: any -> record<IndexAttachments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition" $qp)
  let body = {RangesOnIndexedValues: $RangesOnIndexedValues, IndexReference: $IndexReference, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
#
# POST /amazonclouddirectory/2017-01-11/schema/managed
# operationId: ListManagedSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-managed ListManagedSchemaArns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --SchemaArn: string # The response for ListManagedSchemaArns. When this parameter is used, all minor version ARNs for a major version are listed.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/managed" $qp)
  let body = {SchemaArn: $SchemaArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all attributes that are associated with an object. 
#
# POST /amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition
# operationId: ListObjectAttributes
# --ObjectReference shape: {Selector?: any}
# --FacetFilter shape: {SchemaArn?: any, FacetName?: any}
export def "amazonclouddirectory-2017-01-11-object-attributesx-amz-data-partition ListObjectAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
  --FacetFilter: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
]: any -> record<Attributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition" $qp)
  let body = {ObjectReference: $ObjectReference, NextToken: $NextToken, MaxResults: $MaxResults, FacetFilter: $FacetFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of child objects that are associated with a given object.
#
# POST /amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition
# operationId: ListObjectChildren
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-childrenx-amz-data-partition ListObjectChildren" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<Children: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition" $qp)
  let body = {ObjectReference: $ObjectReference, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
#
# POST /amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition
# operationId: ListObjectParentPaths
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-parentpathsx-amz-data-partition ListObjectParentPaths" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory to which the parent path applies.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<PathToObjectIdentifiersList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition" $qp)
  let body = {ObjectReference: $ObjectReference, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists parent objects that are associated with a given object in pagination fashion.
#
# POST /amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition
# operationId: ListObjectParents
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-parentx-amz-data-partition ListObjectParents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
  --IncludeAllLinksToEachParent: string@bool-completer # When set to True, returns all <a>ListObjectParentsResponse$ParentLinks</a>. There could be multiple links between a parent-child pair.
]: any -> record<Parents: record, NextToken: record, ParentLinks: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition" $qp)
  let body = {ObjectReference: $ObjectReference, NextToken: $NextToken, MaxResults: $MaxResults, IncludeAllLinksToEachParent: $IncludeAllLinksToEachParent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns policies attached to an object in pagination fashion.
#
# POST /amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition
# operationId: ListObjectPolicies
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-policyx-amz-data-partition ListObjectPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<AttachedPolicyIds: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition" $qp)
  let body = {ObjectReference: $ObjectReference, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition
# operationId: ListOutgoingTypedLinks
# --ObjectReference shape: {Selector?: any}
# --FilterAttributeRanges item shape: {AttributeName?: any, Range: any}
# --FilterTypedLink shape: {SchemaArn?: any, TypedLinkName?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-outgoingx-amz-data-partition ListOutgoingTypedLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --FilterAttributeRanges: list # Provides range filters for multiple attributes. When providing ranges to typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. — item shape: {AttributeName?: any, Range: any}
  --FilterTypedLink: record # Identifies the schema Amazon Resource Name (ARN) and facet name for the typed link. — shape: {SchemaArn?: any, TypedLinkName?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
  --ConsistencyLevel: string@ConsistencyLevel-completer # The consistency level to execute the request at.
]: any -> record<TypedLinkSpecifiers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition")
  let body = {ObjectReference: $ObjectReference, FilterAttributeRanges: $FilterAttributeRanges, FilterTypedLink: $FilterTypedLink, NextToken: $NextToken, MaxResults: $MaxResults, ConsistencyLevel: $ConsistencyLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
#
# POST /amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition
# operationId: ListPolicyAttachments
# --PolicyReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-attachmentx-amz-data-partition ListPolicyAttachments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  --x-amz-consistency-level: string@x-amz-consistency-level-completer # Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  PolicyReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<ObjectIdentifiers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition" $qp)
  let body = {PolicyReference: $PolicyReference, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition, "x-amz-consistency-level": $x_amz_consistency_level} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
#
# POST /amazonclouddirectory/2017-01-11/schema/published
# operationId: ListPublishedSchemaArns
export def "amazonclouddirectory-2017-01-11-schema-published ListPublishedSchemaArns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --SchemaArn: string # The response for <code>ListPublishedSchemaArns</code> when this parameter is used will list all minor version ARNs for a major version.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<SchemaArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/published" $qp)
  let body = {SchemaArn: $SchemaArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
#
# POST /amazonclouddirectory/2017-01-11/tags
# operationId: ListTagsForResource
export def "amazonclouddirectory-2017-01-11-tags ListTagsForResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ResourceArn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  --NextToken: string # The pagination token. This is for future use. Currently pagination is not supported for tagging.
  --MaxResults: int # The <code>MaxResults</code> parameter sets the maximum number of results returned in a single page. This is for future use and is not supported currently.
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/tags" $qp)
  let body = {ResourceArn: $ResourceArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition
# operationId: ListTypedLinkFacetAttributes
export def "amazonclouddirectory-2017-01-11-typedlink-facet-attributesx-amz-data-partition ListTypedLinkFacetAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  Name: string # The unique name of the typed link facet.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<Attributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition" $qp)
  let body = {Name: $Name, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition
# operationId: ListTypedLinkFacetNames
export def "amazonclouddirectory-2017-01-11-typedlink-facet-listx-amz-data-partition ListTypedLinkFacetNames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  --NextToken: string # The pagination token.
  --MaxResults: int # The maximum number of results to retrieve.
]: any -> record<FacetNames: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
#
# POST /amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition
# operationId: LookupPolicy
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-policy-lookupx-amz-data-partition LookupPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  --NextToken: string # The token to request the next page of results.
  --MaxResults: int # The maximum number of items to be retrieved in a single call. This is an approximate number.
]: any -> record<PolicyToPathList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition" $qp)
  let body = {ObjectReference: $ObjectReference, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Publishes a development schema with a major version and a recommended minor version.
#
# PUT /amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition
# operationId: PublishSchema
export def "amazonclouddirectory-2017-01-11-schema-publishx-amz-data-partition PublishSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the development schema. For more information, see <a>arns</a>.
  Version: string # The major version under which the schema will be published. Schemas have both a major and minor version associated with them.
  --MinorVersion: string # The minor version under which the schema will be published. This parameter is recommended. Schemas have both a major and minor version associated with them.
  --Name: string # The new name under which the schema will be published. If this is not provided, the development schema is considered.
]: any -> record<PublishedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition")
  let body = {Version: $Version, MinorVersion: $MinorVersion, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes the specified facet from the specified object.
#
# PUT /amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition
# operationId: RemoveFacetFromObject
# --SchemaFacet shape: {SchemaArn?: any, FacetName?: any}
# --ObjectReference shape: {Selector?: any}
export def "amazonclouddirectory-2017-01-11-object-facets-deletex-amz-data-partition RemoveFacetFromObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The ARN of the directory in which the object resides.
  SchemaFacet: record # A facet. — shape: {SchemaArn?: any, FacetName?: any}
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition")
  let body = {SchemaFacet: $SchemaFacet, ObjectReference: $ObjectReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# An API operation for adding tags to a resource.
#
# PUT /amazonclouddirectory/2017-01-11/tags/add
# operationId: TagResource
# --Tags item shape: {Key?: any, Value?: any}
export def "amazonclouddirectory-2017-01-11-tags-add TagResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ResourceArn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  Tags: list # A list of tag key-value pairs. — item shape: {Key?: any, Value?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/tags/add")
  let body = {ResourceArn: $ResourceArn, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# An API operation for removing tags from a resource.
#
# PUT /amazonclouddirectory/2017-01-11/tags/remove
# operationId: UntagResource
export def "amazonclouddirectory-2017-01-11-tags-remove UntagResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  ResourceArn: string # The Amazon Resource Name (ARN) of the resource. Tagging is only supported for directories.
  TagKeys: list # Keys of the tag that need to be removed from the resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/tags/remove")
  let body = {ResourceArn: $ResourceArn, TagKeys: $TagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
#
# POST /amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition
# operationId: UpdateLinkAttributes
# --TypedLinkSpecifier shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
# --AttributeUpdates item shape: {AttributeKey?: any, AttributeAction?: any}
export def "amazonclouddirectory-2017-01-11-typedlink-attributes-updatex-amz-data-partition UpdateLinkAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see <a>arns</a> or <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  TypedLinkSpecifier: record # Contains all the information that is used to uniquely identify a typed link. The parameters discussed in this topic are used to uniquely specify the typed link being operated on. The <a>AttachTypedLink</a> API returns a typed link specifier while the <a>DetachTypedLink</a> API accepts one as input. Similarly, the <a>ListIncomingTypedLinks</a> and <a>ListOutgoingTypedLinks</a> API operations provide typed link specifiers as output. You can also construct a typed link specifier from scratch. — shape: {TypedLinkFacet?: any, SourceObjectReference?: any, TargetObjectReference?: any, IdentityAttributeValues?: any}
  AttributeUpdates: list # The attributes update structure. — item shape: {AttributeKey?: any, AttributeAction?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition")
  let body = {TypedLinkSpecifier: $TypedLinkSpecifier, AttributeUpdates: $AttributeUpdates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a given object's attributes.
#
# PUT /amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition
# operationId: UpdateObjectAttributes
# --ObjectReference shape: {Selector?: any}
# --AttributeUpdates item shape: {ObjectAttributeKey?: any, ObjectAttributeAction?: any}
export def "amazonclouddirectory-2017-01-11-object-updatex-amz-data-partition UpdateObjectAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ObjectReference: record # The reference that identifies an object. — shape: {Selector?: any}
  AttributeUpdates: list # The attributes update structure. — item shape: {ObjectAttributeKey?: any, ObjectAttributeAction?: any}
]: any -> record<ObjectIdentifier: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition")
  let body = {ObjectReference: $ObjectReference, AttributeUpdates: $AttributeUpdates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the schema name with a new name. Only development schema names can be updated.
#
# PUT /amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition
# operationId: UpdateSchema
export def "amazonclouddirectory-2017-01-11-schema-updatex-amz-data-partition UpdateSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  Name: string # The name of the schema.
]: any -> record<SchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
#
# PUT /amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition
# operationId: UpdateTypedLinkFacet
# --AttributeUpdates item shape: {Attribute: any, Action: any}
export def "amazonclouddirectory-2017-01-11-typedlink-facetx-amz-data-partition UpdateTypedLinkFacet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --x-amz-data-partition: string # The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  Name: string # The unique name of the typed link facet.
  AttributeUpdates: list # Attributes update structure. — item shape: {Attribute: any, Action: any}
  IdentityAttributeOrder: list # The order of identity attributes for the facet, from most significant to least significant. The ability to filter typed links considers the order that the attributes are defined on the typed link facet. When providing ranges to a typed link selection, any inexact ranges must be specified at the end. Any attributes that do not have a range specified are presumed to match the entire range. Filters are interpreted in the order of the attributes on the typed link facet, not the order in which they are supplied to any API calls. For more information about identity attributes, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition")
  let body = {Name: $Name, AttributeUpdates: $AttributeUpdates, IdentityAttributeOrder: $IdentityAttributeOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "x-amz-data-partition": $x_amz_data_partition} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
#
# PUT /amazonclouddirectory/2017-01-11/schema/upgradeapplied
# operationId: UpgradeAppliedSchema
export def "amazonclouddirectory-2017-01-11-schema-upgradeapplied UpgradeAppliedSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  PublishedSchemaArn: string # The revision of the published schema to upgrade the directory to.
  DirectoryArn: string # The ARN for the directory to which the upgraded schema will be applied.
  --DryRun: string@bool-completer # Used for testing whether the major version schemas are backward compatible or not. If schema compatibility fails, an exception would be thrown else the call would succeed but no changes will be saved. This parameter is optional.
]: any -> record<UpgradedSchemaArn: record, DirectoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/upgradeapplied")
  let body = {PublishedSchemaArn: $PublishedSchemaArn, DirectoryArn: $DirectoryArn, DryRun: $DryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
#
# PUT /amazonclouddirectory/2017-01-11/schema/upgradepublished
# operationId: UpgradePublishedSchema
export def "amazonclouddirectory-2017-01-11-schema-upgradepublished UpgradePublishedSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  DevelopmentSchemaArn: string # The ARN of the development schema with the changes used for the upgrade.
  PublishedSchemaArn: string # The ARN of the published schema to be upgraded.
  MinorVersion: string # Identifies the minor version of the published schema that will be created. This parameter is NOT optional.
  --DryRun: string@bool-completer # Used for testing whether the Development schema provided is backwards compatible, or not, with the publish schema provided by the user to be upgraded. If schema compatibility fails, an exception would be thrown else the call would succeed. This parameter is optional and defaults to false.
]: any -> record<UpgradedSchemaArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/amazonclouddirectory/2017-01-11/schema/upgradepublished")
  let body = {DevelopmentSchemaArn: $DevelopmentSchemaArn, PublishedSchemaArn: $PublishedSchemaArn, MinorVersion: $MinorVersion, DryRun: $DryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
