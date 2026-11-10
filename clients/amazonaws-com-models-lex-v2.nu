# Auto-generated client for Amazon Lex Model Building V2 v2020-08-07
# Source: https://api.apis.guru/v2/specs/amazonaws.com/models.lex.v2/2020-08-07/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_MODEL_BUILDING_V2_TOKEN

const BASE_URL = "http://models-v2-lex.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LEX_MODEL_BUILDING_V2_TOKEN | default "" }
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
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-create-custom-vocabulary-item" "batch-delete-custom-vocabulary-item" "batch-update-custom-vocabulary-item" "build-bot-locale" "delete-bot-locale" "describe-bot-locale" "update-bot-locale" "create-bot" "list-bots" "create-bot-alias" "list-bot-aliases" "create-bot-locale" "list-bot-locales" "create-bot-version" "list-bot-versions" "create-export" "list-exports" "create-intent" "list-intents" "create-resource-policy" "delete-resource-policy" "describe-resource-policy" "update-resource-policy" "create-resource-policy-statement" "create-slot" "list-slots" "create-slot-type" "list-slot-types" "create-upload-url" "delete-bot" "describe-bot" "update-bot" "delete-bot-alias" "describe-bot-alias" "update-bot-alias" "delete-bot-version" "describe-bot-version" "delete-custom-vocabulary" "delete-export" "describe-export" "update-export" "delete-import" "describe-import" "delete-intent" "describe-intent" "update-intent" "delete-resource-policy-statement" "delete-slot" "describe-slot" "update-slot" "delete-slot-type" "describe-slot-type" "update-slot-type" "delete-utterances" "describe-bot-recommendation" "update-bot-recommendation" "describe-custom-vocabulary-metadata" "list-aggregated-utterances" "list-bot-recommendations" "start-bot-recommendation" "list-built-in-intents" "list-built-in-slot-types" "list-custom-vocabulary-items" "list-imports" "start-import" "list-recommended-intents" "list-tags-for-resource" "tag-resource" "search-associated-transcripts" "stop-bot-recommendation" "untag-resource" "commands"] | sort) } | get name | first)
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

