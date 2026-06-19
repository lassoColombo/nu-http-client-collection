# Auto-generated client for Amazon Lex Model Building V2 v2020-08-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/models.lex.v2/2020-08-07/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_MODEL_BUILDING_V2_TOKEN

const BASE_URL = "http://models-v2-lex.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LEX_MODEL_BUILDING_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://models-v2-lex.us-east-1.amazonaws.com" "http://models-v2-lex.us-east-2.amazonaws.com" "http://models-v2-lex.us-west-1.amazonaws.com" "http://models-v2-lex.us-west-2.amazonaws.com" "http://models-v2-lex.us-gov-west-1.amazonaws.com" "http://models-v2-lex.us-gov-east-1.amazonaws.com" "http://models-v2-lex.ca-central-1.amazonaws.com" "http://models-v2-lex.eu-north-1.amazonaws.com" "http://models-v2-lex.eu-west-1.amazonaws.com" "http://models-v2-lex.eu-west-2.amazonaws.com" "http://models-v2-lex.eu-west-3.amazonaws.com" "http://models-v2-lex.eu-central-1.amazonaws.com" "http://models-v2-lex.eu-south-1.amazonaws.com" "http://models-v2-lex.af-south-1.amazonaws.com" "http://models-v2-lex.ap-northeast-1.amazonaws.com" "http://models-v2-lex.ap-northeast-2.amazonaws.com" "http://models-v2-lex.ap-northeast-3.amazonaws.com" "http://models-v2-lex.ap-southeast-1.amazonaws.com" "http://models-v2-lex.ap-southeast-2.amazonaws.com" "http://models-v2-lex.ap-east-1.amazonaws.com" "http://models-v2-lex.ap-south-1.amazonaws.com" "http://models-v2-lex.sa-east-1.amazonaws.com" "http://models-v2-lex.me-south-1.amazonaws.com" "https://models-v2-lex.us-east-1.amazonaws.com" "https://models-v2-lex.us-east-2.amazonaws.com" "https://models-v2-lex.us-west-1.amazonaws.com" "https://models-v2-lex.us-west-2.amazonaws.com" "https://models-v2-lex.us-gov-west-1.amazonaws.com" "https://models-v2-lex.us-gov-east-1.amazonaws.com" "https://models-v2-lex.ca-central-1.amazonaws.com" "https://models-v2-lex.eu-north-1.amazonaws.com" "https://models-v2-lex.eu-west-1.amazonaws.com" "https://models-v2-lex.eu-west-2.amazonaws.com" "https://models-v2-lex.eu-west-3.amazonaws.com" "https://models-v2-lex.eu-central-1.amazonaws.com" "https://models-v2-lex.eu-south-1.amazonaws.com" "https://models-v2-lex.af-south-1.amazonaws.com" "https://models-v2-lex.ap-northeast-1.amazonaws.com" "https://models-v2-lex.ap-northeast-2.amazonaws.com" "https://models-v2-lex.ap-northeast-3.amazonaws.com" "https://models-v2-lex.ap-southeast-1.amazonaws.com" "https://models-v2-lex.ap-southeast-2.amazonaws.com" "https://models-v2-lex.ap-east-1.amazonaws.com" "https://models-v2-lex.ap-south-1.amazonaws.com" "https://models-v2-lex.sa-east-1.amazonaws.com" "https://models-v2-lex.me-south-1.amazonaws.com" "http://models-v2-lex.cn-north-1.amazonaws.com.cn" "http://models-v2-lex.cn-northwest-1.amazonaws.com.cn" "https://models-v2-lex.cn-north-1.amazonaws.com.cn" "https://models-v2-lex.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bot-type-completer [] { ["Bot" "BotNetwork"] }
def file-format-completer [] { ["LexJson" "TSV"] }
def effect-completer [] { ["Allow" "Deny"] }
def merge-strategy-completer [] { ["Append" "FailOnConflict" "Overwrite"] }
def search-order-completer [] { ["Ascending" "Descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bots-botversions-botlocales-customvocabulary-default-batchcreate create-batch-custom-vocabulary-item" } } | get name | first)
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
export def "bots-botversions-botlocales-customvocabulary-default-batchcreate create-batch-custom-vocabulary-item" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  custom_vocabulary_item_list: list # A list of new custom vocabulary items. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {phrase: any, weight?: any, displayAs?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, errors: record, resources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/batchcreate"))
  let req_body = {"customVocabularyItemList": $custom_vocabulary_item_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchdelete
# operationId: BatchDeleteCustomVocabularyItem
# --customVocabularyItemList item shape: {itemId: any}
export def "bots-botversions-botlocales-customvocabulary-default-batchdelete delete-batch-custom-vocabulary-item" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  custom_vocabulary_item_list: list # A list of custom vocabulary items requested to be deleted. Each entry must contain the unique custom vocabulary entry identifier. — item shape: {itemId: any}
]: any -> record<botId: record, botVersion: record, localeId: record, errors: record, resources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/batchdelete"))
  let req_body = {"customVocabularyItemList": $custom_vocabulary_item_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchupdate
# operationId: BatchUpdateCustomVocabularyItem
# --customVocabularyItemList item shape: {itemId: any, phrase: any, weight?: any, displayAs?: any}
export def "bots-botversions-botlocales-customvocabulary-default-batchupdate update-batch-custom-vocabulary-item" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  custom_vocabulary_item_list: list # A list of custom vocabulary items with updated fields. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {itemId: any, phrase: any, weight?: any, displayAs?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, errors: record, resources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/batchupdate"))
  let req_body = {"customVocabularyItemList": $custom_vocabulary_item_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Builds a bot, its intents, and its slot types into a specific locale. A bot can be built into multiple locales. At runtime the locale is used to choose a specific build of the bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: BuildBotLocale
export def "bots-botversions-botlocales build-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, botLocaleStatus: record, lastBuildSubmittedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes a locale from a bot. When you delete a locale, all intents, slots, and slot types defined for the locale are also deleted.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: DeleteBotLocale
export def "bots-botversions-botlocales delete-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, botLocaleStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Describes the settings that a bot has for a specific locale.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: DescribeBotLocale
export def "bots-botversions-botlocales get-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, localeName: record, description: record, nluIntentConfidenceThreshold: record, voiceSettings: record<voiceId: record, engine: record>, intentsCount: record, slotTypesCount: record, botLocaleStatus: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record, lastBuildSubmittedDateTime: record, botLocaleHistoryEvents: record, recommendedActions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the settings that a bot has for a specific locale.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: UpdateBotLocale
# --voiceSettings shape: {voiceId?: any, engine?: any}
export def "bots-botversions-botlocales update-locale" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  --description: string # The new description of the locale.
  nlu_intent_confidence_threshold: float # The new confidence threshold where Amazon Lex inserts the AMAZON.FallbackIntent and AMAZON.KendraSearchIntent intents in the list of possible intents for an utterance. (format: double)
  --voice-settings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: any, engine?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, localeName: record, description: record, nluIntentConfidenceThreshold: record, voiceSettings: record<voiceId: record, engine: record>, botLocaleStatus: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record, recommendedActions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/"))
  let req_body = {"description": $description, "nluIntentConfidenceThreshold": $nlu_intent_confidence_threshold, "voiceSettings": $voice_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates an Amazon Lex conversational bot.
#
# PUT /bots/
# operationId: CreateBot
# --dataPrivacy shape: {childDirected?: any}
# --botMembers item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
export def "bots create" [
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
  bot_name: string # The name of the bot. The bot name must be unique in the account that creates the bot.
  --description: string # A description of the bot. It appears in lists to help you identify a particular bot.
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role that has permission to access the bot.
  data_privacy: record # By default, data stored by Amazon Lex is encrypted. The DataPrivacy structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot. — shape: {childDirected?: any}
  idle_session_ttl_in_seconds: int # The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.
  --bot-tags: record # A list of tags to add to the bot. You can only add tags when you create a bot. You can't use the UpdateBot operation to update tags. To update tags, use the TagResource operation.
  --test-bot-alias-tags: record # A list of tags to add to the test alias for a bot. You can only add tags when you create a bot. You can't use the UpdateAlias operation to update tags. To update tags on the test alias, use the TagResource operation.
  --bot-type: string@bot-type-completer # The type of a bot to create.
  --bot-members: list # The list of bot members in a network to be created. — item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
]: any -> record<botId: record, botName: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, creationDateTime: record, botTags: record, testBotAliasTags: record, botType: record, botMembers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bots/")
  let req_body = {"botName": $bot_name, "description": $description, "roleArn": $role_arn, "dataPrivacy": $data_privacy, "idleSessionTTLInSeconds": $idle_session_ttl_in_seconds, "botTags": $bot_tags, "testBotAliasTags": $test_bot_alias_tags, "botType": $bot_type, "botMembers": $bot_members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of available bots.
#
# POST /bots/
# operationId: ListBots
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of bots to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListBots operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListBots request to return the next page of results. For a complete set of results, call the ListBots operation until the nextToken returned in the response is null. (body field)
]: any -> record<botSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bots/" $qp)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates an alias for the specified version of a bot. Use an alias to enable you to change the version of a bot without updating applications that use the bot. For example, you can create an alias called "PROD" that your applications use to call the Amazon Lex bot.
#
# PUT /bots/{botId}/botaliases/
# operationId: CreateBotAlias
# --conversationLogSettings shape: {textLogSettings?: any, audioLogSettings?: any}
# --sentimentAnalysisSettings shape: {detectSentiment?: any}
export def "bots-botaliases create-alias" [
  bot_id: string
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
  bot_alias_name: string # The alias to create. The name must be unique for the bot.
  --description: string # A description of the alias. Use this description to help identify the alias.
  --bot-version: string # The version of the bot that this alias points to. You can use the UpdateBotAlias (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_UpdateBotAlias.html) operation to change the bot version associated with the alias.
  --bot-alias-locale-settings: record # Maps configuration information to a specific locale. You can use this parameter to specify a specific Lambda function to run different functions in different locales.
  --conversation-log-settings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: any, audioLogSettings?: any}
  --sentiment-analysis-settings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: any}
  --tags: record # A list of tags to add to the bot alias. You can only add tags when you create an alias, you can't use the UpdateBotAlias operation to update the tags on a bot alias. To update tags, use the TagResource operation.
]: any -> record<botAliasId: record, botAliasName: record, description: record, botVersion: record, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: record, audioLogSettings: record>, sentimentAnalysisSettings: record<detectSentiment: record>, botAliasStatus: record, botId: record, creationDateTime: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botaliases/"))
  let req_body = {"botAliasName": $bot_alias_name, "description": $description, "botVersion": $bot_version, "botAliasLocaleSettings": $bot_alias_locale_settings, "conversationLogSettings": $conversation_log_settings, "sentimentAnalysisSettings": $sentiment_analysis_settings, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of aliases for the specified bot.
#
# POST /bots/{botId}/botaliases/
# operationId: ListBotAliases
export def "bots-botaliases list-aliases" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results-body: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListBotAliases operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<botAliasSummaries: record, nextToken: record, botId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botaliases/") $qp)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates a locale in the bot. The locale contains the intents and slot types that the bot uses in conversations with users in the specified language and locale. You must add a locale to a bot before you can add intents and slot types to the bot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/
# operationId: CreateBotLocale
# --voiceSettings shape: {voiceId?: any, engine?: any}
export def "bots-botversions-botlocales create-locale" [
  bot_id: string
  bot_version: string
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
  locale_id: string # The identifier of the language and locale that the bot will be used in. The string must match one of the supported locales. All of the intents, slot types, and slots used in the bot must have the same locale. For more information, see Supported languages (https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html).
  --description: string # A description of the bot locale. Use this to help identify the bot locale in lists.
  nlu_intent_confidence_threshold: float # Determines the threshold where Amazon Lex will insert the AMAZON.FallbackIntent, AMAZON.KendraSearchIntent, or both when returning alternative intents. AMAZON.FallbackIntent and AMAZON.KendraSearchIntent are only inserted if they are configured for the bot. For example, suppose a bot is configured with the confidence threshold of 0.80 and the AMAZON.FallbackIntent. Amazon Lex returns three alternative intents with the following confidence scores: IntentA (0.70), IntentB (0.60), IntentC (0.50). The response from the RecognizeText operation would be: AMAZON.FallbackIntent IntentA IntentB IntentC (format: double)
  --voice-settings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: any, engine?: any}
]: any -> record<botId: record, botVersion: record, localeName: record, localeId: record, description: record, nluIntentConfidenceThreshold: record, voiceSettings: record<voiceId: record, engine: record>, botLocaleStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/"))
  let req_body = {"localeId": $locale_id, "description": $description, "nluIntentConfidenceThreshold": $nlu_intent_confidence_threshold, "voiceSettings": $voice_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of locales for the specified bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/
# operationId: ListBotLocales
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales list-locales" [
  bot_id: string
  bot_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of bot locales. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification for a filter used to limit the response to only those locales that match the filter specification. You can only specify one filter and one value to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListBotLocales operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token as the nextToken parameter to return the next page of results. (body field)
]: any -> record<botId: record, botVersion: record, nextToken: record, botLocaleSummaries: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/") $qp)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates a new version of the bot based on the DRAFT version. If the DRAFT version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version, it returns the last created version. When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1.
#
# PUT /bots/{botId}/botversions/
# operationId: CreateBotVersion
export def "bots-botversions create-version" [
  bot_id: string
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
  --description: string # A description of the version. Use the description to help identify the version in lists.
  bot_version_locale_specification: record # Specifies the locales that Amazon Lex adds to this version. You can choose the Draft version or any other previously published version for each locale. When you specify a source version, the locale data is copied from the source version to the new version.
]: any -> record<botId: record, description: record, botVersion: record, botVersionLocaleSpecification: record, botStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botversions/"))
  let req_body = {"description": $description, "botVersionLocaleSpecification": $bot_version_locale_specification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about all of the versions of a bot. The ListBotVersions operation returns a summary of each version of a bot. For example, if a bot has three numbered versions, the ListBotVersions operation returns for summaries, one for each numbered version and one for the DRAFT version. The ListBotVersions operation always returns at least one version, the DRAFT version.
#
# POST /bots/{botId}/botversions/
# operationId: ListBotVersions
# --sortBy shape: {attribute?: any, order?: any}
export def "bots-botversions list-versions" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of bot versions. — shape: {attribute?: any, order?: any}
  --max-results-body: int # The maximum number of versions to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response to the ListBotVersion operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<botId: record, botVersionSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botversions/") $qp)
  let req_body = {"sortBy": $sort_by, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates a zip archive containing the contents of a bot or a bot locale. The archive contains a directory structure that contains JSON files that define the bot. You can create an archive that contains the complete definition of a bot, or you can specify that the archive contain only the definition of a single bot locale. For more information about exporting bots, and about the structure of the export archive, see Importing and exporting bots (https://docs.aws.amazon.com/lexv2/latest/dg/importing-exporting.html)
#
# PUT /exports/
# operationId: CreateExport
# --resourceSpecification shape: {botExportSpecification?: any, botLocaleExportSpecification?: any, customVocabularyExportSpecification?: any}
export def "exports create" [
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
  resource_specification: record # Provides information about the bot or bot locale that you want to export. You can specify the botExportSpecification or the botLocaleExportSpecification, but not both. — shape: {botExportSpecification?: any, botLocaleExportSpecification?: any, customVocabularyExportSpecification?: any}
  file_format: string@file-format-completer # The file format of the bot or bot locale definition files.
  --file-password: string # An password to use to encrypt the exported archive. Using a password is optional, but you should encrypt the archive to protect the data in transit between Amazon Lex and your local computer. (format: password)
]: any -> record<exportId: record, resourceSpecification: record<botExportSpecification: record<botId: record, botVersion: record>, botLocaleExportSpecification: record<botId: record, botVersion: record, localeId: record>, customVocabularyExportSpecification: record<botId: record, botVersion: record, localeId: record>>, fileFormat: record, exportStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exports/")
  let req_body = {"resourceSpecification": $resource_specification, "fileFormat": $file_format, "filePassword": $file_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the exports for a bot, bot locale, or custom vocabulary. Exports are kept in the list for 7 days.
#
# POST /exports/
# operationId: ListExports
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "exports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --bot-id: string # The unique identifier that Amazon Lex assigned to the bot.
  --bot-version: string # The version of the bot to list exports for.
  --sort-by: record # Provides information about sorting a list of exports. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the exports in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of exports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListExports operation contains more results that specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListExports request to return the next page of results. For a complete set of results, call the ListExports operation until the nextToken returned in the response is null. (body field)
  --locale-id: string # Specifies the resources that should be exported. If you don't specify a resource type in the filters parameter, both bot locales and custom vocabularies are exported.
]: any -> record<botId: record, botVersion: record, exportSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exports/" $qp)
  let req_body = {"botId": $bot_id, "botVersion": $bot_version, "sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body, "localeId": $locale_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates an intent. To define the interaction between the user and your bot, you define one or more intents. For example, for a pizza ordering bot you would create an OrderPizza intent. When you create an intent, you must provide a name. You can optionally provide the following: Sample utterances. For example, "I want to order a pizza" and "Can I order a pizza." You can't provide utterances for built-in intents. Information to be gathered. You specify slots for the information that you bot requests from the user. You can specify standard slot types, such as date and time, or custom slot types for your application. How the intent is fulfilled. You can provide a Lambda function or configure the intent to return the intent information to your client application. If you use a Lambda function, Amazon Lex invokes the function when all of the intent information is available. A confirmation prompt to send to the user to confirm an intent. For example, "Shall I order your pizza?" A conclusion statement to send to the user after the intent is fulfilled. For example, "I ordered your pizza." A follow-up prompt that asks the user for additional activity. For example, "Do you want a drink with your pizza?"
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
export def "bots-botversions-botlocales-intents create" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  intent_name: string # The name of the intent. Intent names must be unique in the locale that contains the intent and cannot match the name of any built-in intent.
  --description: string # A description of the intent. Use the description to help identify the intent in lists.
  --parent-intent-signature: string # A unique identifier for the built-in intent to base this intent on.
  --sample-utterances: list # An array of strings that a user might say to signal the intent. For example, "I want a pizza", or "I want a {PizzaSize} pizza". In an utterance, slot names are enclosed in curly braces ("{", "}") to indicate where they should be displayed in the utterance shown to the user.. — item shape: {utterance: any}
  --dialog-code-hook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: any}
  --fulfillment-code-hook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: any, postFulfillmentStatusSpecification?: any, fulfillmentUpdatesSpecification?: any, active?: any}
  --intent-confirmation-setting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: any, declinationResponse?: any, active?: any, confirmationResponse?: record, confirmationNextStep?: any, confirmationConditional?: any, declinationNextStep?: any, declinationConditional?: any, failureResponse?: record, failureNextStep?: any, failureConditional?: record, codeHook?: any, elicitationCodeHook?: any}
  --intent-closing-setting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: any, active?: any, nextStep?: any, conditional?: any}
  --input-contexts: list # A list of contexts that must be active for this intent to be considered by Amazon Lex. When an intent has an input context list, Amazon Lex only considers using the intent in an interaction with the user when the specified contexts are included in the active context list for the session. If the contexts are not active, then Amazon Lex will not use the intent. A context can be automatically activated using the outputContexts property or it can be set at runtime. For example, if there are two intents with different input contexts that respond to the same utterances, only the intent with the active context will respond. An intent may have up to 5 input contexts. If an intent has multiple input contexts, all of the contexts must be active to consider the intent. — item shape: {name: any}
  --output-contexts: list # A lists of contexts that the intent activates when it is fulfilled. You can use an output context to indicate the intents that Amazon Lex should consider for the next turn of the conversation with a customer. When you use the outputContextsList property, all of the contexts specified in the list are activated when the intent is fulfilled. You can set up to 10 output contexts. You can also set the number of conversation turns that the context should be active, or the length of time that the context should be active. — item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: any, queryFilterStringEnabled?: any, queryFilterString?: any}
  --initial-response-setting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: any, conditional?: record, codeHook?: record}
]: any -> record<intentId: record, intentName: record, description: record, parentIntentSignature: record, sampleUtterances: record, dialogCodeHook: record<enabled: record>, fulfillmentCodeHook: record<enabled: record, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: record, startResponse: record, updateResponse: record, timeoutInSeconds: record>, active: record>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: record, allowInterrupt: record>, active: record, confirmationResponse: record<messageGroups: record, allowInterrupt: record>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, failureResponse: record<messageGroups: record, allowInterrupt: record>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: record, invocationLabel: record>>, intentClosingSetting: record<closingResponse: record<messageGroups: record, allowInterrupt: record>, active: record, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>>, inputContexts: record, outputContexts: record, kendraConfiguration: record<kendraIndex: record, queryFilterStringEnabled: record, queryFilterString: record>, botId: record, botVersion: record, localeId: record, creationDateTime: record, initialResponseSetting: record<initialResponse: record<messageGroups: record, allowInterrupt: record>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/"))
  let req_body = {"intentName": $intent_name, "description": $description, "parentIntentSignature": $parent_intent_signature, "sampleUtterances": $sample_utterances, "dialogCodeHook": $dialog_code_hook, "fulfillmentCodeHook": $fulfillment_code_hook, "intentConfirmationSetting": $intent_confirmation_setting, "intentClosingSetting": $intent_closing_setting, "inputContexts": $input_contexts, "outputContexts": $output_contexts, "kendraConfiguration": $kendra_configuration, "initialResponseSetting": $initial_response_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of intents that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# operationId: ListIntents
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales-intents list" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of intents. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the intents in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListIntents request to return the next page of results. For a complete set of results, call the ListIntents operation until the nextToken returned in the response is null. (body field)
]: any -> record<botId: record, botVersion: record, localeId: record, intentSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/") $qp)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates a new resource policy with the specified policy statements.
#
# POST /policy/{resourceArn}/
# operationId: CreateResourcePolicy
export def "policy create-resource" [
  resource_arn: string
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
  policy: string # A resource policy to add to the resource. The policy is a JSON structure that contains one or more statements that define the policy. The policy must follow the IAM syntax. For more information about the contents of a JSON policy document, see IAM JSON policy reference (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html). If the policy isn't valid, Amazon Lex returns a validation exception.
]: any -> record<resourceArn: record, revisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/"))
  let req_body = {"policy": $policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes an existing policy from a bot or bot alias. If the resource doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/
# operationId: DeleteResourcePolicy
export def "policy delete-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision to edit. If this ID doesn't match the current revision number, Amazon Lex returns an exception If you don't specify a revision ID, Amazon Lex will delete the current policy.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expectedRevisionId": $expected_revision_id} | compact), body: null}
}

