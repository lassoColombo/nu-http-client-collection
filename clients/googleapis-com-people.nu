# Auto-generated client for People API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/people/v1/openapi.json
# Auth: --token flag or $env.PEOPLE_API_TOKEN

const BASE_URL = "https://people.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PEOPLE_API_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://people.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def sort-order-completer [] { ["FIRST_NAME_ASCENDING" "LAST_MODIFIED_ASCENDING" "LAST_MODIFIED_DESCENDING" "LAST_NAME_ASCENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "contact-groups list" } } | get name | first)
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

# List all contact groups owned by the authenticated user. Members of the contact groups are not populated.
#
# GET /v1/contactGroups
# operationId: people.contactGroups.list
export def "contact-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, `memberCount`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * memberCount * metadata * name
  --page-size: int # Optional. The maximum number of resources to return. Valid values are between 1 and 1000, inclusive. Defaults to 30 if not set or set to 0.
  --page-token: string # Optional. The next_page_token value returned from a previous call to [ListContactGroups](/people/api/rest/v1/contactgroups/list). Requests the next page of resources.
  --sync-token: string # Optional. A sync token, returned by a previous call to `contactgroups.list`. Only resources changed since the sync token was created will be returned.
]: nothing -> record<contactGroups: table<clientData: list, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list, metadata: record, name: string, resourceName: string>, nextPageToken: string, nextSyncToken: string, totalItems: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "groupFields" $group_fields "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "groupFields": $group_fields, "pageSize": $page_size, "pageToken": $page_token, "syncToken": $sync_token} | compact), body: null}
}

# Create a new contact group owned by the authenticated user. Created contact group names must be unique to the users contact groups. Attempting to create a group with a duplicate name will return a HTTP 409 error. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/contactGroups
# operationId: people.contactGroups.create
# --contactGroup shape: {clientData?: list, etag?: string, metadata?: record, name?: string, resourceName?: string}
export def "contact-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --contact-group: record # A contact group. — shape: {clientData?: list, etag?: string, metadata?: record, name?: string, resourceName?: string}
  --read-group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * metadata * name (format: google-fieldmask)
]: any -> record<clientData: table<key: string, value: string>, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list<string>, metadata: record<deleted: bool, updateTime: string>, name: string, resourceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups" $qp)
  let req_body = {"contactGroup": $contact_group, "readGroupFields": $read_group_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Get a list of contact groups owned by the authenticated user by specifying a list of contact group resource names.
#
# GET /v1/contactGroups:batchGet
# operationId: people.contactGroups.batchGet
export def "contact-groups-batch-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, `memberCount`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * memberCount * metadata * name
  --max-members: int # Optional. Specifies the maximum number of members to return for each group. Defaults to 0 if not set, which will return zero members.
  --resource-names: list<string> # Required. The resource names of the contact groups to get. There is a maximum of 200 resource names.
]: nothing -> record<responses: table<contactGroup: record, requestedResourceName: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "groupFields" $group_fields "scalar") (serialize-qp "maxMembers" $max_members "scalar") (serialize-qp "resourceNames" $resource_names "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups:batchGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "groupFields": $group_fields, "maxMembers": $max_members, "resourceNames": $resource_names} | compact), body: null}
}

# List all "Other contacts", that is contacts that are not in a contact group. "Other contacts" are typically auto created contacts from interactions. Sync tokens expire 7 days after the full sync. A request with an expired sync token will get an error with an [google.rpc.ErrorInfo](https://cloud.google.com/apis/design/errors#error_info) with reason "EXPIRED_SYNC_TOKEN". In the case of such an error clients should make a full sync request without a `sync_token`. The first page of a full sync request has an additional quota. If the quota is exceeded, a 429 error will be returned. This quota is fixed and can not be increased. When the `sync_token` is specified, resources deleted since the last sync will be returned as a person with `PersonMetadata.deleted` set to true. When the `page_token` or `sync_token` is specified, all other request parameters must match the first call. Writes may have a propagation delay of several minutes for sync requests. Incremental syncs are not intended for read-after-write use cases. See example usage at [List the user's other contacts that have changed](/people/v1/other-contacts#list_the_users_other_contacts_that_have_changed).
#
# GET /v1/otherContacts
# operationId: people.otherContacts.list
export def "other-contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Optional. The number of "Other contacts" to include in the response. Valid values are between 1 and 1000, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `otherContacts.list` must match the first call that provided the page token.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. What values are valid depend on what ReadSourceType is used. If READ_SOURCE_TYPE_CONTACT is used, valid values are: * emailAddresses * metadata * names * phoneNumbers * photos If READ_SOURCE_TYPE_PROFILE is used, valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-sync-token: oneof<nothing, bool> # Optional. Whether the response should return `next_sync_token` on the last page of results. It can be used to get incremental changes since the last request by setting it on the request `sync_token`. More details about sync behavior at `otherContacts.list`.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT if not set. Possible values for this field are: * READ_SOURCE_TYPE_CONTACT * READ_SOURCE_TYPE_CONTACT,READ_SOURCE_TYPE_PROFILE Specifying READ_SOURCE_TYPE_PROFILE without specifying READ_SOURCE_TYPE_CONTACT is not permitted.
  --sync-token: string # Optional. A sync token, received from a previous response `next_sync_token` Provide this to retrieve only the resources changed since the last request. When syncing, all other parameters provided to `otherContacts.list` must match the first call that provided the sync token. More details about sync behavior at `otherContacts.list`.
]: nothing -> record<nextPageToken: string, nextSyncToken: string, otherContacts: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "readMask" $read_mask "scalar") (serialize-qp "requestSyncToken" $request_sync_token "scalar") (serialize-qp "sources" $sources "multi") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/otherContacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "readMask": $read_mask, "requestSyncToken": $request_sync_token, "sources": $sources, "syncToken": $sync_token} | compact), body: null}
}

