# Auto-generated client for Amazon SimpleDB v2009-04-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sdb/2009-04-15/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLEDB_TOKEN

const BASE_URL = "http://sdb.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SIMPLEDB_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://sdb.amazonaws.com" "https://sdb.amazonaws.com" "http://sdb.us-east-2.amazonaws.com" "http://sdb.us-west-1.amazonaws.com" "http://sdb.us-west-2.amazonaws.com" "http://sdb.us-gov-west-1.amazonaws.com" "http://sdb.us-gov-east-1.amazonaws.com" "http://sdb.ca-central-1.amazonaws.com" "http://sdb.eu-north-1.amazonaws.com" "http://sdb.eu-west-1.amazonaws.com" "http://sdb.eu-west-2.amazonaws.com" "http://sdb.eu-west-3.amazonaws.com" "http://sdb.eu-central-1.amazonaws.com" "http://sdb.eu-south-1.amazonaws.com" "http://sdb.af-south-1.amazonaws.com" "http://sdb.ap-northeast-1.amazonaws.com" "http://sdb.ap-northeast-2.amazonaws.com" "http://sdb.ap-northeast-3.amazonaws.com" "http://sdb.ap-southeast-1.amazonaws.com" "http://sdb.ap-southeast-2.amazonaws.com" "http://sdb.ap-east-1.amazonaws.com" "http://sdb.ap-south-1.amazonaws.com" "http://sdb.sa-east-1.amazonaws.com" "http://sdb.me-south-1.amazonaws.com" "https://sdb.us-east-2.amazonaws.com" "https://sdb.us-west-1.amazonaws.com" "https://sdb.us-west-2.amazonaws.com" "https://sdb.us-gov-west-1.amazonaws.com" "https://sdb.us-gov-east-1.amazonaws.com" "https://sdb.ca-central-1.amazonaws.com" "https://sdb.eu-north-1.amazonaws.com" "https://sdb.eu-west-1.amazonaws.com" "https://sdb.eu-west-2.amazonaws.com" "https://sdb.eu-west-3.amazonaws.com" "https://sdb.eu-central-1.amazonaws.com" "https://sdb.eu-south-1.amazonaws.com" "https://sdb.af-south-1.amazonaws.com" "https://sdb.ap-northeast-1.amazonaws.com" "https://sdb.ap-northeast-2.amazonaws.com" "https://sdb.ap-northeast-3.amazonaws.com" "https://sdb.ap-southeast-1.amazonaws.com" "https://sdb.ap-southeast-2.amazonaws.com" "https://sdb.ap-east-1.amazonaws.com" "https://sdb.ap-south-1.amazonaws.com" "https://sdb.sa-east-1.amazonaws.com" "https://sdb.me-south-1.amazonaws.com" "http://sdb.cn-north-1.amazonaws.com.cn" "http://sdb.cn-northwest-1.amazonaws.com.cn" "https://sdb.cn-north-1.amazonaws.com.cn" "https://sdb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["BatchDeleteAttributes"] }
def version-completer [] { ["2009-04-15"] }
def action-completer-1 [] { ["BatchPutAttributes"] }
def action-completer-2 [] { ["CreateDomain"] }
def action-completer-3 [] { ["DeleteAttributes"] }
def action-completer-4 [] { ["DeleteDomain"] }
def action-completer-5 [] { ["DomainMetadata"] }
def action-completer-6 [] { ["GetAttributes"] }
def action-completer-7 [] { ["ListDomains"] }
def action-completer-8 [] { ["PutAttributes"] }
def action-completer-9 [] { ["Select"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api get-batch-delete-attributes" } } | get name | first)
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

# Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. The following limitations are enforced for this operation: 1 MB request size 25 item limit per BatchDeleteAttributes operation
#
# GET /
# operationId: GET_BatchDeleteAttributes
export def "api get-batch-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain in which the attributes are being deleted.
  --items: list # A list of items on which to perform the operation.
  --action-2: string@action-completer #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "Items" $items "multi") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "Items": $items, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. The following limitations are enforced for this operation: 1 MB request size 25 item limit per BatchDeleteAttributes operation
#
# POST /
# operationId: POST_BatchDeleteAttributes
export def "api create-batch-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# The BatchPutAttributes operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple PutAttribute operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. The client may specify the item name with the Item.X.ItemName parameter. The client may specify new attributes using a combination of the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value parameters. The client may specify the first attribute for the first item using the parameters Item.0.Attribute.0.Name and Item.0.Attribute.0.Value, and for the second attribute for the first item by the parameters Item.0.Attribute.1.Name and Item.0.Attribute.1.Value, and so on. Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", "second_value" }. However, it cannot have two attribute instances where both the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value are the same. Optionally, the requester can supply the Replace parameter for each individual value. Setting this value to true will cause the new attribute values to replace the existing attribute values. For example, if an item I has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requester does a BatchPutAttributes of {'I', 'b', '4' } with the Replace parameter set to true, the final attributes of the item will be { 'a', '1' } and { 'b', '4' }, replacing the previous values of the 'b' attribute with the new value. You cannot specify an empty string as an item or as an attribute name. The BatchPutAttributes operation succeeds or fails in its entirety. There are no partial puts. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. You can execute multiple BatchPutAttributes operations and other operations in parallel. However, large numbers of concurrent BatchPutAttributes calls can result in Service Unavailable (503) responses. The following limitations are enforced for this operation: 256 attribute name-value pairs per item 1 MB request size 1 billion attributes per domain 10 GB of total user data storage per domain 25 item limit per BatchPutAttributes operation
#
# GET /
# operationId: GET_BatchPutAttributes
export def "api get-batch-update-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain in which the attributes are being stored.
  --items: list # A list of items on which to perform the operation.
  --action-2: string@action-completer-1 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "Items" $items "multi") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "Items": $items, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# The BatchPutAttributes operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple PutAttribute operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. The client may specify the item name with the Item.X.ItemName parameter. The client may specify new attributes using a combination of the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value parameters. The client may specify the first attribute for the first item using the parameters Item.0.Attribute.0.Name and Item.0.Attribute.0.Value, and for the second attribute for the first item by the parameters Item.0.Attribute.1.Name and Item.0.Attribute.1.Value, and so on. Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", "second_value" }. However, it cannot have two attribute instances where both the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value are the same. Optionally, the requester can supply the Replace parameter for each individual value. Setting this value to true will cause the new attribute values to replace the existing attribute values. For example, if an item I has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requester does a BatchPutAttributes of {'I', 'b', '4' } with the Replace parameter set to true, the final attributes of the item will be { 'a', '1' } and { 'b', '4' }, replacing the previous values of the 'b' attribute with the new value. You cannot specify an empty string as an item or as an attribute name. The BatchPutAttributes operation succeeds or fails in its entirety. There are no partial puts. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. You can execute multiple BatchPutAttributes operations and other operations in parallel. However, large numbers of concurrent BatchPutAttributes calls can result in Service Unavailable (503) responses. The following limitations are enforced for this operation: 256 attribute name-value pairs per item 1 MB request size 1 billion attributes per domain 10 GB of total user data storage per domain 25 item limit per BatchPutAttributes operation