# Gets the resource policy and policy revision for a bot or bot alias.
#
# GET /policy/{resourceArn}/
# operationId: DescribeResourcePolicy
export def "policy get-resource" [
  resource_arn: string
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
]: nothing -> record<resourceArn: record, policy: record, revisionId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Replaces the existing resource policy for a bot or bot alias with a new one. If the policy doesn't exist, Amazon Lex returns an exception.
#
# PUT /policy/{resourceArn}/
# operationId: UpdateResourcePolicy
export def "policy update-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision of the policy to update. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception. If you don't specify a revision, Amazon Lex overwrites the contents of the policy with the new values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  policy: string # A resource policy to add to the resource. The policy is a JSON structure that contains one or more statements that define the policy. The policy must follow the IAM syntax. For more information about the contents of a JSON policy document, see IAM JSON policy reference (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html). If the policy isn't valid, Amazon Lex returns a validation exception.
]: any -> record<resourceArn: record, revisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/") $qp)
  let req_body = {"policy": $policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"expectedRevisionId": $expected_revision_id} | compact), body: $req_body}
}

# Adds a new resource policy statement to a bot or bot alias. If a resource policy exists, the statement is added to the current resource policy. If a policy doesn't exist, a new policy is created. You can't create a resource policy statement that allows cross-account access.
#
# POST /policy/{resourceArn}/statements/
# operationId: CreateResourcePolicyStatement
# --principal item shape: {service?: any, arn?: any}
export def "policy-statements create-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision of the policy to edit. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception. If you don't specify a revision, Amazon Lex overwrites the contents of the policy with the new values.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  statement_id: string # The name of the statement. The ID is the same as the Sid IAM property. The statement name must be unique within the policy. For more information, see IAM JSON policy elements: Sid (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_sid.html).
  effect: string@effect-completer # Determines whether the statement allows or denies access to the resource.
  principal: list # An IAM principal, such as an IAM users, IAM roles, or AWS services that is allowed or denied access to a resource. For more information, see AWS JSON policy elements: Principal (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html). — item shape: {service?: any, arn?: any}
  action: list<string> # The Amazon Lex action that this policy either allows or denies. The action must apply to the resource type of the specified ARN. For more information, see Actions, resources, and condition keys for Amazon Lex V2 (https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonlexv2.html).
  --condition: record # Specifies a condition when the policy is in effect. If the principal of the policy is a service principal, you must provide two condition blocks, one with a SourceAccount global condition key and one with a SourceArn global condition key. For more information, see IAM JSON policy elements: Condition (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html).
]: any -> record<resourceArn: record, revisionId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/statements/") $qp)
  let req_body = {"statementId": $statement_id, "effect": $effect, "principal": $principal, "action": $action, "condition": $condition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"expectedRevisionId": $expected_revision_id} | compact), body: $req_body}
}