# Provides a list of contacts in the authenticated user's other contacts that matches the search query. The query matches on a contact's `names`, `emailAddresses`, and `phoneNumbers` fields that are from the OTHER_CONTACT source. **IMPORTANT**: Before searching, clients should send a warmup request with an empty query to update the cache. See https://developers.google.com/people/v1/other-contacts#search_the_users_other_contacts
#
# GET /v1/otherContacts:search
# operationId: people.otherContacts.search
export def "other-contacts-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Optional. The number of results to return. Defaults to 10 if field is not set, or set to 0. Values greater than 30 will be capped to 30.
  --query: string # Required. The plain-text query for the request. The query is used to match prefix phrases of the fields on a person. For example, a person with name "foo name" matches queries such as "f", "fo", "foo", "foo n", "nam", etc., but not "oo n".
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * emailAddresses * metadata * names * phoneNumbers
]: nothing -> record<results: table<person: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "readMask" $read_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/otherContacts:search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "query": $query, "readMask": $read_mask} | compact), body: null}
}

# Create a batch of new contacts and return the PersonResponses for the newly Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:batchCreateContacts
# operationId: people.people.batchCreateContacts
# --contacts item shape: {contactPerson?: record}
export def "people-batch-create-contacts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --contacts: list # Required. The contact to create. Allows up to 200 contacts in a single request. — item shape: {contactPerson?: record}
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned in the response. Multiple fields can be specified by separating them with commas. If read mask is left empty, the post-mutate-get is skipped and no data will be returned in the response. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --sources: list<string> # Optional. A mask of what source types to return in the post mutate read. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: any -> record<createdPeople: table<httpStatusCode: int, person: record, requestedResourceName: string, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:batchCreateContacts" $qp)
  let req_body = {"contacts": $contacts, "readMask": $read_mask, "sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Delete a batch of contacts. Any non-contact data will not be deleted. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:batchDeleteContacts
# operationId: people.people.batchDeleteContacts
export def "people-batch-delete-contacts delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --resource-names: list<string> # Required. The resource names of the contact to delete. It's repeatable. Allows up to 500 resource names in a single request.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:batchDeleteContacts" $qp)
  let req_body = {"resourceNames": $resource_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Provides information about a list of specific people by specifying a list of requested resource names. Use `people/me` to indicate the authenticated user. The request returns a 400 error if 'personFields' is not specified.
#
# GET /v1/people:batchGet
# operationId: people.people.getBatchGet
export def "people-batch-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --person-fields: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-mask-include-field: string # Required. Comma-separated list of person fields to be included in the response. Each path should start with `person.`: for example, `person.names` or `person.photos`.
  --resource-names: list<string> # Required. The resource names of the people to provide information about. It's repeatable. The URL query parameter should be resourceNames=&resourceNames=&... - To get information about the authenticated user, specify `people/me`. - To get information about a google account, specify `people/{account_id}`. - To get information about a contact, specify the resource name that identifies the contact as returned by `people.connections.list`. There is a maximum of 200 resource names.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: nothing -> record<responses: table<httpStatusCode: int, person: record, requestedResourceName: string, status: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "personFields" $person_fields "scalar") (serialize-qp "requestMask.includeField" $request_mask_include_field "scalar") (serialize-qp "resourceNames" $resource_names "multi") (serialize-qp "sources" $sources "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:batchGet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "personFields": $person_fields, "requestMask.includeField": $request_mask_include_field, "resourceNames": $resource_names, "sources": $sources} | compact), body: null}
}

