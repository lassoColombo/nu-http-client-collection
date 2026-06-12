# Auto-generated client for MangaDex API v5.13.1
# Source: https://api.mangadex.org/docs/static/api.yaml
# Auth: --token flag or $env.MANGADEX_API_TOKEN

const BASE_URL = "https://api.mangadex.org"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MANGADEX_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mangadex.org" "https://api.mangadex.dev"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def includedTagsMode-completer [] { ["AND" "OR"] }
def excludedTagsMode-completer [] { ["AND" "OR"] }
def hasAvailableChapters-completer [] { ["0" "1" "false" "true"] }
def hasUnavailableChapters-completer [] { ["0" "1" "false" "true"] }
def publicationDemographic-completer [] { ["josei" "seinen" "shoujo" "shounen"] }
def status-completer [] { ["cancelled" "completed" "hiatus" "ongoing"] }
def contentRating-completer [] { ["erotica" "pornographic" "safe" "suggestive"] }
def state-completer [] { ["approved" "autoapproved" "rejected" "requested"] }
def profile-completer [] { ["personal"] }
def visibility-completer [] { ["private" "public"] }
def includeFutureUpdates-completer [] { ["0" "1"] }
def includeEmptyPages-completer [] { ["0" "1"] }
def includeFuturePublishAt-completer [] { ["0" "1"] }
def includeExternalUrl-completer [] { ["0" "1"] }
def includeUnavailable-completer [] { ["0" "1"] }
def type-completer [] { ["chapter" "group" "manga" "tag"] }
def status-completer-1 [] { ["completed" "dropped" "on_hold" "plan_to_read" "re_reading" "reading"] }
def state-completer-1 [] { ["draft" "rejected" "submitted"] }
def category-completer [] { ["author" "chapter" "manga" "scanlation_group" "user"] }
def status-completer-2 [] { ["accepted" "autoresolved" "refused" "waiting"] }
def relation-completer [] { ["adapted_from" "alternate_story" "alternate_version" "based_on" "colored" "doujinshi" "main_story" "monochrome" "prequel" "preserialization" "same_franchise" "sequel" "serialization" "shared_universe" "side_story" "spin_off"] }
def type-completer-1 [] { ["chapter" "group" "manga"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ping get-ping" } } | get name | first)
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

# Ping healthcheck
#
# GET /ping
# operationId: get-ping
export def "ping get-ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manga list
#
# GET /manga
# operationId: get-search-manga
export def "manga get-search-manga" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --title: string
  --authorOrArtist: string # format: uuid
  --authors: list
  --artists: list
  --year: string # Year of release or none
  --includedTags: list
  --includedTagsMode: string@includedTagsMode-completer # default: AND
  --excludedTags: list
  --excludedTagsMode: string@excludedTagsMode-completer # default: OR
  --status: list
  --originalLanguage: list
  --excludedOriginalLanguage: list
  --availableTranslatedLanguage: list
  --publicationDemographic: list
  --ids: list # Manga ids (limited to 100 per request)
  --contentRating: list # default: [safe, suggestive, erotica]
  --createdAtSince: string
  --updatedAtSince: string
  --order: record # default: {latestUploadedChapter: desc}
  --includes: list
  --hasAvailableChapters: string@hasAvailableChapters-completer
  --hasUnavailableChapters: string@hasUnavailableChapters-completer
  --group: string # format: uuid
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "authorOrArtist" $authorOrArtist "scalar") (serialize-qp "authors[]" $authors "multi") (serialize-qp "artists[]" $artists "multi") (serialize-qp "year" $year "scalar") (serialize-qp "includedTags[]" $includedTags "multi") (serialize-qp "includedTagsMode" $includedTagsMode "scalar") (serialize-qp "excludedTags[]" $excludedTags "multi") (serialize-qp "excludedTagsMode" $excludedTagsMode "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "originalLanguage[]" $originalLanguage "multi") (serialize-qp "excludedOriginalLanguage[]" $excludedOriginalLanguage "multi") (serialize-qp "availableTranslatedLanguage[]" $availableTranslatedLanguage "multi") (serialize-qp "publicationDemographic[]" $publicationDemographic "multi") (serialize-qp "ids[]" $ids "multi") (serialize-qp "contentRating[]" $contentRating "multi") (serialize-qp "createdAtSince" $createdAtSince "scalar") (serialize-qp "updatedAtSince" $updatedAtSince "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi") (serialize-qp "hasAvailableChapters" $hasAvailableChapters "scalar") (serialize-qp "hasUnavailableChapters" $hasUnavailableChapters "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/manga" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Manga
#
# POST /manga
# operationId: post-manga
export def "manga post-manga" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  title: record
  --altTitles: list
  --description: record
  --authors: list
  --artists: list
  --links: record
  --officialLinks: record
  originalLanguage: string
  --lastVolume: string # nullable
  --lastChapter: string # nullable
  --publicationDemographic: string@publicationDemographic-completer # nullable
  status: string@status-completer
  --year: int # Year of release (nullable)
  contentRating: string@contentRating-completer
  --chapterNumbersResetOnNewVolume: oneof<nothing, bool>
  --tags: list
  --primaryCover: string # nullable, format: uuid
  --version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/manga")
  let body = {title: $title, altTitles: $altTitles, description: $description, authors: $authors, artists: $artists, links: $links, officialLinks: $officialLinks, originalLanguage: $originalLanguage, lastVolume: $lastVolume, lastChapter: $lastChapter, publicationDemographic: $publicationDemographic, status: $status, year: $year, contentRating: $contentRating, chapterNumbersResetOnNewVolume: $chapterNumbersResetOnNewVolume, tags: $tags, primaryCover: $primaryCover, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Manga volumes & chapters
#
# GET /manga/{id}/aggregate
# operationId: get-manga-aggregate
export def "manga-aggregate get-manga-aggregate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --translatedLanguage: list
  --groups: list
  --includeUnavailable: int
]: nothing -> record<result: string, volumes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "translatedLanguage[]" $translatedLanguage "multi") (serialize-qp "groups[]" $groups "multi") (serialize-qp "includeUnavailable" $includeUnavailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get up to 20 similar Manga Recommendations
#
# GET /manga/{id}/recommendation
# operationId: get-manga-recommendation
export def "manga-recommendation get-manga-recommendation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
  --order: record # default: {score: desc}
  --contentRating: list # default: [safe, suggestive, erotica]
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi") (serialize-qp "order" $order "deepObject") (serialize-qp "contentRating[]" $contentRating "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)/recommendation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Manga
#
# GET /manga/{id}
# operationId: get-manga-id
export def "manga get-manga-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Manga
#
# PUT /manga/{id}
# operationId: put-manga-id
export def "manga put-manga-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --artists: list
  --authors: list
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)")
  let body = {artists: $artists, authors: $authors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Manga
#
# DELETE /manga/{id}
# operationId: delete-manga-id
export def "manga delete-manga-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login
#
# POST /auth/login
# DEPRECATED
# operationId: post-auth-login
@deprecated
export def "auth-login post-auth-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --username: string
  --email: string
  password: string
]: any -> record<result: string, token: record<session: string, refresh: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let body = {username: $username, email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check the set of permissions associated with the current token
#
# GET /auth/check
# operationId: get-auth-check
export def "auth-check get-auth-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, isAuthenticated: bool, roles: list<string>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logout
#
# POST /auth/logout
# DEPRECATED
# operationId: post-auth-logout
@deprecated
export def "auth-logout post-auth-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh token
#
# POST /auth/refresh
# DEPRECATED
# operationId: post-auth-refresh
@deprecated
export def "auth-refresh post-auth-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --body-token: string
]: any -> record<result: string, token: record<session: string, refresh: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/refresh")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List own Api Clients
#
# GET /client
# operationId: get-list-apiclients
export def "client get-list-apiclients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --state: string@state-completer
  --name: string
  --includes: list
  --order: record # default: {createdAt: desc}
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "includes[]" $includes "multi") (serialize-qp "order" $order "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/client" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create ApiClient
#
# POST /client
# operationId: post-create-apiclient
export def "client post-create-apiclient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  name: string
  --description: string # nullable
  profile: string@profile-completer
  --version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, description: string, profile: string, externalClientId: string, isActive: bool, state: string, createdAt: string, updatedAt: string, version: int>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client")
  let body = {name: $name, description: $description, profile: $profile, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Api Client by ID
#
# GET /client/{id}
# operationId: get-apiclient
export def "client get-apiclient" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, description: string, profile: string, externalClientId: string, isActive: bool, state: string, createdAt: string, updatedAt: string, version: int>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit ApiClient
#
# POST /client/{id}
# operationId: post-edit-apiclient
export def "client post-edit-apiclient" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --description: string # nullable
  version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, description: string, profile: string, externalClientId: string, isActive: bool, state: string, createdAt: string, updatedAt: string, version: int>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client/($id)")
  let body = {description: $description, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Api Client
#
# DELETE /client/{id}
# operationId: delete-apiclient
export def "client delete-apiclient" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Secret for Client by ID
#
# GET /client/{id}/secret
# operationId: get-apiclient-secret
export def "client-secret get-apiclient-secret" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client/($id)/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate Client Secret
#
# POST /client/{id}/secret
# operationId: post-regenerate-apiclient-secret
export def "client-secret post-regenerate-apiclient-secret" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --body: record
]: any -> record<result: string, data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client/($id)/secret")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Scanlation Group list
#
# GET /group
# operationId: get-search-group
export def "group get-search-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --ids: list # ScanlationGroup ids (limited to 100 per request)
  --name: string
  --focusedLanguage: string
  --includes: list
  --order: record # default: {latestUploadedChapter: desc}
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ids[]" $ids "multi") (serialize-qp "name" $name "scalar") (serialize-qp "focusedLanguage" $focusedLanguage "scalar") (serialize-qp "includes[]" $includes "multi") (serialize-qp "order" $order "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Scanlation Group
#
# POST /group
# operationId: post-group
export def "group post-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  name: string
  --website: string # nullable
  --ircServer: string # nullable
  --ircChannel: string # nullable
  --discord: string # nullable
  --contactEmail: string # nullable
  --description: string # nullable
  --twitter: string # nullable, format: uri
  --mangaUpdates: string # nullable
  --inactive: oneof<nothing, bool>
  --publishDelay: string # nullable
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, altNames: list, website: string, ircServer: string, ircChannel: string, discord: string, contactEmail: string, description: string, twitter: string, mangaUpdates: string, focusedLanguage: list, locked: bool, official: bool, verified: bool, inactive: bool, exLicensed: bool, publishDelay: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/group")
  let body = {name: $name, website: $website, ircServer: $ircServer, ircChannel: $ircChannel, discord: $discord, contactEmail: $contactEmail, description: $description, twitter: $twitter, mangaUpdates: $mangaUpdates, inactive: $inactive, publishDelay: $publishDelay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Scanlation Group
#
# GET /group/{id}
# operationId: get-group-id
export def "group get-group-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, altNames: list, website: string, ircServer: string, ircChannel: string, discord: string, contactEmail: string, description: string, twitter: string, mangaUpdates: string, focusedLanguage: list, locked: bool, official: bool, verified: bool, inactive: bool, exLicensed: bool, publishDelay: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/group/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Scanlation Group
#
# PUT /group/{id}
# operationId: put-group-id
export def "group put-group-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --name: string
  --leader: string # format: uuid
  --members: list
  --website: string # nullable
  --ircServer: string # nullable
  --ircChannel: string # nullable
  --discord: string # nullable
  --contactEmail: string # nullable
  --description: string # nullable
  --twitter: string # nullable, format: uri
  --mangaUpdates: string # nullable, format: uri
  --focusedLanguages: list # nullable
  --inactive: oneof<nothing, bool>
  --locked: oneof<nothing, bool>
  --publishDelay: string
  version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, altNames: list, website: string, ircServer: string, ircChannel: string, discord: string, contactEmail: string, description: string, twitter: string, mangaUpdates: string, focusedLanguage: list, locked: bool, official: bool, verified: bool, inactive: bool, exLicensed: bool, publishDelay: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($id)")
  let body = {name: $name, leader: $leader, members: $members, website: $website, ircServer: $ircServer, ircChannel: $ircChannel, discord: $discord, contactEmail: $contactEmail, description: $description, twitter: $twitter, mangaUpdates: $mangaUpdates, focusedLanguages: $focusedLanguages, inactive: $inactive, locked: $locked, publishDelay: $publishDelay, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Scanlation Group
#
# DELETE /group/{id}
# operationId: delete-group-id
export def "group delete-group-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow Scanlation Group
#
# POST /group/{id}/follow
# operationId: post-group-id-follow
export def "group-follow post-group-id-follow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($id)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unfollow Scanlation Group
#
# DELETE /group/{id}/follow
# operationId: delete-group-id-follow
export def "group-follow delete-group-id-follow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/group/($id)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create CustomList
#
# POST /list
# operationId: post-list
export def "list post-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  name: string
  --visibility: string@visibility-completer
  --manga: list
  --version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, visibility: string, version: int>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/list")
  let body = {name: $name, visibility: $visibility, manga: $manga, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get CustomList
#
# GET /list/{id}
# operationId: get-list-id
export def "list get-list-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, visibility: string, version: int>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update CustomList
#
# PUT /list/{id}
# operationId: put-list-id
export def "list put-list-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --name: string
  --visibility: string@visibility-completer
  --manga: list
  version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, visibility: string, version: int>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list/($id)")
  let body = {name: $name, visibility: $visibility, manga: $manga, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete CustomList
#
# DELETE /list/{id}
# operationId: delete-list-id
export def "list delete-list-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow CustomList
#
# POST /list/{id}/follow
# operationId: follow-list-id
export def "list-follow follow-list-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --body: record
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list/($id)/follow")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unfollow CustomList
#
# DELETE /list/{id}/follow
# operationId: unfollow-list-id
export def "list-follow unfollow-list-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/list/($id)/follow")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add Manga in CustomList
#
# POST /manga/{id}/list/{listId}
# operationId: post-manga-id-list-listId
export def "manga-list post-manga-id-list-listId" [
  id: string
  listId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int # Sort manga relationship entries in ascending order by
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)/list/($listId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Manga in CustomList
#
# DELETE /manga/{id}/list/{listId}
# operationId: delete-manga-id-list-listId
export def "manga-list delete-manga-id-list-listId" [
  id: string
  listId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int # Sort manga relationship entries in ascending order by
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)/list/($listId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logged User CustomList list
#
# GET /user/list
# operationId: get-user-list
export def "user-list get-user-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User's CustomList list
#
# GET /user/{id}/list
# operationId: get-user-id-list
export def "user-list get-user-id-list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/($id)/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User list
#
# GET /user
# operationId: get-user
export def "user get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --ids: list # User ids (limited to 100 per request)
  --username: string
  --order: record
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ids[]" $ids "multi") (serialize-qp "username" $username "scalar") (serialize-qp "order" $order "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User
#
# GET /user/{id}
# operationId: get-user-id
export def "user get-user-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<username: string, roles: list, version: int>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete User
#
# DELETE /user/{id}
# DEPRECATED
# operationId: delete-user-id
@deprecated
export def "user delete-user-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve User deletion
#
# POST /user/delete/{code}
# DEPRECATED
# operationId: post-user-delete-code
@deprecated
export def "user-delete post-user-delete-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/delete/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Chapter list
#
# GET /chapter
# operationId: get-chapter
export def "chapter get-chapter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --ids: list # Chapter ids (limited to 100 per request)
  --title: string
  --groups: list
  --uploader: string
  --manga: string # format: uuid
  --volume: string
  --chapter: string
  --translatedLanguage: list
  --originalLanguage: list
  --excludedOriginalLanguage: list
  --contentRating: list # default: [safe, suggestive, erotica]
  --excludedGroups: list
  --excludedUploaders: list
  --includeFutureUpdates: string@includeFutureUpdates-completer # default: 1
  --includeEmptyPages: int@includeEmptyPages-completer
  --includeFuturePublishAt: int@includeFuturePublishAt-completer
  --includeExternalUrl: int@includeExternalUrl-completer
  --externalUrl: string
  --excludeExternalUrl: string
  --includeUnavailable: string@includeUnavailable-completer # default: 0
  --createdAtSince: string
  --updatedAtSince: string
  --publishAtSince: string
  --order: record
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ids[]" $ids "multi") (serialize-qp "title" $title "scalar") (serialize-qp "groups[]" $groups "multi") (serialize-qp "uploader" $uploader "scalar") (serialize-qp "manga" $manga "scalar") (serialize-qp "volume[]" $volume "scalar") (serialize-qp "chapter" $chapter "scalar") (serialize-qp "translatedLanguage[]" $translatedLanguage "multi") (serialize-qp "originalLanguage[]" $originalLanguage "multi") (serialize-qp "excludedOriginalLanguage[]" $excludedOriginalLanguage "multi") (serialize-qp "contentRating[]" $contentRating "multi") (serialize-qp "excludedGroups[]" $excludedGroups "multi") (serialize-qp "excludedUploaders[]" $excludedUploaders "multi") (serialize-qp "includeFutureUpdates" $includeFutureUpdates "scalar") (serialize-qp "includeEmptyPages" $includeEmptyPages "scalar") (serialize-qp "includeFuturePublishAt" $includeFuturePublishAt "scalar") (serialize-qp "includeExternalUrl" $includeExternalUrl "scalar") (serialize-qp "externalUrl" $externalUrl "scalar") (serialize-qp "excludeExternalUrl" $excludeExternalUrl "scalar") (serialize-qp "includeUnavailable" $includeUnavailable "scalar") (serialize-qp "createdAtSince" $createdAtSince "scalar") (serialize-qp "updatedAtSince" $updatedAtSince "scalar") (serialize-qp "publishAtSince" $publishAtSince "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/chapter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Chapter
#
# GET /chapter/{id}
# operationId: get-chapter-id
export def "chapter get-chapter-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: string, volume: string, chapter: string, pages: int, translatedLanguage: string, uploader: string, externalUrl: string, version: int, createdAt: string, updatedAt: string, publishAt: string, readableAt: string, isUnavailable: bool>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/chapter/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Chapter
#
# PUT /chapter/{id}
# operationId: put-chapter-id
export def "chapter put-chapter-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --title: string # nullable
  --volume: string # nullable
  --chapter: string # nullable
  --translatedLanguage: string
  --groups: list
  version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: string, volume: string, chapter: string, pages: int, translatedLanguage: string, uploader: string, externalUrl: string, version: int, createdAt: string, updatedAt: string, publishAt: string, readableAt: string, isUnavailable: bool>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chapter/($id)")
  let body = {title: $title, volume: $volume, chapter: $chapter, translatedLanguage: $translatedLanguage, groups: $groups, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Chapter
#
# DELETE /chapter/{id}
# operationId: delete-chapter-id
export def "chapter delete-chapter-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chapter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logged User followed Manga feed (Chapter list)
#
# GET /user/follows/manga/feed
# operationId: get-user-follows-manga-feed
export def "user-follows-manga-feed get-user-follows-manga-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 100
  --offset: int
  --translatedLanguage: list
  --originalLanguage: list
  --excludedOriginalLanguage: list
  --contentRating: list # default: [safe, suggestive, erotica]
  --excludedGroups: list
  --excludedUploaders: list
  --includeFutureUpdates: string@includeFutureUpdates-completer # default: 1
  --externalUrl: string
  --excludeExternalUrl: string
  --createdAtSince: string
  --updatedAtSince: string
  --publishAtSince: string
  --order: record
  --includes: list
  --includeEmptyPages: int@includeEmptyPages-completer
  --includeFuturePublishAt: int@includeFuturePublishAt-completer
  --includeExternalUrl: int@includeExternalUrl-completer
  --includeUnavailable: string@includeUnavailable-completer # default: 0
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "translatedLanguage[]" $translatedLanguage "multi") (serialize-qp "originalLanguage[]" $originalLanguage "multi") (serialize-qp "excludedOriginalLanguage[]" $excludedOriginalLanguage "multi") (serialize-qp "contentRating[]" $contentRating "multi") (serialize-qp "excludedGroups[]" $excludedGroups "multi") (serialize-qp "excludedUploaders[]" $excludedUploaders "multi") (serialize-qp "includeFutureUpdates" $includeFutureUpdates "scalar") (serialize-qp "externalUrl" $externalUrl "scalar") (serialize-qp "excludeExternalUrl" $excludeExternalUrl "scalar") (serialize-qp "createdAtSince" $createdAtSince "scalar") (serialize-qp "updatedAtSince" $updatedAtSince "scalar") (serialize-qp "publishAtSince" $publishAtSince "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi") (serialize-qp "includeEmptyPages" $includeEmptyPages "scalar") (serialize-qp "includeFuturePublishAt" $includeFuturePublishAt "scalar") (serialize-qp "includeExternalUrl" $includeExternalUrl "scalar") (serialize-qp "includeUnavailable" $includeUnavailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/follows/manga/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CustomList Manga feed
#
# GET /list/{id}/feed
# operationId: get-list-id-feed
export def "list-feed get-list-id-feed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 100
  --offset: int
  --translatedLanguage: list
  --originalLanguage: list
  --excludedOriginalLanguage: list
  --contentRating: list # default: [safe, suggestive, erotica]
  --excludedGroups: list
  --excludedUploaders: list
  --includeFutureUpdates: string@includeFutureUpdates-completer # default: 1
  --externalUrl: string
  --excludeExternalUrl: string
  --createdAtSince: string
  --updatedAtSince: string
  --publishAtSince: string
  --order: record
  --includes: list
  --includeEmptyPages: int@includeEmptyPages-completer
  --includeFuturePublishAt: int@includeFuturePublishAt-completer
  --includeExternalUrl: int@includeExternalUrl-completer
  --includeUnavailable: string@includeUnavailable-completer # default: 0
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "translatedLanguage[]" $translatedLanguage "multi") (serialize-qp "originalLanguage[]" $originalLanguage "multi") (serialize-qp "excludedOriginalLanguage[]" $excludedOriginalLanguage "multi") (serialize-qp "contentRating[]" $contentRating "multi") (serialize-qp "excludedGroups[]" $excludedGroups "multi") (serialize-qp "excludedUploaders[]" $excludedUploaders "multi") (serialize-qp "includeFutureUpdates" $includeFutureUpdates "scalar") (serialize-qp "externalUrl" $externalUrl "scalar") (serialize-qp "excludeExternalUrl" $excludeExternalUrl "scalar") (serialize-qp "createdAtSince" $createdAtSince "scalar") (serialize-qp "updatedAtSince" $updatedAtSince "scalar") (serialize-qp "publishAtSince" $publishAtSince "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi") (serialize-qp "includeEmptyPages" $includeEmptyPages "scalar") (serialize-qp "includeFuturePublishAt" $includeFuturePublishAt "scalar") (serialize-qp "includeExternalUrl" $includeExternalUrl "scalar") (serialize-qp "includeUnavailable" $includeUnavailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/list/($id)/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unfollow Manga
#
# DELETE /manga/{id}/follow
# operationId: delete-manga-id-follow
export def "manga-follow delete-manga-id-follow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow Manga
#
# POST /manga/{id}/follow
# operationId: post-manga-id-follow
export def "manga-follow post-manga-id-follow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)/follow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CoverArt list
#
# GET /cover
# operationId: get-cover
export def "cover get-cover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --manga: list # Manga ids (limited to 100 per request)
  --ids: list # Covers ids (limited to 100 per request)
  --uploaders: list # User ids (limited to 100 per request)
  --locales: list # Locales of cover art (limited to 100 per request)
  --order: record
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "manga[]" $manga "multi") (serialize-qp "ids[]" $ids "multi") (serialize-qp "uploaders[]" $uploaders "multi") (serialize-qp "locales[]" $locales "multi") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/cover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload Cover
#
# POST /cover/{mangaOrCoverId}
# operationId: upload-cover
export def "cover upload-cover" [
  mangaOrCoverId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --file: string # format: binary
  --volume: string # nullable
  --description: string
  --locale: string
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<volume: string, fileName: string, description: string, locale: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cover/($mangaOrCoverId)")
  let body = {file: $file, volume: $volume, description: $description, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get Cover
#
# GET /cover/{mangaOrCoverId}
# operationId: get-cover-id
export def "cover get-cover-id" [
  mangaOrCoverId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<volume: string, fileName: string, description: string, locale: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/cover/($mangaOrCoverId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit Cover
#
# PUT /cover/{mangaOrCoverId}
# operationId: edit-cover
export def "cover edit-cover" [
  mangaOrCoverId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --volume: string # nullable
  --description: string # nullable
  --locale: string # nullable
  version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<volume: string, fileName: string, description: string, locale: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cover/($mangaOrCoverId)")
  let body = {volume: $volume, description: $description, locale: $locale, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Cover
#
# DELETE /cover/{mangaOrCoverId}
# operationId: delete-cover
export def "cover delete-cover" [
  mangaOrCoverId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cover/($mangaOrCoverId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Author list
#
# GET /author
# operationId: get-author
export def "author get-author" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --ids: list # Author ids (limited to 100 per request)
  --name: string
  --order: record
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ids[]" $ids "multi") (serialize-qp "name" $name "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/author" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Author
#
# POST /author
# operationId: post-author
export def "author post-author" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  name: string
  --biography: record
  --twitter: string # nullable, format: uri
  --pixiv: string # nullable, format: uri
  --melonBook: string # nullable, format: uri
  --fanBox: string # nullable, format: uri
  --booth: string # nullable, format: uri
  --nicoVideo: string # nullable, format: uri
  --skeb: string # nullable, format: uri
  --fantia: string # nullable, format: uri
  --tumblr: string # nullable, format: uri
  --youtube: string # nullable, format: uri
  --weibo: string # nullable, format: uri
  --naver: string # nullable, format: uri
  --website: string # nullable, format: uri
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, imageUrl: string, biography: record, twitter: string, pixiv: string, melonBook: string, fanBox: string, booth: string, nicoVideo: string, skeb: string, fantia: string, tumblr: string, youtube: string, weibo: string, naver: string, namicomi: string, website: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/author")
  let body = {name: $name, biography: $biography, twitter: $twitter, pixiv: $pixiv, melonBook: $melonBook, fanBox: $fanBox, booth: $booth, nicoVideo: $nicoVideo, skeb: $skeb, fantia: $fantia, tumblr: $tumblr, youtube: $youtube, weibo: $weibo, naver: $naver, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Author
#
# GET /author/{id}
# operationId: get-author-id
export def "author get-author-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, imageUrl: string, biography: record, twitter: string, pixiv: string, melonBook: string, fanBox: string, booth: string, nicoVideo: string, skeb: string, fantia: string, tumblr: string, youtube: string, weibo: string, naver: string, namicomi: string, website: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/author/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Author
#
# PUT /author/{id}
# operationId: put-author-id
export def "author put-author-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --name: string
  --biography: record
  --twitter: string # nullable, format: uri
  --pixiv: string # nullable, format: uri
  --melonBook: string # nullable, format: uri
  --fanBox: string # nullable, format: uri
  --booth: string # nullable, format: uri
  --nicoVideo: string # nullable, format: uri
  --skeb: string # nullable, format: uri
  --fantia: string # nullable, format: uri
  --tumblr: string # nullable, format: uri
  --youtube: string # nullable, format: uri
  --weibo: string # nullable, format: uri
  --naver: string # nullable, format: uri
  --website: string # nullable, format: uri
  version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<name: string, imageUrl: string, biography: record, twitter: string, pixiv: string, melonBook: string, fanBox: string, booth: string, nicoVideo: string, skeb: string, fantia: string, tumblr: string, youtube: string, weibo: string, naver: string, namicomi: string, website: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/author/($id)")
  let body = {name: $name, biography: $biography, twitter: $twitter, pixiv: $pixiv, melonBook: $melonBook, fanBox: $fanBox, booth: $booth, nicoVideo: $nicoVideo, skeb: $skeb, fantia: $fantia, tumblr: $tumblr, youtube: $youtube, weibo: $weibo, naver: $naver, website: $website, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Author
#
# DELETE /author/{id}
# operationId: delete-author-id
export def "author delete-author-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/author/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Legacy ID mapping
#
# POST /legacy/mapping
# operationId: post-legacy-mapping
export def "legacy-mapping post-legacy-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --type: string@type-completer
  --ids: list
]: any -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legacy/mapping")
  let body = {type: $type, ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manga feed
#
# GET /manga/{id}/feed
# operationId: get-manga-id-feed
export def "manga-feed get-manga-id-feed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 100
  --offset: int
  --translatedLanguage: list
  --originalLanguage: list
  --excludedOriginalLanguage: list
  --contentRating: list # default: [safe, suggestive, erotica]
  --excludedGroups: list
  --excludedUploaders: list
  --includeFutureUpdates: string@includeFutureUpdates-completer # default: 1
  --externalUrl: string
  --excludeExternalUrl: string
  --createdAtSince: string
  --updatedAtSince: string
  --publishAtSince: string
  --order: record
  --includes: list
  --includeEmptyPages: int@includeEmptyPages-completer
  --includeFuturePublishAt: int@includeFuturePublishAt-completer
  --includeExternalUrl: int@includeExternalUrl-completer
  --includeUnavailable: string@includeUnavailable-completer # default: 0
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "translatedLanguage[]" $translatedLanguage "multi") (serialize-qp "originalLanguage[]" $originalLanguage "multi") (serialize-qp "excludedOriginalLanguage[]" $excludedOriginalLanguage "multi") (serialize-qp "contentRating[]" $contentRating "multi") (serialize-qp "excludedGroups[]" $excludedGroups "multi") (serialize-qp "excludedUploaders[]" $excludedUploaders "multi") (serialize-qp "includeFutureUpdates" $includeFutureUpdates "scalar") (serialize-qp "externalUrl" $externalUrl "scalar") (serialize-qp "excludeExternalUrl" $excludeExternalUrl "scalar") (serialize-qp "createdAtSince" $createdAtSince "scalar") (serialize-qp "updatedAtSince" $updatedAtSince "scalar") (serialize-qp "publishAtSince" $publishAtSince "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi") (serialize-qp "includeEmptyPages" $includeEmptyPages "scalar") (serialize-qp "includeFuturePublishAt" $includeFuturePublishAt "scalar") (serialize-qp "includeExternalUrl" $includeExternalUrl "scalar") (serialize-qp "includeUnavailable" $includeUnavailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manga read markers
#
# GET /manga/{id}/read
# operationId: get-manga-chapter-readmarkers
export def "manga-read get-manga-chapter-readmarkers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)/read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manga read markers batch
#
# POST /manga/{id}/read
# operationId: post-manga-chapter-readmarkers
export def "manga-read post-manga-chapter-readmarkers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updateHistory: oneof<nothing, bool> # Adding this will cause the chapter to be stored in the user's reading history
  --chapterIdsRead: list
  --chapterIdsUnread: list
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateHistory" $updateHistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($id)/read" $qp)
  let body = {chapterIdsRead: $chapterIdsRead, chapterIdsUnread: $chapterIdsUnread} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manga read markers
#
# GET /manga/read
# operationId: get-manga-chapter-readmarkers-2
export def "manga-read get-manga-chapter-readmarkers-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # Manga ids
  --grouped: oneof<nothing, bool> # Group results by manga ids
]: nothing -> record<result: string, data: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "grouped" $grouped "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/manga/read" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a random Manga
#
# GET /manga/random
# operationId: get-manga-random
export def "manga-random get-manga-random" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
  --contentRating: list # default: [safe, suggestive, erotica]
  --includedTags: list
  --includedTagsMode: string@includedTagsMode-completer # default: AND
  --excludedTags: list
  --excludedTagsMode: string@excludedTagsMode-completer # default: OR
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi") (serialize-qp "contentRating[]" $contentRating "multi") (serialize-qp "includedTags[]" $includedTags "multi") (serialize-qp "includedTagsMode" $includedTagsMode "scalar") (serialize-qp "excludedTags[]" $excludedTags "multi") (serialize-qp "excludedTagsMode" $excludedTagsMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/manga/random" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get MangaDex@Home server URL
#
# GET /at-home/server/{chapterId}
# operationId: get-at-home-server-chapterId
export def "at-home-server get-at-home-server-chapterId" [
  chapterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forcePort443: oneof<nothing, bool> # Force selecting from MangaDex@Home servers that use the standard HTTPS port 443.  While the conventional port for HTTPS traffic is 443 and servers are encouraged to use it, it is not a hard requirement as it technically isn't anything special.  However, some misbehaving school/office network will at time block traffic to non-standard ports, and setting this flag to `true` will ensure selection of a server that uses these. (default: false)
]: nothing -> record<result: string, baseUrl: string, chapter: record<hash: string, data: list<string>, dataSaver: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forcePort443" $forcePort443 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/at-home/server/($chapterId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag list
#
# GET /manga/tag
# operationId: get-manga-tag
export def "manga-tag get-manga-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/manga/tag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logged User details
#
# GET /user/me
# operationId: get-user-me
export def "user-me get-user-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<username: string, roles: list, version: int>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logged User followed Groups
#
# GET /user/follows/group
# operationId: get-user-follows-group
export def "user-follows-group get-user-follows-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user/follows/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if logged User follows a Group
#
# GET /user/follows/group/{id}
# operationId: get-user-follows-group-id
export def "user-follows-group get-user-follows-group-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/follows/group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logged User followed User list
#
# GET /user/follows/user
# operationId: get-user-follows-user
export def "user-follows-user get-user-follows-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/follows/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if logged User follows a User
#
# GET /user/follows/user/{id}
# operationId: get-user-follows-user-id
export def "user-follows-user get-user-follows-user-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/follows/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logged User followed Manga list
#
# GET /user/follows/manga
# operationId: get-user-follows-manga
export def "user-follows-manga get-user-follows-manga" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/user/follows/manga" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if logged User follows a Manga
#
# GET /user/follows/manga/{id}
# operationId: get-user-follows-manga-id
export def "user-follows-manga get-user-follows-manga-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/follows/manga/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get logged User followed CustomList list
#
# GET /user/follows/list
# operationId: get-user-follows-list
export def "user-follows-list get-user-follows-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/follows/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if logged User follows a CustomList
#
# GET /user/follows/list/{id}
# operationId: get-user-follows-list-id
export def "user-follows-list get-user-follows-list-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/follows/list/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Manga reading status for logged User
#
# GET /manga/status
# operationId: get-manga-status
export def "manga-status get-manga-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Used to filter the list by given status
]: nothing -> record<result: string, statuses: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/manga/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Manga reading status
#
# GET /manga/{id}/status
# operationId: get-manga-id-status
export def "manga-status get-manga-id-status" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Manga reading status
#
# POST /manga/{id}/status
# operationId: post-manga-id-status
export def "manga-status post-manga-id-status" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --status: string@status-completer-1 # nullable
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($id)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific Manga Draft
#
# GET /manga/draft/{id}
# operationId: get-manga-id-draft
export def "manga-draft get-manga-id-draft" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/draft/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a Manga Draft
#
# POST /manga/draft/{id}/commit
# operationId: commit-manga-draft
export def "manga-draft-commit commit-manga-draft" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/draft/($id)/commit")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of Manga Drafts
#
# GET /manga/draft
# operationId: get-manga-drafts
export def "manga-draft get-manga-drafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --state: string@state-completer-1
  --order: record # default: {createdAt: desc}
  --includes: list
]: nothing -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<title: record, altTitles: list, description: record, isLocked: bool, links: record, officialLinks: record, originalLanguage: string, lastVolume: string, lastChapter: string, publicationDemographic: string, status: string, year: int, contentRating: string, chapterNumbersResetOnNewVolume: bool, availableTranslatedLanguages: list, latestUploadedChapter: string, tags: list, state: string, version: int, createdAt: string, updatedAt: string>, relationships: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/manga/draft" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Solve Captcha
#
# POST /captcha/solve
# operationId: post-captcha-solve
export def "captcha-solve post-captcha-solve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  captchaChallenge: string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/captcha/solve")
  let body = {captchaChallenge: $captchaChallenge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of report reasons
#
# GET /report/reasons/{category}
# operationId: get-report-reasons-by-category
export def "report-reasons get-report-reasons-by-category" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/report/reasons/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of reports by the user
#
# GET /report
# operationId: get-reports
export def "report get-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 10
  --offset: int
  --category: string@category-completer
  --reasonId: string # format: uuid
  --objectId: string # format: uuid
  --status: string@status-completer-2
  --order: record # default: {createdAt: desc}
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "reasonId" $reasonId "scalar") (serialize-qp "objectId" $objectId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "order" $order "deepObject") (serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Report
#
# POST /report
# operationId: post-report
export def "report post-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --category: string@category-completer
  --reason: string # format: uuid
  --objectId: string # format: uuid
  --details: string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report")
  let body = {category: $category, reason: $reason, objectId: $objectId, details: $details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the current User upload session
#
# GET /upload
# operationId: get-upload-session
export def "upload get-upload-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, attributes: record<isCommitted: bool, isProcessed: bool, isDeleted: bool, version: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start an upload session
#
# POST /upload/begin
# operationId: begin-upload-session
export def "upload-begin begin-upload-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  groups: list
  manga: string # format: uuid
]: any -> record<id: string, type: string, attributes: record<isCommitted: bool, isProcessed: bool, isDeleted: bool, version: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upload/begin")
  let body = {groups: $groups, manga: $manga} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start an edit chapter session
#
# POST /upload/begin/{chapterId}
# operationId: begin-edit-session
export def "upload-begin begin-edit-session" [
  chapterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  version: int
]: any -> record<id: string, type: string, attributes: record<isCommitted: bool, isProcessed: bool, isDeleted: bool, version: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/begin/($chapterId)")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload images to the upload session
#
# POST /upload/{uploadSessionId}
# operationId: put-upload-session-file
export def "upload put-upload-session-file" [
  uploadSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --file: string # format: binary
]: any -> record<result: string, errors: table<id: string, status: int, title: string, detail: string, context: string>, data: table<id: string, type: string, attributes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/($uploadSessionId)")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Abandon upload session
#
# DELETE /upload/{uploadSessionId}
# operationId: abandon-upload-session
export def "upload abandon-upload-session" [
  uploadSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/($uploadSessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commit the upload session and specify chapter data
#
# POST /upload/{uploadSessionId}/commit
# operationId: commit-upload-session
# --chapterDraft shape: {volume: string, chapter: string, title: string, translatedLanguage: string, externalUrl?: string, publishAt?: string}
export def "upload-commit commit-upload-session" [
  uploadSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --chapterDraft: record # shape: {volume: string, chapter: string, title: string, translatedLanguage: string, externalUrl?: string, publishAt?: string}
  --pageOrder: list # ordered list of Upload Session File ids
  --termsAccepted: oneof<nothing, bool> # mandatory on chapter upload, refer to terms at https://mangadex.org/compliance
]: any -> record<id: string, type: string, attributes: record<title: string, volume: string, chapter: string, pages: int, translatedLanguage: string, uploader: string, externalUrl: string, version: int, createdAt: string, updatedAt: string, publishAt: string, readableAt: string, isUnavailable: bool>, relationships: table<id: string, type: string, related: string, attributes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/($uploadSessionId)/commit")
  let body = {chapterDraft: $chapterDraft, pageOrder: $pageOrder, termsAccepted: $termsAccepted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an uploaded image from the Upload Session
#
# DELETE /upload/{uploadSessionId}/{uploadSessionFileId}
# operationId: delete-uploaded-session-file
export def "upload delete-uploaded-session-file" [
  uploadSessionId: string
  uploadSessionFileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/($uploadSessionId)/($uploadSessionFileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a set of uploaded images from the Upload Session
#
# DELETE /upload/{uploadSessionId}/batch
# operationId: delete-uploaded-session-files
export def "upload-batch delete-uploaded-session-files" [
  uploadSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  --body: record
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/upload/($uploadSessionId)/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check if a given manga / locale for a User needs moderation approval
#
# POST /upload/check-approval-required
# operationId: upload-check-approval-required
export def "upload-check-approval-required upload-check-approval-required" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --manga: string # format: uuid
  --locale: string
]: any -> record<result: string, requiresApproval: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upload/check-approval-required")
  let body = {manga: $manga, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manga relation list
#
# GET /manga/{mangaId}/relation
# operationId: get-manga-relation
export def "manga-relation get-manga-relation" [
  mangaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list
]: nothing -> record<result: string, response: string, data: table<id: string, type: string, attributes: record, relationships: list>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes[]" $includes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/manga/($mangaId)/relation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Manga relation
#
# POST /manga/{mangaId}/relation
# operationId: post-manga-relation
export def "manga-relation post-manga-relation" [
  mangaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string
  targetManga: string # format: uuid
  relation: string@relation-completer
]: any -> record<result: string, response: string, data: record<id: string, type: string, attributes: record<relation: string, version: int>, relationships: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($mangaId)/relation")
  let body = {targetManga: $targetManga, relation: $relation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Manga relation
#
# DELETE /manga/{mangaId}/relation/{id}
# operationId: delete-manga-relation-id
export def "manga-relation delete-manga-relation-id" [
  mangaId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manga/($mangaId)/relation/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your ratings
#
# GET /rating
# operationId: get-rating
export def "rating get-rating" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --manga: list
]: nothing -> record<result: string, ratings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "manga" $manga "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/rating" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update Manga rating
#
# POST /rating/{mangaId}
# operationId: post-rating-manga-id
export def "rating post-rating-manga-id" [
  mangaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rating: int
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rating/($mangaId)")
  let body = {rating: $rating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Manga rating
#
# DELETE /rating/{mangaId}
# operationId: delete-rating-manga-id
export def "rating delete-rating-manga-id" [
  mangaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rating/($mangaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get statistics about given chapter
#
# GET /statistics/chapter/{uuid}
# operationId: get-statistics-chapter-uuid
export def "statistics-chapter get-statistics-chapter-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/statistics/chapter/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get statistics about given chapters
#
# GET /statistics/chapter
# operationId: get-statistics-chapters
export def "statistics-chapter get-statistics-chapters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chapter: list
]: nothing -> record<result: string, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chapter[]" $chapter "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/chapter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get statistics about given scanlation group
#
# GET /statistics/group/{uuid}
# operationId: get-statistics-group-uuid
export def "statistics-group get-statistics-group-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/statistics/group/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get statistics about given groups
#
# GET /statistics/group
# operationId: get-statistics-groups
export def "statistics-group get-statistics-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: list
]: nothing -> record<result: string, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group[]" $group "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get statistics about given Manga
#
# GET /statistics/manga/{uuid}
# operationId: get-statistics-manga-uuid
export def "statistics-manga get-statistics-manga-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/statistics/manga/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find statistics about given Manga
#
# GET /statistics/manga
# operationId: get-statistics-manga
export def "statistics-manga get-statistics-manga" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --manga: list
]: nothing -> record<result: string, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "manga[]" $manga "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/manga" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get latest Settings template
#
# GET /settings/template
# operationId: get-settings-template
export def "settings-template get-settings-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/template")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Settings template
#
# POST /settings/template
# operationId: post-settings-template
export def "settings-template post-settings-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/template")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Settings template by version id
#
# GET /settings/template/{version}
# operationId: get-settings-template-version
export def "settings-template get-settings-template-version" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/template/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an User Settings
#
# GET /settings
# operationId: get-settings
export def "settings get-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, updatedAt: string, settings: record, template: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an User Settings
#
# POST /settings
# operationId: post-settings
export def "settings post-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # A JSON object that can be validated against the lastest available template
  --updatedAt: string # Format: 2022-03-14T13:19:37 (format: date-time)
]: any -> record<result: string, updatedAt: string, settings: record, template: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings")
  let body = {settings: $settings, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get users reading history
#
# GET /user/history
# operationId: get-reading-history
export def "user-history get-reading-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string, ratings: table<chapterId: string, readDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create forums thread
#
# POST /forums/thread
# operationId: forums-thread-create
export def "forums-thread forums-thread-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The type of the resource
  --id: string # The id of the resource (format: uuid)
]: any -> record<result: string, response: string, data: record<type: string, id: int, attributes: record<repliesCount: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forums/thread")
  let body = {type: $type, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
