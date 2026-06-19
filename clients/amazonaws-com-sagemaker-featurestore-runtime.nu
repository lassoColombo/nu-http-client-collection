# Auto-generated client for Amazon SageMaker Feature Store Runtime v2020-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sagemaker-featurestore-runtime/2020-07-01/openapi.json
# Auth: --token flag or $env.AMAZON_SAGEMAKER_FEATURE_STORE_RUNTIME_TOKEN

const BASE_URL = "http://featurestore-runtime.sagemaker.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SAGEMAKER_FEATURE_STORE_RUNTIME_TOKEN | default "" }
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

def base-url-completer [] { ["http://featurestore-runtime.sagemaker.us-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.us-east-2.amazonaws.com" "http://featurestore-runtime.sagemaker.us-west-1.amazonaws.com" "http://featurestore-runtime.sagemaker.us-west-2.amazonaws.com" "http://featurestore-runtime.sagemaker.us-gov-west-1.amazonaws.com" "http://featurestore-runtime.sagemaker.us-gov-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ca-central-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-north-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-west-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-west-2.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-west-3.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-central-1.amazonaws.com" "http://featurestore-runtime.sagemaker.eu-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.af-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-northeast-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-northeast-2.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-northeast-3.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-southeast-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-southeast-2.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.ap-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.sa-east-1.amazonaws.com" "http://featurestore-runtime.sagemaker.me-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-east-2.amazonaws.com" "https://featurestore-runtime.sagemaker.us-west-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-west-2.amazonaws.com" "https://featurestore-runtime.sagemaker.us-gov-west-1.amazonaws.com" "https://featurestore-runtime.sagemaker.us-gov-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ca-central-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-north-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-west-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-west-2.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-west-3.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-central-1.amazonaws.com" "https://featurestore-runtime.sagemaker.eu-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.af-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-northeast-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-northeast-2.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-northeast-3.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-southeast-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-southeast-2.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.ap-south-1.amazonaws.com" "https://featurestore-runtime.sagemaker.sa-east-1.amazonaws.com" "https://featurestore-runtime.sagemaker.me-south-1.amazonaws.com" "http://featurestore-runtime.sagemaker.cn-north-1.amazonaws.com.cn" "http://featurestore-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://featurestore-runtime.sagemaker.cn-north-1.amazonaws.com.cn" "https://featurestore-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def deletion-mode-completer [] { ["HardDelete" "SoftDelete"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch-get-record get" } } | get name | first)
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

# Retrieves a batch of Records from a FeatureGroup.
#
# POST /BatchGetRecord
# operationId: BatchGetRecord
# --Identifiers item shape: {FeatureGroupName: any, RecordIdentifiersValueAsString: any, FeatureNames?: any}
export def "batch-get-record get" [
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
  identifiers: list # A list of FeatureGroup names, with their corresponding RecordIdentifier value, and Feature name that have been requested to be retrieved in batch. — item shape: {FeatureGroupName: any, RecordIdentifiersValueAsString: any, FeatureNames?: any}
]: any -> record<Records: record, Errors: record, UnprocessedIdentifiers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BatchGetRecord")
  let req_body = {"Identifiers": $identifiers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Record from a FeatureGroup in the OnlineStore. Feature Store supports both SOFT_DELETE and HARD_DELETE. For SOFT_DELETE (default), feature columns are set to null and the record is no longer retrievable by GetRecord or BatchGetRecord. For HARD_DELETE, the complete Record is removed from the OnlineStore. In both cases, Feature Store appends the deleted record marker to the OfflineStore with feature values set to null, is_deleted value set to True, and EventTime set to the delete input EventTime. Note that the EventTime specified in DeleteRecord should be set later than the EventTime of the existing record in the OnlineStore for that RecordIdentifer. If it is not, the deletion does not occur: For SOFT_DELETE, the existing (undeleted) record remains in the OnlineStore, though the delete record marker is still written to the OfflineStore. HARD_DELETE returns EventTime: 400 ValidationException to indicate that the delete operation failed. No delete record marker is written to the OfflineStore.
#
# DELETE /FeatureGroup/{FeatureGroupName}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --record-identifier-value-as-string: string # The value for the RecordIdentifier that uniquely identifies the record, in string format.
  --event-time: string # Timestamp indicating when the deletion event occurred. EventTime can be used to query data at a certain point in time.
  --target-stores: list # A list of stores from which you're deleting the record. By default, Feature Store deletes the record from all of the stores that you're using for the FeatureGroup.
  --deletion-mode: string@deletion-mode-completer # The name of the deletion mode for deleting the record. By default, the deletion mode is set to SoftDelete.
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
  if ($feature_group_name | is-empty) { error make --unspanned { msg: "path parameter 'FeatureGroupName' must be non-empty" } }
  let qp = [(serialize-qp "RecordIdentifierValueAsString" $record_identifier_value_as_string "scalar") (serialize-qp "EventTime" $event_time "scalar") (serialize-qp "TargetStores" $target_stores "multi") (serialize-qp "DeletionMode" $deletion_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feature_group_name: (encode-path-segment $feature_group_name)} | format pattern "/FeatureGroup/{feature_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RecordIdentifierValueAsString": $record_identifier_value_as_string, "EventTime": $event_time, "TargetStores": $target_stores, "DeletionMode": $deletion_mode} | compact), body: null}
}

# Use for OnlineStore serving from a FeatureStore. Only the latest records stored in the OnlineStore can be retrieved. If no Record with RecordIdentifierValue is found, then an empty result is returned.
#
# GET /FeatureGroup/{FeatureGroupName}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --record-identifier-value-as-string: string # The value that corresponds to RecordIdentifier type and uniquely identifies the record in the FeatureGroup.
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
  if ($feature_group_name | is-empty) { error make --unspanned { msg: "path parameter 'FeatureGroupName' must be non-empty" } }
  let qp = [(serialize-qp "RecordIdentifierValueAsString" $record_identifier_value_as_string "scalar") (serialize-qp "FeatureName" $feature_name "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({feature_group_name: (encode-path-segment $feature_group_name)} | format pattern "/FeatureGroup/{feature_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RecordIdentifierValueAsString": $record_identifier_value_as_string, "FeatureName": $feature_name} | compact), body: null}
}

# Used for data ingestion into the FeatureStore. The PutRecord API writes to both the OnlineStore and OfflineStore. If the record is the latest record for the recordIdentifier, the record is written to both the OnlineStore and OfflineStore. If the record is a historic record, it is written only to the OfflineStore.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  record: list # List of FeatureValues to be inserted. This will be a full over-write. If you only want to update few of the feature values, do the following: Use GetRecord to retrieve the latest record. Update the record returned from GetRecord. Use PutRecord to update feature values. — item shape: {FeatureName: any, ValueAsString: any}
  --target-stores: list<string> # A list of stores to which you're adding the record. By default, Feature Store adds the record to all of the stores that you're using for the FeatureGroup.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feature_group_name | is-empty) { error make --unspanned { msg: "path parameter 'FeatureGroupName' must be non-empty" } }
  let full_url = (build-url $base ({feature_group_name: (encode-path-segment $feature_group_name)} | format pattern "/FeatureGroup/{feature_group_name}"))
  let req_body = {"Record": $record, "TargetStores": $target_stores} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
