# Auto-generated client for Google Docs API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/docs/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_DOCS_API_TOKEN

const BASE_URL = "https://docs.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_DOCS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

def base-url-completer [] { ["https://docs.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def suggestions-view-mode-completer [] { ["DEFAULT_FOR_CURRENT_ACCESS" "PREVIEW_SUGGESTIONS_ACCEPTED" "PREVIEW_WITHOUT_SUGGESTIONS" "SUGGESTIONS_INLINE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "documents create" } } | get name | first)
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

# Creates a blank document using the title given in the request. Other fields in the request, including any provided content, are ignored. Returns the created document.
#
# POST /v1/documents
# operationId: docs.documents.create
# --body shape: {content?: list}
# --documentStyle shape: {background?: record, defaultFooterId?: string, defaultHeaderId?: string, evenPageFooterId?: string, evenPageHeaderId?: string, firstPageFooterId?: string, firstPageHeaderId?: string, marginBottom?: record, marginFooter?: record, marginHeader?: record, marginLeft?: record, marginRight?: record, marginTop?: record, pageNumberStart?: int, pageSize?: record, useCustomHeaderFooterMargins?: bool, useEvenPageHeaderFooter?: bool, useFirstPageHeaderFooter?: bool}
# --namedStyles shape: {styles?: list}
export def "documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record # The document body. The body typically contains the full document contents except for headers, footers, and footnotes. — shape: {content?: list}
  --document-id: string # Output only. The ID of the document.
  --document-style: record # The style of the document. — shape: {background?: record, defaultFooterId?: string, defaultHeaderId?: string, evenPageFooterId?: string, evenPageHeaderId?: string, firstPageFooterId?: string, firstPageHeaderId?: string, marginBottom?: record, marginFooter?: record, marginHeader?: record, marginLeft?: record, marginRight?: record, marginTop?: record, pageNumberStart?: int, pageSize?: record, useCustomHeaderFooterMargins?: bool, useEvenPageHeaderFooter?: bool, useFirstPageHeaderFooter?: bool}
  --footers: record # Output only. The footers in the document, keyed by footer ID.
  --footnotes: record # Output only. The footnotes in the document, keyed by footnote ID.
  --headers: record # Output only. The headers in the document, keyed by header ID.
  --inline-objects: record # Output only. The inline objects in the document, keyed by object ID.
  --lists: record # Output only. The lists in the document, keyed by list ID.
  --named-ranges: record # Output only. The named ranges in the document, keyed by name.
  --named-styles: record # The named styles. Paragraphs in the document can inherit their TextStyle and ParagraphStyle from these named styles. — shape: {styles?: list}
  --positioned-objects: record # Output only. The positioned objects in the document, keyed by object ID.
  --revision-id: string # Output only. The revision ID of the document. Can be used in update requests to specify which revision of a document to apply updates to and how the request should behave if the document has been edited since that revision. Only populated if the user has edit access to the document. The revision ID is not a sequential number but an opaque string. The format of the revision ID might change over time. A returned revision ID is only guaranteed to be valid for 24 hours after it has been returned and cannot be shared across users. If the revision ID is unchanged between calls, then the document has not changed. Conversely, a changed ID (for the same document and user) usually means the document has been updated. However, a changed ID can also be due to internal factors such as ID format changes.
  --suggested-document-style-changes: record # Output only. The suggested changes to the style of the document, keyed by suggestion ID.
  --suggested-named-styles-changes: record # Output only. The suggested changes to the named styles of the document, keyed by suggestion ID.
  --suggestions-view-mode: string@suggestions-view-mode-completer # Output only. The suggestions view mode applied to the document. Note: When editing a document, changes must be based on a document with SUGGESTIONS_INLINE.
  --title: string # The title of the document.
]: any -> record<body: record<content: list<record>>, documentId: string, documentStyle: record<background: record<color: record>, defaultFooterId: string, defaultHeaderId: string, evenPageFooterId: string, evenPageHeaderId: string, firstPageFooterId: string, firstPageHeaderId: string, marginBottom: record<magnitude: float, unit: string>, marginFooter: record<magnitude: float, unit: string>, marginHeader: record<magnitude: float, unit: string>, marginLeft: record<magnitude: float, unit: string>, marginRight: record<magnitude: float, unit: string>, marginTop: record<magnitude: float, unit: string>, pageNumberStart: int, pageSize: record<height: record, width: record>, useCustomHeaderFooterMargins: bool, useEvenPageHeaderFooter: bool, useFirstPageHeaderFooter: bool>, footers: record, footnotes: record, headers: record, inlineObjects: record, lists: record, namedRanges: record, namedStyles: record<styles: list<record>>, positionedObjects: record, revisionId: string, suggestedDocumentStyleChanges: record, suggestedNamedStylesChanges: record, suggestionsViewMode: string, title: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_DOCS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_DOCS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/documents" $qp $auth.query)
  let req_body = {"body": $body, "documentId": $document_id, "documentStyle": $document_style, "footers": $footers, "footnotes": $footnotes, "headers": $headers, "inlineObjects": $inline_objects, "lists": $lists, "namedRanges": $named_ranges, "namedStyles": $named_styles, "positionedObjects": $positioned_objects, "revisionId": $revision_id, "suggestedDocumentStyleChanges": $suggested_document_style_changes, "suggestedNamedStylesChanges": $suggested_named_styles_changes, "suggestionsViewMode": $suggestions_view_mode, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets the latest version of the specified document.
#
# GET /v1/documents/{documentId}
# operationId: docs.documents.get
export def "documents get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --suggestions-view-mode: string@suggestions-view-mode-completer # The suggestions view mode to apply to the document. This allows viewing the document with all suggestions inline, accepted or rejected. If one is not specified, DEFAULT_FOR_CURRENT_ACCESS is used.
]: nothing -> record<body: record<content: list<record>>, documentId: string, documentStyle: record<background: record<color: record>, defaultFooterId: string, defaultHeaderId: string, evenPageFooterId: string, evenPageHeaderId: string, firstPageFooterId: string, firstPageHeaderId: string, marginBottom: record<magnitude: float, unit: string>, marginFooter: record<magnitude: float, unit: string>, marginHeader: record<magnitude: float, unit: string>, marginLeft: record<magnitude: float, unit: string>, marginRight: record<magnitude: float, unit: string>, marginTop: record<magnitude: float, unit: string>, pageNumberStart: int, pageSize: record<height: record, width: record>, useCustomHeaderFooterMargins: bool, useEvenPageHeaderFooter: bool, useFirstPageHeaderFooter: bool>, footers: record, footnotes: record, headers: record, inlineObjects: record, lists: record, namedRanges: record, namedStyles: record<styles: list<record>>, positionedObjects: record, revisionId: string, suggestedDocumentStyleChanges: record, suggestedNamedStylesChanges: record, suggestionsViewMode: string, title: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_DOCS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_DOCS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "suggestionsViewMode" $suggestions_view_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/v1/documents/{document_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "suggestionsViewMode": $suggestions_view_mode} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Applies one or more updates to the document. Each request is validated before being applied. If any request is not valid, then the entire request will fail and nothing will be applied. Some requests have replies to give you some information about how they are applied. Other requests do not need to return information; these each return an empty reply. The order of replies matches that of the requests. For example, suppose you call batchUpdate with four updates, and only the third one returns information. The response would have two empty replies, the reply to the third request, and another empty reply, in that order. Because other users may be editing the document, the document might not exactly reflect your changes: your changes may be altered with respect to collaborator changes. If there are no collaborators, the document should reflect your changes. In any case, the updates in your request are guaranteed to be applied together atomically.
#
# POST /v1/documents/{documentId}:batchUpdate
# operationId: docs.documents.batchUpdate
# --requests item shape: {createFooter?: record, createFootnote?: record, createHeader?: record, createNamedRange?: record, createParagraphBullets?: record, deleteContentRange?: record, deleteFooter?: record, deleteHeader?: record, deleteNamedRange?: record, deleteParagraphBullets?: record, deletePositionedObject?: record, deleteTableColumn?: record, deleteTableRow?: record, insertInlineImage?: record, insertPageBreak?: record, insertSectionBreak?: record, insertTable?: record, insertTableColumn?: record, ... (15 more fields)}
# --writeControl shape: {requiredRevisionId?: string, targetRevisionId?: string}
export def "documents update-batch" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --requests: list # A list of updates to apply to the document. — item shape: {createFooter?: record, createFootnote?: record, createHeader?: record, createNamedRange?: record, createParagraphBullets?: record, deleteContentRange?: record, deleteFooter?: record, deleteHeader?: record, deleteNamedRange?: record, deleteParagraphBullets?: record, deletePositionedObject?: record, deleteTableColumn?: record, deleteTableRow?: record, insertInlineImage?: record, insertPageBreak?: record, insertSectionBreak?: record, insertTable?: record, insertTableColumn?: record, ... (15 more fields)}
  --write-control: record # Provides control over how write requests are executed. — shape: {requiredRevisionId?: string, targetRevisionId?: string}
]: any -> record<documentId: string, replies: table<createFooter: record, createFootnote: record, createHeader: record, createNamedRange: record, insertInlineImage: record, insertInlineSheetsChart: record, replaceAllText: record>, writeControl: record<requiredRevisionId: string, targetRevisionId: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_DOCS_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_DOCS_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/v1/documents/{document_id}:batchUpdate") $qp $auth.query)
  let req_body = {"requests": $requests, "writeControl": $write_control} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