# Update a batch of contacts and return a map of resource names to PersonResponses for the updated contacts. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:batchUpdateContacts
# operationId: people.people.batchUpdateContacts
export def "people-batch-update-contacts update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --contacts: record # Required. A map of resource names to the person data to be updated. Allows up to 200 contacts in a single request.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. If read mask is left empty, the post-mutate-get is skipped and no data will be returned in the response. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --update-mask: string # Required. A field mask to restrict which fields on the person are updated. Multiple fields can be specified by separating them with commas. All specified fields will be replaced, or cleared if left empty for each person. Valid values are: * addresses * biographies * birthdays * calendarUrls * clientData * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * relations * sipAddresses * urls * userDefined (format: google-fieldmask)
]: any -> record<updateResult: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:batchUpdateContacts" $qp)
  let req_body = {"contacts": $contacts, "readMask": $read_mask, "sources": $sources, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Create a new contact and return the person resource for that contact. The request returns a 400 error if more than one field is specified on a field that is a singleton for contact sources: * biographies * birthdays * genders * names Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:createContact
# operationId: people.people.createContact
# --addresses item shape: {city?: string, country?: string, countryCode?: string, extendedAddress?: string, formattedValue?: string, metadata?: record, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
# --ageRanges item shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"LESS_THAN_EIGHTEEN"|"EIGHTEEN_TO_TWENTY"|"TWENTY_ONE_OR_OLDER", metadata?: record}
# --biographies item shape: {contentType?: "CONTENT_TYPE_UNSPECIFIED"|"TEXT_PLAIN"|"TEXT_HTML", metadata?: record, value?: string}
# --birthdays item shape: {date?: record, metadata?: record, text?: string}
# --braggingRights item shape: {metadata?: record, value?: string}
# --calendarUrls item shape: {metadata?: record, type?: string, url?: string}
# --clientData item shape: {key?: string, metadata?: record, value?: string}
# --coverPhotos item shape: {metadata?: record, url?: string}
# --emailAddresses item shape: {displayName?: string, metadata?: record, type?: string, value?: string}
# --events item shape: {date?: record, metadata?: record, type?: string}
# --externalIds item shape: {metadata?: record, type?: string, value?: string}
# --fileAses item shape: {metadata?: record, value?: string}
# --genders item shape: {addressMeAs?: string, metadata?: record, value?: string}
# --imClients item shape: {metadata?: record, protocol?: string, type?: string, username?: string}
# --interests item shape: {metadata?: record, value?: string}
# --locales item shape: {metadata?: record, value?: string}
# --locations item shape: {buildingId?: string, current?: bool, deskCode?: string, floor?: string, floorSection?: string, metadata?: record, type?: string, value?: string}
# --memberships item shape: {contactGroupMembership?: record, domainMembership?: record, metadata?: record}
# --metadata shape: {sources?: list}
# --miscKeywords item shape: {metadata?: record, type?: "TYPE_UNSPECIFIED"|"OUTLOOK_BILLING_INFORMATION"|"OUTLOOK_DIRECTORY_SERVER"|"OUTLOOK_KEYWORD"|"OUTLOOK_MILEAGE"|"OUTLOOK_PRIORITY"|"OUTLOOK_SENSITIVITY"|"OUTLOOK_SUBJECT"|"OUTLOOK_USER"|"HOME"|"WORK"|"OTHER", value?: string}
# --names item shape: {familyName?: string, givenName?: string, honorificPrefix?: string, honorificSuffix?: string, metadata?: record, middleName?: string, phoneticFamilyName?: string, phoneticFullName?: string, phoneticGivenName?: string, phoneticHonorificPrefix?: string, phoneticHonorificSuffix?: string, phoneticMiddleName?: string, unstructuredName?: string}
# --nicknames item shape: {metadata?: record, type?: "DEFAULT"|"MAIDEN_NAME"|"INITIALS"|"GPLUS"|"OTHER_NAME"|"ALTERNATE_NAME"|"SHORT_NAME", value?: string}
# --occupations item shape: {metadata?: record, value?: string}
# --organizations item shape: {costCenter?: string, current?: bool, department?: string, domain?: string, endDate?: record, fullTimeEquivalentMillipercent?: int, jobDescription?: string, location?: string, metadata?: record, name?: string, phoneticName?: string, startDate?: record, symbol?: string, title?: string, type?: string}
# --phoneNumbers item shape: {metadata?: record, type?: string, value?: string}
# --photos item shape: {metadata?: record, url?: string}
# --relations item shape: {metadata?: record, person?: string, type?: string}
# --relationshipInterests item shape: {metadata?: record, value?: string}
# --relationshipStatuses item shape: {metadata?: record, value?: string}
# --residences item shape: {current?: bool, metadata?: record, value?: string}
# --sipAddresses item shape: {metadata?: record, type?: string, value?: string}
# --skills item shape: {metadata?: record, value?: string}
# --taglines item shape: {metadata?: record, value?: string}
# --urls item shape: {metadata?: record, type?: string, value?: string}
# --userDefined item shape: {key?: string, metadata?: record, value?: string}
export def "people-create-contact create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --person-fields: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Defaults to all fields if not set. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --addresses: list # The person's street addresses. — item shape: {city?: string, country?: string, countryCode?: string, extendedAddress?: string, formattedValue?: string, metadata?: record, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
  --biographies: list # The person's biographies. This field is a singleton for contact sources. — item shape: {contentType?: "CONTENT_TYPE_UNSPECIFIED"|"TEXT_PLAIN"|"TEXT_HTML", metadata?: record, value?: string}
  --birthdays: list # The person's birthdays. This field is a singleton for contact sources. — item shape: {date?: record, metadata?: record, text?: string}
  --bragging-rights: list # **DEPRECATED**: No data will be returned The person's bragging rights. — item shape: {metadata?: record, value?: string}
  --calendar-urls: list # The person's calendar URLs. — item shape: {metadata?: record, type?: string, url?: string}
  --client-data: list # The person's client data. — item shape: {key?: string, metadata?: record, value?: string}
  --email-addresses: list # The person's email addresses. For `people.connections.list` and `otherContacts.list` the number of email addresses is limited to 100. If a Person has more email addresses the entire set can be obtained by calling GetPeople. — item shape: {displayName?: string, metadata?: record, type?: string, value?: string}
  --etag: string # The [HTTP entity tag](https://en.wikipedia.org/wiki/HTTP_ETag) of the resource. Used for web cache validation.
  --events: list # The person's events. — item shape: {date?: record, metadata?: record, type?: string}
  --external-ids: list # The person's external IDs. — item shape: {metadata?: record, type?: string, value?: string}
  --file-ases: list # The person's file-ases. — item shape: {metadata?: record, value?: string}
  --genders: list # The person's genders. This field is a singleton for contact sources. — item shape: {addressMeAs?: string, metadata?: record, value?: string}
  --im-clients: list # The person's instant messaging clients. — item shape: {metadata?: record, protocol?: string, type?: string, username?: string}
  --interests: list # The person's interests. — item shape: {metadata?: record, value?: string}
  --locales: list # The person's locale preferences. — item shape: {metadata?: record, value?: string}
  --locations: list # The person's locations. — item shape: {buildingId?: string, current?: bool, deskCode?: string, floor?: string, floorSection?: string, metadata?: record, type?: string, value?: string}
  --memberships: list # The person's group memberships. — item shape: {contactGroupMembership?: record, domainMembership?: record, metadata?: record}
  --metadata: record # The metadata about a person. — shape: {sources?: list}
  --misc-keywords: list # The person's miscellaneous keywords. — item shape: {metadata?: record, type?: "TYPE_UNSPECIFIED"|"OUTLOOK_BILLING_INFORMATION"|"OUTLOOK_DIRECTORY_SERVER"|"OUTLOOK_KEYWORD"|"OUTLOOK_MILEAGE"|"OUTLOOK_PRIORITY"|"OUTLOOK_SENSITIVITY"|"OUTLOOK_SUBJECT"|"OUTLOOK_USER"|"HOME"|"WORK"|"OTHER", value?: string}
  --names: list # The person's names. This field is a singleton for contact sources. — item shape: {familyName?: string, givenName?: string, honorificPrefix?: string, honorificSuffix?: string, metadata?: record, middleName?: string, phoneticFamilyName?: string, phoneticFullName?: string, phoneticGivenName?: string, phoneticHonorificPrefix?: string, phoneticHonorificSuffix?: string, phoneticMiddleName?: string, unstructuredName?: string}
  --nicknames: list # The person's nicknames. — item shape: {metadata?: record, type?: "DEFAULT"|"MAIDEN_NAME"|"INITIALS"|"GPLUS"|"OTHER_NAME"|"ALTERNATE_NAME"|"SHORT_NAME", value?: string}
  --occupations: list # The person's occupations. — item shape: {metadata?: record, value?: string}
  --organizations: list # The person's past or current organizations. — item shape: {costCenter?: string, current?: bool, department?: string, domain?: string, endDate?: record, fullTimeEquivalentMillipercent?: int, jobDescription?: string, location?: string, metadata?: record, name?: string, phoneticName?: string, startDate?: record, symbol?: string, title?: string, type?: string}
  --phone-numbers: list # The person's phone numbers. For `people.connections.list` and `otherContacts.list` the number of phone numbers is limited to 100. If a Person has more phone numbers the entire set can be obtained by calling GetPeople. — item shape: {metadata?: record, type?: string, value?: string}
  --relations: list # The person's relations. — item shape: {metadata?: record, person?: string, type?: string}
  --residences: list # **DEPRECATED**: (Please use `person.locations` instead) The person's residences. — item shape: {current?: bool, metadata?: record, value?: string}
  --resource-name: string # The resource name for the person, assigned by the server. An ASCII string in the form of `people/{person_id}`.
  --sip-addresses: list # The person's SIP addresses. — item shape: {metadata?: record, type?: string, value?: string}
  --skills: list # The person's skills. — item shape: {metadata?: record, value?: string}
  --urls: list # The person's associated URLs. — item shape: {metadata?: record, type?: string, value?: string}
  --user-defined: list # The person's user defined data. — item shape: {key?: string, metadata?: record, value?: string}
]: any -> record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "personFields" $person_fields "scalar") (serialize-qp "sources" $sources "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:createContact" $qp)
  let req_body = {"addresses": $addresses, "biographies": $biographies, "birthdays": $birthdays, "braggingRights": $bragging_rights, "calendarUrls": $calendar_urls, "clientData": $client_data, "emailAddresses": $email_addresses, "etag": $etag, "events": $events, "externalIds": $external_ids, "fileAses": $file_ases, "genders": $genders, "imClients": $im_clients, "interests": $interests, "locales": $locales, "locations": $locations, "memberships": $memberships, "metadata": $metadata, "miscKeywords": $misc_keywords, "names": $names, "nicknames": $nicknames, "occupations": $occupations, "organizations": $organizations, "phoneNumbers": $phone_numbers, "relations": $relations, "residences": $residences, "resourceName": $resource_name, "sipAddresses": $sip_addresses, "skills": $skills, "urls": $urls, "userDefined": $user_defined} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "personFields": $person_fields, "sources": $sources} | compact), body: $req_body}
}

