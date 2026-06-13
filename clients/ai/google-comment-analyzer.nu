# Auto-generated client for Perspective Comment Analyzer API vv1alpha1
# Source: https://api.apis.guru/v2/specs/googleapis.com/commentanalyzer/v1alpha1/openapi.json
# Auth: --token flag or $env.PERSPECTIVE_COMMENT_ANALYZER_API_TOKEN

const BASE_URL = "https://commentanalyzer.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PERSPECTIVE_COMMENT_ANALYZER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://commentanalyzer.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1alpha1-comments-analyze commentanalyzercommentsanalyze" } } | get name | first)
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

# Analyzes the provided text and returns scores for requested attributes.
#
# POST /v1alpha1/comments:analyze
# operationId: commentanalyzer.comments.analyze
# --comment shape: {text?: string, type?: "TEXT_TYPE_UNSPECIFIED"|"PLAIN_TEXT"|"HTML"}
# --context shape: {articleAndParentComment?: record, entries?: list}
export def "v1alpha1-comments-analyze commentanalyzercommentsanalyze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --clientToken: string # Opaque token that is echoed from the request to the response.
  --comment: record # Represents a body of text. — shape: {text?: string, type?: "TEXT_TYPE_UNSPECIFIED"|"PLAIN_TEXT"|"HTML"}
  --communityId: string # Optional identifier associating this AnalyzeCommentRequest with a particular client's community. Different communities may have different norms and rules. Specifying this value enables us to explore building community-specific models for clients.
  --context: record # Context is typically something that a Comment is referencing or replying to (such as an article, or previous comment). Note: Populate only ONE OF the following fields. The oneof syntax cannot be used because that would require nesting entries inside another message and breaking backwards compatibility. The server will return an error if more than one of the following fields is present. — shape: {articleAndParentComment?: record, entries?: list}
  --doNotStore: oneof<nothing, bool> # Do not store the comment or context sent in this request. By default, the service may store comments/context for debugging purposes.
  --dropUnsupportedAttributes: oneof<nothing, bool> # If specified, any requested attribute that is requested but not supported for the language detected will be dropped from the returned scores instead of returning an error.
  --languages: list # The language(s) of the comment and context. If none are specified, we attempt to automatically detect the language. Specifying multiple languages means the text contains multiple lanugages. Both ISO and BCP-47 language codes are accepted. The server returns an error if no language was specified and language detection fails. The server also returns an error if the languages (either specified by the caller, or auto-detected) are not *all* supported by the service.
  --requestedAttributes: record # Specification of requested attributes. The AttributeParameters serve as configuration for each associated attribute. The map keys are attribute names. The available attributes may be different on each RFE installation, and can be seen by calling ListAttributes (see above). For the prod installation, known as Perspective API, see https://developers.perspectiveapi.com/s/about-the-api-model-cards.
  --sessionId: string # Session ID. Used to join related RPCs into a single session. For example, an interactive tool that calls both the AnalyzeComment and SuggestCommentScore RPCs should set all invocations of both RPCs to the same Session ID, typically a random 64-bit integer.
  --spanAnnotations: oneof<nothing, bool> # An advisory parameter that will return span annotations if the model is capable of providing scores with sub-comment resolution. This will likely increase the size of the returned message.
]: any -> record<attributeScores: record, clientToken: string, detectedLanguages: list<string>, languages: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1alpha1/comments:analyze" $qp)
  let body = {clientToken: $clientToken, comment: $comment, communityId: $communityId, context: $context, doNotStore: $doNotStore, dropUnsupportedAttributes: $dropUnsupportedAttributes, languages: $languages, requestedAttributes: $requestedAttributes, sessionId: $sessionId, spanAnnotations: $spanAnnotations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Suggest comment scores as training data.
#
# POST /v1alpha1/comments:suggestscore
# operationId: commentanalyzer.comments.suggestscore
# --comment shape: {text?: string, type?: "TEXT_TYPE_UNSPECIFIED"|"PLAIN_TEXT"|"HTML"}
# --context shape: {articleAndParentComment?: record, entries?: list}
export def "v1alpha1-comments-suggestscore commentanalyzercommentssuggestscore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --attributeScores: record # Attribute scores for the comment. The map keys are attribute names, same as the requested_attribute field in AnalyzeCommentRequest (for example "ATTACK_ON_AUTHOR", "INFLAMMATORY", etc.). This field has the same type as the `attribute_scores` field in AnalyzeCommentResponse. To specify an overall attribute score for the entire comment as a whole, use the `summary_score` field of the mapped AttributeScores object. To specify scores on specific subparts of the comment, use the `span_scores` field. All SpanScore objects must have begin and end fields set. All Score objects must be explicitly set (for binary classification, use the score values 0 and 1). If Score objects don't include a ScoreType, `PROBABILITY` is assumed. `attribute_scores` must not be empty. The mapped AttributeScores objects also must not be empty. An `INVALID_ARGUMENT` error is returned for all malformed requests.
  --clientToken: string # Opaque token that is echoed from the request to the response.
  --comment: record # Represents a body of text. — shape: {text?: string, type?: "TEXT_TYPE_UNSPECIFIED"|"PLAIN_TEXT"|"HTML"}
  --communityId: string # Optional identifier associating this comment score suggestion with a particular sub-community. Different communities may have different norms and rules. Specifying this value enables training community-specific models.
  --context: record # Context is typically something that a Comment is referencing or replying to (such as an article, or previous comment). Note: Populate only ONE OF the following fields. The oneof syntax cannot be used because that would require nesting entries inside another message and breaking backwards compatibility. The server will return an error if more than one of the following fields is present. — shape: {articleAndParentComment?: record, entries?: list}
  --languages: list # The language(s) of the comment and context. If none are specified, we attempt to automatically detect the language. Both ISO and BCP-47 language codes are accepted.
  --sessionId: string # Session ID. Used to join related RPCs into a single session. For example, an interactive tool that calls both the AnalyzeComment and SuggestCommentScore RPCs should set all invocations of both RPCs to the same Session ID, typically a random 64-bit integer.
]: any -> record<clientToken: string, detectedLanguages: list<string>, requestedLanguages: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1alpha1/comments:suggestscore" $qp)
  let body = {attributeScores: $attributeScores, clientToken: $clientToken, comment: $comment, communityId: $communityId, context: $context, languages: $languages, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
