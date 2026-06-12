# Auto-generated client for Coda API v1.5.0
# Source: https://coda.io/apis/v1/openapi.json
# Auth: --token flag or $env.CODA_API_TOKEN

const BASE_URL = "https://coda.io/apis/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CODA_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://coda.io/apis/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def access-completer [] { ["comment" "readonly" "write"] }
def mode-completer [] { ["edit" "play" "view"] }
def contentFormat-completer [] { ["plainText"] }
def outputFormat-completer [] { ["html" "markdown"] }
def sortBy-completer [] { ["name"] }
def sortBy-completer-1 [] { ["createdAt" "natural" "updatedAt"] }
def valueFormat-completer [] { ["rich" "simple" "simpleWithArrays"] }
def scale-completer [] { ["cumulative" "daily"] }
def orderBy-completer [] { ["aiCredits" "aiCreditsAssistant" "aiCreditsBlock" "aiCreditsChat" "aiCreditsColumn" "aiCreditsReviewer" "copies" "createdAt" "date" "docId" "likes" "publishedAt" "sessionsDesktop" "sessionsMobile" "sessionsOther" "title" "totalSessions" "views"] }
def direction-completer [] { ["ascending" "descending"] }
def orderBy-completer-1 [] { ["createdAt" "date" "docInstalls" "docsActivelyUsing" "docsActivelyUsing30Day" "docsActivelyUsing7Day" "docsActivelyUsing90Day" "docsActivelyUsingAllTime" "name" "numActionInvocations" "numFormulaInvocations" "numMetadataInvocations" "numSyncInvocations" "packId" "revenueUsd" "workspaceInstalls" "workspacesActivelyUsing" "workspacesActivelyUsing30Day" "workspacesActivelyUsing7Day" "workspacesActivelyUsing90Day" "workspacesActivelyUsingAllTime" "workspacesWithActiveSubscriptions" "workspacesWithSuccessfulTrials"] }
def orderBy-completer-2 [] { ["date" "docsActivelyUsing" "docsActivelyUsing30Day" "docsActivelyUsing7Day" "docsActivelyUsing90Day" "docsActivelyUsingAllTime" "errors" "formulaInvocations" "formulaName" "formulaType" "medianLatencyMs" "medianResponseSizeBytes" "workspacesActivelyUsing" "workspacesActivelyUsing30Day" "workspacesActivelyUsing7Day" "workspacesActivelyUsing90Day" "workspacesActivelyUsingAllTime"] }
def newRole-completer [] { ["Admin" "DocMaker" "Editor"] }
def accessType-completer [] { ["admin" "edit" "none" "test" "view"] }
def sortBy-completer-2 [] { ["createdAt" "title" "updatedAt"] }
def packEntrypoint-completer [] { ["docs" "go"] }
def sourceCodeVisibility-completer [] { ["private" "shared"] }
def source-completer [] { ["cli" "web"] }
def status-completer [] { ["approved" "canceled" "denied" "pending" "superseded"] }
def type-completer [] { ["awsAccessKey" "awsAssumeRole" "custom" "googleServiceAccount" "header" "httpBasic" "multiHeader" "oauth2ClientCredentials" "urlParam"] }
def access-completer-1 [] { ["admin" "edit" "none" "test" "view"] }
def packAssetType-completer [] { ["agentImage" "cover" "exampleImage" "logo"] }
def sortBy-completer-3 [] { ["agentDirectorySort" "name" "packId" "packVersion" "packVersionModifiedAt"] }
def orderBy-completer-3 [] { ["agentDirectorySort" "name" "packId" "packVersion" "packVersionModifiedAt"] }
def installContext-completer [] { ["doc" "workspace"] }
def releaseChannel-completer [] { ["LATEST" "LIVE"] }
def order-completer [] { ["asc" "desc"] }
def ingestionStatus-completer [] { ["CANCELLED" "COMPLETED" "FAILED" "QUEUED" "STARTED" "UP_FOR_RETRY"] }
def executionType-completer [] { ["FULL" "INCREMENTAL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "categories listCategories" } } | get name | first)
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

# Get doc categories
#
# GET /categories
# operationId: listCategories
export def "categories listCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available docs
#
# GET /docs
# operationId: listDocs
export def "docs listDocs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isOwner: oneof<nothing, bool> # Show only docs owned by the user.
  --isPublished: oneof<nothing, bool> # Show only published docs.
  --qp-query: string # Search term used to filter down results. (e.g. Supercalifragilisticexpialidocious)
  --sourceDoc: string # Show only docs copied from the specified doc ID.
  --isStarred: oneof<nothing, bool> # If true, returns docs that are starred. If false, returns docs that are not starred.
  --inGallery: oneof<nothing, bool> # Show only docs visible within the gallery.
  --workspaceId: string # Show only docs belonging to the given workspace.
  --folderId: string # Show only docs belonging to the given folder.
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<id: string, type: string, href: string, browserLink: string, icon: record, name: string, owner: string, ownerName: string, docSize: record, sourceDoc: record, createdAt: string, updatedAt: string, published: record, folder: record, workspace: record, workspaceId: string, folderId: string>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isOwner" $isOwner "scalar") (serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sourceDoc" $sourceDoc "scalar") (serialize-qp "isStarred" $isStarred "scalar") (serialize-qp "inGallery" $inGallery "scalar") (serialize-qp "workspaceId" $workspaceId "scalar") (serialize-qp "folderId" $folderId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create doc
#
# POST /docs
# operationId: createDoc
export def "docs createDoc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of the new doc. Defaults to 'Untitled'. (e.g. Project Tracker)
  --sourceDoc: string # An optional doc ID from which to create a copy. (e.g. iJKlm_noPq)
  --timezone: string # The timezone to use for the newly created doc. (e.g. America/Los_Angeles)
  --folderId: string # The ID of the folder within which to create this doc. Defaults to your "My docs" folder in the oldest workspace you joined; this is subject to change. You can get this ID by opening the folder in the docs list on your computer and grabbing the `folderId` query parameter.  (e.g. fl-ABcdEFgHJi)
  --initialPage: any
]: any -> record<id: string, type: string, href: string, browserLink: string, icon: record<name: string, type: string, browserLink: string>, name: string, owner: string, ownerName: string, docSize: record<totalRowCount: float, tableAndViewCount: float, pageCount: float, overApiSizeLimit: bool>, sourceDoc: record<id: string, type: string, href: string, browserLink: string>, createdAt: string, updatedAt: string, published: record<description: string, browserLink: string, imageLink: string, discoverable: bool, earnCredit: bool, mode: string, categories: list<record>>, folder: record<id: string, type: string, browserLink: string, name: string>, workspace: record<id: string, type: string, organizationId: string, browserLink: string, name: string>, workspaceId: string, folderId: string, requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/docs")
  let body = {title: $title, sourceDoc: $sourceDoc, timezone: $timezone, folderId: $folderId, initialPage: $initialPage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get info about a doc
#
# GET /docs/{docId}
# operationId: getDoc
export def "docs get" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, href: string, browserLink: string, icon: record<name: string, type: string, browserLink: string>, name: string, owner: string, ownerName: string, docSize: record<totalRowCount: float, tableAndViewCount: float, pageCount: float, overApiSizeLimit: bool>, sourceDoc: record<id: string, type: string, href: string, browserLink: string>, createdAt: string, updatedAt: string, published: record<description: string, browserLink: string, imageLink: string, discoverable: bool, earnCredit: bool, mode: string, categories: list<record>>, folder: record<id: string, type: string, browserLink: string, name: string>, workspace: record<id: string, type: string, organizationId: string, browserLink: string, name: string>, workspaceId: string, folderId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete doc
#
# DELETE /docs/{docId}
# operationId: deleteDoc
export def "docs delete" [
  docId: string
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
  let full_url = (build-url $base $"/docs/($docId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update doc
#
# PATCH /docs/{docId}
# operationId: updateDoc
export def "docs updateDoc" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title of the doc. (e.g. Project Tracker)
  --iconName: string # Name of the icon. (e.g. rocket)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)")
  let body = {title: $title, iconName: $iconName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sharing metadata
#
# GET /docs/{docId}/acl/metadata
# operationId: getSharingMetadata
export def "docs-acl-metadata get" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<canShare: bool, canShareWithWorkspace: bool, canShareWithOrg: bool, canCopy: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/acl/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permissions
#
# GET /docs/{docId}/acl/permissions
# operationId: getPermissions
export def "docs-acl-permissions get" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<principal: any, id: string, access: string>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/acl/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add permission
#
# POST /docs/{docId}/acl/permissions
# operationId: addPermission
export def "docs-acl-permissions addPermission" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access: string@access-completer # Type of access (excluding none).
  principal: any # Metadata about a principal to add to a doc.
  --suppressEmail: oneof<nothing, bool> # When true suppresses email notification
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/acl/permissions")
  let body = {access: $access, principal: $principal, suppressEmail: $suppressEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete permission
#
# DELETE /docs/{docId}/acl/permissions/{permissionId}
# operationId: deletePermission
export def "docs-acl-permissions delete" [
  docId: string
  permissionId: string
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
  let full_url = (build-url $base $"/docs/($docId)/acl/permissions/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search principals
#
# GET /docs/{docId}/acl/principals/search
# operationId: searchPrincipals
export def "docs-acl-principals-search searchPrincipals" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search term used to filter down results. (e.g. Supercalifragilisticexpialidocious)
]: nothing -> record<users: table<name: string, loginId: string, type: string, pictureLink: string>, groups: table<type: string, groupId: string, groupName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/acl/principals/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ACL settings
#
# GET /docs/{docId}/acl/settings
# operationId: getAclSettings
export def "docs-acl-settings get" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowEditorsToChangePermissions: bool, allowCopying: bool, allowViewersToRequestEditing: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/acl/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update ACL settings
#
# PATCH /docs/{docId}/acl/settings
# operationId: updateAclSettings
export def "docs-acl-settings updateAclSettings" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowEditorsToChangePermissions: oneof<nothing, bool> # When true, allows editors to change doc permissions. When false, only doc owner can change doc permissions.
  --allowCopying: oneof<nothing, bool> # When true, allows doc viewers to copy the doc.
  --allowViewersToRequestEditing: oneof<nothing, bool> # When true, allows doc viewers to request editing permissions.
]: any -> record<allowEditorsToChangePermissions: bool, allowCopying: bool, allowViewersToRequestEditing: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/acl/settings")
  let body = {allowEditorsToChangePermissions: $allowEditorsToChangePermissions, allowCopying: $allowCopying, allowViewersToRequestEditing: $allowViewersToRequestEditing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Publish doc
#
# PUT /docs/{docId}/publish
# operationId: publishDoc
export def "docs-publish publishDoc" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # Slug for the published doc. (e.g. my-doc)
  --discoverable: oneof<nothing, bool> # If true, indicates that the doc is discoverable. (e.g. true)
  --earnCredit: oneof<nothing, bool> # If true, new users may be required to sign in to view content within this document. You will receive Coda credit for each user who signs up via your doc.  (e.g. true)
  --categoryNames: list # The names of categories to apply to the document. (e.g. [Project management])
  --mode: string@mode-completer # Which interaction mode the published doc should use.
]: any -> record<requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/publish")
  let body = {slug: $slug, discoverable: $discoverable, earnCredit: $earnCredit, categoryNames: $categoryNames, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpublish doc
#
# DELETE /docs/{docId}/publish
# operationId: unpublishDoc
export def "docs-publish unpublishDoc" [
  docId: string
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
  let full_url = (build-url $base $"/docs/($docId)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pages
#
# GET /docs/{docId}/pages
# operationId: listPages
export def "docs-pages listPages" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<id: string, type: string, href: string, browserLink: string, name: string, subtitle: string, icon: record, image: record, contentType: string, isHidden: bool, isEffectivelyHidden: bool, parent: record, children: list, authors: list, createdAt: string, createdBy: record, updatedAt: string, updatedBy: record>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a page
#
# POST /docs/{docId}/pages
# operationId: createPage
export def "docs-pages createPage" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the page. (e.g. Launch Status)
  --subtitle: string # Subtitle of the page. (e.g. See the status of launch-related tasks.)
  --iconName: string # Name of the icon. (e.g. rocket)
  --imageUrl: string # Url of the cover image to use. (e.g. https://example.com/image.jpg)
  --parentPageId: string # The ID of this new page's parent, if creating a subpage. (e.g. canvas-tuVwxYz)
  --pageContent: any # Content that can be added to a page at creation time, either text (or rich text) or a URL to create a full-page embed.
]: any -> record<requestId: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages")
  let body = {name: $name, subtitle: $subtitle, iconName: $iconName, imageUrl: $imageUrl, parentPageId: $parentPageId, pageContent: $pageContent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a page
#
# GET /docs/{docId}/pages/{pageIdOrName}
# operationId: getPage
export def "docs-pages get" [
  docId: string
  pageIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, href: string, browserLink: string, name: string, subtitle: string, icon: record<name: string, type: string, browserLink: string>, image: record<browserLink: string, type: string, width: float, height: float>, contentType: string, isHidden: bool, isEffectivelyHidden: bool, parent: record<id: string, type: string, href: string, browserLink: string, name: string>, children: table<id: string, type: string, href: string, browserLink: string, name: string>, authors: table<_context: string, _type: string, additionalType: string, name: string, email: string>, createdAt: string, createdBy: record<_context: string, _type: string, additionalType: string, name: string, email: string>, updatedAt: string, updatedBy: record<_context: string, _type: string, additionalType: string, name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a page
#
# PUT /docs/{docId}/pages/{pageIdOrName}
# operationId: updatePage
export def "docs-pages updatePage" [
  docId: string
  pageIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the page. (e.g. Launch Status)
  --subtitle: string # Subtitle of the page. (e.g. See the status of launch-related tasks.)
  --iconName: string # Name of the icon. (e.g. rocket)
  --imageUrl: string # Url of the cover image to use. (e.g. https://example.com/image.jpg)
  --isHidden: oneof<nothing, bool> # Whether the page is hidden or not. Note that for pages that cannot be hidden, like the sole top-level page in a doc, this will be ignored. (e.g. true)
  --contentUpdate: any
]: any -> record<requestId: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)")
  let body = {name: $name, subtitle: $subtitle, iconName: $iconName, imageUrl: $imageUrl, isHidden: $isHidden, contentUpdate: $contentUpdate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a page
#
# DELETE /docs/{docId}/pages/{pageIdOrName}
# operationId: deletePage
export def "docs-pages delete" [
  docId: string
  pageIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<requestId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List page content
#
# GET /docs/{docId}/pages/{pageIdOrName}/content
# operationId: listPageContent
export def "docs-pages-content listPageContent" [
  docId: string
  pageIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of content items to return in this query. (default: 50, e.g. 50)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --contentFormat: string@contentFormat-completer # The format to return content in. Defaults to plainText. (default: plainText, e.g. plainText)
]: nothing -> record<items: table<id: string, type: string, itemContent: record>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "contentFormat" $contentFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)/content" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete page content
#
# DELETE /docs/{docId}/pages/{pageIdOrName}/content
# operationId: deletePageContent
export def "docs-pages-content delete" [
  docId: string
  pageIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --elementIds: list # IDs of the elements to delete from the page. If omitted or empty, all content will be deleted.  (e.g. [cl-lzqh0Q0poT, cl-abc123def])
]: any -> record<requestId: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)/content")
  let body = {elementIds: $elementIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Begin content export
#
# POST /docs/{docId}/pages/{pageIdOrName}/export
# operationId: beginPageContentExport
export def "docs-pages-export beginPageContentExport" [
  docId: string
  pageIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  outputFormat: string@outputFormat-completer # Supported output content formats that can be requested for getting content for an existing page.
]: any -> record<id: string, status: string, href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)/export")
  let body = {outputFormat: $outputFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Content export status
#
# GET /docs/{docId}/pages/{pageIdOrName}/export/{requestId}
# operationId: getPageContentExportStatus
export def "docs-pages-export get" [
  docId: string
  pageIdOrName: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, href: string, downloadLink: string, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/pages/($pageIdOrName)/export/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tables
#
# GET /docs/{docId}/tables
# operationId: listTables
export def "docs-tables listTables" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --sortBy: string@sortBy-completer # Determines how to sort the given objects. (e.g. name)
  --tableTypes: list # Comma-separated list of table types to include in results. If omitted, includes both tables and views. (e.g. table,view)
]: nothing -> record<items: table<id: string, type: string, tableType: string, href: string, browserLink: string, name: string, parent: record>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "tableTypes" $tableTypes "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a table
#
# GET /docs/{docId}/tables/{tableIdOrName}
# operationId: getTable
export def "docs-tables get" [
  docId: string
  tableIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --useUpdatedTableLayouts: oneof<nothing, bool> # Return "detail" and "form" for the `layout` field of detail and form layouts respectively (instead of "masterDetail" for both)
]: nothing -> record<id: string, type: string, tableType: string, href: string, browserLink: string, name: string, parent: record<id: string, type: string, href: string, browserLink: string, name: string>, parentTable: record<id: string, type: string, tableType: string, href: string, browserLink: string, name: string, parent: record<id: string, type: string, href: string, browserLink: string, name: string>>, displayColumn: record<id: string, type: string, href: string>, rowCount: int, sorts: table<column: record, direction: string>, layout: string, filter: record<valid: bool, isVolatile: bool, hasUserFormula: bool, hasTodayFormula: bool, hasNowFormula: bool>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useUpdatedTableLayouts" $useUpdatedTableLayouts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List columns
#
# GET /docs/{docId}/tables/{tableIdOrName}/columns
# operationId: listColumns
export def "docs-tables-columns listColumns" [
  docId: string
  tableIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --visibleOnly: oneof<nothing, bool> # If true, returns only visible columns for the table. This parameter only applies to base tables, and not views. (e.g. true)
]: nothing -> record<items: table<id: string, type: string, href: string, name: string, display: bool, calculated: bool, formula: string, defaultValue: string, format: any>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "visibleOnly" $visibleOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/columns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List table rows
#
# GET /docs/{docId}/tables/{tableIdOrName}/rows
# operationId: listRows
export def "docs-tables-rows listRows" [
  docId: string
  tableIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Query used to filter returned rows, specified as `<column_id_or_name>:<value>`. If you'd like to use a column name instead of an ID, you must quote it (e.g., `"My Column":123`). Also note that `value` is a JSON value; if you'd like to use a string, you must surround it in quotes (e.g., `"groceries"`).  (e.g. c-tuVwxYz:"Apple")
  --sortBy: string@sortBy-completer-1 # Specifies the sort order of the rows returned. If left unspecified, rows are returned by creation time ascending. "UpdatedAt" sort ordering is the order of rows based upon when they were last updated. This does not include updates to calculated values. "Natural" sort ordering is the order that the rows appear in the table view in the application. This ordering is only meaningfully defined for rows that are visible (unfiltered). Because of this, using this sort order will imply visibleOnly=true, that is, to only return visible rows. If you pass sortBy=natural and visibleOnly=false explicitly, this will result in a Bad Request error as this condition cannot be satisfied.
  --useColumnNames: oneof<nothing, bool> # Use column names instead of column IDs in the returned output. This is generally discouraged as it is fragile. If columns are renamed, code using original names may throw errors.  (e.g. true)
  --valueFormat: string@valueFormat-completer # The format that cell values are returned as.
  --visibleOnly: oneof<nothing, bool> # If true, returns only visible rows and columns for the table. (e.g. true)
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --syncToken: string # An opaque token returned from a previous call that can be used to return results that are relevant to the query since the call where the syncToken was generated.  (e.g. eyJsaW1pd)
]: nothing -> record<items: table<id: string, type: string, href: string, name: string, index: int, browserLink: string, createdAt: string, updatedAt: string, values: record>, href: string, nextPageToken: string, nextPageLink: record, nextSyncToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "useColumnNames" $useColumnNames "scalar") (serialize-qp "valueFormat" $valueFormat "scalar") (serialize-qp "visibleOnly" $visibleOnly "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "syncToken" $syncToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Insert/upsert rows
#
# POST /docs/{docId}/tables/{tableIdOrName}/rows
# operationId: upsertRows
# --rows item shape: {cells: list}
export def "docs-tables-rows upsertRows" [
  docId: string
  tableIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disableParsing: oneof<nothing, bool> # If true, the API will not attempt to parse the data in any way. (e.g. true)
  rows: list # item shape: {cells: list}
  --keyColumns: list # Optional column IDs, URLs, or names (fragile and discouraged), specifying columns to be used as upsert keys. (e.g. [c-bCdeFgh])
]: any -> record<requestId: string, addedRowIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disableParsing" $disableParsing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows" $qp)
  let body = {rows: $rows, keyColumns: $keyColumns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete multiple rows
#
# DELETE /docs/{docId}/tables/{tableIdOrName}/rows
# operationId: deleteRows
export def "docs-tables-rows delete-by-docId-tableIdOrName" [
  docId: string
  tableIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  rowIds: list # Row IDs to delete.  (e.g. [i-bCdeFgh, i-CdEfgHi])
]: any -> record<requestId: string, rowIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows")
  let body = {rowIds: $rowIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a row
#
# GET /docs/{docId}/tables/{tableIdOrName}/rows/{rowIdOrName}
# operationId: getRow
export def "docs-tables-rows get" [
  docId: string
  tableIdOrName: string
  rowIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --useColumnNames: oneof<nothing, bool> # Use column names instead of column IDs in the returned output. This is generally discouraged as it is fragile. If columns are renamed, code using original names may throw errors.  (e.g. true)
  --valueFormat: string@valueFormat-completer # The format that cell values are returned as.
]: nothing -> record<id: string, type: string, href: string, name: string, index: int, browserLink: string, createdAt: string, updatedAt: string, values: record, parent: record<id: string, type: string, tableType: string, href: string, browserLink: string, name: string, parent: record<id: string, type: string, href: string, browserLink: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useColumnNames" $useColumnNames "scalar") (serialize-qp "valueFormat" $valueFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows/($rowIdOrName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update row
#
# PUT /docs/{docId}/tables/{tableIdOrName}/rows/{rowIdOrName}
# operationId: updateRow
# --row shape: {cells: list}
export def "docs-tables-rows updateRow" [
  docId: string
  tableIdOrName: string
  rowIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disableParsing: oneof<nothing, bool> # If true, the API will not attempt to parse the data in any way. (e.g. true)
  row: record # An edit made to a particular row. — shape: {cells: list}
]: any -> record<requestId: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disableParsing" $disableParsing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows/($rowIdOrName)" $qp)
  let body = {row: $row} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete row
#
# DELETE /docs/{docId}/tables/{tableIdOrName}/rows/{rowIdOrName}
# operationId: deleteRow
export def "docs-tables-rows delete-by-docId-tableIdOrName-rowIdOrName" [
  docId: string
  tableIdOrName: string
  rowIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<requestId: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows/($rowIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push a button
#
# POST /docs/{docId}/tables/{tableIdOrName}/rows/{rowIdOrName}/buttons/{columnIdOrName}
# operationId: pushButton
export def "docs-tables-rows-buttons pushButton" [
  docId: string
  tableIdOrName: string
  rowIdOrName: string
  columnIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<requestId: string, rowId: string, columnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/rows/($rowIdOrName)/buttons/($columnIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a column
#
# GET /docs/{docId}/tables/{tableIdOrName}/columns/{columnIdOrName}
# operationId: getColumn
export def "docs-tables-columns get" [
  docId: string
  tableIdOrName: string
  columnIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, href: string, name: string, display: bool, calculated: bool, formula: string, defaultValue: string, format: any, parent: record<id: string, type: string, tableType: string, href: string, browserLink: string, name: string, parent: record<id: string, type: string, href: string, browserLink: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/tables/($tableIdOrName)/columns/($columnIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List formulas
#
# GET /docs/{docId}/formulas
# operationId: listFormulas
export def "docs-formulas listFormulas" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --sortBy: string@sortBy-completer # Determines how to sort the given objects. (e.g. name)
]: nothing -> record<items: table<id: string, type: string, href: string, name: string, parent: record>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/formulas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a formula
#
# GET /docs/{docId}/formulas/{formulaIdOrName}
# operationId: getFormula
export def "docs-formulas get" [
  docId: string
  formulaIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, href: string, name: string, parent: record<id: string, type: string, href: string, browserLink: string, name: string>, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/formulas/($formulaIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List controls
#
# GET /docs/{docId}/controls
# operationId: listControls
export def "docs-controls listControls" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --sortBy: string@sortBy-completer # Determines how to sort the given objects. (e.g. name)
]: nothing -> record<items: table<id: string, type: string, href: string, name: string, parent: record>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/docs/($docId)/controls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a control
#
# GET /docs/{docId}/controls/{controlIdOrName}
# operationId: getControl
export def "docs-controls get" [
  docId: string
  controlIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, href: string, name: string, parent: record<id: string, type: string, href: string, browserLink: string, name: string>, controlType: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/controls/($controlIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom doc domains
#
# GET /docs/${docId}/domains
# operationId: listCustomDocDomains
export def "docs-doc-id-domains listCustomDocDomains" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<customDocDomains: table<customDocDomain: string, hasCertificate: bool, hasDnsDocId: bool, setupStatus: string, domainStatus: string, lastVerifiedTimestamp: string>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/$($docId)/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add custom domain
#
# POST /docs/${docId}/domains
# operationId: addCustomDocDomain
export def "docs-doc-id-domains addCustomDocDomain" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customDocDomain: string # The custom domain. (e.g. example.com)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/$($docId)/domains")
  let body = {customDocDomain: $customDocDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a custom domain
#
# DELETE /docs/{docId}/domains/{customDocDomain}
# operationId: deleteCustomDocDomain
export def "docs-domains delete" [
  docId: string
  customDocDomain: string
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
  let full_url = (build-url $base $"/docs/($docId)/domains/($customDocDomain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a custom domain
#
# PATCH /docs/{docId}/domains/{customDocDomain}
# operationId: updateCustomDocDomain
export def "docs-domains updateCustomDocDomain" [
  docId: string
  customDocDomain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/domains/($customDocDomain)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets custom doc domains providers
#
# GET /domains/provider/{customDocDomain}
# operationId: getCustomDocDomainProvider
export def "domains-provider get" [
  customDocDomain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/provider/($customDocDomain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List folders
#
# GET /folders
# operationId: listFolders
export def "folders listFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # Show only folders belonging to the given workspace. (e.g. ws-1Ab234)
  --isStarred: oneof<nothing, bool> # If true, returns folders that are starred. If false, returns folders that are not starred. If not specified, returns all folders.
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<id: string, type: string, name: string, browserLink: string, description: string, icon: record, createdAt: string, canEdit: bool, workspace: record>, href: string, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceId" $workspaceId "scalar") (serialize-qp "isStarred" $isStarred "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create folder
#
# POST /folders
# operationId: createFolder
export def "folders createFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the folder. (e.g. Projects)
  workspaceId: string # ID of the workspace where the folder should be created. (e.g. ws-1Ab234)
  --description: string # Description of the folder. (e.g. A collection of project docs.)
]: any -> record<id: string, type: string, name: string, browserLink: string, description: string, icon: record<name: string, type: string, browserLink: string>, createdAt: string, canEdit: bool, workspace: record<id: string, type: string, organizationId: string, browserLink: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/folders")
  let body = {name: $name, workspaceId: $workspaceId, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get folder
#
# GET /folders/{folderId}
# operationId: getFolder
export def "folders get" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, name: string, browserLink: string, description: string, icon: record<name: string, type: string, browserLink: string>, createdAt: string, canEdit: bool, workspace: record<id: string, type: string, organizationId: string, browserLink: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update folder
#
# PATCH /folders/{folderId}
# operationId: updateFolder
export def "folders updateFolder" [
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the folder. (e.g. Projects)
  --description: string # Description of the folder. (e.g. A collection of project docs.)
]: any -> record<id: string, type: string, name: string, browserLink: string, description: string, icon: record<name: string, type: string, browserLink: string>, createdAt: string, canEdit: bool, workspace: record<id: string, type: string, organizationId: string, browserLink: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folderId)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete folder
#
# DELETE /folders/{folderId}
# operationId: deleteFolder
export def "folders delete" [
  folderId: string
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
  let full_url = (build-url $base $"/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user info
#
# GET /whoami
# operationId: whoami
export def "whoami whoami" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, loginId: string, type: string, pictureLink: string, scoped: bool, tokenName: string, href: string, workspace: record<id: string, type: string, organizationId: string, browserLink: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whoami")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve browser link
#
# GET /resolveBrowserLink
# operationId: resolveBrowserLink
export def "resolve-browser-link resolveBrowserLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # The browser link to try to resolve. (format: url, e.g. https://coda.io/d/_dAbCDeFGH/Launch-Status_sumnO)
  --degradeGracefully: oneof<nothing, bool> # By default, attempting to resolve the Coda URL of a deleted object will result in an error. If this flag is set, the next-available object, all the way up to the doc itself, will be resolved.  (e.g. true)
]: nothing -> record<type: string, href: string, browserLink: string, resource: record<type: string, id: string, name: string, href: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "degradeGracefully" $degradeGracefully "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resolveBrowserLink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mutation status
#
# GET /mutationStatus/{requestId}
# operationId: getMutationStatus
export def "mutation-status get" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<completed: bool, warning: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/mutationStatus/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger automation
#
# POST /docs/{docId}/hooks/automation/{ruleId}
# operationId: triggerWebhookAutomation
export def "docs-hooks-automation triggerWebhookAutomation" [
  docId: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/docs/($docId)/hooks/automation/($ruleId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List doc analytics
#
# GET /analytics/docs
# operationId: listDocAnalytics
export def "analytics-docs listDocAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --docIds: list # List of docIds to fetch.
  --workspaceId: string # ID of the workspace. (e.g. ws-1Ab234)
  --qp-query: string # Search term used to filter down results. (e.g. Supercalifragilisticexpialidocious)
  --isPublished: oneof<nothing, bool> # Limit results to only published items.
  --sinceDate: string # Limit results to activity on or after this date. (format: date, e.g. 2020-08-01)
  --untilDate: string # Limit results to activity on or before this date. (format: date, e.g. 2020-08-05)
  --scale: string@scale-completer # Quantization period over which to view analytics. Defaults to daily. (e.g. daily)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --orderBy: string@orderBy-completer # Use this parameter to order the doc analytics returned.
  --direction: string@direction-completer # Direction to sort results in.
  --limit: int # Maximum number of results to return in this query. (default: 1000, e.g. 10)
]: nothing -> record<items: table<doc: record, metrics: list>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docIds" $docIds "csv") (serialize-qp "workspaceId" $workspaceId "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "sinceDate" $sinceDate "scalar") (serialize-qp "untilDate" $untilDate "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/docs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List page analytics
#
# GET /analytics/docs/{docId}/pages
# operationId: listPageAnalytics
export def "analytics-docs-pages listPageAnalytics" [
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sinceDate: string # Limit results to activity on or after this date. (format: date, e.g. 2020-08-01)
  --untilDate: string # Limit results to activity on or before this date. (format: date, e.g. 2020-08-05)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --limit: int # Maximum number of results to return in this query. (default: 1000, e.g. 10)
]: nothing -> record<items: table<page: record, metrics: list>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sinceDate" $sinceDate "scalar") (serialize-qp "untilDate" $untilDate "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analytics/docs/($docId)/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get doc analytics summary
#
# GET /analytics/docs/summary
# operationId: listDocAnalyticsSummary
export def "analytics-docs-summary listDocAnalyticsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isPublished: oneof<nothing, bool> # Limit results to only published items.
  --sinceDate: string # Limit results to activity on or after this date. (format: date, e.g. 2020-08-01)
  --untilDate: string # Limit results to activity on or before this date. (format: date, e.g. 2020-08-05)
  --workspaceId: string # ID of the workspace. (e.g. ws-1Ab234)
]: nothing -> record<totalSessions: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "sinceDate" $sinceDate "scalar") (serialize-qp "untilDate" $untilDate "scalar") (serialize-qp "workspaceId" $workspaceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/docs/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Pack analytics
#
# GET /analytics/packs
# operationId: listPackAnalytics
export def "analytics-packs listPackAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --packIds: list # Which Pack IDs to fetch.
  --workspaceId: string # ID of the workspace. (e.g. ws-1Ab234)
  --qp-query: string # Search term used to filter down results. (e.g. Supercalifragilisticexpialidocious)
  --sinceDate: string # Limit results to activity on or after this date. (format: date, e.g. 2020-08-01)
  --untilDate: string # Limit results to activity on or before this date. (format: date, e.g. 2020-08-05)
  --scale: string@scale-completer # Quantization period over which to view analytics. Defaults to daily. (e.g. daily)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --orderBy: string@orderBy-completer-1 # Use this parameter to order the Pack analytics returned.
  --direction: string@direction-completer # Direction to sort results in.
  --isPublished: oneof<nothing, bool> # Limit results to only published items. If false or unspecified, returns all items including published ones.
  --limit: int # Maximum number of results to return in this query. (default: 1000, e.g. 10)
]: nothing -> record<items: table<pack: record, metrics: list>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packIds" $packIds "csv") (serialize-qp "workspaceId" $workspaceId "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sinceDate" $sinceDate "scalar") (serialize-qp "untilDate" $untilDate "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/packs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pack analytics summary
#
# GET /analytics/packs/summary
# operationId: listPackAnalyticsSummary
export def "analytics-packs-summary listPackAnalyticsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --packIds: list # Which Pack IDs to fetch.
  --workspaceId: string # ID of the workspace. (e.g. ws-1Ab234)
  --isPublished: oneof<nothing, bool> # Limit results to only published items. If false or unspecified, returns all items including published ones.
  --sinceDate: string # Limit results to activity on or after this date. (format: date, e.g. 2020-08-01)
  --untilDate: string # Limit results to activity on or before this date. (format: date, e.g. 2020-08-05)
]: nothing -> record<totalDocInstalls: int, totalWorkspaceInstalls: int, totalInvocations: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packIds" $packIds "csv") (serialize-qp "workspaceId" $workspaceId "scalar") (serialize-qp "isPublished" $isPublished "scalar") (serialize-qp "sinceDate" $sinceDate "scalar") (serialize-qp "untilDate" $untilDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/packs/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Pack formula analytics
#
# GET /analytics/packs/{packId}/formulas
# operationId: listPackFormulaAnalytics
export def "analytics-packs-formulas listPackFormulaAnalytics" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --packFormulaNames: list # A list of Pack formula names (case-sensitive) for which to retrieve analytics. (e.g. SquareRoot,CubeRoot)
  --packFormulaTypes: list # A list of Pack formula types corresponding to the `packFormulaNames`. If specified, this must have the same length as `packFormulaNames`. (e.g. action,formula)
  --sinceDate: string # Limit results to activity on or after this date. (format: date, e.g. 2020-08-01)
  --untilDate: string # Limit results to activity on or before this date. (format: date, e.g. 2020-08-05)
  --scale: string@scale-completer # Quantization period over which to view analytics. Defaults to daily. (e.g. daily)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --orderBy: string@orderBy-completer-2 # Use this parameter to order the Pack formula analytics returned.
  --direction: string@direction-completer # Direction to sort results in.
  --limit: int # Maximum number of results to return in this query. (default: 1000, e.g. 10)
]: nothing -> record<items: table<formula: record, metrics: list>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packFormulaNames" $packFormulaNames "csv") (serialize-qp "packFormulaTypes" $packFormulaTypes "csv") (serialize-qp "sinceDate" $sinceDate "scalar") (serialize-qp "untilDate" $untilDate "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analytics/packs/($packId)/formulas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analytics last updated day
#
# GET /analytics/updated
# operationId: getAnalyticsLastUpdated
export def "analytics-updated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<docAnalyticsLastUpdated: string, packAnalyticsLastUpdated: string, packFormulaAnalyticsLastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/updated")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspace users
#
# GET /workspaces/{workspaceId}/users
# operationId: listWorkspaceMembers
export def "workspaces-users listWorkspaceMembers" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includedRoles: list # Show only the members that match the included roles. Multiple roles can be specified with a comma-delimited list. (e.g. Editor,DocMaker)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<email: string, name: string, role: string, pictureUrl: string, registeredAt: string, roleChangedAt: string, lastActiveAt: string, ownedDocs: float, docsLastActiveAt: string, docCollaboratorCount: float, totalDocs: float, totalDocsLastActiveAt: string, totalDocCollaboratorsLast90Days: float>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includedRoles" $includedRoles "csv") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspaceId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates user role
#
# POST /workspaces/{workspaceId}/users/role
# operationId: changeUserRole
export def "workspaces-users-role changeUserRole" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email of the user. (e.g. hello@coda.io)
  newRole: string@newRole-completer
]: any -> record<roleChangedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/users/role")
  let body = {email: $email, newRole: $newRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspace roles
#
# GET /workspaces/{workspaceId}/roles
# operationId: listWorkspaceRoleActivity
export def "workspaces-roles listWorkspaceRoleActivity" [
  workspaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<month: string, activeAdminCount: float, activeDocMakerCount: float, activeEditorCount: float, inactiveAdminCount: float, inactiveDocMakerCount: float, inactiveEditorCount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspaceId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Packs
#
# GET /packs
# operationId: listPacks
export def "packs listPacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessType: string@accessType-completer # Deprecated, use accessTypes instead. Filter to only return the Packs for which the current user has this access type (e.g. edit)
  --accessTypes: list # Filter to only return the Packs for which the current user has these access types. (e.g. edit)
  --sortBy: string@sortBy-completer-2 # The sort order of the Packs returned. (e.g. true)
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --direction: string@direction-completer # Direction to sort results in.
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --onlyWorkspaceId: string # Use only this workspace (not all of a user's workspaces) to check for Packs shared via workspace ACL.
  --parentWorkspaceIds: list # Filter to only Packs whose parent workspace is one of the given IDs.
  --excludePublicPacks: oneof<nothing, bool> # Only get Packs shared with users/workspaces, not publicly.
  --packEntrypoint: string@packEntrypoint-completer # Entrypoint for which this pack call is being made. Used to filter non relevant packs
]: nothing -> record<items: table<id: float, logoUrl: string, coverUrl: string, exampleImages: list, agentImages: list, workspaceId: string, categories: list, certified: bool, certifiedAgent: bool, sourceCodeVisibility: string, packEntrypoints: list, verifiedVersion: string, name: string, description: string, shortDescription: string, agentShortDescription: string, agentDescription: string, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accessType" $accessType "scalar") (serialize-qp "accessTypes" $accessTypes "csv") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "onlyWorkspaceId" $onlyWorkspaceId "scalar") (serialize-qp "parentWorkspaceIds" $parentWorkspaceIds "csv") (serialize-qp "excludePublicPacks" $excludePublicPacks "scalar") (serialize-qp "packEntrypoint" $packEntrypoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/packs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Pack
#
# POST /packs
# operationId: createPack
export def "packs createPack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # The parent workspace for the Pack. If unspecified, the user's default workspace will be used. (e.g. ws-asdf)
  --name: string # The name for the Pack. (e.g. Trigonometry)
  --description: string # A brief description of the Pack. (e.g. Common trigonometric functions.)
  --sourcePackId: float # The ID of the new Pack's source, if this new Pack was forked. (nullable, e.g. 10029)
]: any -> record<packId: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/packs")
  let body = {workspaceId: $workspaceId, name: $name, description: $description, sourcePackId: $sourcePackId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single Pack
#
# GET /packs/{packId}
# operationId: getPack
export def "packs get" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, logoUrl: string, coverUrl: string, exampleImages: table<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, agentImages: table<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, workspaceId: string, categories: table<categoryId: string, categoryName: string, categorySlug: string>, certified: bool, certifiedAgent: bool, sourceCodeVisibility: string, packEntrypoints: list<string>, verifiedVersion: string, name: string, description: string, shortDescription: string, agentShortDescription: string, agentDescription: string, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string, overallRateLimit: record<intervalSeconds: int, operationsPerInterval: int>, perConnectionRateLimit: record<intervalSeconds: int, operationsPerInterval: int>, featuredDocStatus: string, additionalInformation: record<videoWalkthrough: string, additionalDetails: string, privacyCollectsPersonalInfo: bool, privacyPersonalInfoCategories: list<string>, privacyDataUsagePurposes: list<string>, privacyDataCollectedBy: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Pack
#
# PATCH /packs/{packId}
# operationId: updatePack
# --overallRateLimit shape: {intervalSeconds: int, operationsPerInterval: int}
# --perConnectionRateLimit shape: {intervalSeconds: int, operationsPerInterval: int}
# --logo shape: {assetId: string, filename: string, mimeType?: string}
# --cover shape: {assetId: string, filename: string, mimeType?: string}
# --exampleImages item shape: {assetId: string, filename: string, mimeType?: string}
# --agentImages item shape: {assetId: string, filename: string, mimeType?: string}
export def "packs updatePack" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overallRateLimit: record # Rate limit in Pack settings. (nullable) — shape: {intervalSeconds: int, operationsPerInterval: int}
  --perConnectionRateLimit: record # Rate limit in Pack settings. (nullable) — shape: {intervalSeconds: int, operationsPerInterval: int}
  --logo: record # Information about an image file for an update Pack request. (nullable) — shape: {assetId: string, filename: string, mimeType?: string}
  --cover: record # Information about an image file for an update Pack request. (nullable) — shape: {assetId: string, filename: string, mimeType?: string}
  --exampleImages: list # The example images for the Pack. (nullable) — item shape: {assetId: string, filename: string, mimeType?: string}
  --agentImages: list # The agent images for the Pack. (nullable) — item shape: {assetId: string, filename: string, mimeType?: string}
  --sourceCodeVisibility: string@sourceCodeVisibility-completer # Visibility of a pack's source code.
  --packEntrypoints: list # Pack entrypoints where this pack is available (nullable)
  --name: string # The name of the Pack. (e.g. Cool Geometry Formulas)
  --description: string # The full description of the Pack. (e.g. This Pack allows users to calculate the surface area and volume of a few common 3D shapes, like cubes and pyramids.)
  --shortDescription: string # A short version of the description of the Pack. (e.g. Calculate cool geometric formulas like surface area.)
  --agentShortDescription: string # A short description for the pack as an agent. (e.g. Chat with a tool that can calculate cool geometric formulas like surface area.)
  --agentDescription: string # A full description for the pack as an agent. (e.g. Chat with a comprehensive tool that can calculate cool geometric formulas like surface area, volume, and other mathematical operations. This agent can help with complex calculations and provide detailed explanations.)
  --supportEmail: string # A contact email for the Pack. (e.g. user@email.com)
  --termsOfServiceUrl: string # A Terms of Service URL for the Pack. (format: url)
  --privacyPolicyUrl: string # A Privacy Policy URL for the Pack. (format: url)
]: any -> record<id: float, logoUrl: string, coverUrl: string, exampleImages: table<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, agentImages: table<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, workspaceId: string, categories: table<categoryId: string, categoryName: string, categorySlug: string>, certified: bool, certifiedAgent: bool, sourceCodeVisibility: string, packEntrypoints: list<string>, verifiedVersion: string, name: string, description: string, shortDescription: string, agentShortDescription: string, agentDescription: string, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string, overallRateLimit: record<intervalSeconds: int, operationsPerInterval: int>, perConnectionRateLimit: record<intervalSeconds: int, operationsPerInterval: int>, featuredDocStatus: string, additionalInformation: record<videoWalkthrough: string, additionalDetails: string, privacyCollectsPersonalInfo: bool, privacyPersonalInfoCategories: list<string>, privacyDataUsagePurposes: list<string>, privacyDataCollectedBy: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)")
  let body = {overallRateLimit: $overallRateLimit, perConnectionRateLimit: $perConnectionRateLimit, logo: $logo, cover: $cover, exampleImages: $exampleImages, agentImages: $agentImages, sourceCodeVisibility: $sourceCodeVisibility, packEntrypoints: $packEntrypoints, name: $name, description: $description, shortDescription: $shortDescription, agentShortDescription: $agentShortDescription, agentDescription: $agentDescription, supportEmail: $supportEmail, termsOfServiceUrl: $termsOfServiceUrl, privacyPolicyUrl: $privacyPolicyUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Pack
#
# DELETE /packs/{packId}
# operationId: deletePack
export def "packs delete" [
  packId: int
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
  let full_url = (build-url $base $"/packs/($packId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the JSON Schema for Pack configuration.
#
# GET /packs/{packId}/configurations/schema
# operationId: getPackConfigurationSchema
export def "packs-configurations-schema get" [
  packId: int
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
  let full_url = (build-url $base $"/packs/($packId)/configurations/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the versions for a Pack.
#
# GET /packs/{packId}/versions
# operationId: listPackVersions
export def "packs-versions listPackVersions" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<packId: float, buildNotes: string, createdAt: string, creationUserLoginId: string, releaseId: float, packVersion: string, sdkVersion: string, source: string>, creationUsers: table<name: string, loginId: string, type: string, pictureLink: string>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the next valid version for a Pack.
#
# POST /packs/{packId}/nextVersion
# operationId: getNextPackVersion
export def "packs-next-version post" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  proposedMetadata: string # The metadata for the next version of the Pack. (e.g. {"formulas": [{"description": "my formula", "name": "foo", "parameters": [], "resultType": 0}]})
  --sdkVersion: string # The SDK version the metadata was built on. (e.g. 1.0.0)
]: any -> record<nextVersion: string, findings: list<string>, findingDetails: table<finding: string, path: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/nextVersion")
  let body = {proposedMetadata: $proposedMetadata, sdkVersion: $sdkVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the difference between two pack versions.
#
# GET /packs/{packId}/versions/{basePackVersion}/diff/{targetPackVersion}
# operationId: getPackVersionDiffs
export def "packs-versions-diff get" [
  packId: int
  basePackVersion: string
  targetPackVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<findings: list<string>, findingDetails: table<finding: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/versions/($basePackVersion)/diff/($targetPackVersion)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register Pack version
#
# POST /packs/{packId}/versions/{packVersion}/register
# operationId: registerPackVersion
export def "packs-versions-register registerPackVersion" [
  packId: int
  packVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  bundleHash: string # The SHA-256 hash of the file to be uploaded. (e.g. f0e4c2f76c58916ec258f246851bea091d14d4247a2fc3e18694461b1816e13b)
]: any -> record<uploadUrl: string, headers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/versions/($packVersion)/register")
  let body = {bundleHash: $bundleHash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pack version upload complete
#
# POST /packs/{packId}/versions/{packVersion}/uploadComplete
# operationId: packVersionUploadComplete
export def "packs-versions-upload-complete packVersionUploadComplete" [
  packId: int
  packVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notes: string # Developer notes of the new Pack version. (e.g. Adding a new formula HelloWorld.)
  --body-source: string@source-completer
  --allowOlderSdkVersion: oneof<nothing, bool> # Bypass Coda's protection against SDK version regression when multiple makers build versions.
]: any -> record<deprecationWarnings: table<path: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/versions/($packVersion)/uploadComplete")
  let body = {notes: $notes, source: $body_source, allowOlderSdkVersion: $allowOlderSdkVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Pack release.
#
# POST /packs/{packId}/releases
# operationId: createPackRelease
export def "packs-releases createPackRelease" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  packVersion: string # Which semantic pack version that the release will be created on. (e.g. 1.0.0)
  --releaseNotes: string # Developers notes. (e.g. The first release.)
]: any -> record<packId: float, releaseNotes: string, createdAt: string, releaseId: float, packVersion: string, sdkVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/releases")
  let body = {packVersion: $packVersion, releaseNotes: $releaseNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the releases for a Pack.
#
# GET /packs/{packId}/releases
# operationId: listPackReleases
export def "packs-releases listPackReleases" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<packId: float, releaseNotes: string, createdAt: string, releaseId: float, packVersion: string, sdkVersion: string>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing Pack release.
#
# PUT /packs/{packId}/releases/{packReleaseId}
# operationId: updatePackRelease
export def "packs-releases updatePackRelease" [
  packId: int
  packReleaseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --releaseNotes: string # Notes about key features or changes in this release that the Pack maker wants to communicate to users. (e.g. The first release.)
]: any -> record<packId: float, releaseNotes: string, createdAt: string, releaseId: float, packVersion: string, sdkVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/releases/($packReleaseId)")
  let body = {releaseNotes: $releaseNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pack reviews
#
# GET /packs/{packId}/reviews
# operationId: listPackReviews
export def "packs-reviews listPackReviews" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return. (default: 25)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --status: string@status-completer # Filter reviews by status.
]: nothing -> record<items: table<packReviewId: string, packId: int, packVersion: string, includesListingReview: bool, packReviewStatus: string, submittedByUserId: int, submissionTimestamp: string, additionalInformation: record>, nextPageToken: string, nextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create pack review
#
# POST /packs/{packId}/reviews
# operationId: createPackReview
export def "packs-reviews createPackReview" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --packVersion: string # Pack version to review (for code reviews)
  --releaseNotes: string # Release notes for this version (used when pack is approved and released)
]: any -> record<packReviewId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/reviews")
  let body = {packVersion: $packVersion, releaseNotes: $releaseNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel pending pack review
#
# POST /packs/{packId}/reviews/pending/cancel
# operationId: cancelPackReview
export def "packs-reviews-pending-cancel cancelPackReview" [
  packId: int
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
  let full_url = (build-url $base $"/packs/($packId)/reviews/pending/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pack listing draft
#
# GET /packs/{packId}/listingDraft
# operationId: getPackListingDraft
export def "packs-listing-draft get" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<packListingDraftId: string, listingData: record<name: string, description: string, shortDescription: string, logo: record<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, cover: record<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, exampleImages: list<record>, agentImages: list<record>, categoryIds: list<string>, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string, sourceCodeVisibility: string, agentShortDescription: string, agentDescription: string, additionalInformation: record<videoWalkthrough: string, additionalDetails: string, privacyCollectsPersonalInfo: bool, privacyPersonalInfoCategories: list, privacyDataUsagePurposes: list, privacyDataCollectedBy: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/listingDraft")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Pack listing draft
#
# PUT /packs/{packId}/listingDraft
# operationId: upsertPackListingDraft
# --listingData shape: {name?: string, description?: string, shortDescription?: string, logo?: record, cover?: record, exampleImages?: list, agentImages?: list, categoryIds?: list, supportEmail?: string, termsOfServiceUrl?: string, privacyPolicyUrl?: string, sourceCodeVisibility?: "private"|"shared", agentShortDescription?: string, agentDescription?: string, additionalInformation?: record}
export def "packs-listing-draft upsertPackListingDraft" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  listingData: record # Input data for creating or updating a Pack listing draft. Agent images only require assetId and filename; the server resolves the full image URL. — shape: {name?: string, description?: string, shortDescription?: string, logo?: record, cover?: record, exampleImages?: list, agentImages?: list, categoryIds?: list, supportEmail?: string, termsOfServiceUrl?: string, privacyPolicyUrl?: string, sourceCodeVisibility?: "private"|"shared", agentShortDescription?: string, agentDescription?: string, additionalInformation?: record}
]: any -> record<packListingDraftId: string, packId: float, listingData: record<name: string, description: string, shortDescription: string, logo: record<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, cover: record<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, exampleImages: list<record>, agentImages: list<record>, categoryIds: list<string>, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string, sourceCodeVisibility: string, agentShortDescription: string, agentDescription: string, additionalInformation: record<videoWalkthrough: string, additionalDetails: string, privacyCollectsPersonalInfo: bool, privacyPersonalInfoCategories: list, privacyDataUsagePurposes: list, privacyDataCollectedBy: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/listingDraft")
  let body = {listingData: $listingData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Pack listing draft
#
# DELETE /packs/{packId}/listingDraft
# operationId: deletePackListingDraft
export def "packs-listing-draft delete" [
  packId: int
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
  let full_url = (build-url $base $"/packs/($packId)/listingDraft")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the OAuth configurations of the Pack.
#
# PUT /packs/{packId}/oauthConfig
# operationId: setPackOauthConfig
export def "packs-oauth-config setPackOauthConfig" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string
  --clientSecret: string
  --redirectUri: string
]: any -> record<maskedClientId: string, maskedClientSecret: string, authorizationUrl: string, tokenUrl: string, tokenPrefix: string, scopes: string, redirectUri: string, useDynamicClientRegistration: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/oauthConfig")
  let body = {clientId: $clientId, clientSecret: $clientSecret, redirectUri: $redirectUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the OAuth configuration of the Pack.
#
# GET /packs/{packId}/oauthConfig
# operationId: getPackOauthConfig
export def "packs-oauth-config get" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<maskedClientId: string, maskedClientSecret: string, authorizationUrl: string, tokenUrl: string, tokenPrefix: string, scopes: string, redirectUri: string, useDynamicClientRegistration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/oauthConfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the system connection credentials of the Pack.
#
# PUT /packs/{packId}/systemConnection
# Discriminator (response): type = header, multiHeader, urlParam, httpBasic, custom, oauth2ClientCredentials, googleServiceAccount, awsAssumeRole, awsAccessKey
# operationId: setPackSystemConnection
export def "packs-system-connection setPackSystemConnection" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credentials: any # Credentials of a Pack connection.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/systemConnection")
  let body = {credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch the system connection credentials of the Pack.
#
# PATCH /packs/{packId}/systemConnection
# Discriminator (request): type = header, multiHeader, urlParam, httpBasic, custom, oauth2ClientCredentials, googleServiceAccount, awsAssumeRole, awsAccessKey
# operationId: patchPackSystemConnection
# --tokensToPatch item shape: {key: string, value: string}
# --paramsToPatch item shape: {key: string, value: string}
export def "packs-system-connection patch" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer
  --body-token: string
  --tokensToPatch: list # item shape: {key: string, value: string}
  --paramsToPatch: list # item shape: {key: string, value: string}
  --username: string
  --password: string
  --clientId: string
  --clientSecret: string
  --serviceAccountKey: string
  --roleArn: string
  --externalId: string
  --accessKeyId: string
  --secretAccessKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/systemConnection")
  let body = {type: $type, token: $body_token, tokensToPatch: $tokensToPatch, paramsToPatch: $paramsToPatch, username: $username, password: $password, clientId: $clientId, clientSecret: $clientSecret, serviceAccountKey: $serviceAccountKey, roleArn: $roleArn, externalId: $externalId, accessKeyId: $accessKeyId, secretAccessKey: $secretAccessKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the system connection metadata of the Pack.
#
# GET /packs/{packId}/systemConnection
# Discriminator (response): type = header, multiHeader, urlParam, httpBasic, custom, oauth2ClientCredentials, googleServiceAccount, awsAssumeRole, awsAccessKey
# operationId: getPackSystemConnection
export def "packs-system-connection get" [
  packId: int
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
  let full_url = (build-url $base $"/packs/($packId)/systemConnection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permissions for a Pack
#
# GET /packs/{packId}/permissions
# operationId: getPackPermissions
export def "packs-permissions get" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, principal: any, access: string>, permissionUsers: table<name: string, loginId: string, type: string, pictureLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a permission for Pack
#
# POST /packs/{packId}/permissions
# operationId: addPackPermission
export def "packs-permissions addPackPermission" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  principal: any # Metadata about a Pack principal.
  access: string@access-completer-1
]: any -> record<permissionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/permissions")
  let body = {principal: $principal, access: $access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user's own permissions for Pack
#
# DELETE /packs/{packId}/permissions
# operationId: deleteUserPackPermission
export def "packs-permissions delete-by-packId" [
  packId: int
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
  let full_url = (build-url $base $"/packs/($packId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a permission for Pack
#
# DELETE /packs/{packId}/permissions/{permissionId}
# operationId: deletePackPermission
export def "packs-permissions delete-by-packId-permissionId" [
  packId: int
  permissionId: string
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
  let full_url = (build-url $base $"/packs/($packId)/permissions/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending Pack invitations for the current user
#
# GET /packs/invitations
# operationId: listUserPackInvitations
export def "packs-invitations listUserPackInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<invitation: record, pack: record, makers: list, networkDomains: list>, nextPageToken: string, nextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/packs/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List invitations for a Pack
#
# GET /packs/{packId}/invitations
# operationId: listPackInvitations
export def "packs-invitations listPackInvitations" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
]: nothing -> record<items: table<invitationId: string, packId: float, inviteeEmail: string, inviterUserId: int, access: string, createdAt: string, expiresAt: string>, nextPageToken: string, nextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invitation for Pack
#
# POST /packs/{packId}/invitations
# operationId: createPackInvitation
export def "packs-invitations createPackInvitation" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email address of the user to invite (e.g. user@example.com)
  access: string@access-completer-1
]: any -> record<invitationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/invitations")
  let body = {email: $email, access: $access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an invitation for Pack
#
# PUT /packs/{packId}/invitations/{invitationId}
# operationId: updatePackInvitation
export def "packs-invitations updatePackInvitation" [
  packId: int
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access: string@access-completer-1
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/invitations/($invitationId)")
  let body = {access: $access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke an invitation for Pack
#
# DELETE /packs/{packId}/invitations/{invitationId}
# operationId: deletePackInvitation
export def "packs-invitations delete" [
  packId: int
  invitationId: string
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
  let full_url = (build-url $base $"/packs/($packId)/invitations/($invitationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reply to a Pack invitation
#
# POST /packs/invitations/{invitationId}/reply
# operationId: replyToPackInvitation
export def "packs-invitations-reply replyToPackInvitation" [
  invitationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-accept: oneof<nothing, bool> # True to accept the invitation, false to reject it
]: any -> record<permissionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/invitations/($invitationId)/reply")
  let body = {accept: $body_accept} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List makers for Pack
#
# GET /packs/{packId}/makers
# operationId: listPackMakers
export def "packs-makers listPackMakers" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<makers: table<name: string, pictureLink: string, slug: string, jobTitle: string, employer: string, description: string, loginId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/makers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a maker for Pack
#
# POST /packs/{packId}/maker
# operationId: addPackMaker
export def "packs-maker addPackMaker" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  loginId: string # The email of the Pack maker. (e.g. api@coda.io)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/maker")
  let body = {loginId: $loginId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a maker for Pack
#
# DELETE /packs/{packId}/maker/{loginId}
# operationId: deletePackMaker
export def "packs-maker delete" [
  packId: int
  loginId: string
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
  let full_url = (build-url $base $"/packs/($packId)/maker/($loginId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List categories for Pack
#
# GET /packs/{packId}/categories
# operationId: listPackCategories
export def "packs-categories listPackCategories" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: table<categoryId: string, categoryName: string, categorySlug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a category for Pack
#
# POST /packs/{packId}/category
# operationId: addPackCategory
export def "packs-category addPackCategory" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  categoryName: string # Name of the publishing category. (e.g. Project management)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/category")
  let body = {categoryName: $categoryName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a category for Pack
#
# DELETE /packs/{packId}/category/{categoryName}
# operationId: deletePackCategory
export def "packs-category delete" [
  packId: int
  categoryName: string
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
  let full_url = (build-url $base $"/packs/($packId)/category/($categoryName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a Pack asset.
#
# POST /packs/{packId}/uploadAsset
# operationId: uploadPackAsset
export def "packs-upload-asset uploadPackAsset" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  packAssetType: string@packAssetType-completer
  imageHash: string # The SHA-256 hash of the image to be uploaded. (e.g. f0e4c2f76c58916ec258f246851bea091d14d4247a2fc3e18694461b1816e13b)
  mimeType: string # The media type of the image being sent. (e.g. image/jpeg)
  filename: string # e.g. image.jpg
]: any -> record<uploadUrl: string, packAssetUploadedPathName: string, headers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/uploadAsset")
  let body = {packAssetType: $packAssetType, imageHash: $imageHash, mimeType: $mimeType, filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload Pack source code.
#
# POST /packs/{packId}/uploadSourceCode
# operationId: uploadPackSourceCode
export def "packs-upload-source-code uploadPackSourceCode" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payloadHash: string # The SHA-256 hash of the image to be uploaded. (e.g. f0e4c2f76c58916ec258f246851bea091d14d4247a2fc3e18694461b1816e13b)
  filename: string # e.g. main.ts
  --packVersion: string # e.g. 1.0.0
]: any -> record<uploadUrl: string, uploadedPathName: string, headers: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/uploadSourceCode")
  let body = {payloadHash: $payloadHash, filename: $filename, packVersion: $packVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pack asset upload complete
#
# POST /packs/{packId}/assets/{packAssetId}/assetType/{packAssetType}/uploadComplete
# operationId: packAssetUploadComplete
export def "packs-assets-asset-type-upload-complete packAssetUploadComplete" [
  packId: int
  packAssetId: string
  packAssetType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<requestId: string, assetId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/assets/($packAssetId)/assetType/($packAssetType)/uploadComplete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pack source code upload complete
#
# POST /packs/{packId}/versions/{packVersion}/sourceCode/uploadComplete
# operationId: packSourceCodeUploadComplete
export def "packs-versions-source-code-upload-complete packSourceCodeUploadComplete" [
  packId: int
  packVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # e.g. main.ts
  codeHash: string # A SHA-256 hash of the source code used to identify duplicate uploads. (e.g. 123456)
]: any -> record<requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/versions/($packVersion)/sourceCode/uploadComplete")
  let body = {filename: $filename, codeHash: $codeHash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get the source code for a Pack version.
#
# GET /packs/{packId}/versions/{packVersion}/sourceCode
# operationId: getPackSourceCode
export def "packs-versions-source-code get" [
  packId: int
  packVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<files: table<filename: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/versions/($packVersion)/sourceCode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the Pack listings accessible to a user.
#
# GET /packs/listings
# operationId: listPackListings
export def "packs-listings listPackListings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --packAccessTypes: list # Pack access types.
  --packIds: list # Which Pack IDs to fetch.
  --onlyWorkspaceId: string # Use only this workspace (not all of a user's workspaces) to check for Packs shared via workspace ACL.
  --parentWorkspaceIds: list # Filter to only Packs whose parent workspace is one of the given IDs.
  --excludePublicPacks: oneof<nothing, bool> # Only get Packs shared with users/workspaces, not publicly.
  --packEntrypoint: string@packEntrypoint-completer # Entrypoint for which this pack call is being made. Used to filter non relevant packs
  --certifiedAgentsOnly: oneof<nothing, bool> # Only include Packs that are certified for agent use. Depending on server configuration, may also include Packs that the user is an admin of.  (default: false)
  --packCategories: list # Filter Packs by one or more category types.
  --sortBy: string@sortBy-completer-3 # Specify a sort order for the returned Pack listings returned.
  --orderBy: string@orderBy-completer-3 # Deprecated: use sortBy instead.
  --direction: string@direction-completer # Direction to sort results in.
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --installContext: string@installContext-completer # Type of installation context for which Pack information is being requested. (e.g. workspace)
]: nothing -> record<items: table<packId: float, packVersion: string, releaseId: float, lastReleasedAt: string, logoUrl: string, logo: record, coverUrl: string, cover: record, exampleImages: list, agentImages: list, name: string, description: string, shortDescription: string, agentShortDescription: string, agentDescription: string, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string, categories: list, makers: list, certified: bool, certifiedAgent: bool, minimumFeatureSet: string, unrestrictedFeatureSet: string, externalMetadataUrl: string, standardPackPlan: record, bundledPackPlan: record, sourceCodeVisibility: string, sdkVersion: string, packCategoryType: string>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "packAccessTypes" $packAccessTypes "csv") (serialize-qp "packIds" $packIds "csv") (serialize-qp "onlyWorkspaceId" $onlyWorkspaceId "scalar") (serialize-qp "parentWorkspaceIds" $parentWorkspaceIds "csv") (serialize-qp "excludePublicPacks" $excludePublicPacks "scalar") (serialize-qp "packEntrypoint" $packEntrypoint "scalar") (serialize-qp "certifiedAgentsOnly" $certifiedAgentsOnly "scalar") (serialize-qp "packCategories" $packCategories "csv") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "installContext" $installContext "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/packs/listings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detailed listing information for a Pack.
#
# GET /packs/{packId}/listing
# operationId: getPackListing
export def "packs-listing get" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspaceId: string # ID of the target workspace (if applicable) for checking installation privileges. (e.g. ws-1Ab234)
  --docId: string # ID of the target document for checking installation privileges (e.g. fleHfrkw3L)
  --ingestionId: string # ID of the target ingestion for checking limit settings (e.g. uuid-uuid-uuid-uuid)
  --installContext: string@installContext-completer # Type of installation context for which Pack information is being requested. (e.g. workspace)
  --releaseChannel: string@releaseChannel-completer # Release channel for which Pack information is being requested. (e.g. LIVE)
]: nothing -> record<packId: float, packVersion: string, releaseId: float, lastReleasedAt: string, logoUrl: string, logo: record<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, coverUrl: string, cover: record<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, exampleImages: table<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, agentImages: table<filename: string, imageUrl: string, assetId: string, altText: string, mimeType: string>, name: string, description: string, shortDescription: string, agentShortDescription: string, agentDescription: string, supportEmail: string, termsOfServiceUrl: string, privacyPolicyUrl: string, categories: table<categoryId: string, categoryName: string, categorySlug: string>, makers: table<name: string, pictureLink: string, slug: string, jobTitle: string, employer: string, description: string>, certified: bool, certifiedAgent: bool, minimumFeatureSet: string, unrestrictedFeatureSet: string, externalMetadataUrl: string, standardPackPlan: record<packPlanId: string, packId: float, pricing: any, createdAt: string>, bundledPackPlan: record<packPlanId: string, packId: float, pricing: record<type: string, minimumFeatureSet: string>, createdAt: string>, sourceCodeVisibility: string, sdkVersion: string, packCategoryType: string, discoverability: string, userAccess: record<canEdit: bool, canTest: bool, canView: bool, canInstall: bool, canPurchase: bool, requiresTrial: bool, canConnectAccount: bool, organization: any, ingestionLimitSettings: record<tableSettings: record, maxBytesPerSyncTableDefault: float, allowedTablesCount: float>>, codaHelpCenterUrl: string, configuration: record<configurationId: string, name: string, policy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspaceId" $workspaceId "scalar") (serialize-qp "docId" $docId "scalar") (serialize-qp "ingestionId" $ingestionId "scalar") (serialize-qp "installContext" $installContext "scalar") (serialize-qp "releaseChannel" $releaseChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/listing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the logs of a Pack.
#
# GET /packs/{packId}/docs/{docId}/logs
# operationId: listPackLogs
export def "packs-docs-logs listPackLogs" [
  packId: int
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --logTypes: list # Only return logs of the given types. (e.g. fetcher,custom)
  --beforeTimestamp: string # Only return logs before the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --afterTimestamp: string # Only return logs after the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --order: string@order-completer # Specifies if the logs will be returned in time desc or asc. Default is desc.
  --q: string # A search query that follows Lucene syntax.  (e.g. context.doc_id:"fleHfrkw3L" AND event.action:"FormulaRequest")
  --requestIds: list # Only return logs matching provided request IDs. (e.g. 416faabf,4127faag)
]: nothing -> record<items: list<any>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "logTypes" $logTypes "csv") (serialize-qp "beforeTimestamp" $beforeTimestamp "scalar") (serialize-qp "afterTimestamp" $afterTimestamp "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "requestIds" $requestIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/docs/($docId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the logs of a Ingestion.
#
# GET /packs/{packId}/tenantId/{tenantId}/rootIngestionId/{rootIngestionId}/logs
# operationId: listIngestionLogs
export def "packs-tenant-id-root-ingestion-id-logs listIngestionLogs" [
  packId: int
  tenantId: string
  rootIngestionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --logTypes: list # Only return logs of the given types. (e.g. fetcher,custom)
  --ingestionExecutionId: string # ID of the ingestion execution. (format: uuid, e.g. a4e293c4-4a85-45a4-b2ba-7f305cba2703)
  --beforeTimestamp: string # Only return logs before the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --afterTimestamp: string # Only return logs after the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --ingestionStatus: string@ingestionStatus-completer # Only fetch logs with the given ingestion status. This only works in combination with the onlyExecutionCompletions parameter.
  --onlyExecutionCompletions: oneof<nothing, bool> # Only fetch logs that represent the completion of a child execution.
  --order: string@order-completer # Specifies if the logs will be returned in time desc or asc. Default is desc.
  --q: string # A search query that follows Lucene syntax.  (e.g. context.doc_id:"fleHfrkw3L" AND event.action:"FormulaRequest")
  --requestIds: list # Only return logs matching provided request IDs. (e.g. 416faabf,4127faag)
]: nothing -> record<items: list<any>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "logTypes" $logTypes "csv") (serialize-qp "ingestionExecutionId" $ingestionExecutionId "scalar") (serialize-qp "beforeTimestamp" $beforeTimestamp "scalar") (serialize-qp "afterTimestamp" $afterTimestamp "scalar") (serialize-qp "ingestionStatus" $ingestionStatus "scalar") (serialize-qp "onlyExecutionCompletions" $onlyExecutionCompletions "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "requestIds" $requestIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/tenantId/($tenantId)/rootIngestionId/($rootIngestionId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the grouped logs of a Pack.
#
# GET /packs/{packId}/docs/{docId}/groupedLogs
# operationId: listGroupedPackLogs
export def "packs-docs-grouped-logs listGroupedPackLogs" [
  packId: int
  docId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --beforeTimestamp: string # Only return logs before the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --afterTimestamp: string # Only return logs after the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --order: string@order-completer # Specifies if the logs will be returned in time desc or asc. Default is desc.
  --q: string # A search query that follows Lucene syntax.  (e.g. context.doc_id:"fleHfrkw3L" AND event.action:"FormulaRequest")
]: nothing -> record<items: list<any>, nextPageToken: string, nextPageLink: record, incompleteRelatedLogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "beforeTimestamp" $beforeTimestamp "scalar") (serialize-qp "afterTimestamp" $afterTimestamp "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/docs/($docId)/groupedLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the grouped logs of a Pack for a specific ingestionExecutionId.
#
# GET /packs/{packId}/tenantId/{tenantId}/rootIngestionId/{rootIngestionId}/groupedLogs
# operationId: listGroupedIngestionLogs
export def "packs-tenant-id-root-ingestion-id-grouped-logs listGroupedIngestionLogs" [
  packId: int
  tenantId: string
  rootIngestionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --ingestionExecutionId: string # ID of the ingestion execution. (format: uuid, e.g. a4e293c4-4a85-45a4-b2ba-7f305cba2703)
  --beforeTimestamp: string # Only return logs before the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --afterTimestamp: string # Only return logs after the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --order: string@order-completer # Specifies if the logs will be returned in time desc or asc. Default is desc.
  --q: string # A search query that follows Lucene syntax.  (e.g. context.doc_id:"fleHfrkw3L" AND event.action:"FormulaRequest")
]: nothing -> record<items: list<any>, nextPageToken: string, nextPageLink: record, incompleteRelatedLogs: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "ingestionExecutionId" $ingestionExecutionId "scalar") (serialize-qp "beforeTimestamp" $beforeTimestamp "scalar") (serialize-qp "afterTimestamp" $afterTimestamp "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/tenantId/($tenantId)/rootIngestionId/($rootIngestionId)/groupedLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of ingestion batch executions for the given root ingestion id.
#
# GET /packs/{packId}/tenantId/{tenantId}/rootIngestionId/{rootIngestionId}/ingestionBatchExecutions
# operationId: listIngestionBatchExecutions
export def "packs-tenant-id-root-ingestion-id-ingestion-batch-executions listIngestionBatchExecutions" [
  packId: int
  tenantId: string
  rootIngestionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --datasource: string # Only show batch executions for this datasource (sync table).
  --executionType: string@executionType-completer # Only show batch executions with this execution type.
  --includeDeletedIngestions: oneof<nothing, bool> # Include deleted ingestion executions in the response
  --ingestionExecutionId: string # Only retrieve this single batch execution.
  --ingestionId: string # Only show batch executions for this sync table ingestion.
  --ingestionStatus: string@ingestionStatus-completer # Only show batch executions with this status.
]: nothing -> record<items: table<completionTimestamp: float, creationTimestamp: float, dynamicLabel: string, dynamicUrl: string, executionType: string, fullExecutionId: string, ingestionExecutionId: string, ingestionId: string, ingestionName: string, ingestionStatusCounts: record, lastFinishedFullWorkflowExecutionId: string, lastFinishedIncrementalWorkflowExecutionId: string, latestFullWorkflowExecutionId: string, latestIncrementalWorkflowExecutionId: string, latestIngestionSequenceId: string, liveIngestionSequenceId: string, parentSyncTableIngestionId: string, startTimestamp: float, totalRowCount: float>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "executionType" $executionType "scalar") (serialize-qp "includeDeletedIngestions" $includeDeletedIngestions "scalar") (serialize-qp "ingestionExecutionId" $ingestionExecutionId "scalar") (serialize-qp "ingestionId" $ingestionId "scalar") (serialize-qp "ingestionStatus" $ingestionStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/tenantId/($tenantId)/rootIngestionId/($rootIngestionId)/ingestionBatchExecutions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of parent items for the given ingestion batch execution id.
#
# GET /packs/{packId}/tenantId/{tenantId}/rootIngestionId/{rootIngestionId}/ingestionBatchExecutions/{ingestionExecutionId}/parentItems
# operationId: listIngestionParentItems
export def "packs-tenant-id-root-ingestion-id-ingestion-batch-executions-parent-items listIngestionParentItems" [
  packId: int
  tenantId: string
  rootIngestionId: string
  ingestionExecutionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --ingestionId: string # The ID of the sync table ingestion. Enables faster lookup. (format: uuid)
  --ingestionStatus: string@ingestionStatus-completer # Only show parent items with this status.
]: nothing -> record<items: table<attemptNumber: float, completionTimestamp: float, errorMessage: string, executionType: string, ingestionChildExecutionIndex: float, ingestionExecutionId: string, ingestionName: string, ingestionStatus: string, parentItemId: string, startTimestamp: float, rowCount: float, latestCheckpointTimestamp: float>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ingestionId" $ingestionId "scalar") (serialize-qp "ingestionStatus" $ingestionStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/tenantId/($tenantId)/rootIngestionId/($rootIngestionId)/ingestionBatchExecutions/($ingestionExecutionId)/parentItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the information for a specific log.
#
# GET /packs/{packId}/tenantId/{tenantId}/rootIngestionId/{rootIngestionId}/logs/{logId}
# Discriminator (response): type = invocation, fetcher, agentRuntime
# operationId: getPackLogDetails
export def "packs-tenant-id-root-ingestion-id-logs get" [
  packId: int
  tenantId: string
  rootIngestionId: string
  logId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailsKey: string # The key of the details to retrieve.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailsKey" $detailsKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packs/($packId)/tenantId/($tenantId)/rootIngestionId/($rootIngestionId)/logs/($logId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List featured docs for a Pack
#
# GET /packs/{packId}/featuredDocs
# operationId: listPackFeaturedDocs
export def "packs-featured-docs listPackFeaturedDocs" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<doc: record, isPinned: bool, docStatus: string, publishedUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/featuredDocs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update featured docs for a Pack
#
# PUT /packs/{packId}/featuredDocs
# operationId: updatePackFeaturedDocs
# --items item shape: {url: string, isPinned?: bool}
export def "packs-featured-docs updatePackFeaturedDocs" [
  packId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # A list of docs to set as the featured docs for a Pack. — item shape: {url: string, isPinned?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packs/($packId)/featuredDocs")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a go link
#
# POST /organizations/{organizationId}/goLinks
# operationId: addGoLink
export def "organizations-go-links addGoLink" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the Go Link that comes after go/. Only alphanumeric characters, dashes, and underscores are allowed.
  destinationUrl: string # The URL that the Go Link redirects to.
  --description: string # Optional description for the Go Link.
  --urlPattern: string # Optional destination URL with {*} placeholders for variables to be inserted. Variables are specified like go/<name>/<var1>/<var2>. (nullable, e.g. https://example.com/{*}/{*})
  --creatorEmail: string # Optional creator email for the Go Link. Only organization admins can set this field. (nullable, e.g. foo@bar.com)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/goLinks")
  let body = {name: $name, destinationUrl: $destinationUrl, description: $description, urlPattern: $urlPattern, creatorEmail: $creatorEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the chat sessions of an agent instance.
#
# GET /go/tenants/{tenantId}/agentInstances/{agentInstanceId}/agentSessionIds
# operationId: listAgentSessionIds
export def "go-tenants-agent-instances-agent-session-ids listAgentSessionIds" [
  tenantId: string
  agentInstanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --agentSessionId: string # ID of the agent chat session. (format: uuid, e.g. a4e293c4-4a85-45a4-b2ba-7f305cba2703)
  --logTypes: list # Only return logs of the given types. (e.g. fetcher,custom)
  --beforeTimestamp: string # Only return logs before the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --afterTimestamp: string # Only return logs after the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --order: string@order-completer # Specifies if the logs will be returned in time desc or asc. Default is desc.
  --q: string # A search query that follows Lucene syntax.  (e.g. trace.id:"a4e293c4-4a85-45a4-b2ba-7f305cba2703" AND event.action:"FormulaRequest")
  --requestIds: list # Only return logs matching provided request IDs. (e.g. 416faabf,4127faag)
]: nothing -> record<items: list<any>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "agentSessionId" $agentSessionId "scalar") (serialize-qp "logTypes" $logTypes "csv") (serialize-qp "beforeTimestamp" $beforeTimestamp "scalar") (serialize-qp "afterTimestamp" $afterTimestamp "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "requestIds" $requestIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/go/tenants/($tenantId)/agentInstances/($agentInstanceId)/agentSessionIds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the logs of an agent instance.
#
# GET /go/tenants/{tenantId}/agentInstances/{agentInstanceId}/logs
# operationId: listAgentLogs
export def "go-tenants-agent-instances-logs listAgentLogs" [
  tenantId: string
  agentInstanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return in this query. (default: 25, e.g. 10)
  --pageToken: string # An opaque token used to fetch the next page of results. (e.g. eyJsaW1pd)
  --logTypes: list # Only return logs of the given types. (e.g. fetcher,custom)
  --agentSessionId: string # ID of the agent chat session. (format: uuid, e.g. a4e293c4-4a85-45a4-b2ba-7f305cba2703)
  --beforeTimestamp: string # Only return logs before the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --afterTimestamp: string # Only return logs after the given time (non-inclusive).  (format: date-time, e.g. 2018-04-11T00:18:57.946Z)
  --order: string@order-completer # Specifies if the logs will be returned in time desc or asc. Default is desc.
  --q: string # A search query that follows Lucene syntax.  (e.g. trace.id:"a4e293c4-4a85-45a4-b2ba-7f305cba2703" AND event.action:"FormulaRequest")
  --requestIds: list # Only return logs matching provided request IDs. (e.g. 416faabf,4127faag)
]: nothing -> record<items: list<any>, nextPageToken: string, nextPageLink: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "logTypes" $logTypes "csv") (serialize-qp "agentSessionId" $agentSessionId "scalar") (serialize-qp "beforeTimestamp" $beforeTimestamp "scalar") (serialize-qp "afterTimestamp" $afterTimestamp "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "requestIds" $requestIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/go/tenants/($tenantId)/agentInstances/($agentInstanceId)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the information for a specific log.
#
# GET /go/tenants/{tenantId}/agentInstances/{agentInstanceId}/logs/{logId}
# Discriminator (response): type = invocation, fetcher, agentRuntime
# operationId: getAgentPackLogDetails
export def "go-tenants-agent-instances-logs get" [
  tenantId: string
  agentInstanceId: string
  logId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailsKey: string # The key of the details to retrieve.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailsKey" $detailsKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/go/tenants/($tenantId)/agentInstances/($agentInstanceId)/logs/($logId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
