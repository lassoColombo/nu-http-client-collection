# Auto-generated client for AWS Migration Hub Config v2019-06-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/migrationhub-config/2019-06-30/openapi.json
# Auth: --token flag or $env.AWS_MIGRATION_HUB_CONFIG_TOKEN

const BASE_URL = "http://migrationhub-config.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_MIGRATION_HUB_CONFIG_TOKEN | default "" }
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

def base-url-completer [] { ["http://migrationhub-config.us-east-1.amazonaws.com" "http://migrationhub-config.us-east-2.amazonaws.com" "http://migrationhub-config.us-west-1.amazonaws.com" "http://migrationhub-config.us-west-2.amazonaws.com" "http://migrationhub-config.us-gov-west-1.amazonaws.com" "http://migrationhub-config.us-gov-east-1.amazonaws.com" "http://migrationhub-config.ca-central-1.amazonaws.com" "http://migrationhub-config.eu-north-1.amazonaws.com" "http://migrationhub-config.eu-west-1.amazonaws.com" "http://migrationhub-config.eu-west-2.amazonaws.com" "http://migrationhub-config.eu-west-3.amazonaws.com" "http://migrationhub-config.eu-central-1.amazonaws.com" "http://migrationhub-config.eu-south-1.amazonaws.com" "http://migrationhub-config.af-south-1.amazonaws.com" "http://migrationhub-config.ap-northeast-1.amazonaws.com" "http://migrationhub-config.ap-northeast-2.amazonaws.com" "http://migrationhub-config.ap-northeast-3.amazonaws.com" "http://migrationhub-config.ap-southeast-1.amazonaws.com" "http://migrationhub-config.ap-southeast-2.amazonaws.com" "http://migrationhub-config.ap-east-1.amazonaws.com" "http://migrationhub-config.ap-south-1.amazonaws.com" "http://migrationhub-config.sa-east-1.amazonaws.com" "http://migrationhub-config.me-south-1.amazonaws.com" "https://migrationhub-config.us-east-1.amazonaws.com" "https://migrationhub-config.us-east-2.amazonaws.com" "https://migrationhub-config.us-west-1.amazonaws.com" "https://migrationhub-config.us-west-2.amazonaws.com" "https://migrationhub-config.us-gov-west-1.amazonaws.com" "https://migrationhub-config.us-gov-east-1.amazonaws.com" "https://migrationhub-config.ca-central-1.amazonaws.com" "https://migrationhub-config.eu-north-1.amazonaws.com" "https://migrationhub-config.eu-west-1.amazonaws.com" "https://migrationhub-config.eu-west-2.amazonaws.com" "https://migrationhub-config.eu-west-3.amazonaws.com" "https://migrationhub-config.eu-central-1.amazonaws.com" "https://migrationhub-config.eu-south-1.amazonaws.com" "https://migrationhub-config.af-south-1.amazonaws.com" "https://migrationhub-config.ap-northeast-1.amazonaws.com" "https://migrationhub-config.ap-northeast-2.amazonaws.com" "https://migrationhub-config.ap-northeast-3.amazonaws.com" "https://migrationhub-config.ap-southeast-1.amazonaws.com" "https://migrationhub-config.ap-southeast-2.amazonaws.com" "https://migrationhub-config.ap-east-1.amazonaws.com" "https://migrationhub-config.ap-south-1.amazonaws.com" "https://migrationhub-config.sa-east-1.amazonaws.com" "https://migrationhub-config.me-south-1.amazonaws.com" "http://migrationhub-config.cn-north-1.amazonaws.com.cn" "http://migrationhub-config.cn-northwest-1.amazonaws.com.cn" "https://migrationhub-config.cn-north-1.amazonaws.com.cn" "https://migrationhub-config.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSMigrationHubMultiAccountService.CreateHomeRegionControl"] }
def x-amz-target-completer-1 [] { ["AWSMigrationHubMultiAccountService.DescribeHomeRegionControls"] }
def x-amz-target-completer-2 [] { ["AWSMigrationHubMultiAccountService.GetHomeRegion"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-aws-migration-hub-multi-account-service-create-home-region-control create" } } | get name | first)
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

# This API sets up the home region for the calling account only.
#
# POST /#X-Amz-Target=AWSMigrationHubMultiAccountService.CreateHomeRegionControl
# operationId: CreateHomeRegionControl
export def "x-amz-target-aws-migration-hub-multi-account-service-create-home-region-control create" [
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
  --x-amz-target: string@x-amz-target-completer
  home_region: any
  target: any
  --body-dry-run: any
]: any -> record<HomeRegionControl: record<ControlId: record, HomeRegion: record, Target: record<Type: record, Id: record>, RequestedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSMigrationHubMultiAccountService.CreateHomeRegionControl")
  let body = {"HomeRegion": $home_region, "Target": $target, "DryRun": $body_dry_run} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This API permits filtering on the <code>ControlId</code> and <code>HomeRegion</code> fields.
#
# POST /#X-Amz-Target=AWSMigrationHubMultiAccountService.DescribeHomeRegionControls
# operationId: DescribeHomeRegionControls
export def "x-amz-target-aws-migration-hub-multi-account-service-describe-home-region-controls post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --x-amz-target: string@x-amz-target-completer-1
  --control-id: any
  --home-region: any
  --target: any
  --max-results: any
  --next-token: any
]: any -> record<HomeRegionControls: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWSMigrationHubMultiAccountService.DescribeHomeRegionControls" $qp)
  let body = {"ControlId": $control_id, "HomeRegion": $home_region, "Target": $target, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the calling account’s home region, if configured. This API is used by other AWS services to determine the regional endpoint for calling AWS Application Discovery Service and Migration Hub. You must call <code>GetHomeRegion</code> at least once before you call any other AWS Application Discovery Service and AWS Migration Hub APIs, to obtain the account's Migration Hub home region.
#
# POST /#X-Amz-Target=AWSMigrationHubMultiAccountService.GetHomeRegion
# operationId: GetHomeRegion
export def "x-amz-target-aws-migration-hub-multi-account-service-get-home-region get" [
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
  --x-amz-target: string@x-amz-target-completer-2
  --body: record
]: any -> record<HomeRegion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWSMigrationHubMultiAccountService.GetHomeRegion")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
