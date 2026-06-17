# Auto-generated client for Amazon Pinpoint SMS and Voice Service v2018-09-05
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sms-voice/2018-09-05/openapi.json
# Auth: --token flag or $env.AMAZON_PINPOINT_SMS_AND_VOICE_SERVICE_TOKEN

const BASE_URL = "http://sms-voice.pinpoint.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_PINPOINT_SMS_AND_VOICE_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://sms-voice.pinpoint.us-east-1.amazonaws.com" "http://sms-voice.pinpoint.us-east-2.amazonaws.com" "http://sms-voice.pinpoint.us-west-1.amazonaws.com" "http://sms-voice.pinpoint.us-west-2.amazonaws.com" "http://sms-voice.pinpoint.us-gov-west-1.amazonaws.com" "http://sms-voice.pinpoint.us-gov-east-1.amazonaws.com" "http://sms-voice.pinpoint.ca-central-1.amazonaws.com" "http://sms-voice.pinpoint.eu-north-1.amazonaws.com" "http://sms-voice.pinpoint.eu-west-1.amazonaws.com" "http://sms-voice.pinpoint.eu-west-2.amazonaws.com" "http://sms-voice.pinpoint.eu-west-3.amazonaws.com" "http://sms-voice.pinpoint.eu-central-1.amazonaws.com" "http://sms-voice.pinpoint.eu-south-1.amazonaws.com" "http://sms-voice.pinpoint.af-south-1.amazonaws.com" "http://sms-voice.pinpoint.ap-northeast-1.amazonaws.com" "http://sms-voice.pinpoint.ap-northeast-2.amazonaws.com" "http://sms-voice.pinpoint.ap-northeast-3.amazonaws.com" "http://sms-voice.pinpoint.ap-southeast-1.amazonaws.com" "http://sms-voice.pinpoint.ap-southeast-2.amazonaws.com" "http://sms-voice.pinpoint.ap-east-1.amazonaws.com" "http://sms-voice.pinpoint.ap-south-1.amazonaws.com" "http://sms-voice.pinpoint.sa-east-1.amazonaws.com" "http://sms-voice.pinpoint.me-south-1.amazonaws.com" "https://sms-voice.pinpoint.us-east-1.amazonaws.com" "https://sms-voice.pinpoint.us-east-2.amazonaws.com" "https://sms-voice.pinpoint.us-west-1.amazonaws.com" "https://sms-voice.pinpoint.us-west-2.amazonaws.com" "https://sms-voice.pinpoint.us-gov-west-1.amazonaws.com" "https://sms-voice.pinpoint.us-gov-east-1.amazonaws.com" "https://sms-voice.pinpoint.ca-central-1.amazonaws.com" "https://sms-voice.pinpoint.eu-north-1.amazonaws.com" "https://sms-voice.pinpoint.eu-west-1.amazonaws.com" "https://sms-voice.pinpoint.eu-west-2.amazonaws.com" "https://sms-voice.pinpoint.eu-west-3.amazonaws.com" "https://sms-voice.pinpoint.eu-central-1.amazonaws.com" "https://sms-voice.pinpoint.eu-south-1.amazonaws.com" "https://sms-voice.pinpoint.af-south-1.amazonaws.com" "https://sms-voice.pinpoint.ap-northeast-1.amazonaws.com" "https://sms-voice.pinpoint.ap-northeast-2.amazonaws.com" "https://sms-voice.pinpoint.ap-northeast-3.amazonaws.com" "https://sms-voice.pinpoint.ap-southeast-1.amazonaws.com" "https://sms-voice.pinpoint.ap-southeast-2.amazonaws.com" "https://sms-voice.pinpoint.ap-east-1.amazonaws.com" "https://sms-voice.pinpoint.ap-south-1.amazonaws.com" "https://sms-voice.pinpoint.sa-east-1.amazonaws.com" "https://sms-voice.pinpoint.me-south-1.amazonaws.com" "http://sms-voice.pinpoint.cn-north-1.amazonaws.com.cn" "http://sms-voice.pinpoint.cn-northwest-1.amazonaws.com.cn" "https://sms-voice.pinpoint.cn-north-1.amazonaws.com.cn" "https://sms-voice.pinpoint.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sms-voice-configuration-sets create" } } | get name | first)
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