# Creates a slot in an intent. A slot is a variable needed to fulfill an intent. For example, an OrderPizza intent might need slots for size, crust, and number of pizzas. For each slot, you define one or more utterances that Amazon Lex uses to elicit a response from the user.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# operationId: CreateSlot
# --valueElicitationSetting shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
# --obfuscationSetting shape: {obfuscationSettingType?: any}
# --multipleValuesSetting shape: {allowMultipleValues?: any}
# --subSlotSetting shape: {expression?: any, slotSpecifications?: any}
export def "bots-botversions-botlocales-intents-slots create" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
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
  slot_name: string # The name of the slot. Slot names must be unique within the bot that contains the slot.
  --description: string # A description of the slot. Use this to help identify the slot in lists.
  --slot-type-id: string # The unique identifier for the slot type associated with this slot. The slot type determines the values that can be entered into the slot.
  value_elicitation_setting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
  --obfuscation-setting: record # Determines whether Amazon Lex obscures slot values in conversation logs. — shape: {obfuscationSettingType?: any}
  --multiple-values-setting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: any}
  --sub-slot-setting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: any, slotSpecifications?: any}
]: any -> record<slotId: record, slotName: record, description: record, slotTypeId: record, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: record>, slotConstraint: record, promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, sampleUtterances: record, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: record>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: record>, botId: record, botVersion: record, localeId: record, intentId: record, creationDateTime: record, multipleValuesSetting: record<allowMultipleValues: record>, subSlotSetting: record<expression: record, slotSpecifications: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/"))
  let req_body = {"slotName": $slot_name, "description": $description, "slotTypeId": $slot_type_id, "valueElicitationSetting": $value_elicitation_setting, "obfuscationSetting": $obfuscation_setting, "multipleValuesSetting": $multiple_values_setting, "subSlotSetting": $sub_slot_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of slots that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# operationId: ListSlots
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales-intents-slots list" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the slots in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of slots to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListSlots operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<botId: record, botVersion: record, localeId: record, intentId: record, slotSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/") $qp)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Creates a custom slot type To create a custom slot type, specify a name for the slot type and a set of enumeration values, the values that a slot of this type can assume.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# operationId: CreateSlotType
# --slotTypeValues item shape: {sampleValue?: any, synonyms?: any}
# --valueSelectionSetting shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
# --externalSourceSetting shape: {grammarSlotTypeSetting?: any}
# --compositeSlotTypeSetting shape: {subSlots?: any}
export def "bots-botversions-botlocales-slottypes create-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  slot_type_name: string # The name for the slot. A slot type name must be unique within the account.
  --description: string # A description of the slot type. Use the description to help identify the slot type in lists.
  --slot-type-values: list # A list of SlotTypeValue objects that defines the values that the slot type can take. Each value can have a list of synonyms, additional values that help train the machine learning model about the values that it resolves for a slot. — item shape: {sampleValue?: any, synonyms?: any}
  --value-selection-setting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
  --parent-slot-type-signature: string # The built-in slot type used as a parent of this slot type. When you define a parent slot type, the new slot type has the configuration of the parent slot type. Only AMAZON.AlphaNumeric is supported.
  --external-source-setting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: any}
  --composite-slot-type-setting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: any}
]: any -> record<slotTypeId: record, slotTypeName: record, description: record, slotTypeValues: record, valueSelectionSetting: record<resolutionStrategy: record, regexFilter: record<pattern: record>, advancedRecognitionSetting: record<audioRecognitionStrategy: record>>, parentSlotTypeSignature: record, botId: record, botVersion: record, localeId: record, creationDateTime: record, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/"))
  let req_body = {"slotTypeName": $slot_type_name, "description": $description, "slotTypeValues": $slot_type_values, "valueSelectionSetting": $value_selection_setting, "parentSlotTypeSignature": $parent_slot_type_signature, "externalSourceSetting": $external_source_setting, "compositeSlotTypeSetting": $composite_slot_type_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of slot types that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# operationId: ListSlotTypes
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-botversions-botlocales-slottypes list-slot-types" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of slot types. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the slot types in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListSlotTypes operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<botId: record, botVersion: record, localeId: record, slotTypeSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/") $qp)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Gets a pre-signed S3 write URL that you use to upload the zip archive when importing a bot or a bot locale.
#
# POST /createuploadurl/
# operationId: CreateUploadUrl
export def "createuploadurl create-upload-url" [
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
]: nothing -> record<importId: record, uploadUrl: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createuploadurl/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes all versions of a bot, including the Draft version. To delete a specific version, use the DeleteBotVersion operation. When you delete a bot, all of the resources contained in the bot are also deleted. Deleting a bot removes all locales, intents, slot, and slot types defined for the bot. If a bot has an alias, the DeleteBot operation returns a ResourceInUseException exception. If you want to delete the bot and the alias, set the skipResourceInUseCheck parameter to true.
#
# DELETE /bots/{botId}/
# operationId: DeleteBot
export def "bots delete" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as an alias or bot network, is using the bot version before it is deleted and throws a ResourceInUseException exception if the bot is being used by another resource. Set this parameter to true to skip this check and remove the bot even if it is being used by another resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<botId: record, botStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact), body: null}
}

