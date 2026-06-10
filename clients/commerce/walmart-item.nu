# Auto-generated client for Item API v3.0.1
# Source: https://api.apis.guru/v2/specs/walmart.com/item/3.0.1/swagger.json
# Auth: --token flag or $env.ITEM_API_TOKEN

const BASE_URL = "https://developer.walmart.com/proxy/item-api-doc-app/rest"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ITEM_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://developer.walmart.com/proxy/item-api-doc-app/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def WM-CONSUMERCHANNELTYPE-completer [] { ["SWAGGER_CHANNEL_TYPE"] }
def feedType-completer [] { ["item"] }
def feedType-completer-1 [] { ["CONTENT_PRODUCT" "SUPPLIER_FULL_ITEM" "item"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "feeds v2getFeedItemStatus" } } | get name | first)
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

# Get status of an item feed
#
# GET /v2/feeds
# operationId: v2getFeedItemStatus
export def "feeds v2getFeedItemStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedId: string # The feed ID.
  --includeDetails: string # Includes the status details for each item in the feed. Do not set this parameter to true as discrepancies may appear between the header and the item details (the item details may be incorrect). Instead, use the Get a feedItems status. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of items to be returned. Cannot be more than 50 items. Use it only when the includeDetails is set to true. (default: 50)
  --WM-CONSUMERCHANNELTYPE: string@WM-CONSUMERCHANNELTYPE-completer # Channel Type
  --WM-CONSUMERID: string # Your Consumer ID
  --WM-SECTIMESTAMP: string # Epoch timestamp
  --WM-SECAUTH-SIGNATURE: string # Authentication signature
  --WM-SVCNAME: string # The Service name
  --WM-QOSCORRELATION-ID: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedId" $feedId "scalar") (serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feeds" $qp)
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $WM_CONSUMERCHANNELTYPE, "WM_CONSUMER.ID": $WM_CONSUMERID, "WM_SEC.TIMESTAMP": $WM_SECTIMESTAMP, "WM_SEC.AUTH_SIGNATURE": $WM_SECAUTH_SIGNATURE, "WM_SVC.NAME": $WM_SVCNAME, "WM_QOS.CORRELATION_ID": $WM_QOSCORRELATION_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload an item feed
#
# POST /v2/feeds
# operationId: v2doPostMultiPart
export def "feeds v2doPostMultiPart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedType: string@feedType-completer # Feed Type (default: item)
  --WM-CONSUMERCHANNELTYPE: string@WM-CONSUMERCHANNELTYPE-completer # Channel Type
  --WM-CONSUMERID: string # Your Consumer ID
  --WM-SECTIMESTAMP: string # Epoch timestamp
  --WM-SECAUTH-SIGNATURE: string # Authentication signature
  --WM-SVCNAME: string # The Service name
  --WM-QOSCORRELATION-ID: string # A Transaction ID
  file: path # Feed File to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedType" $feedType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feeds" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $WM_CONSUMERCHANNELTYPE, "WM_CONSUMER.ID": $WM_CONSUMERID, "WM_SEC.TIMESTAMP": $WM_SECTIMESTAMP, "WM_SEC.AUTH_SIGNATURE": $WM_SECAUTH_SIGNATURE, "WM_SVC.NAME": $WM_SVCNAME, "WM_QOS.CORRELATION_ID": $WM_QOSCORRELATION_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get status of an item within a feed