# Create a new configuration set. After you create the configuration set, you can add one or more event destinations to it.
#
# POST /v1/sms-voice/configuration-sets
# operationId: CreateConfigurationSet
export def "sms-voice-configuration-sets create" [
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
  --configuration-set-name: string # The name that you want to give the configuration set.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sms-voice/configuration-sets")
  let body = {"ConfigurationSetName": $configuration_set_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all of the configuration sets associated with your Amazon Pinpoint account in the current region.
#
# GET /v1/sms-voice/configuration-sets
# operationId: ListConfigurationSets
export def "sms-voice-configuration-sets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A token returned from a previous call to the API that indicates the position in the list of results.
  --page-size: string # Used to specify the number of items that should be returned in the response.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ConfigurationSets: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "NextToken" $next_token "scalar") (serialize-qp "PageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sms-voice/configuration-sets" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new event destination in a configuration set.
#
# POST /v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations
# operationId: CreateConfigurationSetEventDestination
# --EventDestination shape: {CloudWatchLogsDestination?: record, Enabled?: any, KinesisFirehoseDestination?: record, MatchingEventTypes?: list, SnsDestination?: record}
export def "sms-voice-configuration-sets-event-destinations create" [
  configuration_set_name: string
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
  --event-destination: record # An object that defines a single event destination. — shape: {CloudWatchLogsDestination?: record, Enabled?: any, KinesisFirehoseDestination?: record, MatchingEventTypes?: list, SnsDestination?: record}
  --event-destination-name: string # A name that identifies the event destination.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({configuration_set_name: $configuration_set_name} | format pattern "/v1/sms-voice/configuration-sets/{configuration_set_name}/event-destinations"))
  let body = {"EventDestination": $event_destination, "EventDestinationName": $event_destination_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Obtain information about an event destination, including the types of events it reports, the Amazon Resource Name (ARN) of the destination, and the name of the event destination.
#
# GET /v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations
# operationId: GetConfigurationSetEventDestinations
export def "sms-voice-configuration-sets-event-destinations get" [
  configuration_set_name: string
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
]: nothing -> record<EventDestinations: table<CloudWatchLogsDestination: record, Enabled: record, KinesisFirehoseDestination: record, MatchingEventTypes: list, Name: record, SnsDestination: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({configuration_set_name: $configuration_set_name} | format pattern "/v1/sms-voice/configuration-sets/{configuration_set_name}/event-destinations"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing configuration set.
#
# DELETE /v1/sms-voice/configuration-sets/{ConfigurationSetName}
# operationId: DeleteConfigurationSet
export def "sms-voice-configuration-sets delete" [
  configuration_set_name: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({configuration_set_name: $configuration_set_name} | format pattern "/v1/sms-voice/configuration-sets/{configuration_set_name}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an event destination in a configuration set.
#
# DELETE /v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}
# operationId: DeleteConfigurationSetEventDestination
export def "sms-voice-configuration-sets-event-destinations delete" [
  configuration_set_name: string
  event_destination_name: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({configuration_set_name: $configuration_set_name, event_destination_name: $event_destination_name} | format pattern "/v1/sms-voice/configuration-sets/{configuration_set_name}/event-destinations/{event_destination_name}"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an event destination in a configuration set. An event destination is a location that you publish information about your voice calls to. For example, you can log an event to an Amazon CloudWatch destination when a call fails.
#
# PUT /v1/sms-voice/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}
# operationId: UpdateConfigurationSetEventDestination
# --EventDestination shape: {CloudWatchLogsDestination?: record, Enabled?: any, KinesisFirehoseDestination?: record, MatchingEventTypes?: list, SnsDestination?: record}
export def "sms-voice-configuration-sets-event-destinations update" [
  configuration_set_name: string
  event_destination_name: string
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
  --event-destination: record # An object that defines a single event destination. — shape: {CloudWatchLogsDestination?: record, Enabled?: any, KinesisFirehoseDestination?: record, MatchingEventTypes?: list, SnsDestination?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({configuration_set_name: $configuration_set_name, event_destination_name: $event_destination_name} | format pattern "/v1/sms-voice/configuration-sets/{configuration_set_name}/event-destinations/{event_destination_name}"))
  let body = {"EventDestination": $event_destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new voice message and send it to a recipient's phone number.
#
# POST /v1/sms-voice/voice/message
# operationId: SendVoiceMessage
# --Content shape: {CallInstructionsMessage?: record, PlainTextMessage?: record, SSMLMessage?: record}
export def "sms-voice-voice-message send" [
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
  --caller-id: string # The phone number that appears on recipients' devices when they receive the message.
  --configuration-set-name: string # The name of the configuration set that you want to use to send the message.
  --content: record # An object that contains a voice message and information about the recipient that you want to send it to. — shape: {CallInstructionsMessage?: record, PlainTextMessage?: record, SSMLMessage?: record}
  --destination-phone-number: string # The phone number that you want to send the voice message to.
  --origination-phone-number: string # The phone number that Amazon Pinpoint should use to send the voice message. This isn't necessarily the phone number that appears on recipients' devices when they receive the message, because you can specify a CallerId parameter in the request.
]: any -> record<MessageId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sms-voice/voice/message")
  let body = {"CallerId": $caller_id, "ConfigurationSetName": $configuration_set_name, "Content": $content, "DestinationPhoneNumber": $destination_phone_number, "OriginationPhoneNumber": $origination_phone_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
