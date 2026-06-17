# Auto-generated client for Amazon SageMaker Feature Store Runtime v2020-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sagemaker-featurestore-runtime/2020-07-01/openapi.json
# Auth: --token flag or $env.AMAZON_SAGEMAKER_FEATURE_STORE_RUNTIME_TOKEN

const BASE_URL = "http://featurestore-runtime.sagemaker.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SAGEMAKER_FEATURE_STORE_RUNTIME_TOKEN | default "" }
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

def base-url-completer [] { ["http://featurestore-runtime.sagemaker.us-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.us-east-2.amazonaws.com" "http://featurestore-runtime.sagemaker.us-west-1.amazonaws.com" "http://featurestore-runtime.sagemaker.us-west-2.amazonaws.com" "http://featurestore-runtime.sagemaker.us-gov-west-1.amazonaws.com" "http://featurestore-runtime.sagemaker.us-gov-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ca-central-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-north-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-west-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-west-2.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-west-3.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-central-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.af-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-northeast-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-northeast-2.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-northeast-3.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-southeast-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-southeast-2.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.sa-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.me-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-east-2.amazonaws.com" "https://featurestore-runtime.sagemaker.us-west-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-west-2.amazonaws.com" "https://featurestore-runtime.sagemaker.us-gov-west-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-gov-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ca-central-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-north-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-west-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-west-2.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-west-3.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-central-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.af-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-northeast-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-northeast-2.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-northeast-3.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-southeast-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-southeast-2.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.sa-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.me-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.cn-north-1.amazonaws.com.cn" "http://featurestore-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://featurestore-runtime.sagemaker.cn-north-1.amazonaws.com.cn" "https://featurestore-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def deletion-mode-completer [] { ["HardDelete" "SoftDelete"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch-get-record post" } } | get name | first)
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

# Retrieves a batch of <code>Records</code> from a <code>FeatureGroup</code>.
#
# POST /BatchGetRecord
# operationId: BatchGetRecord
# --Identifiers item shape: {FeatureGroupName: any, RecordIdentifiersValueAsString: any, FeatureNames?: any}
export def "batch-get-record post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identifiers: list # A list of <code>FeatureGroup</code> names, with their corresponding <code>RecordIdentifier</code> value, and Feature name that have been requested to be retrieved in batch. — item shape: {FeatureGroupName: any, RecordIdentifiersValueAsString: any, FeatureNames?: any}
]: any -> record<Records: record, Errors: record, UnprocessedIdentifiers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BatchGetRecord")
  let body = {"Identifiers": $identifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes a <code>Record</code> from a <code>FeatureGroup</code> in the <code>OnlineStore</code>. Feature Store supports both <code>SOFT_DELETE</code> and <code>HARD_DELETE</code>. For <code>SOFT_DELETE</code> (default), feature columns are set to <code>null</code> and the record is no longer retrievable by <code>GetRecord</code> or <code>BatchGetRecord</code>. For<code> HARD_DELETE</code>, the complete <code>Record</code> is removed from the <code>OnlineStore</code>. In both cases, Feature Store appends the deleted record marker to the <code>OfflineStore</code> with feature values set to <code>null</code>, <code>is_deleted</code> value set to <code>True</code>, and <code>EventTime</code> set to the delete input <code>EventTime</code>.</p> <p>Note that the <code>EventTime</code> specified in <code>DeleteRecord</code> should be set later than the <code>EventTime</code> of the existing record in the <code>OnlineStore</code> for that <code>RecordIdentifer</code>. If it is not, the deletion does not occur:</p> <ul> <li> <p>For <code>SOFT_DELETE</code>, the existing (undeleted) record remains in the <code>OnlineStore</code>, though the delete record marker is still written to the <code>OfflineStore</code>.</p> </li> <li> <p> <code>HARD_DELETE</code> returns <code>EventTime</code>: <code>400 ValidationException</code> to indicate that the delete operation failed. No delete record marker is written to the <code>OfflineStore</code>.</p> </li> </ul>
#
# DELETE /FeatureGroup/{FeatureGroupName}#RecordIdentifierValueAsString&EventTime
# operationId: DeleteRecord
export def "feature-group delete-record" [
  feature_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --record-identifier-value-as-string: string # The value for the <code>RecordIdentifier</code> that uniquely identifies the record, in string format. 
  --event-time: string # Timestamp indicating when the deletion event occurred. <code>EventTime</code> can be used to query data at a certain point in time.
  --target-stores: list # A list of stores from which you're deleting the record. By default, Feature Store deletes the record from all of the stores that you're using for the <code>FeatureGroup</code>.
  --deletion-mode: string@deletion-mode-completer # The name of the deletion mode for deleting the record. By default, the deletion mode is set to <code>SoftDelete</code>.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RecordIdentifierValueAsString" $record_identifier_value_as_string "scalar") (serialize-qp "EventTime" $event_time "scalar") (serialize-qp "TargetStores" $target_stores "multi") (serialize-qp "DeletionMode" $deletion_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feature_group_name: $feature_group_name} | format pattern "/FeatureGroup/{feature_group_name}#RecordIdentifierValueAsString&EventTime") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use for <code>OnlineStore</code> serving from a <code>FeatureStore</code>. Only the latest records stored in the <code>OnlineStore</code> can be retrieved. If no Record with <code>RecordIdentifierValue</code> is found, then an empty result is returned. 
#
# GET /FeatureGroup/{FeatureGroupName}#RecordIdentifierValueAsString
# operationId: GetRecord
export def "feature-group get-record" [
  feature_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --record-identifier-value-as-string: string # The value that corresponds to <code>RecordIdentifier</code> type and uniquely identifies the record in the <code>FeatureGroup</code>. 
  --feature-name: list # List of names of Features to be retrieved. If not specified, the latest value for all the Features are returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Record: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RecordIdentifierValueAsString" $record_identifier_value_as_string "scalar") (serialize-qp "FeatureName" $feature_name "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({feature_group_name: $feature_group_name} | format pattern "/FeatureGroup/{feature_group_name}#RecordIdentifierValueAsString") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used for data ingestion into the <code>FeatureStore</code>. The <code>PutRecord</code> API writes to both the <code>OnlineStore</code> and <code>OfflineStore</code>. If the record is the latest record for the <code>recordIdentifier</code>, the record is written to both the <code>OnlineStore</code> and <code>OfflineStore</code>. If the record is a historic record, it is written only to the <code>OfflineStore</code>.
#
# PUT /FeatureGroup/{FeatureGroupName}
# operationId: PutRecord
# --Record item shape: {FeatureName: any, ValueAsString: any}
export def "feature-group update-record" [
  feature_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  record: list # <p>List of FeatureValues to be inserted. This will be a full over-write. If you only want to update few of the feature values, do the following:</p> <ul> <li> <p>Use <code>GetRecord</code> to retrieve the latest record.</p> </li> <li> <p>Update the record returned from <code>GetRecord</code>. </p> </li> <li> <p>Use <code>PutRecord</code> to update feature values.</p> </li> </ul> — item shape: {FeatureName: any, ValueAsString: any}
  --target-stores: list # A list of stores to which you're adding the record. By default, Feature Store adds the record to all of the stores that you're using for the <code>FeatureGroup</code>.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({feature_group_name: $feature_group_name} | format pattern "/FeatureGroup/{feature_group_name}"))
  let body = {"Record": $record, "TargetStores": $target_stores} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
