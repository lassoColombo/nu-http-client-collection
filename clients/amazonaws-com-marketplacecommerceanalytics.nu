# Auto-generated client for AWS Marketplace Commerce Analytics v2015-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/marketplacecommerceanalytics/2015-07-01/openapi.json
# Auth: --token flag or $env.AWS_MARKETPLACE_COMMERCE_ANALYTICS_TOKEN

const BASE_URL = "http://marketplacecommerceanalytics.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_MARKETPLACE_COMMERCE_ANALYTICS_TOKEN | default "" }
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

def base-url-completer [] { ["http://marketplacecommerceanalytics.us-east-1.amazonaws.com" "http://marketplacecommerceanalytics.us-east-2.amazonaws.com" "http://marketplacecommerceanalytics.us-west-1.amazonaws.com" "http://marketplacecommerceanalytics.us-west-2.amazonaws.com" "http://marketplacecommerceanalytics.us-gov-west-1.amazonaws.com" "http://marketplacecommerceanalytics.us-gov-east-1.amazonaws.com" "http://marketplacecommerceanalytics.ca-central-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-north-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-west-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-west-2.amazonaws.com" "http://marketplacecommerceanalytics.eu-west-3.amazonaws.com" "http://marketplacecommerceanalytics.eu-central-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-south-1.amazonaws.com" "http://marketplacecommerceanalytics.af-south-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-northeast-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-northeast-2.amazonaws.com" "http://marketplacecommerceanalytics.ap-northeast-3.amazonaws.com" "http://marketplacecommerceanalytics.ap-southeast-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-southeast-2.amazonaws.com" "http://marketplacecommerceanalytics.ap-east-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-south-1.amazonaws.com" "http://marketplacecommerceanalytics.sa-east-1.amazonaws.com" "http://marketplacecommerceanalytics.me-south-1.amazonaws.com" "https://marketplacecommerceanalytics.us-east-1.amazonaws.com" "https://marketplacecommerceanalytics.us-east-2.amazonaws.com" "https://marketplacecommerceanalytics.us-west-1.amazonaws.com" "https://marketplacecommerceanalytics.us-west-2.amazonaws.com" "https://marketplacecommerceanalytics.us-gov-west-1.amazonaws.com" "https://marketplacecommerceanalytics.us-gov-east-1.amazonaws.com" "https://marketplacecommerceanalytics.ca-central-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-north-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-west-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-west-2.amazonaws.com" "https://marketplacecommerceanalytics.eu-west-3.amazonaws.com" "https://marketplacecommerceanalytics.eu-central-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-south-1.amazonaws.com" "https://marketplacecommerceanalytics.af-south-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-northeast-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-northeast-2.amazonaws.com" "https://marketplacecommerceanalytics.ap-northeast-3.amazonaws.com" "https://marketplacecommerceanalytics.ap-southeast-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-southeast-2.amazonaws.com" "https://marketplacecommerceanalytics.ap-east-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-south-1.amazonaws.com" "https://marketplacecommerceanalytics.sa-east-1.amazonaws.com" "https://marketplacecommerceanalytics.me-south-1.amazonaws.com" "http://marketplacecommerceanalytics.cn-north-1.amazonaws.com.cn" "http://marketplacecommerceanalytics.cn-northwest-1.amazonaws.com.cn" "https://marketplacecommerceanalytics.cn-north-1.amazonaws.com.cn" "https://marketplacecommerceanalytics.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["MarketplaceCommerceAnalytics20150701.GenerateDataSet"] }
def x-amz-target-completer-1 [] { ["MarketplaceCommerceAnalytics20150701.StartSupportDataExport"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-marketplace-commerce-analytics20150701-generate-data-set post" } } | get name | first)
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

# Given a data set type and data set publication date, asynchronously publishes the requested data set to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
#
# POST /#X-Amz-Target=MarketplaceCommerceAnalytics20150701.GenerateDataSet
# operationId: GenerateDataSet
export def "x-amz-target-marketplace-commerce-analytics20150701-generate-data-set post" [
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
  data_set_type: any
  data_set_publication_date: any
  role_name_arn: any
  destination_s3_bucket_name: any
  --destination-s3-prefix: any
  sns_topic_arn: any
  --customer-defined-values: any
]: any -> record<dataSetRequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=MarketplaceCommerceAnalytics20150701.GenerateDataSet")
  let body = {"dataSetType": $data_set_type, "dataSetPublicationDate": $data_set_publication_date, "roleNameArn": $role_name_arn, "destinationS3BucketName": $destination_s3_bucket_name, "destinationS3Prefix": $destination_s3_prefix, "snsTopicArn": $sns_topic_arn, "customerDefinedValues": $customer_defined_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Given a data set type and a from date, asynchronously publishes the requested customer support data to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD'T'HH-mm-ss'Z'.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
#
# POST /#X-Amz-Target=MarketplaceCommerceAnalytics20150701.StartSupportDataExport
# operationId: StartSupportDataExport
export def "x-amz-target-marketplace-commerce-analytics20150701-start-support-data-export start" [
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
  --x-amz-target: string@x-amz-target-completer-1
  data_set_type: any
  from_date: any
  role_name_arn: any
  destination_s3_bucket_name: any
  --destination-s3-prefix: any
  sns_topic_arn: any
  --customer-defined-values: any
]: any -> record<dataSetRequestId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=MarketplaceCommerceAnalytics20150701.StartSupportDataExport")
  let body = {"dataSetType": $data_set_type, "fromDate": $from_date, "roleNameArn": $role_name_arn, "destinationS3BucketName": $destination_s3_bucket_name, "destinationS3Prefix": $destination_s3_prefix, "snsTopicArn": $sns_topic_arn, "customerDefinedValues": $customer_defined_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