# Provides a list of domain profiles and domain contacts in the authenticated user's domain directory. When the `sync_token` is specified, resources deleted since the last sync will be returned as a person with `PersonMetadata.deleted` set to true. When the `page_token` or `sync_token` is specified, all other request parameters must match the first call. Writes may have a propagation delay of several minutes for sync requests. Incremental syncs are not intended for read-after-write use cases. See example usage at [List the directory people that have changed](/people/v1/directory#list_the_directory_people_that_have_changed).
#
# GET /v1/people:listDirectoryPeople
# operationId: people.people.listDirectoryPeople
export def "people-list-directory-people list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --merge-sources: list<string> # Optional. Additional data to merge into the directory sources if they are connected through verified join keys such as email addresses or phone numbers.
  --page-size: int # Optional. The number of people to include in the response. Valid values are between 1 and 1000, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `people.listDirectoryPeople` must match the first call that provided the page token.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-sync-token: oneof<nothing, bool> # Optional. Whether the response should return `next_sync_token`. It can be used to get incremental changes since the last request by setting it on the request `sync_token`. More details about sync behavior at `people.listDirectoryPeople`.
  --sources: list<string> # Required. Directory sources to return.
  --sync-token: string # Optional. A sync token, received from a previous response `next_sync_token` Provide this to retrieve only the resources changed since the last request. When syncing, all other parameters provided to `people.listDirectoryPeople` must match the first call that provided the sync token. More details about sync behavior at `people.listDirectoryPeople`.
]: nothing -> record<nextPageToken: string, nextSyncToken: string, people: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "mergeSources" $merge_sources "multi") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "readMask" $read_mask "scalar") (serialize-qp "requestSyncToken" $request_sync_token "scalar") (serialize-qp "sources" $sources "multi") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:listDirectoryPeople" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "mergeSources": $merge_sources, "pageSize": $page_size, "pageToken": $page_token, "readMask": $read_mask, "requestSyncToken": $request_sync_token, "sources": $sources, "syncToken": $sync_token} | compact), body: null}
}

