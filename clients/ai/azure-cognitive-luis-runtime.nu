# Auto-generated client for Language Understanding Intelligent Service (LUIS) Endpoint API for running predictions and extracting user intentions and entities from utterances. vv2.0 preview
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Runtime/v2.0%20preview/swagger.json
# Auth: --token flag or $env.LANGUAGE_UNDERSTANDING_INTELLIGENT_SERVICE_LUIS__ENDPOINT_API_FOR_RUNNING_PREDICTIONS_AND_EXTRACTING_USER_INTENTIONS_AND_ENTITIES_FROM_UTTERANCES_TOKEN

const BASE_URL = "https://azure.local/luis/v2.0/apps"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LANGUAGE_UNDERSTANDING_INTELLIGENT_SERVICE_LUIS__ENDPOINT_API_FOR_RUNNING_PREDICTIONS_AND_EXTRACTING_USER_INTENTIONS_AND_ENTITIES_FROM_UTTERANCES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://azure.local/luis/v2.0/apps"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api Resolve2" } } | get name | first)
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

# Gets predictions for a given utterance, in the form of intents and entities. The current maximum query size is 500 characters.
#
# GET /{appId}
# operationId: Prediction_Resolve2
export def "api Resolve2" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The utterance to predict.
  --timezoneOffset: float # The timezone offset for the location of the request.
  --verbose: oneof<nothing, bool> # If true, return all intents instead of just the top scoring intent.
  --staging: oneof<nothing, bool> # Use the staging endpoint slot.
  --spellCheck: oneof<nothing, bool> # Enable spell checking.
  --bing-spell-check-subscription-key: string # The subscription key to use when enabling bing spell check
  --log: oneof<nothing, bool> # Log query (default is true)
]: nothing -> record<alteredQuery: string, compositeEntities: table<children: list, parentType: string, value: string>, entities: table<endIndex: float, entity: string, startIndex: float, type: string>, intents: table<intent: string, score: float>, query: string, sentimentAnalysis: record<label: string, score: float>, topScoringIntent: record<intent: string, score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "timezoneOffset" $timezoneOffset "scalar") (serialize-qp "verbose" $verbose "scalar") (serialize-qp "staging" $staging "scalar") (serialize-qp "spellCheck" $spellCheck "scalar") (serialize-qp "bing-spell-check-subscription-key" $bing_spell_check_subscription_key "scalar") (serialize-qp "log" $log "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($appId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets predictions for a given utterance, in the form of intents and entities. The current maximum query size is 500 characters.
#
# POST /{appId}
# operationId: Prediction_Resolve
export def "api Resolve" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timezoneOffset: float # The timezone offset for the location of the request.
  --verbose: oneof<nothing, bool> # If true, return all intents instead of just the top scoring intent.
  --staging: oneof<nothing, bool> # Use the staging endpoint slot.
  --spellCheck: oneof<nothing, bool> # Enable spell checking.
  --bing-spell-check-subscription-key: string # The subscription key to use when enabling bing spell check
  --log: oneof<nothing, bool> # Log query (default is true)
  --body: record
]: any -> record<alteredQuery: string, compositeEntities: table<children: list, parentType: string, value: string>, entities: table<endIndex: float, entity: string, startIndex: float, type: string>, intents: table<intent: string, score: float>, query: string, sentimentAnalysis: record<label: string, score: float>, topScoringIntent: record<intent: string, score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timezoneOffset" $timezoneOffset "scalar") (serialize-qp "verbose" $verbose "scalar") (serialize-qp "staging" $staging "scalar") (serialize-qp "spellCheck" $spellCheck "scalar") (serialize-qp "bing-spell-check-subscription-key" $bing_spell_check_subscription_key "scalar") (serialize-qp "log" $log "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($appId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