# Provides metadata information about a bot.
#
# GET /bots/{botId}/
# operationId: DescribeBot
export def "bots get" [
  bot_id: string
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
]: nothing -> record<botId: record, botName: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, creationDateTime: record, lastUpdatedDateTime: record, botType: record, botMembers: record, failureReasons: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration of an existing bot.
#
# PUT /bots/{botId}/
# operationId: UpdateBot
# --dataPrivacy shape: {childDirected?: any}
# --botMembers item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
export def "bots update" [
  bot_id: string
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
  bot_name: string # The new name of the bot. The name must be unique in the account that creates the bot.
  --description: string # A description of the bot.
  role_arn: string # The Amazon Resource Name (ARN) of an IAM role that has permissions to access the bot.
  data_privacy: record # By default, data stored by Amazon Lex is encrypted. The DataPrivacy structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot. — shape: {childDirected?: any}
  idle_session_ttl_in_seconds: int # The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.
  --bot-type: string@bot-type-completer # The type of the bot to be updated.
  --bot-members: list # The list of bot members in the network associated with the update action. — item shape: {botMemberId: any, botMemberName: any, botMemberAliasId: any, botMemberAliasName: any, botMemberVersion: any}
]: any -> record<botId: record, botName: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, creationDateTime: record, lastUpdatedDateTime: record, botType: record, botMembers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/"))
  let req_body = {"botName": $bot_name, "description": $description, "roleArn": $role_arn, "dataPrivacy": $data_privacy, "idleSessionTTLInSeconds": $idle_session_ttl_in_seconds, "botType": $bot_type, "botMembers": $bot_members} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the specified bot alias.
