# Auto-generated client for Optimizely API v2.0
# Source: https://api.optimizely.com/swagger.json
# Auth: --token flag or $env.OPTIMIZELY_API_TOKEN

const BASE_URL = "https://api.optimizely.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPTIMIZELY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.optimizely.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["publish" "start"] }
def type-completer [] { ["other" "personalization"] }
def action-completer-1 [] { ["pause" "publish" "resume" "start" "unarchive"] }
def browser-completer [] { ["chrome" "firefox" "internet_explorer" "opera" "safari"] }
def device-completer [] { ["desktop" "ipad" "iphone" "mobile" "tablet"] }
def source-completer [] { ["campaign" "direct" "referral" "search"] }
def action-completer-2 [] { ["pause" "publish" "start"] }
def multivariate-traffic-policy-completer [] { ["full_factorial"] }
def type-completer-1 [] { ["a/b" "feature" "multiarmed_bandit" "multivariate" "personalization"] }
def list-type-completer [] { ["cookies" "js_variables" "query_parameters" "zip_codes"] }
def activation-type-completer [] { ["callback" "dom_changed" "immediate" "manual" "polling" "url_changed"] }
def category-completer [] { ["article" "cart" "category" "checkout" "home" "landing_page" "other" "pricing" "product_detail" "search_results"] }
def page-type-completer [] { ["global" "single_url" "url_set"] }
def category-completer-1 [] { ["add_to_cart" "convert" "other" "purchase" "save" "search" "share" "sign_up" "subscribe"] }
def event-type-completer [] { ["click"] }
def platform-completer [] { ["android" "custom" "ios" "web"] }
def status-completer [] { ["active" "archived"] }
def third-party-platform-completer [] { ["salesforce"] }
def event-type-completer-1 [] { ["custom"] }
def data-type-completer [] { ["user" "visitor"] }
def identifier-type-completer [] { ["dcp_id" "email" "fullstack_id" "optimizely_end_user_id" "other"] }
def request-type-completer [] { ["access" "delete"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attributes attributes" } } | get name | first)
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

# List Attributes
#
# GET /attributes
# operationId: list_attributes
export def "attributes attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The ID of the Project you would like to list all Attributes for (format: int64)
]: nothing -> table<archived: bool, condition_type: string, description: string, id: int, key: string, last_modified: string, name: string, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Attribute
#
# POST /attributes
# operationId: create_attribute
export def "attributes attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not the Attribute has been archived (default: false)
  --description: string # A short description of the Attribute
  key: string # Unique string identifier for this Attribute within the project (e.g. subscriber_status)
  --name: string # The name of the Attribute. For Full Stack projects, the name will be set to the value of the key. (e.g. Subscriber Status)
  project_id: int # The ID of the project the Attribute belongs to (format: int64, e.g. 17738411154)
]: any -> record<archived: bool, condition_type: string, description: string, id: int, key: string, last_modified: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attributes")
  let body = {archived: $archived, description: $description, key: $key, name: $name, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an Attribute
#
# DELETE /attributes/{attribute_id}
# operationId: delete_attribute
export def "attributes attribute-by-attribute_id" [
  attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attributes/($attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read an Attribute
#
# GET /attributes/{attribute_id}
# operationId: get_attribute
export def "attributes attribute-by-attribute_id-1" [
  attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, condition_type: string, description: string, id: int, key: string, last_modified: string, name: string, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attributes/($attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Attribute
#
# PATCH /attributes/{attribute_id}
# operationId: update_attribute
export def "attributes attribute-by-attribute_id-2" [
  attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not the Attribute has been archived (default: false)
  --description: string # A short description of the Attribute
  --key: string # Unique string identifier for this Attribute within the project (e.g. subscriber_status)
  --name: string # The name of the Attribute (e.g. Subscriber Status)
]: any -> record<archived: bool, condition_type: string, description: string, id: int, key: string, last_modified: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attributes/($attribute_id)")
  let body = {archived: $archived, description: $description, key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Audiences
#
# GET /audiences
# operationId: list_audiences
export def "audiences audiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The Project ID of the Project you would like to list all Audiences for (format: int64)
  --for-journey: oneof<nothing, bool> # Filter audiences by journey status
  --archived: oneof<nothing, bool> # Filter audiences by archived status
]: nothing -> table<archived: bool, conditions: string, created: string, description: string, experiment_count: int, for_journey: bool, id: int, is_classic: bool, last_modified: string, name: string, project_id: int, segmentation: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "for_journey" $for_journey "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Audience
#
# POST /audiences
# operationId: create_audience
export def "audiences audience" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether the Audience has been archived (default: false)
  --conditions: string # A string defining the targeting rules for an Audience (e.g. ["and", {"type": "language", "value": "es"}, {"type": "location", "value": "US-CA-SANFRANCISCO"}])
  --description: string # A short description of the Audience (e.g. People that speak spanish and are in San Francisco)
  --for-journey: oneof<nothing, bool> # Whether the Audience has been part of journey or not (default: false)
  --is-classic: oneof<nothing, bool> # Whether or not Audience is a classic Audience. If true, the Audience is only compatible with classic Experiments. Otherwise, the Audience may be used in Optimizely X Campaigns.
  --name: string # The name of the Audience (e.g. Spanish speaking San Franciscans)
  project_id: int # The ID of the Project the Audience was created in (format: int64, e.g. 1000)
  --segmentation: oneof<nothing, bool> # True if the Audience is available for segmentation on the results page (Audiences can only be used for segmentation in Optimizely Classic). Set to False if you intend to use this Audience only in Optimizely X. Note that a maximum of 10 Audiences can have segmentation set to True in any given Optimizely Classic project. (default: false)
]: any -> record<archived: bool, conditions: string, created: string, description: string, experiment_count: int, for_journey: bool, id: int, is_classic: bool, last_modified: string, name: string, project_id: int, segmentation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audiences")
  let body = {archived: $archived, conditions: $conditions, description: $description, for_journey: $for_journey, is_classic: $is_classic, name: $name, project_id: $project_id, segmentation: $segmentation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read an Audience
#
# GET /audiences/{audience_id}
# operationId: get_audience
export def "audiences audience-by-audience_id" [
  audience_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, conditions: string, created: string, description: string, experiment_count: int, for_journey: bool, id: int, is_classic: bool, last_modified: string, name: string, project_id: int, segmentation: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audiences/($audience_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Audience
#
# PATCH /audiences/{audience_id}
# operationId: update_audience
export def "audiences audience-by-audience_id-1" [
  audience_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # True if the Audience has been archived
  --conditions: string # A string defining the targeting rules for an Audience
  --description: string # A short description of the Audience
  --for-journey: oneof<nothing, bool> # Whether the Audience has been part of journey or not
  --name: string # The name of the Audience (e.g. Spanish speaking San Franciscans)
  --segmentation: oneof<nothing, bool> # True if the Audience is available for segmentation on the results page (Enterprise plans only)
]: any -> record<archived: bool, conditions: string, created: string, description: string, experiment_count: int, for_journey: bool, id: int, is_classic: bool, last_modified: string, name: string, project_id: int, segmentation: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audiences/($audience_id)")
  let body = {archived: $archived, conditions: $conditions, description: $description, for_journey: $for_journey, name: $name, segmentation: $segmentation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Impressions Usage
#
# GET /billing/usage/{account_id}
# operationId: get_impressions_usage_request
export def "billing-usage request" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --usage-date-from: string # Start date of date range
  --usage-date-to: string # End date of date range
  --platforms: list # The platform of the Project (default: [edge, fullstack, web])
  --qp-query: string # Search by experiment_id, project_id. (default: )
  --qp-sort: string # The property to sort by. (default: impression_count)
  --order: string # The property to sort by. (default: desc)
]: nothing -> table<experiment_id: int, experiment_name: string, experiment_status: string, impression_count: int, platform: string, project_id: int, project_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "usage_date_from" $usage_date_from "scalar") (serialize-qp "usage_date_to" $usage_date_to "scalar") (serialize-qp "platforms" $platforms "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/billing/usage/($account_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Impressions Usage Summary
#
# GET /billing/usage/{account_id}/summary
# operationId: get_impressions_usage_summary_request
export def "billing-usage-summary request" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowance: int, end_date: string, last_update_date: string, start_date: string, usage: int, usage_percentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billing/usage/($account_id)/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Campaigns
#
# GET /campaigns
# operationId: list_campaigns
export def "campaigns campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The Project ID of the Project you would like to list all Campaigns for (format: int64)
  --for-journey: oneof<nothing, bool> # Filter campaigns by journey status
  --archived: oneof<nothing, bool> # Filter campaigns by archived status
]: nothing -> table<archived: bool, changes: list<record>, created: string, custom_field_values: record, description: string, earliest: string, experiment_priorities: list<list>, for_journey: bool, holdback: int, id: int, journey_id: string, last_modified: string, latest: string, metrics: list<record>, name: string, page_ids: list<int>, project_id: int, status: string, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "for_journey" $for_journey "scalar") (serialize-qp "archived" $archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Campaign
#
# POST /campaigns
# operationId: create_campaign
# --changes item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
# --metrics item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
# --url_targeting shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
export def "campaigns campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer # Action to change the state of the Campaign. 'publish' publishes your campaign, making any changes live to the world. Status will be 'paused'. 'start' publishes your campaign, making any changes live to the world. Status will be 'running'.
  --archived: oneof<nothing, bool> # Whether the Campaign has been archived (default: false)
  --changes: list # A list of changes to apply to the Campaign.  This corresponds to the Campaign's Shared Code in the application.  Only supports 'custom_css' or 'custom_code' type changes. — item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
  --custom-field-values: record # Map of custom field `api_name` to value for this Campaign. Keys correspond to the `api_name` of a custom field definition for the Project, and values are typed according to that definition's `field_type`. Returns an empty object when no values are set.
  --description: string # The description or goal for a Campaign (e.g. Tailor the landing page hero element for specific audiences)
  --experiment-priorities: list # A list of lists of Experiment IDs that indicate the relative priority of how to show those Experiments in the context of the Campaign. Each list inside of the list represents a group of Experiments of equal priority where groups that appear earlier in the list are of higher priority to be shown.
  --for-journey: oneof<nothing, bool> # Whether the Campaign has been part of journey or not (default: false)
  --holdback: int # Percentage of visitors to exclude from personalization, measured in basis points. 100 basis points = 1% traffic. For example, a value of 500 would mean that 95% of visitors will see a personalized experience and 5% will see the holdback. (e.g. 500)
  --journey-id: string # The ID of the journey the Campaign is part of
  --metrics: list # An ordered list of metrics to track for the Campaign — item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
  --name: string # The name of the Campaign (e.g. Landing Page Optimization)
  --page-ids: list # A list of Page IDs used in the Campaign
  project_id: int # The Project ID the Campaign is in (format: int64, e.g. 1000)
  --type: string@type-completer # Indicates the type of this campaign. Campaigns created or fetched via the API should currently all have a type of `personalization`, but if you get a campaign_id for an experiment and look it up, you may get an `other` value. (default: personalization)
  --url-targeting: record # shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
]: any -> record<archived: bool, changes: table<async: bool, dependencies: list, id: string, name: string, selector: string, src: string, type: string, value: string>, created: string, custom_field_values: record, description: string, earliest: string, experiment_priorities: list<list<int>>, for_journey: bool, holdback: int, id: int, journey_id: string, last_modified: string, latest: string, metrics: table<aggregator: string, display_title: string, event_id: int, event_properties: record, field: string, metrics: list, scope: string, time_window: string, winning_direction: string>, name: string, page_ids: list<int>, project_id: int, status: string, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns" $qp)
  let body = {archived: $archived, changes: $changes, custom_field_values: $custom_field_values, description: $description, experiment_priorities: $experiment_priorities, for_journey: $for_journey, holdback: $holdback, journey_id: $journey_id, metrics: $metrics, name: $name, page_ids: $page_ids, project_id: $project_id, type: $type, url_targeting: $url_targeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a Campaign
#
# DELETE /campaigns/{campaign_id}
# operationId: delete_campaign
export def "campaigns campaign-by-campaign_id" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a Campaign
#
# GET /campaigns/{campaign_id}
# operationId: get_campaign
export def "campaigns campaign-by-campaign_id-1" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, changes: table<async: bool, dependencies: list, id: string, name: string, selector: string, src: string, type: string, value: string>, created: string, custom_field_values: record, description: string, earliest: string, experiment_priorities: list<list<int>>, for_journey: bool, holdback: int, id: int, journey_id: string, last_modified: string, latest: string, metrics: table<aggregator: string, display_title: string, event_id: int, event_properties: record, field: string, metrics: list, scope: string, time_window: string, winning_direction: string>, name: string, page_ids: list<int>, project_id: int, status: string, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Campaign
#
# PATCH /campaigns/{campaign_id}
# operationId: update_campaign
# --changes item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
# --metrics item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
# --url_targeting shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
export def "campaigns campaign-by-campaign_id-2" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-1 # Action to change the state of the Campaign. 'publish' publishes your campaign, making any changes live to the world without changing the status of the campaign. 'start' publishes your campaign, making any changes live to the world. Status will be 'running'. 'pause' stops the campaign. Status will be 'paused'. No new visitors will see the campaign until it is resumed. 'resume' resumes the campaign from a paused status without publishing any new changes. Status will be 'running'. 'unarchive' unarchives an archived campaign. Status will be 'paused'.
  --changes: list # A list of changes to apply to the Campaign — item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
  --description: string # The description or goal for a Campaign (e.g. Tailor the landing page hero element for specific audiences)
  --experiment-priorities: list # A list of lists of Experiment IDs that indicate the relative priority of how to show those Experiments in the context of the Campaign. Each list inside of the list represents a group of Experiments of equal priority where groups that appear earlier in the list are of higher priority to be shown.
  --for-journey: oneof<nothing, bool> # Whether the Campaign has been part of journey or not
  --holdback: int # Percentage of visitors to exclude from personalization, measured in basis points. 100 basis points = 1% traffic. For example, a value of 500 would mean that 95% of visitors will see a personalized experience and 5% will see the holdback. (e.g. 500)
  --journey-id: string # The ID of the journey the Campaign is part of
  --metrics: list # An ordered list of metrics to track for the Campaign — item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
  --name: string # The name of the Campaign (e.g. Landing Page Optimization)
  --page-ids: list # A list of Page IDs used in the Campaign.  Only `url_targeting` or `page_ids` can be used when updating a Campaign, but not both.
  --url-targeting: record # shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
]: any -> record<archived: bool, changes: table<async: bool, dependencies: list, id: string, name: string, selector: string, src: string, type: string, value: string>, created: string, custom_field_values: record, description: string, earliest: string, experiment_priorities: list<list<int>>, for_journey: bool, holdback: int, id: int, journey_id: string, last_modified: string, latest: string, metrics: table<aggregator: string, display_title: string, event_id: int, event_properties: record, field: string, metrics: list, scope: string, time_window: string, winning_direction: string>, name: string, page_ids: list<int>, project_id: int, status: string, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)" $qp)
  let body = {changes: $changes, description: $description, experiment_priorities: $experiment_priorities, for_journey: $for_journey, holdback: $holdback, journey_id: $journey_id, metrics: $metrics, name: $name, page_ids: $page_ids, url_targeting: $url_targeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Campaign results
#
# GET /campaigns/{campaign_id}/results
# operationId: get_campaign_results
export def "campaigns-results results" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: string # The start time of the time interval (beginning time included) used to calculate the results over. If unspecified, defaults to the time that the Campaign was first activated. The start time will be rounded the smallest time modulo 5 minutes larger or equal to start_time. (format: date-time)
  --end-time: string # The end of the time interval (end time excluded) used to calculate results over. If unspecified, defaults to the current time if the Experiment is still running, otherwise defaults to the time the experiment was last active. The end time will be rounded to the largest time modulo 5 minutes smaller or equal to end_time. The end_time in the response may be earlier than requested if fresher results are not available yet. In this case, the results will continue to calculate in the background and subsequent requests will eventually return the full results. (format: date-time)
  --browser: string@browser-completer # Browser to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [device, source, attribute_id, attribute_value].
  --device: string@device-completer # Device to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, source, attribute_id, attribute_value].
  --qp-source: string@source-completer # Source to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, device, attribute_id, attribute_value]. Campaign: Contains users that arrive on a URL containing a 'utm_campaign,' 'utm_source,' 'gclid,' or 'otm_source' query parameter. If the URL contains one of these parameters, the visitor will count as "Campaign" traffic even if they arrived through search. Direct:  Includes all users who do not have any external referrer in their URL. Referral: Includes all users that come from another URL that doesn't count as Campaign.
  --attribute-id: int # ID of the attribute to segment results by. Requests containing attribute_id will return the results for all visitors that have attribute_value for the attribute represented by attribute_id. If present, the attribute_value parameter must also be present, and it cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].  (format: int64)
  --attribute-value: string # UTF-8 encoded value correlating to attribute_id. If present, the attribute_id parameter must also be present. This parameter also requires attribute_id to be set, and cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].
  --segment-conditions: string # (BETA) A string representation of a JSON Segment Conditions Expression. This parameter can be either URL-escaped stringified JSON or Base64-encoded stringified JSON using URL-safe alphabet (preferred). Segment Conditions Expressions consist of Logical Expressions and Match Expressions. Logical Expressions are represented as an array of the format [<operator>, <expression>...], where the supported operators are "and", "or" and "not". Match Expressions are represented as an object of the format {"attribute_id": <attribute_id>, "attribute_value": <value>[, "match_type": <match_type>]}, where supported values for match_type are "exact" match type will match only an exact string match between "value" string and the attribute value. "substring" match type will match if "value" is a substring of the attribute value. "prefix" match type will match if "value" is a string prefix of the attribute value. "regex" match type will match if "value" is a regular expression match for the attribute value. The default match_type is "exact".
]: nothing -> record<campaign_id: int, confidence_threshold: float, end_time: string, is_stale: bool, metrics: table<aggregator: string, event_id: int, event_properties: record, field: string, metrics: list, name: string, results: record, scope: string, time_window: string, winning_direction: string>, start_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "browser" $browser "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_value" $attribute_value "scalar") (serialize-qp "segment_conditions" $segment_conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/campaigns/($campaign_id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve changes for a project.
#
# GET /changes
# operationId: list_change_history
export def "changes history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: int # ID of the Project you want to list changes for. (format: int64)
  --id: list # A specific Change ID to filter by. Can be specified multiple times to include multiple specific changes.
  --start-time: string # Start of the time interval (inclusive) to list changes. The time is formatted in ISO 8601. (format: date-time)
  --end-time: string # End of the time interval (exclusive) to look for changes. The time is formatted in ISO 8601. (format: date-time)
  --user: list # Email of the user who made the change. Can be specified multiple times to include changes from multiple users.
  --entity-type: list # The type of the entity. The entity_type must be one of the following : attribute, audience, campaign, environment, event, experiment, extension, feature, flag, group, list_attribute, metrics, page, project, report, rule, ruleset, section, tag, variation, variable, permission, team. Can be specified multiple times to include changes for multiple entity types.
  --qp-source: string # The source of the change (UI or API)
  --entity: list # Colon (:) delimited string containing the entity_type and entity_id of the entity wanted. The entity_type must be one of the following : attribute, audience, campaign, environment, event, experiment, extension, feature, flag, group, list_attribute, metrics, page, project, report, rule, ruleset, section, tag, variation, variable, permission e.g. ruleset:123, experiment:123. Can be specified multiple times to filter changes to a specific set of entities.
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
]: nothing -> table<change_type: string, changes: list<record>, created: string, entity: record<api_url: string, id: int, name: string, sub_type: string, type: string, ui_url: string>, id: int, project_id: int, revisions: record<current: record, previous: record>, source: string, summary: string, user: record<display_name: string, email: string, first_name: string, id: string, last_name: string, profile_image_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "user" $user "multi") (serialize-qp "entity_type" $entity_type "multi") (serialize-qp "source" $qp_source "scalar") (serialize-qp "entity" $entity "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Environments by Project
#
# GET /environments
# operationId: list_environments
export def "environments environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The ID of the project for which you would like to get Environments (format: int64)
]: nothing -> table<archived: bool, created: string, datafile: record<id: int, latest_file_size: int, other_urls: list, revision: int, sdk_key: string, url: string>, description: string, has_restricted_permissions: bool, id: int, is_primary: bool, key: string, last_modified: string, name: string, priority: int, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Environment
#
# POST /environments
# operationId: create_environment
export def "environments environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Boolean representing whether the Environment is archived. (e.g. false)
  --datafile: record
  --description: string # A short description of the Environment. (e.g. For testing purposes before deploying to Production)
  --has-restricted-permissions: oneof<nothing, bool> # Boolean representing whether starting experiments should be restricted to publishers and above in this Environment. (default: false)
  key: string # Unique string identifier for this Environment within the Project.
  name: string # Name of the Environment. (e.g. Staging)
  --priority: int # Integer representing the priority of the Environment. This is used for ordering in the UI. (e.g. 3)
  project_id: int # ID of the project of the Environment.
]: any -> record<archived: bool, created: string, datafile: record<id: int, latest_file_size: int, other_urls: list<string>, revision: int, sdk_key: string, url: string>, description: string, has_restricted_permissions: bool, id: int, is_primary: bool, key: string, last_modified: string, name: string, priority: int, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let body = {archived: $archived, datafile: $datafile, description: $description, has_restricted_permissions: $has_restricted_permissions, key: $key, name: $name, priority: $priority, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an Environment
#
# DELETE /environments/{environment_id}
# operationId: delete_environment
export def "environments environment-by-environment_id" [
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read an Environment
#
# GET /environments/{environment_id}
# operationId: get_environment
export def "environments environment-by-environment_id-1" [
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, created: string, datafile: record<id: int, latest_file_size: int, other_urls: list<string>, revision: int, sdk_key: string, url: string>, description: string, has_restricted_permissions: bool, id: int, is_primary: bool, key: string, last_modified: string, name: string, priority: int, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Environment
#
# PATCH /environments/{environment_id}
# operationId: update_environment
export def "environments environment-by-environment_id-2" [
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Boolean representing whether the Environment is archived. (e.g. false)
  --description: string # Text description of the Environment. (e.g. For testing purposes before deploying to Production)
  --has-restricted-permissions: oneof<nothing, bool> # Boolean representing whether starting experiments should be restricted to publishers and above in this Environment. (default: false)
  --key: string # Unique string identifier for this Environment within the Project.
  --name: string # Name of the Environment. (e.g. Staging)
  --priority: int # Integer representing the priority of the Environment. This is used for ordering in the UI. (e.g. 3)
]: any -> record<archived: bool, created: string, datafile: record<id: int, latest_file_size: int, other_urls: list<string>, revision: int, sdk_key: string, url: string>, description: string, has_restricted_permissions: bool, id: int, is_primary: bool, key: string, last_modified: string, name: string, priority: int, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environment_id)")
  let body = {archived: $archived, description: $description, has_restricted_permissions: $has_restricted_permissions, key: $key, name: $name, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read the datafile of an Environment
#
# GET /environments/{environment_id}/datafile
# operationId: get_datafile
export def "environments-datafile datafile" [
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environment_id)/datafile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Events
#
# GET /events
# operationId: list_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The ID of the Project you would like to list all Events for (format: int64)
  --include-classic: oneof<nothing, bool> # Whether or not to include classic Events in the list of Events. If this parameter is not provided it will default to false (default: false)
]: nothing -> table<archived: bool, category: string, config: record<selector: string>, created: string, description: string, event_properties: list<record>, event_type: string, id: int, is_classic: bool, is_editable: bool, key: string, last_modified: string, name: string, page_id: int, project_id: int, variation_specific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "include_classic" $include_classic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Event by ID
#
# GET /events/{event_id}
# operationId: get_event
export def "events event" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-classic: oneof<nothing, bool> # Whether or not to return a classic Event if the specified event_id belongs to a classic Event. If this parameter is not provided it will default to false
]: nothing -> record<archived: bool, category: string, config: record<selector: string>, created: string, description: string, event_properties: table<data_type: string, name: string>, event_type: string, id: int, is_classic: bool, is_editable: bool, key: string, last_modified: string, name: string, page_id: int, project_id: int, variation_specific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_classic" $include_classic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Experiments
#
# GET /experiments
# operationId: list_experiments
export def "experiments experiments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The Project ID of the Project you would like to list all Experiments for. You have to either use this argument or the campaign_id argument (format: int64)
  --campaign-id: int # The Campaign ID of the Campaign you would like to list all Experiments for. You have to either use this argument or the project_id argument (format: int64)
  --include-classic: oneof<nothing, bool> # Whether or not to include classic Experiments in the list of Experiments. If this parameter is not provided it will default to false (default: false)
]: nothing -> table<allocation_policy: string, audience_conditions: string, campaign_id: int, changes: list<record>, created: string, custom_field_values: record, description: string, earliest: string, environments: record, feature_id: int, feature_key: string, feature_name: string, holdback: int, id: int, is_classic: bool, key: string, last_modified: string, latest: string, metrics: list<record>, multivariate_traffic_policy: string, name: string, page_ids: list<int>, project_id: int, results_token: string, schedule: record<start_time: string, stop_time: string, time_zone: string>, status: string, traffic_allocation: int, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>, variations: list<record>, whitelist: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "campaign_id" $campaign_id "scalar") (serialize-qp "include_classic" $include_classic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/experiments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Experiment
#
# POST /experiments
# operationId: create_experiment
# --changes item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
# --metrics item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
# --schedule shape: {start_time?: string, stop_time?: string, time_zone?: string}
# --url_targeting shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
# --variations item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, weight: int}
# --whitelist item shape: {user_id: string, variation_id: int}
export def "experiments experiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-2 # Action to change the state of the experiment. `publish` saves and stages your experiment. If you have not started your experiment or the experiment is paused, your changes will not be visible to visitors when you publish. `start` makes your experiment live to all visitors who are in your targeted audience and changes the status to `running`. `pause` stops the experiment and changes the status to `paused`. No new visitors will see a `paused` experiment until you restart it. See [Differences among publish, start, and pause](https://help.optimizely.com/Get_Started/Differences_among_publish%2C_start%2C_and_pause) for details.
  --audience-conditions: string # The audiences that should see this experiment. To target everyone, use the string "everyone" or omit this field. Multiple audiences can be combined with "and" or "or" using the same structure as audience conditions (default: everyone, e.g. ["and", {"audience_id": 7000}, {"audience_id":7001}])
  --campaign-id: int # For Personalization experiences, this ID corresponds to the parent Campaign. For standalone experiments this campaign_id does not correspond to a campaign object. (format: int64, e.g. 2000)
  --changes: list # Custom CSS or JavaScript that will run before all variations in the Experiment (for Experiments in Web Projects only) — item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
  --description: string # The description or hypothesis for an Experiment
  --environments: record # String identifier for the Experiment's status in each Environment based on the environment key.
  --feature-id: int # The ID of a Feature to attach to the Experiment. This turns an Experiment into a Feature Test. (format: int64, e.g. 1000)
  --feature-key: string # The key for the Feature attached to the Experiment. Applies to Feature Tests only. Valid keys contain alphanumeric characters, hyphens, and underscores, and are limited to 64 characters.
  --feature-name: string # The feature flag name to display in the Optimizely app. Whitespaces and other non-alphanumeric characters allowed. Defaults to feature key if left empty. (e.g. This is the user search feature)
  --holdback: int # Percent of traffic to exclude from the experiment, measured in basis points. 100 basis points = 1% traffic. For example, a value of 9900 would mean that 1% of visitors will be eligible for the experiment. This is only applicable for Web. (e.g. 5000)
  --key: string # Unique string identifier for this Experiment within the Project. Only applicable for Full Stack and Mobile projects. (e.g. home_page_experiment)
  --metrics: list # An ordered list of metrics to track for the Experiment. Required for Web, Full Stack, and Mobile Experimentation. Not applicable for Web Personalization Experiences. (default: []) — item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
  --multivariate-traffic-policy: string@multivariate-traffic-policy-completer # For Experiments of type `multivariate`, this specifies how the weights and statuses of combinations will be decided. In `full_factorial` mode, | combination weights are read-only, and are generated by multiplying together weights of section variations.
  --name: string # Name of the Experiment. Required for Web Experimentation. Optional for Web Personalization experiences and Full Stack experiments. Not applicable for Mobile Experiments. (e.g. Blue Button Experiment)
  --page-ids: list # A list of Page IDs used in the Experiment.  `url_targeting` or `page_ids`, but not both.
  project_id: int # The Project the Experiment is in (format: int64, e.g. 1000)
  --results-token: string # temporary token based on experiment id, used to access data platform services from other parts of the product
  --schedule: record # shape: {start_time?: string, stop_time?: string, time_zone?: string}
  --traffic-allocation: int # Percent of traffic allocated for the experiment, measured in basis points. 100 basis points = 1% traffic. For example, a value of 5500 would mean that 55% of visitors will be eligible for the experiment. This is only applicable for Full Stack. (e.g. 5000)
  --type: string@type-completer-1 # Indicates whether this is an `a/b`, `multivariate`, `feature`, or `multiarmed_bandit` test or an experience within a `personalization` campaign. Note that the default for this field is `a/b`. If another test type is desired, populate this field with the appropriate string (from one of the possible values). (default: a/b)
  --url-targeting: record # shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
  --variations: list # A list of variations that each define an experience to show in the context of the Experiment for the purpose of comparison against each other — item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, weight: int}
  --whitelist: list # A list containing the user IDs and variations of users who have been whitelisted — item shape: {user_id: string, variation_id: int}
]: any -> record<allocation_policy: string, audience_conditions: string, campaign_id: int, changes: table<async: bool, dependencies: list, id: string, name: string, selector: string, src: string, type: string, value: string>, created: string, custom_field_values: record, description: string, earliest: string, environments: record, feature_id: int, feature_key: string, feature_name: string, holdback: int, id: int, is_classic: bool, key: string, last_modified: string, latest: string, metrics: table<aggregator: string, display_title: string, event_id: int, event_properties: record, field: string, metrics: list, scope: string, time_window: string, winning_direction: string>, multivariate_traffic_policy: string, name: string, page_ids: list<int>, project_id: int, results_token: string, schedule: record<start_time: string, stop_time: string, time_zone: string>, status: string, traffic_allocation: int, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>, variations: table<actions: list, archived: bool, description: string, feature_enabled: bool, key: string, name: string, status: string, variable_values: record, variation_id: int, weight: int>, whitelist: table<user_id: string, variation_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/experiments" $qp)
  let body = {audience_conditions: $audience_conditions, campaign_id: $campaign_id, changes: $changes, description: $description, environments: $environments, feature_id: $feature_id, feature_key: $feature_key, feature_name: $feature_name, holdback: $holdback, key: $key, metrics: $metrics, multivariate_traffic_policy: $multivariate_traffic_policy, name: $name, page_ids: $page_ids, project_id: $project_id, results_token: $results_token, schedule: $schedule, traffic_allocation: $traffic_allocation, type: $type, url_targeting: $url_targeting, variations: $variations, whitelist: $whitelist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an Experiment
#
# DELETE /experiments/{experiment_id}
# operationId: delete_experiment
export def "experiments experiment-by-experiment_id" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/experiments/($experiment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read an Experiment
#
# GET /experiments/{experiment_id}
# operationId: get_experiment
export def "experiments experiment-by-experiment_id-1" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allocation_policy: string, audience_conditions: string, campaign_id: int, changes: table<async: bool, dependencies: list, id: string, name: string, selector: string, src: string, type: string, value: string>, created: string, custom_field_values: record, description: string, earliest: string, environments: record, feature_id: int, feature_key: string, feature_name: string, holdback: int, id: int, is_classic: bool, key: string, last_modified: string, latest: string, metrics: table<aggregator: string, display_title: string, event_id: int, event_properties: record, field: string, metrics: list, scope: string, time_window: string, winning_direction: string>, multivariate_traffic_policy: string, name: string, page_ids: list<int>, project_id: int, results_token: string, schedule: record<start_time: string, stop_time: string, time_zone: string>, status: string, traffic_allocation: int, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>, variations: table<actions: list, archived: bool, description: string, feature_enabled: bool, key: string, name: string, status: string, variable_values: record, variation_id: int, weight: int>, whitelist: table<user_id: string, variation_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/experiments/($experiment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Experiment
#
# PATCH /experiments/{experiment_id}
# operationId: update_experiment
# --changes item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
# --metrics item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
# --schedule shape: {start_time?: string, stop_time?: string, time_zone?: string}
# --url_targeting shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
# --variations item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, variation_id?: int, weight: int}
# --whitelist item shape: {user_id: string, variation_id: int}
export def "experiments experiment-by-experiment_id-2" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-1 # Action to change the state of the experiment. `publish` saves and stages your experiment. If you have not started your experiment or the experiment is paused, your changes will not be visible to visitors when you publish. `start` makes your experiment live to all visitors who are in your targeted audience and changes the status to `running`. `pause` stops the experiment and changes the status to `paused`. No new visitors will see a `paused` experiment until you restart it. See [Differences among publish, start, and pause](https://help.optimizely.com/Get_Started/Differences_among_publish%2C_start%2C_and_pause) for details. `resume` resumes the experiment from a paused status without publishing any new changes. Status will be `running`. `unarchive` unarchives an archived experiment. Status will be `paused`.
  --audience-conditions: string # The audiences that should see this experiment. To target everyone, use the string "everyone". Multiple audiences can be combined with "and" or "or" using the same structure as audience conditions (e.g. ["and", {"audience_id": 7000}, {"audience_id": 7001}])
  --changes: list # Custom CSS or JavaScript that will run before all variations in the Experiment (for Experiments in Web Projects only) — item shape: {async?: bool, dependencies?: list, name?: string, selector?: string, type: "custom_code"|"custom_css", value: string}
  --description: string # The description or hypothesis for an Experiment (e.g. AB Test to see if the Blue Button converts more visitors)
  --environments: record # String identifier for the Experiment's status in each Environment based on the environment key.
  --feature-id: int # The ID of a Feature to attach to the Experiment. This turns an Experiment into a Feature Test. (format: int64, e.g. 1000)
  --holdback: int # Percent of traffic to exclude from the experiment, measured in basis points. 100 basis points = 1% traffic. For example, a value of 9900 would mean that 1% of visitors will be eligible for the experiment. This is only applicable for Web. (e.g. 5000)
  --key: string # Unique string identifier for this Experiment within the Project. Only applicable for Full Stack and Mobile projects. (e.g. home_page_experiment)
  --metrics: list # An ordered list of metrics to track for the Experiment — item shape: {aggregator?: "unique"|"count"|"sum"|"bounce"|"exit"|"ratio", display_title?: string, event_id?: int, event_properties?: record, field?: "revenue"|"value", metrics?: list, scope?: "session"|"visitor"|"event", time_window?: string, winning_direction?: "increasing"|"decreasing"}
  --name: string # Name of the Experiment (e.g. Blue Button Experiment)
  --page-ids: list # A list of Page IDs used in the Experiment.  Only `url_targeting` or `page_ids` can be used when updating an experiment, but not both.
  --schedule: record # shape: {start_time?: string, stop_time?: string, time_zone?: string}
  --traffic-allocation: int # Percent of traffic allocated for the experiment, measured in basis points. 100 basis points = 1% traffic. For example, a value of 5500 would mean that 55% of visitors will be eligible for the experiment. This is only applicable for Full Stack. (e.g. 5000)
  --url-targeting: record # shape: {activation_code?: string, activation_type?: "immediate"|"manual"|"polling"|"callback"|"dom_changed"|"url_changed", conditions?: string, edit_url: string, key?: string}
  --variations: list # List of IDs of all variations in the Experiment — item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, variation_id?: int, weight: int}
  --whitelist: list # A list containing the user IDs and variations of users who have been whitelisted — item shape: {user_id: string, variation_id: int}
]: any -> record<allocation_policy: string, audience_conditions: string, campaign_id: int, changes: table<async: bool, dependencies: list, id: string, name: string, selector: string, src: string, type: string, value: string>, created: string, custom_field_values: record, description: string, earliest: string, environments: record, feature_id: int, feature_key: string, feature_name: string, holdback: int, id: int, is_classic: bool, key: string, last_modified: string, latest: string, metrics: table<aggregator: string, display_title: string, event_id: int, event_properties: record, field: string, metrics: list, scope: string, time_window: string, winning_direction: string>, multivariate_traffic_policy: string, name: string, page_ids: list<int>, project_id: int, results_token: string, schedule: record<start_time: string, stop_time: string, time_zone: string>, status: string, traffic_allocation: int, type: string, url_targeting: record<activation_code: string, activation_type: string, conditions: string, edit_url: string, key: string, page_id: int>, variations: table<actions: list, archived: bool, description: string, feature_enabled: bool, key: string, name: string, status: string, variable_values: record, variation_id: int, weight: int>, whitelist: table<user_id: string, variation_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/experiments/($experiment_id)" $qp)
  let body = {audience_conditions: $audience_conditions, changes: $changes, description: $description, environments: $environments, feature_id: $feature_id, holdback: $holdback, key: $key, metrics: $metrics, name: $name, page_ids: $page_ids, schedule: $schedule, traffic_allocation: $traffic_allocation, url_targeting: $url_targeting, variations: $variations, whitelist: $whitelist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Experiment results
#
# GET /experiments/{experiment_id}/results
# operationId: get_experiment_results
export def "experiments-results results" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseline-variation-id: string # The ID of the variation to use as the baseline to compare against other variations. Defaults to the first variation if not provided. For an experience in a personalization campaign, the value can also be the string 'holdback'. (format: int64)
  --start-time: string # The start time of the time interval (beginning time included) used to calculate the results over. If unspecified, defaults to the time that the Experiment was first activated. The start time will be rounded the smallest time modulo 5 minutes larger or equal to start_time. (format: date-time)
  --end-time: string # The end of the time interval (end time excluded) used to calculate results over. If unspecified, defaults to the current time if the Experiment is still running, otherwise defaults to the time the experiment was last active. The end time will be rounded to the largest time modulo 5 minutes smaller or equal to end_time. The end_time in the response may be earlier than requested if fresher results are not available yet. In this case, the results will continue to calculate in the background and subsequent requests will eventually return the full results. (format: date-time)
  --browser: string@browser-completer # Browser to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [device, source, attribute_id, attribute_value].
  --device: string@device-completer # Device to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, source, attribute_id, attribute_value].
  --qp-source: string@source-completer # Source to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, device, attribute_id, attribute_value]. Campaign: Contains users that arrive on a URL containing a 'utm_campaign,' 'utm_source,' 'gclid,' or 'otm_source' query parameter. If the URL contains one of these parameters, the visitor will count as "Campaign" traffic even if they arrived through search. Direct:  Includes all users who do not have any external referrer in their URL. Referral: Includes all users that come from another URL that doesn't count as Campaign.
  --attribute-id: int # ID of the attribute to segment results by. Requests containing attribute_id will return the results for all visitors that have attribute_value for the attribute represented by attribute_id. If present, the attribute_value parameter must also be present, and it cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].  (format: int64)
  --attribute-value: string # UTF-8 encoded value correlating to attribute_id. If present, the attribute_id parameter must also be present. This parameter also requires attribute_id to be set, and cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].
  --segment-conditions: string # (BETA) A string representation of a JSON Segment Conditions Expression. This parameter can be either URL-escaped stringified JSON or Base64-encoded stringified JSON using URL-safe alphabet (preferred). Segment Conditions Expressions consist of Logical Expressions and Match Expressions. Logical Expressions are represented as an array of the format [<operator>, <expression>...], where the supported operators are "and", "or" and "not". Match Expressions are represented as an object of the format {"attribute_id": <attribute_id>, "attribute_value": <value>[, "match_type": <match_type>]}, where supported values for match_type are "exact" match type will match only an exact string match between "value" string and the attribute value. "substring" match type will match if "value" is a substring of the attribute value. "prefix" match type will match if "value" is a string prefix of the attribute value. "regex" match type will match if "value" is a regular expression match for the attribute value. The default match_type is "exact".
]: nothing -> record<confidence_threshold: float, end_time: string, experiment_id: int, is_stale: bool, metrics: table<aggregator: string, conclusion: record, event_id: int, event_properties: record, field: string, metrics: list, name: string, results: record, scope: string, time_window: string, winning_direction: string>, reach: record<baseline_count: int, baseline_reach: float, total_count: int, treatment_count: int, treatment_reach: float, variations: record>, start_time: string, stats_config: record<confidence_level: float, difference_type: string, epoch_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseline_variation_id" $baseline_variation_id "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "browser" $browser "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_value" $attribute_value "scalar") (serialize-qp "segment_conditions" $segment_conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/experiments/($experiment_id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read all the Sections in a Multivariate Test
#
# GET /experiments/{experiment_id}/sections
# operationId: get_experiment_sections
export def "experiments-sections sections" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
]: nothing -> table<archived: bool, description: string, experiment_id: int, id: int, name: string, project_id: int, variations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/experiments/($experiment_id)/sections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Section in a Multivariate Test
#
# POST /experiments/{experiment_id}/sections
# operationId: create_section
# --variations item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, weight: int}
export def "experiments-sections section-by-experiment_id" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not the Section has been archived (default: false)
  --description: string # A short description of this Section
  --body-experiment-id: int # The ID of the Multivariate Test this Section belongs to
  --id: int # The ID of this Section
  --name: string # The name of this Section (e.g. Headline Variations)
  --project-id: int # The ID of the project that this Section belongs to
  variations: list # item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, weight: int}
]: any -> record<archived: bool, description: string, experiment_id: int, id: int, name: string, project_id: int, variations: table<actions: list, archived: bool, description: string, feature_enabled: bool, key: string, name: string, status: string, variable_values: record, variation_id: int, weight: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/experiments/($experiment_id)/sections")
  let body = {archived: $archived, description: $description, experiment_id: $body_experiment_id, id: $id, name: $name, project_id: $project_id, variations: $variations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a Section by ID
#
# DELETE /experiments/{experiment_id}/sections/{section_id}
# operationId: delete_section
export def "experiments-sections section-by-section_id-experiment_id" [
  section_id: int
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/experiments/($experiment_id)/sections/($section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a Section of a Multivariate Test
#
# GET /experiments/{experiment_id}/sections/{section_id}
# operationId: get_section
export def "experiments-sections section-by-section_id-experiment_id-1" [
  section_id: int
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, description: string, experiment_id: int, id: int, name: string, project_id: int, variations: table<actions: list, archived: bool, description: string, feature_enabled: bool, key: string, name: string, status: string, variable_values: record, variation_id: int, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/experiments/($experiment_id)/sections/($section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Section by ID
#
# PATCH /experiments/{experiment_id}/sections/{section_id}
# operationId: update_section
# --variations item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, weight: int}
export def "experiments-sections section-by-section_id-experiment_id-2" [
  section_id: int
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not the Section has been archived (default: false)
  --description: string # A short description of this Section
  --name: string # The name of this Section (e.g. Headline Variations)
  --variations: list # item shape: {actions?: list, archived?: bool, description?: string, feature_enabled?: bool, key?: string, name?: string, status?: "active"|"paused"|"archived", variable_values?: record, weight: int}
]: any -> record<archived: bool, description: string, experiment_id: int, id: int, name: string, project_id: int, variations: table<actions: list, archived: bool, description: string, feature_enabled: bool, key: string, name: string, status: string, variable_values: record, variation_id: int, weight: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/experiments/($experiment_id)/sections/($section_id)")
  let body = {archived: $archived, description: $description, name: $name, variations: $variations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Experiment results time series
#
# GET /experiments/{experiment_id}/timeseries
# operationId: get_experiment_timeseries
export def "experiments-timeseries timeseries" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseline-variation-id: string # The ID of the variation to use as the baseline to compare against other variations. Defaults to the first variation if not provided. For an experience in a personalization campaign, the value can also be the string 'holdback'. (format: int64)
  --start-time: string # The start time of the time interval (beginning time included) used to calculate the results over. If unspecified, defaults to the time that the Experiment was first activated. The start time will be rounded the smallest time modulo 5 minutes larger or equal to start_time. (format: date-time)
  --end-time: string # The end of the time interval (end time excluded) used to calculate results over. If unspecified, defaults to the current time if the Experiment is still running, otherwise defaults to the time the experiment was last active. The end time will be rounded to the largest time modulo 5 minutes smaller or equal to end_time. The end_time in the response may be earlier than requested if fresher results are not available yet. In this case, the results will continue to calculate in the background and subsequent requests will eventually return the full results. (format: date-time)
  --browser: string@browser-completer # Browser to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [device, source, attribute_id, attribute_value].
  --device: string@device-completer # Device to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, source, attribute_id, attribute_value].
  --qp-source: string@source-completer # Source to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, device, attribute_id, attribute_value]. Campaign: Contains users that arrive on a URL containing a 'utm_campaign,' 'utm_source,' 'gclid,' or 'otm_source' query parameter. If the URL contains one of these parameters, the visitor will count as "Campaign" traffic even if they arrived through search. Direct:  Includes all users who do not have any external referrer in their URL. Referral: Includes all users that come from another URL that doesn't count as Campaign.
  --attribute-id: int # ID of the attribute to segment results by. Requests containing attribute_id will return the results for all visitors that have attribute_value for the attribute represented by attribute_id. If present, the attribute_value parameter must also be present, and it cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].  (format: int64)
  --attribute-value: string # UTF-8 encoded value correlating to attribute_id. If present, the attribute_id parameter must also be present. This parameter also requires attribute_id to be set, and cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].
  --segment-conditions: string # (BETA) A string representation of a JSON Segment Conditions Expression. This parameter can be either URL-escaped stringified JSON or Base64-encoded stringified JSON using URL-safe alphabet (preferred). Segment Conditions Expressions consist of Logical Expressions and Match Expressions. Logical Expressions are represented as an array of the format [<operator>, <expression>...], where the supported operators are "and", "or" and "not". Match Expressions are represented as an object of the format {"attribute_id": <attribute_id>, "attribute_value": <value>[, "match_type": <match_type>]}, where supported values for match_type are "exact" match type will match only an exact string match between "value" string and the attribute value. "substring" match type will match if "value" is a substring of the attribute value. "prefix" match type will match if "value" is a string prefix of the attribute value. "regex" match type will match if "value" is a regular expression match for the attribute value. The default match_type is "exact".
]: nothing -> record<confidence_threshold: float, end_time: string, experiment_id: int, is_stale: bool, metrics: table<aggregator: string, event_id: int, event_properties: record, field: string, metrics: list, name: string, results: record, scope: string, time_window: string, winning_direction: string>, start_time: string, stats_config: record<confidence_level: float, difference_type: string, epoch_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseline_variation_id" $baseline_variation_id "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "browser" $browser "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_value" $attribute_value "scalar") (serialize-qp "segment_conditions" $segment_conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/experiments/($experiment_id)/timeseries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Campaign results as a CSV
#
# GET /export/campaigns/{campaign_id}/results/csv
# operationId: get_campaign_results_csv
export def "export-campaigns-results-csv csv" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: string # The start time of the time interval (beginning time included) used to calculate the results over. If unspecified, defaults to the time that the Campaign was first activated. The start time will be rounded the smallest time modulo 5 minutes larger or equal to start_time. (format: date-time)
  --end-time: string # The end of the time interval (end time excluded) used to calculate results over. If unspecified, defaults to the current time if the Experiment is still running, otherwise defaults to the time the experiment was last active. The end time will be rounded to the largest time modulo 5 minutes smaller or equal to end_time. The end_time in the response may be earlier than requested if fresher results are not available yet. In this case, the results will continue to calculate in the background and subsequent requests will eventually return the full results. (format: date-time)
  --browser: string@browser-completer # Browser to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [device, source, attribute_id, attribute_value].
  --device: string@device-completer # Device to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, source, attribute_id, attribute_value].
  --qp-source: string@source-completer # Source to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, device, attribute_id, attribute_value]. Campaign: Contains users that arrive on a URL containing a 'utm_campaign,' 'utm_source,' 'gclid,' or 'otm_source' query parameter. If the URL contains one of these parameters, the visitor will count as "Campaign" traffic even if they arrived through search. Direct:  Includes all users who do not have any external referrer in their URL. Referral: Includes all users that come from another URL that doesn't count as Campaign.
  --attribute-id: int # ID of the attribute to segment results by. Requests containing attribute_id will return the results for all visitors that have attribute_value for the attribute represented by attribute_id. If present, the attribute_value parameter must also be present, and it cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].  (format: int64)
  --attribute-value: string # UTF-8 encoded value correlating to attribute_id. If present, the attribute_id parameter must also be present. This parameter also requires attribute_id to be set, and cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].
  --segment-conditions: string # (BETA) A string representation of a JSON Segment Conditions Expression. This parameter can be either URL-escaped stringified JSON or Base64-encoded stringified JSON using URL-safe alphabet (preferred). Segment Conditions Expressions consist of Logical Expressions and Match Expressions. Logical Expressions are represented as an array of the format [<operator>, <expression>...], where the supported operators are "and", "or" and "not". Match Expressions are represented as an object of the format {"attribute_id": <attribute_id>, "attribute_value": <value>[, "match_type": <match_type>]}, where supported values for match_type are "exact" match type will match only an exact string match between "value" string and the attribute value. "substring" match type will match if "value" is a substring of the attribute value. "prefix" match type will match if "value" is a string prefix of the attribute value. "regex" match type will match if "value" is a regular expression match for the attribute value. The default match_type is "exact".
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "browser" $browser "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_value" $attribute_value "scalar") (serialize-qp "segment_conditions" $segment_conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/export/campaigns/($campaign_id)/results/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get AWS credentials to access experimentation events export data.
#
# GET /export/credentials
# operationId: get_enriched_events_export_credentials
export def "export-credentials credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --duration: string # Duration of the AWS credentials token. Please use [H,h] for hours or [M,m] for minutes. Minimum is 15m and Maximum is 1h. Usage 1h. (default: 1h)
]: nothing -> record<credentials: record<accessKeyId: string, expiration: int, secretAccessKey: string, sessionToken: string>, s3Path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "duration" $duration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get GCP credentials to access experimentation events export data.
#
# GET /export/credentials/gcp
# operationId: get_gcp_e3_credentials
export def "export-credentials-gcp credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<token: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/credentials/gcp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Experiment results as a CSV
#
# GET /export/experiments/{experiment_id}/results/csv
# operationId: get_experiment_results_csv
export def "export-experiments-results-csv csv" [
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseline-variation-id: string # The ID of the variation to use as the baseline to compare against other variations. Defaults to the first variation if not provided. For an experience in a personalization campaign, the value can also be the string 'holdback'.
  --start-time: string # The start time of the time interval (beginning time included) used to calculate the results over. If unspecified, defaults to the time that the Experiment was first activated. The start time will be rounded the smallest time modulo 5 minutes larger or equal to start_time. (format: date-time)
  --end-time: string # The end of the time interval (end time excluded) used to calculate results over. If unspecified, defaults to the current time if the Experiment is still running, otherwise defaults to the time the experiment was last active. The end time will be rounded to the largest time modulo 5 minutes smaller or equal to end_time. The end_time in the response may be earlier than requested if fresher results are not available yet. In this case, the results will continue to calculate in the background and subsequent requests will eventually return the full results. (format: date-time)
  --browser: string@browser-completer # Browser to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [device, source, attribute_id, attribute_value].
  --device: string@device-completer # Device to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, source, attribute_id, attribute_value].
  --qp-source: string@source-completer # Source to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, device, attribute_id, attribute_value]. Campaign: Contains users that arrive on a URL containing a 'utm_campaign,' 'utm_source,' 'gclid,' or 'otm_source' query parameter. If the URL contains one of these parameters, the visitor will count as "Campaign" traffic even if they arrived through search. Direct:  Includes all users who do not have any external referrer in their URL. Referral: Includes all users that come from another URL that doesn't count as Campaign.
  --attribute-id: int # ID of the attribute to segment results by. Requests containing attribute_id will return the results for all visitors that have attribute_value for the attribute represented by attribute_id. If present, the attribute_value parameter must also be present, and it cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].  (format: int64)
  --attribute-value: string # UTF-8 encoded value correlating to attribute_id. If present, the attribute_id parameter must also be present. This parameter also requires attribute_id to be set, and cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].
  --segment-conditions: string # (BETA) A string representation of a JSON Segment Conditions Expression. This parameter can be either URL-escaped stringified JSON or Base64-encoded stringified JSON using URL-safe alphabet (preferred). Segment Conditions Expressions consist of Logical Expressions and Match Expressions. Logical Expressions are represented as an array of the format [<operator>, <expression>...], where the supported operators are "and", "or" and "not". Match Expressions are represented as an object of the format {"attribute_id": <attribute_id>, "attribute_value": <value>[, "match_type": <match_type>]}, where supported values for match_type are "exact" match type will match only an exact string match between "value" string and the attribute value. "substring" match type will match if "value" is a substring of the attribute value. "prefix" match type will match if "value" is a string prefix of the attribute value. "regex" match type will match if "value" is a regular expression match for the attribute value. The default match_type is "exact".
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseline_variation_id" $baseline_variation_id "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "browser" $browser "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_value" $attribute_value "scalar") (serialize-qp "segment_conditions" $segment_conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/export/experiments/($experiment_id)/results/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Holdout results as a CSV
#
# GET /export/projects/{project_id}/holdouts/{holdout_id}/results/csv
# operationId: get_holdout_results_csv
export def "export-projects-holdouts-results-csv csv" [
  project_id: int
  holdout_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --browser: string@browser-completer # Browser to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [device, source, attribute_id, attribute_value].
  --device: string@device-completer # Device to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, source, attribute_id, attribute_value].
  --qp-source: string@source-completer # Source to segment results by. This parameter must not be sent with any other segmentation parameters, i.e. any parameters in [browser, device, attribute_id, attribute_value]. Campaign: Contains users that arrive on a URL containing a 'utm_campaign,' 'utm_source,' 'gclid,' or 'otm_source' query parameter. If the URL contains one of these parameters, the visitor will count as "Campaign" traffic even if they arrived through search. Direct:  Includes all users who do not have any external referrer in their URL. Referral: Includes all users that come from another URL that doesn't count as Campaign.
  --attribute-id: int # ID of the attribute to segment results by. Requests containing attribute_id will return the results for all visitors that have attribute_value for the attribute represented by attribute_id. If present, the attribute_value parameter must also be present, and it cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].  (format: int64)
  --attribute-value: string # UTF-8 encoded value correlating to attribute_id. If present, the attribute_id parameter must also be present. This parameter also requires attribute_id to be set, and cannot be sent with any other segmentation parameters, i.e. any parameters in [browser, device, source].
  --segment-conditions: string # (BETA) A string representation of a JSON Segment Conditions Expression. This parameter can be either URL-escaped stringified JSON or Base64-encoded stringified JSON using URL-safe alphabet (preferred). Segment Conditions Expressions consist of Logical Expressions and Match Expressions. Logical Expressions are represented as an array of the format [<operator>, <expression>...], where the supported operators are "and", "or" and "not". Match Expressions are represented as an object of the format {"attribute_id": <attribute_id>, "attribute_value": <value>[, "match_type": <match_type>]}, where supported values for match_type are "exact" match type will match only an exact string match between "value" string and the attribute value. "substring" match type will match if "value" is a substring of the attribute value. "prefix" match type will match if "value" is a string prefix of the attribute value. "regex" match type will match if "value" is a regular expression match for the attribute value. The default match_type is "exact".
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "browser" $browser "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "attribute_id" $attribute_id "scalar") (serialize-qp "attribute_value" $attribute_value "scalar") (serialize-qp "segment_conditions" $segment_conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/export/projects/($project_id)/holdouts/($holdout_id)/results/csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Extensions
#
# GET /extensions
# operationId: list_extensions
export def "extensions extensions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The ID of the project you would like to list all extensions for (format: int64)
]: nothing -> table<archived: bool, created: string, description: string, edit_url: string, enabled: bool, experiment_count: int, fields: list<record>, id: int, implementation: record<apply_js: string, css: string, html: string, reset_js: string>, last_modified: string, name: string, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Extension
#
# POST /extensions
# operationId: create_extension
# --fields item shape: {api_name: string, default_value: string, field_type: "selector"|"text"|"multi_text"|"rich_text"|"number"|"html"|"css"|"js"|"toggle"|"dropdown"|"multi_select"|"image"|"color"|"slider", label: string, options?: record}
# --implementation shape: {apply_js?: string, css?: string, html?: string, reset_js?: string}
export def "extensions extension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description for the extension
  edit_url: string # The URL to load when editing the extension
  --enabled: oneof<nothing, bool> # Whether the extension is enabled. A disabled extension won't appear in the editor and won't be built into the snippet
  --body-fields: list # Array of editable fields in the extension (default: [], e.g. [{api_name: text, default_value: My Butterbar, field_type: text, label: A text field}]) — item shape: {api_name: string, default_value: string, field_type: "selector"|"text"|"multi_text"|"rich_text"|"number"|"html"|"css"|"js"|"toggle"|"dropdown"|"multi_select"|"image"|"color"|"slider", label: string, options?: record}
  implementation: record # shape: {apply_js?: string, css?: string, html?: string, reset_js?: string}
  name: string # Name of the extension (e.g. My Extension)
  project_id: int # The project the extension is in (format: int64, e.g. 1000)
]: any -> record<archived: bool, created: string, description: string, edit_url: string, enabled: bool, experiment_count: int, fields: table<api_name: string, default_value: string, field_type: string, label: string, options: record>, id: int, implementation: record<apply_js: string, css: string, html: string, reset_js: string>, last_modified: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extensions")
  let body = {description: $description, edit_url: $edit_url, enabled: $enabled, fields: $body_fields, implementation: $implementation, name: $name, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an Extension
#
# DELETE /extensions/{extension_id}
# operationId: delete_extension
export def "extensions extension-by-extension_id" [
  extension_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extensions/($extension_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Extension
#
# GET /extensions/{extension_id}
# operationId: get_extension
export def "extensions extension-by-extension_id-1" [
  extension_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, created: string, description: string, edit_url: string, enabled: bool, experiment_count: int, fields: table<api_name: string, default_value: string, field_type: string, label: string, options: record>, id: int, implementation: record<apply_js: string, css: string, html: string, reset_js: string>, last_modified: string, name: string, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extensions/($extension_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Extension
#
# PATCH /extensions/{extension_id}
# operationId: update_extension
# --fields item shape: {api_name: string, default_value: string, field_type: "selector"|"text"|"multi_text"|"rich_text"|"number"|"html"|"css"|"js"|"toggle"|"dropdown"|"multi_select"|"image"|"color"|"slider", label: string, options?: record}
# --implementation shape: {apply_js?: string, css?: string, html?: string, reset_js?: string}
export def "extensions extension-by-extension_id-2" [
  extension_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether the extension is archived
  --description: string # The description for the extension
  --edit-url: string # The URL to load when editing the extension
  --enabled: oneof<nothing, bool> # Whether the extension is enabled
  --body-fields: list # Array of editable fields in the extension (e.g. [{api_name: text, default_value: My Butterbar, field_type: text, label: A text field}]) — item shape: {api_name: string, default_value: string, field_type: "selector"|"text"|"multi_text"|"rich_text"|"number"|"html"|"css"|"js"|"toggle"|"dropdown"|"multi_select"|"image"|"color"|"slider", label: string, options?: record}
  --implementation: record # shape: {apply_js?: string, css?: string, html?: string, reset_js?: string}
  --name: string # Name of the extension (e.g. My Extension)
]: any -> record<archived: bool, created: string, description: string, edit_url: string, enabled: bool, experiment_count: int, fields: table<api_name: string, default_value: string, field_type: string, label: string, options: record>, id: int, implementation: record<apply_js: string, css: string, html: string, reset_js: string>, last_modified: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/extensions/($extension_id)")
  let body = {archived: $archived, description: $description, edit_url: $edit_url, enabled: $enabled, fields: $body_fields, implementation: $implementation, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Features by Project
#
# GET /features
# operationId: list_features
export def "features features" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The ID of the project for which you would like to get Features (format: int64)
]: nothing -> table<archived: bool, created: string, description: string, environments: record, id: int, key: string, last_modified: string, name: string, project_id: int, variables: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Feature
#
# POST /features
# operationId: create_feature
# --variables item shape: {archived?: bool, default_value: string, key: string, type: "boolean"|"string"|"double"|"integer"|"json"}
export def "features feature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether the Feature has been archived (default: false)
  --description: string # A short description of this Feature
  --environments: record # The configuration for this Feature's Rollout within each Environment, keyed by Environment key
  key: string # Unique string identifier for this Feature within the Project (e.g. new_checkout_page)
  --name: string # Name of the Feature (e.g. the checkout feature)
  project_id: int # The ID of the Project this Feature belongs to (format: int64)
  --body-variables: list # Variables define the dynamic configuration of a feature, and each variable can take on a different value on a per-variation basis within a feature test. — item shape: {archived?: bool, default_value: string, key: string, type: "boolean"|"string"|"double"|"integer"|"json"}
]: any -> record<archived: bool, created: string, description: string, environments: record, id: int, key: string, last_modified: string, name: string, project_id: int, variables: table<archived: bool, default_value: string, id: int, key: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/features")
  let body = {archived: $archived, description: $description, environments: $environments, key: $key, name: $name, project_id: $project_id, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a Feature
#
# DELETE /features/{feature_id}
# operationId: delete_feature
export def "features feature-by-feature_id" [
  feature_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($feature_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a Feature
#
# GET /features/{feature_id}
# operationId: get_feature
export def "features feature-by-feature_id-1" [
  feature_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, created: string, description: string, environments: record, id: int, key: string, last_modified: string, name: string, project_id: int, variables: table<archived: bool, default_value: string, id: int, key: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($feature_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Feature
#
# PATCH /features/{feature_id}
# operationId: update_feature
# --variables item shape: {archived?: bool, default_value?: string, description?: string, id?: int, key?: string, type?: "boolean"|"string"|"double"|"integer"|"json"}
export def "features feature-by-feature_id-2" [
  feature_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether the Feature has been archived
  --description: string # A short description of this Feature
  --environments: record # The configuration for this Feature's Rollout within each Environment, keyed by Environment key.
  --key: string # Unique string identifier for this Feature within the Project (e.g. new_checkout_page)
  --name: string # Name of the Feature (e.g. the checkout feature)
  --body-variables: list # Variables define the dynamic configuration of a feature, and each variable can take on a different value on a per-variation basis within a feature test. — item shape: {archived?: bool, default_value?: string, description?: string, id?: int, key?: string, type?: "boolean"|"string"|"double"|"integer"|"json"}
]: any -> record<archived: bool, created: string, description: string, environments: record, id: int, key: string, last_modified: string, name: string, project_id: int, variables: table<archived: bool, default_value: string, id: int, key: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/features/($feature_id)")
  let body = {archived: $archived, description: $description, environments: $environments, key: $key, name: $name, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Exclusion Groups
#
# GET /groups
# operationId: list_groups
export def "groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The ID of the Project you would like to list all Exclusion Groups for (format: int64)
]: nothing -> table<archived: bool, created: string, description: string, entities: list<record>, id: int, last_modified: string, name: string, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Exclusion Group
#
# POST /groups
# operationId: create_group
# --entities item shape: {id: int, kind: "Campaign"|"Experiment", weight: int}
export def "groups group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether the group is archived
  --description: string # The description for an Exclusion Group
  --entities: list # Array of Group Entities in the Exclusion Group (e.g. [{id: 1234, kind: Experiment, weight: 5000}]) — item shape: {id: int, kind: "Campaign"|"Experiment", weight: int}
  name: string # Name of the Exclusion Group (e.g. Homepage Group)
  project_id: int # The Project the Exclusion Group is in (format: int64, e.g. 1000)
]: any -> record<archived: bool, created: string, description: string, entities: table<id: int, kind: string, weight: int>, id: int, last_modified: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let body = {archived: $archived, description: $description, entities: $entities, name: $name, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an Exclusion Group
#
# DELETE /groups/{group_id}
# operationId: delete_group
export def "groups group-by-group_id" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Exclusion Group
#
# GET /groups/{group_id}
# operationId: get_group
export def "groups group-by-group_id-1" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, created: string, description: string, entities: table<id: int, kind: string, weight: int>, id: int, last_modified: string, name: string, project_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Exclusion Group
#
# PATCH /groups/{group_id}
# operationId: update_group
# --entities item shape: {id: int, kind: "Campaign"|"Experiment", weight: int}
export def "groups group-by-group_id-2" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether the Exclusion Group has been archived (default: false)
  --description: string # The updated description of the Exclusion Group (e.g. The Exclusion Group is updated!)
  --entities: list # Array of experiments or campaigns in the Exclusion Group, represented as a GroupEntity object (e.g. [{id: 1234, kind: Experiment, weight: 5000}]) — item shape: {id: int, kind: "Campaign"|"Experiment", weight: int}
  --name: string # The updated name of the Exclusion Group (e.g. Updated Exclusion Group)
]: any -> record<archived: bool, created: string, description: string, entities: table<id: int, kind: string, weight: int>, id: int, last_modified: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($group_id)")
  let body = {archived: $archived, description: $description, entities: $entities, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get list attributes by project
#
# GET /list_attributes
# operationId: list_list_attributes
export def "list-attributes attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: int # The ID of the project for which you would like to get List Attributes (format: int64)
]: nothing -> table<account_id: int, archived: bool, aws_access_key: string, aws_secret_key: string, created: string, description: string, id: int, key_field: string, last_modified: string, list_content: string, list_type: string, name: string, project_id: int, s3_path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/list_attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a List Attribute
#
# POST /list_attributes
# operationId: create_list_attribute
export def "list-attributes attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not the List Attribute has been archived (default: false)
  --description: string # A short description of the List Attribute
  key_field: string # The name of the object which holds targeting ids on your website
  --list-content: string # A comma separated string of IDs or ZIP Codes. Items will be matched against the key_field to determine if an active visitor should be targeted by the list.  Note that if the list currently contains data, providing this value will overwrite the previous data.
  --list-type: string@list-type-completer # The type of data object which holds targeting ids on your website (cookies, query parameters, zip codes, Global JS variables)
  name: string # A unique, human-readable name for the List Attribute (e.g. SubscriberStatus)
  project_id: int # The ID of the project the List Attribute belongs to (format: int64)
]: any -> record<account_id: int, archived: bool, aws_access_key: string, aws_secret_key: string, created: string, description: string, id: int, key_field: string, last_modified: string, list_content: string, list_type: string, name: string, project_id: int, s3_path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/list_attributes")
  let body = {archived: $archived, description: $description, key_field: $key_field, list_content: $list_content, list_type: $list_type, name: $name, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a List Attribute
#
# DELETE /list_attributes/{list_attribute_id}
# operationId: archive_list_attribute
export def "list-attributes attribute-by-list_attribute_id" [
  list_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list_attributes/($list_attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a List Attribute
#
# GET /list_attributes/{list_attribute_id}
# operationId: get_list_attribute
export def "list-attributes attribute-by-list_attribute_id-1" [
  list_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: int, archived: bool, aws_access_key: string, aws_secret_key: string, created: string, description: string, id: int, key_field: string, last_modified: string, list_content: string, list_type: string, name: string, project_id: int, s3_path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list_attributes/($list_attribute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a List Attribute
#
# PATCH /list_attributes/{list_attribute_id}
# operationId: update_list_attribute
export def "list-attributes attribute-by-list_attribute_id-2" [
  list_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not the List Attribute has been archived
  --description: string # A short description of the List Attribute
  --key-field: string # The name of the object which holds targeting ids on your website
  --list-content: string # A comma separated string of IDs or ZIP Codes. Items will be matched against the key_field to determine if an active visitor should be targeted by the list.  Note that if the list currently contains data, providing this value will overwrite the previous data.
  --list-type: string@list-type-completer # The type of data object which holds targeting ids on your website (cookies, query parameters, zip codes, Global JS variables)
  --name: string # A unique, human-readable name for the List Attribute (e.g. SubscriberStatus)
]: any -> record<account_id: int, archived: bool, aws_access_key: string, aws_secret_key: string, created: string, description: string, id: int, key_field: string, last_modified: string, list_content: string, list_type: string, name: string, project_id: int, s3_path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list_attributes/($list_attribute_id)")
  let body = {archived: $archived, description: $description, key_field: $key_field, list_content: $list_content, list_type: $list_type, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pages
#
# GET /pages
# operationId: list_pages
export def "pages pages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --project-id: int # The Project ID of the Project you would like to list all Pages for (format: int64)
]: nothing -> table<activation_code: string, activation_type: string, archived: bool, category: string, conditions: string, created: string, edit_url: string, id: int, key: string, last_modified: string, name: string, page_type: string, project_id: int, single_use: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Page
#
# POST /pages
# operationId: create_page
export def "pages page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --activation-code: string # Stringified Javascript function that determines when the Page is activated. Only required when activation_type is 'polling' or 'callback'. (e.g. function callbackFn(activate, options) { activate(); })
  --activation-type: string@activation-type-completer # Page activation type is a trigger that determines when the page is activated. Triggers tell Optimizely when to start checking whether certain conditions are true 'Immediate' activation mode activates the page as soon as the snippet loads. 'Polling' activation mode polls every 50ms until 'activation_code' evaluates to True, then activates the page. 'Callback' activation mode activates the page when the event defined by 'activation_code' is triggered. 'Manual' activation mode requires code within the subject app to explicitly trigger page activation. 'DOM Changed' sets the page to trigger when the DOM changes [Learn more](https://help.optimizely.com/Build_Campaigns_and_Experiments/Support_for_dynamic_websites%3A_Use_Optimizely_on_single_page_applications#Triggers). 'URL Changed' sets the page to trigger when the URL changes [Learn more](https://help.optimizely.com/Build_Campaigns_and_Experiments/Support_for_dynamic_websites%3A_Use_Optimizely_on_single_page_applications#Triggers).  (e.g. callback)
  --archived: oneof<nothing, bool> # Whether the Page has been archived (default: false)
  --category: string@category-completer # The category this Page is grouped under (default: other)
  --conditions: string # Stringified array of the conditions that activate the Page. The array contains Page Condition JSON dicts joined by "and" and "or". Each individual Page Condition dict has format {"type": "url", "match_type": <match_type>, "value": <value>} where match_types are: "simple" match type will match if "value" matches the hostname and path of the Page URL. "exact" match type will match only an exact string match between "value" and the Page URL. "substring" match type will match if "value" is a substring of the Page URL. "regex" match type will match if "value" is a regular expression match for the Page URL.  (e.g. ["and", {"type": "url", "match_type": "substring", "value": "optimize"}])
  edit_url: string # URL of the Page (e.g. https://www.optimizely.com)
  --key: string # Unique string identifier for this Page within the Project (e.g. home_page)
  name: string # Name of the Page (e.g. Home Page)
  --page-type: string@page-type-completer # Type of Page
  project_id: int # ID of the Page's Project (format: int64, e.g. 1000)
]: any -> record<activation_code: string, activation_type: string, archived: bool, category: string, conditions: string, created: string, edit_url: string, id: int, key: string, last_modified: string, name: string, page_type: string, project_id: int, single_use: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pages")
  let body = {activation_code: $activation_code, activation_type: $activation_type, archived: $archived, category: $category, conditions: $conditions, edit_url: $edit_url, key: $key, name: $name, page_type: $page_type, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a Page
#
# DELETE /pages/{page_id}
# operationId: delete_page
export def "pages page-by-page_id" [
  page_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a page
#
# GET /pages/{page_id}
# operationId: get_page
export def "pages page-by-page_id-1" [
  page_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activation_code: string, activation_type: string, archived: bool, category: string, conditions: string, created: string, edit_url: string, id: int, key: string, last_modified: string, name: string, page_type: string, project_id: int, single_use: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Page
#
# PATCH /pages/{page_id}
# operationId: update_page
export def "pages page-by-page_id-2" [
  page_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --activation-code: string # Stringified Javascript function that determines when the Page is activated. Only required when activation_type is 'polling' or 'callback'.
  --activation-type: string@activation-type-completer # Page activation type is a trigger that determines when the page is activated. Triggers tell Optimizely when to start checking whether certain conditions are true 'Immediate' activation mode activates the page as soon as the snippet loads. 'Polling' activation mode polls every 50ms until 'activation_code' evaluates to True, then activates the page. 'Callback' activation mode activates the page when the event defined by 'activation_code' is triggered. 'Manual' activation mode requires code within the subject app to explicitly trigger page activation. 'DOM Changed' sets the page to trigger when the DOM changes [Learn more](https://help.optimizely.com/Build_Campaigns_and_Experiments/Support_for_dynamic_websites%3A_Use_Optimizely_on_single_page_applications#Triggers). 'URL Changed' sets the page to trigger when the URL changes [Learn more](https://help.optimizely.com/Build_Campaigns_and_Experiments/Support_for_dynamic_websites%3A_Use_Optimizely_on_single_page_applications#Triggers).
  --archived: oneof<nothing, bool> # Whether the Page is archived
  --category: string@category-completer # The category this Page is grouped under
  --conditions: string # Stringified array of the conditions that activate the Page. The array contains Page Condition JSON dicts joined by "and" and "or". Each individual Page Condition dict has format {"type": "url", "match_type": <match_type>, "value": <value>} where match_types are: "simple" match type will match if "value" matches the hostname and path of the Page URL. "exact" match type will match only an exact string match between "value" and the Page URL. "substring" match type will match if "value" is a substring of the Page URL. "regex" match type will match if "value" is a regular expression match for the Page URL.  (e.g. ["and", {"type": "url", "match_type": "substring", "value": "optimize"}])
  --edit-url: string # URL of the Page
  --key: string # Unique string identifier for this Page within the Project (e.g. home_page)
  --name: string # Page Name (e.g. Home Page)
  --page-type: string@page-type-completer # Type of Page
]: any -> record<activation_code: string, activation_type: string, archived: bool, category: string, conditions: string, created: string, edit_url: string, id: int, key: string, last_modified: string, name: string, page_type: string, project_id: int, single_use: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)")
  let body = {activation_code: $activation_code, activation_type: $activation_type, archived: $archived, category: $category, conditions: $conditions, edit_url: $edit_url, key: $key, name: $name, page_type: $page_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an In-Page Event
#
# POST /pages/{page_id}/events
# operationId: create_in_page_event
# --config shape: {selector: string}
export def "pages-events event-by-page_id" [
  page_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not this Event is archived
  --category: string@category-completer-1
  --config: record # shape: {selector: string}
  --description: string # A description of this Event
  event_type: string@event-type-completer # The type of this Event
  --key: string # Unique string identifier for this Event within the Project (e.g. add_to_cart)
  name: string # A human readable name for this Event (e.g. Add to Cart)
]: any -> record<archived: bool, category: string, config: record<selector: string>, created: string, description: string, event_type: string, id: int, is_classic: bool, is_editable: bool, key: string, name: string, page_id: int, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/events")
  let body = {archived: $archived, category: $category, config: $config, description: $description, event_type: $event_type, key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive an In-Page Event
#
# DELETE /pages/{page_id}/events/{event_id}
# operationId: delete_in_page_event
export def "pages-events event-by-page_id-event_id" [
  page_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an In-Page Event
#
# PATCH /pages/{page_id}/events/{event_id}
# operationId: update_in_page_event
# --config shape: {selector: string}
export def "pages-events event-by-page_id-event_id-1" [
  page_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not to archive this Event
  --category: string@category-completer-1
  --config: record # shape: {selector: string}
  --description: string # A description of this Event
  --key: string # Unique string identifier for this Event within the Project (e.g. add_to_cart)
  --name: string # A human readable name for this Event (e.g. Add to Cart)
  --body-page-id: int # The Page ID associated with this Event (format: int64)
]: any -> record<archived: bool, category: string, config: record<selector: string>, created: string, description: string, event_type: string, id: int, is_classic: bool, is_editable: bool, key: string, name: string, page_id: int, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pages/($page_id)/events/($event_id)")
  let body = {archived: $archived, category: $category, config: $config, description: $description, key: $key, name: $name, page_id: $body_page_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Plan & Usage information for all products
#
# GET /plan
# operationId: get_plan
export def "plan plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: int, plan_name: string, product_usages: table<allocation_term_in_months: int, end_time: string, last_update_time: string, overage_cents_per_visitor: float, product_name: string, projects: record, start_time: string, usage: int, usage_allowance: int>, status: string, unit_of_measurement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plan")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Projects
#
# GET /projects
# operationId: list_projects
export def "projects projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --filter: list # Filters Projects by ID, in the format of id:{project_id}. Specifying multiple filters will return all specified projects.
  --turnstile-instance-id: string # Filters Projects by Turnstile Instance ID
]: nothing -> table<account_id: int, confidence_threshold: float, created: string, dcp_service_id: int, description: string, id: int, is_classic: bool, is_flags_enabled: bool, last_modified: string, name: string, platform: string, sdks: list<string>, socket_token: string, status: string, third_party_platform: string, web_snippet: record<code_revision: int, enable_force_variation: bool, exclude_disabled_experiments: bool, exclude_names: bool, include_jquery: bool, ip_anonymization: bool, ip_filter: string, js_file_size: int, library: string, project_javascript: string, visitor_id_locator_name: string, visitor_id_locator_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "turnstile_instance_id" $turnstile_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Project
#
# POST /projects
# operationId: create_project
# --web_snippet shape: {enable_force_variation?: bool, exclude_disabled_experiments?: bool, exclude_names?: bool, include_jquery?: bool, ip_anonymization?: bool, ip_filter?: string, library?: "jquery-1.11.3-trim"|"jquery-1.11.3-full"|"jquery-1.6.4-trim"|"jquery-1.6.4-full"|"none", project_javascript?: string, visitor_id_locator_name?: string, visitor_id_locator_type?: "cookie"|"query"|"localStorage"|"js"}
export def "projects project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confidence-threshold: float # The significance level at which you would like to declare winning and losing variations. A lower number minimizes the time needed to declare a winning or losing variation, but increases the risk that your results aren't true winners and losers. The precision for this number is up to 4 decimal places  (format: double, e.g. 0.9)
  --dcp-service-id: int # The ID of a Dynamic Customer Profile Service associated with this Project (format: int64, e.g. 121234)
  --description: string # A short description of the Project (e.g. Project for user sign up flow)
  --is-flags-enabled: oneof<nothing, bool> # If is_flags_enabled is true, this project uses the new Flags-First user experience and will use the [Flags API](https://library.optimizely.com/docs/api/flags/v1/index.html) to make changes to entities.
  name: string # The name of the Project (e.g. Test Project)
  --platform: string@platform-completer # The platform of the Project (default: web)
  --sdks: list # For Full Stack, Mobile, and OTT projects, the language used for the SDK
  --status: string@status-completer # The current status of the Project (default: active)
  --third-party-platform: string@third-party-platform-completer # The third party platform with which the project is intended to be used. When this is set, a project might have special restrictions. This can have a value of "salesforce" but defaults to null. In order to set this field, an account must have the third party platforms feature and be a fullstack project.
  --web-snippet: record # shape: {enable_force_variation?: bool, exclude_disabled_experiments?: bool, exclude_names?: bool, include_jquery?: bool, ip_anonymization?: bool, ip_filter?: string, library?: "jquery-1.11.3-trim"|"jquery-1.11.3-full"|"jquery-1.6.4-trim"|"jquery-1.6.4-full"|"none", project_javascript?: string, visitor_id_locator_name?: string, visitor_id_locator_type?: "cookie"|"query"|"localStorage"|"js"}
]: any -> record<account_id: int, confidence_threshold: float, created: string, dcp_service_id: int, description: string, id: int, is_classic: bool, is_flags_enabled: bool, last_modified: string, name: string, platform: string, sdks: list<string>, socket_token: string, status: string, third_party_platform: string, web_snippet: record<code_revision: int, enable_force_variation: bool, exclude_disabled_experiments: bool, exclude_names: bool, include_jquery: bool, ip_anonymization: bool, ip_filter: string, js_file_size: int, library: string, project_javascript: string, visitor_id_locator_name: string, visitor_id_locator_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {confidence_threshold: $confidence_threshold, dcp_service_id: $dcp_service_id, description: $description, is_flags_enabled: $is_flags_enabled, name: $name, platform: $platform, sdks: $sdks, status: $status, third_party_platform: $third_party_platform, web_snippet: $web_snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read a Project
#
# GET /projects/{project_id}
# operationId: get_project
export def "projects project-by-project_id" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: int, confidence_threshold: float, created: string, dcp_service_id: int, description: string, id: int, is_classic: bool, is_flags_enabled: bool, last_modified: string, name: string, platform: string, sdks: list<string>, socket_token: string, status: string, third_party_platform: string, web_snippet: record<code_revision: int, enable_force_variation: bool, exclude_disabled_experiments: bool, exclude_names: bool, include_jquery: bool, ip_anonymization: bool, ip_filter: string, js_file_size: int, library: string, project_javascript: string, visitor_id_locator_name: string, visitor_id_locator_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Project
#
# PATCH /projects/{project_id}
# operationId: update_project
# --web_snippet shape: {enable_force_variation?: bool, exclude_disabled_experiments?: bool, exclude_names?: bool, include_jquery?: bool, ip_anonymization?: bool, ip_filter?: string, library?: "jquery-1.11.3-trim"|"jquery-1.11.3-full"|"jquery-1.6.4-trim"|"jquery-1.6.4-full"|"none", project_javascript?: string, visitor_id_locator_name?: string, visitor_id_locator_type?: "cookie"|"query"|"localStorage"|"js"}
export def "projects project-by-project_id-1" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confidence-threshold: float # The significance level at which you would like to declare winning and losing variations. A lower number minimizes the time needed to declare a winning or losing variation, but increases the risk that your results aren't true winners and losers. The precision for this number is up to 4 decimal places. (format: double, e.g. 0.9)
  --dcp-service-id: int # The ID of a Dynamic Customer Profile Service associated with this Project (format: int64, e.g. 121234)
  --description: string # A short description of the Project (e.g. Project for user sign up flow)
  --name: string # The name of the Project (e.g. Test Project)
  --status: string@status-completer # The current status of the Project
  --web-snippet: record # shape: {enable_force_variation?: bool, exclude_disabled_experiments?: bool, exclude_names?: bool, include_jquery?: bool, ip_anonymization?: bool, ip_filter?: string, library?: "jquery-1.11.3-trim"|"jquery-1.11.3-full"|"jquery-1.6.4-trim"|"jquery-1.6.4-full"|"none", project_javascript?: string, visitor_id_locator_name?: string, visitor_id_locator_type?: "cookie"|"query"|"localStorage"|"js"}
]: any -> record<account_id: int, confidence_threshold: float, created: string, dcp_service_id: int, description: string, id: int, is_classic: bool, is_flags_enabled: bool, last_modified: string, name: string, platform: string, sdks: list<string>, socket_token: string, status: string, third_party_platform: string, web_snippet: record<code_revision: int, enable_force_variation: bool, exclude_disabled_experiments: bool, exclude_names: bool, include_jquery: bool, ip_anonymization: bool, ip_filter: string, js_file_size: int, library: string, project_javascript: string, visitor_id_locator_name: string, visitor_id_locator_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let body = {confidence_threshold: $confidence_threshold, dcp_service_id: $dcp_service_id, description: $description, name: $name, status: $status, web_snippet: $web_snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Custom Event
#
# POST /projects/{project_id}/custom_events
# operationId: create_custom_event
# --event_properties item shape: {data_type?: "boolean"|"number"|"string", name?: string}
export def "projects-custom-events event-by-project_id" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not to archive this Event
  --category: string@category-completer-1
  --description: string # A description of this Event
  --event-properties: list # A set of user-defined data elements for the event. Metrics can filter on particular values of these properties. — item shape: {data_type?: "boolean"|"number"|"string", name?: string}
  --event-type: string@event-type-completer-1 # The type of this Event
  key: string # Unique string identifier for this Event within the Project (e.g. loaded_new_app)
  --name: string # A human readable name for this Event. If unspecified, defaults to the key (e.g. Loaded New App)
]: any -> record<archived: bool, category: string, created: string, description: string, event_properties: table<data_type: string, name: string>, event_type: string, id: int, is_classic: bool, is_editable: bool, key: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/custom_events")
  let body = {archived: $archived, category: $category, description: $description, event_properties: $event_properties, event_type: $event_type, key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive a Custom Event
#
# DELETE /projects/{project_id}/custom_events/{event_id}
# operationId: delete_custom_event
export def "projects-custom-events event-by-project_id-event_id" [
  project_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/custom_events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Custom Event
#
# PATCH /projects/{project_id}/custom_events/{event_id}
# operationId: update_custom_event
export def "projects-custom-events event-by-project_id-event_id-1" [
  project_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # Whether or not to archive this Event
  --category: string@category-completer-1
  --description: string # A description of this Event
  --key: string # Unique string identifier for this Event within the Project (e.g. loaded_new_app)
  --name: string # A human readable name for this Event (e.g. Loaded New App)
]: any -> record<archived: bool, category: string, created: string, description: string, event_properties: table<data_type: string, name: string>, event_type: string, id: int, is_classic: bool, is_editable: bool, key: string, name: string, project_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/custom_events/($event_id)")
  let body = {archived: $archived, category: $category, description: $description, key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Webhooks by Project
#
# GET /projects/{project_id}/webhooks
# operationId: list_webhooks
export def "projects-webhooks webhooks" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
]: nothing -> table<active: bool, created: string, description: string, events: list<string>, id: int, last_modified: string, name: string, project_id: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Webhook
#
# POST /projects/{project_id}/webhooks
# operationId: create_webhook
export def "projects-webhooks webhook" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A short description of the Webhook. (e.g. Webhook description)
  --events: list # List of events subscribed to the webhook.
  name: string # Name of the Webhook.
  --body-project-id: int # ID of the project of the Environment.
]: any -> record<active: bool, created: string, description: string, events: list<string>, id: int, last_modified: string, name: string, project_id: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/webhooks")
  let body = {description: $description, events: $events, name: $name, project_id: $body_project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download a CSV with all current catalog data
#
# GET /recommendations/catalogs/{catalog_id}/catalog/{date}
# operationId: get_recs_catalog_csv
export def "recommendations-catalogs-catalog csv" [
  date: string
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/catalogs/($catalog_id)/catalog/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a CSV with all computed recommendations output data
#
# GET /recommendations/catalogs/{catalog_id}/recommenders/{recommender_id}/{date}
# operationId: get_recs_output_csv
export def "recommendations-catalogs-recommenders csv" [
  date: string
  catalog_id: string
  recommender_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/catalogs/($catalog_id)/recommenders/($recommender_id)/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a CSV with summary stats data
#
# GET /recommendations/catalogs/{catalog_id}/stats/{date}
# operationId: get_recs_stats_csv
export def "recommendations-catalogs-stats csv" [
  date: string
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/catalogs/($catalog_id)/stats/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# GET /search
# operationId: get_search_results
export def "search results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
  --qp-query: string # The text to search for.
  --project-id: list # Filters search results by Project ID. Specifying multiple Project IDs will search across all specified projects.
  --type: list # Filters search results by entity type. Specifying multiple types will search across all types specified.
  --type-expand: list # Filters search results by experiment, rule or campaign types. Specifying multiple types will search across all types specified.
  --project-type: list # Filters search results by project type. Specifying one of fx, full_stack, or web will filter results accordingly.
  --expand: list # Include the project name with the search result
  --archived: oneof<nothing, bool> # Whether or not to include archived entities in the search results. If this parameter is not provided it will default to false and no archived entities will be included. (default: false)
  --fullsearch: oneof<nothing, bool> # Whether or not to perform full document search for the given search keyword. If this parameter is not provided it will default to false. (default: false)
  --status: list # Filters search results by the current status of the entity if it has one. Works for Experiments and Campaigns, and it may work for others. Specifying multiple statuses will search for entities with ANY of those statuses.
  --qp-sort: string # The property to sort by.
  --order: string # The property to sort by.
  --environment-key: string # Filters search result by environment_key when applicable
  --audience-id: list # Filters search results by audience ID. Specifying multiple audience IDs.
  --turnstile-instance-id: string # Filters search results by Turnstile Instance ID.
]: nothing -> table<archived: bool, audience_ids: list<int>, campaign_type: string, created: string, description: string, enabled: bool, environment_key: string, environments: record, experiment_count: int, experiment_type: string, feature_key: string, feature_name: string, flag_key: string, group_id: int, id: int, is_flags_enabled: bool, key: string, last_modified: string, name: string, page_id: int, platform: string, project_id: int, project_name: string, rule_type: string, ruleset_enabled: bool, status: string, type: string, updated_time: string, variable_definitions: record, variation_specific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "project_id" $project_id "multi") (serialize-qp "type" $type "multi") (serialize-qp "type_expand" $type_expand "multi") (serialize-qp "project_type" $project_type "csv") (serialize-qp "expand" $expand "csv") (serialize-qp "archived" $archived "scalar") (serialize-qp "fullsearch" $fullsearch "scalar") (serialize-qp "status" $status "csv") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "environment_key" $environment_key "scalar") (serialize-qp "audience_id" $audience_id "multi") (serialize-qp "turnstile_instance_id" $turnstile_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Subject Access Requests
#
# GET /subject-access-requests
# operationId: list_sar_requests_by_account
export def "subject-access-requests account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Optional pagination argument that specifies the maximum number of objects to return per request (default: 25)
  --page: int # Optional pagination argument that specifies the page to return. If you have 140 objects and you choose to return 100 objects per page you will be able to access the last 40 objects on page 2. The default value is 1.  (default: 1)
]: nothing -> table<account_id: int, completed_at_time: string, data_type: string, expired_at_time: string, export_location: string, id: int, identifier: string, identifier_type: string, processing_started_time: string, request_type: string, requested_at_time: string, sla_deadline_time: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subject-access-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Subject Access Request
#
# POST /subject-access-requests
# operationId: create_sar_request
export def "subject-access-requests request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data_type: string@data-type-completer # <p>The type of data to be accessed or deleted. The two options are:</p>  <ul>     <li><code>user</code> - End users (also known as <em>Collaborators</em>) that are added to the accounts of our customers. A user can be a <a href="https://help.optimizely.com/Set_Up_Optimizely/Manage_collaborators_in_Optimizely_X" rel="internal"><u>collaborator</u></a> on multiple accounts.</li>     <li><code>visitor</code> - Visitors who visit or use our customers’ websites, apps and other digital products. Optimizely stores visitor data to calculate experiment results and to tailor content.</li> </ul>  (e.g. user)
  identifier: string # The identifier value that you would like us to use when searching. If <code>user</code> was selected in the previous step, the identifier will be the email address for the User. (e.g. test@optimizely.com)
  identifier_type: string@identifier-type-completer # <p>User data is identified by the email address used to create the end user account. The endpoint only accepts the <code>email</code> datatype if you selected <code>user</code> for <strong>Datatype</strong>.<br> <br> If you selected <code>visitor</code> for <strong>data_type</strong>, you can select 5 options for personal identifier types:</p>  <ul>     <li>     <p><code>dcp_id</code> - Any ID used to identify targeting records in Optimizely.</p>     </li>     <li>     <p><code>email</code> - The email address of a visitor.</p>     </li>     <li>     <p><code>fullstack_id</code> - The unique identifier used for Full Stack experiments.</p>     </li>     <li>     <p><code>optimizely_end_user_id</code> - An Optimizely generated user cookie.</p>     </li>     <li>     <p><code>other</code> -&nbsp;Any other identifier that was uploaded to Optimizely.</p>     </li> </ul>  (e.g. email)
  request_type: string@request-type-completer # <code>delete</code> - Removes all data within an account that is associated to the identifier defined in the identifier field. <br> <code>access</code> - Finds all data stored in Optimizely systems associated to the identifier defined in the identifier field and exports it to an AWS S3 bucket for you to access.  (e.g. access)
]: any -> record<account_id: int, completed_at_time: string, data_type: string, expired_at_time: string, export_location: string, id: int, identifier: string, identifier_type: string, processing_started_time: string, request_type: string, requested_at_time: string, sla_deadline_time: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subject-access-requests")
  let body = {data_type: $data_type, identifier: $identifier, identifier_type: $identifier_type, request_type: $request_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Subject Access Request
#
# GET /subject-access-requests/{request_id}
# operationId: get_sar_request
export def "subject-access-requests request-by-request_id" [
  request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_id: int, completed_at_time: string, data_type: string, expired_at_time: string, export_location: string, id: int, identifier: string, identifier_type: string, processing_started_time: string, request_type: string, requested_at_time: string, sla_deadline_time: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subject-access-requests/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Webhook
#
# DELETE /webhooks/{webhook_id}
# operationId: delete_webhook
export def "webhooks webhook-by-webhook_id" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, message: string, messages: record, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read a Webhook
#
# GET /webhooks/{webhook_id}
# operationId: get_webhook
export def "webhooks webhook-by-webhook_id-1" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, created: string, description: string, events: list<string>, id: int, last_modified: string, name: string, project_id: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Webhook
#
# PATCH /webhooks/{webhook_id}
# operationId: update_webhook
export def "webhooks webhook-by-webhook_id-2" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A short description of the Webhook. (e.g. Webhook description)
  --events: list # List of events subscribed to the webhook.
  name: string # Name of the Webhook.
  project_id: int # ID of the project of the Environment.
]: any -> record<active: bool, created: string, description: string, events: list<string>, id: int, last_modified: string, name: string, project_id: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let body = {description: $description, events: $events, name: $name, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
