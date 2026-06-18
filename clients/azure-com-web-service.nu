# Auto-generated client for WebSite Management Client v2015-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/web-service/2015-08-01/swagger.json
# Auth: --token flag or $env.WEBSITE_MANAGEMENT_CLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEBSITE_MANAGEMENT_CLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def default-provider-completer [] { ["AzureActiveDirectory" "Facebook" "Google" "MicrosoftAccount" "Twitter"] }
def unauthenticated-client-action-completer [] { ["AllowAnonymous" "RedirectToLoginPage"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-web-publishing-users-web get" } } | get name | first)
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

# Gets publishing user
#
# GET /providers/Microsoft.Web/publishingUsers/web
# operationId: Provider_GetPublishingUser
export def "providers-microsoft-web-publishing-users-web get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Web/publishingUsers/web" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates publishing user
#
# PUT /providers/Microsoft.Web/publishingUsers/web
# operationId: Provider_UpdatePublishingUser
# --properties shape: {name?: string, publishingPassword?: string, publishingUserName?: string, scmUri?: string}
export def "providers-microsoft-web-publishing-users-web update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {name?: string, publishingPassword?: string, publishingUserName?: string, scmUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Web/publishingUsers/web" $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the source controls available for Azure websites
#
# GET /providers/Microsoft.Web/sourcecontrols
# operationId: Provider_GetSourceControls
export def "providers-microsoft-web-sourcecontrols get-source-controls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Web/sourcecontrols" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets source control token
#
# GET /providers/Microsoft.Web/sourcecontrols/{sourceControlType}
# operationId: Provider_GetSourceControl
export def "providers-microsoft-web-sourcecontrols get-source-control" [
  source_control_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<expirationTime: string, name: string, refreshToken: string, token: string, tokenSecret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_control_type: (encode-path-segment $source_control_type)} | format pattern "/providers/Microsoft.Web/sourcecontrols/{source_control_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates source control token
#
# PUT /providers/Microsoft.Web/sourcecontrols/{sourceControlType}
# operationId: Provider_UpdateSourceControl
# --properties shape: {expirationTime?: string, name?: string, refreshToken?: string, token?: string, tokenSecret?: string}
export def "providers-microsoft-web-sourcecontrols update-source-control" [
  source_control_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {expirationTime?: string, name?: string, refreshToken?: string, token?: string, tokenSecret?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<expirationTime: string, name: string, refreshToken: string, token: string, tokenSecret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({source_control_type: (encode-path-segment $source_control_type)} | format pattern "/providers/Microsoft.Web/sourcecontrols/{source_control_type}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all domains in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.CertificateRegistration/certificateOrders
# operationId: GlobalCertificateOrder_GetAllCertificateOrders
export def "subscriptions-providers-microsoft-certificate-registration-certificate-orders get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.CertificateRegistration/certificateOrders") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate certificate purchase information
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.CertificateRegistration/validateCertificateRegistrationInformation
# operationId: GlobalCertificateOrder_ValidateCertificatePurchaseInformation
# --properties shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
export def "subscriptions-providers-microsoft-certificate-registration-validate-certificate-registration-information validate-global-order-purchase" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.CertificateRegistration/validateCertificateRegistrationInformation") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Checks if a domain is available for registration
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/checkDomainAvailability
# operationId: GlobalDomainRegistration_CheckDomainAvailability
export def "subscriptions-providers-microsoft-domain-registration-check-domain-availability check-global" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --name: string # Name of the object
]: any -> record<available: bool, domainType: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/checkDomainAvailability") $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all domains in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/domains
# operationId: GlobalDomainRegistration_GetAllDomains
export def "subscriptions-providers-microsoft-domain-registration-domains get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/domains") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates a single sign on request for domain management portal
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/generateSsoRequest
# operationId: GlobalDomainRegistration_GetDomainControlCenterSsoRequest
export def "subscriptions-providers-microsoft-domain-registration-generate-sso-request get-global-control-center" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<postParameterKey: string, postParameterValue: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/generateSsoRequest") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists domain recommendations based on keywords
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/listDomainRecommendations
# operationId: GlobalDomainRegistration_ListDomainRecommendations
export def "subscriptions-providers-microsoft-domain-registration-list-domain-recommendations list-global" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
  --keywords: string # Keywords to be used for generating domain recommendations
  --max-domain-recommendations: int # Maximum number of recommendations (format: int32)
]: any -> record<nextLink: string, value: table<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/listDomainRecommendations") $qp)
  let req_body = {"keywords": $keywords, "maxDomainRecommendations": $max_domain_recommendations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all top level domains supported for registration
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains
# operationId: TopLevelDomains_GetGetTopLevelDomains
export def "subscriptions-providers-microsoft-domain-registration-top-level-domains get-get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/topLevelDomains") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets details of a top level domain
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}
# operationId: TopLevelDomains_GetTopLevelDomain
export def "subscriptions-providers-microsoft-domain-registration-top-level-domains get" [
  subscription_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<name: string, privacy: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists legal agreements that user needs to accept before purchasing domain
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}/listAgreements
# operationId: TopLevelDomains_ListTopLevelDomainAgreements
export def "subscriptions-providers-microsoft-domain-registration-top-level-domains-list-agreements top" [
  subscription_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
  --include-privacy: oneof<nothing, bool> # If true then the list of agreements will include agreements for domain privacy as well.
]: any -> record<nextLink: string, value: table<agreementKey: string, content: string, title: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}/listAgreements") $qp)
  let req_body = {"includePrivacy": $include_privacy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Validates domain registration information
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/validateDomainRegistrationInformation
# operationId: GlobalDomainRegistration_ValidateDomainPurchaseInformation
# --properties shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, name?: string, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
export def "subscriptions-providers-microsoft-domain-registration-validate-domain-registration-information validate-global-purchase" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, name?: string, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DomainRegistration/validateDomainRegistrationInformation") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all certificates for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/certificates
# operationId: Global_GetAllCertificates
export def "subscriptions-providers-microsoft-web-certificates get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/certificates") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if resource name is available
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Web/checknameavailability
# operationId: Global_CheckNameAvailability
export def "subscriptions-providers-microsoft-web-checknameavailability check-global-name-availability" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --is-fqdn: oneof<nothing, bool> # Is fully qualified domain name
  --name: string # Resource name to verify
  --type: string # Resource type used for verification
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/checknameavailability") $qp)
  let req_body = {"isFqdn": $is_fqdn, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets all mobile services for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/classicMobileServices
# operationId: Global_GetAllClassicMobileServices
export def "subscriptions-providers-microsoft-web-classic-mobile-services get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/classicMobileServices") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of available geo regions
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/geoRegions
# operationId: Global_GetSubscriptionGeoRegions
export def "subscriptions-providers-microsoft-web-geo-regions get-global" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --sku: string # Filter only to regions that support this sku
  --linux-workers-enabled: oneof<nothing, bool> # Filter only to regions that support linux workers
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku" $sku "scalar") (serialize-qp "linuxWorkersEnabled" $linux_workers_enabled "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/geoRegions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all hostingEnvironments (App Service Environment) for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/hostingEnvironments
# operationId: Global_GetAllHostingEnvironments
export def "subscriptions-providers-microsoft-web-hosting-environments get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/hostingEnvironments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Whether hosting environment name is available
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/ishostingenvironmentnameavailable
# operationId: Global_IsHostingEnvironmentNameAvailable
export def "subscriptions-providers-microsoft-web-ishostingenvironmentnameavailable get-global-is-hosting-environment-name-available" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Hosting environment name
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/ishostingenvironmentnameavailable") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Whether hosting environment name is available
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/ishostingenvironmentnameavailable/{name}
# operationId: Global_IsHostingEnvironmentWithLegacyNameAvailable
export def "subscriptions-providers-microsoft-web-ishostingenvironmentnameavailable get-global-is-hosting-environment-with-legacy-available" [
  subscription_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/ishostingenvironmentnameavailable/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all managed hosting environments for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/managedHostingEnvironments
# operationId: Global_GetAllManagedHostingEnvironments
export def "subscriptions-providers-microsoft-web-managed-hosting-environments get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/managedHostingEnvironments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List premier add on offers
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/premieraddonoffers
# operationId: Global_ListPremierAddOnOffers
export def "subscriptions-providers-microsoft-web-premieraddonoffers list-global-premier-create-on-offers" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/premieraddonoffers") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets publishing credentials for the subscription owner
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/publishingCredentials
# operationId: Global_GetSubscriptionPublishingCredentials
export def "subscriptions-providers-microsoft-web-publishing-credentials get-global" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/publishingCredentials") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates publishing credentials for the subscription owner
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Web/publishingCredentials
# operationId: Global_UpdateSubscriptionPublishingCredentials
# --properties shape: {name?: string, publishingPassword?: string, publishingUserName?: string, scmUri?: string}
export def "subscriptions-providers-microsoft-web-publishing-credentials update-global" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {name?: string, publishingPassword?: string, publishingUserName?: string, scmUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/publishingCredentials") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of recommendations associated with the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/recommendations
# operationId: Recommendations_GetRecommendationBySubscription
export def "subscriptions-providers-microsoft-web-recommendations get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --featured: oneof<nothing, bool> # If set, this API returns only the most critical recommendation among the others. Otherwise this API returns all recommendations available
  --filter: string # Return only channels specified in the filter. Filter is specified by using OData syntax. Example: $filter=channels eq 'Api' or channel eq 'Notification'
  --api-version: string # API Version
]: nothing -> table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "featured" $featured "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/recommendations") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all App Service Plans for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/serverfarms
# operationId: Global_GetAllServerFarms
export def "subscriptions-providers-microsoft-web-serverfarms get-global-list-server-farms" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --detailed: oneof<nothing, bool> # False to return a subset of App Service Plan properties, true to return all of the properties. Retrieval of all properties may increase the API latency.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/serverfarms") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all Web Apps for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/sites
# operationId: Global_GetAllSites
export def "subscriptions-providers-microsoft-web-sites get-global-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Web/sites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/moveResources
#
# operationId: GlobalResourceGroups_MoveResources
export def "subscriptions-resource-groups-move-resources move-global" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --resources: list<string>
  --target-resource-group: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/moveResources") $qp)
  let req_body = {"resources": $resources, "targetResourceGroup": $target_resource_group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get certificate orders in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders
# operationId: CertificateOrders_GetCertificateOrders
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all certificates associated with a certificate order (only one certificate can be associated with an order at a time)
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates
# operationId: CertificateOrders_GetCertificates
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-certificates list" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), certificate_order_name: (encode-path-segment $certificate_order_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificate_order_name}/certificates") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the certificate associated with the certificate order
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# operationId: CertificateOrders_DeleteCertificate
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-certificates delete" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), certificate_order_name: (encode-path-segment $certificate_order_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificate_order_name}/certificates/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get certificate associated with the certificate order
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# operationId: CertificateOrders_GetCertificate
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-certificates get" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), certificate_order_name: (encode-path-segment $certificate_order_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificate_order_name}/certificates/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associates a Key Vault secret to a certificate store that will be used for storing the certificate once it's ready
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# operationId: CertificateOrders_UpdateCertificate
# --properties shape: {keyVaultId?: string, keyVaultSecretName?: string, provisioningState?: "Initialized"|"WaitingOnCertificateOrder"|"Succeeded"|"CertificateOrderFailed"|"OperationNotPermittedOnKeyVault"|"AzureServiceUnauthorizedToAccessKeyVault"|"KeyVaultDoesNotExist"|"KeyVaultSecretDoesNotExist"|"UnknownError"|"Unknown"}
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-certificates update" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {keyVaultId?: string, keyVaultSecretName?: string, provisioningState?: "Initialized"|"WaitingOnCertificateOrder"|"Succeeded"|"CertificateOrderFailed"|"OperationNotPermittedOnKeyVault"|"AzureServiceUnauthorizedToAccessKeyVault"|"KeyVaultDoesNotExist"|"KeyVaultSecretDoesNotExist"|"UnknownError"|"Unknown"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), certificate_order_name: (encode-path-segment $certificate_order_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificate_order_name}/certificates/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Associates a Key Vault secret to a certificate store that will be used for storing the certificate once it's ready
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# operationId: CertificateOrders_CreateOrUpdateCertificate
# --properties shape: {keyVaultId?: string, keyVaultSecretName?: string, provisioningState?: "Initialized"|"WaitingOnCertificateOrder"|"Succeeded"|"CertificateOrderFailed"|"OperationNotPermittedOnKeyVault"|"AzureServiceUnauthorizedToAccessKeyVault"|"KeyVaultDoesNotExist"|"KeyVaultSecretDoesNotExist"|"UnknownError"|"Unknown"}
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-certificates create-or-update" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {keyVaultId?: string, keyVaultSecretName?: string, provisioningState?: "Initialized"|"WaitingOnCertificateOrder"|"Succeeded"|"CertificateOrderFailed"|"OperationNotPermittedOnKeyVault"|"AzureServiceUnauthorizedToAccessKeyVault"|"KeyVaultDoesNotExist"|"KeyVaultSecretDoesNotExist"|"UnknownError"|"Unknown"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), certificate_order_name: (encode-path-segment $certificate_order_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificate_order_name}/certificates/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an existing certificate order
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# operationId: CertificateOrders_DeleteCertificateOrder
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a certificate order
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# operationId: CertificateOrders_GetCertificateOrder
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record>, serialNumber: string, signedCertificate: record<properties: record>, status: string, validityInYears: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a certificate purchase order
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# operationId: CertificateOrders_UpdateCertificateOrder
# --properties shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record>, serialNumber: string, signedCertificate: record<properties: record>, status: string, validityInYears: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or update a certificate purchase order
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# operationId: CertificateOrders_CreateOrUpdateCertificateOrder
# --properties shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record>, serialNumber: string, signedCertificate: record<properties: record>, status: string, validityInYears: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reissue an existing certificate order
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/reissue
# operationId: CertificateOrders_ReissueCertificateOrder
# --properties shape: {delayExistingRevokeInHours?: int, keySize?: int}
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-reissue create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {delayExistingRevokeInHours?: int, keySize?: int}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/reissue") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Renew an existing certificate order
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/renew
# operationId: CertificateOrders_RenewCertificateOrder
# --properties shape: {keySize?: int}
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-renew create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {keySize?: int}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/renew") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resend certificate email
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/resendEmail
# operationId: CertificateOrders_ResendCertificateEmail
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-resend-email resend" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/resendEmail") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the list of certificate actions
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveCertificateActions
# operationId: CertificateOrders_RetrieveCertificateActions
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-retrieve-certificate-actions get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<createdAt: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveCertificateActions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve email history
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveEmailHistory
# operationId: CertificateOrders_RetrieveCertificateEmailHistory
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-retrieve-email-history get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<emailId: string, timeStamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveEmailHistory") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify domain ownership for this certificate order
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/verifyDomainOwnership
# operationId: CertificateOrders_VerifyDomainOwnership
export def "subscriptions-resource-groups-providers-microsoft-certificate-registration-certificate-orders-verify-domain-ownership verify" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/verifyDomainOwnership") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists domains under a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains
# operationId: Domains_GetDomains
export def "subscriptions-resource-groups-providers-microsoft-domain-registration-domains list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DomainRegistration/domains") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a domain
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# operationId: Domains_DeleteDomain
export def "subscriptions-resource-groups-providers-microsoft-domain-registration-domains delete" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --force-hard-delete-domain: oneof<nothing, bool> # If true then the domain will be deleted immediately instead of after 24 hours
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceHardDeleteDomain" $force_hard_delete_domain "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), domain_name: (encode-path-segment $domain_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DomainRegistration/domains/{domain_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets details of a domain
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# operationId: Domains_GetDomain
export def "subscriptions-resource-groups-providers-microsoft-domain-registration-domains get" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), domain_name: (encode-path-segment $domain_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DomainRegistration/domains/{domain_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a domain
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# operationId: Domains_UpdateDomain
# --properties shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-domain-registration-domains update" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), domain_name: (encode-path-segment $domain_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DomainRegistration/domains/{domain_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a domain
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# operationId: Domains_CreateOrUpdateDomain
# --properties shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-domain-registration-domains create-or-update" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), domain_name: (encode-path-segment $domain_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DomainRegistration/domains/{domain_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves the latest status of a domain purchase operation
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}/operationresults/{operationId}
# operationId: Domains_GetDomainOperation
export def "subscriptions-resource-groups-providers-microsoft-domain-registration-domains-operationresults get-operation" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), domain_name: (encode-path-segment $domain_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DomainRegistration/domains/{domain_name}/operationresults/{operation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns usage records for specified subscription and resource groups
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web.Admin/environments/{environmentName}/usage
# operationId: Usage_GetUsage
export def "subscriptions-resource-groups-providers-microsoft-web-admin-environments-usage get" [
  subscription_id: string
  resource_group_name: string
  environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --last-id: string # Last marker that was returned from the batch
  --batch-size: int # size of the batch to be returned. (format: int32)
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lastId" $last_id "scalar") (serialize-qp "batchSize" $batch_size "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), environment_name: (encode-path-segment $environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web.Admin/environments/{environment_name}/usage") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get certificates for a subscription in the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates
# operationId: Certificates_GetCertificates
export def "subscriptions-resource-groups-providers-microsoft-web-certificates list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/certificates") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a certificate by name in a specified subscription and resourcegroup.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# operationId: Certificates_DeleteCertificate
export def "subscriptions-resource-groups-providers-microsoft-web-certificates delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/certificates/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a certificate by certificate name for a subscription in the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# operationId: Certificates_GetCertificate
export def "subscriptions-resource-groups-providers-microsoft-web-certificates get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/certificates/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or modifies an existing certificate.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# operationId: Certificates_UpdateCertificate
# --properties shape: {cerBlob?: string, expirationDate?: string, friendlyName?: string, hostNames?: list<string>, hostingEnvironmentProfile?: record, issueDate?: string, issuer?: string, password?: string, pfxBlob?: string, publicKeyHash?: string, selfLink?: string, siteName?: string, subjectName?: string, thumbprint?: string, valid?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-certificates update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {cerBlob?: string, expirationDate?: string, friendlyName?: string, hostNames?: list<string>, hostingEnvironmentProfile?: record, issueDate?: string, issuer?: string, password?: string, pfxBlob?: string, publicKeyHash?: string, selfLink?: string, siteName?: string, subjectName?: string, thumbprint?: string, valid?: bool}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/certificates/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or modifies an existing certificate.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# operationId: Certificates_CreateOrUpdateCertificate
# --properties shape: {cerBlob?: string, expirationDate?: string, friendlyName?: string, hostNames?: list<string>, hostingEnvironmentProfile?: record, issueDate?: string, issuer?: string, password?: string, pfxBlob?: string, publicKeyHash?: string, selfLink?: string, siteName?: string, subjectName?: string, thumbprint?: string, valid?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-certificates create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {cerBlob?: string, expirationDate?: string, friendlyName?: string, hostNames?: list<string>, hostingEnvironmentProfile?: record, issueDate?: string, issuer?: string, password?: string, pfxBlob?: string, publicKeyHash?: string, selfLink?: string, siteName?: string, subjectName?: string, thumbprint?: string, valid?: bool}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/certificates/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all mobile services in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices
# operationId: ClassicMobileServices_GetClassicMobileServices
export def "subscriptions-resource-groups-providers-microsoft-web-classic-mobile-services list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/classicMobileServices") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a mobile service.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices/{name}
# operationId: ClassicMobileServices_DeleteClassicMobileService
export def "subscriptions-resource-groups-providers-microsoft-web-classic-mobile-services delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/classicMobileServices/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a mobile service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices/{name}
# operationId: ClassicMobileServices_GetClassicMobileService
export def "subscriptions-resource-groups-providers-microsoft-web-classic-mobile-services get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/classicMobileServices/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the certificate signing requests for a subscription in the specified resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs
# operationId: Certificates_GetCsrs
export def "subscriptions-resource-groups-providers-microsoft-web-csrs list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/csrs") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the certificate signing request.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# operationId: Certificates_DeleteCsr
export def "subscriptions-resource-groups-providers-microsoft-web-csrs delete-certificates" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/csrs/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a certificate signing request by certificate name for a subscription in the specified resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# operationId: Certificates_GetCsr
export def "subscriptions-resource-groups-providers-microsoft-web-csrs get-certificates" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/csrs/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or modifies an existing certificate signing request.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# operationId: Certificates_UpdateCsr
# --properties shape: {csrString?: string, distinguishedName?: string, hostingEnvironment?: string, name?: string, password?: string, pfxBlob?: string, publicKeyHash?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-csrs update-certificates" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {csrString?: string, distinguishedName?: string, hostingEnvironment?: string, name?: string, password?: string, pfxBlob?: string, publicKeyHash?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/csrs/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or modifies an existing certificate signing request.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# operationId: Certificates_CreateOrUpdateCsr
# --properties shape: {csrString?: string, distinguishedName?: string, hostingEnvironment?: string, name?: string, password?: string, pfxBlob?: string, publicKeyHash?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-csrs create-certificates-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {csrString?: string, distinguishedName?: string, hostingEnvironment?: string, name?: string, password?: string, pfxBlob?: string, publicKeyHash?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/csrs/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets deleted web apps in subscription
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/deletedSites
# operationId: Sites_GetDeletedSites
export def "subscriptions-resource-groups-providers-microsoft-web-deleted-sites get" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --include-site-types: string # Types of apps included in the response
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "includeSiteTypes" $include_site_types "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/deletedSites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all hostingEnvironments (App Service Environments) in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments
# operationId: HostingEnvironments_GetHostingEnvironments
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a hostingEnvironment (App Service Environment).
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}
# operationId: HostingEnvironments_DeleteHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --force-delete: oneof<nothing, bool> # Delete even if the hostingEnvironment (App Service Environment) contains resources
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceDelete" $force_delete "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get properties of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}
# operationId: HostingEnvironments_GetHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a hostingEnvironment (App Service Environment).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}
# operationId: HostingEnvironments_CreateOrUpdateHostingEnvironment
# --properties shape: {allowedMultiSizes?: string, allowedWorkerSizes?: string, apiManagementAccountId?: string, clusterSettings?: list, databaseEdition?: string, databaseServiceObjective?: string, dnsSuffix?: string, environmentCapacities?: list, environmentIsHealthy?: bool, environmentStatus?: string, internalLoadBalancingMode?: "None"|"Web"|"Publishing", ipsslAddressCount?: int, lastAction?: string, lastActionResult?: string, location?: string, maximumNumberOfMachines?: int, multiRoleCount?: int, multiSize?: string, ... (14 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {allowedMultiSizes?: string, allowedWorkerSizes?: string, apiManagementAccountId?: string, clusterSettings?: list, databaseEdition?: string, databaseServiceObjective?: string, dnsSuffix?: string, environmentCapacities?: list, environmentIsHealthy?: bool, environmentStatus?: string, internalLoadBalancingMode?: "None"|"Web"|"Publishing", ipsslAddressCount?: int, lastAction?: string, lastActionResult?: string, location?: string, maximumNumberOfMachines?: int, multiRoleCount?: int, multiSize?: string, ... (14 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get used, available, and total worker capacity for hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/compute
# operationId: HostingEnvironments_GetHostingEnvironmentCapacities
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-capacities-compute get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<availableCapacity: int, computeMode: string, excludeFromCapacityAllocation: bool, isApplicableForAllComputeModes: bool, name: string, siteMode: string, totalCapacity: int, unit: string, workerSize: string, workerSizeId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/compute") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get IP addresses assigned to the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/virtualip
# operationId: HostingEnvironments_GetHostingEnvironmentVips
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-capacities-virtualip get-vips" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<internalIpAddress: string, outboundIpAddresses: list<string>, serviceIpAddress: string, vipMappings: table<inUse: bool, internalHttpPort: int, internalHttpsPort: int, virtualIP: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/virtualip") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get diagnostic information for hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics
# operationId: HostingEnvironments_GetHostingEnvironmentDiagnostics
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-diagnostics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<diagnosicsOutput: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get diagnostic information for hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics/{diagnosticsName}
# operationId: HostingEnvironments_GetHostingEnvironmentDiagnosticsItem
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-diagnostics get-item" [
  subscription_id: string
  resource_group_name: string
  name: string
  diagnostics_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<diagnosicsOutput: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), diagnostics_name: (encode-path-segment $diagnostics_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics/{diagnostics_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global metric definitions of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/metricdefinitions
# operationId: HostingEnvironments_GetHostingEnvironmentMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<displayName: string, metricAvailabilities: list<record>, name: string, primaryAggregationType: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global metrics of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/metrics
# operationId: HostingEnvironments_GetHostingEnvironmentMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all multi role pools
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools
# operationId: HostingEnvironments_GetMultiRolePools
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get properties of a multiRole pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default
# operationId: HostingEnvironments_GetMultiRolePool
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a multiRole pool.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default
# operationId: HostingEnvironments_CreateOrUpdateMultiRolePool
# --properties shape: {computeMode?: "Shared"|"Dedicated"|"Dynamic", instanceNames?: list<string>, workerCount?: int, workerSize?: string, workerSizeId?: int}
# --sku shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {computeMode?: "Shared"|"Dedicated"|"Dynamic", instanceNames?: list<string>, workerCount?: int, workerSize?: string, workerSizeId?: int}
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get metric definitions for a specific instance of a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metricdefinitions
# operationId: HostingEnvironments_GetMultiRolePoolInstanceMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default-instances-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), instance: (encode-path-segment $instance)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for a specific instance of a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metrics
# operationId: HostingEnvironments_GetMultiRolePoolInstanceMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default-instances-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --details: oneof<nothing, bool> # Include instance details
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), instance: (encode-path-segment $instance)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metric definitions for a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metricdefinitions
# operationId: HostingEnvironments_GetHostingEnvironmentMultiRoleMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metrics
# operationId: HostingEnvironments_GetHostingEnvironmentMultiRoleMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --start-time: string # Beginning time of metrics query
  --end-time: string # End time of metrics query
  --time-grain: string # Time granularity of metrics query
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "timeGrain" $time_grain "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get available skus for scaling a multiRole pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/skus
# operationId: HostingEnvironments_GetMultiRolePoolSkus
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default-skus get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/skus") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get usages for a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/usages
# operationId: HostingEnvironments_GetHostingEnvironmentMultiRoleUsages
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-multi-role-pools-default-usages get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/usages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all currently running operations on the hostingEnvironment (App Service Environment)
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/operations
# operationId: HostingEnvironments_GetHostingEnvironmentOperations
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-operations list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/operations") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status of an operation on a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/operations/{operationId}
# operationId: HostingEnvironments_GetHostingEnvironmentOperation
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-operations get" [
  subscription_id: string
  resource_group_name: string
  name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/operations/{operation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboots all machines in a hostingEnvironment (App Service Environment).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/reboot
# operationId: HostingEnvironments_RebootHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-reboot create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/reboot") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resumes the hostingEnvironment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/resume
# operationId: HostingEnvironments_ResumeHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-resume create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/resume") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all serverfarms (App Service Plans) on the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/serverfarms
# operationId: HostingEnvironments_GetHostingEnvironmentServerFarms
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-serverfarms get-server-farms" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/serverfarms") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sites on the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/sites
# operationId: HostingEnvironments_GetHostingEnvironmentSites
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-sites get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Comma separated list of site properties to include
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/sites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suspends the hostingEnvironment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/suspend
# operationId: HostingEnvironments_SuspendHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-suspend create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/suspend") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global usages of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/usages
# operationId: HostingEnvironments_GetHostingEnvironmentUsages
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-usages get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/usages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all serverfarms (App Service Plans) on the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/webhostingplans
# operationId: HostingEnvironments_GetHostingEnvironmentWebHostingPlans
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-webhostingplans get-plans" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/webhostingplans") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all worker pools
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools
# operationId: HostingEnvironments_GetWorkerPools
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get properties of a worker pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}
# operationId: HostingEnvironments_GetWorkerPool
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools get" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a worker pool.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}
# operationId: HostingEnvironments_CreateOrUpdateWorkerPool
# --properties shape: {computeMode?: "Shared"|"Dedicated"|"Dynamic", instanceNames?: list<string>, workerCount?: int, workerSize?: string, workerSizeId?: int}
# --sku shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {computeMode?: "Shared"|"Dedicated"|"Dynamic", instanceNames?: list<string>, workerCount?: int, workerSize?: string, workerSizeId?: int}
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get metric definitions for a specific instance of a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/instances/{instance}/metricdefinitions
# operationId: HostingEnvironments_GetWorkerPoolInstanceMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools-instances-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name), instance: (encode-path-segment $instance)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}/instances/{instance}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for a specific instance of a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/instances/{instance}/metrics
# operationId: HostingEnvironments_GetWorkerPoolInstanceMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools-instances-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name), instance: (encode-path-segment $instance)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}/instances/{instance}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metric definitions for a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/metricdefinitions
# operationId: HostingEnvironments_GetHostingEnvironmentWebWorkerMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/metrics
# operationId: HostingEnvironments_GetHostingEnvironmentWebWorkerMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get available skus for scaling a worker pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/skus
# operationId: HostingEnvironments_GetWorkerPoolSkus
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools-skus get" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}/skus") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get usages for a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/usages
# operationId: HostingEnvironments_GetHostingEnvironmentWebWorkerUsages
export def "subscriptions-resource-groups-providers-microsoft-web-hosting-environments-worker-pools-usages get" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_pool_name: (encode-path-segment $worker_pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{worker_pool_name}/usages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all managed hosting environments in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironments
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a managed hosting environment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}
# operationId: ManagedHostingEnvironments_DeleteManagedHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --force-delete: oneof<nothing, bool> # Delete even if the managed hosting environment contains resources
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceDelete" $force_delete "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get properties of a managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironment
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<apiManagementAccount: string, dnsSuffix: string, environmentIsHealthy: bool, environmentStatus: string, ipsslAddressCount: int, location: string, name: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, virtualNetwork: record<id: string, name: string, subnet: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a managed hosting environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}
# operationId: ManagedHostingEnvironments_CreateOrUpdateManagedHostingEnvironment
# --properties shape: {allowedMultiSizes?: string, allowedWorkerSizes?: string, apiManagementAccountId?: string, clusterSettings?: list, databaseEdition?: string, databaseServiceObjective?: string, dnsSuffix?: string, environmentCapacities?: list, environmentIsHealthy?: bool, environmentStatus?: string, internalLoadBalancingMode?: "None"|"Web"|"Publishing", ipsslAddressCount?: int, lastAction?: string, lastActionResult?: string, location?: string, maximumNumberOfMachines?: int, multiRoleCount?: int, multiSize?: string, ... (14 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {allowedMultiSizes?: string, allowedWorkerSizes?: string, apiManagementAccountId?: string, clusterSettings?: list, databaseEdition?: string, databaseServiceObjective?: string, dnsSuffix?: string, environmentCapacities?: list, environmentIsHealthy?: bool, environmentStatus?: string, internalLoadBalancingMode?: "None"|"Web"|"Publishing", ipsslAddressCount?: int, lastAction?: string, lastActionResult?: string, location?: string, maximumNumberOfMachines?: int, multiRoleCount?: int, multiSize?: string, ... (14 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get list of ip addresses assigned to a managed hosting environment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/capacities/virtualip
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentVips
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments-capacities-virtualip get-vips" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<internalIpAddress: string, outboundIpAddresses: list<string>, serviceIpAddress: string, vipMappings: table<inUse: bool, internalHttpPort: int, internalHttpsPort: int, virtualIP: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}/capacities/virtualip") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status of an operation on a managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/operations/{operationId}
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentOperation
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments-operations get" [
  subscription_id: string
  resource_group_name: string
  name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}/operations/{operation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all serverfarms (App Service Plans) on the managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/serverfarms
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentServerFarms
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments-serverfarms get-server-farms" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}/serverfarms") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sites on the managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/sites
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentSites
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments-sites get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Comma separated list of site properties to include
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}/sites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all serverfarms (App Service Plans) on the managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/webhostingplans
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentWebHostingPlans
export def "subscriptions-resource-groups-providers-microsoft-web-managed-hosting-environments-webhostingplans get-plans" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/managedHostingEnvironments/{name}/webhostingplans") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets collection of App Service Plans in a resource group for a given subscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms
# operationId: ServerFarms_GetServerFarms
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms get-server-farms-server-farms" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a App Service Plan
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}
# operationId: ServerFarms_DeleteServerFarm
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms delete-server-farms-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets specified App Service Plan in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}
# operationId: ServerFarms_GetServerFarm
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms get-server-farms-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an App Service Plan
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}
# operationId: ServerFarms_CreateOrUpdateServerFarm
# --properties shape: {adminSiteName?: string, hostingEnvironmentProfile?: record, maximumNumberOfWorkers?: int, name?: string, perSiteScaling?: bool, reserved?: bool, workerTierName?: string}
# --sku shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms create-server-farms-or-update-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --allow-pending-state: oneof<nothing, bool> # OBSOLETE: If true, allow pending state for App Service Plan
  --api-version: string # API Version
  --properties: any # shape: {adminSiteName?: string, hostingEnvironmentProfile?: record, maximumNumberOfWorkers?: int, name?: string, perSiteScaling?: bool, reserved?: bool, workerTierName?: string}
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowPendingState" $allow_pending_state "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List of metrics that can be queried for an App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/metricdefinitions
# operationId: ServerFarms_GetServerFarmMetricDefintions
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-metricdefinitions get-server-farms-server-farm-metric-defintions" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries for App Service Plan metrics
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/metrics
# operationId: ServerFarms_GetServerFarmMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-metrics get-server-farms-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # If true, metrics are broken down per App Service Plan instance
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a server farm operation
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/operationresults/{operationId}
# operationId: ServerFarms_GetServerFarmOperation
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-operationresults get-server-farms-server-farm-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/operationresults/{operation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts web apps in a specified App Service Plan
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/restartSites
# operationId: ServerFarms_RestartSitesForServerFarm
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-restart-sites restart-server-farms-for-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --soft-restart: oneof<nothing, bool> # Soft restart applies the configuration settings and restarts the apps if necessary. Hard restart always restarts and reprovisions the apps
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "softRestart" $soft_restart "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/restartSites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of Apps associated with an App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/sites
# operationId: ServerFarms_GetServerFarmSites
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-sites get-server-farms-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --skip-token: string # Skip to of web apps in a list. If specified, the resulting list will contain web apps starting from (including) the skipToken. Else, the resulting list contains web apps from the start of the list
  --filter: string # Supported filter: $filter=state eq running. Returns only web apps that are currently running
  --top: string # List page size. If specified, results are paged.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$skipToken" $skip_token "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/sites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of VNets associated with App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections
# operationId: ServerFarms_GetVnetsForServerFarm
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections get-server-farms-vnets-for-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a vnet associated with an App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}
# operationId: ServerFarms_GetVnetFromServerFarm
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections get-server-farms-vnet-from-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the vnet gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: ServerFarms_GetServerFarmVnetGateway
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-gateways get-server-farms-server-farm-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the vnet gateway
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: ServerFarms_UpdateServerFarmVnetGateway
# --properties shape: {vnetName?: string, vpnPackageUri?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-gateways update-server-farms-server-farm-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of all routes associated with a vnet, in an app service plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes
# operationId: ServerFarms_GetRoutesForVnet
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-routes list" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/routes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing route for a vnet in an app service plan.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# operationId: ServerFarms_DeleteVnetRoute
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-routes delete-server-farms-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), route_name: (encode-path-segment $route_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/routes/{route_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a specific route associated with a vnet, in an app service plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# operationId: ServerFarms_GetRouteForVnet
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-routes get-server-farms-for-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), route_name: (encode-path-segment $route_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/routes/{route_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new route or updates an existing route for a vnet in an app service plan.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# operationId: ServerFarms_UpdateVnetRoute
# --properties shape: {endAddress?: string, name?: string, routeType?: string, startAddress?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-routes update-server-farms-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {endAddress?: string, name?: string, routeType?: string, startAddress?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), route_name: (encode-path-segment $route_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/routes/{route_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new route or updates an existing route for a vnet in an app service plan.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# operationId: ServerFarms_CreateOrUpdateVnetRoute
# --properties shape: {endAddress?: string, name?: string, routeType?: string, startAddress?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-virtual-network-connections-routes create-server-farms-or-update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {endAddress?: string, name?: string, routeType?: string, startAddress?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), route_name: (encode-path-segment $route_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnet_name}/routes/{route_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Submit a reboot request for a worker machine in the specified server farm
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/workers/{workerName}/reboot
# operationId: ServerFarms_RebootWorkerForServerFarm
export def "subscriptions-resource-groups-providers-microsoft-web-serverfarms-workers-reboot create-server-farms-for-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), worker_name: (encode-path-segment $worker_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/serverfarms/{name}/workers/{worker_name}/reboot") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web apps for a subscription in the specified resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites
# operationId: Sites_GetSites
export def "subscriptions-resource-groups-providers-microsoft-web-sites list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --include-site-types: string # Types of apps included in the response
  --include-slots: oneof<nothing, bool> # Whether or not to include deployments slots in results
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "includeSiteTypes" $include_site_types "scalar") (serialize-qp "includeSlots" $include_slots "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: Sites_DeleteSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --delete-metrics: string # If true, web app metrics are also deleted
  --delete-empty-server-farm: string # If true and App Service Plan is empty after web app deletion, App Service Plan is also deleted
  --skip-dns-registration: string # If true, DNS registration is skipped
  --delete-all-slots: string # If true, all slots associated with web app are also deleted
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteMetrics" $delete_metrics "scalar") (serialize-qp "deleteEmptyServerFarm" $delete_empty_server_farm "scalar") (serialize-qp "skipDnsRegistration" $skip_dns_registration "scalar") (serialize-qp "deleteAllSlots" $delete_all_slots "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: Sites_GetSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --api-version: string # API Version
]: nothing -> record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new web app or modifies an existing web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: Sites_CreateOrUpdateSite
# --properties shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, cloningInfo?: record, containerSize?: int, enabled?: bool, gatewaySiteName?: string, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, maxNumberOfWorkers?: int, microService?: string, name?: string, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --skip-dns-registration: string # If true web app hostname is not registered with DNS on creation. This parameter is only used for app creation
  --skip-custom-domain-verification: string # If true, custom (non *.azurewebsites.net) domains associated with web app are not verified.
  --force-dns-registration: string # If true, web app hostname is force registered with DNS
  --ttl-in-seconds: string # Time to live in seconds for web app's default domain name
  --api-version: string # API Version
  --properties: any # shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, cloningInfo?: record, containerSize?: int, enabled?: bool, gatewaySiteName?: string, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, maxNumberOfWorkers?: int, microService?: string, name?: string, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipDnsRegistration" $skip_dns_registration "scalar") (serialize-qp "skipCustomDomainVerification" $skip_custom_domain_verification "scalar") (serialize-qp "forceDnsRegistration" $force_dns_registration "scalar") (serialize-qp "ttlInSeconds" $ttl_in_seconds "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Applies the configuration settings from the target slot onto the current slot
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/applySlotConfig
# operationId: Sites_ApplySlotConfigToProduction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-apply-slot-config create-to-production" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/applySlotConfig") $qp)
  let req_body = {"preserveVnet": $preserve_vnet, "targetSlot": $target_slot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates web app backup
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backup
# operationId: Sites_BackupSite
# --properties shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backup create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backup") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all available backups for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups
# operationId: Sites_ListSiteBackups
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backups") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Discovers existing web app backups that can be restored
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/discover
# operationId: Sites_DiscoverSiteRestore
# --properties shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups-discover update-restore" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<adjustConnectionStrings: bool, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backups/discover") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a backup from Azure Storage
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}
# operationId: Sites_DeleteBackup
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backups/{backup_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets status of a web app backup that may be in progress.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}
# operationId: Sites_GetSiteBackupStatus
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups get-status" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backups/{backup_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets status of a web app backup that may be in progress, including secrets associated with the backup, such as the Azure Storage SAS URL. Also can be used to update the SAS URL for the backup if a new URL is passed in the request body.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/list
# operationId: Sites_GetSiteBackupStatusSecrets
# --properties shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups-list get-status-secrets" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backups/{backup_id}/list") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Restores a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/restore
# operationId: Sites_RestoreSite
# --properties shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups-restore create" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<operationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/backups/{backup_id}/restore") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the application settings of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings
# operationId: Sites_UpdateSiteAppSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-appsettings update-app-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/appsettings") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the application settings of web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings/list
# operationId: Sites_ListSiteAppSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-appsettings-list list-app-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/appsettings/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Authentication / Authorization settings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings
# operationId: Sites_UpdateSiteAuthSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-authsettings update-auth-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --aad-client-id: string
  --additional-login-params: list<string> # Gets or sets a list of login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".
  --allowed-audiences: list<string> # Gets or sets a list of allowed audience values to consider when validating JWTs issued by Azure Active Directory. Note that the {Microsoft.Web.Hosting.Administration.SiteAuthSettings.ClientId} value is always considered an allowed audience, regardless of this setting.
  --allowed-external-redirect-urls: list<string> # Gets or sets a collection of external URLs that can be redirected to as part of logging in or logging out of the web app. Note that the query string part of the URL is ignored. This is an advanced setting typically only needed by Windows Store application backends. Note that URLs within the current domain are always implicitly allowed.
  --client-id: string # Gets or sets the Client ID of this relying party application, known as the client_id. This setting is required for enabling OpenID Connection authentication with Azure Active Directory or other 3rd party OpenID Connect providers. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --client-secret: string # Gets or sets the Client Secret of this relying party application (in Azure Active Directory, this is also referred to as the Key). This setting is optional. If no client secret is configured, the OpenID Connect implicit auth flow is used to authenticate end users. Otherwise, the OpenID Connect Authorization Code Flow is used to authenticate end users. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --default-provider: string@default-provider-completer # Gets or sets the default authentication provider to use when multiple providers are configured. This setting is only needed if multiple providers are configured and the unauthenticated client action is set to "RedirectToLoginPage".
  --enabled: oneof<nothing, bool> # Gets or sets a value indicating whether the Authentication / Authorization feature is enabled for the current app.
  --facebook-app-id: string # Gets or sets the App ID of the Facebook app used for login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-app-secret: string # Gets or sets the App Secret of the Facebook app used for Facebook Login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Facebook Login authentication. This setting is optional. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --google-client-id: string # Gets or sets the OpenID Connect Client ID for the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-client-secret: string # Gets or sets the client secret associated with the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Google Sign-In authentication. This setting is optional. If not specified, "openid", "profile", and "email" are used as default scopes. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --http-api-prefix-path: string # Gets or sets the relative path prefix used by platform HTTP APIs. Changing this value is not recommended except for compatibility reasons.
  --issuer: string # Gets or sets the OpenID Connect Issuer URI that represents the entity which issues access tokens for this application. When using Azure Active Directory, this value is the URI of the directory tenant, e.g. https://sts.windows.net/{tenant-guid}/. This URI is a case-sensitive identifier for the token issuer. More information on OpenID Connect Discovery: http://openid.net/specs/openid-connect-discovery-1_0.html
  --microsoft-account-client-id: string # Gets or sets the OAuth 2.0 client ID that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-client-secret: string # Gets or sets the OAuth 2.0 client secret that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Microsoft Account authentication. This setting is optional. If not specified, "wl.basic" is used as the default scope. Microsoft Account Scopes and permissions documentation: https://msdn.microsoft.com/en-us/library/dn631845.aspx
  --open-id-issuer: string
  --token-refresh-extension-hours: float # Gets or sets the number of hours after session token expiration that a session token can be used to call the token refresh API. The default is 72 hours. (format: double)
  --token-store-enabled: oneof<nothing, bool> # Gets or sets a value indicating whether to durably store platform-specific security tokens obtained during login flows. This capability is disabled by default.
  --twitter-consumer-key: string # Gets or sets the OAuth 1.0a consumer key of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --twitter-consumer-secret: string # Gets or sets the OAuth 1.0a consumer secret of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --unauthenticated-client-action: string@unauthenticated-client-action-completer # Gets or sets the action to take when an unauthenticated client attempts to access the app.
]: any -> record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/authsettings") $qp)
  let req_body = {"aadClientId": $aad_client_id, "additionalLoginParams": $additional_login_params, "allowedAudiences": $allowed_audiences, "allowedExternalRedirectUrls": $allowed_external_redirect_urls, "clientId": $client_id, "clientSecret": $client_secret, "defaultProvider": $default_provider, "enabled": $enabled, "facebookAppId": $facebook_app_id, "facebookAppSecret": $facebook_app_secret, "facebookOAuthScopes": $facebook_o_auth_scopes, "googleClientId": $google_client_id, "googleClientSecret": $google_client_secret, "googleOAuthScopes": $google_o_auth_scopes, "httpApiPrefixPath": $http_api_prefix_path, "issuer": $issuer, "microsoftAccountClientId": $microsoft_account_client_id, "microsoftAccountClientSecret": $microsoft_account_client_secret, "microsoftAccountOAuthScopes": $microsoft_account_o_auth_scopes, "openIdIssuer": $open_id_issuer, "tokenRefreshExtensionHours": $token_refresh_extension_hours, "tokenStoreEnabled": $token_store_enabled, "twitterConsumerKey": $twitter_consumer_key, "twitterConsumerSecret": $twitter_consumer_secret, "unauthenticatedClientAction": $unauthenticated_client_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the Authentication / Authorization settings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings/list
# operationId: Sites_ListSiteAuthSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-authsettings-list list-auth-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/authsettings/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates backup configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup
# operationId: Sites_UpdateSiteBackupConfiguration
# --properties shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-backup update-configuration" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/backup") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the backup configuration for a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup/list
# operationId: Sites_GetSiteBackupConfiguration
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-backup-list get-configuration" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/backup/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the connection strings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings
# operationId: Sites_UpdateSiteConnectionStrings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-connectionstrings update-connection-strings" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: record # Connection strings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/connectionstrings") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the connection strings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings/list
# operationId: Sites_ListSiteConnectionStrings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-connectionstrings-list list-connection-strings" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/connectionstrings/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web app logs configuration
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs
# operationId: Sites_GetSiteLogsConfig
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-logs get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/logs") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs
# operationId: Sites_UpdateSiteLogsConfig
# --properties shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-logs update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/logs") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata
# operationId: Sites_UpdateSiteMetadata
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-metadata update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/metadata") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the web app meta data.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata/list
# operationId: Sites_ListSiteMetadata
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-metadata-list list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/metadata/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web app publishing credentials
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/publishingcredentials/list
# operationId: Sites_ListSitePublishingCredentials
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-publishingcredentials-list list-publishing-credentials" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/publishingcredentials/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the names of application settings and connection string that remain with the slot during swap operation
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames
# operationId: Sites_GetSlotConfigNames
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-slot-config-names get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<appSettingNames: list<string>, connectionStringNames: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the names of application settings and connection string that remain with the slot during swap operation
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames
# operationId: Sites_UpdateSlotConfigNames
# --properties shape: {appSettingNames?: list<string>, connectionStringNames?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-slot-config-names update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {appSettingNames?: list<string>, connectionStringNames?: list<string>}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<appSettingNames: list<string>, connectionStringNames: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the configuration of the web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# operationId: Sites_GetSiteConfig
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/web") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# operationId: Sites_UpdateSiteConfig
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# operationId: Sites_CreateOrUpdateSiteConfig
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/config/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments
# operationId: Sites_GetDeployments
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/deployments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# operationId: Sites_DeleteDeployment
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# operationId: Sites_GetDeployment
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments get" [
  subscription_id: string
  resource_group_name: string
  name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# operationId: Sites_CreateDeployment
# --properties shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments create" [
  subscription_id: string
  resource_group_name: string
  name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/deployments/{id}") $qp)
  let req_body = {"properties": $properties, "id": $body_id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get web app hostname bindings
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings
# operationId: Sites_GetSiteHostNameBindings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hostNameBindings") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a host name binding
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# operationId: Sites_DeleteSiteHostNameBinding
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), host_name: (encode-path-segment $host_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{host_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get web app binding for a hostname
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# operationId: Sites_GetSiteHostNameBinding
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings get" [
  subscription_id: string
  resource_group_name: string
  name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), host_name: (encode-path-segment $host_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{host_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a web app hostname binding
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# operationId: Sites_CreateOrUpdateSiteHostNameBinding
# --properties shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", name?: string, siteName?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", name?: string, siteName?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), host_name: (encode-path-segment $host_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{host_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves all BizTalk Hybrid Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection
# operationId: Sites_ListSiteRelayServiceConnections
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection list-relay-service-connections" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hybridconnection") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the association to a BizTalk Hybrid Connection, identified by its entity name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: Sites_DeleteSiteRelayServiceConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection delete-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entity_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a BizTalk Hybrid Connection identified by its entity name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: Sites_GetSiteRelayServiceConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection get-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entity_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: Sites_UpdateSiteRelayServiceConnection
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection update-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entity_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: Sites_CreateOrUpdateSiteRelayServiceConnection
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection create-or-update-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entity_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets all instance of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances
# operationId: Sites_GetSiteInstanceIdentifiers
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances get-identifiers" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/instances") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments
# operationId: Sites_GetInstanceDeployments
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-deployments list" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), instance_id: (encode-path-segment $instance_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/instances/{instance_id}/deployments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}
# operationId: Sites_DeleteInstanceDeployment
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-deployments delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), instance_id: (encode-path-segment $instance_id), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/instances/{instance_id}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}
# operationId: Sites_GetInstanceDeployment
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-deployments get" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), instance_id: (encode-path-segment $instance_id), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/instances/{instance_id}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}
# operationId: Sites_CreateInstanceDeployment
# --properties shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-deployments create" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), instance_id: (encode-path-segment $instance_id), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/instances/{instance_id}/deployments/{id}") $qp)
  let req_body = {"properties": $properties, "id": $body_id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new web app or modifies an existing web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/iscloneable
# operationId: Sites_IsSiteCloneable
export def "subscriptions-resource-groups-providers-microsoft-web-sites-iscloneable create-is-cloneable" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/iscloneable") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets metric definitions for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metricdefinitions
# operationId: Sites_GetSiteMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-sites-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets metrics for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metrics
# operationId: Sites_GetSiteMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-sites-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # If true, metric details are included in response
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a view of all network features in use on this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkFeatures/{view}
# operationId: Sites_GetSiteNetworkFeatures
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-features get" [
  subscription_id: string
  resource_group_name: string
  name: string
  view: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<hybridConnections: list<record>, virtualNetworkConnection: record<properties: record>, virtualNetworkName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), view: (encode-path-segment $view)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/networkFeatures/{view}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates new random app publishing password
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/newpassword
# operationId: Sites_GenerateNewSitePublishingPassword
export def "subscriptions-resource-groups-providers-microsoft-web-sites-newpassword generate-new-publishing-password" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/newpassword") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the operation for a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/operationresults/{operationId}
# operationId: Sites_GetSiteOperation
export def "subscriptions-resource-groups-providers-microsoft-web-sites-operationresults get-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/operationresults/{operation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons
#
# operationId: Sites_ListSitePremierAddOns
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons list-premier-create-ons" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/premieraddons") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
#
# operationId: Sites_DeleteSitePremierAddOn
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons delete-premier-create" [
  subscription_id: string
  resource_group_name: string
  name: string
  premier_add_on_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), premier_add_on_name: (encode-path-segment $premier_add_on_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/premieraddons/{premier_add_on_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
#
# operationId: Sites_GetSitePremierAddOn
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons get-premier-create" [
  subscription_id: string
  resource_group_name: string
  name: string
  premier_add_on_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), premier_add_on_name: (encode-path-segment $premier_add_on_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/premieraddons/{premier_add_on_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
#
# operationId: Sites_AddSitePremierAddOn
# --plan shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
# --sku shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons create-premier-create" [
  subscription_id: string
  resource_group_name: string
  name: string
  premier_add_on_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --location: string # Geo region resource belongs to e.g. SouthCentralUS, SouthEastAsia
  --plan: record # The plan object in an ARM, represents a marketplace plan — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --tags: record # Tags associated with resource
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), premier_add_on_name: (encode-path-segment $premier_add_on_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/premieraddons/{premier_add_on_name}") $qp)
  let req_body = {"location": $location, "plan": $plan, "properties": $properties, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the publishing profile for web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publishxml
# operationId: Sites_ListSitePublishingProfileXml
export def "subscriptions-resource-groups-providers-microsoft-web-sites-publishxml list-publishing-profile-xml" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --format: string # Name of the format. Valid values are: FileZilla3 WebDeploy -- default Ftp
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/publishxml") $qp)
  let req_body = {"format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Recovers a deleted web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/recover
# operationId: Sites_RecoverSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites-recover create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --recover-config: oneof<nothing, bool> # If true, then the website's configuration will be reverted to its state at SnapshotTime
  --site-name: string # [Optional] Destination web app name into which web app should be recovered. This is case when new web app should be created instead.
  --slot-name: string # [Optional] Destination web app slot name into which web app should be recovered
  --snapshot-time: string # Point in time in which the site recover should be attempted. (format: date-time)
]: any -> record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/recover") $qp)
  let req_body = {"recoverConfig": $recover_config, "siteName": $site_name, "slotName": $slot_name, "snapshotTime": $snapshot_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resets the configuration settings of the current slot if they were previously modified by calling ApplySlotConfig API
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/resetSlotConfig
# operationId: Sites_ResetProductionSlotConfig
export def "subscriptions-resource-groups-providers-microsoft-web-sites-reset-slot-config reset-production" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/resetSlotConfig") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restart
# operationId: Sites_RestartSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites-restart restart" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --soft-restart: oneof<nothing, bool> # Soft restart applies the configuration settings and restarts the app if necessary. Hard restart always restarts and reprovisions the app
  --synchronous: oneof<nothing, bool> # If true then the API will block until the app has been restarted
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "softRestart" $soft_restart "scalar") (serialize-qp "synchronous" $synchronous "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/restart") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the slots for a web apps
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots
# operationId: Sites_GetSiteSlots
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # List of app properties to include in the response
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: Sites_DeleteSiteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --delete-metrics: string # If true, web app metrics are also deleted
  --delete-empty-server-farm: string # If true and App Service Plan is empty after web app deletion, App Service Plan is also deleted
  --skip-dns-registration: string # If true, DNS registration is skipped
  --delete-all-slots: string # If true, all slots associated with web app are also deleted
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteMetrics" $delete_metrics "scalar") (serialize-qp "deleteEmptyServerFarm" $delete_empty_server_farm "scalar") (serialize-qp "skipDnsRegistration" $skip_dns_registration "scalar") (serialize-qp "deleteAllSlots" $delete_all_slots "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: Sites_GetSiteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --api-version: string # API Version
]: nothing -> record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertiesToInclude" $properties_to_include "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new web app or modifies an existing web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: Sites_CreateOrUpdateSiteSlot
# --properties shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, cloningInfo?: record, containerSize?: int, enabled?: bool, gatewaySiteName?: string, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, maxNumberOfWorkers?: int, microService?: string, name?: string, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --skip-dns-registration: string # If true web app hostname is not registered with DNS on creation. This parameter is only used for app creation
  --skip-custom-domain-verification: string # If true, custom (non *.azurewebsites.net) domains associated with web app are not verified.
  --force-dns-registration: string # If true, web app hostname is force registered with DNS
  --ttl-in-seconds: string # Time to live in seconds for web app's default domain name
  --api-version: string # API Version
  --properties: any # shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, cloningInfo?: record, containerSize?: int, enabled?: bool, gatewaySiteName?: string, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, maxNumberOfWorkers?: int, microService?: string, name?: string, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipDnsRegistration" $skip_dns_registration "scalar") (serialize-qp "skipCustomDomainVerification" $skip_custom_domain_verification "scalar") (serialize-qp "forceDnsRegistration" $force_dns_registration "scalar") (serialize-qp "ttlInSeconds" $ttl_in_seconds "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Applies the configuration settings from the target slot onto the current slot
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/applySlotConfig
# operationId: Sites_ApplySlotConfigSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-apply-slot-config create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/applySlotConfig") $qp)
  let req_body = {"preserveVnet": $preserve_vnet, "targetSlot": $target_slot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates web app backup
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backup
# operationId: Sites_BackupSiteSlot
# --properties shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backup create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backup") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all available backups for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups
# operationId: Sites_ListSiteBackupsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups list" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Discovers existing web app backups that can be restored
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/discover
# operationId: Sites_DiscoverSiteRestoreSlot
# --properties shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups-discover update-restore" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<adjustConnectionStrings: bool, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/discover") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a backup from Azure Storage
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}
# operationId: Sites_DeleteBackupSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backup_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets status of a web app backup that may be in progress.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}
# operationId: Sites_GetSiteBackupStatusSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups get-status" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backup_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets status of a web app backup that may be in progress, including secrets associated with the backup, such as the Azure Storage SAS URL. Also can be used to update the SAS URL for the backup if a new URL is passed in the request body.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/list
# operationId: Sites_GetSiteBackupStatusSecretsSlot
# --properties shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups-list get-status-secrets" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backup_id}/list") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Restores a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/restore
# operationId: Sites_RestoreSiteSlot
# --properties shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups-restore create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<operationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), backup_id: (encode-path-segment $backup_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backup_id}/restore") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the application settings of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings
# operationId: Sites_UpdateSiteAppSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-appsettings update-app-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the application settings of web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings/list
# operationId: Sites_ListSiteAppSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-appsettings-list list-app-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Authentication / Authorization settings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings
# operationId: Sites_UpdateSiteAuthSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-authsettings update-auth-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --aad-client-id: string
  --additional-login-params: list<string> # Gets or sets a list of login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".
  --allowed-audiences: list<string> # Gets or sets a list of allowed audience values to consider when validating JWTs issued by Azure Active Directory. Note that the {Microsoft.Web.Hosting.Administration.SiteAuthSettings.ClientId} value is always considered an allowed audience, regardless of this setting.
  --allowed-external-redirect-urls: list<string> # Gets or sets a collection of external URLs that can be redirected to as part of logging in or logging out of the web app. Note that the query string part of the URL is ignored. This is an advanced setting typically only needed by Windows Store application backends. Note that URLs within the current domain are always implicitly allowed.
  --client-id: string # Gets or sets the Client ID of this relying party application, known as the client_id. This setting is required for enabling OpenID Connection authentication with Azure Active Directory or other 3rd party OpenID Connect providers. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --client-secret: string # Gets or sets the Client Secret of this relying party application (in Azure Active Directory, this is also referred to as the Key). This setting is optional. If no client secret is configured, the OpenID Connect implicit auth flow is used to authenticate end users. Otherwise, the OpenID Connect Authorization Code Flow is used to authenticate end users. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --default-provider: string@default-provider-completer # Gets or sets the default authentication provider to use when multiple providers are configured. This setting is only needed if multiple providers are configured and the unauthenticated client action is set to "RedirectToLoginPage".
  --enabled: oneof<nothing, bool> # Gets or sets a value indicating whether the Authentication / Authorization feature is enabled for the current app.
  --facebook-app-id: string # Gets or sets the App ID of the Facebook app used for login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-app-secret: string # Gets or sets the App Secret of the Facebook app used for Facebook Login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Facebook Login authentication. This setting is optional. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --google-client-id: string # Gets or sets the OpenID Connect Client ID for the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-client-secret: string # Gets or sets the client secret associated with the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Google Sign-In authentication. This setting is optional. If not specified, "openid", "profile", and "email" are used as default scopes. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --http-api-prefix-path: string # Gets or sets the relative path prefix used by platform HTTP APIs. Changing this value is not recommended except for compatibility reasons.
  --issuer: string # Gets or sets the OpenID Connect Issuer URI that represents the entity which issues access tokens for this application. When using Azure Active Directory, this value is the URI of the directory tenant, e.g. https://sts.windows.net/{tenant-guid}/. This URI is a case-sensitive identifier for the token issuer. More information on OpenID Connect Discovery: http://openid.net/specs/openid-connect-discovery-1_0.html
  --microsoft-account-client-id: string # Gets or sets the OAuth 2.0 client ID that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-client-secret: string # Gets or sets the OAuth 2.0 client secret that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Microsoft Account authentication. This setting is optional. If not specified, "wl.basic" is used as the default scope. Microsoft Account Scopes and permissions documentation: https://msdn.microsoft.com/en-us/library/dn631845.aspx
  --open-id-issuer: string
  --token-refresh-extension-hours: float # Gets or sets the number of hours after session token expiration that a session token can be used to call the token refresh API. The default is 72 hours. (format: double)
  --token-store-enabled: oneof<nothing, bool> # Gets or sets a value indicating whether to durably store platform-specific security tokens obtained during login flows. This capability is disabled by default.
  --twitter-consumer-key: string # Gets or sets the OAuth 1.0a consumer key of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --twitter-consumer-secret: string # Gets or sets the OAuth 1.0a consumer secret of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --unauthenticated-client-action: string@unauthenticated-client-action-completer # Gets or sets the action to take when an unauthenticated client attempts to access the app.
]: any -> record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings") $qp)
  let req_body = {"aadClientId": $aad_client_id, "additionalLoginParams": $additional_login_params, "allowedAudiences": $allowed_audiences, "allowedExternalRedirectUrls": $allowed_external_redirect_urls, "clientId": $client_id, "clientSecret": $client_secret, "defaultProvider": $default_provider, "enabled": $enabled, "facebookAppId": $facebook_app_id, "facebookAppSecret": $facebook_app_secret, "facebookOAuthScopes": $facebook_o_auth_scopes, "googleClientId": $google_client_id, "googleClientSecret": $google_client_secret, "googleOAuthScopes": $google_o_auth_scopes, "httpApiPrefixPath": $http_api_prefix_path, "issuer": $issuer, "microsoftAccountClientId": $microsoft_account_client_id, "microsoftAccountClientSecret": $microsoft_account_client_secret, "microsoftAccountOAuthScopes": $microsoft_account_o_auth_scopes, "openIdIssuer": $open_id_issuer, "tokenRefreshExtensionHours": $token_refresh_extension_hours, "tokenStoreEnabled": $token_store_enabled, "twitterConsumerKey": $twitter_consumer_key, "twitterConsumerSecret": $twitter_consumer_secret, "unauthenticatedClientAction": $unauthenticated_client_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the Authentication / Authorization settings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings/list
# operationId: Sites_ListSiteAuthSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-authsettings-list list-auth-settings" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates backup configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup
# operationId: Sites_UpdateSiteBackupConfigurationSlot
# --properties shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-backup update-configuration" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the backup configuration for a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup/list
# operationId: Sites_GetSiteBackupConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-backup-list get-configuration" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the connection strings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings
# operationId: Sites_UpdateSiteConnectionStringsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-connectionstrings update-connection-strings" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: record # Connection strings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the connection strings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings/list
# operationId: Sites_ListSiteConnectionStringsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-connectionstrings-list list-connection-strings" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web app logs configuration
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs
# operationId: Sites_GetSiteLogsConfigSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-logs get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs
# operationId: Sites_UpdateSiteLogsConfigSlot
# --properties shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-logs update" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata
# operationId: Sites_UpdateSiteMetadataSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-metadata update" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the web app meta data.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata/list
# operationId: Sites_ListSiteMetadataSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-metadata-list list" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web app publishing credentials
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/publishingcredentials/list
# operationId: Sites_ListSitePublishingCredentialsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-publishingcredentials-list list-publishing-credentials" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/publishingcredentials/list") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the configuration of the web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# operationId: Sites_GetSiteConfigSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# operationId: Sites_UpdateSiteConfigSlot
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web update" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# operationId: Sites_CreateOrUpdateSiteConfigSlot
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments
# operationId: Sites_GetDeploymentsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments list" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# operationId: Sites_DeleteDeploymentSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# operationId: Sites_GetDeploymentSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# operationId: Sites_CreateDeploymentSlot
# --properties shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}") $qp)
  let req_body = {"properties": $properties, "id": $body_id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get web app hostname bindings
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings
# operationId: Sites_GetSiteHostNameBindingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings list" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a host name binding
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# operationId: Sites_DeleteSiteHostNameBindingSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), host_name: (encode-path-segment $host_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{host_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get web app binding for a hostname
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# operationId: Sites_GetSiteHostNameBindingSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), host_name: (encode-path-segment $host_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{host_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a web app hostname binding
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# operationId: Sites_CreateOrUpdateSiteHostNameBindingSlot
# --properties shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", name?: string, siteName?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  host_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", name?: string, siteName?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), host_name: (encode-path-segment $host_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{host_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves all BizTalk Hybrid Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection
# operationId: Sites_ListSiteRelayServiceConnectionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection list-relay-service-connections" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the association to a BizTalk Hybrid Connection, identified by its entity name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: Sites_DeleteSiteRelayServiceConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection delete-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entity_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a BizTalk Hybrid Connection identified by its entity name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: Sites_GetSiteRelayServiceConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection get-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entity_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: Sites_UpdateSiteRelayServiceConnectionSlot
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection update-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entity_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: Sites_CreateOrUpdateSiteRelayServiceConnectionSlot
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection create-or-update-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), entity_name: (encode-path-segment $entity_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entity_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets all instance of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances
# operationId: Sites_GetSiteInstanceIdentifiersSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances get-identifiers" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments
# operationId: Sites_GetInstanceDeploymentsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-deployments list" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), instance_id: (encode-path-segment $instance_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instance_id}/deployments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}
# operationId: Sites_DeleteInstanceDeploymentSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-deployments delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), instance_id: (encode-path-segment $instance_id), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instance_id}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}
# operationId: Sites_GetInstanceDeploymentSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-deployments get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), instance_id: (encode-path-segment $instance_id), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instance_id}/deployments/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}
# operationId: Sites_CreateInstanceDeploymentSlot
# --properties shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-deployments create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), instance_id: (encode-path-segment $instance_id), id: (encode-path-segment $id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instance_id}/deployments/{id}") $qp)
  let req_body = {"properties": $properties, "id": $body_id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new web app or modifies an existing web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/iscloneable
# operationId: Sites_IsSiteCloneableSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-iscloneable create-is-cloneable" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/iscloneable") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets metric definitions for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metricdefinitions
# operationId: Sites_GetSiteMetricDefinitionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-metricdefinitions get-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metricdefinitions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets metrics for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metrics
# operationId: Sites_GetSiteMetricsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-metrics get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # If true, metric details are included in response
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metrics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a view of all network features in use on this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkFeatures/{view}
# operationId: Sites_GetSiteNetworkFeaturesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-features get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  view: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<hybridConnections: list<record>, virtualNetworkConnection: record<properties: record>, virtualNetworkName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), view: (encode-path-segment $view)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkFeatures/{view}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates new random app publishing password
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/newpassword
# operationId: Sites_GenerateNewSitePublishingPasswordSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-newpassword generate-new-publishing-password" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/newpassword") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the operation for a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/operationresults/{operationId}
# operationId: Sites_GetSiteOperationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-operationresults get-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/operationresults/{operation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons
#
# operationId: Sites_ListSitePremierAddOnsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons list-premier-create-ons" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
#
# operationId: Sites_DeleteSitePremierAddOnSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons delete-premier-create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  premier_add_on_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), premier_add_on_name: (encode-path-segment $premier_add_on_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premier_add_on_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
#
# operationId: Sites_GetSitePremierAddOnSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons get-premier-create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  premier_add_on_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), premier_add_on_name: (encode-path-segment $premier_add_on_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premier_add_on_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
#
# operationId: Sites_AddSitePremierAddOnSlot
# --plan shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
# --sku shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons create-premier-create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  premier_add_on_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --location: string # Geo region resource belongs to e.g. SouthCentralUS, SouthEastAsia
  --plan: record # The plan object in an ARM, represents a marketplace plan — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --tags: record # Tags associated with resource
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), premier_add_on_name: (encode-path-segment $premier_add_on_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premier_add_on_name}") $qp)
  let req_body = {"location": $location, "plan": $plan, "properties": $properties, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the publishing profile for web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publishxml
# operationId: Sites_ListSitePublishingProfileXmlSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-publishxml list-publishing-profile-xml" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --format: string # Name of the format. Valid values are: FileZilla3 WebDeploy -- default Ftp
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publishxml") $qp)
  let req_body = {"format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Recovers a deleted web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/recover
# operationId: Sites_RecoverSiteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-recover create" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --recover-config: oneof<nothing, bool> # If true, then the website's configuration will be reverted to its state at SnapshotTime
  --site-name: string # [Optional] Destination web app name into which web app should be recovered. This is case when new web app should be created instead.
  --slot-name: string # [Optional] Destination web app slot name into which web app should be recovered
  --snapshot-time: string # Point in time in which the site recover should be attempted. (format: date-time)
]: any -> record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/recover") $qp)
  let req_body = {"recoverConfig": $recover_config, "siteName": $site_name, "slotName": $slot_name, "snapshotTime": $snapshot_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resets the configuration settings of the current slot if they were previously modified by calling ApplySlotConfig API
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/resetSlotConfig
# operationId: Sites_ResetSlotConfigSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-reset-slot-config reset" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/resetSlotConfig") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restart
# operationId: Sites_RestartSiteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-restart restart" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --soft-restart: oneof<nothing, bool> # Soft restart applies the configuration settings and restarts the app if necessary. Hard restart always restarts and reprovisions the app
  --synchronous: oneof<nothing, bool> # If true then the API will block until the app has been restarted
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "softRestart" $soft_restart "scalar") (serialize-qp "synchronous" $synchronous "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restart") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the difference in configuration settings between two web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsdiffs
# operationId: Sites_GetSlotsDifferencesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-slotsdiffs get-differences" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> record<nextLink: string, value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsdiffs") $qp)
  let req_body = {"preserveVnet": $preserve_vnet, "targetSlot": $target_slot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Swaps web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsswap
# operationId: Sites_SwapSlotsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-slotsswap create-swap" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsswap") $qp)
  let req_body = {"preserveVnet": $preserve_vnet, "targetSlot": $target_slot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all Snapshots to the user.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/snapshots
# operationId: Sites_GetSiteSnapshotsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-snapshots get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/snapshots") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete source control configuration of web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: Sites_DeleteSiteSourceControlSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web delete-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the source control configuration of web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: Sites_GetSiteSourceControlSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web get-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the source control configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: Sites_UpdateSiteSourceControlSlot
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web update-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the source control configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: Sites_CreateOrUpdateSiteSourceControlSlot
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web create-or-update-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/start
# operationId: Sites_StartSiteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-start start" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/start") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/stop
# operationId: Sites_StopSiteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-stop stop" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/stop") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sync
#
# operationId: Sites_SyncSiteRepositorySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sync sync-repository" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sync") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the quota usage numbers for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/usages
# operationId: Sites_GetSiteUsagesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-usages get" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --filter: string # Return only usages specified in the filter. Filter is specified by using OData syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/usages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of all Virtual Network Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections
# operationId: Sites_GetSiteVNETConnectionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections list" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the specified Virtual Network Connection association from this web app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: Sites_DeleteSiteVNETConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections delete-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific Virtual Network Connection associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: Sites_GetSiteVNETConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections get-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: Sites_UpdateSiteVNETConnectionSlot
# --properties shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: Sites_CreateOrUpdateSiteVNETConnectionSlot
# --properties shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections create-or-update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a Virtual Network connection gateway associated with this web app and virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: Sites_GetSiteVnetGatewaySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections-gateways get-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Virtual Network Gateway.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: Sites_UpdateSiteVNETConnectionGatewaySlot
# --properties shape: {vnetName?: string, vpnPackageUri?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections-gateways update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the Virtual Network Gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: Sites_CreateOrUpdateSiteVNETConnectionGatewaySlot
# --properties shape: {vnetName?: string, vpnPackageUri?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections-gateways create-or-update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), slot: (encode-path-segment $slot), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the difference in configuration settings between two web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsdiffs
# operationId: Sites_GetSlotsDifferencesFromProduction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slotsdiffs get-slots-differences-from-production" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> record<nextLink: string, value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slotsdiffs") $qp)
  let req_body = {"preserveVnet": $preserve_vnet, "targetSlot": $target_slot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Swaps web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsswap
# operationId: Sites_SwapSlotWithProduction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slotsswap create-swap-slot-with-production" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/slotsswap") $qp)
  let req_body = {"preserveVnet": $preserve_vnet, "targetSlot": $target_slot} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all Snapshots to the user.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/snapshots
# operationId: Sites_GetSiteSnapshots
export def "subscriptions-resource-groups-providers-microsoft-web-sites-snapshots get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/snapshots") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete source control configuration of web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: Sites_DeleteSiteSourceControl
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web delete-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the source control configuration of web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: Sites_GetSiteSourceControl
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web get-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the source control configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: Sites_UpdateSiteSourceControl
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web update-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the source control configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: Sites_CreateOrUpdateSiteSourceControl
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web create-or-update-source-control" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/start
# operationId: Sites_StartSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites-start start" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/start") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/stop
# operationId: Sites_StopSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites-stop stop" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/stop") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sync
#
# operationId: Sites_SyncSiteRepository
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sync sync-repository" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/sync") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the quota usage numbers for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/usages
# operationId: Sites_GetSiteUsages
export def "subscriptions-resource-groups-providers-microsoft-web-sites-usages get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --filter: string # Return only usages specified in the filter. Filter is specified by using OData syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/usages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of all Virtual Network Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections
# operationId: Sites_GetSiteVNETConnections
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the specified Virtual Network Connection association from this web app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: Sites_DeleteSiteVNETConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections delete-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific Virtual Network Connection associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: Sites_GetSiteVNETConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections get-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: Sites_UpdateSiteVNETConnection
# --properties shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: Sites_CreateOrUpdateSiteVNETConnection
# --properties shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections create-or-update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieves a Virtual Network connection gateway associated with this web app and virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: Sites_GetSiteVnetGateway
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections-gateways get-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Virtual Network Gateway.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: Sites_UpdateSiteVNETConnectionGateway
# --properties shape: {vnetName?: string, vpnPackageUri?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections-gateways update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the Virtual Network Gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: Sites_CreateOrUpdateSiteVNETConnectionGateway
# --properties shape: {vnetName?: string, vpnPackageUri?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections-gateways create-or-update-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name), vnet_name: (encode-path-segment $vnet_name), gateway_name: (encode-path-segment $gateway_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnet_name}/gateways/{gateway_name}") $qp)
  let req_body = {"properties": $properties, "id": $id, "kind": $kind, "location": $location, "name": $body_name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the list of past recommendations optionally specified by the time range.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendationHistory
# operationId: Recommendations_GetRecommendationHistoryForSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites-recommendation-history get" [
  subscription_id: string
  resource_group_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string # The start time of a time range to query, e.g. $filter=startTime eq '2015-01-01T00:00:00Z' and endTime eq '2015-01-02T00:00:00Z'
  --end-time: string # The end time of a time range to query, e.g. $filter=startTime eq '2015-01-01T00:00:00Z' and endTime eq '2015-01-02T00:00:00Z'
  --api-version: string # API Version
]: nothing -> table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), site_name: (encode-path-segment $site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{site_name}/recommendationHistory") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of recommendations associated with the specified web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendations
# operationId: Recommendations_GetRecommendedRulesForSite
export def "subscriptions-resource-groups-providers-microsoft-web-sites-recommendations get-recommended-rules" [
  subscription_id: string
  resource_group_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --featured: oneof<nothing, bool> # If set, this API returns only the most critical recommendation among the others. Otherwise this API returns all recommendations available
  --site-sku: string # The name of site SKU.
  --num-slots: int # The number of site slots associated to the site (format: int32)
  --api-version: string # API Version
]: nothing -> table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "featured" $featured "scalar") (serialize-qp "siteSku" $site_sku "scalar") (serialize-qp "numSlots" $num_slots "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), site_name: (encode-path-segment $site_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{site_name}/recommendations") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the detailed properties of the recommendation object for the specified web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendations/{name}
# operationId: Recommendations_GetRuleDetailsBySiteName
export def "subscriptions-resource-groups-providers-microsoft-web-sites-recommendations get-rule-details" [
  subscription_id: string
  resource_group_name: string
  site_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version
]: nothing -> record<actionName: string, channels: string, description: string, displayName: string, enabled: int, level: string, message: string, name: string, recommendationId: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), site_name: (encode-path-segment $site_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Web/sites/{site_name}/recommendations/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