# Provides a list of contacts in the authenticated user's grouped contacts that matches the search query. The query matches on a contact's `names`, `nickNames`, `emailAddresses`, `phoneNumbers`, and `organizations` fields that are from the CONTACT source. **IMPORTANT**: Before searching, clients should send a warmup request with an empty query to update the cache. See https://developers.google.com/people/v1/contacts#search_the_users_contacts
#
# GET /v1/people:searchContacts
# operationId: people.people.searchContacts
export def "people-search-contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Optional. The number of results to return. Defaults to 10 if field is not set, or set to 0. Values greater than 30 will be capped to 30.
  --query: string # Required. The plain-text query for the request. The query is used to match prefix phrases of the fields on a person. For example, a person with name "foo name" matches queries such as "f", "fo", "foo", "foo n", "nam", etc., but not "oo n".
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT if not set.
]: nothing -> record<results: table<person: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "readMask" $read_mask "scalar") (serialize-qp "sources" $sources "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:searchContacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "query": $query, "readMask": $read_mask, "sources": $sources} | compact), body: null}
}

# Provides a list of domain profiles and domain contacts in the authenticated user's domain directory that match the search query.
#
# GET /v1/people:searchDirectoryPeople
# operationId: people.people.searchDirectoryPeople
export def "people-search-directory-people list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --merge-sources: list<string> # Optional. Additional data to merge into the directory sources if they are connected through verified join keys such as email addresses or phone numbers.
  --page-size: int # Optional. The number of people to include in the response. Valid values are between 1 and 500, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `SearchDirectoryPeople` must match the first call that provided the page token.
  --query: string # Required. Prefix query that matches fields in the person. Does NOT use the read_mask for determining what fields to match.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Required. Directory sources to return.
]: nothing -> record<nextPageToken: string, people: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "mergeSources" $merge_sources "multi") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "readMask" $read_mask "scalar") (serialize-qp "sources" $sources "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/people:searchDirectoryPeople" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "mergeSources": $merge_sources, "pageSize": $page_size, "pageToken": $page_token, "query": $query, "readMask": $read_mask, "sources": $sources} | compact), body: null}
}

# Delete an existing contact group owned by the authenticated user by specifying a contact group resource name. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# DELETE /v1/{resourceName}
# operationId: people.contactGroups.delete
export def "contact-groups delete" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --delete-contacts: oneof<nothing, bool> # Optional. Set to true to also delete the contacts in the specified group.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "deleteContacts" $delete_contacts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "deleteContacts": $delete_contacts} | compact), body: null}
}

# Provides information about a person by specifying a resource name. Use `people/me` to indicate the authenticated user. The request returns a 400 error if 'personFields' is not specified.
#
# GET /v1/{resourceName}
# operationId: people.people.get
export def "people get" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --person-fields: string # Required. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-mask-include-field: string # Required. Comma-separated list of person fields to be included in the response. Each path should start with `person.`: for example, `person.names` or `person.photos`.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_PROFILE and READ_SOURCE_TYPE_CONTACT if not set.
]: nothing -> record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "personFields" $person_fields "scalar") (serialize-qp "requestMask.includeField" $request_mask_include_field "scalar") (serialize-qp "sources" $sources "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "personFields": $person_fields, "requestMask.includeField": $request_mask_include_field, "sources": $sources} | compact), body: null}
}

# Update the name of an existing contact group owned by the authenticated user. Updated contact group names must be unique to the users contact groups. Attempting to create a group with a duplicate name will return a HTTP 409 error. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# PUT /v1/{resourceName}
# operationId: people.contactGroups.update
# --contactGroup shape: {clientData?: list, etag?: string, metadata?: record, name?: string, resourceName?: string}
export def "contact-groups update" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --contact-group: record # A contact group. — shape: {clientData?: list, etag?: string, metadata?: record, name?: string, resourceName?: string}
  --read-group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * memberCount * metadata * name (format: google-fieldmask)
  --update-group-fields: string # Optional. A field mask to restrict which fields on the group are updated. Multiple fields can be specified by separating them with commas. Defaults to `name` if not set or set to empty. Updated fields are replaced. Valid values are: * clientData * name (format: google-fieldmask)
]: any -> record<clientData: table<key: string, value: string>, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list<string>, metadata: record<deleted: bool, updateTime: string>, name: string, resourceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}") $qp)
  let req_body = {"contactGroup": $contact_group, "readGroupFields": $read_group_fields, "updateGroupFields": $update_group_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Provides a list of the authenticated user's contacts. Sync tokens expire 7 days after the full sync. A request with an expired sync token will get an error with an [google.rpc.ErrorInfo](https://cloud.google.com/apis/design/errors#error_info) with reason "EXPIRED_SYNC_TOKEN". In the case of such an error clients should make a full sync request without a `sync_token`. The first page of a full sync request has an additional quota. If the quota is exceeded, a 429 error will be returned. This quota is fixed and can not be increased. When the `sync_token` is specified, resources deleted since the last sync will be returned as a person with `PersonMetadata.deleted` set to true. When the `page_token` or `sync_token` is specified, all other request parameters must match the first call. Writes may have a propagation delay of several minutes for sync requests. Incremental syncs are not intended for read-after-write use cases. See example usage at [List the user's contacts that have changed](/people/v1/contacts#list_the_users_contacts_that_have_changed).
#
# GET /v1/{resourceName}/connections
# operationId: people.people.connections.list
export def "connections list" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --page-size: int # Optional. The number of connections to include in the response. Valid values are between 1 and 1000, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `people.connections.list` must match the first call that provided the page token.
  --person-fields: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-mask-include-field: string # Required. Comma-separated list of person fields to be included in the response. Each path should start with `person.`: for example, `person.names` or `person.photos`.
  --request-sync-token: oneof<nothing, bool> # Optional. Whether the response should return `next_sync_token` on the last page of results. It can be used to get incremental changes since the last request by setting it on the request `sync_token`. More details about sync behavior at `people.connections.list`.
  --sort-order: string@sort-order-completer # Optional. The order in which the connections should be sorted. Defaults to `LAST_MODIFIED_ASCENDING`.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --sync-token: string # Optional. A sync token, received from a previous response `next_sync_token` Provide this to retrieve only the resources changed since the last request. When syncing, all other parameters provided to `people.connections.list` must match the first call that provided the sync token. More details about sync behavior at `people.connections.list`.
]: nothing -> record<connections: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, nextPageToken: string, nextSyncToken: string, totalItems: int, totalPeople: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "personFields" $person_fields "scalar") (serialize-qp "requestMask.includeField" $request_mask_include_field "scalar") (serialize-qp "requestSyncToken" $request_sync_token "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "sources" $sources "multi") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "personFields": $person_fields, "requestMask.includeField": $request_mask_include_field, "requestSyncToken": $request_sync_token, "sortOrder": $sort_order, "sources": $sources, "syncToken": $sync_token} | compact), body: null}
}

