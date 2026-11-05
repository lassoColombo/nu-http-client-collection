# Auto-generated client for AWS Marketplace Commerce Analytics v2015-07-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/marketplacecommerceanalytics/2015-07-01/openapi.json
# Auth: --token flag or $env.AWS_MARKETPLACE_COMMERCE_ANALYTICS_TOKEN

const BASE_URL = "http://marketplacecommerceanalytics.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_MARKETPLACE_COMMERCE_ANALYTICS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://marketplacecommerceanalytics.us-east-1.amazonaws.com" "http://marketplacecommerceanalytics.us-east-2.amazonaws.com" "http://marketplacecommerceanalytics.us-west-1.amazonaws.com" "http://marketplacecommerceanalytics.us-west-2.amazonaws.com" "http://marketplacecommerceanalytics.us-gov-west-1.amazonaws.com" "http://marketplacecommerceanalytics.us-gov-east-1.amazonaws.com" "http://marketplacecommerceanalytics.ca-central-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-north-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-west-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-west-2.amazonaws.com" "http://marketplacecommerceanalytics.eu-west-3.amazonaws.com" "http://marketplacecommerceanalytics.eu-central-1.amazonaws.com" "http://marketplacecommerceanalytics.eu-south-1.amazonaws.com" "http://marketplacecommerceanalytics.af-south-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-northeast-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-northeast-2.amazonaws.com" "http://marketplacecommerceanalytics.ap-northeast-3.amazonaws.com" "http://marketplacecommerceanalytics.ap-southeast-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-southeast-2.amazonaws.com" "http://marketplacecommerceanalytics.ap-east-1.amazonaws.com" "http://marketplacecommerceanalytics.ap-south-1.amazonaws.com" "http://marketplacecommerceanalytics.sa-east-1.amazonaws.com" "http://marketplacecommerceanalytics.me-south-1.amazonaws.com" "https://marketplacecommerceanalytics.us-east-1.amazonaws.com" "https://marketplacecommerceanalytics.us-east-2.amazonaws.com" "https://marketplacecommerceanalytics.us-west-1.amazonaws.com" "https://marketplacecommerceanalytics.us-west-2.amazonaws.com" "https://marketplacecommerceanalytics.us-gov-west-1.amazonaws.com" "https://marketplacecommerceanalytics.us-gov-east-1.amazonaws.com" "https://marketplacecommerceanalytics.ca-central-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-north-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-west-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-west-2.amazonaws.com" "https://marketplacecommerceanalytics.eu-west-3.amazonaws.com" "https://marketplacecommerceanalytics.eu-central-1.amazonaws.com" "https://marketplacecommerceanalytics.eu-south-1.amazonaws.com" "https://marketplacecommerceanalytics.af-south-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-northeast-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-northeast-2.amazonaws.com" "https://marketplacecommerceanalytics.ap-northeast-3.amazonaws.com" "https://marketplacecommerceanalytics.ap-southeast-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-southeast-2.amazonaws.com" "https://marketplacecommerceanalytics.ap-east-1.amazonaws.com" "https://marketplacecommerceanalytics.ap-south-1.amazonaws.com" "https://marketplacecommerceanalytics.sa-east-1.amazonaws.com" "https://marketplacecommerceanalytics.me-south-1.amazonaws.com" "http://marketplacecommerceanalytics.cn-north-1.amazonaws.com.cn" "http://marketplacecommerceanalytics.cn-northwest-1.amazonaws.com.cn" "https://marketplacecommerceanalytics.cn-north-1.amazonaws.com.cn" "https://marketplacecommerceanalytics.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def data-set-type-completer [] { ["customer_profile_by_geography" "customer_profile_by_industry" "customer_profile_by_revenue" "customer_subscriber_annual_subscriptions" "customer_subscriber_hourly_monthly_subscriptions" "daily_business_canceled_product_subscribers" "daily_business_fees" "daily_business_free_trial_conversions" "daily_business_new_instances" "daily_business_new_product_subscribers" "daily_business_usage_by_instance_type" "disbursed_amount_by_age_of_disbursed_funds" "disbursed_amount_by_age_of_past_due_funds" "disbursed_amount_by_age_of_uncollected_funds" "disbursed_amount_by_customer_geo" "disbursed_amount_by_instance_hours" "disbursed_amount_by_product" "disbursed_amount_by_product_with_uncollected_funds" "disbursed_amount_by_uncollected_funds_breakdown" "monthly_revenue_annual_subscriptions" "monthly_revenue_billing_and_revenue_data" "monthly_revenue_field_demonstration_usage" "monthly_revenue_flexible_payment_schedule" "sales_compensation_billed_revenue" "us_sales_and_use_tax_records"] }
def x-amz-target-completer [] { ["MarketplaceCommerceAnalytics20150701.GenerateDataSet"] }
def data-set-type-completer-1 [] { ["customer_support_contacts_data" "test_customer_support_contacts_data"] }
def x-amz-target-completer-1 [] { ["MarketplaceCommerceAnalytics20150701.StartSupportDataExport"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["generate-data-set" "start-support-data-export" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
# POST /
# operationId: GenerateDataSet
export def "generate-data-set" [
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
  --x-amz-target: string@x-amz-target-completer # required
  data_set_type: string@data-set-type-completer # The desired data set type. customer_subscriber_hourly_monthly_subscriptions From 2017-09-15 to present: Available daily by 24:00 UTC. customer_subscriber_annual_subscriptions From 2017-09-15 to present: Available daily by 24:00 UTC. daily_business_usage_by_instance_type From 2017-09-15 to present: Available daily by 24:00 UTC. daily_business_fees From 2017-09-15 to present: Available daily by 24:00 UTC. daily_business_free_trial_conversions From 2017-09-15 to present: Available daily by 24:00 UTC. daily_business_new_instances From 2017-09-15 to present: Available daily by 24:00 UTC. daily_business_new_product_subscribers From 2017-09-15 to present: Available daily by 24:00 UTC. daily_business_canceled_product_subscribers From 2017-09-15 to present: Available daily by 24:00 UTC. monthly_revenue_billing_and_revenue_data From 2017-09-15 to present: Available monthly on the 15th day of the month by 24:00 UTC. Data includes metered transactions (e.g. hourly) from one month prior. monthly_revenue_annual_subscriptions From 2017-09-15 to present: Available monthly on the 15th day of the month by 24:00 UTC. Data includes up-front software charges (e.g. annual) from one month prior. monthly_revenue_field_demonstration_usage From 2018-03-15 to present: Available monthly on the 15th day of the month by 24:00 UTC. monthly_revenue_flexible_payment_schedule From 2018-11-15 to present: Available monthly on the 15th day of the month by 24:00 UTC. disbursed_amount_by_product From 2017-09-15 to present: Available every 30 days by 24:00 UTC. disbursed_amount_by_instance_hours From 2017-09-15 to present: Available every 30 days by 24:00 UTC. disbursed_amount_by_customer_geo From 2017-09-15 to present: Available every 30 days by 24:00 UTC. disbursed_amount_by_age_of_uncollected_funds From 2017-09-15 to present: Available every 30 days by 24:00 UTC. disbursed_amount_by_age_of_disbursed_funds From 2017-09-15 to present: Available every 30 days by 24:00 UTC. disbursed_amount_by_age_of_past_due_funds From 2018-04-07 to present: Available every 30 days by 24:00 UTC. disbursed_amount_by_uncollected_funds_breakdown From 2019-10-04 to present: Available every 30 days by 24:00 UTC. sales_compensation_billed_revenue From 2017-09-15 to present: Available monthly on the 15th day of the month by 24:00 UTC. Data includes metered transactions (e.g. hourly) from one month prior, and up-front software charges (e.g. annual) from one month prior. us_sales_and_use_tax_records From 2017-09-15 to present: Available monthly on the 15th day of the month by 24:00 UTC. disbursed_amount_by_product_with_uncollected_funds This data set is deprecated. Download related reports from AMMP instead! customer_profile_by_industry This data set is deprecated. Download related reports from AMMP instead! customer_profile_by_revenue This data set is deprecated. Download related reports from AMMP instead! customer_profile_by_geography This data set is deprecated. Download related reports from AMMP instead!
  data_set_publication_date: string # The date a data set was published. For daily data sets, provide a date with day-level granularity for the desired day. For monthly data sets except those with prefix disbursed_amount, provide a date with month-level granularity for the desired month (the day value will be ignored). For data sets with prefix disbursed_amount, provide a date with day-level granularity for the desired day. For these data sets we will look backwards in time over the range of 31 days until the first data set is found (the latest one). (format: date-time)
  role_name_arn: string # The Amazon Resource Name (ARN) of the Role with an attached permissions policy to interact with the provided AWS services.
  destination_s3_bucket_name: string # The name (friendly name, not ARN) of the destination S3 bucket.
  --destination-s3-prefix: string # (Optional) The desired S3 prefix for the published data set, similar to a directory path in standard file systems. For example, if given the bucket name "mybucket" and the prefix "myprefix/mydatasets", the output file "outputfile" would be published to "s3://mybucket/myprefix/mydatasets/outputfile". If the prefix directory structure does not exist, it will be created. If no prefix is provided, the data set will be published to the S3 bucket root.
  sns_topic_arn: string # Amazon Resource Name (ARN) for the SNS Topic that will be notified when the data set has been published or if an error has occurred.
  --customer-defined-values: record # (Optional) Key-value pairs which will be returned, unmodified, in the Amazon SNS notification message and the data set metadata file. These key-value pairs can be used to correlated responses with tracking information from other systems.
]: any -> oneof<record<dataSetRequestId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "MarketplaceCommerceAnalytics20150701.GenerateDataSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"dataSetType": $data_set_type, "dataSetPublicationDate": $data_set_publication_date, "roleNameArn": $role_name_arn, "destinationS3BucketName": $destination_s3_bucket_name, "destinationS3Prefix": $destination_s3_prefix, "snsTopicArn": $sns_topic_arn, "customerDefinedValues": $customer_defined_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Given a data set type and a from date, asynchronously publishes the requested customer support data to the specified S3 bucket and notifies the specified SNS topic once the data is available. Returns a unique request identifier that can be used to correlate requests with notifications from the SNS topic. Data sets will be published in comma-separated values (CSV) format with the file name {data_set_type}_YYYY-MM-DD'T'HH-mm-ss'Z'.csv. If a file with the same name already exists (e.g. if the same data set is requested twice), the original file will be overwritten by the new file. Requires a Role with an attached permissions policy providing Allow permissions for the following actions: s3:PutObject, s3:GetBucketLocation, sns:GetTopicAttributes, sns:Publish, iam:GetRolePolicy.
#
# POST /
# operationId: StartSupportDataExport
export def "start-support-data-export" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  data_set_type: string@data-set-type-completer-1 # Specifies the data set type to be written to the output csv file. The data set types customer_support_contacts_data and test_customer_support_contacts_data both result in a csv file containing the following fields: Product Id, Product Code, Customer Guid, Subscription Guid, Subscription Start Date, Organization, AWS Account Id, Given Name, Surname, Telephone Number, Email, Title, Country Code, ZIP Code, Operation Type, and Operation Time. customer_support_contacts_data Customer support contact data. The data set will contain all changes (Creates, Updates, and Deletes) to customer support contact data from the date specified in the from_date parameter. test_customer_support_contacts_data An example data set containing static test data in the same format as customer_support_contacts_data
  from_date: string # The start date from which to retrieve the data set in UTC. This parameter only affects the customer_support_contacts_data data set type. (format: date-time)
  role_name_arn: string # The Amazon Resource Name (ARN) of the Role with an attached permissions policy to interact with the provided AWS services.
  destination_s3_bucket_name: string # The name (friendly name, not ARN) of the destination S3 bucket.
  --destination-s3-prefix: string # (Optional) The desired S3 prefix for the published data set, similar to a directory path in standard file systems. For example, if given the bucket name "mybucket" and the prefix "myprefix/mydatasets", the output file "outputfile" would be published to "s3://mybucket/myprefix/mydatasets/outputfile". If the prefix directory structure does not exist, it will be created. If no prefix is provided, the data set will be published to the S3 bucket root.
  sns_topic_arn: string # Amazon Resource Name (ARN) for the SNS Topic that will be notified when the data set has been published or if an error has occurred.
  --customer-defined-values: record # (Optional) Key-value pairs which will be returned, unmodified, in the Amazon SNS notification message and the data set metadata file.
]: any -> oneof<record<dataSetRequestId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "MarketplaceCommerceAnalytics20150701.StartSupportDataExport")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"dataSetType": $data_set_type, "fromDate": $from_date, "roleNameArn": $role_name_arn, "destinationS3BucketName": $destination_s3_bucket_name, "destinationS3Prefix": $destination_s3_prefix, "snsTopicArn": $sns_topic_arn, "customerDefinedValues": $customer_defined_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