#
# GET /v2/feeds/{feedId}
# operationId: v2getAllItemsStatus
export def "feeds v2getAllItemsStatus" [
  feedId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeDetails: string # Includes details of each entity in the feed. Do not set this parameter to true. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of entities to be returned. It cannot be more than 50 entities. Use it only when the includeDetails is set to true. (default: 50)
  --WM-CONSUMERCHANNELTYPE: string@WM-CONSUMERCHANNELTYPE-completer # Channel Type
  --WM-CONSUMERID: string # Your Consumer ID
  --WM-SECTIMESTAMP: string # Epoch timestamp
  --WM-SECAUTH-SIGNATURE: string # Authentication signature
  --WM-SVCNAME: string # The Service name
  --WM-QOSCORRELATION-ID: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/feeds/($feedId)" $qp)
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $WM_CONSUMERCHANNELTYPE, "WM_CONSUMER.ID": $WM_CONSUMERID, "WM_SEC.TIMESTAMP": $WM_SECTIMESTAMP, "WM_SEC.AUTH_SIGNATURE": $WM_SECAUTH_SIGNATURE, "WM_SVC.NAME": $WM_SVCNAME, "WM_QOS.CORRELATION_ID": $WM_QOSCORRELATION_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get status of an item feed
#
# GET /v3/feeds
# operationId: v3getFeedItemStatus
export def "feeds v3getFeedItemStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedId: string # The feed ID.
  --includeDetails: string # Includes the status details for each item in the feed. Do not set this parameter to true as discrepancies may appear between the header and the item details (the item details may be incorrect). Instead, use the Get a feedItems status. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of items to be returned. Cannot be more than 50 items. Use it only when the includeDetails is set to true. (default: 50)
  --WM-CONSUMERCHANNELTYPE: string@WM-CONSUMERCHANNELTYPE-completer # Channel Type
  --WM-CONSUMERID: string # Your Consumer ID
  --WM-SECTIMESTAMP: string # Epoch timestamp
  --WM-SECAUTH-SIGNATURE: string # Authentication signature
  --WM-SVCNAME: string # The Service name
  --WM-QOSCORRELATION-ID: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedId" $feedId "scalar") (serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/feeds" $qp)
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $WM_CONSUMERCHANNELTYPE, "WM_CONSUMER.ID": $WM_CONSUMERID, "WM_SEC.TIMESTAMP": $WM_SECTIMESTAMP, "WM_SEC.AUTH_SIGNATURE": $WM_SECAUTH_SIGNATURE, "WM_SVC.NAME": $WM_SVCNAME, "WM_QOS.CORRELATION_ID": $WM_QOSCORRELATION_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload an item feed
#
# POST /v3/feeds
# operationId: v3doPostMultiPart
export def "feeds v3doPostMultiPart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedType: string@feedType-completer-1 # Feed Type (default: item)
  --WM-CONSUMERCHANNELTYPE: string@WM-CONSUMERCHANNELTYPE-completer # Channel Type
  --WM-CONSUMERID: string # Your Consumer ID
  --WM-SECTIMESTAMP: string # Epoch timestamp
  --WM-SECAUTH-SIGNATURE: string # Authentication signature
  --WM-SVCNAME: string # The Service name
  --WM-QOSCORRELATION-ID: string # A Transaction ID
  file: path # Feed File to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feedType" $feedType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/feeds" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $WM_CONSUMERCHANNELTYPE, "WM_CONSUMER.ID": $WM_CONSUMERID, "WM_SEC.TIMESTAMP": $WM_SECTIMESTAMP, "WM_SEC.AUTH_SIGNATURE": $WM_SECAUTH_SIGNATURE, "WM_SVC.NAME": $WM_SVCNAME, "WM_QOS.CORRELATION_ID": $WM_QOSCORRELATION_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get status of an item within a feed
#
# GET /v3/feeds/{feedId}
# operationId: v3getAllItemsStatus
export def "feeds v3getAllItemsStatus" [
  feedId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeDetails: string # Includes details of each entity in the feed. Do not set this parameter to true. (default: false)
  --offset: string # The object response to start with, where 0 is the first entity that can be requested. It can only be used when includeDetails is set to true. (default: 0)
  --limit: string # The number of entities to be returned. It cannot be more than 50 entities. Use it only when the includeDetails is set to true. (default: 50)
  --WM-CONSUMERCHANNELTYPE: string@WM-CONSUMERCHANNELTYPE-completer # Channel Type
  --WM-CONSUMERID: string # Your Consumer ID
  --WM-SECTIMESTAMP: string # Epoch timestamp
  --WM-SECAUTH-SIGNATURE: string # Authentication signature
  --WM-SVCNAME: string # The Service name
  --WM-QOSCORRELATION-ID: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDetails" $includeDetails "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/feeds/($feedId)" $qp)
  let extra_headers = {"WM_CONSUMER.CHANNEL.TYPE": $WM_CONSUMERCHANNELTYPE, "WM_CONSUMER.ID": $WM_CONSUMERID, "WM_SEC.TIMESTAMP": $WM_SECTIMESTAMP, "WM_SEC.AUTH_SIGNATURE": $WM_SECAUTH_SIGNATURE, "WM_SVC.NAME": $WM_SVCNAME, "WM_QOS.CORRELATION_ID": $WM_QOSCORRELATION_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
