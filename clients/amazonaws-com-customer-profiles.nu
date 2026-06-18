# Auto-generated client for Amazon Connect Customer Profiles v2020-08-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/customer-profiles/2020-08-15/openapi.json
# Auth: --token flag or $env.AMAZON_CONNECT_CUSTOMER_PROFILES_TOKEN

const BASE_URL = "http://profile.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_CONNECT_CUSTOMER_PROFILES_TOKEN | default "" }
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

def base-url-completer [] { ["http://profile.us-east-1.amazonaws.com" "http://profile.us-east-2.amazonaws.com" "http://profile.us-west-1.amazonaws.com" "http://profile.us-west-2.amazonaws.com" "http://profile.us-gov-west-1.amazonaws.com" "http://profile.us-gov-east-1.amazonaws.com" "http://profile.ca-central-1.amazonaws.com" "http://profile.eu-north-1.amazonaws.com" "http://profile.eu-west-1.amazonaws.com" "http://profile.eu-west-2.amazonaws.com" "http://profile.eu-west-3.amazonaws.com" "http://profile.eu-central-1.amazonaws.com" "http://profile.eu-south-1.amazonaws.com" "http://profile.af-south-1.amazonaws.com" "http://profile.ap-northeast-1.amazonaws.com" "http://profile.ap-northeast-2.amazonaws.com" "http://profile.ap-northeast-3.amazonaws.com" "http://profile.ap-southeast-1.amazonaws.com" "http://profile.ap-southeast-2.amazonaws.com" "http://profile.ap-east-1.amazonaws.com" "http://profile.ap-south-1.amazonaws.com" "http://profile.sa-east-1.amazonaws.com" "http://profile.me-south-1.amazonaws.com" "https://profile.us-east-1.amazonaws.com" "https://profile.us-east-2.amazonaws.com" "https://profile.us-west-1.amazonaws.com" "https://profile.us-west-2.amazonaws.com" "https://profile.us-gov-west-1.amazonaws.com" "https://profile.us-gov-east-1.amazonaws.com" "https://profile.ca-central-1.amazonaws.com" "https://profile.eu-north-1.amazonaws.com" "https://profile.eu-west-1.amazonaws.com" "https://profile.eu-west-2.amazonaws.com" "https://profile.eu-west-3.amazonaws.com" "https://profile.eu-central-1.amazonaws.com" "https://profile.eu-south-1.amazonaws.com" "https://profile.af-south-1.amazonaws.com" "https://profile.ap-northeast-1.amazonaws.com" "https://profile.ap-northeast-2.amazonaws.com" "https://profile.ap-northeast-3.amazonaws.com" "https://profile.ap-southeast-1.amazonaws.com" "https://profile.ap-southeast-2.amazonaws.com" "https://profile.ap-east-1.amazonaws.com" "https://profile.ap-south-1.amazonaws.com" "https://profile.sa-east-1.amazonaws.com" "https://profile.me-south-1.amazonaws.com" "http://profile.cn-north-1.amazonaws.com.cn" "http://profile.cn-northwest-1.amazonaws.com.cn" "https://profile.cn-north-1.amazonaws.com.cn" "https://profile.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def workflow-type-completer [] { ["APPFLOW_INTEGRATION"] }
def party-type-completer [] { ["BUSINESS" "INDIVIDUAL" "OTHER"] }
def gender-completer [] { ["FEMALE" "MALE" "UNSPECIFIED"] }
def status-completer [] { ["CANCELLED" "COMPLETE" "FAILED" "IN_PROGRESS" "NOT_STARTED" "RETRY" "SPLIT"] }
def logical-operator-completer [] { ["AND" "OR"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains-profiles-keys create" } } | get name | first)
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

# Associates a new key value with a specific profile, such as a Contact Record ContactId. A profile object can have a single unique key and any number of additional keys that can be used to identify the profile that it belongs to.
#
# POST /domains/{DomainName}/profiles/keys
# operationId: AddProfileKey
export def "domains-profiles-keys create" [
  domain_name: string
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
  profile_id: string # The unique identifier of a customer profile.
  key_name: string # A searchable identifier of a customer profile. The predefined keys you can use include: _account, _profileId, _assetId, _caseId, _orderId, _fullName, _phone, _email, _ctrContactId, _marketoLeadId, _salesforceAccountId, _salesforceContactId, _salesforceAssetId, _zendeskUserId, _zendeskExternalId, _zendeskTicketId, _serviceNowSystemId, _serviceNowIncidentId, _segmentUserId, _shopifyCustomerId, _shopifyOrderId.
  values: list<string> # A list of key values.
]: any -> record<KeyName: record, Values: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/keys"))
  let req_body = {"ProfileId": $profile_id, "KeyName": $key_name, "Values": $values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a domain, which is a container for all customer data, such as customer profile attributes, object types, profile keys, and encryption keys. You can create multiple domains, and each domain can have multiple third-party integrations. Each Amazon Connect instance can be associated with only one domain. Multiple Amazon Connect instances can be associated with one domain. Use this API or UpdateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UpdateDomain.html) to enable identity resolution (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html): set Matching to true. To prevent cross-service impersonation when you call this API, see Cross-service confused deputy prevention (https://docs.aws.amazon.com/connect/latest/adminguide/cross-service-confused-deputy-prevention.html) for sample policies that you should apply.
#
# POST /domains/{DomainName}
# operationId: CreateDomain
# --Matching shape: {Enabled?: any, JobSchedule?: any, AutoMerging?: any, ExportingConfig?: any}
export def "domains create" [
  domain_name: string
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
  default_expiration_days: int # The default number of days until the data within the domain expires.
  --default-encryption-key: string # The default encryption key, which is an AWS managed key, is used when no specific type of encryption key is specified. It is used to encrypt all data before it is placed in permanent or semi-permanent storage.
  --dead-letter-queue-url: string # The URL of the SQS dead letter queue, which is used for reporting errors associated with ingesting data from third party applications. You must set up a policy on the DeadLetterQueue for the SendMessage operation to enable Amazon Connect Customer Profiles to send messages to the DeadLetterQueue.
  --matching: record # The flag that enables the matching process of duplicate profiles. — shape: {Enabled?: any, JobSchedule?: any, AutoMerging?: any, ExportingConfig?: any}
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> record<DomainName: record, DefaultExpirationDays: record, DefaultEncryptionKey: record, DeadLetterQueueUrl: record, Matching: record<Enabled: record, JobSchedule: record<DayOfTheWeek: record, Time: record>, AutoMerging: record<Enabled: record, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: record>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: record, LastUpdatedAt: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}"))
  let req_body = {"DefaultExpirationDays": $default_expiration_days, "DefaultEncryptionKey": $default_encryption_key, "DeadLetterQueueUrl": $dead_letter_queue_url, "Matching": $matching, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a specific domain and all of its customer data, such as customer profile attributes and their related objects.
#
# DELETE /domains/{DomainName}
# operationId: DeleteDomain
export def "domains delete" [
  domain_name: string
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
]: nothing -> record<Message: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a specific domain.
#
# GET /domains/{DomainName}
# operationId: GetDomain
export def "domains get" [
  domain_name: string
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
]: nothing -> record<DomainName: record, DefaultExpirationDays: record, DefaultEncryptionKey: record, DeadLetterQueueUrl: record, Stats: record<ProfileCount: record, MeteringProfileCount: record, ObjectCount: record, TotalSize: record>, Matching: record<Enabled: record, JobSchedule: record<DayOfTheWeek: record, Time: record>, AutoMerging: record<Enabled: record, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: record>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: record, LastUpdatedAt: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the properties of a domain, including creating or selecting a dead letter queue or an encryption key. After a domain is created, the name can’t be changed. Use this API or CreateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_CreateDomain.html) to enable identity resolution (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html): set Matching to true. To prevent cross-service impersonation when you call this API, see Cross-service confused deputy prevention (https://docs.aws.amazon.com/connect/latest/adminguide/cross-service-confused-deputy-prevention.html) for sample policies that you should apply. To add or remove tags on an existing Domain, see TagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_TagResource.html)/UntagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UntagResource.html).
#
# PUT /domains/{DomainName}
# operationId: UpdateDomain
# --Matching shape: {Enabled?: any, JobSchedule?: any, AutoMerging?: any, ExportingConfig?: any}
export def "domains update" [
  domain_name: string
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
  --default-expiration-days: int # The default number of days until the data within the domain expires.
  --default-encryption-key: string # The default encryption key, which is an AWS managed key, is used when no specific type of encryption key is specified. It is used to encrypt all data before it is placed in permanent or semi-permanent storage. If specified as an empty string, it will clear any existing value.
  --dead-letter-queue-url: string # The URL of the SQS dead letter queue, which is used for reporting errors associated with ingesting data from third party applications. If specified as an empty string, it will clear any existing value. You must set up a policy on the DeadLetterQueue for the SendMessage operation to enable Amazon Connect Customer Profiles to send messages to the DeadLetterQueue.
  --matching: record # The flag that enables the matching process of duplicate profiles. — shape: {Enabled?: any, JobSchedule?: any, AutoMerging?: any, ExportingConfig?: any}
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> record<DomainName: record, DefaultExpirationDays: record, DefaultEncryptionKey: record, DeadLetterQueueUrl: record, Matching: record<Enabled: record, JobSchedule: record<DayOfTheWeek: record, Time: record>, AutoMerging: record<Enabled: record, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: record>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: record, LastUpdatedAt: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}"))
  let req_body = {"DefaultExpirationDays": $default_expiration_days, "DefaultEncryptionKey": $default_encryption_key, "DeadLetterQueueUrl": $dead_letter_queue_url, "Matching": $matching, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an integration workflow. An integration workflow is an async process which ingests historic data and sets up an integration for ongoing updates. The supported Amazon AppFlow sources are Salesforce, ServiceNow, and Marketo.
#
# POST /domains/{DomainName}/workflows/integrations
# operationId: CreateIntegrationWorkflow
# --IntegrationConfig shape: {AppflowIntegration?: any}
export def "domains-workflows-integrations create" [
  domain_name: string
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
  workflow_type: string@workflow-type-completer # The type of workflow. The only supported value is APPFLOW_INTEGRATION.
  integration_config: record # Configuration data for integration workflow. — shape: {AppflowIntegration?: any}
  object_type_name: string # The name of the profile object type.
  role_arn: string # The Amazon Resource Name (ARN) of the IAM role. Customer Profiles assumes this role to create resources on your behalf as part of workflow execution.
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> record<WorkflowId: record, Message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/workflows/integrations"))
  let req_body = {"WorkflowType": $workflow_type, "IntegrationConfig": $integration_config, "ObjectTypeName": $object_type_name, "RoleArn": $role_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a standard profile. A standard profile represents the following attributes for a customer profile in a domain.
#
# POST /domains/{DomainName}/profiles
# operationId: CreateProfile
# --Address shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
# --ShippingAddress shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
# --MailingAddress shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
# --BillingAddress shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
@deprecated --flag party-type
@deprecated --flag gender
export def "domains-profiles create" [
  domain_name: string
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
  --account-number: string # A unique account number that you have given to the customer.
  --additional-information: string # Any additional information relevant to the customer’s profile.
  --party-type: string@party-type-completer # The type of profile used to describe the customer. (DEPRECATED)
  --business-name: string # The name of the customer’s business.
  --first-name: string # The customer’s first name.
  --middle-name: string # The customer’s middle name.
  --last-name: string # The customer’s last name.
  --birth-date: string # The customer’s birth date.
  --gender: string@gender-completer # The gender with which the customer identifies. (DEPRECATED)
  --phone-number: string # The customer’s phone number, which has not been specified as a mobile, home, or business number.
  --mobile-phone-number: string # The customer’s mobile phone number.
  --home-phone-number: string # The customer’s home phone number.
  --business-phone-number: string # The customer’s business phone number.
  --email-address: string # The customer’s email address, which has not been specified as a personal or business address.
  --personal-email-address: string # The customer’s personal email address.
  --business-email-address: string # The customer’s business email address.
  --address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --shipping-address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --mailing-address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --billing-address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --attributes: record # A key value pair of attributes of a customer profile.
  --party-type-string: string # An alternative to PartyType which accepts any string as input.
  --gender-string: string # An alternative to Gender which accepts any string as input.
]: any -> record<ProfileId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles"))
  let req_body = {"AccountNumber": $account_number, "AdditionalInformation": $additional_information, "PartyType": $party_type, "BusinessName": $business_name, "FirstName": $first_name, "MiddleName": $middle_name, "LastName": $last_name, "BirthDate": $birth_date, "Gender": $gender, "PhoneNumber": $phone_number, "MobilePhoneNumber": $mobile_phone_number, "HomePhoneNumber": $home_phone_number, "BusinessPhoneNumber": $business_phone_number, "EmailAddress": $email_address, "PersonalEmailAddress": $personal_email_address, "BusinessEmailAddress": $business_email_address, "Address": $address, "ShippingAddress": $shipping_address, "MailingAddress": $mailing_address, "BillingAddress": $billing_address, "Attributes": $attributes, "PartyTypeString": $party_type_string, "GenderString": $gender_string} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the properties of a profile. The ProfileId is required for updating a customer profile. When calling the UpdateProfile API, specifying an empty string value means that any existing value will be removed. Not specifying a string value means that any value already there will be kept.
#
# PUT /domains/{DomainName}/profiles
# operationId: UpdateProfile
# --Address shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
# --ShippingAddress shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
# --MailingAddress shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
# --BillingAddress shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
@deprecated --flag party-type
@deprecated --flag gender
export def "domains-profiles update" [
  domain_name: string
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
  profile_id: string # The unique identifier of a customer profile.
  --additional-information: string # Any additional information relevant to the customer’s profile.
  --account-number: string # A unique account number that you have given to the customer.
  --party-type: string@party-type-completer # The type of profile used to describe the customer. (DEPRECATED)
  --business-name: string # The name of the customer’s business.
  --first-name: string # The customer’s first name.
  --middle-name: string # The customer’s middle name.
  --last-name: string # The customer’s last name.
  --birth-date: string # The customer’s birth date.
  --gender: string@gender-completer # The gender with which the customer identifies. (DEPRECATED)
  --phone-number: string # The customer’s phone number, which has not been specified as a mobile, home, or business number.
  --mobile-phone-number: string # The customer’s mobile phone number.
  --home-phone-number: string # The customer’s home phone number.
  --business-phone-number: string # The customer’s business phone number.
  --email-address: string # The customer’s email address, which has not been specified as a personal or business address.
  --personal-email-address: string # The customer’s personal email address.
  --business-email-address: string # The customer’s business email address.
  --address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --shipping-address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --mailing-address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --billing-address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: any, Address2?: any, Address3?: any, Address4?: any, City?: any, County?: any, State?: any, Province?: any, Country?: any, PostalCode?: any}
  --attributes: record # A key value pair of attributes of a customer profile.
  --party-type-string: string # An alternative to PartyType which accepts any string as input.
  --gender-string: string # An alternative to Gender which accepts any string as input.
]: any -> record<ProfileId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles"))
  let req_body = {"ProfileId": $profile_id, "AdditionalInformation": $additional_information, "AccountNumber": $account_number, "PartyType": $party_type, "BusinessName": $business_name, "FirstName": $first_name, "MiddleName": $middle_name, "LastName": $last_name, "BirthDate": $birth_date, "Gender": $gender, "PhoneNumber": $phone_number, "MobilePhoneNumber": $mobile_phone_number, "HomePhoneNumber": $home_phone_number, "BusinessPhoneNumber": $business_phone_number, "EmailAddress": $email_address, "PersonalEmailAddress": $personal_email_address, "BusinessEmailAddress": $business_email_address, "Address": $address, "ShippingAddress": $shipping_address, "MailingAddress": $mailing_address, "BillingAddress": $billing_address, "Attributes": $attributes, "PartyTypeString": $party_type_string, "GenderString": $gender_string} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes an integration from a specific domain.
#
# POST /domains/{DomainName}/integrations/delete
# operationId: DeleteIntegration
export def "domains-integrations-delete delete" [
  domain_name: string
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
  uri: string # The URI of the S3 bucket or any other type of data source.
]: any -> record<Message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/integrations/delete"))
  let req_body = {"Uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the standard customer profile and all data pertaining to the profile.
#
# POST /domains/{DomainName}/profiles/delete
# operationId: DeleteProfile
export def "domains-profiles-delete delete" [
  domain_name: string
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
  profile_id: string # The unique identifier of a customer profile.
]: any -> record<Message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/delete"))
  let req_body = {"ProfileId": $profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a searchable key from a customer profile.
#
# POST /domains/{DomainName}/profiles/keys/delete
# operationId: DeleteProfileKey
export def "domains-profiles-keys-delete delete" [
  domain_name: string
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
  profile_id: string # The unique identifier of a customer profile.
  key_name: string # A searchable identifier of a customer profile.
  values: list<string> # A list of key values.
]: any -> record<Message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/keys/delete"))
  let req_body = {"ProfileId": $profile_id, "KeyName": $key_name, "Values": $values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes an object associated with a profile of a given ProfileObjectType.
#
# POST /domains/{DomainName}/profiles/objects/delete
# operationId: DeleteProfileObject
export def "domains-profiles-objects-delete delete" [
  domain_name: string
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
  profile_id: string # The unique identifier of a customer profile.
  profile_object_unique_key: string # The unique identifier of the profile object generated by the service.
  object_type_name: string # The name of the profile object type.
]: any -> record<Message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/objects/delete"))
  let req_body = {"ProfileId": $profile_id, "ProfileObjectUniqueKey": $profile_object_unique_key, "ObjectTypeName": $object_type_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a ProfileObjectType from a specific domain as well as removes all the ProfileObjects of that type. It also disables integrations from this specific ProfileObjectType. In addition, it scrubs all of the fields of the standard profile that were populated from this ProfileObjectType.
#
# DELETE /domains/{DomainName}/object-types/{ObjectTypeName}
# operationId: DeleteProfileObjectType
export def "domains-object-types delete-profile" [
  domain_name: string
  object_type_name: string
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
]: nothing -> record<Message: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), object_type_name: (encode-path-segment $object_type_name)} | format pattern "/domains/{domain_name}/object-types/{object_type_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the object types for a specific domain.
#
# GET /domains/{DomainName}/object-types/{ObjectTypeName}
# operationId: GetProfileObjectType
export def "domains-object-types get-profile" [
  domain_name: string
  object_type_name: string
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
]: nothing -> record<ObjectTypeName: record, Description: record, TemplateId: record, ExpirationDays: record, EncryptionKey: record, AllowProfileCreation: record, SourceLastUpdatedTimestampFormat: record, Fields: record, Keys: record, CreatedAt: record, LastUpdatedAt: record, Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), object_type_name: (encode-path-segment $object_type_name)} | format pattern "/domains/{domain_name}/object-types/{object_type_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Defines a ProfileObjectType. To add or remove tags on an existing ObjectType, see TagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_TagResource.html)/UntagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UntagResource.html).
#
# PUT /domains/{DomainName}/object-types/{ObjectTypeName}
# operationId: PutProfileObjectType
export def "domains-object-types update-profile" [
  domain_name: string
  object_type_name: string
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
  description: string # Description of the profile object type.
  --template-id: string # A unique identifier for the object template. For some attributes in the request, the service will use the default value from the object template when TemplateId is present. If these attributes are present in the request, the service may return a BadRequestException. These attributes include: AllowProfileCreation, SourceLastUpdatedTimestampFormat, Fields, and Keys. For example, if AllowProfileCreation is set to true when TemplateId is set, the service may return a BadRequestException.
  --expiration-days: int # The number of days until the data in the object expires.
  --encryption-key: string # The customer-provided key to encrypt the profile object that will be created in this profile object type.
  --allow-profile-creation: oneof<nothing, bool> # Indicates whether a profile should be created when data is received if one doesn’t exist for an object of this type. The default is FALSE. If the AllowProfileCreation flag is set to FALSE, then the service tries to fetch a standard profile and associate this object with the profile. If it is set to TRUE, and if no match is found, then the service creates a new standard profile.
  --source-last-updated-timestamp-format: string # The format of your sourceLastUpdatedTimestamp that was previously set up.
  --fields: record # A map of the name and ObjectType field.
  --keys: record # A list of unique keys that can be used to map data to the profile.
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> record<ObjectTypeName: record, Description: record, TemplateId: record, ExpirationDays: record, EncryptionKey: record, AllowProfileCreation: record, SourceLastUpdatedTimestampFormat: record, Fields: record, Keys: record, CreatedAt: record, LastUpdatedAt: record, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), object_type_name: (encode-path-segment $object_type_name)} | format pattern "/domains/{domain_name}/object-types/{object_type_name}"))
  let req_body = {"Description": $description, "TemplateId": $template_id, "ExpirationDays": $expiration_days, "EncryptionKey": $encryption_key, "AllowProfileCreation": $allow_profile_creation, "SourceLastUpdatedTimestampFormat": $source_last_updated_timestamp_format, "Fields": $fields, "Keys": $keys, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified workflow and all its corresponding resources. This is an async process.
#
# DELETE /domains/{DomainName}/workflows/{WorkflowId}
# operationId: DeleteWorkflow
export def "domains-workflows delete" [
  domain_name: string
  workflow_id: string
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
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), workflow_id: (encode-path-segment $workflow_id)} | format pattern "/domains/{domain_name}/workflows/{workflow_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of specified workflow.
#
# GET /domains/{DomainName}/workflows/{WorkflowId}
# operationId: GetWorkflow
export def "domains-workflows get" [
  domain_name: string
  workflow_id: string
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
]: nothing -> record<WorkflowId: record, WorkflowType: record, Status: record, ErrorDescription: record, StartDate: record, LastUpdatedAt: record, Attributes: record<AppflowIntegration: record<SourceConnectorType: record, ConnectorProfileName: record, RoleArn: record>>, Metrics: record<AppflowIntegration: record<RecordsProcessed: record, StepsCompleted: record, TotalSteps: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), workflow_id: (encode-path-segment $workflow_id)} | format pattern "/domains/{domain_name}/workflows/{workflow_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tests the auto-merging settings of your Identity Resolution Job without merging your data. It randomly selects a sample of matching groups from the existing matching results, and applies the automerging settings that you provided. You can then view the number of profiles in the sample, the number of matches, and the number of profiles identified to be merged. This enables you to evaluate the accuracy of the attributes in your matching list. You can't view which profiles are matched and would be merged. We strongly recommend you use this API to do a dry run of the automerging process before running the Identity Resolution Job. Include at least two matching attributes. If your matching list includes too few attributes (such as only FirstName or only LastName), there may be a large number of matches. This increases the chances of erroneous merges.
#
# POST /domains/{DomainName}/identity-resolution-jobs/auto-merging-preview
# operationId: GetAutoMergingPreview
# --Consolidation shape: {MatchingAttributesList?: any}
# --ConflictResolution shape: {ConflictResolvingModel?: any, SourceName?: any}
export def "domains-identity-resolution-jobs-auto-merging-preview get" [
  domain_name: string
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
  consolidation: record # The matching criteria to be used during the auto-merging process. — shape: {MatchingAttributesList?: any}
  conflict_resolution: record # How the auto-merging process should resolve conflicts between different profiles. — shape: {ConflictResolvingModel?: any, SourceName?: any}
  --min-allowed-confidence-score-for-merging: float # Minimum confidence score required for profiles within a matching group to be merged during the auto-merge process. (format: double)
]: any -> record<DomainName: record, NumberOfMatchesInSample: record, NumberOfProfilesInSample: record, NumberOfProfilesWillBeMerged: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/identity-resolution-jobs/auto-merging-preview"))
  let req_body = {"Consolidation": $consolidation, "ConflictResolution": $conflict_resolution, "MinAllowedConfidenceScoreForMerging": $min_allowed_confidence_score_for_merging} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about an Identity Resolution Job in a specific domain. Identity Resolution Jobs are set up using the Amazon Connect admin console. For more information, see Use Identity Resolution to consolidate similar profiles (https://docs.aws.amazon.com/connect/latest/adminguide/use-identity-resolution.html).
#
# GET /domains/{DomainName}/identity-resolution-jobs/{JobId}
# operationId: GetIdentityResolutionJob
export def "domains-identity-resolution-jobs get" [
  domain_name: string
  job_id: string
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
]: nothing -> record<DomainName: record, JobId: record, Status: record, Message: record, JobStartTime: record, JobEndTime: record, LastUpdatedAt: record, JobExpirationTime: record, AutoMerging: record<Enabled: record, Consolidation: record<MatchingAttributesList: record>, ConflictResolution: record<ConflictResolvingModel: record, SourceName: record>, MinAllowedConfidenceScoreForMerging: record>, ExportingLocation: record<S3Exporting: record<S3BucketName: record, S3KeyName: record>>, JobStats: record<NumberOfProfilesReviewed: record, NumberOfMatchesFound: record, NumberOfMergesDone: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), job_id: (encode-path-segment $job_id)} | format pattern "/domains/{domain_name}/identity-resolution-jobs/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an integration for a domain.
#
# POST /domains/{DomainName}/integrations
# operationId: GetIntegration
export def "domains-integrations get" [
  domain_name: string
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
  uri: string # The URI of the S3 bucket or any other type of data source.
]: any -> record<DomainName: record, Uri: record, ObjectTypeName: record, CreatedAt: record, LastUpdatedAt: record, Tags: record, ObjectTypeNames: record, WorkflowId: record, IsUnstructured: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/integrations"))
  let req_body = {"Uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all of the integrations in your domain.
#
# GET /domains/{DomainName}/integrations
# operationId: ListIntegrations
export def "domains-integrations list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous ListIntegrations API call.
  --max-results: int # The maximum number of objects returned per page.
  --include-hidden: oneof<nothing, bool> # Boolean to indicate if hidden integration should be returned. Defaults to False.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include-hidden" $include_hidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/integrations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds an integration between the service and a third-party service, which includes Amazon AppFlow and Amazon Connect. An integration can belong to only one domain. To add or remove tags on an existing Integration, see TagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_TagResource.html)/ UntagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UntagResource.html).
#
# PUT /domains/{DomainName}/integrations
# operationId: PutIntegration
# --FlowDefinition shape: {Description?: any, FlowName?: any, KmsArn?: any, SourceFlowConfig?: any, Tasks?: any, TriggerConfig?: any}
export def "domains-integrations update" [
  domain_name: string
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
  --uri: string # The URI of the S3 bucket or any other type of data source.
  --object-type-name: string # The name of the profile object type.
  --tags: record # The tags used to organize, track, or control access for this resource.
  --flow-definition: record # The configurations that control how Customer Profiles retrieves data from the source, Amazon AppFlow. Customer Profiles uses this information to create an AppFlow flow on behalf of customers. — shape: {Description?: any, FlowName?: any, KmsArn?: any, SourceFlowConfig?: any, Tasks?: any, TriggerConfig?: any}
  --object-type-names: record # A map in which each key is an event type from an external application such as Segment or Shopify, and each value is an ObjectTypeName (template) used to ingest the event. It supports the following event types: SegmentIdentify, ShopifyCreateCustomers, ShopifyUpdateCustomers, ShopifyCreateDraftOrders, ShopifyUpdateDraftOrders, ShopifyCreateOrders, and ShopifyUpdatedOrders.
]: any -> record<DomainName: record, Uri: record, ObjectTypeName: record, CreatedAt: record, LastUpdatedAt: record, Tags: record, ObjectTypeNames: record, WorkflowId: record, IsUnstructured: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/integrations"))
  let req_body = {"Uri": $uri, "ObjectTypeName": $object_type_name, "Tags": $tags, "FlowDefinition": $flow_definition, "ObjectTypeNames": $object_type_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Before calling this API, use CreateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_CreateDomain.html) or UpdateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UpdateDomain.html) to enable identity resolution: set Matching to true. GetMatches returns potentially matching profiles, based on the results of the latest run of a machine learning process. The process of matching duplicate profiles. If Matching = true, Amazon Connect Customer Profiles starts a weekly batch process called Identity Resolution Job. If you do not specify a date and time for Identity Resolution Job to run, by default it runs every Saturday at 12AM UTC to detect duplicate profiles in your domains. After the Identity Resolution Job completes, use the GetMatches (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html) API to return and review the results. Or, if you have configured ExportingConfig in the MatchingRequest, you can download the results from S3. Amazon Connect uses the following profile attributes to identify matches: PhoneNumber HomePhoneNumber BusinessPhoneNumber MobilePhoneNumber EmailAddress PersonalEmailAddress BusinessEmailAddress FullName For example, two or more profiles—with spelling mistakes such as John Doe and Jhn Doe, or different casing email addresses such as JOHN_DOE@ANYCOMPANY.COM and johndoe@anycompany.com, or different phone number formats such as 555-010-0000 and +1-555-010-0000—can be detected as belonging to the same customer John Doe and merged into a unified profile.
#
# GET /domains/{DomainName}/matches
# operationId: GetMatches
export def "domains-matches get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<NextToken: record, MatchGenerationDate: record, PotentialMatches: record, Matches: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the template information for a specific object type. A template is a predefined ProfileObjectType, such as “Salesforce-Account” or “Salesforce-Contact.” When a user sends a ProfileObject, using the PutProfileObject API, with an ObjectTypeName that matches one of the TemplateIds, it uses the mappings from the template.
#
# GET /templates/{TemplateId}
# operationId: GetProfileObjectTypeTemplate
export def "templates get-profile-object-type" [
  template_id: string
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
]: nothing -> record<TemplateId: record, SourceName: record, SourceObject: record, AllowProfileCreation: record, SourceLastUpdatedTimestampFormat: record, Fields: record, Keys: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/templates/{template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get granular list of steps in workflow.
#
# GET /domains/{DomainName}/workflows/{WorkflowId}/steps
# operationId: GetWorkflowSteps
export def "domains-workflows-steps get" [
  domain_name: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<WorkflowId: record, WorkflowType: record, Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), workflow_id: (encode-path-segment $workflow_id)} | format pattern "/domains/{domain_name}/workflows/{workflow_id}/steps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the integrations associated to a specific URI in the AWS account.
#
# POST /integrations
# operationId: ListAccountIntegrations
export def "integrations list-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous ListAccountIntegrations API call.
  --max-results: int # The maximum number of objects returned per page.
  --include-hidden: oneof<nothing, bool> # Boolean to indicate if hidden integration should be returned. Defaults to False.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  uri: string # The URI of the S3 bucket or any other type of data source.
]: any -> record<Items: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "include-hidden" $include_hidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/integrations" $qp)
  let req_body = {"Uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of all the domains for an AWS account that have been created.
#
# GET /domains
# operationId: ListDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous ListDomain API call.
  --max-results: int # The maximum number of objects returned per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the Identity Resolution Jobs in your domain. The response sorts the list by JobStartTime.
#
# GET /domains/{DomainName}/identity-resolution-jobs
# operationId: ListIdentityResolutionJobs
export def "domains-identity-resolution-jobs list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<IdentityResolutionJobsList: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/identity-resolution-jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the template information for object types.
#
# GET /templates
# operationId: ListProfileObjectTypeTemplates
export def "templates list-profile-object-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous ListObjectTypeTemplates API call.
  --max-results: int # The maximum number of objects returned per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the templates available within the service.
#
# GET /domains/{DomainName}/object-types
# operationId: ListProfileObjectTypes
export def "domains-object-types list-profile" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Identifies the next page of results to return.
  --max-results: int # The maximum number of objects returned per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Items: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/object-types") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of objects associated with a profile of a given ProfileObjectType.
#
# POST /domains/{DomainName}/profiles/objects
# operationId: ListProfileObjects
# --ObjectFilter shape: {KeyName?: any, Values?: any}
export def "domains-profiles-objects list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous call to ListProfileObjects.
  --max-results: int # The maximum number of objects returned per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  object_type_name: string # The name of the profile object type.
  profile_id: string # The unique identifier of a customer profile.
  --object-filter: record # The filter applied to ListProfileObjects response to include profile objects with the specified index values. This filter is only supported for ObjectTypeName _asset, _case and _order. — shape: {KeyName?: any, Values?: any}
]: any -> record<Items: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/objects") $qp)
  let req_body = {"ObjectTypeName": $object_type_name, "ProfileId": $profile_id, "ObjectFilter": $object_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds additional objects to customer profiles of a given ObjectType. When adding a specific profile object, like a Contact Record, an inferred profile can get created if it is not mapped to an existing profile. The resulting profile will only have a phone number populated in the standard ProfileObject. Any additional Contact Records with the same phone number will be mapped to the same inferred profile. When a ProfileObject is created and if a ProfileObjectType already exists for the ProfileObject, it will provide data to a standard profile depending on the ProfileObjectType definition. PutProfileObject needs an ObjectType, which can be created using PutProfileObjectType.
#
# PUT /domains/{DomainName}/profiles/objects
# operationId: PutProfileObject
export def "domains-profiles-objects update" [
  domain_name: string
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
  object_type_name: string # The name of the profile object type.
  object: string # A string that is serialized from a JSON object.
]: any -> record<ProfileObjectUniqueKey: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/objects"))
  let req_body = {"ObjectTypeName": $object_type_name, "Object": $object} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Displays the tags associated with an Amazon Connect Customer Profiles resource. In Connect Customer Profiles, domains, profile object types, and integrations can be tagged.
#
# GET /tags/{resourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
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
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns one or more tags (key-value pairs) to the specified Amazon Connect Customer Profiles resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In Connect Customer Profiles, domains, profile object types, and integrations can be tagged. Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters. You can use the TagResource action with a resource that already has tags. If you specify a new tag key, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag. You can associate as many as 50 tags with a resource.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
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
  tags: record # The tags used to organize, track, or control access for this resource.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Query to list all workflows.
#
# POST /domains/{DomainName}/workflows
# operationId: ListWorkflows
export def "domains-workflows list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --workflow-type: string@workflow-type-completer # The type of workflow. The only supported value is APPFLOW_INTEGRATION.
  --status: string@status-completer # Status of workflow execution.
  --query-start-date: string # Retrieve workflows started after timestamp. (format: date-time)
  --query-end-date: string # Retrieve workflows ended after timestamp. (format: date-time)
]: any -> record<Items: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/workflows") $qp)
  let req_body = {"WorkflowType": $workflow_type, "Status": $status, "QueryStartDate": $query_start_date, "QueryEndDate": $query_end_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Runs an AWS Lambda job that does the following: All the profileKeys in the ProfileToBeMerged will be moved to the main profile. All the objects in the ProfileToBeMerged will be moved to the main profile. All the ProfileToBeMerged will be deleted at the end. All the profileKeys in the ProfileIdsToBeMerged will be moved to the main profile. Standard fields are merged as follows: Fields are always "union"-ed if there are no conflicts in standard fields or attributeKeys. When there are conflicting fields: If no SourceProfileIds entry is specified, the main Profile value is always taken. If a SourceProfileIds entry is specified, the specified profileId is always taken, even if it is a NULL value. You can use MergeProfiles together with GetMatches (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html), which returns potentially matching profiles, or use it with the results of another matching system. After profiles have been merged, they cannot be separated (unmerged).
#
# POST /domains/{DomainName}/profiles/objects/merge
# operationId: MergeProfiles
# --FieldSourceProfileIds shape: {AccountNumber?: any, AdditionalInformation?: any, PartyType?: any, BusinessName?: any, FirstName?: any, MiddleName?: any, LastName?: any, BirthDate?: any, Gender?: any, PhoneNumber?: any, MobilePhoneNumber?: any, HomePhoneNumber?: any, BusinessPhoneNumber?: any, EmailAddress?: any, PersonalEmailAddress?: any, BusinessEmailAddress?: any, Address?: any, ShippingAddress?: any, MailingAddress?: any, BillingAddress?: any, Attributes?: any}
export def "domains-profiles-objects-merge create" [
  domain_name: string
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
  main_profile_id: string # The identifier of the profile to be taken.
  profile_ids_to_be_merged: list<string> # The identifier of the profile to be merged into MainProfileId.
  --field-source-profile-ids: record # A duplicate customer profile that is to be merged into a main profile. — shape: {AccountNumber?: any, AdditionalInformation?: any, PartyType?: any, BusinessName?: any, FirstName?: any, MiddleName?: any, LastName?: any, BirthDate?: any, Gender?: any, PhoneNumber?: any, MobilePhoneNumber?: any, HomePhoneNumber?: any, BusinessPhoneNumber?: any, EmailAddress?: any, PersonalEmailAddress?: any, BusinessEmailAddress?: any, Address?: any, ShippingAddress?: any, MailingAddress?: any, BillingAddress?: any, Attributes?: any}
]: any -> record<Message: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/objects/merge"))
  let req_body = {"MainProfileId": $main_profile_id, "ProfileIdsToBeMerged": $profile_ids_to_be_merged, "FieldSourceProfileIds": $field_source_profile_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Searches for profiles within a specific domain using one or more predefined search keys (e.g., _fullName, _phone, _email, _account, etc.) and/or custom-defined search keys. A search key is a data type pair that consists of a KeyName and Values list. This operation supports searching for profiles with a minimum of 1 key-value(s) pair and up to 5 key-value(s) pairs using either AND or OR logic.
#
# POST /domains/{DomainName}/profiles/search
# operationId: SearchProfiles
# --AdditionalSearchKeys item shape: {KeyName: any, Values: any}
export def "domains-profiles-search list" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous SearchProfiles API call.
  --max-results: int # The maximum number of objects returned per page. The default is 20 if this parameter is not included in the request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  key_name: string # A searchable identifier of a customer profile. The predefined keys you can use to search include: _account, _profileId, _assetId, _caseId, _orderId, _fullName, _phone, _email, _ctrContactId, _marketoLeadId, _salesforceAccountId, _salesforceContactId, _salesforceAssetId, _zendeskUserId, _zendeskExternalId, _zendeskTicketId, _serviceNowSystemId, _serviceNowIncidentId, _segmentUserId, _shopifyCustomerId, _shopifyOrderId.
  values: list<string> # A list of key values.
  --additional-search-keys: list # A list of AdditionalSearchKey objects that are each searchable identifiers of a profile. Each AdditionalSearchKey object contains a KeyName and a list of Values associated with that specific key (i.e., a key-value(s) pair). These additional search keys will be used in conjunction with the LogicalOperator and the required KeyName and Values parameters to search for profiles that satisfy the search criteria. — item shape: {KeyName: any, Values: any}
  --logical-operator: string@logical-operator-completer # Relationship between all specified search keys that will be used to search for profiles. This includes the required KeyName and Values parameters as well as any key-value(s) pairs specified in the AdditionalSearchKeys list. This parameter influences which profiles will be returned in the response in the following manner: AND - The response only includes profiles that match all of the search keys. OR - The response includes profiles that match at least one of the search keys. The OR relationship is the default behavior if this parameter is not included in the request.
]: any -> record<Items: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next-token" $next_token "scalar") (serialize-qp "max-results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/domains/{domain_name}/profiles/search") $qp)
  let req_body = {"KeyName": $key_name, "Values": $values, "AdditionalSearchKeys": $additional_search_keys, "LogicalOperator": $logical_operator} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes one or more tags from the specified Amazon Connect Customer Profiles resource. In Connect Customer Profiles, domains, profile object types, and integrations can be tagged.
#
# DELETE /tags/{resourceArn}#tagKeys
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The list of tag keys to remove from the resource.
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
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}#tagKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
