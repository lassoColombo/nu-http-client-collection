# Auto-generated client for AWS Import/Export v2010-06-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/importexport/2010-06-01/openapi.json
# Auth: --token flag or $env.AWS_IMPORT_EXPORT_TOKEN

const BASE_URL = "http://importexport.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_IMPORT_EXPORT_TOKEN | default "" }
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

def base-url-completer [] { ["http://importexport.amazonaws.com" "https://importexport.amazonaws.com" "http://importexport.cn-north-1.amazonaws.com.cn" "http://importexport.cn-northwest-1.amazonaws.com.cn" "https://importexport.cn-north-1.amazonaws.com.cn" "https://importexport.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Operation-completer [] { ["CancelJob"] }
def Action-completer [] { ["CancelJob"] }
def Version-completer [] { ["2010-06-01"] }
def JobType-completer [] { ["Export" "Import"] }
def Operation-completer-1 [] { ["CreateJob"] }
def Action-completer-1 [] { ["CreateJob"] }
def Operation-completer-2 [] { ["GetShippingLabel"] }
def Action-completer-2 [] { ["GetShippingLabel"] }
def Operation-completer-3 [] { ["GetStatus"] }
def Action-completer-3 [] { ["GetStatus"] }
def Operation-completer-4 [] { ["ListJobs"] }
def Action-completer-4 [] { ["ListJobs"] }
def Operation-completer-5 [] { ["UpdateJob"] }
def Action-completer-5 [] { ["UpdateJob"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "operation-cancel-job-action-cancel-job CancelJob" } } | get name | first)
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

# This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
#
# GET /#Operation=CancelJob&Action=CancelJob
# operationId: GET_CancelJob
export def "operation-cancel-job-action-cancel-job CancelJob" [
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
  --JobId: string
  --APIVersion: string
  --Operation: string@Operation-completer
  --Action: string@Action-completer
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "JobId" $JobId "scalar") (serialize-qp "APIVersion" $APIVersion "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=CancelJob&Action=CancelJob" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
#
# POST /#Operation=CancelJob&Action=CancelJob
# operationId: POST_CancelJob
export def "operation-cancel-job-action-cancel-job CancelJob-1" [
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
  --Operation: string@Operation-completer
  --Action: string@Action-completer
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=CancelJob&Action=CancelJob" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
#
# GET /#Operation=CreateJob&Action=CreateJob
# operationId: GET_CreateJob
export def "operation-create-job-action-create-job CreateJob" [
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
  --JobType: string@JobType-completer
  --Manifest: string
  --ManifestAddendum: string
  --ValidateOnly: oneof<nothing, bool>
  --APIVersion: string
  --Operation: string@Operation-completer-1
  --Action: string@Action-completer-1
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "JobType" $JobType "scalar") (serialize-qp "Manifest" $Manifest "scalar") (serialize-qp "ManifestAddendum" $ManifestAddendum "scalar") (serialize-qp "ValidateOnly" $ValidateOnly "scalar") (serialize-qp "APIVersion" $APIVersion "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=CreateJob&Action=CreateJob" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
#
# POST /#Operation=CreateJob&Action=CreateJob
# operationId: POST_CreateJob
export def "operation-create-job-action-create-job CreateJob-1" [
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
  --Operation: string@Operation-completer-1
  --Action: string@Action-completer-1
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=CreateJob&Action=CreateJob" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
#
# GET /#Operation=GetShippingLabel&Action=GetShippingLabel
# operationId: GET_GetShippingLabel
export def "operation-get-shipping-label-action-get-shipping-label GetShippingLabel" [
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
  --jobIds: list
  --name: string
  --company: string
  --phoneNumber: string
  --country: string
  --stateOrProvince: string
  --city: string
  --postalCode: string
  --street1: string
  --street2: string
  --street3: string
  --APIVersion: string
  --Operation: string@Operation-completer-2
  --Action: string@Action-completer-2
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "jobIds" $jobIds "multi") (serialize-qp "name" $name "scalar") (serialize-qp "company" $company "scalar") (serialize-qp "phoneNumber" $phoneNumber "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "stateOrProvince" $stateOrProvince "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "postalCode" $postalCode "scalar") (serialize-qp "street1" $street1 "scalar") (serialize-qp "street2" $street2 "scalar") (serialize-qp "street3" $street3 "scalar") (serialize-qp "APIVersion" $APIVersion "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=GetShippingLabel&Action=GetShippingLabel" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
#
# POST /#Operation=GetShippingLabel&Action=GetShippingLabel
# operationId: POST_GetShippingLabel
export def "operation-get-shipping-label-action-get-shipping-label GetShippingLabel-1" [
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
  --Operation: string@Operation-completer-2
  --Action: string@Action-completer-2
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=GetShippingLabel&Action=GetShippingLabel" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
#
# GET /#Operation=GetStatus&Action=GetStatus
# operationId: GET_GetStatus
export def "operation-get-status-action-get-status GetStatus" [
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
  --JobId: string
  --APIVersion: string
  --Operation: string@Operation-completer-3
  --Action: string@Action-completer-3
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "JobId" $JobId "scalar") (serialize-qp "APIVersion" $APIVersion "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=GetStatus&Action=GetStatus" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
#
# POST /#Operation=GetStatus&Action=GetStatus
# operationId: POST_GetStatus
export def "operation-get-status-action-get-status GetStatus-1" [
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
  --Operation: string@Operation-completer-3
  --Action: string@Action-completer-3
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=GetStatus&Action=GetStatus" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
#
# GET /#Operation=ListJobs&Action=ListJobs
# operationId: GET_ListJobs
export def "operation-list-jobs-action-list-jobs ListJobs" [
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
  --MaxJobs: int
  --Marker: string
  --APIVersion: string
  --Operation: string@Operation-completer-4
  --Action: string@Action-completer-4
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "MaxJobs" $MaxJobs "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "APIVersion" $APIVersion "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=ListJobs&Action=ListJobs" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
#
# POST /#Operation=ListJobs&Action=ListJobs
# operationId: POST_ListJobs
export def "operation-list-jobs-action-list-jobs ListJobs-1" [
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
  --MaxJobs: string # Pagination limit
  --Marker: string # Pagination token
  --Operation: string@Operation-completer-4
  --Action: string@Action-completer-4
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "MaxJobs" $MaxJobs "scalar") (serialize-qp "Marker" $Marker "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=ListJobs&Action=ListJobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}

# You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
#
# GET /#Operation=UpdateJob&Action=UpdateJob
# operationId: GET_UpdateJob
export def "operation-update-job-action-update-job UpdateJob" [
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
  --JobId: string
  --Manifest: string
  --JobType: string@JobType-completer
  --ValidateOnly: oneof<nothing, bool>
  --APIVersion: string
  --Operation: string@Operation-completer-5
  --Action: string@Action-completer-5
  --Version: string@Version-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "JobId" $JobId "scalar") (serialize-qp "Manifest" $Manifest "scalar") (serialize-qp "JobType" $JobType "scalar") (serialize-qp "ValidateOnly" $ValidateOnly "scalar") (serialize-qp "APIVersion" $APIVersion "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=UpdateJob&Action=UpdateJob" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
#
# POST /#Operation=UpdateJob&Action=UpdateJob
# operationId: POST_UpdateJob
export def "operation-update-job-action-update-job UpdateJob-1" [
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
  --Operation: string@Operation-completer-5
  --Action: string@Action-completer-5
  --Version: string@Version-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "AWSAccessKeyId" $AWSAccessKeyId "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "SignatureMethod" $SignatureMethod "scalar") (serialize-qp "SignatureVersion" $SignatureVersion "scalar") (serialize-qp "Timestamp" $Timestamp "scalar") (serialize-qp "Version" $Version "scalar") (serialize-qp "Signature" $Signature "scalar") (serialize-qp "Operation" $Operation "scalar") (serialize-qp "Action" $Action "scalar") (serialize-qp "Version" $Version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#Operation=UpdateJob&Action=UpdateJob" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/xml" $body
}
