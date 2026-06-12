# Auto-generated client for Books API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/books/v1/openapi.json
# Auth: --token flag or $env.BOOKS_API_TOKEN

const BASE_URL = "https://books.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BOOKS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://books.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def licenseTypes-completer [] { ["BOTH" "CONCURRENT" "DOWNLOAD" "LICENSE_TYPES_UNDEFINED"] }
def reason-completer [] { ["IOS_PREX" "IOS_SEARCH" "ONBOARDING" "REASON_UNDEFINED"] }
def reason-completer-1 [] { ["ONBOARDING" "REASON_UNDEFINED"] }
def projection-completer [] { ["FULL" "LITE" "PROJECTION_UNDEFINED"] }
def action-completer [] { ["ACTION_UNDEFINED" "bookmark" "chapter" "next-page" "prev-page" "scroll" "search"] }
def maxAllowedMaturityRating-completer [] { ["MATURE" "MAX_ALLOWED_MATURITY_RATING_UNDEFINED" "not-mature"] }
def download-completer [] { ["DOWNLOAD_UNDEFINED" "EPUB"] }
def filter-completer [] { ["FILTER_UNDEFINED" "ebooks" "free-ebooks" "full" "paid-ebooks" "partial"] }
def libraryRestrict-completer [] { ["LIBRARY_RESTRICT_UNDEFINED" "my-library" "no-restrict"] }
def orderBy-completer [] { ["ORDER_BY_UNDEFINED" "newest" "relevance"] }
def printType-completer [] { ["ALL" "BOOKS" "MAGAZINES" "PRINT_TYPE_UNDEFINED"] }
def rating-completer [] { ["HAVE_IT" "NOT_INTERESTED" "RATING_UNDEFINED"] }
def association-completer [] { ["ASSOCIATION_UNDEFINED" "end-of-sample" "end-of-volume" "related-for-play"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "books-cloudloading-add-book bookscloudloadingaddBook" } } | get name | first)
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

