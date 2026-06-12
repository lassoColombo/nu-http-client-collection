# Auto-generated client for Qualtrics API v0.2
# Source: https://api.apis.guru/v2/specs/qualtrics.com/0.2/openapi.json
# Auth: --token flag or $env.QUALTRICS_API_TOKEN

const BASE_URL = "https://fra1.qualtrics.com/API/v3"
const DEFAULT_AUTH = "x-api-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o QUALTRICS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-token" => { {headers: {X-API-TOKEN: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://fra1.qualtrics.com/API/v3"] }
def auth-scheme-completer [] { ["x-api-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "directories-mailinglists-contacts CreateContactInMailinglist" } } | get name | first)
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

# Create contact in mailing list
#
# POST /directories/{DirectoryId}/mailinglists/{MailingListId}/contacts
# operationId: CreateContactInMailinglist
export def "directories-mailinglists-contacts CreateContactInMailinglist" [
  DirectoryId: string
  MailingListId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --firstName: string
  --lastName: string
  --unsubscribed: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directories/($DirectoryId)/mailinglists/($MailingListId)/contacts")
  let body = {email: $email, firstName: $firstName, lastName: $lastName, unsubscribed: $unsubscribed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get distributions for survey
#
# GET /distributions
# operationId: GetDistributions
export def "distributions GetDistributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --surveyId: string # The survey for which to load the distributions
]: nothing -> record<meta: record<httpStatus: string, requestId: string>, result: record<elements: list<record>, nextPage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "surveyId" $surveyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/distributions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate distribution links
#
# POST /distributions
# operationId: GenerateDistributionLinks
export def "distributions GenerateDistributionLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string # default: CreateDistribution
  --description: string
  --expirationDate: string # e.g. 2021-01-21 00:00:00
  --linkType: string
  --mailingListId: string
  --surveyId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/distributions")
  let body = {action: $action, description: $description, expirationDate: $expirationDate, linkType: $linkType, mailingListId: $mailingListId, surveyId: $surveyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve distribution links
#
# GET /distributions/{DistributionId}/links
# operationId: Retrievedistributionlinks
export def "distributions-links Retrievedistributionlinks" [
  DistributionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --surveyId: string # ID of the survey (eg: SV_123)
]: nothing -> record<meta: record<httpStatus: string, requestId: string>, result: record<elements: list<record>, nextPage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "surveyId" $surveyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/distributions/($DistributionId)/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove subscription to response event
#
# DELETE /eventsubscriptions/
# operationId: WebhookDelete
export def "eventsubscriptions WebhookDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encrypt: oneof<nothing, bool>
  publicationUrl: string # The internal publication URL - will be generated by PowerAutomate
  topics: string # The topics to subscribe to. Must follow the format surveyengine.completedResponse.[SurveyID] (default: surveyengine.completedResponse.<Insert SurveyID>)
]: any -> record<meta: record<httpStatus: string, requestId: string>, result: record<meta: record<httpStatus: string>, result: record<id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsubscriptions/")
  let body = {encrypt: $encrypt, publicationUrl: $publicationUrl, topics: $topics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Triggers when a response is submitted to a qualtrics survey
#
# POST /eventsubscriptions/
# operationId: WhenAResponseIsReceived
export def "eventsubscriptions WhenAResponseIsReceived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encrypt: oneof<nothing, bool>
  publicationUrl: string # The internal publication URL - will be generated by PowerAutomate
  topics: string # The topics to subscribe to. Must follow the format surveyengine.completedResponse.[SurveyID] (default: surveyengine.completedResponse.<Insert SurveyID>)
]: any -> record<meta: record<httpStatus: string, requestId: string>, result: record<meta: record<httpStatus: string>, result: record<id: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eventsubscriptions/")
  let body = {encrypt: $encrypt, publicationUrl: $publicationUrl, topics: $topics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get event subscriptions
#
# GET /eventsubscriptions/{SubscriptionId}
# operationId: GetEventSubscriptions
export def "eventsubscriptions GetEventSubscriptions" [
  SubscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<meta: record<httpStatus: string, requestId: string>, result: record<meta: record<httpStatus: string>, result: record<id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/eventsubscriptions/($SubscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get survey
#
# GET /survey-definitions/{SurveyId}
# operationId: GetSurvey
export def "survey-definitions GetSurvey" [
  SurveyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/survey-definitions/($SurveyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