# Modify the members of a contact group owned by the authenticated user. The only system contact groups that can have members added are `contactGroups/myContacts` and `contactGroups/starred`. Other system contact groups are deprecated and can only have contacts removed.
#
# POST /v1/{resourceName}/members:modify
# operationId: people.contactGroups.members.modify
export def "members-modify create" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --resource-names-to-add: list<string> # Optional. The resource names of the contact people to add in the form of `people/{person_id}`. The total number of resource names in `resource_names_to_add` and `resource_names_to_remove` must be less than or equal to 1000.
  --resource-names-to-remove: list<string> # Optional. The resource names of the contact people to remove in the form of `people/{person_id}`. The total number of resource names in `resource_names_to_add` and `resource_names_to_remove` must be less than or equal to 1000.
]: any -> record<canNotRemoveLastContactGroupResourceNames: list<string>, notFoundResourceNames: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}/members:modify") $qp)
  let req_body = {"resourceNamesToAdd": $resource_names_to_add, "resourceNamesToRemove": $resource_names_to_remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Copies an "Other contact" to a new contact in the user's "myContacts" group Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/{resourceName}:copyOtherContactToMyContactsGroup
# operationId: people.otherContacts.copyOtherContactToMyContactsGroup
export def "other-contacts copy-to-my-group" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --copy-mask: string # Required. A field mask to restrict which fields are copied into the new contact. Valid values are: * emailAddresses * names * phoneNumbers (format: google-fieldmask)
  --read-mask: string # Optional. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Defaults to the copy mask with metadata and membership fields if not set. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: any -> record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}:copyOtherContactToMyContactsGroup") $qp)
  let req_body = {"copyMask": $copy_mask, "readMask": $read_mask, "sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Delete a contact person. Any non-contact data will not be deleted. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# DELETE /v1/{resourceName}:deleteContact
# operationId: people.people.deleteContact
export def "people delete-contact" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}:deleteContact") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Delete a contact's photo. Mutate requests for the same user should be done sequentially to avoid // lock contention.
#
# DELETE /v1/{resourceName}:deleteContactPhoto
# operationId: people.people.deleteContactPhoto
export def "people delete-contact-photo" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --person-fields: string # Optional. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Defaults to empty if not set, which will skip the post mutate get. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: nothing -> record<person: record<addresses: list<record>, ageRange: string, ageRanges: list<record>, biographies: list<record>, birthdays: list<record>, braggingRights: list<record>, calendarUrls: list<record>, clientData: list<record>, coverPhotos: list<record>, emailAddresses: list<record>, etag: string, events: list<record>, externalIds: list<record>, fileAses: list<record>, genders: list<record>, imClients: list<record>, interests: list<record>, locales: list<record>, locations: list<record>, memberships: list<record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list, objectType: string, previousResourceNames: list, sources: list>, miscKeywords: list<record>, names: list<record>, nicknames: list<record>, occupations: list<record>, organizations: list<record>, phoneNumbers: list<record>, photos: list<record>, relations: list<record>, relationshipInterests: list<record>, relationshipStatuses: list<record>, residences: list<record>, resourceName: string, sipAddresses: list<record>, skills: list<record>, taglines: list<record>, urls: list<record>, userDefined: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "personFields" $person_fields "scalar") (serialize-qp "sources" $sources "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}:deleteContactPhoto") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "personFields": $person_fields, "sources": $sources} | compact), body: null}
}