#
# DELETE /bots/{botId}/botaliases/{botAliasId}/
# operationId: DeleteBotAlias
export def "bots-botaliases delete-alias" [
  bot_id: string
  bot_alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as a bot network, is using the bot alias before it is deleted and throws a ResourceInUseException exception if the alias is being used by another resource. Set this parameter to true to skip this check and remove the alias even if it is being used by another resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<botAliasId: record, botId: record, botAliasStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id)} | format pattern "/bots/{bot_id}/botaliases/{bot_alias_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact), body: null}
}

# Get information about a specific bot alias.
#
# GET /bots/{botId}/botaliases/{botAliasId}/
# operationId: DescribeBotAlias
export def "bots-botaliases get-alias" [
  bot_id: string
  bot_alias_id: string
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
]: nothing -> record<botAliasId: record, botAliasName: record, description: record, botVersion: record, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: record, audioLogSettings: record>, sentimentAnalysisSettings: record<detectSentiment: record>, botAliasHistoryEvents: record, botAliasStatus: record, botId: record, creationDateTime: record, lastUpdatedDateTime: record, parentBotNetworks: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id)} | format pattern "/bots/{bot_id}/botaliases/{bot_alias_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration of an existing bot alias.
#
# PUT /bots/{botId}/botaliases/{botAliasId}/
# operationId: UpdateBotAlias
# --conversationLogSettings shape: {textLogSettings?: any, audioLogSettings?: any}
# --sentimentAnalysisSettings shape: {detectSentiment?: any}
export def "bots-botaliases update-alias" [
  bot_id: string
  bot_alias_id: string
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
  bot_alias_name: string # The new name to assign to the bot alias.
  --description: string # The new description to assign to the bot alias.
  --bot-version: string # The new bot version to assign to the bot alias.
  --bot-alias-locale-settings: record # The new Lambda functions to use in each locale for the bot alias.
  --conversation-log-settings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: any, audioLogSettings?: any}
  --sentiment-analysis-settings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: any}
]: any -> record<botAliasId: record, botAliasName: record, description: record, botVersion: record, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: record, audioLogSettings: record>, sentimentAnalysisSettings: record<detectSentiment: record>, botAliasStatus: record, botId: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id)} | format pattern "/bots/{bot_id}/botaliases/{bot_alias_id}/"))
  let req_body = {"botAliasName": $bot_alias_name, "description": $description, "botVersion": $bot_version, "botAliasLocaleSettings": $bot_alias_locale_settings, "conversationLogSettings": $conversation_log_settings, "sentimentAnalysisSettings": $sentiment_analysis_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a specific version of a bot. To delete all versions of a bot, use the DeleteBot (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DeleteBot.html) operation.
#
# DELETE /bots/{botId}/botversions/{botVersion}/
# operationId: DeleteBotVersion
export def "bots-botversions delete-version" [
  bot_id: string
  bot_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, Amazon Lex checks if any other resource, such as an alias or bot network, is using the bot version before it is deleted and throws a ResourceInUseException exception if the version is being used by another resource. Set this parameter to true to skip this check and remove the version even if it is being used by another resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<botId: record, botVersion: record, botStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact), body: null}
}