#
# POST /
# operationId: POST_BatchPutAttributes
export def "api create-batch-update-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-1 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# The CreateDomain operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The CreateDomain operation may take 10 or more seconds to complete. CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. The client can create up to 100 domains per account. If the client requires additional domains, go to http://aws.amazon.com/contact-us/simpledb-limit-request/ (http://aws.amazon.com/contact-us/simpledb-limit-request/).
#
# GET /
# operationId: GET_CreateDomain
export def "api get-create-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  --action-2: string@action-completer-2 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# The CreateDomain operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The CreateDomain operation may take 10 or more seconds to complete. CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. The client can create up to 100 domains per account. If the client requires additional domains, go to http://aws.amazon.com/contact-us/simpledb-limit-request/ (http://aws.amazon.com/contact-us/simpledb-limit-request/).
#
# POST /
# operationId: POST_CreateDomain
export def "api create-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-2 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. If DeleteAttributes is called without being passed any attributes or values specified, all the attributes for the item are deleted. DeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a GetAttributes or Select operation (read) immediately after a DeleteAttributes or PutAttributes operation (write) might not return updated item data.
#
# GET /
# operationId: GET_DeleteAttributes
export def "api get-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain in which to perform the operation.
  --item-name: string # The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  --attributes: list # A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  --expected: record # The update condition which, if specified, determines whether the specified attributes will be deleted or not. The update condition must be satisfied in order for this request to be processed and the attributes to be deleted.
  --action-2: string@action-completer-3 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "ItemName" $item_name "scalar") (serialize-qp "Attributes" $attributes "multi") (serialize-qp "Expected" $expected "multi") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "ItemName": $item_name, "Attributes": $attributes, "Expected": $expected, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. If DeleteAttributes is called without being passed any attributes or values specified, all the attributes for the item are deleted. DeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a GetAttributes or Select operation (read) immediately after a DeleteAttributes or PutAttributes operation (write) might not return updated item data.
