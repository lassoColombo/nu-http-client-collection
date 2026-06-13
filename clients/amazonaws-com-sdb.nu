# Auto-generated client for Amazon SimpleDB v2009-04-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sdb/2009-04-15/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLEDB_TOKEN

const BASE_URL = "http://sdb.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SIMPLEDB_TOKEN | default "" }
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

def base-url-completer [] { ["http://sdb.amazonaws.com" "https://sdb.amazonaws.com" "http://sdb.us-east-2.amazonaws.com" "http://sdb.us-west-1.amazonaws.com" "http://sdb.us-west-2.amazonaws.com" "http://sdb.us-gov-west-1.amazonaws.com" "http://sdb.us-gov-east-1.amazonaws.com" "http://sdb.ca-central-1.amazonaws.com" "http://sdb.eu-north-1.amazonaws.com" "http://sdb.eu-west-1.amazonaws.com" "http://sdb.eu-west-2.amazonaws.com" "http://sdb.eu-west-3.amazonaws.com" "http://sdb.eu-central-1.amazonaws.com" "http://sdb.eu-south-1.amazonaws.com" "http://sdb.af-south-1.amazonaws.com" "http://sdb.ap-northeast-1.amazonaws.com" "http://sdb.ap-northeast-2.amazonaws.com" "http://sdb.ap-northeast-3.amazonaws.com" "http://sdb.ap-southeast-1.amazonaws.com" "http://sdb.ap-southeast-2.amazonaws.com" "http://sdb.ap-east-1.amazonaws.com" "http://sdb.ap-south-1.amazonaws.com" "http://sdb.sa-east-1.amazonaws.com" "http://sdb.me-south-1.amazonaws.com" "https://sdb.us-east-2.amazonaws.com" "https://sdb.us-west-1.amazonaws.com" "https://sdb.us-west-2.amazonaws.com" "https://sdb.us-gov-west-1.amazonaws.com" "https://sdb.us-gov-east-1.amazonaws.com" "https://sdb.ca-central-1.amazonaws.com" "https://sdb.eu-north-1.amazonaws.com" "https://sdb.eu-west-1.amazonaws.com" "https://sdb.eu-west-2.amazonaws.com" "https://sdb.eu-west-3.amazonaws.com" "https://sdb.eu-central-1.amazonaws.com" "https://sdb.eu-south-1.amazonaws.com" "https://sdb.af-south-1.amazonaws.com" "https://sdb.ap-northeast-1.amazonaws.com" "https://sdb.ap-northeast-2.amazonaws.com" "https://sdb.ap-northeast-3.amazonaws.com" "https://sdb.ap-southeast-1.amazonaws.com" "https://sdb.ap-southeast-2.amazonaws.com" "https://sdb.ap-east-1.amazonaws.com" "https://sdb.ap-south-1.amazonaws.com" "https://sdb.sa-east-1.amazonaws.com" "https://sdb.me-south-1.amazonaws.com" "http://sdb.cn-north-1.amazonaws.com.cn" "http://sdb.cn-northwest-1.amazonaws.com.cn" "https://sdb.cn-north-1.amazonaws.com.cn" "https://sdb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Action-completer [] { ["BatchDeleteAttributes"] }
def Version-completer [] { ["2009-04-15"] }
def Action-completer-1 [] { ["BatchPutAttributes"] }
def Action-completer-2 [] { ["CreateDomain"] }
def Action-completer-3 [] { ["DeleteAttributes"] }
def Action-completer-4 [] { ["DeleteDomain"] }
def Action-completer-5 [] { ["DomainMetadata"] }
def Action-completer-6 [] { ["GetAttributes"] }
def Action-completer-7 [] { ["ListDomains"] }
def Action-completer-8 [] { ["PutAttributes"] }
def Action-completer-9 [] { ["Select"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "action-batch-delete-attributes BatchDeleteAttributes" } } | get name | first)
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

# <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
#
# GET /#Action=BatchDeleteAttributes
# operationId: GET_BatchDeleteAttributes
export def "action-batch-delete-attributes BatchDeleteAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain in which the attributes are being deleted.
  --Items: list # A list of items on which to perform the operation.
  --Action: string@Action-completer
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "Items" $Items "multi") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=BatchDeleteAttributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. </p> <note> <p> If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. </p> <p> BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. </p> <p> The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. </p> <p> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. </p> <p> This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. </p> </note> <p> The following limitations are enforced for this operation: <ul> <li>1 MB request size</li> <li>25 item limit per BatchDeleteAttributes operation</li> </ul> </p>
#
# POST /#Action=BatchDeleteAttributes
# operationId: POST_BatchDeleteAttributes
export def "action-batch-delete-attributes BatchDeleteAttributes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=BatchDeleteAttributes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
#
# GET /#Action=BatchPutAttributes
# operationId: GET_BatchPutAttributes
export def "action-batch-put-attributes BatchPutAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain in which the attributes are being stored.
  --Items: list # A list of items on which to perform the operation.
  --Action: string@Action-completer-1
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "Items" $Items "multi") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=BatchPutAttributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> The <code>BatchPutAttributes</code> operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple <a>PutAttribute</a> operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. </p> <p> The client may specify the item name with the <code>Item.X.ItemName</code> parameter. The client may specify new attributes using a combination of the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> parameters. The client may specify the first attribute for the first item using the parameters <code>Item.0.Attribute.0.Name</code> and <code>Item.0.Attribute.0.Value</code>, and for the second attribute for the first item by the parameters <code>Item.0.Attribute.1.Name</code> and <code>Item.0.Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", "second_value" }</code>. However, it cannot have two attribute instances where both the <code>Item.X.Attribute.Y.Name</code> and <code>Item.X.Attribute.Y.Value</code> are the same. </p> <p> Optionally, the requester can supply the <code>Replace</code> parameter for each individual value. Setting this value to <code>true</code> will cause the new attribute values to replace the existing attribute values. For example, if an item <code>I</code> has the attributes <code>{ 'a', '1' }, { 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requester does a BatchPutAttributes of <code>{'I', 'b', '4' }</code> with the Replace parameter set to true, the final attributes of the item will be <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, replacing the previous values of the 'b' attribute with the new value. </p> <note> You cannot specify an empty string as an item or as an attribute name. The <code>BatchPutAttributes</code> operation succeeds or fails in its entirety. There are no partial puts. </note> <important> This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using <code>Expected.X.Name</code>, <code>Expected.X.Value</code>, or <code>Expected.X.Exists</code>. </important> <p> You can execute multiple <code>BatchPutAttributes</code> operations and other operations in parallel. However, large numbers of concurrent <code>BatchPutAttributes</code> calls can result in Service Unavailable (503) responses. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 attribute name-value pairs per item</li> <li>1 MB request size</li> <li>1 billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> <li>25 item limit per <code>BatchPutAttributes</code> operation</li> </ul> </p>
#
# POST /#Action=BatchPutAttributes
# operationId: POST_BatchPutAttributes
export def "action-batch-put-attributes BatchPutAttributes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-1
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=BatchPutAttributes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
#
# GET /#Action=CreateDomain
# operationId: GET_CreateDomain
export def "action-create-domain CreateDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'.
  --Action: string@Action-completer-2
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=CreateDomain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> The <code>CreateDomain</code> operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The <code>CreateDomain</code> operation may take 10 or more seconds to complete. </p> <note> CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. </note> <p> The client can create up to 100 domains per account. </p> <p> If the client requires additional domains, go to <a href="http://aws.amazon.com/contact-us/simpledb-limit-request/"> http://aws.amazon.com/contact-us/simpledb-limit-request/</a>. </p>
#
# POST /#Action=CreateDomain
# operationId: POST_CreateDomain
export def "action-create-domain CreateDomain-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-2
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=CreateDomain" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
#
# GET /#Action=DeleteAttributes
# operationId: GET_DeleteAttributes
export def "action-delete-attributes DeleteAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain in which to perform the operation.
  --ItemName: string # The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs.
  --Attributes: list # A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  --Expected: record # The update condition which, if specified, determines whether the specified attributes will be deleted or not. The update condition must be satisfied in order for this request to be processed and the attributes to be deleted.
  --Action: string@Action-completer-3
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "ItemName" $ItemName "scalar") (serialize-qp "Attributes" $Attributes "multi") (serialize-qp "Expected" $Expected "multi") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=DeleteAttributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. </p> <note> If <code>DeleteAttributes</code> is called without being passed any attributes or values specified, all the attributes for the item are deleted. </note> <p> <code>DeleteAttributes</code> is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. </p> <p> Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <code>DeleteAttributes</code> or <a>PutAttributes</a> operation (write) might not return updated item data. </p>
#
# POST /#Action=DeleteAttributes
# operationId: POST_DeleteAttributes
export def "action-delete-attributes DeleteAttributes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-3
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=DeleteAttributes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
#
# GET /#Action=DeleteDomain
# operationId: GET_DeleteDomain
export def "action-delete-domain DeleteDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain to delete.
  --Action: string@Action-completer-4
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=DeleteDomain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> The <code>DeleteDomain</code> operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The <code>DeleteDomain</code> operation might take 10 or more seconds to complete. </p> <note> Running <code>DeleteDomain</code> on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response. </note>
#
# POST /#Action=DeleteDomain
# operationId: POST_DeleteDomain
export def "action-delete-domain DeleteDomain-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-4
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=DeleteDomain" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