# Create a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchcreate
# operationId: BatchCreateCustomVocabularyItem
export def "batch-create-custom-vocabulary-item" [
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
  custom_vocabulary_item_list: list # A list of new custom vocabulary items. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {phrase: string, weight?: int, displayAs?: string}
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/batchcreate") $auth.query)
  let req_body = {"customVocabularyItemList": $custom_vocabulary_item_list} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchdelete
# operationId: BatchDeleteCustomVocabularyItem
export def "batch-delete-custom-vocabulary-item" [
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
  custom_vocabulary_item_list: list # A list of custom vocabulary items requested to be deleted. Each entry must contain the unique custom vocabulary entry identifier. — item shape: {itemId: string}
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/batchdelete") $auth.query)
  let req_body = {"customVocabularyItemList": $custom_vocabulary_item_list} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Update a batch of custom vocabulary items for a given bot locale's custom vocabulary.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/batchupdate
# operationId: BatchUpdateCustomVocabularyItem
export def "batch-update-custom-vocabulary-item" [
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
  custom_vocabulary_item_list: list # A list of custom vocabulary items with updated fields. Each entry must contain a phrase and can optionally contain a displayAs and/or a weight. — item shape: {itemId: string, phrase: string, weight?: int, displayAs?: string}
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, errors: table<itemId: string, errorMessage: string, errorCode: string>, resources: table<itemId: string, phrase: string, weight: int, displayAs: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/batchupdate") $auth.query)
  let req_body = {"customVocabularyItemList": $custom_vocabulary_item_list} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Builds a bot, its intents, and its slot types into a specific locale. A bot can be built into multiple locales. At runtime the locale is used to choose a specific build of the bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: BuildBotLocale
export def "build-bot-locale" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, botLocaleStatus: string, lastBuildSubmittedDateTime: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Removes a locale from a bot. When you delete a locale, all intents, slots, and slot types defined for the locale are also deleted.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: DeleteBotLocale
export def "delete-bot-locale" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, botLocaleStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Describes the settings that a bot has for a specific locale.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: DescribeBotLocale
export def "describe-bot-locale" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, localeName: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, intentsCount: int, slotTypesCount: int, botLocaleStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, lastBuildSubmittedDateTime: string, botLocaleHistoryEvents: table<event: string, eventDate: string>, recommendedActions: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the settings that a bot has for a specific locale.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/
# operationId: UpdateBotLocale
export def "update-bot-locale" [
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
  --voice-settings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: string, engine?: "standard"|"neural"}
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, localeName: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, botLocaleStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, recommendedActions: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/") $auth.query)
  let req_body = {"description": $description, "nluIntentConfidenceThreshold": $nlu_intent_confidence_threshold, "voiceSettings": $voice_settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Creates an Amazon Lex conversational bot.
#
# PUT /bots/
# operationId: CreateBot
export def "create-bot" [
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
  data_privacy: record # By default, data stored by Amazon Lex is encrypted. The DataPrivacy structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot. — shape: {childDirected?: bool}
  idle_session_ttl_in_seconds: int # The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.
  --bot-tags: record # A list of tags to add to the bot. You can only add tags when you create a bot. You can't use the UpdateBot operation to update tags. To update tags, use the TagResource operation.
  --test-bot-alias-tags: record # A list of tags to add to the test alias for a bot. You can only add tags when you create a bot. You can't use the UpdateAlias operation to update tags. To update tags on the test alias, use the TagResource operation.
  --bot-type: string@bot-type-completer # The type of a bot to create.
  --bot-members: list # The list of bot members in a network to be created. — item shape: {botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string}
]: any -> oneof<record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, botTags: record, testBotAliasTags: record, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bots/" $auth.query)
  let req_body = {"botName": $bot_name, "description": $description, "roleArn": $role_arn, "dataPrivacy": $data_privacy, "idleSessionTTLInSeconds": $idle_session_ttl_in_seconds, "botTags": $bot_tags, "testBotAliasTags": $test_bot_alias_tags, "botType": $bot_type, "botMembers": $bot_members} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets a list of available bots.
#
# POST /bots/
# operationId: ListBots
export def "list-bots" [
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
  --sort-by: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: "BotName", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "BotName"|"BotType", values: list<string>, operator: "CO"|"EQ"|"NE"}
  --body-max-results: int # The maximum number of bots to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBots operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListBots request to return the next page of results. For a complete set of results, call the ListBots operation until the nextToken returned in the response is null. (spec name: nextToken)
]: any -> oneof<record<botSummaries: table<botId: string, botName: string, description: string, botStatus: string, latestBotVersion: string, lastUpdatedDateTime: string, botType: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bots/" $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an alias for the specified version of a bot. Use an alias to enable you to change the version of a bot without updating applications that use the bot. For example, you can create an alias called "PROD" that your applications use to call the Amazon Lex bot.
#
# PUT /bots/{botId}/botaliases/
# operationId: CreateBotAlias
export def "create-bot-alias" [
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
  --conversation-log-settings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: list, audioLogSettings?: list}
  --sentiment-analysis-settings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: bool}
  --tags: record # A list of tags to add to the bot alias. You can only add tags when you create an alias, you can't use the UpdateBotAlias operation to update the tags on a bot alias. To update tags, use the TagResource operation.
]: any -> oneof<record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasStatus: string, botId: string, creationDateTime: string, tags: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botaliases/") $auth.query)
  let req_body = {"botAliasName": $bot_alias_name, "description": $description, "botVersion": $bot_version, "botAliasLocaleSettings": $bot_alias_locale_settings, "conversationLogSettings": $conversation_log_settings, "sentimentAnalysisSettings": $sentiment_analysis_settings, "tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets a list of aliases for the specified bot.
#
# POST /bots/{botId}/botaliases/
# operationId: ListBotAliases
export def "list-bot-aliases" [
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
  --body-max-results: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBotAliases operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botAliasSummaries: table<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string, botId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botaliases/") $qp $auth.query)
  let req_body = {"maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a locale in the bot. The locale contains the intents and slot types that the bot uses in conversations with users in the specified language and locale. You must add a locale to a bot before you can add intents and slot types to the bot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/
# operationId: CreateBotLocale
export def "create-bot-locale" [
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
  --voice-settings: record # Defines settings for using an Amazon Polly voice to communicate with a user. — shape: {voiceId?: string, engine?: "standard"|"neural"}
]: any -> oneof<record<botId: string, botVersion: string, localeName: string, localeId: string, description: string, nluIntentConfidenceThreshold: float, voiceSettings: record<voiceId: string, engine: string>, botLocaleStatus: string, creationDateTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/") $auth.query)
  let req_body = {"localeId": $locale_id, "description": $description, "nluIntentConfidenceThreshold": $nlu_intent_confidence_threshold, "voiceSettings": $voice_settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets a list of locales for the specified bot.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/
# operationId: ListBotLocales
export def "list-bot-locales" [
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
  --sort-by: record # Specifies attributes for sorting a list of bot locales. — shape: {attribute?: "BotLocaleName", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification for a filter used to limit the response to only those locales that match the filter specification. You can only specify one filter and one value to filter on. — item shape: {name: "BotLocaleName", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of aliases to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBotLocales operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token as the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersion: string, nextToken: string, botLocaleSummaries: table<localeId: string, localeName: string, description: string, botLocaleStatus: string, lastUpdatedDateTime: string, lastBuildSubmittedDateTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new version of the bot based on the DRAFT version. If the DRAFT version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version, it returns the last created version. When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1.
#
# PUT /bots/{botId}/botversions/
# operationId: CreateBotVersion
export def "create-bot-version" [
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
]: any -> oneof<record<botId: string, description: string, botVersion: string, botVersionLocaleSpecification: record, botStatus: string, creationDateTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botversions/") $auth.query)
  let req_body = {"description": $description, "botVersionLocaleSpecification": $bot_version_locale_specification} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets information about all of the versions of a bot. The ListBotVersions operation returns a summary of each version of a bot. For example, if a bot has three numbered versions, the ListBotVersions operation returns for summaries, one for each numbered version and one for the DRAFT version. The ListBotVersions operation always returns at least one version, the DRAFT version.
#
# POST /bots/{botId}/botversions/
# operationId: ListBotVersions
export def "list-bot-versions" [
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
  --sort-by: record # Specifies attributes for sorting a list of bot versions. — shape: {attribute?: "BotVersion", order?: "Ascending"|"Descending"}
  --body-max-results: int # The maximum number of versions to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response to the ListBotVersion operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersionSummaries: table<botName: string, botVersion: string, description: string, botStatus: string, creationDateTime: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/botversions/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a zip archive containing the contents of a bot or a bot locale. The archive contains a directory structure that contains JSON files that define the bot. You can create an archive that contains the complete definition of a bot, or you can specify that the archive contain only the definition of a single bot locale. For more information about exporting bots, and about the structure of the export archive, see Importing and exporting bots (https://docs.aws.amazon.com/lexv2/latest/dg/importing-exporting.html)
#
# PUT /exports/
# operationId: CreateExport
export def "create-export" [
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
  resource_specification: record # Provides information about the bot or bot locale that you want to export. You can specify the botExportSpecification or the botLocaleExportSpecification, but not both. — shape: {botExportSpecification?: record, botLocaleExportSpecification?: record, customVocabularyExportSpecification?: record}
  file_format: string@file-format-completer # The file format of the bot or bot locale definition files.
  --file-password: string # An password to use to encrypt the exported archive. Using a password is optional, but you should encrypt the archive to protect the data in transit between Amazon Lex and your local computer. (format: password)
]: any -> oneof<record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, creationDateTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exports/" $auth.query)
  let req_body = {"resourceSpecification": $resource_specification, "fileFormat": $file_format, "filePassword": $file_password} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Lists the exports for a bot, bot locale, or custom vocabulary. Exports are kept in the list for 7 days.
#
# POST /exports/
# operationId: ListExports
export def "list-exports" [
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
  --sort-by: record # Provides information about sorting a list of exports. — shape: {attribute?: "LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the exports in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "ExportResourceType", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of exports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListExports operation contains more results that specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListExports request to return the next page of results. For a complete set of results, call the ListExports operation until the nextToken returned in the response is null. (spec name: nextToken)
  --locale-id: string # Specifies the resources that should be exported. If you don't specify a resource type in the filters parameter, both bot locales and custom vocabularies are exported.
]: any -> oneof<record<botId: string, botVersion: string, exportSummaries: table<exportId: string, resourceSpecification: record, fileFormat: string, exportStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string, localeId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exports/" $qp $auth.query)
  let req_body = {"botId": $bot_id, "botVersion": $bot_version, "sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token, "localeId": $locale_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an intent. To define the interaction between the user and your bot, you define one or more intents. For example, for a pizza ordering bot you would create an OrderPizza intent. When you create an intent, you must provide a name. You can optionally provide the following: Sample utterances. For example, "I want to order a pizza" and "Can I order a pizza." You can't provide utterances for built-in intents. Information to be gathered. You specify slots for the information that you bot requests from the user. You can specify standard slot types, such as date and time, or custom slot types for your application. How the intent is fulfilled. You can provide a Lambda function or configure the intent to return the intent information to your client application. If you use a Lambda function, Amazon Lex invokes the function when all of the intent information is available. A confirmation prompt to send to the user to confirm an intent. For example, "Shall I order your pizza?" A conclusion statement to send to the user after the intent is fulfilled. For example, "I ordered your pizza." A follow-up prompt that asks the user for additional activity. For example, "Do you want a drink with your pizza?"
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# operationId: CreateIntent
export def "create-intent" [
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
  --sample-utterances: list # An array of strings that a user might say to signal the intent. For example, "I want a pizza", or "I want a {PizzaSize} pizza". In an utterance, slot names are enclosed in curly braces ("{", "}") to indicate where they should be displayed in the utterance shown to the user.. — item shape: {utterance: string}
  --dialog-code-hook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: bool}
  --fulfillment-code-hook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: bool, postFulfillmentStatusSpecification?: record, fulfillmentUpdatesSpecification?: record, active?: bool}
  --intent-confirmation-setting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: record, declinationResponse?: record, active?: bool, confirmationResponse?: record, confirmationNextStep?: record, confirmationConditional?: record, declinationNextStep?: record, declinationConditional?: record, failureResponse?: record, failureNextStep?: record, failureConditional?: record, codeHook?: record, elicitationCodeHook?: record}
  --intent-closing-setting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: record, active?: bool, nextStep?: record, conditional?: record}
  --input-contexts: list # A list of contexts that must be active for this intent to be considered by Amazon Lex. When an intent has an input context list, Amazon Lex only considers using the intent in an interaction with the user when the specified contexts are included in the active context list for the session. If the contexts are not active, then Amazon Lex will not use the intent. A context can be automatically activated using the outputContexts property or it can be set at runtime. For example, if there are two intents with different input contexts that respond to the same utterances, only the intent with the active context will respond. An intent may have up to 5 input contexts. If an intent has multiple input contexts, all of the contexts must be active to consider the intent. — item shape: {name: string}
  --output-contexts: list # A lists of contexts that the intent activates when it is fulfilled. You can use an output context to indicate the intents that Amazon Lex should consider for the next turn of the conversation with a customer. When you use the outputContextsList property, all of the contexts specified in the list are activated when the intent is fulfilled. You can set up to 10 output contexts. You can also set the number of conversation turns that the context should be active, or the length of time that the context should be active. — item shape: {name: string, timeToLiveInSeconds: int, turnsToLive: int}
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: string, queryFilterStringEnabled?: bool, queryFilterString?: string}
  --initial-response-setting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: record, conditional?: record, codeHook?: record}
]: any -> oneof<record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/") $auth.query)
  let req_body = {"intentName": $intent_name, "description": $description, "parentIntentSignature": $parent_intent_signature, "sampleUtterances": $sample_utterances, "dialogCodeHook": $dialog_code_hook, "fulfillmentCodeHook": $fulfillment_code_hook, "intentConfirmationSetting": $intent_confirmation_setting, "intentClosingSetting": $intent_closing_setting, "inputContexts": $input_contexts, "outputContexts": $output_contexts, "kendraConfiguration": $kendra_configuration, "initialResponseSetting": $initial_response_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list of intents that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/
# operationId: ListIntents
export def "list-intents" [
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
  --sort-by: record # Specifies attributes for sorting a list of intents. — shape: {attribute?: "IntentName"|"LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the intents in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: "IntentName", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListIntents request to return the next page of results. For a complete set of results, call the ListIntents operation until the nextToken returned in the response is null. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, intentSummaries: table<intentId: string, intentName: string, description: string, parentIntentSignature: string, inputContexts: list, outputContexts: list, lastUpdatedDateTime: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new resource policy with the specified policy statements.
#
# POST /policy/{resourceArn}/
# operationId: CreateResourcePolicy
export def "create-resource-policy" [
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
]: any -> oneof<record<resourceArn: string, revisionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/") $auth.query)
  let req_body = {"policy": $policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Removes an existing policy from a bot or bot alias. If the resource doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
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
]: nothing -> oneof<record<resourceArn: string, revisionId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"expectedRevisionId": $expected_revision_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets the resource policy and policy revision for a bot or bot alias.
#
# GET /policy/{resourceArn}/
# operationId: DescribeResourcePolicy
export def "describe-resource-policy" [
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
]: nothing -> oneof<record<resourceArn: string, policy: string, revisionId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Replaces the existing resource policy for a bot or bot alias with a new one. If the policy doesn't exist, Amazon Lex returns an exception.
#
# PUT /policy/{resourceArn}/
# operationId: UpdateResourcePolicy
export def "update-resource-policy" [
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
]: any -> oneof<record<resourceArn: string, revisionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/") $qp $auth.query)
  let req_body = {"policy": $policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"expectedRevisionId": $expected_revision_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds a new resource policy statement to a bot or bot alias. If a resource policy exists, the statement is added to the current resource policy. If a policy doesn't exist, a new policy is created. You can't create a resource policy statement that allows cross-account access.
#
# POST /policy/{resourceArn}/statements/
# operationId: CreateResourcePolicyStatement
export def "create-resource-policy-statement" [
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
  principal: list # An IAM principal, such as an IAM users, IAM roles, or AWS services that is allowed or denied access to a resource. For more information, see AWS JSON policy elements: Principal (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html). — item shape: {service?: string, arn?: string}
  action: list<string> # The Amazon Lex action that this policy either allows or denies. The action must apply to the resource type of the specified ARN. For more information, see Actions, resources, and condition keys for Amazon Lex V2 (https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonlexv2.html).
  --condition: record # Specifies a condition when the policy is in effect. If the principal of the policy is a service principal, you must provide two condition blocks, one with a SourceAccount global condition key and one with a SourceArn global condition key. For more information, see IAM JSON policy elements: Condition (https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html).
]: any -> oneof<record<resourceArn: string, revisionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/policy/{resource_arn}/statements/") $qp $auth.query)
  let req_body = {"statementId": $statement_id, "effect": $effect, "principal": $principal, "action": $action, "condition": $condition} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expectedRevisionId": $expected_revision_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a slot in an intent. A slot is a variable needed to fulfill an intent. For example, an OrderPizza intent might need slots for size, crust, and number of pizzas. For each slot, you define one or more utterances that Amazon Lex uses to elicit a response from the user.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# operationId: CreateSlot
export def "create-slot" [
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
  value_elicitation_setting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: record, slotConstraint?: "Required"|"Optional", promptSpecification?: record, sampleUtterances?: list, waitAndContinueSpecification?: record, slotCaptureSetting?: record}
  --obfuscation-setting: record # Determines whether Amazon Lex obscures slot values in conversation logs. — shape: {obfuscationSettingType?: "None"|"DefaultObfuscation"}
  --multiple-values-setting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: bool}
  --sub-slot-setting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: string, slotSpecifications?: record}
]: any -> oneof<record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/") $auth.query)
  let req_body = {"slotName": $slot_name, "description": $description, "slotTypeId": $slot_type_id, "valueElicitationSetting": $value_elicitation_setting, "obfuscationSetting": $obfuscation_setting, "multipleValuesSetting": $multiple_values_setting, "subSlotSetting": $sub_slot_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of slots that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/
# operationId: ListSlots
export def "list-slots" [
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
  --sort-by: record # Specifies attributes for sorting a list of bots. — shape: {attribute?: "SlotName"|"LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the slots in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: "SlotName", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of slots to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListSlots operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, intentId: string, slotSummaries: table<slotId: string, slotName: string, description: string, slotConstraint: string, slotTypeId: string, valueElicitationPromptSpecification: record, lastUpdatedDateTime: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a custom slot type To create a custom slot type, specify a name for the slot type and a set of enumeration values, the values that a slot of this type can assume.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# operationId: CreateSlotType
export def "create-slot-type" [
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
  --slot-type-values: list # A list of SlotTypeValue objects that defines the values that the slot type can take. Each value can have a list of synonyms, additional values that help train the machine learning model about the values that it resolves for a slot. — item shape: {sampleValue?: record, synonyms?: list}
  --value-selection-setting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: "OriginalValue"|"TopResolution"|"Concatenation", regexFilter?: record, advancedRecognitionSetting?: record}
  --parent-slot-type-signature: string # The built-in slot type used as a parent of this slot type. When you define a parent slot type, the new slot type has the configuration of the parent slot type. Only AMAZON.AlphaNumeric is supported.
  --external-source-setting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: record}
  --composite-slot-type-setting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: list}
]: any -> oneof<record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/") $auth.query)
  let req_body = {"slotTypeName": $slot_type_name, "description": $description, "slotTypeValues": $slot_type_values, "valueSelectionSetting": $value_selection_setting, "parentSlotTypeSignature": $parent_slot_type_signature, "externalSourceSetting": $external_source_setting, "compositeSlotTypeSetting": $composite_slot_type_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of slot types that match the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/
# operationId: ListSlotTypes
export def "list-slot-types" [
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
  --sort-by: record # Specifies attributes for sorting a list of slot types. — shape: {attribute?: "SlotTypeName"|"LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the slot types in the response to only those that match the filter specification. You can only specify one filter and only one string to filter on. — item shape: {name: "SlotTypeName"|"ExternalSourceType", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListSlotTypes operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, slotTypeSummaries: table<slotTypeId: string, slotTypeName: string, description: string, parentSlotTypeSignature: string, lastUpdatedDateTime: string, slotTypeCategory: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a pre-signed S3 write URL that you use to upload the zip archive when importing a bot or a bot locale.
#
# POST /createuploadurl/
# operationId: CreateUploadUrl
export def "create-upload-url" [
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
]: nothing -> oneof<record<importId: string, uploadUrl: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createuploadurl/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Deletes all versions of a bot, including the Draft version. To delete a specific version, use the DeleteBotVersion operation. When you delete a bot, all of the resources contained in the bot are also deleted. Deleting a bot removes all locales, intents, slot, and slot types defined for the bot. If a bot has an alias, the DeleteBot operation returns a ResourceInUseException exception. If you want to delete the bot and the alias, set the skipResourceInUseCheck parameter to true.
#
# DELETE /bots/{botId}/
# operationId: DeleteBot
export def "delete-bot" [
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
]: nothing -> oneof<record<botId: string, botStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Provides metadata information about a bot.
#
# GET /bots/{botId}/
# operationId: DescribeBot
export def "describe-bot" [
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
]: nothing -> oneof<record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, lastUpdatedDateTime: string, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>, failureReasons: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the configuration of an existing bot.
#
# PUT /bots/{botId}/
# operationId: UpdateBot
export def "update-bot" [
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
  data_privacy: record # By default, data stored by Amazon Lex is encrypted. The DataPrivacy structure provides settings that determine how Amazon Lex handles special cases of securing the data for your bot. — shape: {childDirected?: bool}
  idle_session_ttl_in_seconds: int # The time, in seconds, that Amazon Lex should keep information about a user's conversation with the bot. A user interaction remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. You can specify between 60 (1 minute) and 86,400 (24 hours) seconds.
  --bot-type: string@bot-type-completer # The type of the bot to be updated.
  --bot-members: list # The list of bot members in the network associated with the update action. — item shape: {botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string}
]: any -> oneof<record<botId: string, botName: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, creationDateTime: string, lastUpdatedDateTime: string, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/") $auth.query)
  let req_body = {"botName": $bot_name, "description": $description, "roleArn": $role_arn, "dataPrivacy": $data_privacy, "idleSessionTTLInSeconds": $idle_session_ttl_in_seconds, "botType": $bot_type, "botMembers": $bot_members} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Deletes the specified bot alias.
#
# DELETE /bots/{botId}/botaliases/{botAliasId}/
# operationId: DeleteBotAlias
export def "delete-bot-alias" [
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
]: nothing -> oneof<record<botAliasId: string, botId: string, botAliasStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id)} | format pattern "/bots/{bot_id}/botaliases/{bot_alias_id}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Get information about a specific bot alias.
#
# GET /bots/{botId}/botaliases/{botAliasId}/
# operationId: DescribeBotAlias
export def "describe-bot-alias" [
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
]: nothing -> oneof<record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasHistoryEvents: table<botVersion: string, startDate: string, endDate: string>, botAliasStatus: string, botId: string, creationDateTime: string, lastUpdatedDateTime: string, parentBotNetworks: table<botId: string, botVersion: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id)} | format pattern "/bots/{bot_id}/botaliases/{bot_alias_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the configuration of an existing bot alias.
#
# PUT /bots/{botId}/botaliases/{botAliasId}/
# operationId: UpdateBotAlias
export def "update-bot-alias" [
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
  --conversation-log-settings: record # Configures conversation logging that saves audio, text, and metadata for the conversations with your users. — shape: {textLogSettings?: list, audioLogSettings?: list}
  --sentiment-analysis-settings: record # Determines whether Amazon Lex will use Amazon Comprehend to detect the sentiment of user utterances. — shape: {detectSentiment?: bool}
]: any -> oneof<record<botAliasId: string, botAliasName: string, description: string, botVersion: string, botAliasLocaleSettings: record, conversationLogSettings: record<textLogSettings: list<record>, audioLogSettings: list<record>>, sentimentAnalysisSettings: record<detectSentiment: bool>, botAliasStatus: string, botId: string, creationDateTime: string, lastUpdatedDateTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_alias_id | is-empty) { error make --unspanned { msg: "path parameter 'botAliasId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_alias_id: (encode-path-segment $bot_alias_id)} | format pattern "/bots/{bot_id}/botaliases/{bot_alias_id}/") $auth.query)
  let req_body = {"botAliasName": $bot_alias_name, "description": $description, "botVersion": $bot_version, "botAliasLocaleSettings": $bot_alias_locale_settings, "conversationLogSettings": $conversation_log_settings, "sentimentAnalysisSettings": $sentiment_analysis_settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Deletes a specific version of a bot. To delete all versions of a bot, use the DeleteBot (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DeleteBot.html) operation.
#
# DELETE /bots/{botId}/botversions/{botVersion}/
# operationId: DeleteBotVersion
export def "delete-bot-version" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, botStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let qp = [(serialize-qp "skipResourceInUseCheck" $skip_resource_in_use_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Provides metadata about a version of a bot.
#
# GET /bots/{botId}/botversions/{botVersion}/
# operationId: DescribeBotVersion
export def "describe-bot-version" [
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
]: nothing -> oneof<record<botId: string, botName: string, botVersion: string, description: string, roleArn: string, dataPrivacy: record<childDirected: bool>, idleSessionTTLInSeconds: int, botStatus: string, failureReasons: list<string>, creationDateTime: string, parentBotNetworks: table<botId: string, botVersion: string>, botType: string, botMembers: table<botMemberId: string, botMemberName: string, botMemberAliasId: string, botMemberAliasName: string, botMemberVersion: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes a custom vocabulary from the specified locale in the specified bot.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary
# operationId: DeleteCustomVocabulary
export def "delete-custom-vocabulary" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, customVocabularyStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Removes a previous export and the associated files stored in an S3 bucket.
#
# DELETE /exports/{exportId}/
# operationId: DeleteExport
export def "delete-export" [
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
]: nothing -> oneof<record<exportId: string, exportStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/exports/{export_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets information about a specific export.
#
# GET /exports/{exportId}/
# operationId: DescribeExport
export def "describe-export" [
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
]: nothing -> oneof<record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, failureReasons: list<string>, downloadUrl: string, creationDateTime: string, lastUpdatedDateTime: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/exports/{export_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the password used to protect an export zip archive. The password is not required. If you don't supply a password, Amazon Lex generates a zip file that is not protected by a password. This is the archive that is available at the pre-signed S3 URL provided by the DescribeExport (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_DescribeExport.html) operation.
#
# PUT /exports/{exportId}/
# operationId: UpdateExport
export def "update-export" [
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
]: any -> oneof<record<exportId: string, resourceSpecification: record<botExportSpecification: record<botId: string, botVersion: string>, botLocaleExportSpecification: record<botId: string, botVersion: string, localeId: string>, customVocabularyExportSpecification: record<botId: string, botVersion: string, localeId: string>>, fileFormat: string, exportStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/exports/{export_id}/") $auth.query)
  let req_body = {"filePassword": $file_password} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Removes a previous import and the associated file stored in an S3 bucket.
#
# DELETE /imports/{importId}/
# operationId: DeleteImport
export def "delete-import" [
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
]: nothing -> oneof<record<importId: string, importStatus: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($import_id | is-empty) { error make --unspanned { msg: "path parameter 'importId' must be non-empty" } }
  let full_url = (build-url $base ({import_id: (encode-path-segment $import_id)} | format pattern "/imports/{import_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Gets information about a specific import.
#
# GET /imports/{importId}/
# operationId: DescribeImport
export def "describe-import" [
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
]: nothing -> oneof<record<importId: string, resourceSpecification: record<botImportSpecification: record<botName: string, roleArn: string, dataPrivacy: record, idleSessionTTLInSeconds: int, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: string, botVersion: string, localeId: string, nluIntentConfidenceThreshold: float, voiceSettings: record>, customVocabularyImportSpecification: record<botId: string, botVersion: string, localeId: string>>, importedResourceId: string, importedResourceName: string, mergeStrategy: string, importStatus: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($import_id | is-empty) { error make --unspanned { msg: "path parameter 'importId' must be non-empty" } }
  let full_url = (build-url $base ({import_id: (encode-path-segment $import_id)} | format pattern "/imports/{import_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes the specified intent. Deleting an intent also deletes the slots associated with the intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DeleteIntent
export def "delete-intent" [
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
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns metadata about an intent.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: DescribeIntent
export def "describe-intent" [
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
]: nothing -> oneof<record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, slotPriorities: table<priority: int, slotId: string>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the settings for an intent.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/
# operationId: UpdateIntent
export def "update-intent" [
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
  --sample-utterances: list # New utterances used to invoke the intent. — item shape: {utterance: string}
  --dialog-code-hook: record # Settings that determine the Lambda function that Amazon Lex uses for processing user responses. — shape: {enabled?: bool}
  --fulfillment-code-hook: record # Determines if a Lambda function should be invoked for a specific intent. — shape: {enabled?: bool, postFulfillmentStatusSpecification?: record, fulfillmentUpdatesSpecification?: record, active?: bool}
  --slot-priorities: list # A new list of slots and their priorities that are contained by the intent. — item shape: {priority: int, slotId: string}
  --intent-confirmation-setting: record # Provides a prompt for making sure that the user is ready for the intent to be fulfilled. — shape: {promptSpecification?: record, declinationResponse?: record, active?: bool, confirmationResponse?: record, confirmationNextStep?: record, confirmationConditional?: record, declinationNextStep?: record, declinationConditional?: record, failureResponse?: record, failureNextStep?: record, failureConditional?: record, codeHook?: record, elicitationCodeHook?: record}
  --intent-closing-setting: record # Provides a statement the Amazon Lex conveys to the user when the intent is successfully fulfilled. — shape: {closingResponse?: record, active?: bool, nextStep?: record, conditional?: record}
  --input-contexts: list # A new list of contexts that must be active in order for Amazon Lex to consider the intent. — item shape: {name: string}
  --output-contexts: list # A new list of contexts that Amazon Lex activates when the intent is fulfilled. — item shape: {name: string, timeToLiveInSeconds: int, turnsToLive: int}
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. — shape: {kendraIndex?: string, queryFilterStringEnabled?: bool, queryFilterString?: string}
  --initial-response-setting: record # Configuration setting for a response sent to the user before Amazon Lex starts eliciting slots. — shape: {initialResponse?: record, nextStep?: record, conditional?: record, codeHook?: record}
]: any -> oneof<record<intentId: string, intentName: string, description: string, parentIntentSignature: string, sampleUtterances: table<utterance: string>, dialogCodeHook: record<enabled: bool>, fulfillmentCodeHook: record<enabled: bool, postFulfillmentStatusSpecification: record<successResponse: record, failureResponse: record, timeoutResponse: record, successNextStep: record, successConditional: record, failureNextStep: record, failureConditional: record, timeoutNextStep: record, timeoutConditional: record>, fulfillmentUpdatesSpecification: record<active: bool, startResponse: record, updateResponse: record, timeoutInSeconds: int>, active: bool>, slotPriorities: table<priority: int, slotId: string>, intentConfirmationSetting: record<promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, declinationResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, confirmationResponse: record<messageGroups: list, allowInterrupt: bool>, confirmationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, confirmationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, declinationNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, declinationConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, failureResponse: record<messageGroups: list, allowInterrupt: bool>, failureNextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, failureConditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>, elicitationCodeHook: record<enableCodeHookInvocation: bool, invocationLabel: string>>, intentClosingSetting: record<closingResponse: record<messageGroups: list, allowInterrupt: bool>, active: bool, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>>, inputContexts: table<name: string>, outputContexts: table<name: string, timeToLiveInSeconds: int, turnsToLive: int>, kendraConfiguration: record<kendraIndex: string, queryFilterStringEnabled: bool, queryFilterString: string>, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, initialResponseSetting: record<initialResponse: record<messageGroups: list, allowInterrupt: bool>, nextStep: record<dialogAction: record, intent: record, sessionAttributes: record>, conditional: record<active: bool, conditionalBranches: list, defaultBranch: record>, codeHook: record<enableCodeHookInvocation: bool, active: bool, invocationLabel: string, postCodeHookSpecification: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/") $auth.query)
  let req_body = {"intentName": $intent_name, "description": $description, "parentIntentSignature": $parent_intent_signature, "sampleUtterances": $sample_utterances, "dialogCodeHook": $dialog_code_hook, "fulfillmentCodeHook": $fulfillment_code_hook, "slotPriorities": $slot_priorities, "intentConfirmationSetting": $intent_confirmation_setting, "intentClosingSetting": $intent_closing_setting, "inputContexts": $input_contexts, "outputContexts": $output_contexts, "kendraConfiguration": $kendra_configuration, "initialResponseSetting": $initial_response_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a policy statement from a resource policy. If you delete the last statement from a policy, the policy is deleted. If you specify a statement ID that doesn't exist in the policy, or if the bot or bot alias doesn't have a policy attached, Amazon Lex returns an exception.
#
# DELETE /policy/{resourceArn}/statements/{statementId}/
# operationId: DeleteResourcePolicyStatement
export def "delete-resource-policy-statement" [
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
]: nothing -> oneof<record<resourceArn: string, revisionId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  if ($statement_id | is-empty) { error make --unspanned { msg: "path parameter 'statementId' must be non-empty" } }
  let qp = [(serialize-qp "expectedRevisionId" $expected_revision_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn), statement_id: (encode-path-segment $statement_id)} | format pattern "/policy/{resource_arn}/statements/{statement_id}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"expectedRevisionId": $expected_revision_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Deletes the specified slot from an intent.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DeleteSlot
export def "delete-slot" [
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
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id), slot_id: (encode-path-segment $slot_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/{slot_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets metadata information about a slot.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: DescribeSlot
export def "describe-slot" [
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
]: nothing -> oneof<record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, lastUpdatedDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  if ($slot_id | is-empty) { error make --unspanned { msg: "path parameter 'slotId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id), slot_id: (encode-path-segment $slot_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/{slot_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the settings for a slot.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/intents/{intentId}/slots/{slotId}/
# operationId: UpdateSlot
export def "update-slot" [
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
  value_elicitation_setting: record # Specifies the elicitation setting details for constituent sub slots of a composite slot. — shape: {defaultValueSpecification?: record, slotConstraint?: "Required"|"Optional", promptSpecification?: record, sampleUtterances?: list, waitAndContinueSpecification?: record, slotCaptureSetting?: record}
  --obfuscation-setting: record # Determines whether Amazon Lex obscures slot values in conversation logs. — shape: {obfuscationSettingType?: "None"|"DefaultObfuscation"}
  --multiple-values-setting: record # Indicates whether a slot can return multiple values. — shape: {allowMultipleValues?: bool}
  --sub-slot-setting: record # Specifications for the constituent sub slots and the expression for the composite slot. — shape: {expression?: string, slotSpecifications?: record}
]: any -> oneof<record<slotId: string, slotName: string, description: string, slotTypeId: string, valueElicitationSetting: record<defaultValueSpecification: record<defaultValueList: list>, slotConstraint: string, promptSpecification: record<messageGroups: list, maxRetries: int, allowInterrupt: bool, messageSelectionStrategy: string, promptAttemptsSpecification: record>, sampleUtterances: list<record>, waitAndContinueSpecification: record<waitingResponse: record, continueResponse: record, stillWaitingResponse: record, active: bool>, slotCaptureSetting: record<captureResponse: record, captureNextStep: record, captureConditional: record, failureResponse: record, failureNextStep: record, failureConditional: record, codeHook: record, elicitationCodeHook: record>>, obfuscationSetting: record<obfuscationSettingType: string>, botId: string, botVersion: string, localeId: string, intentId: string, creationDateTime: string, lastUpdatedDateTime: string, multipleValuesSetting: record<allowMultipleValues: bool>, subSlotSetting: record<expression: string, slotSpecifications: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  if ($slot_id | is-empty) { error make --unspanned { msg: "path parameter 'slotId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), intent_id: (encode-path-segment $intent_id), slot_id: (encode-path-segment $slot_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/intents/{intent_id}/slots/{slot_id}/") $auth.query)
  let req_body = {"slotName": $slot_name, "description": $description, "slotTypeId": $slot_type_id, "valueElicitationSetting": $value_elicitation_setting, "obfuscationSetting": $obfuscation_setting, "multipleValuesSetting": $multiple_values_setting, "subSlotSetting": $sub_slot_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a slot type from a bot locale. If a slot is using the slot type, Amazon Lex throws a ResourceInUseException exception. To avoid the exception, set the skipResourceInUseCheck parameter to true.
#
# DELETE /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DeleteSlotType
export def "delete-slot-type" [
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
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), slot_type_id: (encode-path-segment $slot_type_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/{slot_type_id}/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"skipResourceInUseCheck": $skip_resource_in_use_check} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets metadata information about a slot type.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: DescribeSlotType
export def "describe-slot-type" [
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
]: nothing -> oneof<record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($slot_type_id | is-empty) { error make --unspanned { msg: "path parameter 'slotTypeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), slot_type_id: (encode-path-segment $slot_type_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/{slot_type_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the configuration of an existing slot type.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/slottypes/{slotTypeId}/
# operationId: UpdateSlotType
export def "update-slot-type" [
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
  --slot-type-values: list # A new list of values and their optional synonyms that define the values that the slot type can take. — item shape: {sampleValue?: record, synonyms?: list}
  --value-selection-setting: record # Contains settings used by Amazon Lex to select a slot value. — shape: {resolutionStrategy?: "OriginalValue"|"TopResolution"|"Concatenation", regexFilter?: record, advancedRecognitionSetting?: record}
  --parent-slot-type-signature: string # The new built-in slot type that should be used as the parent of this slot type.
  --external-source-setting: record # Provides information about the external source of the slot type's definition. — shape: {grammarSlotTypeSetting?: record}
  --composite-slot-type-setting: record # A composite slot is a combination of two or more slots that capture multiple pieces of information in a single user input. — shape: {subSlots?: list}
]: any -> oneof<record<slotTypeId: string, slotTypeName: string, description: string, slotTypeValues: table<sampleValue: record, synonyms: list>, valueSelectionSetting: record<resolutionStrategy: string, regexFilter: record<pattern: string>, advancedRecognitionSetting: record<audioRecognitionStrategy: string>>, parentSlotTypeSignature: string, botId: string, botVersion: string, localeId: string, creationDateTime: string, lastUpdatedDateTime: string, externalSourceSetting: record<grammarSlotTypeSetting: record<source: record>>, compositeSlotTypeSetting: record<subSlots: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($slot_type_id | is-empty) { error make --unspanned { msg: "path parameter 'slotTypeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), slot_type_id: (encode-path-segment $slot_type_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/slottypes/{slot_type_id}/") $auth.query)
  let req_body = {"slotTypeName": $slot_type_name, "description": $description, "slotTypeValues": $slot_type_values, "valueSelectionSetting": $value_selection_setting, "parentSlotTypeSignature": $parent_slot_type_signature, "externalSourceSetting": $external_source_setting, "compositeSlotTypeSetting": $composite_slot_type_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Deletes stored utterances. Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the ListAggregatedUtterances (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_ListAggregatedUtterances.html) operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.. Use the DeleteUtterances operation to manually delete utterances for a specific session. When you use the DeleteUtterances operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the ListAggregatedUtterances operation are deleted after 15 days.
#
# DELETE /bots/{botId}/utterances/
# operationId: DeleteUtterances
export def "delete-utterances" [
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
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "localeId" $locale_id "scalar") (serialize-qp "sessionId" $session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/utterances/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"localeId": $locale_id, "sessionId": $session_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Provides metadata information about a bot recommendation. This information will enable you to get a description on the request inputs, to download associated transcripts after processing is complete, and to download intents and slot-types generated by the bot recommendation.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# operationId: DescribeBotRecommendation
export def "describe-bot-recommendation" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, failureReasons: list<string>, creationDateTime: string, lastUpdatedDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>, botRecommendationResults: record<botLocaleExportUrl: string, associatedTranscriptsUrl: string, statistics: record<intents: record, slotTypes: record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing bot recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/
# operationId: UpdateBotRecommendation
export def "update-bot-recommendation" [
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
  encryption_setting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: string, botLocaleExportPassword?: string, associatedTranscriptsPassword?: string}
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, lastUpdatedDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/") $auth.query)
  let req_body = {"encryptionSetting": $encryption_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Provides metadata information about a custom vocabulary.
#
# GET /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/metadata
# operationId: DescribeCustomVocabularyMetadata
export def "describe-custom-vocabulary-metadata" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, customVocabularyStatus: string, creationDateTime: string, lastUpdatedDateTime: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/metadata") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provides a list of utterances that users have sent to the bot. Utterances are aggregated by the text of the utterance. For example, all instances where customers used the phrase "I want to order pizza" are aggregated into the same line in the response. You can see both detected utterances and missed utterances. A detected utterance is where the bot properly recognized the utterance and activated the associated intent. A missed utterance was not recognized by the bot and didn't activate an intent. Utterances can be aggregated for a bot alias or for a bot version, but not both at the same time. Utterances statistics are not generated under the following conditions: The childDirected field was set to true when the bot was created. You are using slot obfuscation with one or more slots. You opted out of participating in improving Amazon Lex.
#
# POST /bots/{botId}/aggregatedutterances/
# operationId: ListAggregatedUtterances
export def "list-aggregated-utterances" [
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
  aggregation_duration: record # Provides parameters for setting the time window and duration for aggregating utterance data. — shape: {relativeAggregationDuration?: record}
  --sort-by: record # Specifies attributes for sorting a list of utterances. — shape: {attribute?: "HitCount"|"MissedCount", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the utterances in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "Utterance", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of utterances to return in each page of results. If there are fewer results than the maximum page size, only the actual number of results are returned. If you don't specify the maxResults parameter, 1,000 results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListAggregatedUtterances operation contains more results that specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botId: string, botAliasId: string, botVersion: string, localeId: string, aggregationDuration: record<relativeAggregationDuration: record<timeDimension: string, timeValue: int>>, aggregationWindowStartTime: string, aggregationWindowEndTime: string, aggregationLastRefreshedDateTime: string, aggregatedUtterancesSummaries: table<utterance: string, hitCount: int, missedCount: int, utteranceFirstRecordedInAggregationDuration: string, utteranceLastRecordedInAggregationDuration: string, containsDataFromDeletedResources: bool>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id)} | format pattern "/bots/{bot_id}/aggregatedutterances/") $qp $auth.query)
  let req_body = {"botAliasId": $bot_alias_id, "botVersion": $bot_version, "localeId": $locale_id, "aggregationDuration": $aggregation_duration, "sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list of bot recommendations that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# operationId: ListBotRecommendations
export def "list-bot-recommendations" [
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
  --body-max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBotRecommendation operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationSummaries: table<botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, lastUpdatedDateTime: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/") $qp $auth.query)
  let req_body = {"maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Use this to provide your transcript data, and to start the bot recommendation process.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/
# operationId: StartBotRecommendation
export def "start-bot-recommendation" [
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
  transcript_source_setting: record # Indicates the setting of the location where the transcript is stored. — shape: {s3BucketTranscriptSource?: record}
  --encryption-setting: record # The object representing the passwords that were used to encrypt the data related to the bot recommendation, as well as the KMS key ARN used to encrypt the associated metadata. — shape: {kmsKeyArn?: string, botLocaleExportPassword?: string, associatedTranscriptsPassword?: string}
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string, creationDateTime: string, transcriptSourceSetting: record<s3BucketTranscriptSource: record<s3BucketName: string, pathFormat: record, transcriptFormat: string, transcriptFilter: record, kmsKeyArn: string>>, encryptionSetting: record<kmsKeyArn: string, botLocaleExportPassword: string, associatedTranscriptsPassword: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/") $auth.query)
  let req_body = {"transcriptSourceSetting": $transcript_source_setting, "encryptionSetting": $encryption_setting} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets a list of built-in intents provided by Amazon Lex that you can use in your bot. To use a built-in intent as a the base for your own intent, include the built-in intent signature in the parentIntentSignature parameter when you call the CreateIntent operation. For more information, see CreateIntent (https://docs.aws.amazon.com/lexv2/latest/APIReference/API_CreateIntent.html).
#
# POST /builtins/locales/{localeId}/intents/
# operationId: ListBuiltInIntents
export def "list-built-in-intents" [
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
  --sort-by: record # Specifies attributes for sorting a list of built-in intents. — shape: {attribute?: "IntentSignature", order?: "Ascending"|"Descending"}
  --body-max-results: int # The maximum number of built-in intents to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBuiltInIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<builtInIntentSummaries: table<intentSignature: string, description: string>, nextToken: string, localeId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/builtins/locales/{locale_id}/intents/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of built-in slot types that meet the specified criteria.
#
# POST /builtins/locales/{localeId}/slottypes/
# operationId: ListBuiltInSlotTypes
export def "list-built-in-slot-types" [
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
  --sort-by: record # Specifies attributes for sorting a list of built-in slot types. — shape: {attribute?: "SlotTypeSignature", order?: "Ascending"|"Descending"}
  --body-max-results: int # The maximum number of built-in slot types to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListBuiltInSlotTypes operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
]: any -> oneof<record<builtInSlotTypeSummaries: table<slotTypeSignature: string, description: string>, nextToken: string, localeId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/builtins/locales/{locale_id}/slottypes/") $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Paginated list of custom vocabulary items for a given bot locale's custom vocabulary.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/customvocabulary/DEFAULT/list
# operationId: ListCustomVocabularyItems
export def "list-custom-vocabulary-items" [
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
  --body-max-results: int # The maximum number of items returned by the list operation. (spec name: maxResults)
  --body-next-token: string # The nextToken identifier to the list custom vocabulary request. (spec name: nextToken)
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, customVocabularyItems: table<itemId: string, phrase: string, weight: int, displayAs: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/customvocabulary/DEFAULT/list") $qp $auth.query)
  let req_body = {"maxResults": $body_max_results, "nextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the imports for a bot, bot locale, or custom vocabulary. Imports are kept in the list for 7 days.
#
# POST /imports/
# operationId: ListImports
export def "list-imports" [
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
  --sort-by: record # Provides information for sorting a list of imports. — shape: {attribute?: "LastUpdatedDateTime", order?: "Ascending"|"Descending"}
  --filters: list # Provides the specification of a filter used to limit the bots in the response to only those that match the filter specification. You can only specify one filter and one string to filter on. — item shape: {name: "ImportResourceType", values: list<string>, operator: "CO"|"EQ"}
  --body-max-results: int # The maximum number of imports to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
  --body-next-token: string # If the response from the ListImports operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use the returned token in the nextToken parameter of a ListImports request to return the next page of results. For a complete set of results, call the ListImports operation until the nextToken returned in the response is null. (spec name: nextToken)
  --locale-id: string # Specifies the locale that should be present in the list. If you don't specify a resource type in the filters parameter, the list contains both bot locales and custom vocabularies.
]: any -> oneof<record<botId: string, botVersion: string, importSummaries: table<importId: string, importedResourceId: string, importedResourceName: string, importStatus: string, mergeStrategy: string, creationDateTime: string, lastUpdatedDateTime: string, importedResourceType: string>, nextToken: string, localeId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/imports/" $qp $auth.query)
  let req_body = {"botId": $bot_id, "botVersion": $bot_version, "sortBy": $sort_by, "filters": $filters, "maxResults": $body_max_results, "nextToken": $body_next_token, "localeId": $locale_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Starts importing a bot, bot locale, or custom vocabulary from a zip archive that you uploaded to an S3 bucket.
#
# PUT /imports/
# operationId: StartImport
export def "start-import" [
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
  resource_specification: record # Provides information about the bot or bot locale that you want to import. You can specify the botImportSpecification or the botLocaleImportSpecification, but not both. — shape: {botImportSpecification?: record, botLocaleImportSpecification?: record, customVocabularyImportSpecification?: record}
  merge_strategy: string@merge-strategy-completer # The strategy to use when there is a name conflict between the imported resource and an existing resource. When the merge strategy is FailOnConflict existing resources are not overwritten and the import fails.
  --file-password: string # The password used to encrypt the zip archive that contains the resource definition. You should always encrypt the zip archive to protect it during transit between your site and Amazon Lex. (format: password)
]: any -> oneof<record<importId: string, resourceSpecification: record<botImportSpecification: record<botName: string, roleArn: string, dataPrivacy: record, idleSessionTTLInSeconds: int, botTags: record, testBotAliasTags: record>, botLocaleImportSpecification: record<botId: string, botVersion: string, localeId: string, nluIntentConfidenceThreshold: float, voiceSettings: record>, customVocabularyImportSpecification: record<botId: string, botVersion: string, localeId: string>>, mergeStrategy: string, importStatus: string, creationDateTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/" $auth.query)
  let req_body = {"importId": $import_id, "resourceSpecification": $resource_specification, "mergeStrategy": $merge_strategy, "filePassword": $file_password} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets a list of recommended intents provided by the bot recommendation that you can use in your bot. Intents in the response are ordered by relevance.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/intents
# operationId: ListRecommendedIntents
export def "list-recommended-intents" [
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
  --body-next-token: string # If the response from the ListRecommendedIntents operation contains more results than specified in the maxResults parameter, a token is returned in the response. Use that token in the nextToken parameter to return the next page of results. (spec name: nextToken)
  --body-max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned. (spec name: maxResults)
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationId: string, summaryList: table<intentId: string, intentName: string, sampleUtterancesCount: int>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/intents") $qp $auth.query)
  let req_body = {"nextToken": $body_next_token, "maxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of tags associated with a resource. Only bots, bot aliases, and bot channels can have tags associated with them.
#
# GET /tags/{resourceARN}
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
]: nothing -> oneof<record<tags: record>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceARN' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds the specified tags to the specified resource. If a tag key already exists, the existing value is replaced with the new value.
#
# POST /tags/{resourceARN}
# operationId: TagResource
export def "tag-resource" [
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
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceARN' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Search for associated transcripts that meet the specified criteria.
#
# POST /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/associatedtranscripts
# operationId: SearchAssociatedTranscripts
export def "search-associated-transcripts" [
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
  filters: list # A list of filter objects. — item shape: {name: "IntentId"|"SlotTypeId", values: list<string>}
  --max-results: int # The maximum number of bot recommendations to return in each page of results. If there are fewer results than the max page size, only the actual number of results are returned.
  --next-index: int # If the response from the SearchAssociatedTranscriptsRequest operation contains more results than specified in the maxResults parameter, an index is returned in the response. Use that index in the nextIndex parameter to return the next page of results.
]: any -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationId: string, nextIndex: int, associatedTranscripts: table<transcript: string>, totalResults: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/associatedtranscripts") $auth.query)
  let req_body = {"searchOrder": $search_order, "filters": $filters, "maxResults": $max_results, "nextIndex": $next_index} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Stop an already running Bot Recommendation request.
#
# PUT /bots/{botId}/botversions/{botVersion}/botlocales/{localeId}/botrecommendations/{botRecommendationId}/stopbotrecommendation
# operationId: StopBotRecommendation
export def "stop-bot-recommendation" [
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
]: nothing -> oneof<record<botId: string, botVersion: string, localeId: string, botRecommendationStatus: string, botRecommendationId: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_id | is-empty) { error make --unspanned { msg: "path parameter 'botId' must be non-empty" } }
  if ($bot_version | is-empty) { error make --unspanned { msg: "path parameter 'botVersion' must be non-empty" } }
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'localeId' must be non-empty" } }
  if ($bot_recommendation_id | is-empty) { error make --unspanned { msg: "path parameter 'botRecommendationId' must be non-empty" } }
  let full_url = (build-url $base ({bot_id: (encode-path-segment $bot_id), bot_version: (encode-path-segment $bot_version), locale_id: (encode-path-segment $locale_id), bot_recommendation_id: (encode-path-segment $bot_recommendation_id)} | format pattern "/bots/{bot_id}/botversions/{bot_version}/botlocales/{locale_id}/botrecommendations/{bot_recommendation_id}/stopbotrecommendation") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [202]
}

# Removes tags from a bot, bot alias, or bot channel.
#
# DELETE /tags/{resourceARN}
# operationId: UntagResource
export def "untag-resource" [
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
  --tag-keys: list # A list of tag keys to remove from the resource. If a tag key does not exist on the resource, it is ignored. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceARN' must be non-empty" } }
  if ($tag_keys == null) { error make --unspanned { msg: "required query parameter 'tagKeys' missing: pass --tag-keys" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"tagKeys": $tag_keys} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}