#
# POST /
# operationId: POST_DeleteAttributes
export def "api create-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-3 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# The DeleteDomain operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The DeleteDomain operation might take 10 or more seconds to complete. Running DeleteDomain on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response.
#
# GET /
# operationId: GET_DeleteDomain
export def "api get-delete-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain to delete.
  --action-2: string@action-completer-4 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# The DeleteDomain operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The DeleteDomain operation might take 10 or more seconds to complete. Running DeleteDomain on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response.
#
# POST /
# operationId: POST_DeleteDomain
export def "api create-delete-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-4 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values.
#
# GET /
# operationId: GET_DomainMetadata
export def "api get-domain-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain for which to display the metadata of.
  --action-2: string@action-completer-5 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<ItemCount: record, ItemNamesSizeBytes: record, AttributeNameCount: record, AttributeNamesSizeBytes: record, AttributeValueCount: record, AttributeValuesSizeBytes: record, Timestamp: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values.
#
# POST /
# operationId: POST_DomainMetadata
export def "api create-domain-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-5 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<ItemCount: record, ItemNamesSizeBytes: record, AttributeNameCount: record, AttributeNamesSizeBytes: record, AttributeValueCount: record, AttributeValuesSizeBytes: record, Timestamp: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned.
#
# GET /
# operationId: GET_GetAttributes
export def "api get-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain in which to perform the operation.
  --item-name: string # The name of the item.
  --attribute-names: list # The names of the attributes.
  --consistent-read: oneof<nothing, bool> # Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If true, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  --action-2: string@action-completer-6 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<Attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "ItemName" $item_name "scalar") (serialize-qp "AttributeNames" $attribute_names "multi") (serialize-qp "ConsistentRead" $consistent_read "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "ItemName": $item_name, "AttributeNames": $attribute_names, "ConsistentRead": $consistent_read, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned.
#
# POST /
# operationId: POST_GetAttributes
export def "api create-get-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-6 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<Attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# The ListDomains operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by MaxNumberOfDomains (#MaxNumberOfDomains). A NextToken (#NextToken) is returned if there are more than MaxNumberOfDomains domains. Calling ListDomains successive times with the NextToken provided by the operation returns up to MaxNumberOfDomains more domain names with each successive operation call.
#
# GET /
# operationId: GET_ListDomains
export def "api get-list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --max-number-of-domains: int # The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  --next-token: string # A string informing Amazon SimpleDB where to start the next list of domain names.
  --action-2: string@action-completer-7 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<DomainNames: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "MaxNumberOfDomains" $max_number_of_domains "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "MaxNumberOfDomains": $max_number_of_domains, "NextToken": $next_token, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# The ListDomains operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by MaxNumberOfDomains (#MaxNumberOfDomains). A NextToken (#NextToken) is returned if there are more than MaxNumberOfDomains domains. Calling ListDomains successive times with the NextToken provided by the operation returns up to MaxNumberOfDomains more domain names with each successive operation call.
#
# POST /
# operationId: POST_ListDomains
export def "api create-list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --max-number-of-domains: string # Pagination limit
  --next-token: string # Pagination token
  --action-2: string@action-completer-7 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<DomainNames: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "MaxNumberOfDomains" $max_number_of_domains "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "MaxNumberOfDomains": $max_number_of_domains, "NextToken": $next_token, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the Attribute.X.Name and Attribute.X.Value parameters. The client specifies the first attribute by the parameters Attribute.0.Name and Attribute.0.Value, the second attribute by the parameters Attribute.1.Name and Attribute.1.Value, and so on. Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", second_value" }. However, it cannot have two attribute instances where both the Attribute.X.Name and Attribute.X.Value are the same. Optionally, the requestor can supply the Replace parameter for each individual attribute. Setting this value to true causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requestor calls PutAttributes using the attributes { 'b', '4' } with the Replace parameter set to true, the final attributes of the item are changed to { 'a', '1' } and { 'b', '4' }, which replaces the previous values of the 'b' attribute with the new value. Using PutAttributes to replace attribute values that do not exist will not result in an error response. You cannot specify an empty string as an attribute name. Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate GetAttributes or Select operation (read) immediately after a PutAttributes or DeleteAttributes operation (write) might not return the updated data. The following limitations are enforced for this operation: 256 total attribute name-value pairs per item One billion attributes per domain 10 GB of total user data storage per domain