# Update contact data for an existing contact person. Any non-contact data will not be modified. Any non-contact data in the person to update will be ignored. All fields specified in the `update_mask` will be replaced. The server returns a 400 error if `person.metadata.sources` is not specified for the contact to be updated or if there is no contact source. The server returns a 400 error with reason `"failedPrecondition"` if `person.metadata.sources.etag` is different than the contact's etag, which indicates the contact has changed since its data was read. Clients should get the latest person and merge their updates into the latest person. The server returns a 400 error if `memberships` are being updated and there are no contact group memberships specified on the person. The server returns a 400 error if more than one field is specified on a field that is a singleton for contact sources: * biographies * birthdays * genders * names Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# PATCH /v1/{resourceName}:updateContact
# operationId: people.people.updateContact
# --addresses item shape: {city?: string, country?: string, countryCode?: string, extendedAddress?: string, formattedValue?: string, metadata?: record, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
# --ageRanges item shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"LESS_THAN_EIGHTEEN"|"EIGHTEEN_TO_TWENTY"|"TWENTY_ONE_OR_OLDER", metadata?: record}
# --biographies item shape: {contentType?: "CONTENT_TYPE_UNSPECIFIED"|"TEXT_PLAIN"|"TEXT_HTML", metadata?: record, value?: string}
# --birthdays item shape: {date?: record, metadata?: record, text?: string}
# --braggingRights item shape: {metadata?: record, value?: string}
# --calendarUrls item shape: {metadata?: record, type?: string, url?: string}
# --clientData item shape: {key?: string, metadata?: record, value?: string}
# --coverPhotos item shape: {metadata?: record, url?: string}
# --emailAddresses item shape: {displayName?: string, metadata?: record, type?: string, value?: string}
# --events item shape: {date?: record, metadata?: record, type?: string}
# --externalIds item shape: {metadata?: record, type?: string, value?: string}
# --fileAses item shape: {metadata?: record, value?: string}
# --genders item shape: {addressMeAs?: string, metadata?: record, value?: string}
# --imClients item shape: {metadata?: record, protocol?: string, type?: string, username?: string}
# --interests item shape: {metadata?: record, value?: string}
# --locales item shape: {metadata?: record, value?: string}
# --locations item shape: {buildingId?: string, current?: bool, deskCode?: string, floor?: string, floorSection?: string, metadata?: record, type?: string, value?: string}
# --memberships item shape: {contactGroupMembership?: record, domainMembership?: record, metadata?: record}
# --metadata shape: {sources?: list}
# --miscKeywords item shape: {metadata?: record, type?: "TYPE_UNSPECIFIED"|"OUTLOOK_BILLING_INFORMATION"|"OUTLOOK_DIRECTORY_SERVER"|"OUTLOOK_KEYWORD"|"OUTLOOK_MILEAGE"|"OUTLOOK_PRIORITY"|"OUTLOOK_SENSITIVITY"|"OUTLOOK_SUBJECT"|"OUTLOOK_USER"|"HOME"|"WORK"|"OTHER", value?: string}
# --names item shape: {familyName?: string, givenName?: string, honorificPrefix?: string, honorificSuffix?: string, metadata?: record, middleName?: string, phoneticFamilyName?: string, phoneticFullName?: string, phoneticGivenName?: string, phoneticHonorificPrefix?: string, phoneticHonorificSuffix?: string, phoneticMiddleName?: string, unstructuredName?: string}
# --nicknames item shape: {metadata?: record, type?: "DEFAULT"|"MAIDEN_NAME"|"INITIALS"|"GPLUS"|"OTHER_NAME"|"ALTERNATE_NAME"|"SHORT_NAME", value?: string}
# --occupations item shape: {metadata?: record, value?: string}
# --organizations item shape: {costCenter?: string, current?: bool, department?: string, domain?: string, endDate?: record, fullTimeEquivalentMillipercent?: int, jobDescription?: string, location?: string, metadata?: record, name?: string, phoneticName?: string, startDate?: record, symbol?: string, title?: string, type?: string}
# --phoneNumbers item shape: {metadata?: record, type?: string, value?: string}
# --photos item shape: {metadata?: record, url?: string}
# --relations item shape: {metadata?: record, person?: string, type?: string}
# --relationshipInterests item shape: {metadata?: record, value?: string}
# --relationshipStatuses item shape: {metadata?: record, value?: string}
# --residences item shape: {current?: bool, metadata?: record, value?: string}
# --sipAddresses item shape: {metadata?: record, type?: string, value?: string}
# --skills item shape: {metadata?: record, value?: string}
# --taglines item shape: {metadata?: record, value?: string}
# --urls item shape: {metadata?: record, type?: string, value?: string}
# --userDefined item shape: {key?: string, metadata?: record, value?: string}
export def "people update-contact" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --person-fields: string # Optional. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Defaults to all fields if not set. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --update-person-fields: string # Required. A field mask to restrict which fields on the person are updated. Multiple fields can be specified by separating them with commas. All updated fields will be replaced. Valid values are: * addresses * biographies * birthdays * calendarUrls * clientData * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * relations * sipAddresses * urls * userDefined
  --addresses: list # The person's street addresses. — item shape: {city?: string, country?: string, countryCode?: string, extendedAddress?: string, formattedValue?: string, metadata?: record, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
  --biographies: list # The person's biographies. This field is a singleton for contact sources. — item shape: {contentType?: "CONTENT_TYPE_UNSPECIFIED"|"TEXT_PLAIN"|"TEXT_HTML", metadata?: record, value?: string}
  --birthdays: list # The person's birthdays. This field is a singleton for contact sources. — item shape: {date?: record, metadata?: record, text?: string}
  --bragging-rights: list # **DEPRECATED**: No data will be returned The person's bragging rights. — item shape: {metadata?: record, value?: string}
  --calendar-urls: list # The person's calendar URLs. — item shape: {metadata?: record, type?: string, url?: string}
  --client-data: list # The person's client data. — item shape: {key?: string, metadata?: record, value?: string}
  --email-addresses: list # The person's email addresses. For `people.connections.list` and `otherContacts.list` the number of email addresses is limited to 100. If a Person has more email addresses the entire set can be obtained by calling GetPeople. — item shape: {displayName?: string, metadata?: record, type?: string, value?: string}
  --etag: string # The [HTTP entity tag](https://en.wikipedia.org/wiki/HTTP_ETag) of the resource. Used for web cache validation.
  --events: list # The person's events. — item shape: {date?: record, metadata?: record, type?: string}
  --external-ids: list # The person's external IDs. — item shape: {metadata?: record, type?: string, value?: string}
  --file-ases: list # The person's file-ases. — item shape: {metadata?: record, value?: string}
  --genders: list # The person's genders. This field is a singleton for contact sources. — item shape: {addressMeAs?: string, metadata?: record, value?: string}
  --im-clients: list # The person's instant messaging clients. — item shape: {metadata?: record, protocol?: string, type?: string, username?: string}
  --interests: list # The person's interests. — item shape: {metadata?: record, value?: string}
  --locales: list # The person's locale preferences. — item shape: {metadata?: record, value?: string}
  --locations: list # The person's locations. — item shape: {buildingId?: string, current?: bool, deskCode?: string, floor?: string, floorSection?: string, metadata?: record, type?: string, value?: string}
  --memberships: list # The person's group memberships. — item shape: {contactGroupMembership?: record, domainMembership?: record, metadata?: record}
  --metadata: record # The metadata about a person. — shape: {sources?: list}
  --misc-keywords: list # The person's miscellaneous keywords. — item shape: {metadata?: record, type?: "TYPE_UNSPECIFIED"|"OUTLOOK_BILLING_INFORMATION"|"OUTLOOK_DIRECTORY_SERVER"|"OUTLOOK_KEYWORD"|"OUTLOOK_MILEAGE"|"OUTLOOK_PRIORITY"|"OUTLOOK_SENSITIVITY"|"OUTLOOK_SUBJECT"|"OUTLOOK_USER"|"HOME"|"WORK"|"OTHER", value?: string}
  --names: list # The person's names. This field is a singleton for contact sources. — item shape: {familyName?: string, givenName?: string, honorificPrefix?: string, honorificSuffix?: string, metadata?: record, middleName?: string, phoneticFamilyName?: string, phoneticFullName?: string, phoneticGivenName?: string, phoneticHonorificPrefix?: string, phoneticHonorificSuffix?: string, phoneticMiddleName?: string, unstructuredName?: string}
  --nicknames: list # The person's nicknames. — item shape: {metadata?: record, type?: "DEFAULT"|"MAIDEN_NAME"|"INITIALS"|"GPLUS"|"OTHER_NAME"|"ALTERNATE_NAME"|"SHORT_NAME", value?: string}
  --occupations: list # The person's occupations. — item shape: {metadata?: record, value?: string}
  --organizations: list # The person's past or current organizations. — item shape: {costCenter?: string, current?: bool, department?: string, domain?: string, endDate?: record, fullTimeEquivalentMillipercent?: int, jobDescription?: string, location?: string, metadata?: record, name?: string, phoneticName?: string, startDate?: record, symbol?: string, title?: string, type?: string}
  --phone-numbers: list # The person's phone numbers. For `people.connections.list` and `otherContacts.list` the number of phone numbers is limited to 100. If a Person has more phone numbers the entire set can be obtained by calling GetPeople. — item shape: {metadata?: record, type?: string, value?: string}
  --relations: list # The person's relations. — item shape: {metadata?: record, person?: string, type?: string}
  --residences: list # **DEPRECATED**: (Please use `person.locations` instead) The person's residences. — item shape: {current?: bool, metadata?: record, value?: string}
  --body-resource-name: string # The resource name for the person, assigned by the server. An ASCII string in the form of `people/{person_id}`.
  --sip-addresses: list # The person's SIP addresses. — item shape: {metadata?: record, type?: string, value?: string}
  --skills: list # The person's skills. — item shape: {metadata?: record, value?: string}
  --urls: list # The person's associated URLs. — item shape: {metadata?: record, type?: string, value?: string}
  --user-defined: list # The person's user defined data. — item shape: {key?: string, metadata?: record, value?: string}
]: any -> record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "personFields" $person_fields "scalar") (serialize-qp "sources" $sources "multi") (serialize-qp "updatePersonFields" $update_person_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}:updateContact") $qp)
  let req_body = {"addresses": $addresses, "biographies": $biographies, "birthdays": $birthdays, "braggingRights": $bragging_rights, "calendarUrls": $calendar_urls, "clientData": $client_data, "emailAddresses": $email_addresses, "etag": $etag, "events": $events, "externalIds": $external_ids, "fileAses": $file_ases, "genders": $genders, "imClients": $im_clients, "interests": $interests, "locales": $locales, "locations": $locations, "memberships": $memberships, "metadata": $metadata, "miscKeywords": $misc_keywords, "names": $names, "nicknames": $nicknames, "occupations": $occupations, "organizations": $organizations, "phoneNumbers": $phone_numbers, "relations": $relations, "residences": $residences, "resourceName": $body_resource_name, "sipAddresses": $sip_addresses, "skills": $skills, "urls": $urls, "userDefined": $user_defined} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "personFields": $person_fields, "sources": $sources, "updatePersonFields": $update_person_fields} | compact), body: $req_body}
}