# Provides metadata about a version of a bot.
#
# GET /bots/{botId}/botversions/{botVersion}/
# operationId: DescribeBotVersion
export def "bots-botversions get-version" [
  bot_id: string
  bot_version: string
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
]: nothing -> record<botId: record, botName: record, botVersion: record, description: record, roleArn: record, dataPrivacy: record<childDirected: record>, idleSessionTTLInSeconds: record, botStatus: record, failureReasons: record, creationDateTime: record, parentBotNetworks: record, botType: record, botMembers: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes a custom vocabulary from the specified locale in the specified bot.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary
# operationId: DeleteCustomVocabulary
export def "bots-botversions-botlocales-customvocabulary delete-custom-vocabulary" [
  bot_id: string
  bot_version: string
  locale_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, customVocabularyStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes a previous export and the associated files stored in an S3 bucket.
#
# DELETE /exports/{exportId}/
# operationId: DeleteExport
export def "exports delete" [
  export_id: string
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
]: nothing -> record<exportId: record, exportStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/exports/{export_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about a specific export.
#
# GET /exports/{exportId}/
# operationId: DescribeExport
export def "exports get" [
  export_id: string
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
]: nothing -> record<exportId: record, resourceSpecification: record<botExportSpecification: record<botId: record, botVersion: record>, botLocaleExportSpecification: record<botId: record, botVersion: record, localeId: record>, customVocabularyExportSpecification: record<botId: record, botVersion: record, localeId: record>>, fileFormat: record, exportStatus: record, failureReasons: record, downloadUrl: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/exports/{export_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the password used to protect an export zip archive. The password is not required. If you don't supply a password, Amazon Lex generates a zip file that is not protected by a password. This is the archive that is available at the pre-signed S3 URL provided by the DescribeExport (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DescribeExport.html) operation.
#
# PUT /exports/{exportId}/
# operationId: UpdateExport
export def "exports update" [
  export_id: string
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
  --file-password: string # The new password to use to encrypt the export zip archive. (format: password)
]: any -> record<exportId: record, resourceSpecification: record<botExportSpecification: record<botId: record, botVersion: record>, botLocaleExportSpecification: record<botId: record, botVersion: record, localeId: record>, customVocabularyExportSpecification: record<botId: record, botVersion: record, localeId: record>>, fileFormat: record, exportStatus: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/exports/{export_id}/"))
  let req_body = {"filePassword": $file_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes a previous import and the associated file stored in an S3 bucket.
#
# DELETE /imports/{importId}/
# operationId: DeleteImport
export def "imports delete" [
  import_id: string
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
]: nothing -> record<importId: record, importStatus: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($import_id | is-empty) { error make --unspanned { msg: "path parameter 'importId' must be non-empty" } }
  let full_url = (build-url $base ({import_id: (encode-path-segment $import_id)} | format pattern "/imports/{import_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about a specific import.
#
# GET /imports/{importId}/
# operationId: DescribeImport
export def "imports get" [
  import_id: string
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
]: nothing -> record<importId: record, resourceSpecification: record<botImportSpecification: record<botName: record, roleArn: record, dataPrivacy: record, idleSessionTTLInSeconds: record, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: record, botVersion: record, localeId: record, nluIntentConfidenceThreshold: record, voiceSettings: record>, customVocabularyImportSpecification: record<botId: record, botVersion: record, localeId: record>>, importedResourceId: record, importedResourceName: record, mergeStrategy: record, importStatus: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($import_id | is-empty) { error make --unspanned { msg: "path parameter 'importId' must be non-empty" } }
  let full_url = (build-url $base ({import_id: (encode-path-segment $import_id)} | format pattern "/imports/{import_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes the specified intent. Deleting an intent also deletes the slots associated with the intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DeleteIntent
export def "bots-botversions-botlocales-intents delete" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns metadata about an intent.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DescribeIntent
export def "bots-botversions-botlocales-intents get" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
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
]: nothing -> record<intentId: record, intentName: record, description: record, parentIntentSignature: record, sampleUtterances: record, dialogCodeHook: record<enabled: record>, fulfillmentCodeHook: record<enabled: record, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: record, startResponse: record, updateResponse: record, timeoutInSeconds: record>, active: record>, slotPriorities: record, intentConfirmationSetting: record<promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: record, allowInterrupt: record>, active: record, confirmationResponse: record<messageGroups: record, allowInterrupt: record>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, failureResponse: record<messageGroups: record, allowInterrupt: record>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: record, invocationLabel: record>>, intentClosingSetting: record<closingResponse: record<messageGroups: record, allowInterrupt: record>, active: record, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>>, inputContexts: record, outputContexts: record, kendraConfiguration: record<kendraIndex: record, queryFilterStringEnabled: record, queryFilterString: record>, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, initialResponseSetting: record<initialResponse: record<messageGroups: record, allowInterrupt: record>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
export def "bots-botversions-botlocales-intents update" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
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
  intent_name: string # The new name for the intent.
  --description: string # The new description of the intent.
  --parent-intent-signature: string # The signature of the new built-in intent to use as the parent of this intent.
  --sample-utterances: list # New utterances used to invoke the intent. — item shape: {utterance: any}
  --dialog-code-hook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: any}
  --fulfillment-code-hook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: any, postFulfillmentStatusSpecification?: any, fulfillmentUpdatesSpecification?: any, active?: any}
  --slot-priorities: list # A new list of slots and their priorities that are contained by the intent. — item shape: {priority: any, slotId: any}
  --intent-confirmation-setting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: any, declinationResponse?: any, active?: any, confirmationResponse?: record, confirmationNextStep?: any, confirmationConditional?: any, declinationNextStep?: any, declinationConditional?: any, failureResponse?: record, failureNextStep?: any, failureConditional?: record, codeHook?: any, elicitationCodeHook?: any}
  --intent-closing-setting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: any, active?: any, nextStep?: any, conditional?: any}
  --input-contexts: list # A new list of contexts that must be active in order for Amazon Lex to consider the intent. — item shape: {name: any}
  --output-contexts: list # A new list of contexts that Amazon Lex activates when the intent is fulfilled. — item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: any, queryFilterStringEnabled?: any, queryFilterString?: any}
  --initial-response-setting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: any, conditional?: record, codeHook?: record}
]: any -> record<intentId: record, intentName: record, description: record, parentIntentSignature: record, sampleUtterances: record, dialogCodeHook: record<enabled: record>, fulfillmentCodeHook: record<enabled: record, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: record, startResponse: record, updateResponse: record, timeoutInSeconds: record>, active: record>, slotPriorities: record, intentConfirmationSetting: record<promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: record, allowInterrupt: record>, active: record, confirmationResponse: record<messageGroups: record, allowInterrupt: record>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, failureResponse: record<messageGroups: record, allowInterrupt: record>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: record, invocationLabel: record>>, intentClosingSetting: record<closingResponse: record<messageGroups: record, allowInterrupt: record>, active: record, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>>, inputContexts: record, outputContexts: record, kendraConfiguration: record<kendraIndex: record, queryFilterStringEnabled: record, queryFilterString: record>, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, initialResponseSetting: record<initialResponse: record<messageGroups: record, allowInterrupt: record>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: record, conditionalBranches: record, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: record, active: record, invocationLabel: record, postCodeHookSpecification: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/"))
  let req_body = {"intentName": $intent_name, "description": $description, "parentIntentSignature": $parent_intent_signature, "sampleUtterances": $sample_utterances, "dialogCodeHook": $dialog_code_hook, "fulfillmentCodeHook": $fulfillment_code_hook, "slotPriorities": $slot_priorities, "intentConfirmationSetting": $intent_confirmation_setting, "intentClosingSetting": $intent_closing_setting, "inputContexts": $input_contexts, "outputContexts": $output_contexts, "kendraConfiguration": $kendra_configuration, "initialResponseSetting": $initial_response_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a policy statement from a resource policy. If you delete the last statement from a policy, the policy is deleted. If you specify a statement ID that doesn't exist in the policy, or if the bot or bot alias doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/statements/{statementId}/
# operationId: DeleteResourcePolicyStatement
export def "policy-statements delete-resource" [
  resource_arn: string
  statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expected-revision-id: string # The identifier of the revision of the policy to delete the statement from. If this revision ID doesn't match the current revision ID, Amazon Lex throws an exception. If you don't specify a revision, Amazon Lex removes the current contents of the statement.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'statementId' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn), statement_id: (encode-path-segment $statement_id)} | format pattern "/policy/{resource_arn}/statements/{statement_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expectedRevisionId": $expected_revision_id} | compact), body: null}
}

# Deletes the specified slot from an intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DeleteSlot
export def "bots-botversions-botlocales-intents-slots delete" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  slot_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  if ($slot_id | is-empty) { error make --unspanned { msg: "path parameter 'slotId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id), slot_id: (encode-path-segment $slot_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/{slot_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets metadata information about a slot.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DescribeSlot
export def "bots-botversions-botlocales-intents-slots get" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  slot_id: string
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
]: nothing -> record<slotId: record, slotName: record, description: record, slotTypeId: record, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: record>, slotConstraint: record, promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, sampleUtterances: record, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: record>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: record>, botId: record, botVersion: record, localeId: record, intentId: record, creationDateTime: record, lastUpdatedDateTime: record, multipleValuesSetting: record<allowMultipleValues: record>, subSlotSetting: record<expression: record, slotSpecifications: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  if ($slot_id | is-empty) { error make --unspanned { msg: "path parameter 'slotId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id), slot_id: (encode-path-segment $slot_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/{slot_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the settings for a slot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: UpdateSlot
# --valueElicitationSetting shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
# --obfuscationSetting shape: {obfuscationSettingType?: any}
# --multipleValuesSetting shape: {allowMultipleValues?: any}
# --subSlotSetting shape: {expression?: any, slotSpecifications?: any}
export def "bots-botversions-botlocales-intents-slots update" [
  bot_id: string
  bot_version: string
  locale_id: string
  intent_id: string
  slot_id: string
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
  slot_name: string # The new name for the slot.
  --description: string # The new description for the slot.
  --slot-type-id: string # The unique identifier of the new slot type to associate with this slot.
  value_elicitation_setting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: any, slotConstraint?: any, promptSpecification?: any, sampleUtterances?: any, waitAndContinueSpecification?: record, slotCaptureSetting?: any}
  --obfuscation-setting: record # Determines whether Amazon Lex obscures slot values in conversation logs. — shape: {obfuscationSettingType?: any}
  --multiple-values-setting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: any}
  --sub-slot-setting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: any, slotSpecifications?: any}
]: any -> record<slotId: record, slotName: record, description: record, slotTypeId: record, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: record>, slotConstraint: record, promptSpecification: record<messageGroups: record, maxRetries: record, allowInterrupt: record, messageSelectionStrategy: record, promptAttemptsSpecification: record>, sampleUtterances: record, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: record>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: record>, botId: record, botVersion: record, localeId: record, intentId: record, creationDateTime: record, lastUpdatedDateTime: record, multipleValuesSetting: record<allowMultipleValues: record>, subSlotSetting: record<expression: record, slotSpecifications: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  if ($slot_id | is-empty) { error make --unspanned { msg: "path parameter 'slotId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id), slot_id: (encode-path-segment $slot_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/{slot_id}/"))
  let req_body = {"slotName": $slot_name, "description": $description, "slotTypeId": $slot_type_id, "valueElicitationSetting": $value_elicitation_setting, "obfuscationSetting": $obfuscation_setting, "multipleValuesSetting": $multiple_values_setting, "subSlotSetting": $sub_slot_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a slot type from a bot locale. If a slot is using the slot type, Amazon Lex throws a ResourceInUseException exception. To avoid the exception, set the skipResourceInUseCheck parameter to true.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DeleteSlotType
export def "bots-botversions-botlocales-slottypes delete-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  slot_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-resource-in-use-check: oneof<nothing, bool> # By default, the DeleteSlotType operations throws a ResourceInUseException exception if you try to delete a slot type used by a slot. Set the skipResourceInUseCheck parameter to true to skip this check and remove the slot type even if a slot uses it.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($slot_type_id | is-empty) { error make --unspanned { msg: "path parameter 'slotTypeId' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), slot_type_id: (encode-path-segment $slot_type_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/{slot_type_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact), body: null}
}

# Gets metadata information about a slot type.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DescribeSlotType
export def "bots-botversions-botlocales-slottypes get-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  slot_type_id: string
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
]: nothing -> record<slotTypeId: record, slotTypeName: record, description: record, slotTypeValues: record, valueSelectionSetting: record<resolutionStrategy: record, regexFilter: record<pattern: record>, advancedRecognitionSetting: record<audioRecognitionStrategy: record>>, parentSlotTypeSignature: record, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($slot_type_id | is-empty) { error make --unspanned { msg: "path parameter 'slotTypeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), slot_type_id: (encode-path-segment $slot_type_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/{slot_type_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the configuration of an existing slot type.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: UpdateSlotType
# --slotTypeValues item shape: {sampleValue?: any, synonyms?: any}
# --valueSelectionSetting shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
# --externalSourceSetting shape: {grammarSlotTypeSetting?: any}
# --compositeSlotTypeSetting shape: {subSlots?: any}
export def "bots-botversions-botlocales-slottypes update-slot-type" [
  bot_id: string
  bot_version: string
  locale_id: string
  slot_type_id: string
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
  slot_type_name: string # The new name of the slot type.
  --description: string # The new description of the slot type.
  --slot-type-values: list # A new list of values and their optional synonyms that define the values that the slot type can take. — item shape: {sampleValue?: any, synonyms?: any}
  --value-selection-setting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: any, regexFilter?: any, advancedRecognitionSetting?: any}
  --parent-slot-type-signature: string # The new built-in slot type that should be used as the parent of this slot type.
  --external-source-setting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: any}
  --composite-slot-type-setting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: any}
]: any -> record<slotTypeId: record, slotTypeName: record, description: record, slotTypeValues: record, valueSelectionSetting: record<resolutionStrategy: record, regexFilter: record<pattern: record>, advancedRecognitionSetting: record<audioRecognitionStrategy: record>>, parentSlotTypeSignature: record, botId: record, botVersion: record, localeId: record, creationDateTime: record, lastUpdatedDateTime: record, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($slot_type_id | is-empty) { error make --unspanned { msg: "path parameter 'slotTypeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), slot_type_id: (encode-path-segment $slot_type_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/{slot_type_id}/"))
  let req_body = {"slotTypeName": $slot_type_name, "description": $description, "slotTypeValues": $slot_type_values, "valueSelectionSetting": $value_selection_setting, "parentSlotTypeSignature": $parent_slot_type_signature, "externalSourceSetting": $external_source_setting, "compositeSlotTypeSetting": $composite_slot_type_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes stored utterances. Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the ListAggregatedUtterances (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_ListAggregatedUtterances.html) operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.. Use the DeleteUtterances operation to manually delete utterances for a specific session. When you use the DeleteUtterances operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the ListAggregatedUtterances operation are deleted after 15 days.
#
# DELETE /bots/{botId}/utterances/
# operationId: DeleteUtterances
export def "bots-utterances delete" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-id: string # The identifier of the language and locale where the utterances were collected. The string must match one of the supported locales. For more information, see Supported languages (https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html).
  --session-id: string # The unique identifier of the session with the user. The ID is returned in the response from the RecognizeText (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_runtime_RecognizeText.html) and RecognizeUtterance (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_runtime_RecognizeUtterance.html) operations.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "localeId" $locale_id "scalar") (serialize-qp "sessionId" $session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/utterances/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"localeId": $locale_id, "sessionId": $session_id} | compact), body: null}
}