# Add a user-upload volume and triggers processing.
#
# POST /books/v1/cloudloading/addBook
# operationId: books.cloudloading.addBook
export def "books-cloudloading-add-book bookscloudloadingaddBook" [
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
  --drive-document-id: string # A drive document id. The upload_client_token must not be set.
  --mime-type: string # The document MIME type. It can be set only if the drive_document_id is set.
  --name: string # The document name. It can be set only if the drive_document_id is set.
  --upload-client-token: string # Scotty upload token.
]: nothing -> record<author: string, processingState: string, title: string, volumeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "drive_document_id" $drive_document_id "scalar") (serialize-qp "mime_type" $mime_type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "upload_client_token" $upload_client_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/cloudloading/addBook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove the book and its contents
#
# POST /books/v1/cloudloading/deleteBook
# operationId: books.cloudloading.deleteBook
export def "books-cloudloading-delete-book bookscloudloadingdeleteBook" [
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
  --volumeId: string # The id of the book to be removed.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "volumeId" $volumeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/cloudloading/deleteBook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a user-upload volume.
#
# POST /books/v1/cloudloading/updateBook
# operationId: books.cloudloading.updateBook
export def "books-cloudloading-update-book bookscloudloadingupdateBook" [
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
  --author: string
  --processingState: string
  --title: string
  --volumeId: string
]: any -> record<author: string, processingState: string, title: string, volumeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/cloudloading/updateBook" $qp)
  let body = {author: $author, processingState: $processingState, title: $title, volumeId: $volumeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of offline dictionary metadata available
#
# GET /books/v1/dictionary/listOfflineMetadata
# operationId: books.dictionary.listOfflineMetadata
export def "books-dictionary-list-offline-metadata booksdictionarylistOfflineMetadata" [
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
  --cpksver: string # The device/version ID from which to request the data.
]: nothing -> record<items: table<download_url: string, encrypted_key: string, language: string, size: string, version: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "cpksver" $cpksver "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/dictionary/listOfflineMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information regarding the family that the user is part of.
#
# GET /books/v1/familysharing/getFamilyInfo
# operationId: books.familysharing.getFamilyInfo
export def "books-familysharing-get-family-info booksfamilysharinggetFamilyInfo" [
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<kind: string, membership: record<acquirePermission: string, ageGroup: string, allowedMaturityRating: string, isInFamily: bool, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/familysharing/getFamilyInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiates sharing of the content with the user's family. Empty response indicates success.
#
# POST /books/v1/familysharing/share
# operationId: books.familysharing.share
export def "books-familysharing-share booksfamilysharingshare" [
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
  --docId: string # The docid to share.
  --qp-source: string # String to identify the originator of this request.
  --volumeId: string # The volume to share.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "docId" $docId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "volumeId" $volumeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/familysharing/share" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiates revoking content that has already been shared with the user's family. Empty response indicates success.
#
# POST /books/v1/familysharing/unshare
# operationId: books.familysharing.unshare
export def "books-familysharing-unshare booksfamilysharingunshare" [
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
  --docId: string # The docid to unshare.
  --qp-source: string # String to identify the originator of this request.
  --volumeId: string # The volume to unshare.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "docId" $docId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "volumeId" $volumeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/familysharing/unshare" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the current settings for the user.
#
# GET /books/v1/myconfig/getUserSettings
# operationId: books.myconfig.getUserSettings
export def "books-myconfig-get-user-settings booksmyconfiggetUserSettings" [
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
  --country: string # Unused. Added only to workaround TEX mandatory request template requirement
]: nothing -> record<kind: string, notesExport: record<folderName: string, isEnabled: bool>, notification: record<matchMyInterests: record<opted_state: string>, moreFromAuthors: record<opted_state: string>, moreFromSeries: record<opted_state: string>, priceDrop: record<opted_state: string>, rewardExpirations: record<opted_state: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/myconfig/getUserSettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Release downloaded content access restriction.
#
# POST /books/v1/myconfig/releaseDownloadAccess
# operationId: books.myconfig.releaseDownloadAccess
export def "books-myconfig-release-download-access booksmyconfigreleaseDownloadAccess" [
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
  --cpksver: string # The device/version ID from which to release the restriction.
  --volumeIds: list # The volume(s) to release restrictions for.
  --locale: string # ISO-639-1, ISO-3166-1 codes for message localization, i.e. en_US.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<downloadAccessList: table<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "cpksver" $cpksver "scalar") (serialize-qp "volumeIds" $volumeIds "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/myconfig/releaseDownloadAccess" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request concurrent and download access restrictions.
#
# POST /books/v1/myconfig/requestAccess
# operationId: books.myconfig.requestAccess
export def "books-myconfig-request-access booksmyconfigrequestAccess" [
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
  --cpksver: string # The device/version ID from which to request the restrictions.
  --nonce: string # The client nonce value.
  --qp-source: string # String to identify the originator of this request.
  --volumeId: string # The volume to request concurrent/download restrictions for.
  --licenseTypes: string@licenseTypes-completer # The type of access license to request. If not specified, the default is BOTH.
  --locale: string # ISO-639-1, ISO-3166-1 codes for message localization, i.e. en_US.
]: nothing -> record<concurrentAccess: record<deviceAllowed: bool, kind: string, maxConcurrentDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, timeWindowSeconds: int, volumeId: string>, downloadAccess: record<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "cpksver" $cpksver "scalar") (serialize-qp "nonce" $nonce "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "volumeId" $volumeId "scalar") (serialize-qp "licenseTypes" $licenseTypes "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/myconfig/requestAccess" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request downloaded content access for specified volumes on the My eBooks shelf.
#
# POST /books/v1/myconfig/syncVolumeLicenses
# operationId: books.myconfig.syncVolumeLicenses
export def "books-myconfig-sync-volume-licenses booksmyconfigsyncVolumeLicenses" [
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
  --cpksver: string # The device/version ID from which to release the restriction.
  --nonce: string # The client nonce value.
  --qp-source: string # String to identify the originator of this request.
  --features: list # List of features supported by the client, i.e., 'RENTALS'
  --includeNonComicsSeries: oneof<nothing, bool> # Set to true to include non-comics series. Defaults to false.
  --locale: string # ISO-639-1, ISO-3166-1 codes for message localization, i.e. en_US.
  --showPreorders: oneof<nothing, bool> # Set to true to show pre-ordered books. Defaults to false.
  --volumeIds: list # The volume(s) to request download restrictions for.
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "cpksver" $cpksver "scalar") (serialize-qp "nonce" $nonce "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "features" $features "multi") (serialize-qp "includeNonComicsSeries" $includeNonComicsSeries "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "showPreorders" $showPreorders "scalar") (serialize-qp "volumeIds" $volumeIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/myconfig/syncVolumeLicenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the settings for the user. If a sub-object is specified, it will overwrite the existing sub-object stored in the server. Unspecified sub-objects will retain the existing value.
#
# POST /books/v1/myconfig/updateUserSettings
# operationId: books.myconfig.updateUserSettings
# --notesExport shape: {folderName?: string, isEnabled?: bool}
# --notification shape: {matchMyInterests?: record, moreFromAuthors?: record, moreFromSeries?: record, priceDrop?: record, rewardExpirations?: record}
export def "books-myconfig-update-user-settings booksmyconfigupdateUserSettings" [
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
  --kind: string # Resource type.
  --notesExport: record # User settings in sub-objects, each for different purposes. — shape: {folderName?: string, isEnabled?: bool}
  --notification: record # shape: {matchMyInterests?: record, moreFromAuthors?: record, moreFromSeries?: record, priceDrop?: record, rewardExpirations?: record}
]: any -> record<kind: string, notesExport: record<folderName: string, isEnabled: bool>, notification: record<matchMyInterests: record<opted_state: string>, moreFromAuthors: record<opted_state: string>, moreFromSeries: record<opted_state: string>, priceDrop: record<opted_state: string>, rewardExpirations: record<opted_state: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/myconfig/updateUserSettings" $qp)
  let body = {kind: $kind, notesExport: $notesExport, notification: $notification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of annotations, possibly filtered.
#
# GET /books/v1/mylibrary/annotations
# operationId: books.mylibrary.annotations.list
export def "books-mylibrary-annotations booksmylibraryannotationslist" [
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
  --contentVersion: string # The content version for the requested volume.
  --layerId: string # The layer ID to limit annotation by.
  --layerIds: list # The layer ID(s) to limit annotation by.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # The value of the nextToken from the previous page.
  --showDeleted: oneof<nothing, bool> # Set to true to return deleted annotations. updatedMin must be in the request to use this. Defaults to false.
  --qp-source: string # String to identify the originator of this request.
  --updatedMax: string # RFC 3339 timestamp to restrict to items updated prior to this timestamp (exclusive).
  --updatedMin: string # RFC 3339 timestamp to restrict to items updated since this timestamp (inclusive).
  --volumeId: string # The volume to restrict annotations to.
]: nothing -> record<items: table<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record, created: string, currentVersionRanges: record, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record, pageIds: list, selectedText: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "layerId" $layerId "scalar") (serialize-qp "layerIds" $layerIds "multi") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "showDeleted" $showDeleted "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "updatedMax" $updatedMax "scalar") (serialize-qp "updatedMin" $updatedMin "scalar") (serialize-qp "volumeId" $volumeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/mylibrary/annotations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new annotation.
#
# POST /books/v1/mylibrary/annotations
# operationId: books.mylibrary.annotations.insert
# --clientVersionRanges shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
# --currentVersionRanges shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
# --layerSummary shape: {allowedCharacterCount?: int, limitType?: string, remainingCharacterCount?: int}
export def "books-mylibrary-annotations booksmylibraryannotationsinsert" [
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
  --annotationId: string # The ID for the annotation to insert.
  --country: string # ISO-3166-1 code to override the IP-based location.
  --showOnlySummaryInResponse: oneof<nothing, bool> # Requests that only the summary of the specified layer be provided in the response.
  --qp-source: string # String to identify the originator of this request.
  --afterSelectedText: string # Anchor text after excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --beforeSelectedText: string # Anchor text before excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --clientVersionRanges: record # Selection ranges sent from the client. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --created: string # Timestamp for the created time of this annotation.
  --currentVersionRanges: record # Selection ranges for the most recent content version. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --data: string # User-created data for this annotation.
  --deleted: oneof<nothing, bool> # Indicates that this annotation is deleted.
  --highlightStyle: string # The highlight style for this annotation.
  --id: string # Id of this annotation, in the form of a GUID.
  --kind: string # Resource type.
  --layerId: string # The layer this annotation is for.
  --layerSummary: record # shape: {allowedCharacterCount?: int, limitType?: string, remainingCharacterCount?: int}
  --pageIds: list # Pages that this annotation spans.
  --selectedText: string # Excerpt from the volume.
  --selfLink: string # URL to this resource.
  --updated: string # Timestamp for the last time this annotation was modified.
  --volumeId: string # The volume that this annotation belongs to.
]: any -> record<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, created: string, currentVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int>, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "annotationId" $annotationId "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "showOnlySummaryInResponse" $showOnlySummaryInResponse "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/mylibrary/annotations" $qp)
  let body = {afterSelectedText: $afterSelectedText, beforeSelectedText: $beforeSelectedText, clientVersionRanges: $clientVersionRanges, created: $created, currentVersionRanges: $currentVersionRanges, data: $data, deleted: $deleted, highlightStyle: $highlightStyle, id: $id, kind: $kind, layerId: $layerId, layerSummary: $layerSummary, pageIds: $pageIds, selectedText: $selectedText, selfLink: $selfLink, updated: $updated, volumeId: $volumeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the summary of specified layers.
#
# POST /books/v1/mylibrary/annotations/summary
# operationId: books.mylibrary.annotations.summary
export def "books-mylibrary-annotations-summary booksmylibraryannotationssummary" [
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
  --layerIds: list # Array of layer IDs to get the summary for.
  --volumeId: string # Volume id to get the summary for.
]: nothing -> record<kind: string, layers: table<allowedCharacterCount: int, layerId: string, limitType: string, remainingCharacterCount: int, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "layerIds" $layerIds "multi") (serialize-qp "volumeId" $volumeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/mylibrary/annotations/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an annotation.
#
# DELETE /books/v1/mylibrary/annotations/{annotationId}
# operationId: books.mylibrary.annotations.delete
export def "books-mylibrary-annotations booksmylibraryannotationsdelete" [
  annotationId: string
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/annotations/($annotationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing annotation.
#
# PUT /books/v1/mylibrary/annotations/{annotationId}
# operationId: books.mylibrary.annotations.update
# --clientVersionRanges shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
# --currentVersionRanges shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
# --layerSummary shape: {allowedCharacterCount?: int, limitType?: string, remainingCharacterCount?: int}
export def "books-mylibrary-annotations booksmylibraryannotationsupdate" [
  annotationId: string
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
  --qp-source: string # String to identify the originator of this request.
  --afterSelectedText: string # Anchor text after excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --beforeSelectedText: string # Anchor text before excerpt. For requests, if the user bookmarked a screen that has no flowing text on it, then this field should be empty.
  --clientVersionRanges: record # Selection ranges sent from the client. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --created: string # Timestamp for the created time of this annotation.
  --currentVersionRanges: record # Selection ranges for the most recent content version. — shape: {cfiRange?: record, contentVersion?: string, gbImageRange?: record, gbTextRange?: record, imageCfiRange?: record}
  --data: string # User-created data for this annotation.
  --deleted: oneof<nothing, bool> # Indicates that this annotation is deleted.
  --highlightStyle: string # The highlight style for this annotation.
  --id: string # Id of this annotation, in the form of a GUID.
  --kind: string # Resource type.
  --layerId: string # The layer this annotation is for.
  --layerSummary: record # shape: {allowedCharacterCount?: int, limitType?: string, remainingCharacterCount?: int}
  --pageIds: list # Pages that this annotation spans.
  --selectedText: string # Excerpt from the volume.
  --selfLink: string # URL to this resource.
  --updated: string # Timestamp for the last time this annotation was modified.
  --volumeId: string # The volume that this annotation belongs to.
]: any -> record<afterSelectedText: string, beforeSelectedText: string, clientVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, created: string, currentVersionRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, imageCfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, highlightStyle: string, id: string, kind: string, layerId: string, layerSummary: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int>, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/annotations/($annotationId)" $qp)
  let body = {afterSelectedText: $afterSelectedText, beforeSelectedText: $beforeSelectedText, clientVersionRanges: $clientVersionRanges, created: $created, currentVersionRanges: $currentVersionRanges, data: $data, deleted: $deleted, highlightStyle: $highlightStyle, id: $id, kind: $kind, layerId: $layerId, layerSummary: $layerSummary, pageIds: $pageIds, selectedText: $selectedText, selfLink: $selfLink, updated: $updated, volumeId: $volumeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of bookshelves belonging to the authenticated user.
#
# GET /books/v1/mylibrary/bookshelves
# operationId: books.mylibrary.bookshelves.list
export def "books-mylibrary-bookshelves booksmylibrarybookshelveslist" [
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<items: table<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/mylibrary/bookshelves" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves metadata for a specific bookshelf belonging to the authenticated user.
#
# GET /books/v1/mylibrary/bookshelves/{shelf}
# operationId: books.mylibrary.bookshelves.get
export def "books-mylibrary-bookshelves booksmylibrarybookshelvesget" [
  shelf: string
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/bookshelves/($shelf)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a volume to a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/addVolume
# operationId: books.mylibrary.bookshelves.addVolume
export def "books-mylibrary-bookshelves-add-volume booksmylibrarybookshelvesaddVolume" [
  shelf: string
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
  --volumeId: string # ID of volume to add.
  --reason: string@reason-completer # The reason for which the book is added to the library.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "volumeId" $volumeId "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/bookshelves/($shelf)/addVolume" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clears all volumes from a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/clearVolumes
# operationId: books.mylibrary.bookshelves.clearVolumes
export def "books-mylibrary-bookshelves-clear-volumes booksmylibrarybookshelvesclearVolumes" [
  shelf: string
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/bookshelves/($shelf)/clearVolumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moves a volume within a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/moveVolume
# operationId: books.mylibrary.bookshelves.moveVolume
export def "books-mylibrary-bookshelves-move-volume booksmylibrarybookshelvesmoveVolume" [
  shelf: string
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
  --volumeId: string # ID of volume to move.
  --volumePosition: int # Position on shelf to move the item (0 puts the item before the current first item, 1 puts it between the first and the second and so on.)
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "volumeId" $volumeId "scalar") (serialize-qp "volumePosition" $volumePosition "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/bookshelves/($shelf)/moveVolume" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a volume from a bookshelf.
#
# POST /books/v1/mylibrary/bookshelves/{shelf}/removeVolume
# operationId: books.mylibrary.bookshelves.removeVolume
export def "books-mylibrary-bookshelves-remove-volume booksmylibrarybookshelvesremoveVolume" [
  shelf: string
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
  --volumeId: string # ID of volume to remove.
  --reason: string@reason-completer-1 # The reason for which the book is removed from the library.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "volumeId" $volumeId "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/bookshelves/($shelf)/removeVolume" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets volume information for volumes on a bookshelf.
#
# GET /books/v1/mylibrary/bookshelves/{shelf}/volumes
# operationId: books.mylibrary.bookshelves.volumes.list
export def "books-mylibrary-bookshelves-volumes booksmylibrarybookshelvesvolumeslist" [
  shelf: string
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
  --country: string # ISO-3166-1 code to override the IP-based location.
  --maxResults: int # Maximum number of results to return
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --q: string # Full-text search query string in this bookshelf.
  --showPreorders: oneof<nothing, bool> # Set to true to show pre-ordered books. Defaults to false.
  --qp-source: string # String to identify the originator of this request.
  --startIndex: int # Index of the first element to return (starts at 0)
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "showPreorders" $showPreorders "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/bookshelves/($shelf)/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves my reading position information for a volume.
#
# GET /books/v1/mylibrary/readingpositions/{volumeId}
# operationId: books.mylibrary.readingpositions.get
export def "books-mylibrary-readingpositions booksmylibraryreadingpositionsget" [
  volumeId: string
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
  --contentVersion: string # Volume content version for which this reading position is requested.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<epubCfiPosition: string, gbImagePosition: string, gbTextPosition: string, kind: string, pdfPosition: string, updated: string, volumeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/readingpositions/($volumeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets my reading position information for a volume.
#
# POST /books/v1/mylibrary/readingpositions/{volumeId}/setPosition
# operationId: books.mylibrary.readingpositions.setPosition
export def "books-mylibrary-readingpositions-set-position booksmylibraryreadingpositionssetPosition" [
  volumeId: string
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
  --position: string # Position string for the new volume reading position.
  --timestamp: string # RFC 3339 UTC format timestamp associated with this reading position.
  --action: string@action-completer # Action that caused this reading position to be set.
  --contentVersion: string # Volume content version for which this reading position applies.
  --deviceCookie: string # Random persistent device cookie optional on set position.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "deviceCookie" $deviceCookie "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/mylibrary/readingpositions/($volumeId)/setPosition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns notification details for a given notification id.
#
# GET /books/v1/notification/get
# operationId: books.notification.get
export def "books-notification-get booksnotificationget" [
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
  --notification-id: string # String to identify the notification.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating notification title and body.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<body: string, crmExperimentIds: list<string>, doc_id: string, doc_type: string, dont_show_notification: bool, iconUrl: string, is_document_mature: bool, kind: string, notificationGroup: string, notification_type: string, pcampaign_id: string, reason: string, show_notification_settings_action: bool, targetUrl: string, timeToExpireMs: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "notification_id" $notification_id "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/notification/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List categories for onboarding experience.
#
# GET /books/v1/onboarding/listCategories
# operationId: books.onboarding.listCategories
export def "books-onboarding-list-categories booksonboardinglistCategories" [
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
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Default is en-US if unset.
]: nothing -> record<items: table<badgeUrl: string, categoryId: string, name: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/onboarding/listCategories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available volumes under categories for onboarding experience.
#
# GET /books/v1/onboarding/listCategoryVolumes
# operationId: books.onboarding.listCategoryVolumes
export def "books-onboarding-list-category-volumes booksonboardinglistCategoryVolumes" [
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
  --categoryId: list # List of category ids requested.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Default is en-US if unset.
  --maxAllowedMaturityRating: string@maxAllowedMaturityRating-completer # The maximum allowed maturity rating of returned volumes. Books with a higher maturity rating are filtered out.
  --pageSize: int # Number of maximum results per page to be included in the response.
  --pageToken: string # The value of the nextToken from the previous page.
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "categoryId" $categoryId "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxAllowedMaturityRating" $maxAllowedMaturityRating "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/onboarding/listCategoryVolumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a stream of personalized book clusters
#
# GET /books/v1/personalizedstream/get
# operationId: books.personalizedstream.get
export def "books-personalizedstream-get bookspersonalizedstreamget" [
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
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --maxAllowedMaturityRating: string@maxAllowedMaturityRating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<clusters: table<banner_with_content_container: record, subTitle: string, title: string, totalVolumes: int, uid: string, volumes: list>, kind: string, totalClusters: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxAllowedMaturityRating" $maxAllowedMaturityRating "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/personalizedstream/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accepts the promo offer.
#
# POST /books/v1/promooffer/accept
# operationId: books.promooffer.accept
export def "books-promooffer-accept bookspromoofferaccept" [
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
  --androidId: string # device android_id
  --device: string # device device
  --manufacturer: string # device manufacturer
  --model: string # device model
  --offerId: string
  --product: string # device product
  --serial: string # device serial
  --volumeId: string # Volume id to exercise the offer
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "androidId" $androidId "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "offerId" $offerId "scalar") (serialize-qp "product" $product "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "volumeId" $volumeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/promooffer/accept" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Marks the promo offer as dismissed.
#
# POST /books/v1/promooffer/dismiss
# operationId: books.promooffer.dismiss
export def "books-promooffer-dismiss bookspromoofferdismiss" [
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
  --androidId: string # device android_id
  --device: string # device device
  --manufacturer: string # device manufacturer
  --model: string # device model
  --offerId: string # Offer to dimiss
  --product: string # device product
  --serial: string # device serial
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "androidId" $androidId "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "offerId" $offerId "scalar") (serialize-qp "product" $product "scalar") (serialize-qp "serial" $serial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/promooffer/dismiss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of promo offers available to the user
#
# GET /books/v1/promooffer/get
# operationId: books.promooffer.get
export def "books-promooffer-get bookspromoofferget" [
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
  --androidId: string # device android_id
  --device: string # device device
  --manufacturer: string # device manufacturer
  --model: string # device model
  --product: string # device product
  --serial: string # device serial
]: nothing -> record<items: table<artUrl: string, gservicesKey: string, id: string, items: list>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "androidId" $androidId "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "product" $product "scalar") (serialize-qp "serial" $serial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/promooffer/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Series metadata for the given series ids.
#
# GET /books/v1/series/get
# operationId: books.series.get
export def "books-series-get booksseriesget" [
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
  --series-id: list # String that identifies the series
]: nothing -> record<kind: string, series: table<bannerImageUrl: string, eligibleForSubscription: bool, imageUrl: string, isComplete: bool, seriesFormatType: string, seriesId: string, seriesSubscriptionReleaseInfo: record, seriesType: string, subscriptionId: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "series_id" $series_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/series/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Series membership data given the series id.
#
# GET /books/v1/series/membership/get
# operationId: books.series.membership.get
export def "books-series-membership-get booksseriesmembershipget" [
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
  --series-id: string # String that identifies the series
  --page-size: int # Number of maximum results per page to be included in the response.
  --page-token: string # The value of the nextToken from the previous page.
]: nothing -> record<kind: string, member: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "series_id" $series_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/series/membership/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of public bookshelves for the specified user.
#
# GET /books/v1/users/{userId}/bookshelves
# operationId: books.bookshelves.list
export def "books-users-bookshelves booksbookshelveslist" [
  userId: string
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<items: table<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/users/($userId)/bookshelves" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves metadata for a specific bookshelf for the specified user.
#
# GET /books/v1/users/{userId}/bookshelves/{shelf}
# operationId: books.bookshelves.get
export def "books-users-bookshelves booksbookshelvesget" [
  userId: string
  shelf: string
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
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<access: string, created: string, description: string, id: int, kind: string, selfLink: string, title: string, updated: string, volumeCount: int, volumesLastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/users/($userId)/bookshelves/($shelf)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves volumes in a specific bookshelf for the specified user.
#
# GET /books/v1/users/{userId}/bookshelves/{shelf}/volumes
# operationId: books.bookshelves.volumes.list
export def "books-users-bookshelves-volumes booksbookshelvesvolumeslist" [
  userId: string
  shelf: string
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
  --maxResults: int # Maximum number of results to return
  --showPreorders: oneof<nothing, bool> # Set to true to show pre-ordered books. Defaults to false.
  --qp-source: string # String to identify the originator of this request.
  --startIndex: int # Index of the first element to return (starts at 0)
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "showPreorders" $showPreorders "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/users/($userId)/bookshelves/($shelf)/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Performs a book search.
#
# GET /books/v1/volumes
# operationId: books.volumes.list
export def "books-volumes booksvolumeslist" [
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
  --q: string # Full-text search query string.
  --download: string@download-completer # Restrict to volumes by download availability.
  --filter: string@filter-completer # Filter search results.
  --langRestrict: string # Restrict results to books with this language code.
  --libraryRestrict: string@libraryRestrict-completer # Restrict search to this user's library.
  --maxAllowedMaturityRating: string@maxAllowedMaturityRating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --maxResults: int # Maximum number of results to return.
  --orderBy: string@orderBy-completer # Sort search results.
  --partner: string # Restrict and brand results for partner ID.
  --printType: string@printType-completer # Restrict to books or magazines.
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --showPreorders: oneof<nothing, bool> # Set to true to show books available for preorder. Defaults to false.
  --qp-source: string # String to identify the originator of this request.
  --startIndex: int # Index of the first result to return (starts at 0)
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "langRestrict" $langRestrict "scalar") (serialize-qp "libraryRestrict" $libraryRestrict "scalar") (serialize-qp "maxAllowedMaturityRating" $maxAllowedMaturityRating "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "partner" $partner "scalar") (serialize-qp "printType" $printType "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "showPreorders" $showPreorders "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of books in My Library.
#
# GET /books/v1/volumes/mybooks
# operationId: books.volumes.mybooks.list
export def "books-volumes-mybooks booksvolumesmybookslist" [
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
  --acquireMethod: list # How the book was acquired
  --country: string # ISO-3166-1 code to override the IP-based location.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex:'en_US'. Used for generating recommendations.
  --maxResults: int # Maximum number of results to return.
  --processingState: list # The processing state of the user uploaded volumes to be returned. Applicable only if the UPLOADED is specified in the acquireMethod.
  --qp-source: string # String to identify the originator of this request.
  --startIndex: int # Index of the first result to return (starts at 0)
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "acquireMethod" $acquireMethod "multi") (serialize-qp "country" $country "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "processingState" $processingState "multi") (serialize-qp "source" $qp_source "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/volumes/mybooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of recommended books for the current user.
#
# GET /books/v1/volumes/recommended
# operationId: books.volumes.recommended.list
export def "books-volumes-recommended booksvolumesrecommendedlist" [
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
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --maxAllowedMaturityRating: string@maxAllowedMaturityRating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxAllowedMaturityRating" $maxAllowedMaturityRating "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/volumes/recommended" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rate a recommended book for the current user.
#
# POST /books/v1/volumes/recommended/rate
# operationId: books.volumes.recommended.rate
export def "books-volumes-recommended-rate booksvolumesrecommendedrate" [
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
  --rating: string@rating-completer # Rating to be given to the volume.
  --volumeId: string # ID of the source volume.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<consistency_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "volumeId" $volumeId "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/volumes/recommended/rate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of books uploaded by the current user.
#
# GET /books/v1/volumes/useruploaded
# operationId: books.volumes.useruploaded.list
export def "books-volumes-useruploaded booksvolumesuseruploadedlist" [
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
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --maxResults: int # Maximum number of results to return.
  --processingState: list # The processing state of the user uploaded volumes to be returned.
  --qp-source: string # String to identify the originator of this request.
  --startIndex: int # Index of the first result to return (starts at 0)
  --volumeId: list # The ids of the volumes to be returned. If not specified all that match the processingState are returned.
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "processingState" $processingState "multi") (serialize-qp "source" $qp_source "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "volumeId" $volumeId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/books/v1/volumes/useruploaded" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets volume information for a single volume.
#
# GET /books/v1/volumes/{volumeId}
# operationId: books.volumes.get
export def "books-volumes booksvolumesget" [
  volumeId: string
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
  --country: string # ISO-3166-1 code to override the IP-based location.
  --includeNonComicsSeries: oneof<nothing, bool> # Set to true to include non-comics series. Defaults to false.
  --partner: string # Brand results for partner ID.
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --qp-source: string # string to identify the originator of this request.
  --user-library-consistent-read: oneof<nothing, bool>
]: nothing -> record<accessInfo: record<accessViewStatus: string, country: string, downloadAccess: record<deviceAllowed: bool, downloadsAcquired: int, justAcquired: bool, kind: string, maxDownloadDevices: int, message: string, nonce: string, reasonCode: string, restricted: bool, signature: string, source: string, volumeId: string>, driveImportedContentLink: string, embeddable: bool, epub: record<acsTokenLink: string, downloadLink: string, isAvailable: bool>, explicitOfflineLicenseManagement: bool, pdf: record<acsTokenLink: string, downloadLink: string, isAvailable: bool>, publicDomain: bool, quoteSharingAllowed: bool, textToSpeechPermission: string, viewOrderUrl: string, viewability: string, webReaderLink: string>, etag: string, id: string, kind: string, layerInfo: record<layers: list<record>>, recommendedInfo: record<explanation: string>, saleInfo: record<buyLink: string, country: string, isEbook: bool, listPrice: record<amount: float, currencyCode: string>, offers: list<record>, onSaleDate: string, retailPrice: record<amount: float, currencyCode: string>, saleability: string>, searchInfo: record<textSnippet: string>, selfLink: string, userInfo: record<acquiredTime: string, acquisitionType: int, copy: record<allowedCharacterCount: int, limitType: string, remainingCharacterCount: int, updated: string>, entitlementType: int, familySharing: record<familyRole: string, isSharingAllowed: bool, isSharingDisabledByFop: bool>, isFamilySharedFromUser: bool, isFamilySharedToUser: bool, isFamilySharingAllowed: bool, isFamilySharingDisabledByFop: bool, isInMyBooks: bool, isPreordered: bool, isPurchased: bool, isUploaded: bool, readingPosition: record<epubCfiPosition: string, gbImagePosition: string, gbTextPosition: string, kind: string, pdfPosition: string, updated: string, volumeId: string>, rentalPeriod: record<endUtcSec: string, startUtcSec: string>, rentalState: string, review: record<author: record, content: string, date: string, fullTextUrl: string, kind: string, rating: string, source: record, title: string, type: string, volumeId: string>, updated: string, userUploadedVolumeInfo: record<processingState: string>>, volumeInfo: record<allowAnonLogging: bool, authors: list<string>, averageRating: float, canonicalVolumeLink: string, categories: list<string>, comicsContent: bool, contentVersion: string, description: string, dimensions: record<height: string, thickness: string, width: string>, imageLinks: record<extraLarge: string, large: string, medium: string, small: string, smallThumbnail: string, thumbnail: string>, industryIdentifiers: list<record>, infoLink: string, language: string, mainCategory: string, maturityRating: string, pageCount: int, panelizationSummary: record<containsEpubBubbles: bool, containsImageBubbles: bool, epubBubbleVersion: string, imageBubbleVersion: string>, previewLink: string, printType: string, printedPageCount: int, publishedDate: string, publisher: string, ratingsCount: int, readingModes: record<image: bool, text: bool>, samplePageCount: int, seriesInfo: record<bookDisplayNumber: string, kind: string, shortSeriesBookTitle: string, volumeSeries: list>, subtitle: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "includeNonComicsSeries" $includeNonComicsSeries "scalar") (serialize-qp "partner" $partner "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "user_library_consistent_read" $user_library_consistent_read "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of associated books.
#
# GET /books/v1/volumes/{volumeId}/associated
# operationId: books.volumes.associated.list
export def "books-volumes-associated booksvolumesassociatedlist" [
  volumeId: string
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
  --association: string@association-completer # Association type.
  --locale: string # ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'. Used for generating recommendations.
  --maxAllowedMaturityRating: string@maxAllowedMaturityRating-completer # The maximum allowed maturity rating of returned recommendations. Books with a higher maturity rating are filtered out.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<items: table<accessInfo: record, etag: string, id: string, kind: string, layerInfo: record, recommendedInfo: record, saleInfo: record, searchInfo: record, selfLink: string, userInfo: record, volumeInfo: record>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "association" $association "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxAllowedMaturityRating" $maxAllowedMaturityRating "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/associated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the volume annotations for a volume and layer.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}
# operationId: books.layers.volumeAnnotations.list
export def "books-volumes-layers bookslayersvolumeAnnotationslist" [
  volumeId: string
  layerId: string
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
  --contentVersion: string # The content version for the requested volume.
  --endOffset: string # The end offset to end retrieving data from.
  --endPosition: string # The end position to end retrieving data from.
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # The value of the nextToken from the previous page.
  --showDeleted: oneof<nothing, bool> # Set to true to return deleted annotations. updatedMin must be in the request to use this. Defaults to false.
  --qp-source: string # String to identify the originator of this request.
  --startOffset: string # The start offset to start retrieving data from.
  --startPosition: string # The start position to start retrieving data from.
  --updatedMax: string # RFC 3339 timestamp to restrict to items updated prior to this timestamp (exclusive).
  --updatedMin: string # RFC 3339 timestamp to restrict to items updated since this timestamp (inclusive).
  --volumeAnnotationsVersion: string # The version of the volume annotations that you are requesting.
]: nothing -> record<items: table<annotationDataId: string, annotationDataLink: string, annotationType: string, contentRanges: record, data: string, deleted: bool, id: string, kind: string, layerId: string, pageIds: list, selectedText: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "endOffset" $endOffset "scalar") (serialize-qp "endPosition" $endPosition "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "showDeleted" $showDeleted "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "startOffset" $startOffset "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "updatedMax" $updatedMax "scalar") (serialize-qp "updatedMin" $updatedMin "scalar") (serialize-qp "volumeAnnotationsVersion" $volumeAnnotationsVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/layers/($layerId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the volume annotation.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}/annotations/{annotationId}
# operationId: books.layers.volumeAnnotations.get
export def "books-volumes-layers-annotations bookslayersvolumeAnnotationsget" [
  volumeId: string
  layerId: string
  annotationId: string
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
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<annotationDataId: string, annotationDataLink: string, annotationType: string, contentRanges: record<cfiRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, contentVersion: string, gbImageRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>, gbTextRange: record<endOffset: string, endPosition: string, startOffset: string, startPosition: string>>, data: string, deleted: bool, id: string, kind: string, layerId: string, pageIds: list<string>, selectedText: string, selfLink: string, updated: string, volumeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/layers/($layerId)/annotations/($annotationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the annotation data for a volume and layer.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}/data
# operationId: books.layers.annotationData.list
export def "books-volumes-layers-data bookslayersannotationDatalist" [
  volumeId: string
  layerId: string
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
  --contentVersion: string # The content version for the requested volume.
  --annotationDataId: list # The list of Annotation Data Ids to retrieve. Pagination is ignored if this is set.
  --h: int # The requested pixel height for any images. If height is provided width must also be provided.
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # The value of the nextToken from the previous page.
  --scale: int # The requested scale for the image.
  --qp-source: string # String to identify the originator of this request.
  --updatedMax: string # RFC 3339 timestamp to restrict to items updated prior to this timestamp (exclusive).
  --updatedMin: string # RFC 3339 timestamp to restrict to items updated since this timestamp (inclusive).
  --w: int # The requested pixel width for any images. If width is provided height must also be provided.
]: nothing -> record<items: table<annotationType: string, data: record, encodedData: string, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeId: string>, kind: string, nextPageToken: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "annotationDataId" $annotationDataId "multi") (serialize-qp "h" $h "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "updatedMax" $updatedMax "scalar") (serialize-qp "updatedMin" $updatedMin "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/layers/($layerId)/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the annotation data.
#
# GET /books/v1/volumes/{volumeId}/layers/{layerId}/data/{annotationDataId}
# operationId: books.layers.annotationData.get
export def "books-volumes-layers-data bookslayersannotationDataget" [
  volumeId: string
  layerId: string
  annotationDataId: string
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
  --contentVersion: string # The content version for the volume you are trying to retrieve.
  --allowWebDefinitions: oneof<nothing, bool> # For the dictionary layer. Whether or not to allow web definitions.
  --h: int # The requested pixel height for any images. If height is provided width must also be provided.
  --locale: string # The locale information for the data. ISO-639-1 language and ISO-3166-1 country code. Ex: 'en_US'.
  --scale: int # The requested scale for the image.
  --qp-source: string # String to identify the originator of this request.
  --w: int # The requested pixel width for any images. If width is provided height must also be provided.
]: nothing -> record<annotationType: string, data: record<common: record<title: string>, dict: record<source: record, words: list>, kind: string>, encodedData: string, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "allowWebDefinitions" $allowWebDefinitions "scalar") (serialize-qp "h" $h "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/layers/($layerId)/data/($annotationDataId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the layer summaries for a volume.
#
# GET /books/v1/volumes/{volumeId}/layersummary
# operationId: books.layers.list
export def "books-volumes-layersummary bookslayerslist" [
  volumeId: string
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
  --contentVersion: string # The content version for the requested volume.
  --maxResults: int # Maximum number of results to return
  --pageToken: string # The value of the nextToken from the previous page.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<items: table<annotationCount: int, annotationTypes: list, annotationsDataLink: string, annotationsLink: string, contentVersion: string, dataCount: int, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeAnnotationsVersion: string, volumeId: string>, kind: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/layersummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the layer summary for a volume.
#
# GET /books/v1/volumes/{volumeId}/layersummary/{summaryId}
# operationId: books.layers.get
export def "books-volumes-layersummary bookslayersget" [
  volumeId: string
  summaryId: string
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
  --contentVersion: string # The content version for the requested volume.
  --qp-source: string # String to identify the originator of this request.
]: nothing -> record<annotationCount: int, annotationTypes: list<string>, annotationsDataLink: string, annotationsLink: string, contentVersion: string, dataCount: int, id: string, kind: string, layerId: string, selfLink: string, updated: string, volumeAnnotationsVersion: string, volumeId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "contentVersion" $contentVersion "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/books/v1/volumes/($volumeId)/layersummary/($summaryId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
