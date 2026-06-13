# Auto-generated client for Google Docs API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/docs/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_DOCS_API_TOKEN

const BASE_URL = "https://docs.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_DOCS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://docs.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def suggestionsViewMode-completer [] { ["DEFAULT_FOR_CURRENT_ACCESS" "PREVIEW_SUGGESTIONS_ACCEPTED" "PREVIEW_WITHOUT_SUGGESTIONS" "SUGGESTIONS_INLINE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "documents docsdocumentscreate" } } | get name | first)
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
export def "documents docsdocumentscreate" [
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
  --body-body: record # The document body. The body typically contains the full document contents except for headers, footers, and footnotes. — shape: {content?: list}
  --documentId: string # Output only. The ID of the document.
  --documentStyle: record # The style of the document. — shape: {background?: record, defaultFooterId?: string, defaultHeaderId?: string, evenPageFooterId?: string, evenPageHeaderId?: string, firstPageFooterId?: string, firstPageHeaderId?: string, marginBottom?: record, marginFooter?: record, marginHeader?: record, marginLeft?: record, marginRight?: record, marginTop?: record, pageNumberStart?: int, pageSize?: record, useCustomHeaderFooterMargins?: bool, useEvenPageHeaderFooter?: bool, useFirstPageHeaderFooter?: bool}
  --footers: record # Output only. The footers in the document, keyed by footer ID.
  --footnotes: record # Output only. The footnotes in the document, keyed by footnote ID.
  --headers: record # Output only. The headers in the document, keyed by header ID.
  --inlineObjects: record # Output only. The inline objects in the document, keyed by object ID.
  --lists: record # Output only. The lists in the document, keyed by list ID.
  --namedRanges: record # Output only. The named ranges in the document, keyed by name.
  --namedStyles: record # The named styles. Paragraphs in the document can inherit their TextStyle and ParagraphStyle from these named styles. — shape: {styles?: list}
  --positionedObjects: record # Output only. The positioned objects in the document, keyed by object ID.
  --revisionId: string # Output only. The revision ID of the document. Can be used in update requests to specify which revision of a document to apply updates to and how the request should behave if the document has been edited since that revision. Only populated if the user has edit access to the document. The revision ID is not a sequential number but an opaque string. The format of the revision ID might change over time. A returned revision ID is only guaranteed to be valid for 24 hours after it has been returned and cannot be shared across users. If the revision ID is unchanged between calls, then the document has not changed. Conversely, a changed ID (for the same document and user) usually means the document has been updated. However, a changed ID can also be due to internal factors such as ID format changes.
  --suggestedDocumentStyleChanges: record # Output only. The suggested changes to the style of the document, keyed by suggestion ID.
  --suggestedNamedStylesChanges: record # Output only. The suggested changes to the named styles of the document, keyed by suggestion ID.
  --suggestionsViewMode: string@suggestionsViewMode-completer # Output only. The suggestions view mode applied to the document. Note: When editing a document, changes must be based on a document with SUGGESTIONS_INLINE.
  --title: string # The title of the document.
]: any -> record<body: record<content: list<record>>, documentId: string, documentStyle: record<background: record<color: record>, defaultFooterId: string, defaultHeaderId: string, evenPageFooterId: string, evenPageHeaderId: string, firstPageFooterId: string, firstPageHeaderId: string, marginBottom: record<magnitude: float, unit: string>, marginFooter: record<magnitude: float, unit: string>, marginHeader: record<magnitude: float, unit: string>, marginLeft: record<magnitude: float, unit: string>, marginRight: record<magnitude: float, unit: string>, marginTop: record<magnitude: float, unit: string>, pageNumberStart: int, pageSize: record<height: record, width: record>, useCustomHeaderFooterMargins: bool, useEvenPageHeaderFooter: bool, useFirstPageHeaderFooter: bool>, footers: record, footnotes: record, headers: record, inlineObjects: record, lists: record, namedRanges: record, namedStyles: record<styles: list<record>>, positionedObjects: record, revisionId: string, suggestedDocumentStyleChanges: record, suggestedNamedStylesChanges: record, suggestionsViewMode: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/documents" $qp)
  let body = {body: $body_body, documentId: $documentId, documentStyle: $documentStyle, footers: $footers, footnotes: $footnotes, headers: $headers, inlineObjects: $inlineObjects, lists: $lists, namedRanges: $namedRanges, namedStyles: $namedStyles, positionedObjects: $positionedObjects, revisionId: $revisionId, suggestedDocumentStyleChanges: $suggestedDocumentStyleChanges, suggestedNamedStylesChanges: $suggestedNamedStylesChanges, suggestionsViewMode: $suggestionsViewMode, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the latest version of the specified document.
#
# GET /v1/documents/{documentId}
# operationId: docs.documents.get
export def "documents docsdocumentsget" [
  documentId: string
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
  --suggestionsViewMode: string@suggestionsViewMode-completer # The suggestions view mode to apply to the document. This allows viewing the document with all suggestions inline, accepted or rejected. If one is not specified, DEFAULT_FOR_CURRENT_ACCESS is used.
]: nothing -> record<body: record<content: list<record>>, documentId: string, documentStyle: record<background: record<color: record>, defaultFooterId: string, defaultHeaderId: string, evenPageFooterId: string, evenPageHeaderId: string, firstPageFooterId: string, firstPageHeaderId: string, marginBottom: record<magnitude: float, unit: string>, marginFooter: record<magnitude: float, unit: string>, marginHeader: record<magnitude: float, unit: string>, marginLeft: record<magnitude: float, unit: string>, marginRight: record<magnitude: float, unit: string>, marginTop: record<magnitude: float, unit: string>, pageNumberStart: int, pageSize: record<height: record, width: record>, useCustomHeaderFooterMargins: bool, useEvenPageHeaderFooter: bool, useFirstPageHeaderFooter: bool>, footers: record, footnotes: record, headers: record, inlineObjects: record, lists: record, namedRanges: record, namedStyles: record<styles: list<record>>, positionedObjects: record, revisionId: string, suggestedDocumentStyleChanges: record, suggestedNamedStylesChanges: record, suggestionsViewMode: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "suggestionsViewMode" $suggestionsViewMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/documents/($documentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Applies one or more updates to the document. Each request is validated before being applied. If any request is not valid, then the entire request will fail and nothing will be applied. Some requests have replies to give you some information about how they are applied. Other requests do not need to return information; these each return an empty reply. The order of replies matches that of the requests. For example, suppose you call batchUpdate with four updates, and only the third one returns information. The response would have two empty replies, the reply to the third request, and another empty reply, in that order. Because other users may be editing the document, the document might not exactly reflect your changes: your changes may be altered with respect to collaborator changes. If there are no collaborators, the document should reflect your changes. In any case, the updates in your request are guaranteed to be applied together atomically.
#
# POST /v1/documents/{documentId}:batchUpdate
# operationId: docs.documents.batchUpdate
# --requests item shape: {createFooter?: record, createFootnote?: record, createHeader?: record, createNamedRange?: record, createParagraphBullets?: record, deleteContentRange?: record, deleteFooter?: record, deleteHeader?: record, deleteNamedRange?: record, deleteParagraphBullets?: record, deletePositionedObject?: record, deleteTableColumn?: record, deleteTableRow?: record, insertInlineImage?: record, insertPageBreak?: record, insertSectionBreak?: record, insertTable?: record, insertTableColumn?: record, insertTableRow?: record, insertText?: record, mergeTableCells?: record, pinTableHeaderRows?: record, replaceAllText?: record, replaceImage?: record, replaceNamedRangeContent?: record, unmergeTableCells?: record, updateDocumentStyle?: record, updateParagraphStyle?: record, updateSectionStyle?: record, updateTableCellStyle?: record, updateTableColumnProperties?: record, updateTableRowStyle?: record, updateTextStyle?: record}
# --writeControl shape: {requiredRevisionId?: string, targetRevisionId?: string}
export def "documents docsdocumentsbatchUpdate" [
  documentId: string
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
  --requests: list # A list of updates to apply to the document. — item shape: {createFooter?: record, createFootnote?: record, createHeader?: record, createNamedRange?: record, createParagraphBullets?: record, deleteContentRange?: record, deleteFooter?: record, deleteHeader?: record, deleteNamedRange?: record, deleteParagraphBullets?: record, deletePositionedObject?: record, deleteTableColumn?: record, deleteTableRow?: record, insertInlineImage?: record, insertPageBreak?: record, insertSectionBreak?: record, insertTable?: record, insertTableColumn?: record, insertTableRow?: record, insertText?: record, mergeTableCells?: record, pinTableHeaderRows?: record, replaceAllText?: record, replaceImage?: record, replaceNamedRangeContent?: record, unmergeTableCells?: record, updateDocumentStyle?: record, updateParagraphStyle?: record, updateSectionStyle?: record, updateTableCellStyle?: record, updateTableColumnProperties?: record, updateTableRowStyle?: record, updateTextStyle?: record}
  --writeControl: record # Provides control over how write requests are executed. — shape: {requiredRevisionId?: string, targetRevisionId?: string}
]: any -> record<documentId: string, replies: table<createFooter: record, createFootnote: record, createHeader: record, createNamedRange: record, insertInlineImage: record, insertInlineSheetsChart: record, replaceAllText: record>, writeControl: record<requiredRevisionId: string, targetRevisionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/documents/($documentId):batchUpdate" $qp)
  let body = {requests: $requests, writeControl: $writeControl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