# Update a contact's photo. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# PATCH /v1/{resourceName}:updateContactPhoto
# operationId: people.people.updateContactPhoto
export def "people update-contact-photo" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --person-fields: string # Optional. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Defaults to empty if not set, which will skip the post mutate get. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --photo-bytes: string # Required. Raw photo bytes (format: byte)
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: any -> record<person: record<addresses: list<record>, ageRange: string, ageRanges: list<record>, biographies: list<record>, birthdays: list<record>, braggingRights: list<record>, calendarUrls: list<record>, clientData: list<record>, coverPhotos: list<record>, emailAddresses: list<record>, etag: string, events: list<record>, externalIds: list<record>, fileAses: list<record>, genders: list<record>, imClients: list<record>, interests: list<record>, locales: list<record>, locations: list<record>, memberships: list<record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list, objectType: string, previousResourceNames: list, sources: list>, miscKeywords: list<record>, names: list<record>, nicknames: list<record>, occupations: list<record>, organizations: list<record>, phoneNumbers: list<record>, photos: list<record>, relations: list<record>, relationshipInterests: list<record>, relationshipStatuses: list<record>, residences: list<record>, resourceName: string, sipAddresses: list<record>, skills: list<record>, taglines: list<record>, urls: list<record>, userDefined: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v1/{resource_name}:updateContactPhoto") $qp)
  let req_body = {"personFields": $person_fields, "photoBytes": $photo_bytes, "sources": $sources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}
