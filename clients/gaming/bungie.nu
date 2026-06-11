# Auto-generated client for Bungie.Net API v2.21.9
# Source: https://raw.githubusercontent.com/Bungie-net/api/master/openapi.json
# Auth: --token flag or $env.BUNGIE_API_KEY

const BASE_URL = "https://www.bungie.net/Platform"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUNGIE_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://www.bungie.net/Platform"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app-api-usage AppGetApplicationApiUsage" } } | get name | first)
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

# Get API usage by application for time frame specified. You can go as far back as 30 days ago, and can ask for up to a 48 hour window of time in a single request. You must be authenticated with at least the ReadUserData permission to access this endpoint.
#
# GET /App/ApiUsage/{applicationId}/
# operationId: App.GetApplicationApiUsage
export def "app-api-usage AppGetApplicationApiUsage" [
  applicationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --end: string # End time for query. Goes to now if not specified. (format: date-time)
  --start: string # Start time for query. Goes to 24 hours ago if not specified. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "end" $end "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/App/ApiUsage/($applicationId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of applications created by Bungie.
#
# GET /App/FirstParty/
# operationId: App.GetBungieApplications
export def "app-first-party AppGetBungieApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/App/FirstParty/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Loads a bungienet user by membership id.
#
# GET /User/GetBungieNetUserById/{id}/
# operationId: User.GetBungieNetUserById
export def "user-get-bungie-net-user-by-id UserGetBungieNetUserById" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/GetBungieNetUserById/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of all display names linked to this membership id but sanitized (profanity filtered). Obeys all visibility rules of calling user and is heavily cached.
#
# GET /User/GetSanitizedPlatformDisplayNames/{membershipId}/
# operationId: User.GetSanitizedPlatformDisplayNames
export def "user-get-sanitized-platform-display-names UserGetSanitizedPlatformDisplayNames" [
  membershipId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/GetSanitizedPlatformDisplayNames/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of credential types attached to the requested account
#
# GET /User/GetCredentialTypesForTargetAccount/{membershipId}/
# operationId: User.GetCredentialTypesForTargetAccount
export def "user-get-credential-types-for-target-account UserGetCredentialTypesForTargetAccount" [
  membershipId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/GetCredentialTypesForTargetAccount/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all available user themes.
#
# GET /User/GetAvailableThemes/
# operationId: User.GetAvailableThemes
export def "user-get-available-themes UserGetAvailableThemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/User/GetAvailableThemes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of accounts associated with the supplied membership ID and membership type. This will include all linked accounts (even when hidden) if supplied credentials permit it.
#
# GET /User/GetMembershipsById/{membershipId}/{membershipType}/
# operationId: User.GetMembershipDataById
export def "user-get-memberships-by-id UserGetMembershipDataById" [
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/GetMembershipsById/($membershipId)/($membershipType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of accounts associated with signed in user. This is useful for OAuth implementations that do not give you access to the token response.
#
# GET /User/GetMembershipsForCurrentUser/
# operationId: User.GetMembershipDataForCurrentUser
export def "user-get-memberships-for-current-user UserGetMembershipDataForCurrentUser" [
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
  let full_url = (build-url $base "/User/GetMembershipsForCurrentUser/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets any hard linked membership given a credential. Only works for credentials that are public (just SteamID64 right now). Cross Save aware.
#
# GET /User/GetMembershipFromHardLinkedCredential/{crType}/{credential}/
# operationId: User.GetMembershipFromHardLinkedCredential
export def "user-get-membership-from-hard-linked-credential UserGetMembershipFromHardLinkedCredential" [
  credential: string
  crType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/GetMembershipFromHardLinkedCredential/($crType)/($credential)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [OBSOLETE] Do not use this to search users, use SearchByGlobalNamePost instead.
#
# GET /User/Search/Prefix/{displayNamePrefix}/{page}/
# operationId: User.SearchByGlobalNamePrefix
export def "user-search-prefix UserSearchByGlobalNamePrefix" [
  displayNamePrefix: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/Search/Prefix/($displayNamePrefix)/($page)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Given the prefix of a global display name, returns all users who share that name.
#
# POST /User/Search/GlobalName/{page}/
# operationId: User.SearchByGlobalNamePost
export def "user-search-global-name UserSearchByGlobalNamePost" [
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayNamePrefix: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/Search/GlobalName/($page)/")
  let body = {displayNamePrefix: $displayNamePrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets an object describing a particular variant of content.
#
# GET /Content/GetContentType/{type}/
# operationId: Content.GetContentType
export def "content-get-content-type ContentGetContentType" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Content/GetContentType/($type)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a content item referenced by id
#
# GET /Content/GetContentById/{id}/{locale}/
# operationId: Content.GetContentById
export def "content-get-content-by-id ContentGetContentById" [
  id: int
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --head: string@bool-completer # false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "head" $head "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Content/GetContentById/($id)/($locale)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the newest item that matches a given tag and Content Type.
#
# GET /Content/GetContentByTagAndType/{tag}/{type}/{locale}/
# operationId: Content.GetContentByTagAndType
export def "content-get-content-by-tag-and-type ContentGetContentByTagAndType" [
  locale: string
  tag: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --head: string@bool-completer # Not used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "head" $head "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Content/GetContentByTagAndType/($tag)/($type)/($locale)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets content based on querystring information passed in. Provides basic search and text search capabilities.
#
# GET /Content/Search/{locale}/
# operationId: Content.SearchContentWithText
export def "content-search ContentSearchContentWithText" [
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ctype: string # Content type tag: Help, News, etc. Supply multiple ctypes separated by space.
  --currentpage: int # Page number for the search results, starting with page 1. (format: int32)
  --head: string@bool-completer # Not used.
  --searchtext: string # Word or phrase for the search.
  --qp-source: string # For analytics, hint at the part of the app that triggered the search. Optional.
  --tag: string # Tag used on the content to be searched.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ctype" $ctype "scalar") (serialize-qp "currentpage" $currentpage "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "searchtext" $searchtext "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Content/Search/($locale)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches for Content Items that match the given Tag and Content Type.
#
# GET /Content/SearchContentByTagAndType/{tag}/{type}/{locale}/
# operationId: Content.SearchContentByTagAndType
export def "content-search-content-by-tag-and-type ContentSearchContentByTagAndType" [
  locale: string
  tag: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currentpage: int # Page number for the search results starting with page 1. (format: int32)
  --head: string@bool-completer # Not used.
  --itemsperpage: int # Not used. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currentpage" $currentpage "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "itemsperpage" $itemsperpage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Content/SearchContentByTagAndType/($tag)/($type)/($locale)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for Help Articles.
#
# GET /Content/SearchHelpArticles/{searchtext}/{size}/
# operationId: Content.SearchHelpArticles
export def "content-search-help-articles ContentSearchHelpArticles" [
  searchtext: string
  size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Content/SearchHelpArticles/($searchtext)/($size)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a JSON string response that is the RSS feed for news articles.
#
# GET /Content/Rss/NewsArticles/{pageToken}/
# operationId: Content.RssNewsArticles
export def "content-rss-news-articles ContentRssNewsArticles" [
  pageToken: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --categoryfilter: string # Optionally filter response to only include news items in a certain category.
  --includebody: string@bool-completer # Optionally include full content body for each news item.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryfilter" $categoryfilter "scalar") (serialize-qp "includebody" $includebody "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Content/Rss/NewsArticles/($pageToken)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get topics from any forum.
#
# GET /Forum/GetTopicsPaged/{page}/{pageSize}/{group}/{sort}/{quickDate}/{categoryFilter}/
# operationId: Forum.GetTopicsPaged
export def "forum-get-topics-paged ForumGetTopicsPaged" [
  categoryFilter: int
  group: int
  page: int
  pageSize: int
  quickDate: int
  sort: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locales: string # Comma seperated list of locales posts must match to return in the result list. Default 'en'
  --tagstring: string # The tags to search, if any.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locales" $locales "scalar") (serialize-qp "tagstring" $tagstring "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Forum/GetTopicsPaged/($page)/($pageSize)/($group)/($sort)/($quickDate)/($categoryFilter)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a listing of all topics marked as part of the core group.
#
# GET /Forum/GetCoreTopicsPaged/{page}/{sort}/{quickDate}/{categoryFilter}/
# operationId: Forum.GetCoreTopicsPaged
export def "forum-get-core-topics-paged ForumGetCoreTopicsPaged" [
  categoryFilter: int
  page: int
  quickDate: int
  sort: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locales: string # Comma seperated list of locales posts must match to return in the result list. Default 'en'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locales" $locales "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Forum/GetCoreTopicsPaged/($page)/($sort)/($quickDate)/($categoryFilter)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a thread of posts at the given parent, optionally returning replies to those posts as well as the original parent.
#
# GET /Forum/GetPostsThreadedPaged/{parentPostId}/{page}/{pageSize}/{replySize}/{getParentPost}/{rootThreadMode}/{sortMode}/
# operationId: Forum.GetPostsThreadedPaged
export def "forum-get-posts-threaded-paged ForumGetPostsThreadedPaged" [
  getParentPost: bool
  page: int
  pageSize: int
  parentPostId: int
  replySize: int
  rootThreadMode: bool
  sortMode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Forum/GetPostsThreadedPaged/($parentPostId)/($page)/($pageSize)/($replySize)/($getParentPost)/($rootThreadMode)/($sortMode)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a thread of posts starting at the topicId of the input childPostId, optionally returning replies to those posts as well as the original parent.
#
# GET /Forum/GetPostsThreadedPagedFromChild/{childPostId}/{page}/{pageSize}/{replySize}/{rootThreadMode}/{sortMode}/
# operationId: Forum.GetPostsThreadedPagedFromChild
export def "forum-get-posts-threaded-paged-from-child ForumGetPostsThreadedPagedFromChild" [
  childPostId: int
  page: int
  pageSize: int
  replySize: int
  rootThreadMode: bool
  sortMode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Forum/GetPostsThreadedPagedFromChild/($childPostId)/($page)/($pageSize)/($replySize)/($rootThreadMode)/($sortMode)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the post specified and its immediate parent.
#
# GET /Forum/GetPostAndParent/{childPostId}/
# operationId: Forum.GetPostAndParent
export def "forum-get-post-and-parent ForumGetPostAndParent" [
  childPostId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Forum/GetPostAndParent/($childPostId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the post specified and its immediate parent of posts that are awaiting approval.
#
# GET /Forum/GetPostAndParentAwaitingApproval/{childPostId}/
# operationId: Forum.GetPostAndParentAwaitingApproval
export def "forum-get-post-and-parent-awaiting-approval ForumGetPostAndParentAwaitingApproval" [
  childPostId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Forum/GetPostAndParentAwaitingApproval/($childPostId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the post Id for the given content item's comments, if it exists.
#
# GET /Forum/GetTopicForContent/{contentId}/
# operationId: Forum.GetTopicForContent
export def "forum-get-topic-for-content ForumGetTopicForContent" [
  contentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Forum/GetTopicForContent/($contentId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets tag suggestions based on partial text entry, matching them with other tags previously used in the forums.
#
# GET /Forum/GetForumTagSuggestions/
# operationId: Forum.GetForumTagSuggestions
export def "forum-get-forum-tag-suggestions ForumGetForumTagSuggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partialtag: string # The partial tag input to generate suggestions from.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partialtag" $partialtag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Forum/GetForumTagSuggestions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified forum poll.
#
# GET /Forum/Poll/{topicId}/
# operationId: Forum.GetPoll
export def "forum-poll ForumGetPoll" [
  topicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Forum/Poll/($topicId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Allows the caller to get a list of to 25 recruitment thread summary information objects.
#
# POST /Forum/Recruit/Summaries/
# operationId: Forum.GetRecruitmentThreadSummaries
export def "forum-recruit-summaries ForumGetRecruitmentThreadSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Forum/Recruit/Summaries/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of all available group avatars for the signed-in user.
#
# GET /GroupV2/GetAvailableAvatars/
# operationId: GroupV2.GetAvailableAvatars
export def "group-v2-get-available-avatars GroupV2GetAvailableAvatars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/GetAvailableAvatars/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all available group themes.
#
# GET /GroupV2/GetAvailableThemes/
# operationId: GroupV2.GetAvailableThemes
export def "group-v2-get-available-themes GroupV2GetAvailableThemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/GetAvailableThemes/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the state of the user's clan invite preferences for a particular membership type - true if they wish to be invited to clans, false otherwise.
#
# GET /GroupV2/GetUserClanInviteSetting/{mType}/
# operationId: GroupV2.GetUserClanInviteSetting
export def "group-v2-get-user-clan-invite-setting GroupV2GetUserClanInviteSetting" [
  mType: int
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
  let full_url = (build-url $base $"/GroupV2/GetUserClanInviteSetting/($mType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets groups recommended for you based on the groups to whom those you follow belong.
#
# POST /GroupV2/Recommended/{groupType}/{createDateRange}/
# operationId: GroupV2.GetRecommendedGroups
export def "group-v2-recommended GroupV2GetRecommendedGroups" [
  createDateRange: int
  groupType: int
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
  let full_url = (build-url $base $"/GroupV2/Recommended/($groupType)/($createDateRange)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for Groups.
#
# POST /GroupV2/Search/
# operationId: GroupV2.GroupSearch
export def "group-v2-search GroupV2GroupSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --groupType: int # format: int32
  --creationDate: int # format: int32
  --sortBy: int # format: int32
  --groupMemberCountFilter: int # nullable, format: int32
  --localeFilter: string
  --tagText: string
  --itemsPerPage: int # format: int32
  --currentPage: int # format: int32
  --requestContinuationToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/Search/")
  let body = {name: $name, groupType: $groupType, creationDate: $creationDate, sortBy: $sortBy, groupMemberCountFilter: $groupMemberCountFilter, localeFilter: $localeFilter, tagText: $tagText, itemsPerPage: $itemsPerPage, currentPage: $currentPage, requestContinuationToken: $requestContinuationToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about a specific group of the given ID.
#
# GET /GroupV2/{groupId}/
# operationId: GroupV2.GetGroup
export def "group-v2 GroupV2GetGroup" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about a specific group with the given name and type.
#
# GET /GroupV2/Name/{groupName}/{groupType}/
# operationId: GroupV2.GetGroupByName
export def "group-v2-name GroupV2GetGroupByName" [
  groupName: string
  groupType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/Name/($groupName)/($groupType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about a specific group with the given name and type. The POST version.
#
# POST /GroupV2/NameV2/
# operationId: GroupV2.GetGroupByNameV2
export def "group-v2-name-v2 GroupV2GetGroupByNameV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupName: string
  --groupType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/NameV2/")
  let body = {groupName: $groupName, groupType: $groupType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of available optional conversation channels and their settings.
#
# GET /GroupV2/{groupId}/OptionalConversations/
# operationId: GroupV2.GetGroupOptionalConversations
export def "group-v2-optional-conversations GroupV2GetGroupOptionalConversations" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/OptionalConversations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an existing group. You must have suitable permissions in the group to perform this operation. This latest revision will only edit the fields you pass in - pass null for properties you want to leave unaltered.
#
# POST /GroupV2/{groupId}/Edit/
# operationId: GroupV2.EditGroup
export def "group-v2-edit GroupV2EditGroup" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --about: string
  --motto: string
  --theme: string
  --avatarImageIndex: int # nullable, format: int32
  --tags: string
  --isPublic: string@bool-completer # nullable
  --membershipOption: int # nullable, format: int32
  --isPublicTopicAdminOnly: string@bool-completer # nullable
  --allowChat: string@bool-completer # nullable
  --chatSecurity: int # nullable, format: int32
  --callsign: string
  --locale: string
  --homepage: int # nullable, format: int32
  --enableInvitationMessagingForAdmins: string@bool-completer # nullable
  --defaultPublicity: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Edit/")
  let body = {name: $name, about: $about, motto: $motto, theme: $theme, avatarImageIndex: $avatarImageIndex, tags: $tags, isPublic: $isPublic, membershipOption: $membershipOption, isPublicTopicAdminOnly: $isPublicTopicAdminOnly, allowChat: $allowChat, chatSecurity: $chatSecurity, callsign: $callsign, locale: $locale, homepage: $homepage, enableInvitationMessagingForAdmins: $enableInvitationMessagingForAdmins, defaultPublicity: $defaultPublicity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit an existing group's clan banner. You must have suitable permissions in the group to perform this operation. All fields are required.
#
# POST /GroupV2/{groupId}/EditClanBanner/
# operationId: GroupV2.EditClanBanner
export def "group-v2-edit-clan-banner GroupV2EditClanBanner" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --decalId: int # format: uint32
  --decalColorId: int # format: uint32
  --decalBackgroundColorId: int # format: uint32
  --gonfalonId: int # format: uint32
  --gonfalonColorId: int # format: uint32
  --gonfalonDetailId: int # format: uint32
  --gonfalonDetailColorId: int # format: uint32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/EditClanBanner/")
  let body = {decalId: $decalId, decalColorId: $decalColorId, decalBackgroundColorId: $decalBackgroundColorId, gonfalonId: $gonfalonId, gonfalonColorId: $gonfalonColorId, gonfalonDetailId: $gonfalonDetailId, gonfalonDetailColorId: $gonfalonDetailColorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit group options only available to a founder. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/EditFounderOptions/
# operationId: GroupV2.EditFounderOptions
export def "group-v2-edit-founder-options GroupV2EditFounderOptions" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --InvitePermissionOverride: string@bool-completer # Minimum Member Level allowed to invite new members to group Always Allowed: Founder, Acting Founder True means admins have this power, false means they don't Default is false for clans, true for groups. (nullable)
  --UpdateCulturePermissionOverride: string@bool-completer # Minimum Member Level allowed to update group culture Always Allowed: Founder, Acting Founder True means admins have this power, false means they don't Default is false for clans, true for groups. (nullable)
  --HostGuidedGamePermissionOverride: int # Minimum Member Level allowed to host guided games Always Allowed: Founder, Acting Founder, Admin Allowed Overrides: None, Member, Beginner Default is Member for clans, None for groups, although this means nothing for groups. (nullable, format: int32)
  --UpdateBannerPermissionOverride: string@bool-completer # Minimum Member Level allowed to update banner Always Allowed: Founder, Acting Founder True means admins have this power, false means they don't Default is false for clans, true for groups. (nullable)
  --JoinLevel: int # Level to join a member at when accepting an invite, application, or joining an open clan Default is Beginner. (nullable, format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/EditFounderOptions/")
  let body = {InvitePermissionOverride: $InvitePermissionOverride, UpdateCulturePermissionOverride: $UpdateCulturePermissionOverride, HostGuidedGamePermissionOverride: $HostGuidedGamePermissionOverride, UpdateBannerPermissionOverride: $UpdateBannerPermissionOverride, JoinLevel: $JoinLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new optional conversation/chat channel. Requires admin permissions to the group.
#
# POST /GroupV2/{groupId}/OptionalConversations/Add/
# operationId: GroupV2.AddOptionalConversation
export def "group-v2-optional-conversations-add GroupV2AddOptionalConversation" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chatName: string
  --chatSecurity: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/OptionalConversations/Add/")
  let body = {chatName: $chatName, chatSecurity: $chatSecurity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit the settings of an optional conversation/chat channel. Requires admin permissions to the group.
#
# POST /GroupV2/{groupId}/OptionalConversations/Edit/{conversationId}/
# operationId: GroupV2.EditOptionalConversation
export def "group-v2-optional-conversations-edit GroupV2EditOptionalConversation" [
  conversationId: int
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --chatEnabled: string@bool-completer # nullable
  --chatName: string
  --chatSecurity: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/OptionalConversations/Edit/($conversationId)/")
  let body = {chatEnabled: $chatEnabled, chatName: $chatName, chatSecurity: $chatSecurity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of members in a given group.
#
# GET /GroupV2/{groupId}/Members/
# operationId: GroupV2.GetMembersOfGroup
export def "group-v2-members GroupV2GetMembersOfGroup" [
  currentpage: int
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memberType: int # Filter out other member types. Use None for all members. (format: int32)
  --nameSearch: string # The name fragment upon which a search should be executed for members with matching display or unique names.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "memberType" $memberType "scalar") (serialize-qp "nameSearch" $nameSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of members in a given group who are of admin level or higher.
#
# GET /GroupV2/{groupId}/AdminsAndFounder/
# operationId: GroupV2.GetAdminsAndFounderOfGroup
export def "group-v2-admins-and-founder GroupV2GetAdminsAndFounderOfGroup" [
  currentpage: int
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/AdminsAndFounder/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit the membership type of a given member. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/SetMembershipType/{memberType}/
# operationId: GroupV2.EditGroupMembership
export def "group-v2-members-set-membership-type GroupV2EditGroupMembership" [
  groupId: int
  membershipId: int
  membershipType: int
  memberType: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/($membershipType)/($membershipId)/SetMembershipType/($memberType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kick a member from the given group, forcing them to reapply if they wish to re-join the group. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Kick/
# operationId: GroupV2.KickMember
export def "group-v2-members-kick GroupV2KickMember" [
  groupId: int
  membershipId: int
  membershipType: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/($membershipType)/($membershipId)/Kick/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bans the requested member from the requested group for the specified period of time.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Ban/
# operationId: GroupV2.BanMember
export def "group-v2-members-ban GroupV2BanMember" [
  groupId: int
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string
  --length: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/($membershipType)/($membershipId)/Ban/")
  let body = {comment: $comment, length: $length} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unbans the requested member, allowing them to re-apply for membership.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Unban/
# operationId: GroupV2.UnbanMember
export def "group-v2-members-unban GroupV2UnbanMember" [
  groupId: int
  membershipId: int
  membershipType: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/($membershipType)/($membershipId)/Unban/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of banned members in a given group. Only accessible to group Admins and above. Not applicable to all groups. Check group features.
#
# GET /GroupV2/{groupId}/Banned/
# operationId: GroupV2.GetBannedMembersOfGroup
export def "group-v2-banned GroupV2GetBannedMembersOfGroup" [
  currentpage: int
  groupId: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Banned/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of edits made to a given group. Only accessible to group Admins and above.
#
# GET /GroupV2/{groupId}/EditHistory/
# operationId: GroupV2.GetGroupEditHistory
export def "group-v2-edit-history GroupV2GetGroupEditHistory" [
  currentpage: int
  groupId: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/EditHistory/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# An administrative method to allow the founder of a group or clan to give up their position to another admin permanently.
#
# POST /GroupV2/{groupId}/Admin/AbdicateFoundership/{membershipType}/{founderIdNew}/
# operationId: GroupV2.AbdicateFoundership
export def "group-v2-admin-abdicate-foundership GroupV2AbdicateFoundership" [
  founderIdNew: int
  groupId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Admin/AbdicateFoundership/($membershipType)/($founderIdNew)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of users who are awaiting a decision on their application to join a given group. Modified to include application info.
#
# GET /GroupV2/{groupId}/Members/Pending/
# operationId: GroupV2.GetPendingMemberships
export def "group-v2-members-pending GroupV2GetPendingMemberships" [
  currentpage: int
  groupId: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/Pending/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of users who have been invited into the group.
#
# GET /GroupV2/{groupId}/Members/InvitedIndividuals/
# operationId: GroupV2.GetInvitedIndividuals
export def "group-v2-members-invited-individuals GroupV2GetInvitedIndividuals" [
  currentpage: int
  groupId: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/InvitedIndividuals/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/ApproveAll/
# operationId: GroupV2.ApproveAllPending
export def "group-v2-members-approve-all GroupV2ApproveAllPending" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/ApproveAll/")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deny all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/DenyAll/
# operationId: GroupV2.DenyAllPending
export def "group-v2-members-deny-all GroupV2DenyAllPending" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/DenyAll/")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Approve all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/ApproveList/
# operationId: GroupV2.ApprovePendingForList
# --memberships item shape: {membershipType?: int, membershipId?: int, displayName?: string, bungieGlobalDisplayName?: string, bungieGlobalDisplayNameCode?: int}
export def "group-v2-members-approve-list GroupV2ApprovePendingForList" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memberships: list # item shape: {membershipType?: int, membershipId?: int, displayName?: string, bungieGlobalDisplayName?: string, bungieGlobalDisplayNameCode?: int}
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/ApproveList/")
  let body = {memberships: $memberships, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Approve the given membershipId to join the group/clan as long as they have applied.
#
# POST /GroupV2/{groupId}/Members/Approve/{membershipType}/{membershipId}/
# operationId: GroupV2.ApprovePending
export def "group-v2-members-approve GroupV2ApprovePending" [
  groupId: int
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/Approve/($membershipType)/($membershipId)/")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deny all of the pending users for the given group that match the passed-in .
#
# POST /GroupV2/{groupId}/Members/DenyList/
# operationId: GroupV2.DenyPendingForList
# --memberships item shape: {membershipType?: int, membershipId?: int, displayName?: string, bungieGlobalDisplayName?: string, bungieGlobalDisplayNameCode?: int}
export def "group-v2-members-deny-list GroupV2DenyPendingForList" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memberships: list # item shape: {membershipType?: int, membershipId?: int, displayName?: string, bungieGlobalDisplayName?: string, bungieGlobalDisplayNameCode?: int}
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/DenyList/")
  let body = {memberships: $memberships, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about the groups that a given member has joined.
#
# GET /GroupV2/User/{membershipType}/{membershipId}/{filter}/{groupType}/
# operationId: GroupV2.GetGroupsForMember
export def "group-v2-user GroupV2GetGroupsForMember" [
  filter: int
  groupType: int
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/User/($membershipType)/($membershipId)/($filter)/($groupType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Allows a founder to manually recover a group they can see in game but not on bungie.net
#
# GET /GroupV2/Recover/{membershipType}/{membershipId}/{groupType}/
# operationId: GroupV2.RecoverGroupForFounder
export def "group-v2-recover GroupV2RecoverGroupForFounder" [
  groupType: int
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/Recover/($membershipType)/($membershipId)/($groupType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about the groups that a given member has applied to or been invited to.
#
# GET /GroupV2/User/Potential/{membershipType}/{membershipId}/{filter}/{groupType}/
# operationId: GroupV2.GetPotentialGroupsForMember
export def "group-v2-user-potential GroupV2GetPotentialGroupsForMember" [
  filter: int
  groupType: int
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/User/Potential/($membershipType)/($membershipId)/($filter)/($groupType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite a user to join this group.
#
# POST /GroupV2/{groupId}/Members/IndividualInvite/{membershipType}/{membershipId}/
# operationId: GroupV2.IndividualGroupInvite
export def "group-v2-members-individual-invite GroupV2IndividualGroupInvite" [
  groupId: int
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/IndividualInvite/($membershipType)/($membershipId)/")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancels a pending invitation to join a group.
#
# POST /GroupV2/{groupId}/Members/IndividualInviteCancel/{membershipType}/{membershipId}/
# operationId: GroupV2.IndividualGroupInviteCancel
export def "group-v2-members-individual-invite-cancel GroupV2IndividualGroupInviteCancel" [
  groupId: int
  membershipId: int
  membershipType: int
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
  let full_url = (build-url $base $"/GroupV2/($groupId)/Members/IndividualInviteCancel/($membershipType)/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Twitch Drops self-repair function - scans twitch for drops not marked as fulfilled and resyncs them.
#
# POST /Tokens/Partner/ForceDropsRepair/
# operationId: Tokens.ForceDropsRepair
export def "tokens-partner-force-drops-repair TokensForceDropsRepair" [
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
  let full_url = (build-url $base "/Tokens/Partner/ForceDropsRepair/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Claim a partner offer as the authenticated user.
#
# POST /Tokens/Partner/ClaimOffer/
# operationId: Tokens.ClaimPartnerOffer
export def "tokens-partner-claim-offer TokensClaimPartnerOffer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PartnerOfferId: string
  --BungieNetMembershipId: int # format: int64
  --TransactionId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Tokens/Partner/ClaimOffer/")
  let body = {PartnerOfferId: $PartnerOfferId, BungieNetMembershipId: $BungieNetMembershipId, TransactionId: $TransactionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply a partner offer to the targeted user. This endpoint does not claim a new offer, but any already claimed offers will be applied to the game if not already.
#
# POST /Tokens/Partner/ApplyMissingOffers/{partnerApplicationId}/{targetBnetMembershipId}/
# operationId: Tokens.ApplyMissingPartnerOffersWithoutClaim
export def "tokens-partner-apply-missing-offers TokensApplyMissingPartnerOffersWithoutClaim" [
  partnerApplicationId: int
  targetBnetMembershipId: int
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
  let full_url = (build-url $base $"/Tokens/Partner/ApplyMissingOffers/($partnerApplicationId)/($targetBnetMembershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the partner sku and offer history of the targeted user. Elevated permissions are required to see users that are not yourself.
#
# GET /Tokens/Partner/History/{partnerApplicationId}/{targetBnetMembershipId}/
# operationId: Tokens.GetPartnerOfferSkuHistory
export def "tokens-partner-history TokensGetPartnerOfferSkuHistory" [
  partnerApplicationId: int
  targetBnetMembershipId: int
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
  let full_url = (build-url $base $"/Tokens/Partner/History/($partnerApplicationId)/($targetBnetMembershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the partner rewards history of the targeted user, both partner offers and Twitch drops.
#
# GET /Tokens/Partner/History/{targetBnetMembershipId}/Application/{partnerApplicationId}/
# operationId: Tokens.GetPartnerRewardHistory
export def "tokens-partner-history-application TokensGetPartnerRewardHistory" [
  partnerApplicationId: int
  targetBnetMembershipId: int
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
  let full_url = (build-url $base $"/Tokens/Partner/History/($targetBnetMembershipId)/Application/($partnerApplicationId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the bungie rewards for the targeted user.
#
# GET /Tokens/Rewards/GetRewardsForUser/{membershipId}/
# operationId: Tokens.GetBungieRewardsForUser
export def "tokens-rewards-get-rewards-for-user TokensGetBungieRewardsForUser" [
  membershipId: int
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
  let full_url = (build-url $base $"/Tokens/Rewards/GetRewardsForUser/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the bungie rewards for the targeted user when a platform membership Id and Type are used.
#
# GET /Tokens/Rewards/GetRewardsForPlatformUser/{membershipId}/{membershipType}/
# operationId: Tokens.GetBungieRewardsForPlatformUser
export def "tokens-rewards-get-rewards-for-platform-user TokensGetBungieRewardsForPlatformUser" [
  membershipId: int
  membershipType: int
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
  let full_url = (build-url $base $"/Tokens/Rewards/GetRewardsForPlatformUser/($membershipId)/($membershipType)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of the current bungie rewards
#
# GET /Tokens/Rewards/BungieRewards/
# operationId: Tokens.GetBungieRewardsList
export def "tokens-rewards-bungie-rewards TokensGetBungieRewardsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Tokens/Rewards/BungieRewards/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the current version of the manifest as a json object.
#
# GET /Destiny2/Manifest/
# operationId: Destiny2.GetDestinyManifest
export def "destiny2-manifest Destiny2GetDestinyManifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Manifest/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the static definition of an entity of the given Type and hash identifier. Examine the API Documentation for the Type Names of entities that have their own definitions. Note that the return type will always *inherit from* DestinyDefinition, but the specific type returned will be the requested entity type if it can be found. Please don't use this as a chatty alternative to the Manifest database if you require large sets of data, but for simple and one-off accesses this should be handy.
#
# GET /Destiny2/Manifest/{entityType}/{hashIdentifier}/
# operationId: Destiny2.GetDestinyEntityDefinition
export def "destiny2-manifest Destiny2GetDestinyEntityDefinition" [
  entityType: string
  hashIdentifier: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/Manifest/($entityType)/($hashIdentifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of Destiny memberships given a global Bungie Display Name. This method will hide overridden memberships due to cross save.
#
# POST /Destiny2/SearchDestinyPlayerByBungieName/{membershipType}/
# operationId: Destiny2.SearchDestinyPlayerByBungieName
export def "destiny2-search-destiny-player-by-bungie-name Destiny2SearchDestinyPlayerByBungieName" [
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayName: string
  --displayNameCode: int # format: int16
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/SearchDestinyPlayerByBungieName/($membershipType)/")
  let body = {displayName: $displayName, displayNameCode: $displayNameCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a summary information about all profiles linked to the requesting membership type/membership ID that have valid Destiny information. The passed-in Membership Type/Membership ID may be a Bungie.Net membership or a Destiny membership. It only returns the minimal amount of data to begin making more substantive requests, but will hopefully serve as a useful alternative to UserServices for people who just care about Destiny data. Note that it will only return linked accounts whose linkages you are allowed to view.
#
# GET /Destiny2/{membershipType}/Profile/{membershipId}/LinkedProfiles/
# operationId: Destiny2.GetLinkedProfiles
export def "destiny2-profile-linked-profiles Destiny2GetLinkedProfiles" [
  membershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getAllMemberships: string@bool-completer # (optional) if set to 'true', all memberships regardless of whether they're obscured by overrides will be returned. Normal privacy restrictions on account linking will still apply no matter what.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getAllMemberships" $getAllMemberships "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($membershipId)/LinkedProfiles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns Destiny Profile information for the supplied membership.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/
# operationId: Destiny2.GetProfile
export def "destiny2-profile Destiny2GetProfile" [
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($destinyMembershipId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns character information for the supplied character.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/
# operationId: Destiny2.GetCharacter
export def "destiny2-profile-character Destiny2GetCharacter" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($destinyMembershipId)/Character/($characterId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information on the weekly clan rewards and if the clan has earned them or not. Note that this will always report rewards as not redeemed.
#
# GET /Destiny2/Clan/{groupId}/WeeklyRewardState/
# operationId: Destiny2.GetClanWeeklyRewardState
export def "destiny2-clan-weekly-reward-state Destiny2GetClanWeeklyRewardState" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/Clan/($groupId)/WeeklyRewardState/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the dictionary of values for the Clan Banner
#
# GET /Destiny2/Clan/ClanBannerDictionary/
# operationId: Destiny2.GetClanBannerSource
export def "destiny2-clan-clan-banner-dictionary Destiny2GetClanBannerSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Clan/ClanBannerDictionary/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the details of an instanced Destiny Item. An instanced Destiny item is one with an ItemInstanceId. Non-instanced items, such as materials, have no useful instance-specific details and thus are not queryable here.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Item/{itemInstanceId}/
# operationId: Destiny2.GetItem
export def "destiny2-profile-item Destiny2GetItem" [
  destinyMembershipId: int
  itemInstanceId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($destinyMembershipId)/Item/($itemInstanceId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get currently available vendors from the list of vendors that can possibly have rotating inventory. Note that this does not include things like preview vendors and vendors-as-kiosks, neither of whom have rotating/dynamic inventories. Use their definitions as-is for those.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/
# operationId: Destiny2.GetVendors
export def "destiny2-profile-character-vendors Destiny2GetVendors" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
  --filter: int # The filter of what vendors and items to return, if any. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($destinyMembershipId)/Character/($characterId)/Vendors/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of a specific Vendor.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/{vendorHash}/
# operationId: Destiny2.GetVendor
export def "destiny2-profile-character-vendors Destiny2GetVendor" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  vendorHash: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($destinyMembershipId)/Character/($characterId)/Vendors/($vendorHash)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get items available from vendors where the vendors have items for sale that are common for everyone. If any portion of the Vendor's available inventory is character or account specific, we will be unable to return their data from this endpoint due to the way that available inventory is computed. As I am often guilty of saying: 'It's a long story...'
#
# GET /Destiny2/Vendors/
# operationId: Destiny2.GetPublicVendors
export def "destiny2-vendors Destiny2GetPublicVendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/Destiny2/Vendors/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Given a Presentation Node that has Collectibles as direct descendants, this will return item details about those descendants in the context of the requesting character.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Collectibles/{collectiblePresentationNodeHash}/
# operationId: Destiny2.GetCollectibleNodeDetails
export def "destiny2-profile-character-collectibles Destiny2GetCollectibleNodeDetails" [
  characterId: int
  collectiblePresentationNodeHash: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --components: list # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Profile/($destinyMembershipId)/Character/($characterId)/Collectibles/($collectiblePresentationNodeHash)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer an item to/from your vault. You must have a valid Destiny account. You must also pass BOTH a reference AND an instance ID if it's an instanced item. itshappening.gif
#
# POST /Destiny2/Actions/Items/TransferItem/
# operationId: Destiny2.TransferItem
export def "destiny2-actions-items-transfer-item Destiny2TransferItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --itemReferenceHash: int # format: uint32
  --stackSize: int # format: int32
  --transferToVault: string@bool-completer
  --itemId: int # The instance ID of the item for this action request. (format: int64)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/TransferItem/")
  let body = {itemReferenceHash: $itemReferenceHash, stackSize: $stackSize, transferToVault: $transferToVault, itemId: $itemId, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Extract an item from the Postmaster, with whatever implications that may entail. You must have a valid Destiny account. You must also pass BOTH a reference AND an instance ID if it's an instanced item.
#
# POST /Destiny2/Actions/Items/PullFromPostmaster/
# operationId: Destiny2.PullFromPostmaster
export def "destiny2-actions-items-pull-from-postmaster Destiny2PullFromPostmaster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --itemReferenceHash: int # format: uint32
  --stackSize: int # format: int32
  --itemId: int # The instance ID of the item for this action request. (format: int64)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/PullFromPostmaster/")
  let body = {itemReferenceHash: $itemReferenceHash, stackSize: $stackSize, itemId: $itemId, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Equip an item. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Items/EquipItem/
# operationId: Destiny2.EquipItem
export def "destiny2-actions-items-equip-item Destiny2EquipItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --itemId: int # The instance ID of the item for this action request. (format: int64)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/EquipItem/")
  let body = {itemId: $itemId, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Equip a list of items by itemInstanceIds. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline. Any items not found on your character will be ignored.
#
# POST /Destiny2/Actions/Items/EquipItems/
# operationId: Destiny2.EquipItems
export def "destiny2-actions-items-equip-items Destiny2EquipItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --itemIds: list
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/EquipItems/")
  let body = {itemIds: $itemIds, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Equip a loadout. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Loadouts/EquipLoadout/
# operationId: Destiny2.EquipLoadout
export def "destiny2-actions-loadouts-equip-loadout Destiny2EquipLoadout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loadoutIndex: int # The index of the loadout for this action request. (format: int32)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/EquipLoadout/")
  let body = {loadoutIndex: $loadoutIndex, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Snapshot a loadout with the currently equipped items.
#
# POST /Destiny2/Actions/Loadouts/SnapshotLoadout/
# operationId: Destiny2.SnapshotLoadout
export def "destiny2-actions-loadouts-snapshot-loadout Destiny2SnapshotLoadout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --colorHash: int # nullable, format: uint32
  --iconHash: int # nullable, format: uint32
  --nameHash: int # nullable, format: uint32
  --loadoutIndex: int # The index of the loadout for this action request. (format: int32)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/SnapshotLoadout/")
  let body = {colorHash: $colorHash, iconHash: $iconHash, nameHash: $nameHash, loadoutIndex: $loadoutIndex, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the color, icon, and name of a loadout.
#
# POST /Destiny2/Actions/Loadouts/UpdateLoadoutIdentifiers/
# operationId: Destiny2.UpdateLoadoutIdentifiers
export def "destiny2-actions-loadouts-update-loadout-identifiers Destiny2UpdateLoadoutIdentifiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --colorHash: int # nullable, format: uint32
  --iconHash: int # nullable, format: uint32
  --nameHash: int # nullable, format: uint32
  --loadoutIndex: int # The index of the loadout for this action request. (format: int32)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/UpdateLoadoutIdentifiers/")
  let body = {colorHash: $colorHash, iconHash: $iconHash, nameHash: $nameHash, loadoutIndex: $loadoutIndex, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear the identifiers and items of a loadout.
#
# POST /Destiny2/Actions/Loadouts/ClearLoadout/
# operationId: Destiny2.ClearLoadout
export def "destiny2-actions-loadouts-clear-loadout Destiny2ClearLoadout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loadoutIndex: int # The index of the loadout for this action request. (format: int32)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/ClearLoadout/")
  let body = {loadoutIndex: $loadoutIndex, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the Lock State for an instanced item. You must have a valid Destiny Account.
#
# POST /Destiny2/Actions/Items/SetLockState/
# operationId: Destiny2.SetItemLockState
export def "destiny2-actions-items-set-lock-state Destiny2SetItemLockState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@bool-completer
  --itemId: int # The instance ID of the item for this action request. (format: int64)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/SetLockState/")
  let body = {state: $state, itemId: $itemId, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the Tracking State for an instanced item, if that item is a Quest or Bounty. You must have a valid Destiny Account. Yeah, it's an item.
#
# POST /Destiny2/Actions/Items/SetTrackedState/
# operationId: Destiny2.SetQuestTrackedState
export def "destiny2-actions-items-set-tracked-state Destiny2SetQuestTrackedState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@bool-completer
  --itemId: int # The instance ID of the item for this action request. (format: int64)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/SetTrackedState/")
  let body = {state: $state, itemId: $itemId, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Insert a plug into a socketed item. I know how it sounds, but I assure you it's much more G-rated than you might be guessing. We haven't decided yet whether this will be able to insert plugs that have side effects, but if we do it will require special scope permission for an application attempting to do so. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline. Request must include proof of permission for 'InsertPlugs' from the account owner.
#
# POST /Destiny2/Actions/Items/InsertSocketPlug/
# operationId: Destiny2.InsertSocketPlug
# --plug shape: {socketIndex?: int, socketArrayType?: int, plugItemHash?: int}
export def "destiny2-actions-items-insert-socket-plug Destiny2InsertSocketPlug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actionToken: string # Action token provided by the AwaGetActionToken API call.
  --itemInstanceId: int # The instance ID of the item having a plug inserted. Only instanced items can have sockets. (format: int64)
  --plug: record # The plugs being inserted. — shape: {socketIndex?: int, socketArrayType?: int, plugItemHash?: int}
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/InsertSocketPlug/")
  let body = {actionToken: $actionToken, itemInstanceId: $itemInstanceId, plug: $plug, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Insert a 'free' plug into an item's socket. This does not require 'Advanced Write Action' authorization and is available to 3rd-party apps, but will only work on 'free and reversible' socket actions (Perks, Armor Mods, Shaders, Ornaments, etc.). You must have a valid Destiny Account, and the character must either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Items/InsertSocketPlugFree/
# operationId: Destiny2.InsertSocketPlugFree
# --plug shape: {socketIndex?: int, socketArrayType?: int, plugItemHash?: int}
export def "destiny2-actions-items-insert-socket-plug-free Destiny2InsertSocketPlugFree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --plug: record # The plugs being inserted. — shape: {socketIndex?: int, socketArrayType?: int, plugItemHash?: int}
  --itemId: int # The instance ID of the item for this action request. (format: int64)
  --characterId: int # format: int64
  --membershipType: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/InsertSocketPlugFree/")
  let body = {plug: $plug, itemId: $itemId, characterId: $characterId, membershipType: $membershipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the available post game carnage report for the activity ID.
#
# GET /Destiny2/Stats/PostGameCarnageReport/{activityId}/
# operationId: Destiny2.GetPostGameCarnageReport
export def "destiny2-stats-post-game-carnage-report Destiny2GetPostGameCarnageReport" [
  activityId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/Stats/PostGameCarnageReport/($activityId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report a player that you met in an activity that was engaging in ToS-violating activities. Both you and the offending player must have played in the activityId passed in. Please use this judiciously and only when you have strong suspicions of violation, pretty please.
#
# POST /Destiny2/Stats/PostGameCarnageReport/{activityId}/Report/
# operationId: Destiny2.ReportOffensivePostGameCarnageReportPlayer
export def "destiny2-stats-post-game-carnage-report-report Destiny2ReportOffensivePostGameCarnageReportPlayer" [
  activityId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reasonCategoryHashes: list # So you've decided to report someone instead of cursing them and their descendants. Well, okay then. This is the category or categorie(s) of infractions for which you are reporting the user. These are hash identifiers that map to DestinyReportReasonCategoryDefinition entries.
  --reasonHashes: list # If applicable, provide a more specific reason(s) within the general category of problems provided by the reasonHash. This is also an identifier for a reason. All reasonHashes provided must be children of at least one the reasonCategoryHashes provided.
  --offendingCharacterId: int # Within the PGCR provided when calling the Reporting endpoint, this should be the character ID of the user that you thought was violating terms of use. They must exist in the PGCR provided. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/Stats/PostGameCarnageReport/($activityId)/Report/")
  let body = {reasonCategoryHashes: $reasonCategoryHashes, reasonHashes: $reasonHashes, offendingCharacterId: $offendingCharacterId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets historical stats definitions.
#
# GET /Destiny2/Stats/Definition/
# operationId: Destiny2.GetHistoricalStatsDefinition
export def "destiny2-stats-definition Destiny2GetHistoricalStatsDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Stats/Definition/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/Leaderboards/Clans/{groupId}/
# operationId: Destiny2.GetClanLeaderboards
export def "destiny2-stats-leaderboards-clans Destiny2GetClanLeaderboards" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxtop" $maxtop "scalar") (serialize-qp "modes" $modes "scalar") (serialize-qp "statid" $statid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/Stats/Leaderboards/Clans/($groupId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets aggregated stats for a clan using the same categories as the clan leaderboards. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/AggregateClanStats/{groupId}/
# operationId: Destiny2.GetClanAggregateStats
export def "destiny2-stats-aggregate-clan-stats Destiny2GetClanAggregateStats" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/Stats/AggregateClanStats/($groupId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint has not yet been implemented. It is being returned for a preview of future functionality, and for public comment/suggestion/preparation.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/Leaderboards/
# operationId: Destiny2.GetLeaderboards
export def "destiny2-account-stats-leaderboards Destiny2GetLeaderboards" [
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxtop" $maxtop "scalar") (serialize-qp "modes" $modes "scalar") (serialize-qp "statid" $statid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Account/($destinyMembershipId)/Stats/Leaderboards/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/Leaderboards/{membershipType}/{destinyMembershipId}/{characterId}/
# operationId: Destiny2.GetLeaderboardsForCharacter
export def "destiny2-stats-leaderboards Destiny2GetLeaderboardsForCharacter" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxtop" $maxtop "scalar") (serialize-qp "modes" $modes "scalar") (serialize-qp "statid" $statid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/Stats/Leaderboards/($membershipType)/($destinyMembershipId)/($characterId)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a page list of Destiny items.
#
# GET /Destiny2/Armory/Search/{type}/{searchTerm}/
# operationId: Destiny2.SearchDestinyEntities
export def "destiny2-armory-search Destiny2SearchDestinyEntities" [
  searchTerm: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number to return, starting with 0. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/Armory/Search/($type)/($searchTerm)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets historical stats for indicated character.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/
# operationId: Destiny2.GetHistoricalStats
export def "destiny2-account-character-stats Destiny2GetHistoricalStats" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dayend: string # Last day to return when daily stats are requested. Use the format YYYY-MM-DD. Currently, we cannot allow more than 31 days of daily data to be requested in a single request. (format: date-time)
  --daystart: string # First day to return when daily stats are requested. Use the format YYYY-MM-DD. Currently, we cannot allow more than 31 days of daily data to be requested in a single request. (format: date-time)
  --groups: list # Group of stats to include, otherwise only general stats are returned. Comma separated list is allowed. Values: General, Weapons, Medals
  --modes: list # Game modes to return. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --periodType: int # Indicates a specific period type to return. Optional. May be: Daily, AllTime, or Activity (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dayend" $dayend "scalar") (serialize-qp "daystart" $daystart "scalar") (serialize-qp "groups" $groups "multi") (serialize-qp "modes" $modes "multi") (serialize-qp "periodType" $periodType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Account/($destinyMembershipId)/Character/($characterId)/Stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets aggregate historical stats organized around each character for a given account.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/
# operationId: Destiny2.GetHistoricalStatsForAccount
export def "destiny2-account-stats Destiny2GetHistoricalStatsForAccount" [
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groups: list # Groups of stats to include, otherwise only general stats are returned. Comma separated list is allowed. Values: General, Weapons, Medals.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groups" $groups "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Account/($destinyMembershipId)/Stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets activity history stats for indicated character.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/Activities/
# operationId: Destiny2.GetActivityHistory
export def "destiny2-account-character-stats-activities Destiny2GetActivityHistory" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of rows to return (format: int32)
  --mode: int # A filter for the activity mode to be returned. None returns all activities. See the documentation for DestinyActivityModeType for valid values, and pass in string representation. (format: int32)
  --page: int # Page number to return, starting with 0. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Account/($destinyMembershipId)/Character/($characterId)/Stats/Activities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details about unique weapon usage, including all exotic weapons.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/UniqueWeapons/
# operationId: Destiny2.GetUniqueWeaponHistory
export def "destiny2-account-character-stats-unique-weapons Destiny2GetUniqueWeaponHistory" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Account/($destinyMembershipId)/Character/($characterId)/Stats/UniqueWeapons/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all activities the character has participated in together with aggregate statistics for those activities.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/AggregateActivityStats/
# operationId: Destiny2.GetDestinyAggregateActivityStats
export def "destiny2-account-character-stats-aggregate-activity-stats Destiny2GetDestinyAggregateActivityStats" [
  characterId: int
  destinyMembershipId: int
  membershipType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/($membershipType)/Account/($destinyMembershipId)/Character/($characterId)/Stats/AggregateActivityStats/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets custom localized content for the milestone of the given hash, if it exists.
#
# GET /Destiny2/Milestones/{milestoneHash}/Content/
# operationId: Destiny2.GetPublicMilestoneContent
export def "destiny2-milestones-content Destiny2GetPublicMilestoneContent" [
  milestoneHash: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Destiny2/Milestones/($milestoneHash)/Content/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets public information about currently available Milestones.
#
# GET /Destiny2/Milestones/
# operationId: Destiny2.GetPublicMilestones
export def "destiny2-milestones Destiny2GetPublicMilestones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Milestones/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize a request to perform an advanced write action.
#
# POST /Destiny2/Awa/Initialize/
# operationId: Destiny2.AwaInitializeRequest
export def "destiny2-awa-initialize Destiny2AwaInitializeRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: int # Type of advanced write action. (format: int32)
  --affectedItemId: int # Item instance ID the action shall be applied to. This is optional for all but a new AwaType values. Rule of thumb is to provide the item instance ID if one is available. (nullable, format: int64)
  --membershipType: int # Destiny membership type of the account to modify. (format: int32)
  --characterId: int # Destiny character ID, if applicable, that will be affected by the action. (nullable, format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Awa/Initialize/")
  let body = {type: $type, affectedItemId: $affectedItemId, membershipType: $membershipType, characterId: $characterId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Provide the result of the user interaction. Called by the Bungie Destiny App to approve or reject a request.
#
# POST /Destiny2/Awa/AwaProvideAuthorizationResult/
# operationId: Destiny2.AwaProvideAuthorizationResult
export def "destiny2-awa-awa-provide-authorization-result Destiny2AwaProvideAuthorizationResult" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --selection: int # Indication of the selection the user has made (Approving or rejecting the action) (format: int32)
  --correlationId: string # Correlation ID of the request
  --nonce: list # Secret nonce received via the PUSH notification.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Awa/AwaProvideAuthorizationResult/")
  let body = {selection: $selection, correlationId: $correlationId, nonce: $nonce} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the action token if user approves the request.
#
# GET /Destiny2/Awa/GetActionToken/{correlationId}/
# operationId: Destiny2.AwaGetActionToken
export def "destiny2-awa-get-action-token Destiny2AwaGetActionToken" [
  correlationId: string
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
  let full_url = (build-url $base $"/Destiny2/Awa/GetActionToken/($correlationId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns community content.
#
# GET /CommunityContent/Get/{sort}/{mediaFilter}/{page}/
# operationId: CommunityContent.GetCommunityContent
export def "community-content-get CommunityContentGetCommunityContent" [
  mediaFilter: int
  page: int
  sort: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CommunityContent/Get/($sort)/($mediaFilter)/($page)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns trending items for Bungie.net, collapsed into the first page of items per category. For pagination within a category, call GetTrendingCategory.
#
# GET /Trending/Categories/
# operationId: Trending.GetTrendingCategories
export def "trending-categories TrendingGetTrendingCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Trending/Categories/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns paginated lists of trending items for a category.
#
# GET /Trending/Categories/{categoryId}/{pageNumber}/
# operationId: Trending.GetTrendingCategory
export def "trending-categories TrendingGetTrendingCategory" [
  categoryId: string
  pageNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Trending/Categories/($categoryId)/($pageNumber)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the detailed results for a specific trending entry. Note that trending entries are uniquely identified by a combination of *both* the TrendingEntryType *and* the identifier: the identifier alone is not guaranteed to be globally unique.
#
# GET /Trending/Details/{trendingEntryType}/{identifier}/
# operationId: Trending.GetTrendingEntryDetail
export def "trending-details TrendingGetTrendingEntryDetail" [
  identifier: string
  trendingEntryType: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Trending/Details/($trendingEntryType)/($identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a count of all active non-public fireteams for the specified clan. Maximum value returned is 25.
#
# GET /Fireteam/Clan/{groupId}/ActiveCount/
# operationId: Fireteam.GetActivePrivateClanFireteamCount
export def "fireteam-clan-active-count FireteamGetActivePrivateClanFireteamCount" [
  groupId: int
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
  let full_url = (build-url $base $"/Fireteam/Clan/($groupId)/ActiveCount/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a listing of all of this clan's fireteams that are have available slots. Caller is not checked for join criteria so caching is maximized.
#
# GET /Fireteam/Clan/{groupId}/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{publicOnly}/{page}/
# operationId: Fireteam.GetAvailableClanFireteams
export def "fireteam-clan-available FireteamGetAvailableClanFireteams" [
  activityType: int
  dateRange: int
  groupId: int
  page: int
  platform: int
  publicOnly: int
  slotFilter: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --excludeImmediate: string@bool-completer # If you wish the result to exclude immediate fireteams, set this to true. Immediate-only can be forced using the dateRange enum.
  --langFilter: string # An optional language filter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeImmediate" $excludeImmediate "scalar") (serialize-qp "langFilter" $langFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Fireteam/Clan/($groupId)/Available/($platform)/($activityType)/($dateRange)/($slotFilter)/($publicOnly)/($page)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a listing of all public fireteams starting now with open slots. Caller is not checked for join criteria so caching is maximized.
#
# GET /Fireteam/Search/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{page}/
# operationId: Fireteam.SearchPublicAvailableClanFireteams
export def "fireteam-search-available FireteamSearchPublicAvailableClanFireteams" [
  activityType: int
  dateRange: int
  page: int
  platform: int
  slotFilter: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --excludeImmediate: string@bool-completer # If you wish the result to exclude immediate fireteams, set this to true. Immediate-only can be forced using the dateRange enum.
  --langFilter: string # An optional language filter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeImmediate" $excludeImmediate "scalar") (serialize-qp "langFilter" $langFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Fireteam/Search/Available/($platform)/($activityType)/($dateRange)/($slotFilter)/($page)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a listing of all fireteams that caller is an applicant, a member, or an alternate of.
#
# GET /Fireteam/Clan/{groupId}/My/{platform}/{includeClosed}/{page}/
# operationId: Fireteam.GetMyClanFireteams
export def "fireteam-clan-my FireteamGetMyClanFireteams" [
  groupId: int
  includeClosed: bool
  page: int
  platform: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupFilter: string@bool-completer # If true, filter by clan. Otherwise, ignore the clan and show all of the user's fireteams.
  --langFilter: string # An optional language filter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupFilter" $groupFilter "scalar") (serialize-qp "langFilter" $langFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Fireteam/Clan/($groupId)/My/($platform)/($includeClosed)/($page)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a specific fireteam.
#
# GET /Fireteam/Clan/{groupId}/Summary/{fireteamId}/
# operationId: Fireteam.GetClanFireteam
export def "fireteam-clan-summary FireteamGetClanFireteam" [
  fireteamId: int
  groupId: int
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
  let full_url = (build-url $base $"/Fireteam/Clan/($groupId)/Summary/($fireteamId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns your Bungie Friend list
#
# GET /Social/Friends/
# operationId: Social.GetFriendList
export def "social-friends SocialGetFriendList" [
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
  let full_url = (build-url $base "/Social/Friends/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns your friend request queue.
#
# GET /Social/Friends/Requests/
# operationId: Social.GetFriendRequestList
export def "social-friends-requests SocialGetFriendRequestList" [
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
  let full_url = (build-url $base "/Social/Friends/Requests/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Requests a friend relationship with the target user. Any of the target user's linked membership ids are valid inputs.
#
# POST /Social/Friends/Add/{membershipId}/
# operationId: Social.IssueFriendRequest
export def "social-friends-add SocialIssueFriendRequest" [
  membershipId: string
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
  let full_url = (build-url $base $"/Social/Friends/Add/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accepts a friend relationship with the target user. The user must be on your incoming friend request list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Accept/{membershipId}/
# operationId: Social.AcceptFriendRequest
export def "social-friends-requests-accept SocialAcceptFriendRequest" [
  membershipId: string
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
  let full_url = (build-url $base $"/Social/Friends/Requests/Accept/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Declines a friend relationship with the target user. The user must be on your incoming friend request list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Decline/{membershipId}/
# operationId: Social.DeclineFriendRequest
export def "social-friends-requests-decline SocialDeclineFriendRequest" [
  membershipId: string
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
  let full_url = (build-url $base $"/Social/Friends/Requests/Decline/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a friend relationship with the target user. The user must be on your friend list, though no error will occur if they are not.
#
# POST /Social/Friends/Remove/{membershipId}/
# operationId: Social.RemoveFriend
export def "social-friends-remove SocialRemoveFriend" [
  membershipId: string
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
  let full_url = (build-url $base $"/Social/Friends/Remove/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a friend relationship with the target user. The user must be on your outgoing request friend list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Remove/{membershipId}/
# operationId: Social.RemoveFriendRequest
export def "social-friends-requests-remove SocialRemoveFriendRequest" [
  membershipId: string
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
  let full_url = (build-url $base $"/Social/Friends/Requests/Remove/($membershipId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the platform friend of the requested type, with additional information if they have Bungie accounts. Must have a recent login session with said platform.
#
# GET /Social/PlatformFriends/{friendPlatform}/{page}/
# operationId: Social.GetPlatformFriendList
export def "social-platform-friends SocialGetPlatformFriendList" [
  friendPlatform: int
  page: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Social/PlatformFriends/($friendPlatform)/($page)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of available localization cultures
#
# GET /GetAvailableLocales/
# operationId: .GetAvailableLocales
export def "get-available-locales GetAvailableLocales" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GetAvailableLocales/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the common settings used by the Bungie.Net environment.
#
# GET /Settings/
# operationId: .GetCommonSettings
export def "settings GetCommonSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Settings/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the user-specific system overrides that should be respected alongside common systems.
#
# GET /UserSystemOverrides/
# operationId: .GetUserSystemOverrides
export def "user-system-overrides GetUserSystemOverrides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UserSystemOverrides/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets any active global alert for display in the forum banners, help pages, etc. Usually used for DOC alerts.
#
# GET /GlobalAlerts/
# operationId: .GetGlobalAlerts
export def "global-alerts GetGlobalAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includestreaming: string@bool-completer # Determines whether Streaming Alerts are included in results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includestreaming" $includestreaming "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/GlobalAlerts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