# Provides metadata information about a bot recommendation. This information will enable you to get a description on the request inputs, to download associated transcripts after processing is complete, and to download intents and slot-types generated by the bot recommendation.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# operationId: DescribeBotRecommendation
export def "bots-botversions-botlocales-botrecommendations get-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record, failureReasons: record, creationDateTime: record, lastUpdatedDateTime: record, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: record, pathFormat: record, transcriptFormat: record, transcriptFilter: record, kmsKeyArn: record>>, encryptionSetting: record<kmsKeyArn: record, botLocaleExportPassword: record, associatedTranscriptsPassword: record>, botRecommendationResults: record<botLocaleExportUrl: record, associatedTranscriptsUrl: record, statistics: record<intents: record, slotTypes: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing bot recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# operationId: UpdateBotRecommendation
# --encryptionSetting shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
export def "bots-botversions-botlocales-botrecommendations update-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
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
  encryption_setting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record, creationDateTime: record, lastUpdatedDateTime: record, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: record, pathFormat: record, transcriptFormat: record, transcriptFilter: record, kmsKeyArn: record>>, encryptionSetting: record<kmsKeyArn: record, botLocaleExportPassword: record, associatedTranscriptsPassword: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/"))
  let req_body = {"encryptionSetting": $encryption_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Provides metadata information about a custom vocabulary.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/metadata
# operationId: DescribeCustomVocabularyMetadata
export def "bots-botversions-botlocales-customvocabulary-default-metadata get-custom-vocabulary" [
  bot_id: string
  bot_version: string
  locale_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, customVocabularyStatus: record, creationDateTime: record, lastUpdatedDateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Provides a list of utterances that users have sent to the bot. Utterances are aggregated by the text of the utterance. For example, all instances where customers used the phrase "I want to order pizza" are aggregated into the same line in the response. You can see both detected utterances and missed utterances. A detected utterance is where the bot properly recognized the utterance and activated the associated intent. A missed utterance was not recognized by the bot and didn't activate an intent. Utterances can be aggregated for a bot alias or for a bot version, but not both at the same time. Utterances statistics are not generated under the following conditions: The childDirected field was set to true when the bot was created. You are using slot obfuscation with one or more slots. You opted out of participating in improving Amazon Lex.
#
# POST /bots/{botId}/aggregatedutterances/
# operationId: ListAggregatedUtterances
# --aggregationDuration shape: {relativeAggregationDuration?: any}
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "bots-aggregatedutterances list-aggregated-utterances" [
  bot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --bot-alias-id: string # The identifier of the bot alias associated with this request. If you specify the bot alias, you can't specify the bot version.
  --bot-version: string # The identifier of the bot version associated with this request. If you specify the bot version, you can't specify the bot alias.
  locale_id: string # The identifier of the language and locale where the utterances were collected. For more information, see Supported languages (https://docs.aws.amazon.com/lexv2/latest/dg/how-languages.html).
  aggregation_duration: record # Provides parameters for setting the time window and duration for aggregating utterance data. — shape: {relativeAggregationDuration?: any}
  --sort-by: record # Specifies attributes for sorting a list of utterances. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the utterances in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of utterances to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. If you don't specify the maxResults parameter, 1,000 results are returned. (body field)
  --next-token-body: string # If the response from the ListAggregatedUtterances operation contains more results that specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<botId: record, botAliasId: record, botVersion: record, localeId: record, aggregationDuration: record<relativeAggregationDuration: record<timeDimension: record, timeValue: record>>, aggregationWindowStartTime: record, aggregationWindowEndTime: record, aggregationLastRefreshedDateTime: record, aggregatedUtterancesSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/aggregatedutterances/") $qp)
  let req_body = {"botAliasId": $bot_alias_id, "botVersion": $bot_version, "localeId": $locale_id, "aggregationDuration": $aggregation_duration, "sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Get a list of bot recommendations that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# operationId: ListBotRecommendations
export def "bots-botversions-botlocales-botrecommendations list-recommendations" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results-body: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListBotRecommendation operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationSummaries: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/") $qp)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Use this to provide your transcript data, and to start the bot recommendation process.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# operationId: StartBotRecommendation
# --transcriptSourceSetting shape: {s3BucketTranscriptSource?: any}
# --encryptionSetting shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
export def "bots-botversions-botlocales-botrecommendations start-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
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
  transcript_source_setting: record # Indicates the setting of the location where the transcript is stored. — shape: {s3BucketTranscriptSource?: any}
  --encryption-setting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: any, botLocaleExportPassword?: any, associatedTranscriptsPassword?: any}
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record, creationDateTime: record, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: record, pathFormat: record, transcriptFormat: record, transcriptFilter: record, kmsKeyArn: record>>, encryptionSetting: record<kmsKeyArn: record, botLocaleExportPassword: record, associatedTranscriptsPassword: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/"))
  let req_body = {"transcriptSourceSetting": $transcript_source_setting, "encryptionSetting": $encryption_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of built-in intents provided by Amazon Lex that you can use in your bot. To use a built-in intent as a the base for your own intent, include the built-in intent signature in the parentIntentSignature parameter when you call the CreateIntent operation. For more information, see CreateIntent (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateIntent.html).
#
# POST /builtins/locales/{localeId}/intents/
# operationId: ListBuiltInIntents
# --sortBy shape: {attribute?: any, order?: any}
export def "builtins-locales-intents list-built" [
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of built-in intents. — shape: {attribute?: any, order?: any}
  --max-results-body: int # The maximum number of built-in intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListBuiltInIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<builtInIntentSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/builtins/locales/{locale_id}/intents/") $qp)
  let req_body = {"sortBy": $sort_by, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Gets a list of built-in slot types that meet the specified criteria.
#
# POST /builtins/locales/{localeId}/slottypes/
# operationId: ListBuiltInSlotTypes
# --sortBy shape: {attribute?: any, order?: any}
export def "builtins-locales-slottypes list-built-in-slot-types" [
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --sort-by: record # Specifies attributes for sorting a list of built-in slot types. — shape: {attribute?: any, order?: any}
  --max-results-body: int # The maximum number of built-in slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListBuiltInSlotTypes operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
]: any -> record<builtInSlotTypeSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/builtins/locales/{locale_id}/slottypes/") $qp)
  let req_body = {"sortBy": $sort_by, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Paginated list of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/list
# operationId: ListCustomVocabularyItems
export def "bots-botversions-botlocales-customvocabulary-default-list list-custom-vocabulary-items" [
  bot_id: string
  bot_version: string
  locale_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --max-results-body: int # The maximum number of items returned by the list operation. (body field)
  --next-token-body: string # The nextToken identifier to the list custom vocabulary request. (body field)
]: any -> record<botId: record, botVersion: record, localeId: record, customVocabularyItems: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/list") $qp)
  let req_body = {"maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Lists the imports for a bot, bot locale, or custom vocabulary. Imports are kept in the list for 7 days.
#
# POST /imports/
# operationId: ListImports
# --sortBy shape: {attribute?: any, order?: any}
# --filters item shape: {name: any, values: any, operator: any}
export def "imports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --bot-id: string # The unique identifier that Amazon Lex assigned to the bot.
  --bot-version: string # The version of the bot to list imports for.
  --sort-by: record # Provides information for sorting a list of imports. — shape: {attribute?: any, order?: any}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: any, values: any, operator: any}
  --max-results-body: int # The maximum number of imports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
  --next-token-body: string # If the response from the ListImports operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListImports request to return the next page of results. For a complete set of results, call the ListImports operation until the nextToken returned in the response is null. (body field)
  --locale-id: string # Specifies the locale that should be present in the list. If you don't specify a resource type in the filters parameter, the list contains both bot locales and custom vocabularies.
]: any -> record<botId: record, botVersion: record, importSummaries: record, nextToken: record, localeId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/imports/" $qp)
  let req_body = {"botId": $bot_id, "botVersion": $bot_version, "sortBy": $sort_by, "filters": $filters, "maxResults": $max_results_body, "nextToken": $next_token_body, "localeId": $locale_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Starts importing a bot, bot locale, or custom vocabulary from a zip archive that you uploaded to an S3 bucket.
#
# PUT /imports/
# operationId: StartImport
# --resourceSpecification shape: {botImportSpecification?: any, botLocaleImportSpecification?: any, customVocabularyImportSpecification?: record}
export def "imports start" [
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
  import_id: string # The unique identifier for the import. It is included in the response from the CreateUploadUrl (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateUploadUrl.html) operation.
  resource_specification: record # Provides information about the bot or bot locale that you want to import. You can specify the botImportSpecification or the botLocaleImportSpecification, but not both. — shape: {botImportSpecification?: any, botLocaleImportSpecification?: any, customVocabularyImportSpecification?: record}
  merge_strategy: string@merge-strategy-completer # The strategy to use when there is a name conflict between the imported resource and an existing resource. When the merge strategy is FailOnConflict existing resources are not overwritten and the import fails.
  --file-password: string # The password used to encrypt the zip archive that contains the resource definition. You should always encrypt the zip archive to protect it during transit between your site and Amazon Lex. (format: password)
]: any -> record<importId: record, resourceSpecification: record<botImportSpecification: record<botName: record, roleArn: record, dataPrivacy: record, idleSessionTTLInSeconds: record, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: record, botVersion: record, localeId: record, nluIntentConfidenceThreshold: record, voiceSettings: record>, customVocabularyImportSpecification: record<botId: record, botVersion: record, localeId: record>>, mergeStrategy: record, importStatus: record, creationDateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/")
  let req_body = {"importId": $import_id, "resourceSpecification": $resource_specification, "mergeStrategy": $merge_strategy, "filePassword": $file_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets a list of recommended intents provided by the bot recommendation that you can use in your bot. Intents in the response are ordered by relevance.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/intents
# operationId: ListRecommendedIntents
export def "bots-botversions-botlocales-botrecommendations-intents list-recommended" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --next-token-body: string # If the response from the ListRecommendedIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (body field)
  --max-results-body: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (body field)
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationId: record, summaryList: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/intents") $qp)
  let req_body = {"nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"maxResults": $max_results, "nextToken": $next_token} | compact), body: $req_body}
}

# Gets a list of tags associated with a resource. Only bots, bot aliases, and bot channels can have tags associated with them.
#
# GET /tags/{resourceARN}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceARN' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds the specified tags to the specified resource. If a tag key already exists, the existing value is replaced with the new value.
#
# POST /tags/{resourceARN}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # A list of tag keys to add to the resource. If a tag key already exists, the existing value is replaced with the new value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceARN' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search for associated transcripts that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/associatedtranscripts
# operationId: SearchAssociatedTranscripts
# --filters item shape: {name: any, values: any}
export def "bots-botversions-botlocales-botrecommendations-associatedtranscripts list-associated-transcripts" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
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
  --search-order: string@search-order-completer # How SearchResults are ordered. Valid values are Ascending or Descending. The default is Descending.
  filters: list # A list of filter objects. — item shape: {name: any, values: any}
  --max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --next-index: int # If the response from the SearchAssociatedTranscriptsRequest operation contains more results than specified in the maxResults parameter, an index is returned in the response. Use that index in the nextIndex parameter to return the next page of results.
]: any -> record<botId: record, botVersion: record, localeId: record, botRecommendationId: record, nextIndex: record, associatedTranscripts: record, totalResults: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/associatedtranscripts"))
  let req_body = {"searchOrder": $search_order, "filters": $filters, "maxResults": $max_results, "nextIndex": $next_index} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stop an already running Bot Recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/stopbotrecommendation
# operationId: StopBotRecommendation
export def "bots-botversions-botlocales-botrecommendations-stopbotrecommendation stop-recommendation" [
  bot_id: string
  bot_version: string
  locale_id: string
  bot_recommendation_id: string
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
]: nothing -> record<botId: record, botVersion: record, localeId: record, botRecommendationStatus: record, botRecommendationId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/stopbotrecommendation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes tags from a bot, bot alias, or bot channel.
#
# DELETE /tags/{resourceARN}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # A list of tag keys to remove from the resource. If a tag key does not exist on the resource, it is ignored.
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceARN' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
