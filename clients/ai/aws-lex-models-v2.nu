# Auto-generated client for Amazon Lex Model Building V2 v2020-08-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/models.lex.v2/2020-08-07/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_MODEL_BUILDING_V2_TOKEN

const BASE_URL = "http://models-v2-lex.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LEX_MODEL_BUILDING_V2_TOKEN | default "" }
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

def base-url-completer [] { ["http://models-v2-lex.us-east-1.amazonaws.com" "http://models-v2-lex.us-east-2.amazonaws.com" "http://models-v2-lex.us-west-1.amazonaws.com" "http://models-v2-lex.us-west-2.amazonaws.com" "http://models-v2-lex.us-gov-west-1.amazonaws.com" "http://models-v2-lex.us-gov-east-1.amazonaws.com" "http://models-v2-lex.ca-central-1.amazonaws.com" "http://models-v2-lex.eu-north-1.amazonaws.com" "http://models-v2-lex.eu-west-1.amazonaws.com" "http://models-v2-lex.eu-west-2.amazonaws.com" "http://models-v2-lex.eu-west-3.amazonaws.com" "http://models-v2-lex.eu-central-1.amazonaws.com" "http://models-v2-lex.eu-south-1.amazonaws.com" "http://models-v2-lex.af-south-1.amazonaws.com" "http://models-v2-lex.ap-northeast-1.amazonaws.com" "http://models-v2-lex.ap-northeast-2.amazonaws.com" "http://models-v2-lex.ap-northeast-3.amazonaws.com" "http://models-v2-lex.ap-southeast-1.amazonaws.com" "http://models-v2-lex.ap-southeast-2.amazonaws.com" "http://models-v2-lex.ap-east-1.amazonaws.com" "http://models-v2-lex.ap-south-1.amazonaws.com" "http://models-v2-lex.sa-east-1.amazonaws.com" "http://models-v2-lex.me-south-1.amazonaws.com" "https://models-v2-lex.us-east-1.amazonaws.com" "https://models-v2-lex.us-east-2.amazonaws.com" "https://models-v2-lex.us-west-1.amazonaws.com" "https://models-v2-lex.us-west-2.amazonaws.com" "https://models-v2-lex.us-gov-west-1.amazonaws.com" "https://models-v2-lex.us-gov-east-1.amazonaws.com" "https://models-v2-lex.ca-central-1.amazonaws.com" "https://models-v2-lex.eu-north-1.amazonaws.com" "https://models-v2-lex.eu-west-1.amazonaws.com" "https://models-v2-lex.eu-west-2.amazonaws.com" "https://models-v2-lex.eu-west-3.amazonaws.com" "https://models-v2-lex.eu-central-1.amazonaws.com" "https://models-v2-lex.eu-south-1.amazonaws.com" "https://models-v2-lex.af-south-1.amazonaws.com" "https://models-v2-lex.ap-northeast-1.amazonaws.com" "https://models-v2-lex.ap-northeast-2.amazonaws.com" "https://models-v2-lex.ap-northeast-3.amazonaws.com" "https://models-v2-lex.ap-southeast-1.amazonaws.com" "https://models-v2-lex.ap-southeast-2.amazonaws.com" "https://models-v2-lex.ap-east-1.amazonaws.com" "https://models-v2-lex.ap-south-1.amazonaws.com" "https://models-v2-lex.sa-east-1.amazonaws.com" "https://models-v2-lex.me-south-1.amazonaws.com" "http://models-v2-lex.cn-north-1.amazonaws.com.cn" "http://models-v2-lex.cn-northwest-1.amazonaws.com.cn" "https://models-v2-lex.cn-north-1.amazonaws.com.cn" "https://models-v2-lex.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def botType-completer [] { ["Bot" "BotNetwork"] }
def fileFormat-completer [] { ["LexJson" "TSV"] }
def effect-completer [] { ["Allow" "Deny"] }
def mergeStrategy-completer [] { ["Append" "FailOnConflict" "Overwrite"] }
def searchOrder-completer [] { ["Ascending" "Descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bots-botversions-botlocales-customvocabulary-default-batchcreate BatchCreateCustomVocabularyItem" } } | get name | first)
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

# Create a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchcreate
# operationId: BatchCreateCustomVocabularyItem
# --customVocabularyItemList item shape: {phrase: any, weight?: any, displayAs?: any}
export def "bots-botversions-botlocales-customvocabulary-default-batchcreate BatchCreateCustomVocabularyItem" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  customVocabularyItemList: list # A list of new custom vocabulary items. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {phrase: any, weight?: any, displayAs?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, errors: record, resources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/customvocabulary/DEFAULT/batchcreate")
  let body = {customVocabularyItemList: $customVocabularyItemList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchdelete
# operationId: BatchDeleteCustomVocabularyItem
# --customVocabularyItemList item shape: {itemId: any}
export def "bots-botversions-botlocales-customvocabulary-default-batchdelete BatchDeleteCustomVocabularyItem" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  customVocabularyItemList: list # A list of custom vocabulary items requested to be deleted. Each entry must contain the unique custom vocabulary entry identifier. — item shape: {itemId: any}
]: any -> record<botId: record, botVersion: record, localeId: record, errors: record, resources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/customvocabulary/DEFAULT/batchdelete")
  let body = {customVocabularyItemList: $customVocabularyItemList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchupdate
# operationId: BatchUpdateCustomVocabularyItem
# --customVocabularyItemList item shape: {itemId: any, phrase: any, weight?: any, displayAs?: any}
export def "bots-botversions-botlocales-customvocabulary-default-batchupdate BatchUpdateCustomVocabularyItem" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  customVocabularyItemList: list # A list of custom vocabulary items with updated fields. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {itemId: any, phrase: any, weight?: any, displayAs?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, errors: record, resources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/customvocabulary/DEFAULT/batchupdate")
  let body = {customVocabularyItemList: $customVocabularyItemList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Builds a bot, its intents, and its slot types into a specific locale. A bot can be built into multiple locales. At runtime the locale is used to choose a specific build of the bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: BuildBotLocale
export def "bots-botversions-botlocales BuildBotLocale" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, botLocaleStatus: record, lastBuildSubmittedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Removes a locale from a bot.</p> <p>When you delete a locale, all intents, slots, and slot types defined for the locale are also deleted.</p>
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: DeleteBotLocale
export def "bots-botversions-botlocales DeleteBotLocale" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, botLocaleStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes the settings that a bot has for a specific locale. 
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: DescribeBotLocale
export def "bots-botversions-botlocales DescribeBotLocale" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, localeName: record, description: record, nluIntentConfidenceThreshold: record, voiceSettings: record<voiceId: record, engine: record>, intentsCount: record, slotTypesCount: record, botLocaleStatus: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record, lastBuildSubmittedDateTime: record, botLocaleHistoryEvents: record, recommendedActions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the settings that a bot has for a specific locale.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: UpdateBotLocale
# --voiceSettings shape: {voiceId?: any, engine?: any}
export def "bots-botversions-botlocales UpdateBotLocale" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --description: string # The new description of the locale.
  nluIntentConfidenceThreshold: float # The new confidence threshold where Amazon Lex inserts the <code>AMAZON.FallbackIntent</code> and <code>AMAZON.KendraSearchIntent</code> intents in the list of possible intents for an utterance. (format: double)
  --voiceSettings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: any, engine?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, localeName: record, description: record, nluIntentConfidenceThreshold: record, voiceSettings: record<voiceId: record, engine: record>, botLocaleStatus: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record, recommendedActions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/")
  let body = {description: $description, nluIntentConfidenceThreshold: $nluIntentConfidenceThreshold, voiceSettings: $voiceSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Amazon Lex conversational bot. 
#
# PUT /bots/
# operationId: CreateBot
# --dataPrivacy shape: {childDirected?: any}
# --botMembers item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
export def "bots CreateBot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  botName: string # The name of the bot. The bot name must be unique in the account that creates the bot.
  --description: string # A description of the bot. It appears in lists to help you identify a particular bot.
  roleArn: string # The Amazon Resource Name (ARN) of an IAM role that has permission to access the bot.
  dataPrivacy: record # By default, data stored by Amazon Lex is encrypted. The <code>DataPrivacy</code> structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot.  — shape: {childDirected?: any}
  idleSessionTTLInSeconds: int # <p>The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. </p> <p>A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout.</p> <p>You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.</p>
  --botTags: record # A list of tags to add to the bot. You can only add tags when you create a bot. You can't use the <code>UpdateBot</code> operation to update tags. To update tags, use the <code>TagResource</code> operation.
  --testBotAliasTags: record # A list of tags to add to the test alias for a bot. You can only add tags when you create a bot. You can't use the <code>UpdateAlias</code> operation to update tags. To update tags on the test alias, use the <code>TagResource</code> operation.
  --botType: string@botType-completer # The type of a bot to create.
  --botMembers: list # The list of bot members in a network to be created. — item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
]: any -> record<botId: record, botName: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, creationDateTime: record, botTags: record, testBotAliasTags: record, botType: record, botMembers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bots/")
  let body = {botName: $botName, description: $description, roleArn: $roleArn, dataPrivacy: $dataPrivacy, idleSessionTTLInSeconds: $idleSessionTTLInSeconds, botTags: $botTags, testBotAliasTags: $testBotAliasTags, botType: $botType, botMembers: $botMembers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of available bots.
#
# POST /bots/
# operationId: ListBots
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots ListBots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of bots to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned.
  --nextToken: string # <p>If the response from the <code>ListBots</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. </p> <p>Use the returned token in the <code>nextToken</code> parameter of a <code>ListBots</code> request to return the next page of results. For a complete set of results, call the <code>ListBots</code> operation until the <code>nextToken</code> returned in the response is null.</p>
]: any -> record<botSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bots/" $qp)
  let body = {sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an alias for the specified version of a bot. Use an alias to enable you to change the version of a bot without updating applications that use the bot.</p> <p>For example, you can create an alias called "PROD" that your applications use to call the Amazon Lex bot. </p>
#
# PUT /bots/{botId}/botaliases/
# operationId: CreateBotAlias
# --conversationLogSettings shape: {textLogSettings?: any, audioLogSettings?: any}
# --sentimentAnalysisSettings shape: {detectSentiment?: any}
export def "bots-botaliases CreateBotAlias" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  botAliasName: string # The alias to create. The name must be unique for the bot.
  --description: string # A description of the alias. Use this description to help identify the alias.
  --botVersion: string # The version of the bot that this alias points to. You can use the <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_UpdateBotAlias.html">UpdateBotAlias</a> operation to change the bot version associated with the alias.
  --botAliasLocaleSettings: record # Maps configuration information to a specific locale. You can use this parameter to specify a specific Lambda function to run different functions in different locales.
  --conversationLogSettings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: any, audioLogSettings?: any}
  --sentimentAnalysisSettings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: any}
  --tags: record # A list of tags to add to the bot alias. You can only add tags when you create an alias, you can't use the <code>UpdateBotAlias</code> operation to update the tags on a bot alias. To update tags, use the <code>TagResource</code> operation.
]: any -> record<botAliasId: record, botAliasName: record, description: record, botVersion: record, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: record, audioLogSettings: record>, sentimentAnalysisSettings: record<detectSentiment: record>, botAliasStatus: record, botId: record, creationDateTime: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botaliases/")
  let body = {botAliasName: $botAliasName, description: $description, botVersion: $botVersion, botAliasLocaleSettings: $botAliasLocaleSettings, conversationLogSettings: $conversationLogSettings, sentimentAnalysisSettings: $sentimentAnalysisSettings, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of aliases for the specified bot.
#
# POST /bots/{botId}/botaliases/
# operationId: ListBotAliases
export def "bots-botaliases ListBotAliases" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --maxResults: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the <code>ListBotAliases</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<botAliasSummaries: record, nextToken: record, botId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botaliases/" $qp)
  let body = {maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a locale in the bot. The locale contains the intents and slot types that the bot uses in conversations with users in the specified language and locale. You must add a locale to a bot before you can add intents and slot types to the bot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/
# operationId: CreateBotLocale
# --voiceSettings shape: {voiceId?: any, engine?: any}
export def "bots-botversions-botlocales CreateBotLocale" [
  botId: string
  botVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  localeId: string # The identifier of the language and locale that the bot will be used in. The string must match one of the supported locales. All of the intents, slot types, and slots used in the bot must have the same locale. For more information, see <a href="https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html">Supported languages</a>.
  --description: string # A description of the bot locale. Use this to help identify the bot locale in lists.
  nluIntentConfidenceThreshold: float # <p>Determines the threshold where Amazon Lex will insert the <code>AMAZON.FallbackIntent</code>, <code>AMAZON.KendraSearchIntent</code>, or both when returning alternative intents. <code>AMAZON.FallbackIntent</code> and <code>AMAZON.KendraSearchIntent</code> are only inserted if they are configured for the bot.</p> <p>For example, suppose a bot is configured with the confidence threshold of 0.80 and the <code>AMAZON.FallbackIntent</code>. Amazon Lex returns three alternative intents with the following confidence scores: IntentA (0.70), IntentB (0.60), IntentC (0.50). The response from the <code>RecognizeText</code> operation would be:</p> <ul> <li> <p>AMAZON.FallbackIntent</p> </li> <li> <p>IntentA</p> </li> <li> <p>IntentB</p> </li> <li> <p>IntentC</p> </li> </ul> (format: double)
  --voiceSettings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: any, engine?: any}
]: any -> record<botId: record, botVersion: record, localeName: record, localeId: record, description: record, nluIntentConfidenceThreshold: record, voiceSettings: record<voiceId: record, engine: record>, botLocaleStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/")
  let body = {localeId: $localeId, description: $description, nluIntentConfidenceThreshold: $nluIntentConfidenceThreshold, voiceSettings: $voiceSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of locales for the specified bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/
# operationId: ListBotLocales
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales ListBotLocales" [
  botId: string
  botVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of bot locales. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification for a filter used to limit the response to only those locales that match the filter specification. You can only specify one filter and one value to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the <code>ListBotLocales</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token as the <code>nextToken</code> parameter to return the next page of results. 
]: any -> record<botId: record, botVersion: record, nextToken: record, botLocaleSummaries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/" $qp)
  let body = {sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a new version of the bot based on the <code>DRAFT</code> version. If the <code>DRAFT</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version, it returns the last created version.</p> <p>When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1.</p>
#
# PUT /bots/{botId}/botversions/
# operationId: CreateBotVersion
export def "bots-botversions CreateBotVersion" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --description: string # A description of the version. Use the description to help identify the version in lists.
  botVersionLocaleSpecification: record # Specifies the locales that Amazon Lex adds to this version. You can choose the <code>Draft</code> version or any other previously published version for each locale. When you specify a source version, the locale data is copied from the source version to the new version.
]: any -> record<botId: record, description: record, botVersion: record, botVersionLocaleSpecification: record, botStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/")
  let body = {description: $description, botVersionLocaleSpecification: $botVersionLocaleSpecification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Gets information about all of the versions of a bot.</p> <p>The <code>ListBotVersions</code> operation returns a summary of each version of a bot. For example, if a bot has three numbered versions, the <code>ListBotVersions</code> operation returns for summaries, one for each numbered version and one for the <code>DRAFT</code> version.</p> <p>The <code>ListBotVersions</code> operation always returns at least one version, the <code>DRAFT</code> version.</p>
#
# POST /bots/{botId}/botversions/
# operationId: ListBotVersions
# --sortBy shape: {attribute?: any, order?: any}
export def "bots-botversions ListBotVersions" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of bot versions. — shape: {attribute?: any, order?: any}
  --maxResults: int # The maximum number of versions to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response to the <code>ListBotVersion</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<botId: record, botVersionSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/" $qp)
  let body = {sortBy: $sortBy, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a zip archive containing the contents of a bot or a bot locale. The archive contains a directory structure that contains JSON files that define the bot.</p> <p>You can create an archive that contains the complete definition of a bot, or you can specify that the archive contain only the definition of a single bot locale.</p> <p>For more information about exporting bots, and about the structure of the export archive, see <a href="https://docs.aws.amazon.com/lexv2/latest/dg/importing-exporting.html"> Importing and exporting bots </a> </p>
#
# PUT /exports/
# operationId: CreateExport
# --resourceSpecification shape: {botExportSpecification?: any, botLocaleExportSpecification?: any, customVocabularyExportSpecification?: any}
export def "exports CreateExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  resourceSpecification: record # Provides information about the bot or bot locale that you want to export. You can specify the <code>botExportSpecification</code> or the <code>botLocaleExportSpecification</code>, but not both. — shape: {botExportSpecification?: any, botLocaleExportSpecification?: any, customVocabularyExportSpecification?: any}
  fileFormat: string@fileFormat-completer # The file format of the bot or bot locale definition files.
  --filePassword: string # An password to use to encrypt the exported archive. Using a password is optional, but you should encrypt the archive to protect the data in transit between Amazon Lex and your local computer. (format: password)
]: any -> record<exportId: record, resourceSpecification: record<botExportSpecification: record<botId: record, botVersion: record>, botLocaleExportSpecification: record<botId: record, botVersion: record, localeId: record>, customVocabularyExportSpecification: record<botId: record, botVersion: record, localeId: record>>, fileFormat: record, exportStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exports/")
  let body = {resourceSpecification: $resourceSpecification, fileFormat: $fileFormat, filePassword: $filePassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the exports for a bot, bot locale, or custom vocabulary. Exports are kept in the list for 7 days.
#
# POST /exports/
# operationId: ListExports
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "exports ListExports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --botId: string # The unique identifier that Amazon Lex assigned to the bot.
  --botVersion: string # The version of the bot to list exports for. 
  --sortBy: record # Provides information about sorting a list of exports. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the exports in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of exports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # <p>If the response from the <code>ListExports</code> operation contains more results that specified in the <code>maxResults</code> parameter, a token is returned in the response. </p> <p>Use the returned token in the <code>nextToken</code> parameter of a <code>ListExports</code> request to return the next page of results. For a complete set of results, call the <code>ListExports</code> operation until the <code>nextToken</code> returned in the response is null.</p>
  --localeId: string # Specifies the resources that should be exported. If you don't specify a resource type in the <code>filters</code> parameter, both bot locales and custom vocabularies are exported.
]: any -> record<botId: record, botVersion: record, exportSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exports/" $qp)
  let body = {botId: $botId, botVersion: $botVersion, sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken, localeId: $localeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an intent.</p> <p>To define the interaction between the user and your bot, you define one or more intents. For example, for a pizza ordering bot you would create an <code>OrderPizza</code> intent.</p> <p>When you create an intent, you must provide a name. You can optionally provide the following:</p> <ul> <li> <p>Sample utterances. For example, "I want to order a pizza" and "Can I order a pizza." You can't provide utterances for built-in intents.</p> </li> <li> <p>Information to be gathered. You specify slots for the information that you bot requests from the user. You can specify standard slot types, such as date and time, or custom slot types for your application.</p> </li> <li> <p>How the intent is fulfilled. You can provide a Lambda function or configure the intent to return the intent information to your client application. If you use a Lambda function, Amazon Lex invokes the function when all of the intent information is available.</p> </li> <li> <p>A confirmation prompt to send to the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent is fulfilled. For example, "I ordered your pizza."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, "Do you want a drink with your pizza?"</p> </li> </ul>
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# operationId: CreateIntent
# --sampleUtterances item shape: {utterance: any}
# --dialogCodeHook shape: {enabled?: any}
# --fulfillmentCodeHook shape: {enabled?: any, postFulfillmentStatusSpecification?: any, fulfillmentUpdatesSpecification?: any, active?: any}
# --intentConfirmationSetting shape: {promptSpecification?: any, declinationResponse?: any, active?: any, confirmationResponse?: record, confirmationNextStep?: any, confirmationConditional?: any, declinationNextStep?: any, declinationConditional?: any, failureResponse?: record, failureNextStep?: any, failureConditional?: record, codeHook?: any, elicitationCodeHook?: any}
# --intentClosingSetting shape: {closingResponse?: any, active?: any, nextStep?: any, conditional?: any}
# --inputContexts item shape: {name: any}
# --outputContexts item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
# --kendraConfiguration shape: {kendraIndex?: any, queryFilterStringEnabled?: any, queryFilterString?: any}
# --initialResponseSetting shape: {initialResponse?: record, nextStep?: any, conditional?: record, codeHook?: record}
export def "bots-botversions-botlocales-intents CreateIntent" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  intentName: string # The name of the intent. Intent names must be unique in the locale that contains the intent and cannot match the name of any built-in intent.
  --description: string # A description of the intent. Use the description to help identify the intent in lists.
  --parentIntentSignature: string # A unique identifier for the built-in intent to base this intent on.
  --sampleUtterances: list # <p>An array of strings that a user might say to signal the intent. For example, "I want a pizza", or "I want a {PizzaSize} pizza". </p> <p>In an utterance, slot names are enclosed in curly braces ("{", "}") to indicate where they should be displayed in the utterance shown to the user.. </p> — item shape: {utterance: any}
  --dialogCodeHook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: any}
  --fulfillmentCodeHook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: any, postFulfillmentStatusSpecification?: any, fulfillmentUpdatesSpecification?: any, active?: any}
  --intentConfirmationSetting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: any, declinationResponse?: any, active?: any, confirmationResponse?: record, confirmationNextStep?: any, confirmationConditional?: any, declinationNextStep?: any, declinationConditional?: any, failureResponse?: record, failureNextStep?: any, failureConditional?: record, codeHook?: any, elicitationCodeHook?: any}
  --intentClosingSetting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: any, active?: any, nextStep?: any, conditional?: any}
  --inputContexts: list # <p>A list of contexts that must be active for this intent to be considered by Amazon Lex.</p> <p>When an intent has an input context list, Amazon Lex only considers using the intent in an interaction with the user when the specified contexts are included in the active context list for the session. If the contexts are not active, then Amazon Lex will not use the intent.</p> <p>A context can be automatically activated using the <code>outputContexts</code> property or it can be set at runtime.</p> <p> For example, if there are two intents with different input contexts that respond to the same utterances, only the intent with the active context will respond.</p> <p>An intent may have up to 5 input contexts. If an intent has multiple input contexts, all of the contexts must be active to consider the intent.</p> — item shape: {name: any}
  --outputContexts: list # <p>A lists of contexts that the intent activates when it is fulfilled.</p> <p>You can use an output context to indicate the intents that Amazon Lex should consider for the next turn of the conversation with a customer. </p> <p>When you use the <code>outputContextsList</code> property, all of the contexts specified in the list are activated when the intent is fulfilled. You can set up to 10 output contexts. You can also set the number of conversation turns that the context should be active, or the length of time that the context should be active.</p> — item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
  --kendraConfiguration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: any, queryFilterStringEnabled?: any, queryFilterString?: any}
  --initialResponseSetting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: any, conditional?: record, codeHook?: record}
]: any -> record<intentId: record, intentName: record, description: record, parentIntentSignature: record, sampleUtterances: record, dialogCodeHook: record<enabled: record>, fulfillmentCodeHook: record<enabled: record, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: record, startResponse: record, updateResponse: record, timeoutInSeconds: record>, active: record>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: record, allowInterrupt: record>, active: record, confirmationResponse: record<messageGroups: record, allowInterrupt: record>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, failureResponse: record<messageGroups: record, allowInterrupt: record>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: record, invocationLabel: record>>, intentClosingSetting: record<closingResponse: record<messageGroups: record, allowInterrupt: record>, active: record, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>>, inputContexts: record, outputContexts: record, kendraConfiguration: record<kendraIndex: record, queryFilterStringEnabled: record, queryFilterString: record>, botId: record, botVersion: record, localeId: record, creationDateTime: record, initialResponseSetting: record<initialResponse: record<messageGroups: record, allowInterrupt: record>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/")
  let body = {intentName: $intentName, description: $description, parentIntentSignature: $parentIntentSignature, sampleUtterances: $sampleUtterances, dialogCodeHook: $dialogCodeHook, fulfillmentCodeHook: $fulfillmentCodeHook, intentConfirmationSetting: $intentConfirmationSetting, intentClosingSetting: $intentClosingSetting, inputContexts: $inputContexts, outputContexts: $outputContexts, kendraConfiguration: $kendraConfiguration, initialResponseSetting: $initialResponseSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of intents that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# operationId: ListIntents
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales-intents ListIntents" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of intents. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the intents in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # <p>If the response from the <code>ListIntents</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response.</p> <p>Use the returned token in the <code>nextToken</code> parameter of a <code>ListIntents</code> request to return the next page of results. For a complete set of results, call the <code>ListIntents</code> operation until the <code>nextToken</code> returned in the response is null.</p>
]: any -> record<botId: record, botVersion: record, localeId: record, intentSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/" $qp)
  let body = {sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new resource policy with the specified policy statements.
#
# POST /policy/{resourceArn}/
# operationId: CreateResourcePolicy
export def "policy CreateResourcePolicy" [
  resourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  policy: string # <p>A resource policy to add to the resource. The policy is a JSON structure that contains one or more statements that define the policy. The policy must follow the IAM syntax. For more information about the contents of a JSON policy document, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html"> IAM JSON policy reference </a>. </p> <p>If the policy isn't valid, Amazon Lex returns a validation exception.</p>
]: any -> record<resourceArn: record, revisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/policy/($resourceArn)/")
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing policy from a bot or bot alias. If the resource doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/
# operationId: DeleteResourcePolicy
export def "policy DeleteResourcePolicy" [
  resourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expectedRevisionId: string # <p>The identifier of the revision to edit. If this ID doesn't match the current revision number, Amazon Lex returns an exception</p> <p>If you don't specify a revision ID, Amazon Lex will delete the current policy.</p>
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expectedRevisionId" $expectedRevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/policy/($resourceArn)/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the resource policy and policy revision for a bot or bot alias.
#
# GET /policy/{resourceArn}/
# operationId: DescribeResourcePolicy
export def "policy DescribeResourcePolicy" [
  resourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<resourceArn: record, policy: record, revisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/policy/($resourceArn)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the existing resource policy for a bot or bot alias with a new one. If the policy doesn't exist, Amazon Lex returns an exception.
#
# PUT /policy/{resourceArn}/
# operationId: UpdateResourcePolicy
export def "policy UpdateResourcePolicy" [
  resourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expectedRevisionId: string # <p>The identifier of the revision of the policy to update. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception.</p> <p>If you don't specify a revision, Amazon Lex overwrites the contents of the policy with the new values.</p>
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  policy: string # <p>A resource policy to add to the resource. The policy is a JSON structure that contains one or more statements that define the policy. The policy must follow the IAM syntax. For more information about the contents of a JSON policy document, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html"> IAM JSON policy reference </a>. </p> <p>If the policy isn't valid, Amazon Lex returns a validation exception.</p>
]: any -> record<resourceArn: record, revisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expectedRevisionId" $expectedRevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/policy/($resourceArn)/" $qp)
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Adds a new resource policy statement to a bot or bot alias. If a resource policy exists, the statement is added to the current resource policy. If a policy doesn't exist, a new policy is created.</p> <p>You can't create a resource policy statement that allows cross-account access.</p>
#
# POST /policy/{resourceArn}/statements/
# operationId: CreateResourcePolicyStatement
# --principal item shape: {service?: any, arn?: any}
export def "policy-statements CreateResourcePolicyStatement" [
  resourceArn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expectedRevisionId: string # <p>The identifier of the revision of the policy to edit. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception.</p> <p>If you don't specify a revision, Amazon Lex overwrites the contents of the policy with the new values.</p>
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  statementId: string # The name of the statement. The ID is the same as the <code>Sid</code> IAM property. The statement name must be unique within the policy. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_sid.html">IAM JSON policy elements: Sid</a>. 
  effect: string@effect-completer # Determines whether the statement allows or denies access to the resource.
  principal: list # An IAM principal, such as an IAM users, IAM roles, or AWS services that is allowed or denied access to a resource. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html">AWS JSON policy elements: Principal</a>. — item shape: {service?: any, arn?: any}
  action: list # The Amazon Lex action that this policy either allows or denies. The action must apply to the resource type of the specified ARN. For more information, see <a href="https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonlexv2.html"> Actions, resources, and condition keys for Amazon Lex V2</a>.
  --condition: record # <p>Specifies a condition when the policy is in effect. If the principal of the policy is a service principal, you must provide two condition blocks, one with a SourceAccount global condition key and one with a SourceArn global condition key.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html">IAM JSON policy elements: Condition </a>.</p>
]: any -> record<resourceArn: record, revisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expectedRevisionId" $expectedRevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/policy/($resourceArn)/statements/" $qp)
  let body = {statementId: $statementId, effect: $effect, principal: $principal, action: $action, condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a slot in an intent. A slot is a variable needed to fulfill an intent. For example, an <code>OrderPizza</code> intent might need slots for size, crust, and number of pizzas. For each slot, you define one or more utterances that Amazon Lex uses to elicit a response from the user. 
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# operationId: CreateSlot
# --valueElicitationSetting shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
# --obfuscationSetting shape: {obfuscationSettingType?: any}
# --multipleValuesSetting shape: {allowMultipleValues?: any}
# --subSlotSetting shape: {expression?: any, slotSpecifications?: any}
export def "bots-botversions-botlocales-intents-slots CreateSlot" [
  botId: string
  botVersion: string
  localeId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  slotName: string # The name of the slot. Slot names must be unique within the bot that contains the slot.
  --description: string # A description of the slot. Use this to help identify the slot in lists.
  --slotTypeId: string # The unique identifier for the slot type associated with this slot. The slot type determines the values that can be entered into the slot.
  valueElicitationSetting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
  --obfuscationSetting: record # Determines whether Amazon Lex obscures slot values in conversation logs.  — shape: {obfuscationSettingType?: any}
  --multipleValuesSetting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: any}
  --subSlotSetting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: any, slotSpecifications?: any}
]: any -> record<slotId: record, slotName: record, description: record, slotTypeId: record, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: record>, slotConstraint: record, promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, sampleUtterances: record, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: record>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: record>, botId: record, botVersion: record, localeId: record, intentId: record, creationDateTime: record, multipleValuesSetting: record<allowMultipleValues: record>, subSlotSetting: record<expression: record, slotSpecifications: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/slots/")
  let body = {slotName: $slotName, description: $description, slotTypeId: $slotTypeId, valueElicitationSetting: $valueElicitationSetting, obfuscationSetting: $obfuscationSetting, multipleValuesSetting: $multipleValuesSetting, subSlotSetting: $subSlotSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of slots that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# operationId: ListSlots
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales-intents-slots ListSlots" [
  botId: string
  botVersion: string
  localeId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the slots in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of slots to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the <code>ListSlots</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<botId: record, botVersion: record, localeId: record, intentId: record, slotSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/slots/" $qp)
  let body = {sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a custom slot type</p> <p> To create a custom slot type, specify a name for the slot type and a set of enumeration values, the values that a slot of this type can assume. </p>
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# operationId: CreateSlotType
# --slotTypeValues item shape: {sampleValue?: any, synonyms?: any}
# --valueSelectionSetting shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
# --externalSourceSetting shape: {grammarSlotTypeSetting?: any}
# --compositeSlotTypeSetting shape: {subSlots?: any}
export def "bots-botversions-botlocales-slottypes CreateSlotType" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  slotTypeName: string # The name for the slot. A slot type name must be unique within the account.
  --description: string # A description of the slot type. Use the description to help identify the slot type in lists.
  --slotTypeValues: list # A list of <code>SlotTypeValue</code> objects that defines the values that the slot type can take. Each value can have a list of synonyms, additional values that help train the machine learning model about the values that it resolves for a slot. — item shape: {sampleValue?: any, synonyms?: any}
  --valueSelectionSetting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
  --parentSlotTypeSignature: string # <p>The built-in slot type used as a parent of this slot type. When you define a parent slot type, the new slot type has the configuration of the parent slot type.</p> <p>Only <code>AMAZON.AlphaNumeric</code> is supported.</p>
  --externalSourceSetting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: any}
  --compositeSlotTypeSetting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: any}
]: any -> record<slotTypeId: record, slotTypeName: record, description: record, slotTypeValues: record, valueSelectionSetting: record<resolutionStrategy: record, regexFilter: record<pattern: record>, advancedRecognitionSetting: record<audioRecognitionStrategy: record>>, parentSlotTypeSignature: record, botId: record, botVersion: record, localeId: record, creationDateTime: record, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/slottypes/")
  let body = {slotTypeName: $slotTypeName, description: $description, slotTypeValues: $slotTypeValues, valueSelectionSetting: $valueSelectionSetting, parentSlotTypeSignature: $parentSlotTypeSignature, externalSourceSetting: $externalSourceSetting, compositeSlotTypeSetting: $compositeSlotTypeSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of slot types that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# operationId: ListSlotTypes
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales-slottypes ListSlotTypes" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of slot types. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the slot types in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the <code>ListSlotTypes</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<botId: record, botVersion: record, localeId: record, slotTypeSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/slottypes/" $qp)
  let body = {sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a pre-signed S3 write URL that you use to upload the zip archive when importing a bot or a bot locale. 
#
# POST /createuploadurl/
# operationId: CreateUploadUrl
export def "createuploadurl CreateUploadUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<importId: record, uploadUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createuploadurl/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Deletes all versions of a bot, including the <code>Draft</code> version. To delete a specific version, use the <code>DeleteBotVersion</code> operation.</p> <p>When you delete a bot, all of the resources contained in the bot are also deleted. Deleting a bot removes all locales, intents, slot, and slot types defined for the bot.</p> <p>If a bot has an alias, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception. If you want to delete the bot and the alias, set the <code>skipResourceInUseCheck</code> parameter to <code>true</code>.</p>
#
# DELETE /bots/{botId}/
# operationId: DeleteBot
export def "bots DeleteBot" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipResourceInUseCheck: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as an alias or bot network, is using the bot version before it is deleted and throws a <code>ResourceInUseException</code> exception if the bot is being used by another resource. Set this parameter to <code>true</code> to skip this check and remove the bot even if it is being used by another resource.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipResourceInUseCheck" $skipResourceInUseCheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides metadata information about a bot. 
#
# GET /bots/{botId}/
# operationId: DescribeBot
export def "bots DescribeBot" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botName: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, creationDateTime: record, lastUpdatedDateTime: record, botType: record, botMembers: record, failureReasons: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the configuration of an existing bot. 
#
# PUT /bots/{botId}/
# operationId: UpdateBot
# --dataPrivacy shape: {childDirected?: any}
# --botMembers item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
export def "bots UpdateBot" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  botName: string # The new name of the bot. The name must be unique in the account that creates the bot.
  --description: string # A description of the bot.
  roleArn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the bot.
  dataPrivacy: record # By default, data stored by Amazon Lex is encrypted. The <code>DataPrivacy</code> structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot.  — shape: {childDirected?: any}
  idleSessionTTLInSeconds: int # <p>The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot.</p> <p>A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout.</p> <p>You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.</p>
  --botType: string@botType-completer # The type of the bot to be updated.
  --botMembers: list # The list of bot members in the network associated with the update action. — item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
]: any -> record<botId: record, botName: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, creationDateTime: record, lastUpdatedDateTime: record, botType: record, botMembers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/")
  let body = {botName: $botName, description: $description, roleArn: $roleArn, dataPrivacy: $dataPrivacy, idleSessionTTLInSeconds: $idleSessionTTLInSeconds, botType: $botType, botMembers: $botMembers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified bot alias.
#
# DELETE /bots/{botId}/botaliases/{botAliasId}/
# operationId: DeleteBotAlias
export def "bots-botaliases DeleteBotAlias" [
  botAliasId: string
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipResourceInUseCheck: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as a bot network, is using the bot alias before it is deleted and throws a <code>ResourceInUseException</code> exception if the alias is being used by another resource. Set this parameter to <code>true</code> to skip this check and remove the alias even if it is being used by another resource.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botAliasId: record, botId: record, botAliasStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipResourceInUseCheck" $skipResourceInUseCheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botaliases/($botAliasId)/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a specific bot alias.
#
# GET /bots/{botId}/botaliases/{botAliasId}/
# operationId: DescribeBotAlias
export def "bots-botaliases DescribeBotAlias" [
  botAliasId: string
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botAliasId: record, botAliasName: record, description: record, botVersion: record, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: record, audioLogSettings: record>, sentimentAnalysisSettings: record<detectSentiment: record>, botAliasHistoryEvents: record, botAliasStatus: record, botId: record, creationDateTime: record, lastUpdatedDateTime: record, parentBotNetworks: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botaliases/($botAliasId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the configuration of an existing bot alias.
#
# PUT /bots/{botId}/botaliases/{botAliasId}/
# operationId: UpdateBotAlias
# --conversationLogSettings shape: {textLogSettings?: any, audioLogSettings?: any}
# --sentimentAnalysisSettings shape: {detectSentiment?: any}
export def "bots-botaliases UpdateBotAlias" [
  botAliasId: string
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  botAliasName: string # The new name to assign to the bot alias.
  --description: string # The new description to assign to the bot alias.
  --botVersion: string # The new bot version to assign to the bot alias.
  --botAliasLocaleSettings: record # The new Lambda functions to use in each locale for the bot alias.
  --conversationLogSettings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: any, audioLogSettings?: any}
  --sentimentAnalysisSettings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: any}
]: any -> record<botAliasId: record, botAliasName: record, description: record, botVersion: record, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: record, audioLogSettings: record>, sentimentAnalysisSettings: record<detectSentiment: record>, botAliasStatus: record, botId: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botaliases/($botAliasId)/")
  let body = {botAliasName: $botAliasName, description: $description, botVersion: $botVersion, botAliasLocaleSettings: $botAliasLocaleSettings, conversationLogSettings: $conversationLogSettings, sentimentAnalysisSettings: $sentimentAnalysisSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific version of a bot. To delete all versions of a bot, use the <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DeleteBot.html">DeleteBot</a> operation.
#
# DELETE /bots/{botId}/botversions/{botVersion}/
# operationId: DeleteBotVersion
export def "bots-botversions DeleteBotVersion" [
  botId: string
  botVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipResourceInUseCheck: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as an alias or bot network, is using the bot version before it is deleted and throws a <code>ResourceInUseException</code> exception if the version is being used by another resource. Set this parameter to <code>true</code> to skip this check and remove the version even if it is being used by another resource.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, botStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipResourceInUseCheck" $skipResourceInUseCheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides metadata about a version of a bot.
#
# GET /bots/{botId}/botversions/{botVersion}/
# operationId: DescribeBotVersion
export def "bots-botversions DescribeBotVersion" [
  botId: string
  botVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botName: record, botVersion: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, failureReasons: record, creationDateTime: record, parentBotNetworks: record, botType: record, botMembers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a custom vocabulary from the specified locale in the specified bot.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary
# operationId: DeleteCustomVocabulary
export def "bots-botversions-botlocales-customvocabulary DeleteCustomVocabulary" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, customVocabularyStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/customvocabulary")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a previous export and the associated files stored in an S3 bucket.
#
# DELETE /exports/{exportId}/
# operationId: DeleteExport
export def "exports DeleteExport" [
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<exportId: record, exportStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exports/($exportId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a specific export.
#
# GET /exports/{exportId}/
# operationId: DescribeExport
export def "exports DescribeExport" [
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<exportId: record, resourceSpecification: record<botExportSpecification: record<botId: record, botVersion: record>, botLocaleExportSpecification: record<botId: record, botVersion: record, localeId: record>, customVocabularyExportSpecification: record<botId: record, botVersion: record, localeId: record>>, fileFormat: record, exportStatus: record, failureReasons: record, downloadUrl: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exports/($exportId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Updates the password used to protect an export zip archive.</p> <p>The password is not required. If you don't supply a password, Amazon Lex generates a zip file that is not protected by a password. This is the archive that is available at the pre-signed S3 URL provided by the <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DescribeExport.html">DescribeExport</a> operation.</p>
#
# PUT /exports/{exportId}/
# operationId: UpdateExport
export def "exports UpdateExport" [
  exportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --filePassword: string # The new password to use to encrypt the export zip archive. (format: password)
]: any -> record<exportId: record, resourceSpecification: record<botExportSpecification: record<botId: record, botVersion: record>, botLocaleExportSpecification: record<botId: record, botVersion: record, localeId: record>, customVocabularyExportSpecification: record<botId: record, botVersion: record, localeId: record>>, fileFormat: record, exportStatus: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exports/($exportId)/")
  let body = {filePassword: $filePassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a previous import and the associated file stored in an S3 bucket.
#
# DELETE /imports/{importId}/
# operationId: DeleteImport
export def "imports DeleteImport" [
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<importId: record, importStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/($importId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a specific import.
#
# GET /imports/{importId}/
# operationId: DescribeImport
export def "imports DescribeImport" [
  importId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<importId: record, resourceSpecification: record<botImportSpecification: record<botName: record, roleArn: record, dataPrivacy: record, idleSessionTTLInSeconds: record, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: record, botVersion: record, localeId: record, nluIntentConfidenceThreshold: record, voiceSettings: record>, customVocabularyImportSpecification: record<botId: record, botVersion: record, localeId: record>>, importedResourceId: record, importedResourceName: record, mergeStrategy: record, importStatus: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/imports/($importId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Removes the specified intent.</p> <p>Deleting an intent also deletes the slots associated with the intent.</p>
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DeleteIntent
export def "bots-botversions-botlocales-intents DeleteIntent" [
  intentId: string
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata about an intent.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DescribeIntent
export def "bots-botversions-botlocales-intents DescribeIntent" [
  intentId: string
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<intentId: record, intentName: record, description: record, parentIntentSignature: record, sampleUtterances: record, dialogCodeHook: record<enabled: record>, fulfillmentCodeHook: record<enabled: record, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: record, startResponse: record, updateResponse: record, timeoutInSeconds: record>, active: record>, slotPriorities: record, intentConfirmationSetting: record<promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: record, allowInterrupt: record>, active: record, confirmationResponse: record<messageGroups: record, allowInterrupt: record>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, failureResponse: record<messageGroups: record, allowInterrupt: record>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: record, invocationLabel: record>>, intentClosingSetting: record<closingResponse: record<messageGroups: record, allowInterrupt: record>, active: record, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>>, inputContexts: record, outputContexts: record, kendraConfiguration: record<kendraIndex: record, queryFilterStringEnabled: record, queryFilterString: record>, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, initialResponseSetting: record<initialResponse: record<messageGroups: record, allowInterrupt: record>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the settings for an intent.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: UpdateIntent
# --sampleUtterances item shape: {utterance: any}
# --dialogCodeHook shape: {enabled?: any}
# --fulfillmentCodeHook shape: {enabled?: any, postFulfillmentStatusSpecification?: any, fulfillmentUpdatesSpecification?: any, active?: any}
# --slotPriorities item shape: {priority: any, slotId: any}
# --intentConfirmationSetting shape: {promptSpecification?: any, declinationResponse?: any, active?: any, confirmationResponse?: record, confirmationNextStep?: any, confirmationConditional?: any, declinationNextStep?: any, declinationConditional?: any, failureResponse?: record, failureNextStep?: any, failureConditional?: record, codeHook?: any, elicitationCodeHook?: any}
# --intentClosingSetting shape: {closingResponse?: any, active?: any, nextStep?: any, conditional?: any}
# --inputContexts item shape: {name: any}
# --outputContexts item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
# --kendraConfiguration shape: {kendraIndex?: any, queryFilterStringEnabled?: any, queryFilterString?: any}
# --initialResponseSetting shape: {initialResponse?: record, nextStep?: any, conditional?: record, codeHook?: record}
export def "bots-botversions-botlocales-intents UpdateIntent" [
  intentId: string
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  intentName: string # The new name for the intent.
  --description: string # The new description of the intent.
  --parentIntentSignature: string # The signature of the new built-in intent to use as the parent of this intent.
  --sampleUtterances: list # New utterances used to invoke the intent. — item shape: {utterance: any}
  --dialogCodeHook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: any}
  --fulfillmentCodeHook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: any, postFulfillmentStatusSpecification?: any, fulfillmentUpdatesSpecification?: any, active?: any}
  --slotPriorities: list # A new list of slots and their priorities that are contained by the intent. — item shape: {priority: any, slotId: any}
  --intentConfirmationSetting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: any, declinationResponse?: any, active?: any, confirmationResponse?: record, confirmationNextStep?: any, confirmationConditional?: any, declinationNextStep?: any, declinationConditional?: any, failureResponse?: record, failureNextStep?: any, failureConditional?: record, codeHook?: any, elicitationCodeHook?: any}
  --intentClosingSetting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: any, active?: any, nextStep?: any, conditional?: any}
  --inputContexts: list # A new list of contexts that must be active in order for Amazon Lex to consider the intent. — item shape: {name: any}
  --outputContexts: list # A new list of contexts that Amazon Lex activates when the intent is fulfilled. — item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
  --kendraConfiguration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: any, queryFilterStringEnabled?: any, queryFilterString?: any}
  --initialResponseSetting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: any, conditional?: record, codeHook?: record}
]: any -> record<intentId: record, intentName: record, description: record, parentIntentSignature: record, sampleUtterances: record, dialogCodeHook: record<enabled: record>, fulfillmentCodeHook: record<enabled: record, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: record, startResponse: record, updateResponse: record, timeoutInSeconds: record>, active: record>, slotPriorities: record, intentConfirmationSetting: record<promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: record, allowInterrupt: record>, active: record, confirmationResponse: record<messageGroups: record, allowInterrupt: record>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, failureResponse: record<messageGroups: record, allowInterrupt: record>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: record, invocationLabel: record>>, intentClosingSetting: record<closingResponse: record<messageGroups: record, allowInterrupt: record>, active: record, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>>, inputContexts: record, outputContexts: record, kendraConfiguration: record<kendraIndex: record, queryFilterStringEnabled: record, queryFilterString: record>, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, initialResponseSetting: record<initialResponse: record<messageGroups: record, allowInterrupt: record>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/")
  let body = {intentName: $intentName, description: $description, parentIntentSignature: $parentIntentSignature, sampleUtterances: $sampleUtterances, dialogCodeHook: $dialogCodeHook, fulfillmentCodeHook: $fulfillmentCodeHook, slotPriorities: $slotPriorities, intentConfirmationSetting: $intentConfirmationSetting, intentClosingSetting: $intentClosingSetting, inputContexts: $inputContexts, outputContexts: $outputContexts, kendraConfiguration: $kendraConfiguration, initialResponseSetting: $initialResponseSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a policy statement from a resource policy. If you delete the last statement from a policy, the policy is deleted. If you specify a statement ID that doesn't exist in the policy, or if the bot or bot alias doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/statements/{statementId}/
# operationId: DeleteResourcePolicyStatement
export def "policy-statements DeleteResourcePolicyStatement" [
  resourceArn: string
  statementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expectedRevisionId: string # <p>The identifier of the revision of the policy to delete the statement from. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception.</p> <p>If you don't specify a revision, Amazon Lex removes the current contents of the statement. </p>
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expectedRevisionId" $expectedRevisionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/policy/($resourceArn)/statements/($statementId)/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified slot from an intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DeleteSlot
export def "bots-botversions-botlocales-intents-slots DeleteSlot" [
  slotId: string
  botId: string
  botVersion: string
  localeId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/slots/($slotId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets metadata information about a slot.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DescribeSlot
export def "bots-botversions-botlocales-intents-slots DescribeSlot" [
  slotId: string
  botId: string
  botVersion: string
  localeId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<slotId: record, slotName: record, description: record, slotTypeId: record, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: record>, slotConstraint: record, promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, sampleUtterances: record, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: record>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: record>, botId: record, botVersion: record, localeId: record, intentId: record, creationDateTime: record, lastUpdatedDateTime: record, multipleValuesSetting: record<allowMultipleValues: record>, subSlotSetting: record<expression: record, slotSpecifications: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/slots/($slotId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the settings for a slot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: UpdateSlot
# --valueElicitationSetting shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
# --obfuscationSetting shape: {obfuscationSettingType?: any}
# --multipleValuesSetting shape: {allowMultipleValues?: any}
# --subSlotSetting shape: {expression?: any, slotSpecifications?: any}
export def "bots-botversions-botlocales-intents-slots UpdateSlot" [
  slotId: string
  botId: string
  botVersion: string
  localeId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  slotName: string # The new name for the slot.
  --description: string # The new description for the slot.
  --slotTypeId: string # The unique identifier of the new slot type to associate with this slot. 
  valueElicitationSetting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
  --obfuscationSetting: record # Determines whether Amazon Lex obscures slot values in conversation logs.  — shape: {obfuscationSettingType?: any}
  --multipleValuesSetting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: any}
  --subSlotSetting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: any, slotSpecifications?: any}
]: any -> record<slotId: record, slotName: record, description: record, slotTypeId: record, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: record>, slotConstraint: record, promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, sampleUtterances: record, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: record>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: record>, botId: record, botVersion: record, localeId: record, intentId: record, creationDateTime: record, lastUpdatedDateTime: record, multipleValuesSetting: record<allowMultipleValues: record>, subSlotSetting: record<expression: record, slotSpecifications: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/intents/($intentId)/slots/($slotId)/")
  let body = {slotName: $slotName, description: $description, slotTypeId: $slotTypeId, valueElicitationSetting: $valueElicitationSetting, obfuscationSetting: $obfuscationSetting, multipleValuesSetting: $multipleValuesSetting, subSlotSetting: $subSlotSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes a slot type from a bot locale.</p> <p>If a slot is using the slot type, Amazon Lex throws a <code>ResourceInUseException</code> exception. To avoid the exception, set the <code>skipResourceInUseCheck</code> parameter to <code>true</code>.</p>
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DeleteSlotType
export def "bots-botversions-botlocales-slottypes DeleteSlotType" [
  slotTypeId: string
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skipResourceInUseCheck: oneof<nothing, bool> # By default, the <code>DeleteSlotType</code> operations throws a <code>ResourceInUseException</code> exception if you try to delete a slot type used by a slot. Set the <code>skipResourceInUseCheck</code> parameter to <code>true</code> to skip this check and remove the slot type even if a slot uses it.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skipResourceInUseCheck" $skipResourceInUseCheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/slottypes/($slotTypeId)/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets metadata information about a slot type.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DescribeSlotType
export def "bots-botversions-botlocales-slottypes DescribeSlotType" [
  slotTypeId: string
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<slotTypeId: record, slotTypeName: record, description: record, slotTypeValues: record, valueSelectionSetting: record<resolutionStrategy: record, regexFilter: record<pattern: record>, advancedRecognitionSetting: record<audioRecognitionStrategy: record>>, parentSlotTypeSignature: record, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/slottypes/($slotTypeId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the configuration of an existing slot type.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: UpdateSlotType
# --slotTypeValues item shape: {sampleValue?: any, synonyms?: any}
# --valueSelectionSetting shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
# --externalSourceSetting shape: {grammarSlotTypeSetting?: any}
# --compositeSlotTypeSetting shape: {subSlots?: any}
export def "bots-botversions-botlocales-slottypes UpdateSlotType" [
  slotTypeId: string
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  slotTypeName: string # The new name of the slot type.
  --description: string # The new description of the slot type.
  --slotTypeValues: list # A new list of values and their optional synonyms that define the values that the slot type can take. — item shape: {sampleValue?: any, synonyms?: any}
  --valueSelectionSetting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
  --parentSlotTypeSignature: string # The new built-in slot type that should be used as the parent of this slot type.
  --externalSourceSetting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: any}
  --compositeSlotTypeSetting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: any}
]: any -> record<slotTypeId: record, slotTypeName: record, description: record, slotTypeValues: record, valueSelectionSetting: record<resolutionStrategy: record, regexFilter: record<pattern: record>, advancedRecognitionSetting: record<audioRecognitionStrategy: record>>, parentSlotTypeSignature: record, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/slottypes/($slotTypeId)/")
  let body = {slotTypeName: $slotTypeName, description: $description, slotTypeValues: $slotTypeValues, valueSelectionSetting: $valueSelectionSetting, parentSlotTypeSignature: $parentSlotTypeSignature, externalSourceSetting: $externalSourceSetting, compositeSlotTypeSetting: $compositeSlotTypeSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_ListAggregatedUtterances.html">ListAggregatedUtterances</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input..</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete utterances for a specific session. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>ListAggregatedUtterances</code> operation are deleted after 15 days.</p>
#
# DELETE /bots/{botId}/utterances/
# operationId: DeleteUtterances
export def "bots-utterances DeleteUtterances" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --localeId: string # The identifier of the language and locale where the utterances were collected. The string must match one of the supported locales. For more information, see <a href="https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html">Supported languages</a>.
  --sessionId: string # The unique identifier of the session with the user. The ID is returned in the response from the <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_runtime_RecognizeText.html">RecognizeText</a> and <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_runtime_RecognizeUtterance.html">RecognizeUtterance</a> operations.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "localeId" $localeId "scalar") (serialize-qp "sessionId" $sessionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/utterances/" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides metadata information about a bot recommendation. This information will enable you to get a description on the request inputs, to download associated transcripts after processing is complete, and to download intents and slot-types generated by the bot recommendation.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# operationId: DescribeBotRecommendation
export def "bots-botversions-botlocales-botrecommendations DescribeBotRecommendation" [
  botId: string
  botVersion: string
  localeId: string
  botRecommendationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: record, pathFormat: record, transcriptFormat: record, transcriptFilter: record, kmsKeyArn: record>>, encryptionSetting: record<kmsKeyArn: record, botLocaleExportPassword: record, associatedTranscriptsPassword: record>, botRecommendationResults: record<botLocaleExportUrl: record, associatedTranscriptsUrl: record, statistics: record<intents: record, slotTypes: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/($botRecommendationId)/")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing bot recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# operationId: UpdateBotRecommendation
# --encryptionSetting shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
export def "bots-botversions-botlocales-botrecommendations UpdateBotRecommendation" [
  botId: string
  botVersion: string
  localeId: string
  botRecommendationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  encryptionSetting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record, creationDateTime: record, lastUpdatedDateTime: record, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: record, pathFormat: record, transcriptFormat: record, transcriptFilter: record, kmsKeyArn: record>>, encryptionSetting: record<kmsKeyArn: record, botLocaleExportPassword: record, associatedTranscriptsPassword: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/($botRecommendationId)/")
  let body = {encryptionSetting: $encryptionSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides metadata information about a custom vocabulary.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/metadata
# operationId: DescribeCustomVocabularyMetadata
export def "bots-botversions-botlocales-customvocabulary-default-metadata DescribeCustomVocabularyMetadata" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, customVocabularyStatus: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/customvocabulary/DEFAULT/metadata")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Provides a list of utterances that users have sent to the bot.</p> <p>Utterances are aggregated by the text of the utterance. For example, all instances where customers used the phrase "I want to order pizza" are aggregated into the same line in the response.</p> <p>You can see both detected utterances and missed utterances. A detected utterance is where the bot properly recognized the utterance and activated the associated intent. A missed utterance was not recognized by the bot and didn't activate an intent.</p> <p>Utterances can be aggregated for a bot alias or for a bot version, but not both at the same time.</p> <p>Utterances statistics are not generated under the following conditions:</p> <ul> <li> <p>The <code>childDirected</code> field was set to true when the bot was created.</p> </li> <li> <p>You are using slot obfuscation with one or more slots.</p> </li> <li> <p>You opted out of participating in improving Amazon Lex.</p> </li> </ul>
#
# POST /bots/{botId}/aggregatedutterances/
# operationId: ListAggregatedUtterances
# --aggregationDuration shape: {relativeAggregationDuration?: any}
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-aggregatedutterances ListAggregatedUtterances" [
  botId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --botAliasId: string # The identifier of the bot alias associated with this request. If you specify the bot alias, you can't specify the bot version.
  --botVersion: string # The identifier of the bot version associated with this request. If you specify the bot version, you can't specify the bot alias.
  localeId: string # The identifier of the language and locale where the utterances were collected. For more information, see <a href="https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html">Supported languages</a>.
  aggregationDuration: record # Provides parameters for setting the time window and duration for aggregating utterance data. — shape: {relativeAggregationDuration?: any}
  --sortBy: record # Specifies attributes for sorting a list of utterances. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the utterances in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of utterances to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. If you don't specify the <code>maxResults</code> parameter, 1,000 results are returned.
  --nextToken: string # If the response from the <code>ListAggregatedUtterances</code> operation contains more results that specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<botId: record, botAliasId: record, botVersion: record, localeId: record, aggregationDuration: record<relativeAggregationDuration: record<timeDimension: record, timeValue: record>>, aggregationWindowStartTime: record, aggregationWindowEndTime: record, aggregationLastRefreshedDateTime: record, aggregatedUtterancesSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/aggregatedutterances/" $qp)
  let body = {botAliasId: $botAliasId, botVersion: $botVersion, localeId: $localeId, aggregationDuration: $aggregationDuration, sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of bot recommendations that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# operationId: ListBotRecommendations
export def "bots-botversions-botlocales-botrecommendations ListBotRecommendations" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --maxResults: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the ListBotRecommendation operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results.
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/" $qp)
  let body = {maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use this to provide your transcript data, and to start the bot recommendation process.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# operationId: StartBotRecommendation
# --transcriptSourceSetting shape: {s3BucketTranscriptSource?: any}
# --encryptionSetting shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
export def "bots-botversions-botlocales-botrecommendations StartBotRecommendation" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  transcriptSourceSetting: record # Indicates the setting of the location where the transcript is stored. — shape: {s3BucketTranscriptSource?: any}
  --encryptionSetting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record, creationDateTime: record, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: record, pathFormat: record, transcriptFormat: record, transcriptFilter: record, kmsKeyArn: record>>, encryptionSetting: record<kmsKeyArn: record, botLocaleExportPassword: record, associatedTranscriptsPassword: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/")
  let body = {transcriptSourceSetting: $transcriptSourceSetting, encryptionSetting: $encryptionSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Gets a list of built-in intents provided by Amazon Lex that you can use in your bot. </p> <p>To use a built-in intent as a the base for your own intent, include the built-in intent signature in the <code>parentIntentSignature</code> parameter when you call the <code>CreateIntent</code> operation. For more information, see <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateIntent.html">CreateIntent</a>.</p>
#
# POST /builtins/locales/{localeId}/intents/
# operationId: ListBuiltInIntents
# --sortBy shape: {attribute?: any, order?: any}
export def "builtins-locales-intents ListBuiltInIntents" [
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of built-in intents. — shape: {attribute?: any, order?: any}
  --maxResults: int # The maximum number of built-in intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the <code>ListBuiltInIntents</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<builtInIntentSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/builtins/locales/($localeId)/intents/" $qp)
  let body = {sortBy: $sortBy, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of built-in slot types that meet the specified criteria.
#
# POST /builtins/locales/{localeId}/slottypes/
# operationId: ListBuiltInSlotTypes
# --sortBy shape: {attribute?: any, order?: any}
export def "builtins-locales-slottypes ListBuiltInSlotTypes" [
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --sortBy: record # Specifies attributes for sorting a list of built-in slot types. — shape: {attribute?: any, order?: any}
  --maxResults: int # The maximum number of built-in slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # If the response from the <code>ListBuiltInSlotTypes</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response. Use that token in the <code>nextToken</code> parameter to return the next page of results.
]: any -> record<builtInSlotTypeSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/builtins/locales/($localeId)/slottypes/" $qp)
  let body = {sortBy: $sortBy, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Paginated list of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/list
# operationId: ListCustomVocabularyItems
export def "bots-botversions-botlocales-customvocabulary-default-list ListCustomVocabularyItems" [
  botId: string
  botVersion: string
  localeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --maxResults: int # The maximum number of items returned by the list operation.
  --nextToken: string # The nextToken identifier to the list custom vocabulary request.
]: any -> record<botId: record, botVersion: record, localeId: record, customVocabularyItems: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/customvocabulary/DEFAULT/list" $qp)
  let body = {maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the imports for a bot, bot locale, or custom vocabulary. Imports are kept in the list for 7 days.
#
# POST /imports/
# operationId: ListImports
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "imports ListImports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --botId: string # The unique identifier that Amazon Lex assigned to the bot.
  --botVersion: string # The version of the bot to list imports for.
  --sortBy: record # Provides information for sorting a list of imports. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --maxResults: int # The maximum number of imports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextToken: string # <p>If the response from the <code>ListImports</code> operation contains more results than specified in the <code>maxResults</code> parameter, a token is returned in the response.</p> <p>Use the returned token in the <code>nextToken</code> parameter of a <code>ListImports</code> request to return the next page of results. For a complete set of results, call the <code>ListImports</code> operation until the <code>nextToken</code> returned in the response is null.</p>
  --localeId: string # Specifies the locale that should be present in the list. If you don't specify a resource type in the <code>filters</code> parameter, the list contains both bot locales and custom vocabularies.
]: any -> record<botId: record, botVersion: record, importSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/imports/" $qp)
  let body = {botId: $botId, botVersion: $botVersion, sortBy: $sortBy, filters: $filters, maxResults: $maxResults, nextToken: $nextToken, localeId: $localeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts importing a bot, bot locale, or custom vocabulary from a zip archive that you uploaded to an S3 bucket.
#
# PUT /imports/
# operationId: StartImport
# --resourceSpecification shape: {botImportSpecification?: any, botLocaleImportSpecification?: any, customVocabularyImportSpecification?: record}
export def "imports StartImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  importId: string # The unique identifier for the import. It is included in the response from the <a href="https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateUploadUrl.html">CreateUploadUrl</a> operation.
  resourceSpecification: record # Provides information about the bot or bot locale that you want to import. You can specify the <code>botImportSpecification</code> or the <code>botLocaleImportSpecification</code>, but not both. — shape: {botImportSpecification?: any, botLocaleImportSpecification?: any, customVocabularyImportSpecification?: record}
  mergeStrategy: string@mergeStrategy-completer # The strategy to use when there is a name conflict between the imported resource and an existing resource. When the merge strategy is <code>FailOnConflict</code> existing resources are not overwritten and the import fails.
  --filePassword: string # The password used to encrypt the zip archive that contains the resource definition. You should always encrypt the zip archive to protect it during transit between your site and Amazon Lex. (format: password)
]: any -> record<importId: record, resourceSpecification: record<botImportSpecification: record<botName: record, roleArn: record, dataPrivacy: record, idleSessionTTLInSeconds: record, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: record, botVersion: record, localeId: record, nluIntentConfidenceThreshold: record, voiceSettings: record>, customVocabularyImportSpecification: record<botId: record, botVersion: record, localeId: record>>, mergeStrategy: record, importStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/")
  let body = {importId: $importId, resourceSpecification: $resourceSpecification, mergeStrategy: $mergeStrategy, filePassword: $filePassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of recommended intents provided by the bot recommendation that you can use in your bot. Intents in the response are ordered by relevance.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/intents
# operationId: ListRecommendedIntents
export def "bots-botversions-botlocales-botrecommendations-intents ListRecommendedIntents" [
  botId: string
  botVersion: string
  localeId: string
  botRecommendationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --nextToken: string # If the response from the ListRecommendedIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results.
  --maxResults: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationId: record, summaryList: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/($botRecommendationId)/intents" $qp)
  let body = {nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of tags associated with a resource. Only bots, bot aliases, and bot channels can have tags associated with them.
#
# GET /tags/{resourceARN}
# operationId: ListTagsForResource
export def "tags ListTagsForResource" [
  resourceARN: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($resourceARN)")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds the specified tags to the specified resource. If a tag key already exists, the existing value is replaced with the new value.
#
# POST /tags/{resourceARN}
# operationId: TagResource
export def "tags TagResource" [
  resourceARN: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  tags: record # A list of tag keys to add to the resource. If a tag key already exists, the existing value is replaced with the new value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($resourceARN)")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for associated transcripts that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/associatedtranscripts
# operationId: SearchAssociatedTranscripts
# --filters item shape: {name: any, values: any}
export def "bots-botversions-botlocales-botrecommendations-associatedtranscripts SearchAssociatedTranscripts" [
  botId: string
  botVersion: string
  localeId: string
  botRecommendationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --searchOrder: string@searchOrder-completer # How SearchResults are ordered. Valid values are Ascending or Descending. The default is Descending.
  filters: list # A list of filter objects. — item shape: {name: any, values: any}
  --maxResults: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --nextIndex: int # If the response from the SearchAssociatedTranscriptsRequest operation contains more results than specified in the maxResults parameter, an index is returned in the response. Use that index in the nextIndex parameter to return the next page of results.
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationId: record, nextIndex: record, associatedTranscripts: record, totalResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/($botRecommendationId)/associatedtranscripts")
  let body = {searchOrder: $searchOrder, filters: $filters, maxResults: $maxResults, nextIndex: $nextIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stop an already running Bot Recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/stopbotrecommendation
# operationId: StopBotRecommendation
export def "bots-botversions-botlocales-botrecommendations-stopbotrecommendation StopBotRecommendation" [
  botId: string
  botVersion: string
  localeId: string
  botRecommendationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bots/($botId)/botversions/($botVersion)/botlocales/($localeId)/botrecommendations/($botRecommendationId)/stopbotrecommendation")
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes tags from a bot, bot alias, or bot channel.
#
# DELETE /tags/{resourceARN}#tagKeys
# operationId: UntagResource
export def "tags UntagResource" [
  resourceARN: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tagKeys: list # A list of tag keys to remove from the resource. If a tag key does not exist on the resource, it is ignored.
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tagKeys" $tagKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($resourceARN)#tagKeys" $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