#  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
#
# GET /#Action=DomainMetadata
# operationId: GET_DomainMetadata
export def "action-domain-metadata DomainMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain for which to display the metadata of.
  --Action: string@Action-completer-5
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=DomainMetadata" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values. 
#
# POST /#Action=DomainMetadata
# operationId: POST_DomainMetadata
export def "action-domain-metadata DomainMetadata-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-5
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=DomainMetadata" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
#
# GET /#Action=GetAttributes
# operationId: GET_GetAttributes
export def "action-get-attributes GetAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain in which to perform the operation.
  --ItemName: string # The name of the item.
  --AttributeNames: list # The names of the attributes.
  --ConsistentRead: oneof<nothing, bool> # Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  --Action: string@Action-completer-6
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "ItemName" $ItemName "scalar") (serialize-qp "AttributeNames" $AttributeNames "multi") (serialize-qp "ConsistentRead" $ConsistentRead "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=GetAttributes" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. </p> <p> If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. </p> <note> If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned. </note>
#
# POST /#Action=GetAttributes
# operationId: POST_GetAttributes
export def "action-get-attributes GetAttributes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-6
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=GetAttributes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

#  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
#
# GET /#Action=ListDomains
# operationId: GET_ListDomains
export def "action-list-domains ListDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --MaxNumberOfDomains: int # The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  --NextToken: string # A string informing Amazon SimpleDB where to start the next list of domain names.
  --Action: string@Action-completer-7
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "MaxNumberOfDomains" $MaxNumberOfDomains "scalar") (serialize-qp "NextToken" $NextToken "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=ListDomains" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  The <code>ListDomains</code> operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by <a href="#MaxNumberOfDomains">MaxNumberOfDomains</a>. A <a href="#NextToken">NextToken</a> is returned if there are more than <code>MaxNumberOfDomains</code> domains. Calling <code>ListDomains</code> successive times with the <code>NextToken</code> provided by the operation returns up to <code>MaxNumberOfDomains</code> more domain names with each successive operation call. 
#
# POST /#Action=ListDomains
# operationId: POST_ListDomains
export def "action-list-domains ListDomains-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --MaxNumberOfDomains: string # Pagination limit
  --NextToken: string # Pagination token
  --Action: string@Action-completer-7
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "MaxNumberOfDomains" $MaxNumberOfDomains "scalar") (serialize-qp "NextToken" $NextToken "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=ListDomains" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
#
# GET /#Action=PutAttributes
# operationId: GET_PutAttributes
export def "action-put-attributes PutAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --DomainName: string # The name of the domain in which to perform the operation.
  --ItemName: string # The name of the item.
  --Attributes: list # The list of attributes.
  --Expected: record # The update condition which, if specified, determines whether the specified attributes will be updated or not. The update condition must be satisfied in order for this request to be processed and the attributes to be updated.
  --Action: string@Action-completer-8
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "DomainName" $DomainName "scalar") (serialize-qp "ItemName" $ItemName "scalar") (serialize-qp "Attributes" $Attributes "multi") (serialize-qp "Expected" $Expected "multi") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=PutAttributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> parameters. The client specifies the first attribute by the parameters <code>Attribute.0.Name</code> and <code>Attribute.0.Value</code>, the second attribute by the parameters <code>Attribute.1.Name</code> and <code>Attribute.1.Value</code>, and so on. </p> <p> Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes <code>{ "first_name", "first_value" }</code> and <code>{ "first_name", second_value" }</code>. However, it cannot have two attribute instances where both the <code>Attribute.X.Name</code> and <code>Attribute.X.Value</code> are the same. </p> <p> Optionally, the requestor can supply the <code>Replace</code> parameter for each individual attribute. Setting this value to <code>true</code> causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes <code>{ 'a', '1' }</code>, <code>{ 'b', '2'}</code> and <code>{ 'b', '3' }</code> and the requestor calls <code>PutAttributes</code> using the attributes <code>{ 'b', '4' }</code> with the <code>Replace</code> parameter set to true, the final attributes of the item are changed to <code>{ 'a', '1' }</code> and <code>{ 'b', '4' }</code>, which replaces the previous values of the 'b' attribute with the new value. </p> <note> Using <code>PutAttributes</code> to replace attribute values that do not exist will not result in an error response. </note> <p> You cannot specify an empty string as an attribute name. </p> <p> Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate <a>GetAttributes</a> or <a>Select</a> operation (read) immediately after a <a>PutAttributes</a> or <a>DeleteAttributes</a> operation (write) might not return the updated data. </p> <p> The following limitations are enforced for this operation: <ul> <li>256 total attribute name-value pairs per item</li> <li>One billion attributes per domain</li> <li>10 GB of total user data storage per domain</li> </ul> </p>
#
# POST /#Action=PutAttributes
# operationId: POST_PutAttributes
export def "action-put-attributes PutAttributes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --Action: string@Action-completer-8
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=PutAttributes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
#
# GET /#Action=Select
# operationId: GET_Select
export def "action-select Select" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --SelectExpression: string # The expression used to query the domain.
  --NextToken: string # A string informing Amazon SimpleDB where to start the next list of <code>ItemNames</code>.
  --ConsistentRead: oneof<nothing, bool> # Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If <code>true</code>, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  --Action: string@Action-completer-9
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "SelectExpression" $SelectExpression "scalar") (serialize-qp "NextToken" $NextToken "scalar") (serialize-qp "ConsistentRead" $ConsistentRead "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=Select" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p> The <code>Select</code> operation returns a set of attributes for <code>ItemNames</code> that match the select expression. <code>Select</code> is similar to the standard SQL SELECT statement. </p> <p> The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate <code>NextToken</code> so the client can access the next page of results. </p> <p> For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide. </p>
#
# POST /#Action=Select
# operationId: POST_Select
export def "action-select Select-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AWSAccessKeyId: string
  --Action: string
  --SignatureMethod: string
  --SignatureVersion: string
  --Timestamp: string
  --Version: string
  --Signature: string
  --NextToken: string # Pagination token
  --Action: string@Action-completer-9
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "NextToken" $NextToken "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Action=Select" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}
