# Auto-generated client for Amazon Lex Model Building Service v2017-04-19
# Source: https://api.apis.guru/v2/specs/amazonaws.com/lex-models/2017-04-19/openapi.json
# Auth: --token flag or $env.AMAZON_LEX_MODEL_BUILDING_SERVICE_TOKEN

const BASE_URL = "http://models.lex.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LEX_MODEL_BUILDING_SERVICE_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
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

def base-url-completer [] { ["http://models.lex.us-east-1.amazonaws.com" "http://models.lex.us-east-2.amazonaws.com" "http://models.lex.us-west-1.amazonaws.com" "http://models.lex.us-west-2.amazonaws.com" "http://models.lex.us-gov-west-1.amazonaws.com" "http://models.lex.us-gov-east-1.amazonaws.com" "http://models.lex.ca-central-1.amazonaws.com" "http://models.lex.eu-north-1.amazonaws.com" "http://models.lex.eu-west-1.amazonaws.com" "http://models.lex.eu-west-2.amazonaws.com" "http://models.lex.eu-west-3.amazonaws.com" "http://models.lex.eu-central-1.amazonaws.com" "http://models.lex.eu-south-1.amazonaws.com" "http://models.lex.af-south-1.amazonaws.com" "http://models.lex.ap-northeast-1.amazonaws.com" "http://models.lex.ap-northeast-2.amazonaws.com" "http://models.lex.ap-northeast-3.amazonaws.com" "http://models.lex.ap-southeast-1.amazonaws.com" "http://models.lex.ap-southeast-2.amazonaws.com" "http://models.lex.ap-east-1.amazonaws.com" "http://models.lex.ap-south-1.amazonaws.com" "http://models.lex.sa-east-1.amazonaws.com" "http://models.lex.me-south-1.amazonaws.com" "https://models.lex.us-east-1.amazonaws.com" "https://models.lex.us-east-2.amazonaws.com" "https://models.lex.us-west-1.amazonaws.com" "https://models.lex.us-west-2.amazonaws.com" "https://models.lex.us-gov-west-1.amazonaws.com" "https://models.lex.us-gov-east-1.amazonaws.com" "https://models.lex.ca-central-1.amazonaws.com" "https://models.lex.eu-north-1.amazonaws.com" "https://models.lex.eu-west-1.amazonaws.com" "https://models.lex.eu-west-2.amazonaws.com" "https://models.lex.eu-west-3.amazonaws.com" "https://models.lex.eu-central-1.amazonaws.com" "https://models.lex.eu-south-1.amazonaws.com" "https://models.lex.af-south-1.amazonaws.com" "https://models.lex.ap-northeast-1.amazonaws.com" "https://models.lex.ap-northeast-2.amazonaws.com" "https://models.lex.ap-northeast-3.amazonaws.com" "https://models.lex.ap-southeast-1.amazonaws.com" "https://models.lex.ap-southeast-2.amazonaws.com" "https://models.lex.ap-east-1.amazonaws.com" "https://models.lex.ap-south-1.amazonaws.com" "https://models.lex.sa-east-1.amazonaws.com" "https://models.lex.me-south-1.amazonaws.com" "http://models.lex.cn-north-1.amazonaws.com.cn" "http://models.lex.cn-northwest-1.amazonaws.com.cn" "https://models.lex.cn-north-1.amazonaws.com.cn" "https://models.lex.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def locale-completer [] { ["de-DE" "en-AU" "en-GB" "en-IN" "en-US" "es-419" "es-ES" "es-US" "fr-CA" "fr-FR" "it-IT" "ja-JP" "ko-KR"] }
def resource-type-completer [] { ["BOT" "INTENT" "SLOT_TYPE"] }
def export-type-completer [] { ["ALEXA_SKILLS_KIT" "LEX"] }
def sort-by-attribute-completer [] { ["MIGRATION_DATE_TIME" "V1_BOT_NAME"] }
def sort-by-order-completer [] { ["ASCENDING" "DESCENDING"] }
def migration-status-equals-completer [] { ["COMPLETED" "FAILED" "IN_PROGRESS"] }
def migration-strategy-completer [] { ["CREATE_NEW" "UPDATE_EXISTING"] }
def status-type-completer [] { ["Detected" "Missed"] }
def view-completer [] { ["aggregation"] }
def process-behavior-completer [] { ["BUILD" "SAVE"] }
def value-selection-strategy-completer [] { ["ORIGINAL_VALUE" "TOP_RESOLUTION"] }
def merge-strategy-completer [] { ["FAIL_ON_CONFLICT" "OVERWRITE_LATEST"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bots-versions create" } } | get name | first)
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

# Creates a new version of the bot based on the $LATEST version. If the $LATEST version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version. You can update only the $LATEST version of the bot. You can't update the numbered versions that you create with the CreateBotVersion operation. When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see versioning-intro. This operation requires permission for the lex:CreateBotVersion action.
#
# POST /bots/{name}/versions
# operationId: CreateBotVersion
export def "bots-versions create" [
  name: string
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
  --checksum: string # Identifies a specific revision of the $LATEST version of the bot. If you specify a checksum and the $LATEST version of the bot has a different checksum, a PreconditionFailedException exception is returned and Amazon Lex doesn't publish a new version. If you don't specify a checksum, Amazon Lex publishes the $LATEST version.
]: any -> record<name: record, description: record, intents: record, clarificationPrompt: record<messages: record, maxAttempts: record, responseCard: record>, abortStatement: record<messages: record, responseCard: record>, status: record, failureReason: record, lastUpdatedDate: record, createdDate: record, idleSessionTTLInSeconds: record, voiceId: record, checksum: record, version: record, locale: record, childDirected: record, enableModelImprovements: record, detectSentiment: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/bots/{name}/versions") $auth.query)
  let req_body = {"checksum": $checksum} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Creates a new version of an intent based on the $LATEST version of the intent. If the $LATEST version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created. You can update only the $LATEST version of the intent. You can't update the numbered versions that you create with the CreateIntentVersion operation. When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see versioning-intro. This operation requires permissions to perform the lex:CreateIntentVersion action.
#
# POST /intents/{name}/versions
# operationId: CreateIntentVersion
export def "intents-versions create" [
  name: string
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
  --checksum: string # Checksum of the $LATEST version of the intent that should be used to create the new version. If you specify a checksum and the $LATEST version of the intent has a different checksum, Amazon Lex returns a PreconditionFailedException exception and doesn't publish a new version. If you don't specify a checksum, Amazon Lex publishes the $LATEST version.
]: any -> record<name: record, description: record, slots: record, sampleUtterances: record, confirmationPrompt: record<messages: record, maxAttempts: record, responseCard: record>, rejectionStatement: record<messages: record, responseCard: record>, followUpPrompt: record<prompt: record<messages: record, maxAttempts: record, responseCard: record>, rejectionStatement: record<messages: record, responseCard: record>>, conclusionStatement: record<messages: record, responseCard: record>, dialogCodeHook: record<uri: record, messageVersion: record>, fulfillmentActivity: record<type: record, codeHook: record<uri: record, messageVersion: record>>, parentIntentSignature: record, lastUpdatedDate: record, createdDate: record, version: record, checksum: record, kendraConfiguration: record<kendraIndex: record, queryFilterString: record, role: record>, inputContexts: record, outputContexts: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/intents/{name}/versions") $auth.query)
  let req_body = {"checksum": $checksum} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Creates a new version of a slot type based on the $LATEST version of the specified slot type. If the $LATEST version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. You can update only the $LATEST version of a slot type. You can't update the numbered versions that you create with the CreateSlotTypeVersion operation. When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see versioning-intro. This operation requires permissions for the lex:CreateSlotTypeVersion action.
#
# POST /slottypes/{name}/versions
# operationId: CreateSlotTypeVersion
export def "slottypes-versions create-slot-type" [
  name: string
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
  --checksum: string # Checksum for the $LATEST version of the slot type that you want to publish. If you specify a checksum and the $LATEST version of the slot type has a different checksum, Amazon Lex returns a PreconditionFailedException exception and doesn't publish the new version. If you don't specify a checksum, Amazon Lex publishes the $LATEST version.
]: any -> record<name: record, description: record, enumerationValues: record, lastUpdatedDate: record, createdDate: record, version: record, checksum: record, valueSelectionStrategy: record, parentSlotTypeSignature: record, slotTypeConfigurations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/slottypes/{name}/versions") $auth.query)
  let req_body = {"checksum": $checksum} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Deletes all versions of the bot, including the $LATEST version. To delete a specific version of the bot, use the DeleteBotVersion operation. The DeleteBot operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later. Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the DeleteUtterances operation. If a bot has an alias, you can't delete it. Instead, the DeleteBot operation returns a ResourceInUseException exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the DeleteBot operation is successful. This operation requires permissions for the lex:DeleteBot action.
#
# DELETE /bots/{name}
# operationId: DeleteBot
export def "bots delete" [
  name: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/bots/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes an alias for the specified bot. You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the DeleteBot operation returns a ResourceInUseException exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the DeleteBotAlias operation is successful.
#
# DELETE /bots/{botName}/aliases/{name}
# operationId: DeleteBotAlias
export def "bots-aliases delete-alias" [
  bot_name: string
  name: string
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
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), name: (encode-path-segment $name)} | format pattern "/bots/{bot_name}/aliases/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns information about an Amazon Lex bot alias. For more information about aliases, see versioning-aliases. This operation requires permissions for the lex:GetBotAlias action.
#
# GET /bots/{botName}/aliases/{name}
# operationId: GetBotAlias
export def "bots-aliases get-alias" [
  bot_name: string
  name: string
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
]: nothing -> record<name: record, description: record, botVersion: record, botName: record, lastUpdatedDate: record, createdDate: record, checksum: record, conversationLogs: record<logSettings: record, iamRoleArn: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), name: (encode-path-segment $name)} | format pattern "/bots/{bot_name}/aliases/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see versioning-aliases. This operation requires permissions for the lex:PutBotAlias action.
#
# PUT /bots/{botName}/aliases/{name}
# operationId: PutBotAlias
# --conversationLogs shape: {logSettings?: any, iamRoleArn?: any}
# --tags item shape: {key: any, value: any}
export def "bots-aliases update-alias" [
  bot_name: string
  name: string
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
  --description: string # A description of the alias.
  bot_version: string # The version of the bot.
  --checksum: string # Identifies a specific revision of the $LATEST version. When you create a new bot alias, leave the checksum field blank. If you specify a checksum you get a BadRequestException exception. When you want to update a bot alias, set the checksum field to the checksum of the most recent revision of the $LATEST version. If you don't specify the checksum field, or if the checksum does not match the $LATEST version, you get a PreconditionFailedException exception.
  --conversation-logs: record # Provides the settings needed for conversation logs. — shape: {logSettings?: any, iamRoleArn?: any}
  --tags: list # A list of tags to add to the bot alias. You can only add tags when you create an alias, you can't use the PutBotAlias operation to update the tags on a bot alias. To update tags, use the TagResource operation. — item shape: {key: any, value: any}
]: any -> record<name: record, description: record, botVersion: record, botName: record, lastUpdatedDate: record, createdDate: record, checksum: record, conversationLogs: record<logSettings: record, iamRoleArn: record>, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), name: (encode-path-segment $name)} | format pattern "/bots/{bot_name}/aliases/{name}") $auth.query)
  let req_body = {"description": $description, "botVersion": $bot_version, "checksum": $checksum, "conversationLogs": $conversation_logs, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the association between an Amazon Lex bot and a messaging platform. This operation requires permission for the lex:DeleteBotChannelAssociation action.
#
# DELETE /bots/{botName}/aliases/{aliasName}/channels/{name}
# operationId: DeleteBotChannelAssociation
export def "bots-aliases-channels delete-association" [
  bot_name: string
  alias_name: string
  name: string
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
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($alias_name | is-empty) { error make --unspanned { msg: "path parameter 'aliasName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), alias_name: (encode-path-segment $alias_name), name: (encode-path-segment $name)} | format pattern "/bots/{bot_name}/aliases/{alias_name}/channels/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns information about the association between an Amazon Lex bot and a messaging platform. This operation requires permissions for the lex:GetBotChannelAssociation action.
#
# GET /bots/{botName}/aliases/{aliasName}/channels/{name}
# operationId: GetBotChannelAssociation
export def "bots-aliases-channels get-association" [
  bot_name: string
  alias_name: string
  name: string
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
]: nothing -> record<name: record, description: record, botAlias: record, botName: record, createdDate: record, type: record, botConfiguration: record, status: record, failureReason: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($alias_name | is-empty) { error make --unspanned { msg: "path parameter 'aliasName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), alias_name: (encode-path-segment $alias_name), name: (encode-path-segment $name)} | format pattern "/bots/{bot_name}/aliases/{alias_name}/channels/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a specific version of a bot. To delete all versions of a bot, use the DeleteBot operation. This operation requires permissions for the lex:DeleteBotVersion action.
#
# DELETE /bots/{name}/versions/{version}
# operationId: DeleteBotVersion
export def "bots-versions delete" [
  name: string
  version: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/bots/{name}/versions/{version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes all versions of the intent, including the $LATEST version. To delete a specific version of the intent, use the DeleteIntentVersion operation. You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see how-it-works), you must remove those references first. If you get the ResourceInUseException exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to DeleteIntent is successful. This operation requires permission for the lex:DeleteIntent action.
#
# DELETE /intents/{name}
# operationId: DeleteIntent
export def "intents delete" [
  name: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/intents/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a specific version of an intent. To delete all versions of a intent, use the DeleteIntent operation. This operation requires permissions for the lex:DeleteIntentVersion action.
#
# DELETE /intents/{name}/versions/{version}
# operationId: DeleteIntentVersion
export def "intents-versions delete" [
  name: string
  version: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/intents/{name}/versions/{version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns information about an intent. In addition to the intent name, you must specify the intent version. This operation requires permissions to perform the lex:GetIntent action.
#
# GET /intents/{name}/versions/{version}
# operationId: GetIntent
export def "intents-versions get" [
  name: string
  version: string
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
]: nothing -> record<name: record, description: record, slots: record, sampleUtterances: record, confirmationPrompt: record<messages: record, maxAttempts: record, responseCard: record>, rejectionStatement: record<messages: record, responseCard: record>, followUpPrompt: record<prompt: record<messages: record, maxAttempts: record, responseCard: record>, rejectionStatement: record<messages: record, responseCard: record>>, conclusionStatement: record<messages: record, responseCard: record>, dialogCodeHook: record<uri: record, messageVersion: record>, fulfillmentActivity: record<type: record, codeHook: record<uri: record, messageVersion: record>>, parentIntentSignature: record, lastUpdatedDate: record, createdDate: record, version: record, checksum: record, kendraConfiguration: record<kendraIndex: record, queryFilterString: record, role: record>, inputContexts: record, outputContexts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/intents/{name}/versions/{version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes all versions of the slot type, including the $LATEST version. To delete a specific version of the slot type, use the DeleteSlotTypeVersion operation. You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. If you get the ResourceInUseException exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the DeleteSlotType call is successful. This operation requires permission for the lex:DeleteSlotType action.
#
# DELETE /slottypes/{name}
# operationId: DeleteSlotType
export def "slottypes delete-slot-type" [
  name: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/slottypes/{name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a specific version of a slot type. To delete all versions of a slot type, use the DeleteSlotType operation. This operation requires permissions for the lex:DeleteSlotTypeVersion action.
#
# DELETE /slottypes/{name}/version/{version}
# operationId: DeleteSlotTypeVersion
export def "slottypes-version delete-slot-type" [
  name: string
  version: string
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/slottypes/{name}/version/{version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes stored utterances. Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the GetUtterancesView operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input. Use the DeleteUtterances operation to manually delete stored utterances for a specific user. When you use the DeleteUtterances operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the GetUtterancesView operation are deleted after 15 days. This operation requires permissions for the lex:DeleteUtterances action.
#
# DELETE /bots/{botName}/utterances/{userId}
# operationId: DeleteUtterances
export def "bots-utterances delete" [
  bot_name: string
  user_id: string
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
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), user_id: (encode-path-segment $user_id)} | format pattern "/bots/{bot_name}/utterances/{user_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. This operation requires permissions for the lex:GetBot action.
#
# GET /bots/{name}/versions/{versionoralias}
# operationId: GetBot
export def "bots-versions get" [
  name: string
  versionoralias: string
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
]: nothing -> record<name: record, description: record, intents: record, enableModelImprovements: record, nluIntentConfidenceThreshold: record, clarificationPrompt: record<messages: record, maxAttempts: record, responseCard: record>, abortStatement: record<messages: record, responseCard: record>, status: record, failureReason: record, lastUpdatedDate: record, createdDate: record, idleSessionTTLInSeconds: record, voiceId: record, checksum: record, version: record, locale: record, childDirected: record, detectSentiment: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($versionoralias | is-empty) { error make --unspanned { msg: "path parameter 'versionoralias' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), versionoralias: (encode-path-segment $versionoralias)} | format pattern "/bots/{name}/versions/{versionoralias}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of aliases for a specified Amazon Lex bot. This operation requires permissions for the lex:GetBotAliases action.
#
# GET /bots/{botName}/aliases/
# operationId: GetBotAliases
export def "bots-aliases get" [
  bot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request.
  --max-results: int # The maximum number of aliases to return in the response. The default is 50. .
  --name-contains: string # Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<BotAliases: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nameContains" $name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name)} | format pattern "/bots/{bot_name}/aliases/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results, "nameContains": $name_contains} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of all of the channels associated with the specified bot. The GetBotChannelAssociations operation requires permissions for the lex:GetBotChannelAssociations action.
#
# GET /bots/{botName}/aliases/{aliasName}/channels/
# operationId: GetBotChannelAssociations
export def "bots-aliases-channels get-associations" [
  bot_name: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request.
  --max-results: int # The maximum number of associations to return in the response. The default is 50.
  --name-contains: string # Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the nameContains parameter.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<botChannelAssociations: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bot_name | is-empty) { error make --unspanned { msg: "path parameter 'botName' must be non-empty" } }
  if ($alias_name | is-empty) { error make --unspanned { msg: "path parameter 'aliasName' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nameContains" $name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bot_name: (encode-path-segment $bot_name), alias_name: (encode-path-segment $alias_name)} | format pattern "/bots/{bot_name}/aliases/{alias_name}/channels/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results, "nameContains": $name_contains} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about all of the versions of a bot. The GetBotVersions operation returns a BotMetadata object for each version of a bot. For example, if a bot has three numbered versions, the GetBotVersions operation returns four BotMetadata objects in the response, one for each numbered version and one for the $LATEST version. The GetBotVersions operation always returns at least one version, the $LATEST version. This operation requires permissions for the lex:GetBotVersions action.
#
# GET /bots/{name}/versions/
# operationId: GetBotVersions
export def "bots-versions list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request.
  --max-results: int # The maximum number of bot versions to return in the response. The default is 10.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<bots: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/bots/{name}/versions/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns bot information as follows: If you provide the nameContains field, the response includes information for the $LATEST version of all bots whose name contains the specified string. If you don't specify the nameContains field, the operation returns information about the $LATEST version of all of your bots. This operation requires permission for the lex:GetBots action.
#
# GET /bots/
# operationId: GetBots
export def "bots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request.
  --max-results: int # The maximum number of bots to return in the response that the request will return. The default is 10.
  --name-contains: string # Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<bots: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nameContains" $name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bots/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results, "nameContains": $name_contains} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about a built-in intent. This operation requires permission for the lex:GetBuiltinIntent action.
#
# GET /builtins/intents/{signature}
# operationId: GetBuiltinIntent
export def "builtins-intents get" [
  signature: string
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
]: nothing -> record<signature: record, supportedLocales: record, slots: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($signature | is-empty) { error make --unspanned { msg: "path parameter 'signature' must be non-empty" } }
  let full_url = (build-url $base ({signature: (encode-path-segment $signature)} | format pattern "/builtins/intents/{signature}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets a list of built-in intents that meet the specified criteria. This operation requires permission for the lex:GetBuiltinIntents action.
#
# GET /builtins/intents/
# operationId: GetBuiltinIntents
export def "builtins-intents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string@locale-completer # A list of locales that the intent supports.
  --signature-contains: string # Substring to match in built-in intent signatures. An intent will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To find the signature for an intent, see Standard Built-in Intents (https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents) in the Alexa Skills Kit.
  --next-token: string # A pagination token that fetches the next page of intents. If this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, use the pagination token in the next request.
  --max-results: int # The maximum number of intents to return in the response. The default is 10.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<intents: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "signatureContains" $signature_contains "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/builtins/intents/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale": $locale, "signatureContains": $signature_contains, "nextToken": $next_token, "maxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of built-in slot types that meet the specified criteria. For a list of built-in slot types, see Slot Type Reference (https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference) in the Alexa Skills Kit. This operation requires permission for the lex:GetBuiltInSlotTypes action.
#
# GET /builtins/slottypes/
# operationId: GetBuiltinSlotTypes
export def "builtins-slottypes get-slot-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string@locale-completer # A list of locales that the slot type supports.
  --signature-contains: string # Substring to match in built-in slot type signatures. A slot type will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  --next-token: string # A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of slot types, specify the pagination token in the next request.
  --max-results: int # The maximum number of slot types to return in the response. The default is 10.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<slotTypes: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "signatureContains" $signature_contains "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/builtins/slottypes/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale": $locale, "signatureContains": $signature_contains, "nextToken": $next_token, "maxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exports the contents of a Amazon Lex resource in a specified format.
#
# GET /exports/
# operationId: GetExport
export def "exports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the bot to export.
  --version: string # The version of the bot to export.
  --resource-type: string@resource-type-completer # The type of resource to export.
  --export-type: string@export-type-completer # The format of the exported data.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<name: record, version: record, resourceType: record, exportType: record, exportStatus: record, failureReason: record, url: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "resourceType" $resource_type "scalar") (serialize-qp "exportType" $export_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exports/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "version": $version, "resourceType": $resource_type, "exportType": $export_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about an import job started with the StartImport operation.
#
# GET /imports/{importId}
# operationId: GetImport
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
]: nothing -> record<name: record, resourceType: record, mergeStrategy: record, importId: record, importStatus: record, failureReason: record, createdDate: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($import_id | is-empty) { error make --unspanned { msg: "path parameter 'importId' must be non-empty" } }
  let full_url = (build-url $base ({import_id: (encode-path-segment $import_id)} | format pattern "/imports/{import_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets information about all of the versions of an intent. The GetIntentVersions operation returns an IntentMetadata object for each version of an intent. For example, if an intent has three numbered versions, the GetIntentVersions operation returns four IntentMetadata objects in the response, one for each numbered version and one for the $LATEST version. The GetIntentVersions operation always returns at least one version, the $LATEST version. This operation requires permissions for the lex:GetIntentVersions action.
#
# GET /intents/{name}/versions/
# operationId: GetIntentVersions
export def "intents-versions list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request.
  --max-results: int # The maximum number of intent versions to return in the response. The default is 10.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<intents: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/intents/{name}/versions/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns intent information as follows: If you specify the nameContains field, returns the $LATEST version of all intents that contain the specified string. If you don't specify the nameContains field, returns information about the $LATEST version of all intents. The operation requires permission for the lex:GetIntents action.
#
# GET /intents/
# operationId: GetIntents
export def "intents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request.
  --max-results: int # The maximum number of intents to return in the response. The default is 10.
  --name-contains: string # Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<intents: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nameContains" $name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/intents/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results, "nameContains": $name_contains} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provides details about an ongoing or complete migration from an Amazon Lex V1 bot to an Amazon Lex V2 bot. Use this operation to view the migration alerts and warnings related to the migration.
#
# GET /migrations/{migrationId}
# operationId: GetMigration
export def "migrations get" [
  migration_id: string
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
]: nothing -> record<migrationId: record, v1BotName: record, v1BotVersion: record, v1BotLocale: record, v2BotId: record, v2BotRole: record, migrationStatus: record, migrationStrategy: record, migrationTimestamp: record, alerts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($migration_id | is-empty) { error make --unspanned { msg: "path parameter 'migrationId' must be non-empty" } }
  let full_url = (build-url $base ({migration_id: (encode-path-segment $migration_id)} | format pattern "/migrations/{migration_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets a list of migrations between Amazon Lex V1 and Amazon Lex V2.
#
# GET /migrations
# operationId: GetMigrations
export def "migrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by-attribute: string@sort-by-attribute-completer # The field to sort the list of migrations by. You can sort by the Amazon Lex V1 bot name or the date and time that the migration was started.
  --sort-by-order: string@sort-by-order-completer # The order so sort the list.
  --v1-bot-name-contains: string # Filters the list to contain only bots whose name contains the specified string. The string is matched anywhere in bot name.
  --migration-status-equals: string@migration-status-equals-completer # Filters the list to contain only migrations in the specified state.
  --max-results: int # The maximum number of migrations to return in the response. The default is 10.
  --next-token: string # A pagination token that fetches the next page of migrations. If the response to this operation is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of migrations, specify the pagination token in the request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<migrationSummaries: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortByAttribute" $sort_by_attribute "scalar") (serialize-qp "sortByOrder" $sort_by_order "scalar") (serialize-qp "v1BotNameContains" $v1_bot_name_contains "scalar") (serialize-qp "migrationStatusEquals" $migration_status_equals "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/migrations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sortByAttribute": $sort_by_attribute, "sortByOrder": $sort_by_order, "v1BotNameContains": $v1_bot_name_contains, "migrationStatusEquals": $migration_status_equals, "maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Starts migrating a bot from Amazon Lex V1 to Amazon Lex V2. Migrate your bot when you want to take advantage of the new features of Amazon Lex V2. For more information, see Migrating a bot (https://docs.aws.amazon.com/lex/latest/dg/migrate.html) in the Amazon Lex developer guide.
#
# POST /migrations
# operationId: StartMigration
export def "migrations start" [
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
  v1_bot_name: string # The name of the Amazon Lex V1 bot that you are migrating to Amazon Lex V2.
  v1_bot_version: string # The version of the bot to migrate to Amazon Lex V2. You can migrate the $LATEST version as well as any numbered version.
  v2_bot_name: string # The name of the Amazon Lex V2 bot that you are migrating the Amazon Lex V1 bot to. If the Amazon Lex V2 bot doesn't exist, you must use the CREATE_NEW migration strategy. If the Amazon Lex V2 bot exists, you must use the UPDATE_EXISTING migration strategy to change the contents of the Amazon Lex V2 bot.
  v2_bot_role: string # The IAM role that Amazon Lex uses to run the Amazon Lex V2 bot.
  migration_strategy: string@migration-strategy-completer # The strategy used to conduct the migration. CREATE_NEW - Creates a new Amazon Lex V2 bot and migrates the Amazon Lex V1 bot to the new bot. UPDATE_EXISTING - Overwrites the existing Amazon Lex V2 bot metadata and the locale being migrated. It doesn't change any other locales in the Amazon Lex V2 bot. If the locale doesn't exist, a new locale is created in the Amazon Lex V2 bot.
]: any -> record<v1BotName: record, v1BotVersion: record, v1BotLocale: record, v2BotId: record, v2BotRole: record, migrationId: record, migrationStrategy: record, migrationTimestamp: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/migrations" $auth.query)
  let req_body = {"v1BotName": $v1_bot_name, "v1BotVersion": $v1_bot_version, "v2BotName": $v2_bot_name, "v2BotRole": $v2_bot_role, "migrationStrategy": $migration_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version. This operation requires permissions for the lex:GetSlotType action.
#
# GET /slottypes/{name}/versions/{version}
# operationId: GetSlotType
export def "slottypes-versions get-slot-type" [
  name: string
  version: string
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
]: nothing -> record<name: record, description: record, enumerationValues: record, lastUpdatedDate: record, createdDate: record, version: record, checksum: record, valueSelectionStrategy: record, parentSlotTypeSignature: record, slotTypeConfigurations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/slottypes/{name}/versions/{version}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets information about all versions of a slot type. The GetSlotTypeVersions operation returns a SlotTypeMetadata object for each version of a slot type. For example, if a slot type has three numbered versions, the GetSlotTypeVersions operation returns four SlotTypeMetadata objects in the response, one for each numbered version and one for the $LATEST version. The GetSlotTypeVersions operation always returns at least one version, the $LATEST version. This operation requires permissions for the lex:GetSlotTypeVersions action.
#
# GET /slottypes/{name}/versions/
# operationId: GetSlotTypeVersions
export def "slottypes-versions list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request.
  --max-results: int # The maximum number of slot type versions to return in the response. The default is 10.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<slotTypes: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/slottypes/{name}/versions/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns slot type information as follows: If you specify the nameContains field, returns the $LATEST version of all slot types that contain the specified string. If you don't specify the nameContains field, returns information about the $LATEST version of all slot types. The operation requires permission for the lex:GetSlotTypes action.
#
# GET /slottypes/
# operationId: GetSlotTypes
export def "slottypes get-slot-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  --max-results: int # The maximum number of slot types to return in the response. The default is 10.
  --name-contains: string # Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<slotTypes: record, nextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nameContains" $name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/slottypes/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nextToken": $next_token, "maxResults": $max_results, "nameContains": $name_contains} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use the GetUtterancesView operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to. For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the GetUtterancesView operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the OrderFlowers intent so that your bot recognizes that utterance. After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version. If you set childDirected field to true when you created your bot, if you are using slot obfuscation with one or more slots, or if you opted out of participating in improving Amazon Lex, utterances are not available. This operation requires permissions for the lex:GetUtterancesView action.
#
# GET /bots/{botname}/utterances
# operationId: GetUtterancesView
export def "bots-utterances get-view" [
  botname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bot-versions: list # An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  --status-type: string@status-type-completer # To return utterances that were recognized and handled, use Detected. To return utterances that were not recognized, use Missed.
  --view: string@view-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<botName: record, utterances: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($botname | is-empty) { error make --unspanned { msg: "path parameter 'botname' must be non-empty" } }
  let qp = [(serialize-qp "bot_versions" $bot_versions "multi") (serialize-qp "status_type" $status_type "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({botname: (encode-path-segment $botname)} | format pattern "/bots/{botname}/utterances") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"bot_versions": $bot_versions, "status_type": $status_type, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of tags associated with the specified resource. Only bots, bot aliases, and bot channels can have tags associated with them.
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
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
# POST /tags/{resourceArn}
# operationId: TagResource
# --tags item shape: {key: any, value: any}
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
  tags: list # A list of tag keys to add to the resource. If a tag key already exists, the existing value is replaced with the new value. — item shape: {key: any, value: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the response FAILED. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see how-it-works. If you specify the name of an existing bot, the fields in the request replace the existing values in the $LATEST version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the idleTTLInSeconds and privacySettings fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception. This operation requires permissions for the lex:PutBot action. For more information, see security-iam.
#
# PUT /bots/{name}/versions/$LATEST
# operationId: PutBot
# --intents item shape: {intentName: any, intentVersion: any}
# --clarificationPrompt shape: {messages?: any, maxAttempts?: any, responseCard?: any}
# --abortStatement shape: {messages?: any, responseCard?: any}
# --tags item shape: {key: any, value: any}
export def "bots-versions-latest update" [
  name: string
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
  --description: string # A description of the bot.
  --intents: list # An array of Intent objects. Each intent represents a command that a user can express. For example, a pizza ordering bot might support an OrderPizza intent. For more information, see how-it-works. — item shape: {intentName: any, intentVersion: any}
  --enable-model-improvements: oneof<nothing, bool> # Set to true to enable access to natural language understanding improvements. When you set the enableModelImprovements parameter to true you can use the nluIntentConfidenceThreshold parameter to configure confidence scores. For more information, see Confidence Scores (https://docs.aws.amazon.com/lex/latest/dg/confidence-scores.html). You can only set the enableModelImprovements parameter in certain Regions. If you set the parameter to true, your bot has access to accuracy improvements. The Regions where you can set the enableModelImprovements parameter to true are: US East (N. Virginia) (us-east-1) US West (Oregon) (us-west-2) Asia Pacific (Sydney) (ap-southeast-2) EU (Ireland) (eu-west-1) In other Regions, the enableModelImprovements parameter is set to true by default. In these Regions setting the parameter to false throws a ValidationException exception.
  --nlu-intent-confidence-threshold: float # Determines the threshold where Amazon Lex will insert the AMAZON.FallbackIntent, AMAZON.KendraSearchIntent, or both when returning alternative intents in a PostContent (https://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html) or PostText (https://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html) response. AMAZON.FallbackIntent and AMAZON.KendraSearchIntent are only inserted if they are configured for the bot. You must set the enableModelImprovements parameter to true to use confidence scores in the following regions. US East (N. Virginia) (us-east-1) US West (Oregon) (us-west-2) Asia Pacific (Sydney) (ap-southeast-2) EU (Ireland) (eu-west-1) In other Regions, the enableModelImprovements parameter is set to true by default. For example, suppose a bot is configured with the confidence threshold of 0.80 and the AMAZON.FallbackIntent. Amazon Lex returns three alternative intents with the following confidence scores: IntentA (0.70), IntentB (0.60), IntentC (0.50). The response from the PostText operation would be: AMAZON.FallbackIntent IntentA IntentB IntentC (format: double)
  --clarification-prompt: record # Obtains information from the user. To define a prompt, provide one or more messages and specify the number of attempts to get information from the user. If you provide more than one message, Amazon Lex chooses one of the messages to use to prompt the user. For more information, see how-it-works. — shape: {messages?: any, maxAttempts?: any, responseCard?: any}
  --abort-statement: record # A collection of messages that convey information to the user. At runtime, Amazon Lex selects the message to convey. — shape: {messages?: any, responseCard?: any}
  --idle-session-ttl-in-seconds: int # The maximum time in seconds that Amazon Lex retains the data gathered in a conversation. A user interaction session remains active for the amount of time specified. If no conversation occurs during this time, the session expires and Amazon Lex deletes any data provided before the timeout. For example, suppose that a user chooses the OrderPizza intent, but gets sidetracked halfway through placing an order. If the user doesn't complete the order within the specified time, Amazon Lex discards the slot information that it gathered, and the user must start over. If you don't include the idleSessionTTLInSeconds element in a PutBot operation request, Amazon Lex uses the default value. This is also true if the request replaces an existing bot. The default is 300 seconds (5 minutes).
  --voice-id: string # The Amazon Polly voice ID that you want Amazon Lex to use for voice interactions with the user. The locale configured for the voice must match the locale of the bot. For more information, see Voices in Amazon Polly (https://docs.aws.amazon.com/polly/latest/dg/voicelist.html) in the Amazon Polly Developer Guide.
  --checksum: string # Identifies a specific revision of the $LATEST version. When you create a new bot, leave the checksum field blank. If you specify a checksum you get a BadRequestException exception. When you want to update a bot, set the checksum field to the checksum of the most recent revision of the $LATEST version. If you don't specify the checksum field, or if the checksum does not match the $LATEST version, you get a PreconditionFailedException exception.
  --process-behavior: string@process-behavior-completer # If you set the processBehavior element to BUILD, Amazon Lex builds the bot so that it can be run. If you set the element to SAVE Amazon Lex saves the bot, but doesn't build it. If you don't specify this value, the default value is BUILD.
  locale: string@locale-completer # Specifies the target locale for the bot. Any intent used in the bot must be compatible with the locale of the bot. The default is en-US.
  --child-directed: oneof<nothing, bool> # For each Amazon Lex bot created with the Amazon Lex Model Building Service, you must specify whether your use of Amazon Lex is related to a website, program, or other application that is directed or targeted, in whole or in part, to children under age 13 and subject to the Children's Online Privacy Protection Act (COPPA) by specifying true or false in the childDirected field. By specifying true in the childDirected field, you confirm that your use of Amazon Lex is related to a website, program, or other application that is directed or targeted, in whole or in part, to children under age 13 and subject to COPPA. By specifying false in the childDirected field, you confirm that your use of Amazon Lex is not related to a website, program, or other application that is directed or targeted, in whole or in part, to children under age 13 and subject to COPPA. You may not specify a default value for the childDirected field that does not accurately reflect whether your use of Amazon Lex is related to a website, program, or other application that is directed or targeted, in whole or in part, to children under age 13 and subject to COPPA. If your use of Amazon Lex relates to a website, program, or other application that is directed in whole or in part, to children under age 13, you must obtain any required verifiable parental consent under COPPA. For information regarding the use of Amazon Lex in connection with websites, programs, or other applications that are directed or targeted, in whole or in part, to children under age 13, see the Amazon Lex FAQ. (https://aws.amazon.com/lex/faqs#data-security)
  --detect-sentiment: oneof<nothing, bool> # When set to true user utterances are sent to Amazon Comprehend for sentiment analysis. If you don't specify detectSentiment, the default is false.
  --create-version: oneof<nothing, bool> # When set to true a new numbered version of the bot is created. This is the same as calling the CreateBotVersion operation. If you don't specify createVersion, the default is false.
  --tags: list # A list of tags to add to the bot. You can only add tags when you create a bot, you can't use the PutBot operation to update the tags on a bot. To update tags, use the TagResource operation. — item shape: {key: any, value: any}
]: any -> record<name: record, description: record, intents: record, enableModelImprovements: record, nluIntentConfidenceThreshold: record, clarificationPrompt: record<messages: record, maxAttempts: record, responseCard: record>, abortStatement: record<messages: record, responseCard: record>, status: record, failureReason: record, lastUpdatedDate: record, createdDate: record, idleSessionTTLInSeconds: record, voiceId: record, checksum: record, version: record, locale: record, childDirected: record, createVersion: record, detectSentiment: record, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/bots/{name}/versions/$LATEST") $auth.query)
  let req_body = {"description": $description, "intents": $intents, "enableModelImprovements": $enable_model_improvements, "nluIntentConfidenceThreshold": $nlu_intent_confidence_threshold, "clarificationPrompt": $clarification_prompt, "abortStatement": $abort_statement, "idleSessionTTLInSeconds": $idle_session_ttl_in_seconds, "voiceId": $voice_id, "checksum": $checksum, "processBehavior": $process_behavior, "locale": $locale, "childDirected": $child_directed, "detectSentiment": $detect_sentiment, "createVersion": $create_version, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an intent or replaces an existing intent. To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an OrderPizza intent. To create an intent or replace an existing intent, you must provide the following: Intent name. For example, OrderPizza. Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza." Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza. How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. You can specify other optional information in the request, such as: A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?" A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order." A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?" If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the $LATEST version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the $LATEST version of an intent, the status field of any bot that uses the $LATEST version of the intent is set to NOT_BUILT. For more information, see how-it-works. This operation requires permissions for the lex:PutIntent action.
#
# PUT /intents/{name}/versions/$LATEST
# operationId: PutIntent
# --slots item shape: {name: any, description?: any, slotConstraint: any, slotType?: any, slotTypeVersion?: any, valueElicitationPrompt?: any, priority?: any, sampleUtterances?: any, responseCard?: any, obfuscationSetting?: any, defaultValueSpec?: any}
# --confirmationPrompt shape: {messages?: any, maxAttempts?: any, responseCard?: any}
# --rejectionStatement shape: {messages?: any, responseCard?: any}
# --followUpPrompt shape: {prompt?: any, rejectionStatement?: any}
# --conclusionStatement shape: {messages?: any, responseCard?: any}
# --dialogCodeHook shape: {uri?: any, messageVersion?: any}
# --fulfillmentActivity shape: {type?: any, codeHook?: any}
# --kendraConfiguration shape: {kendraIndex?: any, queryFilterString?: any, role?: any}
# --inputContexts item shape: {name: any}
# --outputContexts item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
export def "intents-versions-latest update" [
  name: string
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
  --description: string # A description of the intent.
  --slots: list # An array of intent slots. At runtime, Amazon Lex elicits required slot values from the user using prompts defined in the slots. For more information, see how-it-works. — item shape: {name: any, description?: any, slotConstraint: any, slotType?: any, slotTypeVersion?: any, valueElicitationPrompt?: any, priority?: any, sampleUtterances?: any, responseCard?: any, obfuscationSetting?: any, defaultValueSpec?: any}
  --sample-utterances: list<string> # An array of utterances (strings) that a user might say to signal the intent. For example, "I want {PizzaSize} pizza", "Order {Quantity} {PizzaSize} pizzas". In each utterance, a slot name is enclosed in curly braces.
  --confirmation-prompt: record # Obtains information from the user. To define a prompt, provide one or more messages and specify the number of attempts to get information from the user. If you provide more than one message, Amazon Lex chooses one of the messages to use to prompt the user. For more information, see how-it-works. — shape: {messages?: any, maxAttempts?: any, responseCard?: any}
  --rejection-statement: record # A collection of messages that convey information to the user. At runtime, Amazon Lex selects the message to convey. — shape: {messages?: any, responseCard?: any}
  --follow-up-prompt: record # A prompt for additional activity after an intent is fulfilled. For example, after the OrderPizza intent is fulfilled, you might prompt the user to find out whether the user wants to order drinks. — shape: {prompt?: any, rejectionStatement?: any}
  --conclusion-statement: record # A collection of messages that convey information to the user. At runtime, Amazon Lex selects the message to convey. — shape: {messages?: any, responseCard?: any}
  --dialog-code-hook: record # Specifies a Lambda function that verifies requests to a bot or fulfills the user's request to a bot.. — shape: {uri?: any, messageVersion?: any}
  --fulfillment-activity: record # Describes how the intent is fulfilled after the user provides all of the information required for the intent. You can provide a Lambda function to process the intent, or you can return the intent information to the client application. We recommend that you use a Lambda function so that the relevant logic lives in the Cloud and limit the client-side code primarily to presentation. If you need to update the logic, you only update the Lambda function; you don't need to upgrade your client application. Consider the following examples: In a pizza ordering application, after the user provides all of the information for placing an order, you use a Lambda function to place an order with a pizzeria. In a gaming application, when a user says "pick up a rock," this information must go back to the client application so that it can perform the operation and update the graphics. In this case, you want Amazon Lex to return the intent data to the client. — shape: {type?: any, codeHook?: any}
  --parent-intent-signature: string # A unique identifier for the built-in intent to base this intent on. To find the signature for an intent, see Standard Built-in Intents (https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents) in the Alexa Skills Kit.
  --checksum: string # Identifies a specific revision of the $LATEST version. When you create a new intent, leave the checksum field blank. If you specify a checksum you get a BadRequestException exception. When you want to update a intent, set the checksum field to the checksum of the most recent revision of the $LATEST version. If you don't specify the checksum field, or if the checksum does not match the $LATEST version, you get a PreconditionFailedException exception.
  --create-version: oneof<nothing, bool> # When set to true a new numbered version of the intent is created. This is the same as calling the CreateIntentVersion operation. If you do not specify createVersion, the default is false.
  --kendra-configuration: record # Provides configuration information for the AMAZON.KendraSearchIntent intent. When you use this intent, Amazon Lex searches the specified Amazon Kendra index and returns documents from the index that match the user's utterance. For more information, see AMAZON.KendraSearchIntent (http://docs.aws.amazon.com/lex/latest/dg/built-in-intent-kendra-search.html). — shape: {kendraIndex?: any, queryFilterString?: any, role?: any}
  --input-contexts: list # An array of InputContext objects that lists the contexts that must be active for Amazon Lex to choose the intent in a conversation with the user. — item shape: {name: any}
  --output-contexts: list # An array of OutputContext objects that lists the contexts that the intent activates when the intent is fulfilled. — item shape: {name: any, timeToLiveInSeconds: any, turnsToLive: any}
]: any -> record<name: record, description: record, slots: record, sampleUtterances: record, confirmationPrompt: record<messages: record, maxAttempts: record, responseCard: record>, rejectionStatement: record<messages: record, responseCard: record>, followUpPrompt: record<prompt: record<messages: record, maxAttempts: record, responseCard: record>, rejectionStatement: record<messages: record, responseCard: record>>, conclusionStatement: record<messages: record, responseCard: record>, dialogCodeHook: record<uri: record, messageVersion: record>, fulfillmentActivity: record<type: record, codeHook: record<uri: record, messageVersion: record>>, parentIntentSignature: record, lastUpdatedDate: record, createdDate: record, version: record, checksum: record, createVersion: record, kendraConfiguration: record<kendraIndex: record, queryFilterString: record, role: record>, inputContexts: record, outputContexts: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/intents/{name}/versions/$LATEST") $auth.query)
  let req_body = {"description": $description, "slots": $slots, "sampleUtterances": $sample_utterances, "confirmationPrompt": $confirmation_prompt, "rejectionStatement": $rejection_statement, "followUpPrompt": $follow_up_prompt, "conclusionStatement": $conclusion_statement, "dialogCodeHook": $dialog_code_hook, "fulfillmentActivity": $fulfillment_activity, "parentIntentSignature": $parent_intent_signature, "checksum": $checksum, "createVersion": $create_version, "kendraConfiguration": $kendra_configuration, "inputContexts": $input_contexts, "outputContexts": $output_contexts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates a custom slot type or replaces an existing custom slot type. To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see how-it-works. If you specify the name of an existing slot type, the fields in the request replace the existing values in the $LATEST version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the $LATEST version of a slot type, if a bot uses the $LATEST version of an intent that contains the slot type, the bot's status field is set to NOT_BUILT. This operation requires permissions for the lex:PutSlotType action.
#
# PUT /slottypes/{name}/versions/$LATEST
# operationId: PutSlotType
# --enumerationValues item shape: {value: any, synonyms?: any}
# --slotTypeConfigurations item shape: {regexConfiguration?: any}
export def "slottypes-versions-latest update-slot-type" [
  name: string
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
  --description: string # A description of the slot type.
  --enumeration-values: list # A list of EnumerationValue objects that defines the values that the slot type can take. Each value can have a list of synonyms, which are additional values that help train the machine learning model about the values that it resolves for a slot. A regular expression slot type doesn't require enumeration values. All other slot types require a list of enumeration values. When Amazon Lex resolves a slot value, it generates a resolution list that contains up to five possible values for the slot. If you are using a Lambda function, this resolution list is passed to the function. If you are not using a Lambda function you can choose to return the value that the user entered or the first value in the resolution list as the slot value. The valueSelectionStrategy field indicates the option to use. — item shape: {value: any, synonyms?: any}
  --checksum: string # Identifies a specific revision of the $LATEST version. When you create a new slot type, leave the checksum field blank. If you specify a checksum you get a BadRequestException exception. When you want to update a slot type, set the checksum field to the checksum of the most recent revision of the $LATEST version. If you don't specify the checksum field, or if the checksum does not match the $LATEST version, you get a PreconditionFailedException exception.
  --value-selection-strategy: string@value-selection-strategy-completer # Determines the slot resolution strategy that Amazon Lex uses to return slot type values. The field can be set to one of the following values: ORIGINAL_VALUE - Returns the value entered by the user, if the user value is similar to the slot value. TOP_RESOLUTION - If there is a resolution list for the slot, return the first value in the resolution list as the slot type value. If there is no resolution list, null is returned. If you don't specify the valueSelectionStrategy, the default is ORIGINAL_VALUE.
  --create-version: oneof<nothing, bool> # When set to true a new numbered version of the slot type is created. This is the same as calling the CreateSlotTypeVersion operation. If you do not specify createVersion, the default is false.
  --parent-slot-type-signature: string # The built-in slot type used as the parent of the slot type. When you define a parent slot type, the new slot type has all of the same configuration as the parent. Only AMAZON.AlphaNumeric is supported.
  --slot-type-configurations: list # Configuration information that extends the parent built-in slot type. The configuration is added to the settings for the parent slot type. — item shape: {regexConfiguration?: any}
]: any -> record<name: record, description: record, enumerationValues: record, lastUpdatedDate: record, createdDate: record, version: record, checksum: record, valueSelectionStrategy: record, createVersion: record, parentSlotTypeSignature: record, slotTypeConfigurations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/slottypes/{name}/versions/$LATEST") $auth.query)
  let req_body = {"description": $description, "enumerationValues": $enumeration_values, "checksum": $checksum, "valueSelectionStrategy": $value_selection_strategy, "createVersion": $create_version, "parentSlotTypeSignature": $parent_slot_type_signature, "slotTypeConfigurations": $slot_type_configurations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Starts a job to import a resource to Amazon Lex.
#
# POST /imports/
# operationId: StartImport
# --tags item shape: {key: any, value: any}
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
  payload: string # A zip archive in binary format. The archive should contain one file, a JSON file containing the resource to import. The resource should match the type specified in the resourceType field.
  resource_type: string@resource-type-completer # Specifies the type of resource to export. Each resource also exports any resources that it depends on. A bot exports dependent intents. An intent exports dependent slot types.
  merge_strategy: string@merge-strategy-completer # Specifies the action that the StartImport operation should take when there is an existing resource with the same name. FAIL_ON_CONFLICT - The import operation is stopped on the first conflict between a resource in the import file and an existing resource. The name of the resource causing the conflict is in the failureReason field of the response to the GetImport operation. OVERWRITE_LATEST - The import operation proceeds even if there is a conflict with an existing resource. The $LASTEST version of the existing resource is overwritten with the data from the import file.
  --tags: list # A list of tags to add to the imported bot. You can only add tags when you import a bot, you can't add tags to an intent or slot type. — item shape: {key: any, value: any}
]: any -> record<name: record, resourceType: record, mergeStrategy: record, importId: record, importStatus: record, tags: record, createdDate: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports/" $auth.query)
  let req_body = {"payload": $payload, "resourceType": $resource_type, "mergeStrategy": $merge_strategy, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Removes tags from a bot, bot alias or bot channel.
#
# DELETE /tags/{resourceArn}
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'resourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}