#
# GET /
# operationId: GET_PutAttributes
export def "api get-update-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --domain-name: string # The name of the domain in which to perform the operation.
  --item-name: string # The name of the item.
  --attributes: list # The list of attributes.
  --expected: record # The update condition which, if specified, determines whether the specified attributes will be updated or not. The update condition must be satisfied in order for this request to be processed and the attributes to be updated.
  --action-2: string@action-completer-8 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "DomainName" $domain_name "scalar") (serialize-qp "ItemName" $item_name "scalar") (serialize-qp "Attributes" $attributes "multi") (serialize-qp "Expected" $expected "multi") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "DomainName": $domain_name, "ItemName": $item_name, "Attributes": $attributes, "Expected": $expected, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the Attribute.X.Name and Attribute.X.Value parameters. The client specifies the first attribute by the parameters Attribute.0.Name and Attribute.0.Value, the second attribute by the parameters Attribute.1.Name and Attribute.1.Value, and so on. Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", second_value" }. However, it cannot have two attribute instances where both the Attribute.X.Name and Attribute.X.Value are the same. Optionally, the requestor can supply the Replace parameter for each individual attribute. Setting this value to true causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requestor calls PutAttributes using the attributes { 'b', '4' } with the Replace parameter set to true, the final attributes of the item are changed to { 'a', '1' } and { 'b', '4' }, which replaces the previous values of the 'b' attribute with the new value. Using PutAttributes to replace attribute values that do not exist will not result in an error response. You cannot specify an empty string as an attribute name. Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate GetAttributes or Select operation (read) immediately after a PutAttributes or DeleteAttributes operation (write) might not return the updated data. The following limitations are enforced for this operation: 256 total attribute name-value pairs per item One billion attributes per domain 10 GB of total user data storage per domain
#
# POST /
# operationId: POST_PutAttributes
export def "api create-update-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --action-2: string@action-completer-8 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}

# The Select operation returns a set of attributes for ItemNames that match the select expression. Select is similar to the standard SQL SELECT statement. The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate NextToken so the client can access the next page of results. For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide.
#
# GET /
# operationId: GET_Select
export def "api get-select" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --select-expression: string # The expression used to query the domain.
  --next-token: string # A string informing Amazon SimpleDB where to start the next list of ItemNames.
  --consistent-read: oneof<nothing, bool> # Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If true, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  --action-2: string@action-completer-9 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "SelectExpression" $select_expression "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "ConsistentRead" $consistent_read "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "SelectExpression": $select_expression, "NextToken": $next_token, "ConsistentRead": $consistent_read, "Action": $action_2, "Version": $version_2} | compact), body: null}
}

# The Select operation returns a set of attributes for ItemNames that match the select expression. Select is similar to the standard SQL SELECT statement. The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate NextToken so the client can access the next page of results. For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide.
#
# POST /
# operationId: POST_Select
export def "api create-select" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string
  --action: string
  --signature-method: string
  --signature-version: string
  --timestamp: string
  --version: string
  --signature: string
  --next-token: string # Pagination token
  --action-2: string@action-completer-9 #  (disambiguated-2)
  --version-2: string@version-completer #  (disambiguated-2)
  --body: any
]: any -> record<Items: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $aws_access_key_id "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "SignatureMethod" $signature_method "scalar") (serialize-qp "SignatureVersion" $signature_version "scalar") (serialize-qp "Timestamp" $timestamp "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Signature" $signature "scalar") (serialize-qp "NextToken" $next_token "scalar") (serialize-qp "Action" $action_2 "scalar") (serialize-qp "Version" $version_2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/xml" $req_body {query: ({"AWSAccessKeyId": $aws_access_key_id, "Action": $action, "SignatureMethod": $signature_method, "SignatureVersion": $signature_version, "Timestamp": $timestamp, "Version": $version, "Signature": $signature, "NextToken": $next_token, "Action": $action_2, "Version": $version_2} | compact), body: $req_body}
}
