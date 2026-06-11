# Auto-generated client for Sonarr v3.0.0
# Source: https://raw.githubusercontent.com/Sonarr/Sonarr/develop/src/Sonarr.Api.V3/openapi.json
# Auth: --token flag or $env.SONARR_TOKEN

const BASE_URL = "http://localhost:8989"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SONARR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-Api-Key: $token_val}, query: ""} }
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://localhost:8989" "https://localhost:8989"] }
def auth-scheme-completer [] { ["x-api-key" "query-apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def priority-completer [] { ["high" "low" "normal"] }
def status-completer [] { ["aborted" "cancelled" "completed" "failed" "orphaned" "queued" "started"] }
def result-completer [] { ["successful" "unknown" "unsuccessful"] }
def trigger-completer [] { ["manual" "scheduled" "unspecified"] }
def preferredProtocol-completer [] { ["torrent" "unknown" "usenet"] }
def protocol-completer [] { ["torrent" "unknown" "usenet"] }
def applyTags-completer [] { ["add" "remove" "replace"] }
def releaseType-completer [] { ["multiEpisode" "seasonPack" "singleEpisode" "unknown"] }
def authenticationMethod-completer [] { ["basic" "external" "forms" "none"] }
def authenticationRequired-completer [] { ["disabledForLocalAddresses" "enabled"] }
def updateMechanism-completer [] { ["apt" "builtIn" "docker" "external" "script"] }
def proxyType-completer [] { ["http" "socks4" "socks5"] }
def certificateValidation-completer [] { ["disabled" "disabledForLocalAddresses" "enabled"] }
def shouldMonitor-completer [] { ["all" "existing" "firstSeason" "future" "lastSeason" "latestSeason" "missing" "monitorSpecials" "none" "pilot" "recent" "skip" "unknown" "unmonitorSpecials"] }
def monitorNewItems-completer [] { ["all" "none"] }
def seriesType-completer [] { ["anime" "daily" "standard"] }
def listType-completer [] { ["advanced" "other" "plex" "program" "simkl" "trakt"] }
def listSyncLevel-completer [] { ["disabled" "keepAndTag" "keepAndUnmonitor" "logOnly"] }
def downloadPropersAndRepacks-completer [] { ["doNotPrefer" "doNotUpgrade" "preferAndUpgrade"] }
def fileDate-completer [] { ["localAirDate" "none" "utcAirDate"] }
def rescanAfterRefresh-completer [] { ["afterManual" "always" "never"] }
def episodeTitleRequired-completer [] { ["always" "bulkSeasonReleases" "never"] }
def status-completer-1 [] { ["continuing" "deleted" "ended" "upcoming"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-info get" } } | get name | first)
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

# GET /api
export def "api-info get" [
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
  let full_url = (build-url $base "/api")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /login
export def "login post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --returnUrl: string
  --username: string
  --password: string
  --rememberMe: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnUrl" $returnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/login" $qp)
  let body = {username: $username, password: $password, rememberMe: $rememberMe} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# GET /login
export def "login get" [
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
  let full_url = (build-url $base "/login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /logout
export def "logout get" [
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
  let full_url = (build-url $base "/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/autotagging
#
# --specifications item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, negate?: bool, required?: bool, fields?: list}
export def "autotagging post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name: string # nullable
  --removeTagsAutomatically: string@bool-completer
  --tags: list # nullable
  --specifications: list # nullable — item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, negate?: bool, required?: bool, fields?: list}
]: any -> record<id: int, name: string, removeTagsAutomatically: bool, tags: list<int>, specifications: table<id: int, name: string, implementation: string, implementationName: string, negate: bool, required: bool, fields: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/autotagging")
  let body = {id: $id, name: $name, removeTagsAutomatically: $removeTagsAutomatically, tags: $tags, specifications: $specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/autotagging
export def "autotagging list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, removeTagsAutomatically: bool, tags: list<int>, specifications: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/autotagging")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/autotagging/{id}
#
# --specifications item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, negate?: bool, required?: bool, fields?: list}
export def "autotagging put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --name: string # nullable
  --removeTagsAutomatically: string@bool-completer
  --tags: list # nullable
  --specifications: list # nullable — item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, negate?: bool, required?: bool, fields?: list}
]: any -> record<id: int, name: string, removeTagsAutomatically: bool, tags: list<int>, specifications: table<id: int, name: string, implementation: string, implementationName: string, negate: bool, required: bool, fields: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/autotagging/($id)")
  let body = {id: $body_id, name: $name, removeTagsAutomatically: $removeTagsAutomatically, tags: $tags, specifications: $specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/autotagging/{id}
export def "autotagging delete" [
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
  let full_url = (build-url $base $"/api/v3/autotagging/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/autotagging/{id}
export def "autotagging get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, removeTagsAutomatically: bool, tags: list<int>, specifications: table<id: int, name: string, implementation: string, implementationName: string, negate: bool, required: bool, fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/autotagging/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/autotagging/schema
export def "autotagging-schema get" [
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
  let full_url = (build-url $base "/api/v3/autotagging/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/system/backup
export def "system-backup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, path: string, type: string, size: int, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/system/backup")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/system/backup/{id}
export def "system-backup delete" [
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
  let full_url = (build-url $base $"/api/v3/system/backup/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/system/backup/restore/{id}
export def "system-backup-restore post" [
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
  let full_url = (build-url $base $"/api/v3/system/backup/restore/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/system/backup/restore/upload
export def "system-backup-restore-upload post" [
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
  let full_url = (build-url $base "/api/v3/system/backup/restore/upload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/blocklist
export def "blocklist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
  --seriesIds: list
  --protocols: list
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, seriesId: int, episodeIds: list, sourceTitle: string, languages: list, quality: record, customFormats: list, date: string, protocol: string, indexer: string, message: string, series: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "seriesIds" $seriesIds "multi") (serialize-qp "protocols" $protocols "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/blocklist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/blocklist/{id}
export def "blocklist delete" [
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
  let full_url = (build-url $base $"/api/v3/blocklist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/blocklist/bulk
export def "blocklist-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/blocklist/bulk")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/calendar
export def "calendar list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # format: date-time
  --end: string # format: date-time
  --unmonitored: string@bool-completer # default: false
  --includeSeries: string@bool-completer # default: false
  --includeEpisodeFile: string@bool-completer # default: false
  --includeEpisodeImages: string@bool-completer # default: false
  --tags: string # default: 
]: nothing -> table<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list, quality: record, customFormats: list, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list, originalLanguage: record, remotePoster: string, seasons: list, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list, tags: list, added: string, addOptions: record, ratings: record, statistics: record, episodesChanged: bool, languageProfileId: int>, images: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "unmonitored" $unmonitored "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisodeFile" $includeEpisodeFile "scalar") (serialize-qp "includeEpisodeImages" $includeEpisodeImages "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/calendar/{id}
export def "calendar get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int>, images: table<coverType: string, url: string, remoteUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/calendar/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /feed/v3/calendar/sonarr.ics
export def "feed-calendar-sonarrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pastDays: int # format: int32, default: 7
  --futureDays: int # format: int32, default: 28
  --tags: string # default: 
  --unmonitored: string@bool-completer # default: false
  --premieresOnly: string@bool-completer # default: false
  --asAllDay: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pastDays" $pastDays "scalar") (serialize-qp "futureDays" $futureDays "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "unmonitored" $unmonitored "scalar") (serialize-qp "premieresOnly" $premieresOnly "scalar") (serialize-qp "asAllDay" $asAllDay "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feed/v3/calendar/sonarr.ics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/command
#
# --body shape: {sendUpdatesToClient?: bool, lastExecutionTime?: string, lastStartTime?: string, trigger?: "unspecified"|"manual"|"scheduled", suppressMessages?: bool, clientUserAgent?: string}
export def "command post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --name: string # nullable
  --commandName: string # nullable
  --message: string # nullable
  --body-body: record # shape: {sendUpdatesToClient?: bool, lastExecutionTime?: string, lastStartTime?: string, trigger?: "unspecified"|"manual"|"scheduled", suppressMessages?: bool, clientUserAgent?: string}
  --priority: string@priority-completer
  --status: string@status-completer
  --body-result: string@result-completer
  --queued: string # format: date-time
  --started: string # nullable, format: date-time
  --ended: string # nullable, format: date-time
  --duration: string # nullable, format: date-span
  --exception: string # nullable
  --trigger: string@trigger-completer
  --clientUserAgent: string # nullable
  --stateChangeTime: string # nullable, format: date-time
  --sendUpdatesToClient: string@bool-completer
  --updateScheduledTask: string@bool-completer
  --lastExecutionTime: string # nullable, format: date-time
]: any -> record<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isLongRunning: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, result: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/command")
  let body = {id: $id, name: $name, commandName: $commandName, message: $message, body: $body_body, priority: $priority, status: $status, result: $body_result, queued: $queued, started: $started, ended: $ended, duration: $duration, exception: $exception, trigger: $trigger, clientUserAgent: $clientUserAgent, stateChangeTime: $stateChangeTime, sendUpdatesToClient: $sendUpdatesToClient, updateScheduledTask: $updateScheduledTask, lastExecutionTime: $lastExecutionTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/command
export def "command list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isLongRunning: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, result: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/command")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/command/{id}
export def "command delete" [
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
  let full_url = (build-url $base $"/api/v3/command/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/command/{id}
export def "command get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isLongRunning: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, result: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/command/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/customfilter
export def "customfilter list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, type: string, label: string, filters: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/customfilter")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/customfilter
export def "customfilter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --type: string # nullable
  --label: string # nullable
  --filters: list # nullable
]: any -> record<id: int, type: string, label: string, filters: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/customfilter")
  let body = {id: $id, type: $type, label: $label, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/customfilter/{id}
export def "customfilter put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --type: string # nullable
  --label: string # nullable
  --filters: list # nullable
]: any -> record<id: int, type: string, label: string, filters: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/customfilter/($id)")
  let body = {id: $body_id, type: $type, label: $label, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/customfilter/{id}
export def "customfilter delete" [
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
  let full_url = (build-url $base $"/api/v3/customfilter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/customfilter/{id}
export def "customfilter get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, type: string, label: string, filters: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/customfilter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/customformat
export def "customformat list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/customformat")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/customformat
#
# --specifications item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, infoLink?: string, negate?: bool, required?: bool, fields?: list, presets?: list}
export def "customformat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name: string # nullable
  --includeCustomFormatWhenRenaming: string@bool-completer # nullable
  --specifications: list # nullable — item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, infoLink?: string, negate?: bool, required?: bool, fields?: list, presets?: list}
]: any -> record<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: table<id: int, name: string, implementation: string, implementationName: string, infoLink: string, negate: bool, required: bool, fields: list, presets: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/customformat")
  let body = {id: $id, name: $name, includeCustomFormatWhenRenaming: $includeCustomFormatWhenRenaming, specifications: $specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/customformat/{id}
#
# --specifications item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, infoLink?: string, negate?: bool, required?: bool, fields?: list, presets?: list}
export def "customformat put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --name: string # nullable
  --includeCustomFormatWhenRenaming: string@bool-completer # nullable
  --specifications: list # nullable — item shape: {id?: int, name?: string, implementation?: string, implementationName?: string, infoLink?: string, negate?: bool, required?: bool, fields?: list, presets?: list}
]: any -> record<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: table<id: int, name: string, implementation: string, implementationName: string, infoLink: string, negate: bool, required: bool, fields: list, presets: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/customformat/($id)")
  let body = {id: $body_id, name: $name, includeCustomFormatWhenRenaming: $includeCustomFormatWhenRenaming, specifications: $specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/customformat/{id}
export def "customformat delete" [
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
  let full_url = (build-url $base $"/api/v3/customformat/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/customformat/{id}
export def "customformat get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: table<id: int, name: string, implementation: string, implementationName: string, infoLink: string, negate: bool, required: bool, fields: list, presets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/customformat/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/customformat/bulk
export def "customformat-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --includeCustomFormatWhenRenaming: string@bool-completer # nullable
]: any -> record<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: table<id: int, name: string, implementation: string, implementationName: string, infoLink: string, negate: bool, required: bool, fields: list, presets: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/customformat/bulk")
  let body = {ids: $ids, includeCustomFormatWhenRenaming: $includeCustomFormatWhenRenaming} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/customformat/bulk
export def "customformat-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --includeCustomFormatWhenRenaming: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/customformat/bulk")
  let body = {ids: $ids, includeCustomFormatWhenRenaming: $includeCustomFormatWhenRenaming} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/customformat/schema
export def "customformat-schema get" [
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
  let full_url = (build-url $base "/api/v3/customformat/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/wanted/cutoff
export def "wanted-cutoff list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
  --includeSeries: string@bool-completer # default: false
  --includeEpisodeFile: string@bool-completer # default: false
  --includeImages: string@bool-completer # default: false
  --monitored: string@bool-completer # default: true
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record, images: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisodeFile" $includeEpisodeFile "scalar") (serialize-qp "includeImages" $includeImages "scalar") (serialize-qp "monitored" $monitored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/wanted/cutoff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/wanted/cutoff/{id}
export def "wanted-cutoff get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int>, images: table<coverType: string, url: string, remoteUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/wanted/cutoff/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/delayprofile
export def "delayprofile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --enableUsenet: string@bool-completer
  --enableTorrent: string@bool-completer
  --preferredProtocol: string@preferredProtocol-completer
  --usenetDelay: int # format: int32
  --torrentDelay: int # format: int32
  --bypassIfHighestQuality: string@bool-completer
  --bypassIfAboveCustomFormatScore: string@bool-completer
  --minimumCustomFormatScore: int # format: int32
  --order: int # format: int32
  --tags: list # nullable
]: any -> record<id: int, enableUsenet: bool, enableTorrent: bool, preferredProtocol: string, usenetDelay: int, torrentDelay: int, bypassIfHighestQuality: bool, bypassIfAboveCustomFormatScore: bool, minimumCustomFormatScore: int, order: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/delayprofile")
  let body = {id: $id, enableUsenet: $enableUsenet, enableTorrent: $enableTorrent, preferredProtocol: $preferredProtocol, usenetDelay: $usenetDelay, torrentDelay: $torrentDelay, bypassIfHighestQuality: $bypassIfHighestQuality, bypassIfAboveCustomFormatScore: $bypassIfAboveCustomFormatScore, minimumCustomFormatScore: $minimumCustomFormatScore, order: $order, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/delayprofile
export def "delayprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, enableUsenet: bool, enableTorrent: bool, preferredProtocol: string, usenetDelay: int, torrentDelay: int, bypassIfHighestQuality: bool, bypassIfAboveCustomFormatScore: bool, minimumCustomFormatScore: int, order: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/delayprofile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/delayprofile/{id}
export def "delayprofile delete" [
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
  let full_url = (build-url $base $"/api/v3/delayprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/delayprofile/{id}
export def "delayprofile put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --enableUsenet: string@bool-completer
  --enableTorrent: string@bool-completer
  --preferredProtocol: string@preferredProtocol-completer
  --usenetDelay: int # format: int32
  --torrentDelay: int # format: int32
  --bypassIfHighestQuality: string@bool-completer
  --bypassIfAboveCustomFormatScore: string@bool-completer
  --minimumCustomFormatScore: int # format: int32
  --order: int # format: int32
  --tags: list # nullable
]: any -> record<id: int, enableUsenet: bool, enableTorrent: bool, preferredProtocol: string, usenetDelay: int, torrentDelay: int, bypassIfHighestQuality: bool, bypassIfAboveCustomFormatScore: bool, minimumCustomFormatScore: int, order: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/delayprofile/($id)")
  let body = {id: $body_id, enableUsenet: $enableUsenet, enableTorrent: $enableTorrent, preferredProtocol: $preferredProtocol, usenetDelay: $usenetDelay, torrentDelay: $torrentDelay, bypassIfHighestQuality: $bypassIfHighestQuality, bypassIfAboveCustomFormatScore: $bypassIfAboveCustomFormatScore, minimumCustomFormatScore: $minimumCustomFormatScore, order: $order, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/delayprofile/{id}
export def "delayprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, enableUsenet: bool, enableTorrent: bool, preferredProtocol: string, usenetDelay: int, torrentDelay: int, bypassIfHighestQuality: bool, bypassIfAboveCustomFormatScore: bool, minimumCustomFormatScore: int, order: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/delayprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/delayprofile/reorder/{id}
export def "delayprofile-reorder put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --after: int # format: int32
]: nothing -> table<id: int, enableUsenet: bool, enableTorrent: bool, preferredProtocol: string, usenetDelay: int, torrentDelay: int, bypassIfHighestQuality: bool, bypassIfAboveCustomFormatScore: bool, minimumCustomFormatScore: int, order: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/delayprofile/reorder/($id)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/diskspace
export def "diskspace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, path: string, label: string, freeSpace: int, totalSpace: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/diskspace")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/downloadclient
export def "downloadclient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/downloadclient")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/downloadclient
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
export def "downloadclient post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
  --enable: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --removeCompletedDownloads: string@bool-completer
  --removeFailedDownloads: string@bool-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/downloadclient" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/downloadclient/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
export def "downloadclient put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
  --enable: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --removeCompletedDownloads: string@bool-completer
  --removeFailedDownloads: string@bool-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/downloadclient/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/downloadclient/{id}
export def "downloadclient delete" [
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
  let full_url = (build-url $base $"/api/v3/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/downloadclient/{id}
export def "downloadclient get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/downloadclient/bulk
export def "downloadclient-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enable: string@bool-completer # nullable
  --priority: int # nullable, format: int32
  --removeCompletedDownloads: string@bool-completer # nullable
  --removeFailedDownloads: string@bool-completer # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/downloadclient/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/downloadclient/bulk
export def "downloadclient-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enable: string@bool-completer # nullable
  --priority: int # nullable, format: int32
  --removeCompletedDownloads: string@bool-completer # nullable
  --removeFailedDownloads: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/downloadclient/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/downloadclient/schema
export def "downloadclient-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/downloadclient/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/downloadclient/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
export def "downloadclient-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
  --enable: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --removeCompletedDownloads: string@bool-completer
  --removeFailedDownloads: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/downloadclient/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v3/downloadclient/testall
export def "downloadclient-testall post" [
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
  let full_url = (build-url $base "/api/v3/downloadclient/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/downloadclient/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
export def "downloadclient-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
  --enable: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --removeCompletedDownloads: string@bool-completer
  --removeFailedDownloads: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/downloadclient/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/downloadclient
export def "config-downloadclient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, downloadClientWorkingFolders: string, enableCompletedDownloadHandling: bool, autoRedownloadFailed: bool, autoRedownloadFailedFromInteractiveSearch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/downloadclient")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/downloadclient/{id}
export def "config-downloadclient put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --downloadClientWorkingFolders: string # nullable
  --enableCompletedDownloadHandling: string@bool-completer
  --autoRedownloadFailed: string@bool-completer
  --autoRedownloadFailedFromInteractiveSearch: string@bool-completer
]: any -> record<id: int, downloadClientWorkingFolders: string, enableCompletedDownloadHandling: bool, autoRedownloadFailed: bool, autoRedownloadFailedFromInteractiveSearch: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/downloadclient/($id)")
  let body = {id: $body_id, downloadClientWorkingFolders: $downloadClientWorkingFolders, enableCompletedDownloadHandling: $enableCompletedDownloadHandling, autoRedownloadFailed: $autoRedownloadFailed, autoRedownloadFailedFromInteractiveSearch: $autoRedownloadFailedFromInteractiveSearch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/downloadclient/{id}
export def "config-downloadclient get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, downloadClientWorkingFolders: string, enableCompletedDownloadHandling: bool, autoRedownloadFailed: bool, autoRedownloadFailedFromInteractiveSearch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/episode
export def "episode list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesId: int # format: int32
  --seasonNumber: int # format: int32
  --episodeIds: list
  --episodeFileId: int # format: int32
  --includeSeries: string@bool-completer # default: false
  --includeEpisodeFile: string@bool-completer # default: false
  --includeImages: string@bool-completer # default: false
]: nothing -> table<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list, quality: record, customFormats: list, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list, originalLanguage: record, remotePoster: string, seasons: list, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list, tags: list, added: string, addOptions: record, ratings: record, statistics: record, episodesChanged: bool, languageProfileId: int>, images: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "seasonNumber" $seasonNumber "scalar") (serialize-qp "episodeIds" $episodeIds "multi") (serialize-qp "episodeFileId" $episodeFileId "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisodeFile" $includeEpisodeFile "scalar") (serialize-qp "includeImages" $includeImages "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/episode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/episode/{id}
#
# --episodeFile shape: {id?: int, seriesId?: int, seasonNumber?: int, relativePath?: string, path?: string, size?: int, dateAdded?: string, sceneName?: string, releaseGroup?: string, languages?: list, quality?: record, customFormats?: list, customFormatScore?: int, indexerFlags?: int, releaseType?: "unknown"|"singleEpisode"|"multiEpisode"|"seasonPack", mediaInfo?: record, qualityCutoffNotMet?: bool}
# --series shape: {id?: int, title?: string, alternateTitles?: list, sortTitle?: string, status?: "continuing"|"ended"|"upcoming"|"deleted", profileName?: string, overview?: string, nextAiring?: string, previousAiring?: string, network?: string, airTime?: string, images?: list, originalLanguage?: record, remotePoster?: string, seasons?: list, year?: int, path?: string, qualityProfileId?: int, seasonFolder?: bool, monitored?: bool, monitorNewItems?: "all"|"none", useSceneNumbering?: bool, runtime?: int, tvdbId?: int, tvRageId?: int, tvMazeId?: int, tmdbId?: int, firstAired?: string, lastAired?: string, seriesType?: "standard"|"daily"|"anime", cleanTitle?: string, imdbId?: string, titleSlug?: string, rootFolderPath?: string, folder?: string, certification?: string, genres?: list, tags?: list, added?: string, addOptions?: record, ratings?: record, statistics?: record, episodesChanged?: bool}
# --images item shape: {coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"clearlogo", url?: string, remoteUrl?: string}
export def "episode put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --seriesId: int # format: int32
  --tvdbId: int # format: int32
  --episodeFileId: int # format: int32
  --seasonNumber: int # format: int32
  --episodeNumber: int # format: int32
  --title: string # nullable
  --airDate: string # nullable
  --airDateUtc: string # nullable, format: date-time
  --lastSearchTime: string # nullable, format: date-time
  --runtime: int # format: int32
  --finaleType: string # nullable
  --overview: string # nullable
  --episodeFile: record # shape: {id?: int, seriesId?: int, seasonNumber?: int, relativePath?: string, path?: string, size?: int, dateAdded?: string, sceneName?: string, releaseGroup?: string, languages?: list, quality?: record, customFormats?: list, customFormatScore?: int, indexerFlags?: int, releaseType?: "unknown"|"singleEpisode"|"multiEpisode"|"seasonPack", mediaInfo?: record, qualityCutoffNotMet?: bool}
  --hasFile: string@bool-completer
  --monitored: string@bool-completer
  --absoluteEpisodeNumber: int # nullable, format: int32
  --sceneAbsoluteEpisodeNumber: int # nullable, format: int32
  --sceneEpisodeNumber: int # nullable, format: int32
  --sceneSeasonNumber: int # nullable, format: int32
  --unverifiedSceneNumbering: string@bool-completer
  --endTime: string # nullable, format: date-time
  --grabDate: string # nullable, format: date-time
  --series: record # shape: {id?: int, title?: string, alternateTitles?: list, sortTitle?: string, status?: "continuing"|"ended"|"upcoming"|"deleted", profileName?: string, overview?: string, nextAiring?: string, previousAiring?: string, network?: string, airTime?: string, images?: list, originalLanguage?: record, remotePoster?: string, seasons?: list, year?: int, path?: string, qualityProfileId?: int, seasonFolder?: bool, monitored?: bool, monitorNewItems?: "all"|"none", useSceneNumbering?: bool, runtime?: int, tvdbId?: int, tvRageId?: int, tvMazeId?: int, tmdbId?: int, firstAired?: string, lastAired?: string, seriesType?: "standard"|"daily"|"anime", cleanTitle?: string, imdbId?: string, titleSlug?: string, rootFolderPath?: string, folder?: string, certification?: string, genres?: list, tags?: list, added?: string, addOptions?: record, ratings?: record, statistics?: record, episodesChanged?: bool}
  --images: list # nullable — item shape: {coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"clearlogo", url?: string, remoteUrl?: string}
]: any -> record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int>, images: table<coverType: string, url: string, remoteUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/episode/($id)")
  let body = {id: $body_id, seriesId: $seriesId, tvdbId: $tvdbId, episodeFileId: $episodeFileId, seasonNumber: $seasonNumber, episodeNumber: $episodeNumber, title: $title, airDate: $airDate, airDateUtc: $airDateUtc, lastSearchTime: $lastSearchTime, runtime: $runtime, finaleType: $finaleType, overview: $overview, episodeFile: $episodeFile, hasFile: $hasFile, monitored: $monitored, absoluteEpisodeNumber: $absoluteEpisodeNumber, sceneAbsoluteEpisodeNumber: $sceneAbsoluteEpisodeNumber, sceneEpisodeNumber: $sceneEpisodeNumber, sceneSeasonNumber: $sceneSeasonNumber, unverifiedSceneNumbering: $unverifiedSceneNumbering, endTime: $endTime, grabDate: $grabDate, series: $series, images: $images} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/episode/{id}
export def "episode get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int>, images: table<coverType: string, url: string, remoteUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/episode/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/episode/monitor
export def "episode-monitor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeImages: string@bool-completer # default: false
  --episodeIds: list # nullable
  --monitored: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeImages" $includeImages "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/episode/monitor" $qp)
  let body = {episodeIds: $episodeIds, monitored: $monitored} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/episodefile
export def "episodefile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesId: int # format: int32
  --episodeFileIds: list
]: nothing -> table<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "episodeFileIds" $episodeFileIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/episodefile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/episodefile/{id}
#
# --languages item shape: {id?: int, name?: string}
# --quality shape: {quality?: record, revision?: record}
# --customFormats item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
# --mediaInfo shape: {id?: int, audioBitrate?: int, audioChannels?: float, audioCodec?: string, audioLanguages?: string, audioStreamCount?: int, videoBitDepth?: int, videoBitrate?: int, videoCodec?: string, videoFps?: float, videoDynamicRange?: string, videoDynamicRangeType?: string, resolution?: string, runTime?: string, scanType?: string, subtitles?: string}
export def "episodefile put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --seriesId: int # format: int32
  --seasonNumber: int # format: int32
  --relativePath: string # nullable
  --path: string # nullable
  --size: int # format: int64
  --dateAdded: string # format: date-time
  --sceneName: string # nullable
  --releaseGroup: string # nullable
  --languages: list # nullable — item shape: {id?: int, name?: string}
  --quality: record # shape: {quality?: record, revision?: record}
  --customFormats: list # nullable — item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
  --customFormatScore: int # format: int32
  --indexerFlags: int # nullable, format: int32
  --releaseType: string@releaseType-completer
  --mediaInfo: record # shape: {id?: int, audioBitrate?: int, audioChannels?: float, audioCodec?: string, audioLanguages?: string, audioStreamCount?: int, videoBitDepth?: int, videoBitrate?: int, videoCodec?: string, videoFps?: float, videoDynamicRange?: string, videoDynamicRangeType?: string, resolution?: string, runTime?: string, scanType?: string, subtitles?: string}
  --qualityCutoffNotMet: string@bool-completer
]: any -> record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: table<id: int, name: string>, quality: record<quality: record<id: int, name: string, source: string, resolution: int>, revision: record<version: int, real: int, isRepack: bool>>, customFormats: table<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: list>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/episodefile/($id)")
  let body = {id: $body_id, seriesId: $seriesId, seasonNumber: $seasonNumber, relativePath: $relativePath, path: $path, size: $size, dateAdded: $dateAdded, sceneName: $sceneName, releaseGroup: $releaseGroup, languages: $languages, quality: $quality, customFormats: $customFormats, customFormatScore: $customFormatScore, indexerFlags: $indexerFlags, releaseType: $releaseType, mediaInfo: $mediaInfo, qualityCutoffNotMet: $qualityCutoffNotMet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/episodefile/{id}
export def "episodefile delete" [
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
  let full_url = (build-url $base $"/api/v3/episodefile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/episodefile/{id}
export def "episodefile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: table<id: int, name: string>, quality: record<quality: record<id: int, name: string, source: string, resolution: int>, revision: record<version: int, real: int, isRepack: bool>>, customFormats: table<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: list>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/episodefile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/episodefile/editor
#
# --languages item shape: {id?: int, name?: string}
# --quality shape: {quality?: record, revision?: record}
export def "episodefile-editor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --episodeFileIds: list # nullable
  --languages: list # nullable — item shape: {id?: int, name?: string}
  --quality: record # shape: {quality?: record, revision?: record}
  --sceneName: string # nullable
  --releaseGroup: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/episodefile/editor")
  let body = {episodeFileIds: $episodeFileIds, languages: $languages, quality: $quality, sceneName: $sceneName, releaseGroup: $releaseGroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/episodefile/bulk
#
# --languages item shape: {id?: int, name?: string}
# --quality shape: {quality?: record, revision?: record}
export def "episodefile-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --episodeFileIds: list # nullable
  --languages: list # nullable — item shape: {id?: int, name?: string}
  --quality: record # shape: {quality?: record, revision?: record}
  --sceneName: string # nullable
  --releaseGroup: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/episodefile/bulk")
  let body = {episodeFileIds: $episodeFileIds, languages: $languages, quality: $quality, sceneName: $sceneName, releaseGroup: $releaseGroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/episodefile/bulk
export def "episodefile-bulk put" [
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
  let full_url = (build-url $base "/api/v3/episodefile/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/filesystem
export def "filesystem get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string
  --includeFiles: string@bool-completer # default: false
  --allowFoldersWithoutTrailingSlashes: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "includeFiles" $includeFiles "scalar") (serialize-qp "allowFoldersWithoutTrailingSlashes" $allowFoldersWithoutTrailingSlashes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/filesystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/filesystem/type
export def "filesystem-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/filesystem/type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/filesystem/mediafiles
export def "filesystem-mediafiles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/filesystem/mediafiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, source: string, type: string, message: string, wikiUrl: record<fullUri: string, scheme: string, host: string, port: int, path: string, query: string, fragment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/history
export def "history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
  --includeSeries: string@bool-completer
  --includeEpisode: string@bool-completer
  --eventType: list
  --episodeId: int # format: int32
  --downloadId: string
  --seriesIds: list
  --languages: list
  --quality: list
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, episodeId: int, seriesId: int, sourceTitle: string, languages: list, quality: record, customFormats: list, customFormatScore: int, qualityCutoffNotMet: bool, date: string, downloadId: string, eventType: string, data: record, episode: record, series: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisode" $includeEpisode "scalar") (serialize-qp "eventType" $eventType "multi") (serialize-qp "episodeId" $episodeId "scalar") (serialize-qp "downloadId" $downloadId "scalar") (serialize-qp "seriesIds" $seriesIds "multi") (serialize-qp "languages" $languages "multi") (serialize-qp "quality" $quality "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/history/since
export def "history-since get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # format: date-time
  --eventType: string
  --includeSeries: string@bool-completer # default: false
  --includeEpisode: string@bool-completer # default: false
]: nothing -> table<id: int, episodeId: int, seriesId: int, sourceTitle: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, qualityCutoffNotMet: bool, date: string, downloadId: string, eventType: string, data: record, episode: record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record, images: list>, series: record<id: int, title: string, alternateTitles: list, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list, originalLanguage: record, remotePoster: string, seasons: list, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list, tags: list, added: string, addOptions: record, ratings: record, statistics: record, episodesChanged: bool, languageProfileId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisode" $includeEpisode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/history/since" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/history/series
export def "history-series get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesId: int # format: int32
  --seasonNumber: int # format: int32
  --eventType: string
  --includeSeries: string@bool-completer # default: false
  --includeEpisode: string@bool-completer # default: false
]: nothing -> table<id: int, episodeId: int, seriesId: int, sourceTitle: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, qualityCutoffNotMet: bool, date: string, downloadId: string, eventType: string, data: record, episode: record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record, images: list>, series: record<id: int, title: string, alternateTitles: list, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list, originalLanguage: record, remotePoster: string, seasons: list, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list, tags: list, added: string, addOptions: record, ratings: record, statistics: record, episodesChanged: bool, languageProfileId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "seasonNumber" $seasonNumber "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisode" $includeEpisode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/history/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/history/failed/{id}
export def "history-failed post" [
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
  let full_url = (build-url $base $"/api/v3/history/failed/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/config/host
export def "config-host list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, logSizeLimit: int, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, trustCgnatIpAddresses: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/host")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/host/{id}
export def "config-host put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --bindAddress: string # nullable
  --port: int # format: int32
  --sslPort: int # format: int32
  --enableSsl: string@bool-completer
  --launchBrowser: string@bool-completer
  --authenticationMethod: string@authenticationMethod-completer
  --authenticationRequired: string@authenticationRequired-completer
  --analyticsEnabled: string@bool-completer
  --username: string # nullable
  --password: string # nullable
  --passwordConfirmation: string # nullable
  --logLevel: string # nullable
  --logSizeLimit: int # format: int32
  --consoleLogLevel: string # nullable
  --branch: string # nullable
  --apiKey: string # nullable
  --sslCertPath: string # nullable
  --sslCertPassword: string # nullable
  --urlBase: string # nullable
  --instanceName: string # nullable
  --applicationUrl: string # nullable
  --updateAutomatically: string@bool-completer
  --updateMechanism: string@updateMechanism-completer
  --updateScriptPath: string # nullable
  --proxyEnabled: string@bool-completer
  --proxyType: string@proxyType-completer
  --proxyHostname: string # nullable
  --proxyPort: int # format: int32
  --proxyUsername: string # nullable
  --proxyPassword: string # nullable
  --proxyBypassFilter: string # nullable
  --proxyBypassLocalAddresses: string@bool-completer
  --certificateValidation: string@certificateValidation-completer
  --backupFolder: string # nullable
  --backupInterval: int # format: int32
  --backupRetention: int # format: int32
  --trustCgnatIpAddresses: string@bool-completer
]: any -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, logSizeLimit: int, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, trustCgnatIpAddresses: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/host/($id)")
  let body = {id: $body_id, bindAddress: $bindAddress, port: $port, sslPort: $sslPort, enableSsl: $enableSsl, launchBrowser: $launchBrowser, authenticationMethod: $authenticationMethod, authenticationRequired: $authenticationRequired, analyticsEnabled: $analyticsEnabled, username: $username, password: $password, passwordConfirmation: $passwordConfirmation, logLevel: $logLevel, logSizeLimit: $logSizeLimit, consoleLogLevel: $consoleLogLevel, branch: $branch, apiKey: $apiKey, sslCertPath: $sslCertPath, sslCertPassword: $sslCertPassword, urlBase: $urlBase, instanceName: $instanceName, applicationUrl: $applicationUrl, updateAutomatically: $updateAutomatically, updateMechanism: $updateMechanism, updateScriptPath: $updateScriptPath, proxyEnabled: $proxyEnabled, proxyType: $proxyType, proxyHostname: $proxyHostname, proxyPort: $proxyPort, proxyUsername: $proxyUsername, proxyPassword: $proxyPassword, proxyBypassFilter: $proxyBypassFilter, proxyBypassLocalAddresses: $proxyBypassLocalAddresses, certificateValidation: $certificateValidation, backupFolder: $backupFolder, backupInterval: $backupInterval, backupRetention: $backupRetention, trustCgnatIpAddresses: $trustCgnatIpAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/host/{id}
export def "config-host get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, logSizeLimit: int, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, trustCgnatIpAddresses: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/host/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/importlist
export def "importlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, searchForMissingEpisodes: bool, shouldMonitor: string, monitorNewItems: string, rootFolderPath: string, qualityProfileId: int, seriesType: string, seasonFolder: bool, listType: string, listOrder: int, minRefreshInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/importlist
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
export def "importlist post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --searchForMissingEpisodes: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --monitorNewItems: string@monitorNewItems-completer
  --rootFolderPath: string # nullable
  --qualityProfileId: int # format: int32
  --seriesType: string@seriesType-completer
  --seasonFolder: string@bool-completer
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, searchForMissingEpisodes: bool, shouldMonitor: string, monitorNewItems: string, rootFolderPath: string, qualityProfileId: int, seriesType: string, seasonFolder: bool, listType: string, listOrder: int, minRefreshInterval: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/importlist" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, searchForMissingEpisodes: $searchForMissingEpisodes, shouldMonitor: $shouldMonitor, monitorNewItems: $monitorNewItems, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId, seriesType: $seriesType, seasonFolder: $seasonFolder, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/importlist/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
export def "importlist put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --searchForMissingEpisodes: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --monitorNewItems: string@monitorNewItems-completer
  --rootFolderPath: string # nullable
  --qualityProfileId: int # format: int32
  --seriesType: string@seriesType-completer
  --seasonFolder: string@bool-completer
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, searchForMissingEpisodes: bool, shouldMonitor: string, monitorNewItems: string, rootFolderPath: string, qualityProfileId: int, seriesType: string, seasonFolder: bool, listType: string, listOrder: int, minRefreshInterval: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/importlist/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, searchForMissingEpisodes: $searchForMissingEpisodes, shouldMonitor: $shouldMonitor, monitorNewItems: $monitorNewItems, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId, seriesType: $seriesType, seasonFolder: $seasonFolder, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/importlist/{id}
export def "importlist delete" [
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
  let full_url = (build-url $base $"/api/v3/importlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/importlist/{id}
export def "importlist get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, searchForMissingEpisodes: bool, shouldMonitor: string, monitorNewItems: string, rootFolderPath: string, qualityProfileId: int, seriesType: string, seasonFolder: bool, listType: string, listOrder: int, minRefreshInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/importlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/importlist/bulk
export def "importlist-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enableAutomaticAdd: string@bool-completer # nullable
  --rootFolderPath: string # nullable
  --qualityProfileId: int # nullable, format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, searchForMissingEpisodes: bool, shouldMonitor: string, monitorNewItems: string, rootFolderPath: string, qualityProfileId: int, seriesType: string, seasonFolder: bool, listType: string, listOrder: int, minRefreshInterval: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlist/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableAutomaticAdd: $enableAutomaticAdd, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/importlist/bulk
export def "importlist-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enableAutomaticAdd: string@bool-completer # nullable
  --rootFolderPath: string # nullable
  --qualityProfileId: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlist/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableAutomaticAdd: $enableAutomaticAdd, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/importlist/schema
export def "importlist-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, searchForMissingEpisodes: bool, shouldMonitor: string, monitorNewItems: string, rootFolderPath: string, qualityProfileId: int, seriesType: string, seasonFolder: bool, listType: string, listOrder: int, minRefreshInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlist/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/importlist/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
export def "importlist-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --searchForMissingEpisodes: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --monitorNewItems: string@monitorNewItems-completer
  --rootFolderPath: string # nullable
  --qualityProfileId: int # format: int32
  --seriesType: string@seriesType-completer
  --seasonFolder: string@bool-completer
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/importlist/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, searchForMissingEpisodes: $searchForMissingEpisodes, shouldMonitor: $shouldMonitor, monitorNewItems: $monitorNewItems, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId, seriesType: $seriesType, seasonFolder: $seasonFolder, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v3/importlist/testall
export def "importlist-testall post" [
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
  let full_url = (build-url $base "/api/v3/importlist/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/importlist/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
export def "importlist-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, searchForMissingEpisodes?: bool, shouldMonitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", monitorNewItems?: "all"|"none", rootFolderPath?: string, qualityProfileId?: int, seriesType?: "standard"|"daily"|"anime", seasonFolder?: bool, listType?: "program"|"plex"|"trakt"|"simkl"|"other"|"advanced", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --searchForMissingEpisodes: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --monitorNewItems: string@monitorNewItems-completer
  --rootFolderPath: string # nullable
  --qualityProfileId: int # format: int32
  --seriesType: string@seriesType-completer
  --seasonFolder: string@bool-completer
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/importlist/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, searchForMissingEpisodes: $searchForMissingEpisodes, shouldMonitor: $shouldMonitor, monitorNewItems: $monitorNewItems, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId, seriesType: $seriesType, seasonFolder: $seasonFolder, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/importlist
export def "config-importlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, listSyncLevel: string, listSyncTag: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/importlist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/importlist/{id}
export def "config-importlist put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --listSyncLevel: string@listSyncLevel-completer
  --listSyncTag: int # format: int32
]: any -> record<id: int, listSyncLevel: string, listSyncTag: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/importlist/($id)")
  let body = {id: $body_id, listSyncLevel: $listSyncLevel, listSyncTag: $listSyncTag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/importlist/{id}
export def "config-importlist get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, listSyncLevel: string, listSyncTag: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/importlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/importlistexclusion
#
# DEPRECATED
@deprecated
export def "importlistexclusion list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, tvdbId: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlistexclusion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/importlistexclusion
export def "importlistexclusion post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --tvdbId: int # format: int32
  --title: string # nullable
]: any -> record<id: int, tvdbId: int, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlistexclusion")
  let body = {id: $id, tvdbId: $tvdbId, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/importlistexclusion/paged
export def "importlistexclusion-paged get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, tvdbId: int, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/importlistexclusion/paged" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/importlistexclusion/{id}
export def "importlistexclusion put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --tvdbId: int # format: int32
  --title: string # nullable
]: any -> record<id: int, tvdbId: int, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/importlistexclusion/($id)")
  let body = {id: $body_id, tvdbId: $tvdbId, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/importlistexclusion/{id}
export def "importlistexclusion delete" [
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
  let full_url = (build-url $base $"/api/v3/importlistexclusion/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/importlistexclusion/{id}
export def "importlistexclusion get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, tvdbId: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/importlistexclusion/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/importlistexclusion/bulk
export def "importlistexclusion-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/importlistexclusion/bulk")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/indexer
export def "indexer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, seasonSearchMaximumSingleEpisodeAge: int, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/indexer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/indexer
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
export def "indexer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --seasonSearchMaximumSingleEpisodeAge: int # format: int32
  --downloadClientId: int # format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, seasonSearchMaximumSingleEpisodeAge: int, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/indexer" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, seasonSearchMaximumSingleEpisodeAge: $seasonSearchMaximumSingleEpisodeAge, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/indexer/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
export def "indexer put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --seasonSearchMaximumSingleEpisodeAge: int # format: int32
  --downloadClientId: int # format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, seasonSearchMaximumSingleEpisodeAge: int, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/indexer/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, seasonSearchMaximumSingleEpisodeAge: $seasonSearchMaximumSingleEpisodeAge, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/indexer/{id}
export def "indexer delete" [
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
  let full_url = (build-url $base $"/api/v3/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/indexer/{id}
export def "indexer get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, seasonSearchMaximumSingleEpisodeAge: int, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/indexer/bulk
export def "indexer-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enableRss: string@bool-completer # nullable
  --enableAutomaticSearch: string@bool-completer # nullable
  --enableInteractiveSearch: string@bool-completer # nullable
  --priority: int # nullable, format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, seasonSearchMaximumSingleEpisodeAge: int, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/indexer/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/indexer/bulk
export def "indexer-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enableRss: string@bool-completer # nullable
  --enableAutomaticSearch: string@bool-completer # nullable
  --enableInteractiveSearch: string@bool-completer # nullable
  --priority: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/indexer/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/indexer/schema
export def "indexer-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, seasonSearchMaximumSingleEpisodeAge: int, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/indexer/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/indexer/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
export def "indexer-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --seasonSearchMaximumSingleEpisodeAge: int # format: int32
  --downloadClientId: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/indexer/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, seasonSearchMaximumSingleEpisodeAge: $seasonSearchMaximumSingleEpisodeAge, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v3/indexer/testall
export def "indexer-testall post" [
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
  let full_url = (build-url $base "/api/v3/indexer/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/indexer/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
export def "indexer-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, seasonSearchMaximumSingleEpisodeAge?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --seasonSearchMaximumSingleEpisodeAge: int # format: int32
  --downloadClientId: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/indexer/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, seasonSearchMaximumSingleEpisodeAge: $seasonSearchMaximumSingleEpisodeAge, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/indexer
export def "config-indexer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, minimumAge: int, retention: int, maximumSize: int, rssSyncInterval: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/indexer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/indexer/{id}
export def "config-indexer put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --minimumAge: int # format: int32
  --retention: int # format: int32
  --maximumSize: int # format: int32
  --rssSyncInterval: int # format: int32
]: any -> record<id: int, minimumAge: int, retention: int, maximumSize: int, rssSyncInterval: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/indexer/($id)")
  let body = {id: $body_id, minimumAge: $minimumAge, retention: $retention, maximumSize: $maximumSize, rssSyncInterval: $rssSyncInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/indexer/{id}
export def "config-indexer get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, minimumAge: int, retention: int, maximumSize: int, rssSyncInterval: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/indexerflag
export def "indexerflag get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, nameLower: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/indexerflag")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/language
export def "language list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, nameLower: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/language")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/language/{id}
export def "language get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, nameLower: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/language/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/languageprofile
#
# DEPRECATED
# --cutoff shape: {id?: int, name?: string}
# --languages item shape: {id?: int, language?: record, allowed?: bool}
@deprecated
export def "languageprofile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --name: string # nullable
  --upgradeAllowed: string@bool-completer
  --cutoff: record # shape: {id?: int, name?: string}
  --languages: list # nullable — item shape: {id?: int, language?: record, allowed?: bool}
]: any -> record<id: int, name: string, upgradeAllowed: bool, cutoff: record<id: int, name: string>, languages: table<id: int, language: record, allowed: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/languageprofile")
  let body = {id: $id, name: $name, upgradeAllowed: $upgradeAllowed, cutoff: $cutoff, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/languageprofile
#
# DEPRECATED
@deprecated
export def "languageprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, upgradeAllowed: bool, cutoff: record<id: int, name: string>, languages: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/languageprofile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/languageprofile/{id}
#
# DEPRECATED
@deprecated
export def "languageprofile delete" [
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
  let full_url = (build-url $base $"/api/v3/languageprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/languageprofile/{id}
#
# DEPRECATED
# --cutoff shape: {id?: int, name?: string}
# --languages item shape: {id?: int, language?: record, allowed?: bool}
@deprecated
export def "languageprofile put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --name: string # nullable
  --upgradeAllowed: string@bool-completer
  --cutoff: record # shape: {id?: int, name?: string}
  --languages: list # nullable — item shape: {id?: int, language?: record, allowed?: bool}
]: any -> record<id: int, name: string, upgradeAllowed: bool, cutoff: record<id: int, name: string>, languages: table<id: int, language: record, allowed: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/languageprofile/($id)")
  let body = {id: $body_id, name: $name, upgradeAllowed: $upgradeAllowed, cutoff: $cutoff, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/languageprofile/{id}
export def "languageprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, upgradeAllowed: bool, cutoff: record<id: int, name: string>, languages: table<id: int, language: record, allowed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/languageprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/languageprofile/schema
#
# DEPRECATED
@deprecated
export def "languageprofile-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, upgradeAllowed: bool, cutoff: record<id: int, name: string>, languages: table<id: int, language: record, allowed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/languageprofile/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/localization
export def "localization list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, strings: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/localization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/localization/language
export def "localization-language get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/localization/language")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/localization/{id}
export def "localization get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, strings: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/localization/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/log
export def "log get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
  --level: string
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, time: string, exception: string, exceptionType: string, level: string, logger: string, message: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "level" $level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/log/file
export def "log-file list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, filename: string, lastWriteTime: string, contentsUrl: string, downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/log/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/log/file/{filename}
export def "log-file get" [
  filename: string
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
  let full_url = (build-url $base $"/api/v3/log/file/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/manualimport
export def "manualimport get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folder: string
  --downloadId: string
  --seriesId: int # format: int32
  --seasonNumber: int # format: int32
  --filterExistingFiles: string@bool-completer # default: true
]: nothing -> table<id: int, path: string, relativePath: string, folderName: string, name: string, size: int, series: record<id: int, title: string, alternateTitles: list, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list, originalLanguage: record, remotePoster: string, seasons: list, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list, tags: list, added: string, addOptions: record, ratings: record, statistics: record, episodesChanged: bool, languageProfileId: int>, seasonNumber: int, episodes: list<record>, episodeFileId: int, releaseGroup: string, quality: record<quality: record, revision: record>, languages: list<record>, qualityWeight: int, downloadId: string, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, rejections: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder" $folder "scalar") (serialize-qp "downloadId" $downloadId "scalar") (serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "seasonNumber" $seasonNumber "scalar") (serialize-qp "filterExistingFiles" $filterExistingFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/manualimport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/manualimport
export def "manualimport post" [
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
  let full_url = (build-url $base "/api/v3/manualimport")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/mediacover/{seriesId}/{filename}
export def "mediacover get" [
  seriesId: int
  filename: string
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
  let full_url = (build-url $base $"/api/v3/mediacover/($seriesId)/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/config/mediamanagement
export def "config-mediamanagement list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, autoUnmonitorPreviouslyDownloadedEpisodes: bool, recycleBin: string, recycleBinCleanupDays: int, downloadPropersAndRepacks: string, createEmptySeriesFolders: bool, deleteEmptyFolders: bool, fileDate: string, rescanAfterRefresh: string, setPermissionsLinux: bool, chmodFolder: string, chownGroup: string, episodeTitleRequired: string, skipFreeSpaceCheckWhenImporting: bool, minimumFreeSpaceWhenImporting: int, copyUsingHardlinks: bool, useScriptImport: bool, scriptImportPath: string, importExtraFiles: bool, extraFileExtensions: string, enableMediaInfo: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/mediamanagement")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/mediamanagement/{id}
export def "config-mediamanagement put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --autoUnmonitorPreviouslyDownloadedEpisodes: string@bool-completer
  --recycleBin: string # nullable
  --recycleBinCleanupDays: int # format: int32
  --downloadPropersAndRepacks: string@downloadPropersAndRepacks-completer
  --createEmptySeriesFolders: string@bool-completer
  --deleteEmptyFolders: string@bool-completer
  --fileDate: string@fileDate-completer
  --rescanAfterRefresh: string@rescanAfterRefresh-completer
  --setPermissionsLinux: string@bool-completer
  --chmodFolder: string # nullable
  --chownGroup: string # nullable
  --episodeTitleRequired: string@episodeTitleRequired-completer
  --skipFreeSpaceCheckWhenImporting: string@bool-completer
  --minimumFreeSpaceWhenImporting: int # format: int32
  --copyUsingHardlinks: string@bool-completer
  --useScriptImport: string@bool-completer
  --scriptImportPath: string # nullable
  --importExtraFiles: string@bool-completer
  --extraFileExtensions: string # nullable
  --enableMediaInfo: string@bool-completer
]: any -> record<id: int, autoUnmonitorPreviouslyDownloadedEpisodes: bool, recycleBin: string, recycleBinCleanupDays: int, downloadPropersAndRepacks: string, createEmptySeriesFolders: bool, deleteEmptyFolders: bool, fileDate: string, rescanAfterRefresh: string, setPermissionsLinux: bool, chmodFolder: string, chownGroup: string, episodeTitleRequired: string, skipFreeSpaceCheckWhenImporting: bool, minimumFreeSpaceWhenImporting: int, copyUsingHardlinks: bool, useScriptImport: bool, scriptImportPath: string, importExtraFiles: bool, extraFileExtensions: string, enableMediaInfo: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/mediamanagement/($id)")
  let body = {id: $body_id, autoUnmonitorPreviouslyDownloadedEpisodes: $autoUnmonitorPreviouslyDownloadedEpisodes, recycleBin: $recycleBin, recycleBinCleanupDays: $recycleBinCleanupDays, downloadPropersAndRepacks: $downloadPropersAndRepacks, createEmptySeriesFolders: $createEmptySeriesFolders, deleteEmptyFolders: $deleteEmptyFolders, fileDate: $fileDate, rescanAfterRefresh: $rescanAfterRefresh, setPermissionsLinux: $setPermissionsLinux, chmodFolder: $chmodFolder, chownGroup: $chownGroup, episodeTitleRequired: $episodeTitleRequired, skipFreeSpaceCheckWhenImporting: $skipFreeSpaceCheckWhenImporting, minimumFreeSpaceWhenImporting: $minimumFreeSpaceWhenImporting, copyUsingHardlinks: $copyUsingHardlinks, useScriptImport: $useScriptImport, scriptImportPath: $scriptImportPath, importExtraFiles: $importExtraFiles, extraFileExtensions: $extraFileExtensions, enableMediaInfo: $enableMediaInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/mediamanagement/{id}
export def "config-mediamanagement get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, autoUnmonitorPreviouslyDownloadedEpisodes: bool, recycleBin: string, recycleBinCleanupDays: int, downloadPropersAndRepacks: string, createEmptySeriesFolders: bool, deleteEmptyFolders: bool, fileDate: string, rescanAfterRefresh: string, setPermissionsLinux: bool, chmodFolder: string, chownGroup: string, episodeTitleRequired: string, skipFreeSpaceCheckWhenImporting: bool, minimumFreeSpaceWhenImporting: int, copyUsingHardlinks: bool, useScriptImport: bool, scriptImportPath: string, importExtraFiles: bool, extraFileExtensions: string, enableMediaInfo: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/mediamanagement/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/metadata
export def "metadata list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/metadata
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
export def "metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
  --enable: string@bool-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/metadata" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/metadata/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
export def "metadata put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
  --enable: string@bool-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/metadata/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/metadata/{id}
export def "metadata delete" [
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
  let full_url = (build-url $base $"/api/v3/metadata/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/metadata/{id}
export def "metadata get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/metadata/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/metadata/schema
export def "metadata-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/metadata/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/metadata/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
export def "metadata-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
  --enable: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/metadata/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v3/metadata/testall
export def "metadata-testall post" [
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
  let full_url = (build-url $base "/api/v3/metadata/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/metadata/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
export def "metadata-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
  --enable: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/metadata/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/wanted/missing
export def "wanted-missing list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
  --includeSeries: string@bool-completer # default: false
  --includeImages: string@bool-completer # default: false
  --monitored: string@bool-completer # default: true
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record, images: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeImages" $includeImages "scalar") (serialize-qp "monitored" $monitored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/wanted/missing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/wanted/missing/{id}
export def "wanted-missing get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record<id: int, seriesId: int, seasonNumber: int, relativePath: string, path: string, size: int, dateAdded: string, sceneName: string, releaseGroup: string, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, indexerFlags: int, releaseType: string, mediaInfo: record<id: int, audioBitrate: int, audioChannels: float, audioCodec: string, audioLanguages: string, audioStreamCount: int, videoBitDepth: int, videoBitrate: int, videoCodec: string, videoFps: float, videoDynamicRange: string, videoDynamicRangeType: string, resolution: string, runTime: string, scanType: string, subtitles: string>, qualityCutoffNotMet: bool>, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int>, images: table<coverType: string, url: string, remoteUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/wanted/missing/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/config/naming
export def "config-naming list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, renameEpisodes: bool, replaceIllegalCharacters: bool, colonReplacementFormat: int, customColonReplacementFormat: string, multiEpisodeStyle: int, standardEpisodeFormat: string, dailyEpisodeFormat: string, animeEpisodeFormat: string, seriesFolderFormat: string, seasonFolderFormat: string, specialsFolderFormat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/naming")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/naming/{id}
export def "config-naming put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --renameEpisodes: string@bool-completer
  --replaceIllegalCharacters: string@bool-completer
  --colonReplacementFormat: int # format: int32
  --customColonReplacementFormat: string # nullable
  --multiEpisodeStyle: int # format: int32
  --standardEpisodeFormat: string # nullable
  --dailyEpisodeFormat: string # nullable
  --animeEpisodeFormat: string # nullable
  --seriesFolderFormat: string # nullable
  --seasonFolderFormat: string # nullable
  --specialsFolderFormat: string # nullable
]: any -> record<id: int, renameEpisodes: bool, replaceIllegalCharacters: bool, colonReplacementFormat: int, customColonReplacementFormat: string, multiEpisodeStyle: int, standardEpisodeFormat: string, dailyEpisodeFormat: string, animeEpisodeFormat: string, seriesFolderFormat: string, seasonFolderFormat: string, specialsFolderFormat: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/naming/($id)")
  let body = {id: $body_id, renameEpisodes: $renameEpisodes, replaceIllegalCharacters: $replaceIllegalCharacters, colonReplacementFormat: $colonReplacementFormat, customColonReplacementFormat: $customColonReplacementFormat, multiEpisodeStyle: $multiEpisodeStyle, standardEpisodeFormat: $standardEpisodeFormat, dailyEpisodeFormat: $dailyEpisodeFormat, animeEpisodeFormat: $animeEpisodeFormat, seriesFolderFormat: $seriesFolderFormat, seasonFolderFormat: $seasonFolderFormat, specialsFolderFormat: $specialsFolderFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/naming/{id}
export def "config-naming get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, renameEpisodes: bool, replaceIllegalCharacters: bool, colonReplacementFormat: int, customColonReplacementFormat: string, multiEpisodeStyle: int, standardEpisodeFormat: string, dailyEpisodeFormat: string, animeEpisodeFormat: string, seriesFolderFormat: string, seasonFolderFormat: string, specialsFolderFormat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/naming/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/config/naming/examples
export def "config-naming-examples get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --renameEpisodes: string@bool-completer
  --replaceIllegalCharacters: string@bool-completer
  --colonReplacementFormat: int # format: int32
  --customColonReplacementFormat: string
  --multiEpisodeStyle: int # format: int32
  --standardEpisodeFormat: string
  --dailyEpisodeFormat: string
  --animeEpisodeFormat: string
  --seriesFolderFormat: string
  --seasonFolderFormat: string
  --specialsFolderFormat: string
  --id: int # format: int32
  --resourceName: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "renameEpisodes" $renameEpisodes "scalar") (serialize-qp "replaceIllegalCharacters" $replaceIllegalCharacters "scalar") (serialize-qp "colonReplacementFormat" $colonReplacementFormat "scalar") (serialize-qp "customColonReplacementFormat" $customColonReplacementFormat "scalar") (serialize-qp "multiEpisodeStyle" $multiEpisodeStyle "scalar") (serialize-qp "standardEpisodeFormat" $standardEpisodeFormat "scalar") (serialize-qp "dailyEpisodeFormat" $dailyEpisodeFormat "scalar") (serialize-qp "animeEpisodeFormat" $animeEpisodeFormat "scalar") (serialize-qp "seriesFolderFormat" $seriesFolderFormat "scalar") (serialize-qp "seasonFolderFormat" $seasonFolderFormat "scalar") (serialize-qp "specialsFolderFormat" $specialsFolderFormat "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "resourceName" $resourceName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/config/naming/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/notification
export def "notification list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onDownload: bool, onUpgrade: bool, onImportComplete: bool, onRename: bool, onSeriesAdd: bool, onSeriesDelete: bool, onEpisodeFileDelete: bool, onEpisodeFileDeleteForUpgrade: bool, onHealthIssue: bool, includeHealthWarnings: bool, onHealthRestored: bool, onApplicationUpdate: bool, onManualInteractionRequired: bool, supportsOnGrab: bool, supportsOnDownload: bool, supportsOnUpgrade: bool, supportsOnImportComplete: bool, supportsOnRename: bool, supportsOnSeriesAdd: bool, supportsOnSeriesDelete: bool, supportsOnEpisodeFileDelete: bool, supportsOnEpisodeFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, supportsOnApplicationUpdate: bool, supportsOnManualInteractionRequired: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/notification
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
export def "notification post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onDownload: string@bool-completer
  --onUpgrade: string@bool-completer
  --onImportComplete: string@bool-completer
  --onRename: string@bool-completer
  --onSeriesAdd: string@bool-completer
  --onSeriesDelete: string@bool-completer
  --onEpisodeFileDelete: string@bool-completer
  --onEpisodeFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --onHealthRestored: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --onManualInteractionRequired: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnDownload: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnImportComplete: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnSeriesAdd: string@bool-completer
  --supportsOnSeriesDelete: string@bool-completer
  --supportsOnEpisodeFileDelete: string@bool-completer
  --supportsOnEpisodeFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --supportsOnHealthRestored: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --supportsOnManualInteractionRequired: string@bool-completer
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onDownload: bool, onUpgrade: bool, onImportComplete: bool, onRename: bool, onSeriesAdd: bool, onSeriesDelete: bool, onEpisodeFileDelete: bool, onEpisodeFileDeleteForUpgrade: bool, onHealthIssue: bool, includeHealthWarnings: bool, onHealthRestored: bool, onApplicationUpdate: bool, onManualInteractionRequired: bool, supportsOnGrab: bool, supportsOnDownload: bool, supportsOnUpgrade: bool, supportsOnImportComplete: bool, supportsOnRename: bool, supportsOnSeriesAdd: bool, supportsOnSeriesDelete: bool, supportsOnEpisodeFileDelete: bool, supportsOnEpisodeFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, supportsOnApplicationUpdate: bool, supportsOnManualInteractionRequired: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/notification" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onDownload: $onDownload, onUpgrade: $onUpgrade, onImportComplete: $onImportComplete, onRename: $onRename, onSeriesAdd: $onSeriesAdd, onSeriesDelete: $onSeriesDelete, onEpisodeFileDelete: $onEpisodeFileDelete, onEpisodeFileDeleteForUpgrade: $onEpisodeFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, includeHealthWarnings: $includeHealthWarnings, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, onManualInteractionRequired: $onManualInteractionRequired, supportsOnGrab: $supportsOnGrab, supportsOnDownload: $supportsOnDownload, supportsOnUpgrade: $supportsOnUpgrade, supportsOnImportComplete: $supportsOnImportComplete, supportsOnRename: $supportsOnRename, supportsOnSeriesAdd: $supportsOnSeriesAdd, supportsOnSeriesDelete: $supportsOnSeriesDelete, supportsOnEpisodeFileDelete: $supportsOnEpisodeFileDelete, supportsOnEpisodeFileDeleteForUpgrade: $supportsOnEpisodeFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, supportsOnManualInteractionRequired: $supportsOnManualInteractionRequired, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/notification/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
export def "notification put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: string@bool-completer # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onDownload: string@bool-completer
  --onUpgrade: string@bool-completer
  --onImportComplete: string@bool-completer
  --onRename: string@bool-completer
  --onSeriesAdd: string@bool-completer
  --onSeriesDelete: string@bool-completer
  --onEpisodeFileDelete: string@bool-completer
  --onEpisodeFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --onHealthRestored: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --onManualInteractionRequired: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnDownload: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnImportComplete: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnSeriesAdd: string@bool-completer
  --supportsOnSeriesDelete: string@bool-completer
  --supportsOnEpisodeFileDelete: string@bool-completer
  --supportsOnEpisodeFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --supportsOnHealthRestored: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --supportsOnManualInteractionRequired: string@bool-completer
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onDownload: bool, onUpgrade: bool, onImportComplete: bool, onRename: bool, onSeriesAdd: bool, onSeriesDelete: bool, onEpisodeFileDelete: bool, onEpisodeFileDeleteForUpgrade: bool, onHealthIssue: bool, includeHealthWarnings: bool, onHealthRestored: bool, onApplicationUpdate: bool, onManualInteractionRequired: bool, supportsOnGrab: bool, supportsOnDownload: bool, supportsOnUpgrade: bool, supportsOnImportComplete: bool, supportsOnRename: bool, supportsOnSeriesAdd: bool, supportsOnSeriesDelete: bool, supportsOnEpisodeFileDelete: bool, supportsOnEpisodeFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, supportsOnApplicationUpdate: bool, supportsOnManualInteractionRequired: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/notification/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onDownload: $onDownload, onUpgrade: $onUpgrade, onImportComplete: $onImportComplete, onRename: $onRename, onSeriesAdd: $onSeriesAdd, onSeriesDelete: $onSeriesDelete, onEpisodeFileDelete: $onEpisodeFileDelete, onEpisodeFileDeleteForUpgrade: $onEpisodeFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, includeHealthWarnings: $includeHealthWarnings, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, onManualInteractionRequired: $onManualInteractionRequired, supportsOnGrab: $supportsOnGrab, supportsOnDownload: $supportsOnDownload, supportsOnUpgrade: $supportsOnUpgrade, supportsOnImportComplete: $supportsOnImportComplete, supportsOnRename: $supportsOnRename, supportsOnSeriesAdd: $supportsOnSeriesAdd, supportsOnSeriesDelete: $supportsOnSeriesDelete, supportsOnEpisodeFileDelete: $supportsOnEpisodeFileDelete, supportsOnEpisodeFileDeleteForUpgrade: $supportsOnEpisodeFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, supportsOnManualInteractionRequired: $supportsOnManualInteractionRequired, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/notification/{id}
export def "notification delete" [
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
  let full_url = (build-url $base $"/api/v3/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/notification/{id}
export def "notification get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onDownload: bool, onUpgrade: bool, onImportComplete: bool, onRename: bool, onSeriesAdd: bool, onSeriesDelete: bool, onEpisodeFileDelete: bool, onEpisodeFileDeleteForUpgrade: bool, onHealthIssue: bool, includeHealthWarnings: bool, onHealthRestored: bool, onApplicationUpdate: bool, onManualInteractionRequired: bool, supportsOnGrab: bool, supportsOnDownload: bool, supportsOnUpgrade: bool, supportsOnImportComplete: bool, supportsOnRename: bool, supportsOnSeriesAdd: bool, supportsOnSeriesDelete: bool, supportsOnEpisodeFileDelete: bool, supportsOnEpisodeFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, supportsOnApplicationUpdate: bool, supportsOnManualInteractionRequired: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/notification/schema
export def "notification-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onDownload: bool, onUpgrade: bool, onImportComplete: bool, onRename: bool, onSeriesAdd: bool, onSeriesDelete: bool, onEpisodeFileDelete: bool, onEpisodeFileDeleteForUpgrade: bool, onHealthIssue: bool, includeHealthWarnings: bool, onHealthRestored: bool, onApplicationUpdate: bool, onManualInteractionRequired: bool, supportsOnGrab: bool, supportsOnDownload: bool, supportsOnUpgrade: bool, supportsOnImportComplete: bool, supportsOnRename: bool, supportsOnSeriesAdd: bool, supportsOnSeriesDelete: bool, supportsOnEpisodeFileDelete: bool, supportsOnEpisodeFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, supportsOnApplicationUpdate: bool, supportsOnManualInteractionRequired: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/notification/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/notification/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
export def "notification-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: string@bool-completer # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onDownload: string@bool-completer
  --onUpgrade: string@bool-completer
  --onImportComplete: string@bool-completer
  --onRename: string@bool-completer
  --onSeriesAdd: string@bool-completer
  --onSeriesDelete: string@bool-completer
  --onEpisodeFileDelete: string@bool-completer
  --onEpisodeFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --onHealthRestored: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --onManualInteractionRequired: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnDownload: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnImportComplete: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnSeriesAdd: string@bool-completer
  --supportsOnSeriesDelete: string@bool-completer
  --supportsOnEpisodeFileDelete: string@bool-completer
  --supportsOnEpisodeFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --supportsOnHealthRestored: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --supportsOnManualInteractionRequired: string@bool-completer
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/notification/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onDownload: $onDownload, onUpgrade: $onUpgrade, onImportComplete: $onImportComplete, onRename: $onRename, onSeriesAdd: $onSeriesAdd, onSeriesDelete: $onSeriesDelete, onEpisodeFileDelete: $onEpisodeFileDelete, onEpisodeFileDeleteForUpgrade: $onEpisodeFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, includeHealthWarnings: $includeHealthWarnings, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, onManualInteractionRequired: $onManualInteractionRequired, supportsOnGrab: $supportsOnGrab, supportsOnDownload: $supportsOnDownload, supportsOnUpgrade: $supportsOnUpgrade, supportsOnImportComplete: $supportsOnImportComplete, supportsOnRename: $supportsOnRename, supportsOnSeriesAdd: $supportsOnSeriesAdd, supportsOnSeriesDelete: $supportsOnSeriesDelete, supportsOnEpisodeFileDelete: $supportsOnEpisodeFileDelete, supportsOnEpisodeFileDeleteForUpgrade: $supportsOnEpisodeFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, supportsOnManualInteractionRequired: $supportsOnManualInteractionRequired, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v3/notification/testall
export def "notification-testall post" [
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
  let full_url = (build-url $base "/api/v3/notification/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/notification/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
export def "notification-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onDownload?: bool, onUpgrade?: bool, onImportComplete?: bool, onRename?: bool, onSeriesAdd?: bool, onSeriesDelete?: bool, onEpisodeFileDelete?: bool, onEpisodeFileDeleteForUpgrade?: bool, onHealthIssue?: bool, includeHealthWarnings?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, onManualInteractionRequired?: bool, supportsOnGrab?: bool, supportsOnDownload?: bool, supportsOnUpgrade?: bool, supportsOnImportComplete?: bool, supportsOnRename?: bool, supportsOnSeriesAdd?: bool, supportsOnSeriesDelete?: bool, supportsOnEpisodeFileDelete?: bool, supportsOnEpisodeFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, supportsOnApplicationUpdate?: bool, supportsOnManualInteractionRequired?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onDownload: string@bool-completer
  --onUpgrade: string@bool-completer
  --onImportComplete: string@bool-completer
  --onRename: string@bool-completer
  --onSeriesAdd: string@bool-completer
  --onSeriesDelete: string@bool-completer
  --onEpisodeFileDelete: string@bool-completer
  --onEpisodeFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --onHealthRestored: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --onManualInteractionRequired: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnDownload: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnImportComplete: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnSeriesAdd: string@bool-completer
  --supportsOnSeriesDelete: string@bool-completer
  --supportsOnEpisodeFileDelete: string@bool-completer
  --supportsOnEpisodeFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --supportsOnHealthRestored: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --supportsOnManualInteractionRequired: string@bool-completer
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/notification/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onDownload: $onDownload, onUpgrade: $onUpgrade, onImportComplete: $onImportComplete, onRename: $onRename, onSeriesAdd: $onSeriesAdd, onSeriesDelete: $onSeriesDelete, onEpisodeFileDelete: $onEpisodeFileDelete, onEpisodeFileDeleteForUpgrade: $onEpisodeFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, includeHealthWarnings: $includeHealthWarnings, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, onManualInteractionRequired: $onManualInteractionRequired, supportsOnGrab: $supportsOnGrab, supportsOnDownload: $supportsOnDownload, supportsOnUpgrade: $supportsOnUpgrade, supportsOnImportComplete: $supportsOnImportComplete, supportsOnRename: $supportsOnRename, supportsOnSeriesAdd: $supportsOnSeriesAdd, supportsOnSeriesDelete: $supportsOnSeriesDelete, supportsOnEpisodeFileDelete: $supportsOnEpisodeFileDelete, supportsOnEpisodeFileDeleteForUpgrade: $supportsOnEpisodeFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, supportsOnManualInteractionRequired: $supportsOnManualInteractionRequired, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/parse
export def "parse get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --path: string
]: nothing -> record<id: int, title: string, parsedEpisodeInfo: record<releaseTitle: string, seriesTitle: string, seriesTitleInfo: record<title: string, titleWithoutYear: string, year: int, allTitles: list>, quality: record<quality: record, revision: record>, seasonNumber: int, episodeNumbers: list<int>, absoluteEpisodeNumbers: list<int>, specialAbsoluteEpisodeNumbers: list<float>, airDate: string, languages: list<record>, fullSeason: bool, isPartialSeason: bool, isMultiSeason: bool, isSeasonExtra: bool, isSplitEpisode: bool, isMiniSeries: bool, special: bool, releaseGroup: string, releaseHash: string, seasonPart: int, releaseTokens: string, dailyPart: int, isDaily: bool, isAbsoluteNumbering: bool, isPossibleSpecialEpisode: bool, isPossibleSceneSeasonSpecial: bool, releaseType: string>, series: record<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int>, episodes: table<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record, images: list>, languages: table<id: int, name: string>, customFormats: table<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: list>, customFormatScore: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/parse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /ping
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# HEAD /ping
export def "ping head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/qualitydefinition/{id}
#
# --quality shape: {id?: int, name?: string, source?: "unknown"|"television"|"televisionRaw"|"web"|"webRip"|"dvd"|"bluray"|"blurayRaw", resolution?: int}
export def "qualitydefinition put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --quality: record # shape: {id?: int, name?: string, source?: "unknown"|"television"|"televisionRaw"|"web"|"webRip"|"dvd"|"bluray"|"blurayRaw", resolution?: int}
  --title: string # nullable
  --weight: int # format: int32
  --minSize: float # nullable, format: double
  --maxSize: float # nullable, format: double
  --preferredSize: float # nullable, format: double
]: any -> record<id: int, quality: record<id: int, name: string, source: string, resolution: int>, title: string, weight: int, minSize: float, maxSize: float, preferredSize: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/qualitydefinition/($id)")
  let body = {id: $body_id, quality: $quality, title: $title, weight: $weight, minSize: $minSize, maxSize: $maxSize, preferredSize: $preferredSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/qualitydefinition/{id}
export def "qualitydefinition get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, quality: record<id: int, name: string, source: string, resolution: int>, title: string, weight: int, minSize: float, maxSize: float, preferredSize: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/qualitydefinition/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/qualitydefinition
export def "qualitydefinition list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, quality: record<id: int, name: string, source: string, resolution: int>, title: string, weight: int, minSize: float, maxSize: float, preferredSize: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/qualitydefinition")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/qualitydefinition/update
export def "qualitydefinition-update put" [
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
  let full_url = (build-url $base "/api/v3/qualitydefinition/update")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/qualitydefinition/limits
export def "qualitydefinition-limits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<min: int, max: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/qualitydefinition/limits")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/qualityprofile
#
# --items item shape: {id?: int, name?: string, quality?: record, items?: list, allowed?: bool}
# --formatItems item shape: {id?: int, format?: int, name?: string, score?: int}
export def "qualityprofile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name: string # nullable
  --upgradeAllowed: string@bool-completer
  --cutoff: int # format: int32
  --items: list # nullable — item shape: {id?: int, name?: string, quality?: record, items?: list, allowed?: bool}
  --minFormatScore: int # format: int32
  --cutoffFormatScore: int # format: int32
  --minUpgradeFormatScore: int # format: int32
  --formatItems: list # nullable — item shape: {id?: int, format?: int, name?: string, score?: int}
]: any -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, minUpgradeFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/qualityprofile")
  let body = {id: $id, name: $name, upgradeAllowed: $upgradeAllowed, cutoff: $cutoff, items: $items, minFormatScore: $minFormatScore, cutoffFormatScore: $cutoffFormatScore, minUpgradeFormatScore: $minUpgradeFormatScore, formatItems: $formatItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/qualityprofile
export def "qualityprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: list<record>, minFormatScore: int, cutoffFormatScore: int, minUpgradeFormatScore: int, formatItems: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/qualityprofile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/qualityprofile/{id}
export def "qualityprofile delete" [
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
  let full_url = (build-url $base $"/api/v3/qualityprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/qualityprofile/{id}
#
# --items item shape: {id?: int, name?: string, quality?: record, items?: list, allowed?: bool}
# --formatItems item shape: {id?: int, format?: int, name?: string, score?: int}
export def "qualityprofile put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --name: string # nullable
  --upgradeAllowed: string@bool-completer
  --cutoff: int # format: int32
  --items: list # nullable — item shape: {id?: int, name?: string, quality?: record, items?: list, allowed?: bool}
  --minFormatScore: int # format: int32
  --cutoffFormatScore: int # format: int32
  --minUpgradeFormatScore: int # format: int32
  --formatItems: list # nullable — item shape: {id?: int, format?: int, name?: string, score?: int}
]: any -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, minUpgradeFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/qualityprofile/($id)")
  let body = {id: $body_id, name: $name, upgradeAllowed: $upgradeAllowed, cutoff: $cutoff, items: $items, minFormatScore: $minFormatScore, cutoffFormatScore: $cutoffFormatScore, minUpgradeFormatScore: $minUpgradeFormatScore, formatItems: $formatItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/qualityprofile/{id}
export def "qualityprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, minUpgradeFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/qualityprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/qualityprofile/schema
export def "qualityprofile-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, minUpgradeFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/qualityprofile/schema")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/queue/{id}
export def "queue delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --removeFromClient: string@bool-completer # default: true
  --blocklist: string@bool-completer # default: false
  --skipRedownload: string@bool-completer # default: false
  --changeCategory: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeFromClient" $removeFromClient "scalar") (serialize-qp "blocklist" $blocklist "scalar") (serialize-qp "skipRedownload" $skipRedownload "scalar") (serialize-qp "changeCategory" $changeCategory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/queue/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/queue/bulk
export def "queue-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --removeFromClient: string@bool-completer # default: true
  --blocklist: string@bool-completer # default: false
  --skipRedownload: string@bool-completer # default: false
  --changeCategory: string@bool-completer # default: false
  --ids: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeFromClient" $removeFromClient "scalar") (serialize-qp "blocklist" $blocklist "scalar") (serialize-qp "skipRedownload" $skipRedownload "scalar") (serialize-qp "changeCategory" $changeCategory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/queue/bulk" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/queue
export def "queue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string
  --includeUnknownSeriesItems: string@bool-completer # default: false
  --includeSeries: string@bool-completer # default: false
  --includeEpisode: string@bool-completer # default: false
  --seriesIds: list
  --protocol: string
  --languages: list
  --quality: list
  --status: list
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, seriesId: int, episodeId: int, seasonNumber: int, series: record, episode: record, languages: list, quality: record, customFormats: list, customFormatScore: int, size: float, title: string, estimatedCompletionTime: string, added: string, status: string, trackedDownloadStatus: string, trackedDownloadState: string, statusMessages: list, errorMessage: string, downloadId: string, protocol: string, downloadClient: string, downloadClientHasPostImportCategory: bool, indexer: string, outputPath: string, episodeHasFile: bool, sizeleft: float, timeleft: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeUnknownSeriesItems" $includeUnknownSeriesItems "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisode" $includeEpisode "scalar") (serialize-qp "seriesIds" $seriesIds "multi") (serialize-qp "protocol" $protocol "scalar") (serialize-qp "languages" $languages "multi") (serialize-qp "quality" $quality "multi") (serialize-qp "status" $status "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/queue/grab/{id}
export def "queue-grab post" [
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
  let full_url = (build-url $base $"/api/v3/queue/grab/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/queue/grab/bulk
export def "queue-grab-bulk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queue/grab/bulk")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/queue/details
export def "queue-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesId: int # format: int32
  --episodeIds: list
  --includeSeries: string@bool-completer # default: false
  --includeEpisode: string@bool-completer # default: false
]: nothing -> table<id: int, seriesId: int, episodeId: int, seasonNumber: int, series: record<id: int, title: string, alternateTitles: list, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list, originalLanguage: record, remotePoster: string, seasons: list, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list, tags: list, added: string, addOptions: record, ratings: record, statistics: record, episodesChanged: bool, languageProfileId: int>, episode: record<id: int, seriesId: int, tvdbId: int, episodeFileId: int, seasonNumber: int, episodeNumber: int, title: string, airDate: string, airDateUtc: string, lastSearchTime: string, runtime: int, finaleType: string, overview: string, episodeFile: record, hasFile: bool, monitored: bool, absoluteEpisodeNumber: int, sceneAbsoluteEpisodeNumber: int, sceneEpisodeNumber: int, sceneSeasonNumber: int, unverifiedSceneNumbering: bool, endTime: string, grabDate: string, series: record, images: list>, languages: list<record>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, size: float, title: string, estimatedCompletionTime: string, added: string, status: string, trackedDownloadStatus: string, trackedDownloadState: string, statusMessages: list<record>, errorMessage: string, downloadId: string, protocol: string, downloadClient: string, downloadClientHasPostImportCategory: bool, indexer: string, outputPath: string, episodeHasFile: bool, sizeleft: float, timeleft: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "episodeIds" $episodeIds "multi") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "includeEpisode" $includeEpisode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/queue/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/queue/status
export def "queue-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, totalCount: int, count: int, unknownCount: int, errors: bool, warnings: bool, unknownErrors: bool, unknownWarnings: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/queue/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/release
#
# --quality shape: {quality?: record, revision?: record}
# --languages item shape: {id?: int, name?: string}
# --mappedEpisodeInfo item shape: {id?: int, seasonNumber?: int, episodeNumber?: int, absoluteEpisodeNumber?: int, title?: string}
# --customFormats item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
# --sceneMapping shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
export def "release post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --guid: string # nullable
  --quality: record # shape: {quality?: record, revision?: record}
  --qualityWeight: int # format: int32
  --age: int # format: int32
  --ageHours: float # format: double
  --ageMinutes: float # format: double
  --size: int # format: int64
  --indexerId: int # format: int32
  --indexer: string # nullable
  --releaseGroup: string # nullable
  --subGroup: string # nullable
  --releaseHash: string # nullable
  --title: string # nullable
  --fullSeason: string@bool-completer
  --sceneSource: string@bool-completer
  --seasonNumber: int # format: int32
  --languages: list # nullable — item shape: {id?: int, name?: string}
  --languageWeight: int # format: int32
  --airDate: string # nullable
  --seriesTitle: string # nullable
  --episodeNumbers: list # nullable
  --absoluteEpisodeNumbers: list # nullable
  --mappedSeasonNumber: int # nullable, format: int32
  --mappedEpisodeNumbers: list # nullable
  --mappedAbsoluteEpisodeNumbers: list # nullable
  --mappedSeriesId: int # nullable, format: int32
  --mappedEpisodeInfo: list # nullable — item shape: {id?: int, seasonNumber?: int, episodeNumber?: int, absoluteEpisodeNumber?: int, title?: string}
  --approved: string@bool-completer
  --temporarilyRejected: string@bool-completer
  --rejected: string@bool-completer
  --tvdbId: int # format: int32
  --tvRageId: int # format: int32
  --imdbId: string # nullable
  --rejections: list # nullable
  --publishDate: string # format: date-time
  --commentUrl: string # nullable
  --downloadUrl: string # nullable
  --infoUrl: string # nullable
  --episodeRequested: string@bool-completer
  --downloadAllowed: string@bool-completer
  --releaseWeight: int # format: int32
  --customFormats: list # nullable — item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
  --customFormatScore: int # format: int32
  --sceneMapping: record # shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
  --magnetUrl: string # nullable
  --infoHash: string # nullable
  --seeders: int # nullable, format: int32
  --leechers: int # nullable, format: int32
  --protocol: string@protocol-completer
  --indexerFlags: int # format: int32
  --isDaily: string@bool-completer
  --isAbsoluteNumbering: string@bool-completer
  --isPossibleSpecialEpisode: string@bool-completer
  --special: string@bool-completer
  --seriesId: int # nullable, format: int32
  --episodeId: int # nullable, format: int32
  --episodeIds: list # nullable
  --downloadClientId: int # nullable, format: int32
  --downloadClient: string # nullable
  --shouldOverride: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/release")
  let body = {id: $id, guid: $guid, quality: $quality, qualityWeight: $qualityWeight, age: $age, ageHours: $ageHours, ageMinutes: $ageMinutes, size: $size, indexerId: $indexerId, indexer: $indexer, releaseGroup: $releaseGroup, subGroup: $subGroup, releaseHash: $releaseHash, title: $title, fullSeason: $fullSeason, sceneSource: $sceneSource, seasonNumber: $seasonNumber, languages: $languages, languageWeight: $languageWeight, airDate: $airDate, seriesTitle: $seriesTitle, episodeNumbers: $episodeNumbers, absoluteEpisodeNumbers: $absoluteEpisodeNumbers, mappedSeasonNumber: $mappedSeasonNumber, mappedEpisodeNumbers: $mappedEpisodeNumbers, mappedAbsoluteEpisodeNumbers: $mappedAbsoluteEpisodeNumbers, mappedSeriesId: $mappedSeriesId, mappedEpisodeInfo: $mappedEpisodeInfo, approved: $approved, temporarilyRejected: $temporarilyRejected, rejected: $rejected, tvdbId: $tvdbId, tvRageId: $tvRageId, imdbId: $imdbId, rejections: $rejections, publishDate: $publishDate, commentUrl: $commentUrl, downloadUrl: $downloadUrl, infoUrl: $infoUrl, episodeRequested: $episodeRequested, downloadAllowed: $downloadAllowed, releaseWeight: $releaseWeight, customFormats: $customFormats, customFormatScore: $customFormatScore, sceneMapping: $sceneMapping, magnetUrl: $magnetUrl, infoHash: $infoHash, seeders: $seeders, leechers: $leechers, protocol: $protocol, indexerFlags: $indexerFlags, isDaily: $isDaily, isAbsoluteNumbering: $isAbsoluteNumbering, isPossibleSpecialEpisode: $isPossibleSpecialEpisode, special: $special, seriesId: $seriesId, episodeId: $episodeId, episodeIds: $episodeIds, downloadClientId: $downloadClientId, downloadClient: $downloadClient, shouldOverride: $shouldOverride} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/release
export def "release get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesId: int # format: int32
  --episodeId: int # format: int32
  --seasonNumber: int # format: int32
]: nothing -> table<id: int, guid: string, quality: record<quality: record, revision: record>, qualityWeight: int, age: int, ageHours: float, ageMinutes: float, size: int, indexerId: int, indexer: string, releaseGroup: string, subGroup: string, releaseHash: string, title: string, fullSeason: bool, sceneSource: bool, seasonNumber: int, languages: list<record>, languageWeight: int, airDate: string, seriesTitle: string, episodeNumbers: list<int>, absoluteEpisodeNumbers: list<int>, mappedSeasonNumber: int, mappedEpisodeNumbers: list<int>, mappedAbsoluteEpisodeNumbers: list<int>, mappedSeriesId: int, mappedEpisodeInfo: list<record>, approved: bool, temporarilyRejected: bool, rejected: bool, tvdbId: int, tvRageId: int, imdbId: string, rejections: list<string>, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, episodeRequested: bool, downloadAllowed: bool, releaseWeight: int, customFormats: list<record>, customFormatScore: int, sceneMapping: record<title: string, seasonNumber: int, sceneSeasonNumber: int, sceneOrigin: string, comment: string>, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, indexerFlags: int, isDaily: bool, isAbsoluteNumbering: bool, isPossibleSpecialEpisode: bool, special: bool, seriesId: int, episodeId: int, episodeIds: list<int>, downloadClientId: int, downloadClient: string, shouldOverride: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "episodeId" $episodeId "scalar") (serialize-qp "seasonNumber" $seasonNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/release" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/releaseprofile
export def "releaseprofile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name: string # nullable
  --enabled: string@bool-completer
  --required: any # nullable
  --ignored: any # nullable
  --indexerId: int # format: int32
  --tags: list # nullable
]: any -> record<id: int, name: string, enabled: bool, required: any, ignored: any, indexerId: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/releaseprofile")
  let body = {id: $id, name: $name, enabled: $enabled, required: $required, ignored: $ignored, indexerId: $indexerId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/releaseprofile
export def "releaseprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, enabled: bool, required: any, ignored: any, indexerId: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/releaseprofile")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/releaseprofile/{id}
export def "releaseprofile delete" [
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
  let full_url = (build-url $base $"/api/v3/releaseprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/releaseprofile/{id}
export def "releaseprofile put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --name: string # nullable
  --enabled: string@bool-completer
  --required: any # nullable
  --ignored: any # nullable
  --indexerId: int # format: int32
  --tags: list # nullable
]: any -> record<id: int, name: string, enabled: bool, required: any, ignored: any, indexerId: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/releaseprofile/($id)")
  let body = {id: $body_id, name: $name, enabled: $enabled, required: $required, ignored: $ignored, indexerId: $indexerId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/releaseprofile/{id}
export def "releaseprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, enabled: bool, required: any, ignored: any, indexerId: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/releaseprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/release/push
#
# --quality shape: {quality?: record, revision?: record}
# --languages item shape: {id?: int, name?: string}
# --mappedEpisodeInfo item shape: {id?: int, seasonNumber?: int, episodeNumber?: int, absoluteEpisodeNumber?: int, title?: string}
# --customFormats item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
# --sceneMapping shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
export def "release-push post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --guid: string # nullable
  --quality: record # shape: {quality?: record, revision?: record}
  --qualityWeight: int # format: int32
  --age: int # format: int32
  --ageHours: float # format: double
  --ageMinutes: float # format: double
  --size: int # format: int64
  --indexerId: int # format: int32
  --indexer: string # nullable
  --releaseGroup: string # nullable
  --subGroup: string # nullable
  --releaseHash: string # nullable
  --title: string # nullable
  --fullSeason: string@bool-completer
  --sceneSource: string@bool-completer
  --seasonNumber: int # format: int32
  --languages: list # nullable — item shape: {id?: int, name?: string}
  --languageWeight: int # format: int32
  --airDate: string # nullable
  --seriesTitle: string # nullable
  --episodeNumbers: list # nullable
  --absoluteEpisodeNumbers: list # nullable
  --mappedSeasonNumber: int # nullable, format: int32
  --mappedEpisodeNumbers: list # nullable
  --mappedAbsoluteEpisodeNumbers: list # nullable
  --mappedSeriesId: int # nullable, format: int32
  --mappedEpisodeInfo: list # nullable — item shape: {id?: int, seasonNumber?: int, episodeNumber?: int, absoluteEpisodeNumber?: int, title?: string}
  --approved: string@bool-completer
  --temporarilyRejected: string@bool-completer
  --rejected: string@bool-completer
  --tvdbId: int # format: int32
  --tvRageId: int # format: int32
  --imdbId: string # nullable
  --rejections: list # nullable
  --publishDate: string # format: date-time
  --commentUrl: string # nullable
  --downloadUrl: string # nullable
  --infoUrl: string # nullable
  --episodeRequested: string@bool-completer
  --downloadAllowed: string@bool-completer
  --releaseWeight: int # format: int32
  --customFormats: list # nullable — item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
  --customFormatScore: int # format: int32
  --sceneMapping: record # shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
  --magnetUrl: string # nullable
  --infoHash: string # nullable
  --seeders: int # nullable, format: int32
  --leechers: int # nullable, format: int32
  --protocol: string@protocol-completer
  --indexerFlags: int # format: int32
  --isDaily: string@bool-completer
  --isAbsoluteNumbering: string@bool-completer
  --isPossibleSpecialEpisode: string@bool-completer
  --special: string@bool-completer
  --seriesId: int # nullable, format: int32
  --episodeId: int # nullable, format: int32
  --episodeIds: list # nullable
  --downloadClientId: int # nullable, format: int32
  --downloadClient: string # nullable
  --shouldOverride: string@bool-completer # nullable
]: any -> table<id: int, guid: string, quality: record<quality: record, revision: record>, qualityWeight: int, age: int, ageHours: float, ageMinutes: float, size: int, indexerId: int, indexer: string, releaseGroup: string, subGroup: string, releaseHash: string, title: string, fullSeason: bool, sceneSource: bool, seasonNumber: int, languages: list<record>, languageWeight: int, airDate: string, seriesTitle: string, episodeNumbers: list<int>, absoluteEpisodeNumbers: list<int>, mappedSeasonNumber: int, mappedEpisodeNumbers: list<int>, mappedAbsoluteEpisodeNumbers: list<int>, mappedSeriesId: int, mappedEpisodeInfo: list<record>, approved: bool, temporarilyRejected: bool, rejected: bool, tvdbId: int, tvRageId: int, imdbId: string, rejections: list<string>, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, episodeRequested: bool, downloadAllowed: bool, releaseWeight: int, customFormats: list<record>, customFormatScore: int, sceneMapping: record<title: string, seasonNumber: int, sceneSeasonNumber: int, sceneOrigin: string, comment: string>, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, indexerFlags: int, isDaily: bool, isAbsoluteNumbering: bool, isPossibleSpecialEpisode: bool, special: bool, seriesId: int, episodeId: int, episodeIds: list<int>, downloadClientId: int, downloadClient: string, shouldOverride: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/release/push")
  let body = {id: $id, guid: $guid, quality: $quality, qualityWeight: $qualityWeight, age: $age, ageHours: $ageHours, ageMinutes: $ageMinutes, size: $size, indexerId: $indexerId, indexer: $indexer, releaseGroup: $releaseGroup, subGroup: $subGroup, releaseHash: $releaseHash, title: $title, fullSeason: $fullSeason, sceneSource: $sceneSource, seasonNumber: $seasonNumber, languages: $languages, languageWeight: $languageWeight, airDate: $airDate, seriesTitle: $seriesTitle, episodeNumbers: $episodeNumbers, absoluteEpisodeNumbers: $absoluteEpisodeNumbers, mappedSeasonNumber: $mappedSeasonNumber, mappedEpisodeNumbers: $mappedEpisodeNumbers, mappedAbsoluteEpisodeNumbers: $mappedAbsoluteEpisodeNumbers, mappedSeriesId: $mappedSeriesId, mappedEpisodeInfo: $mappedEpisodeInfo, approved: $approved, temporarilyRejected: $temporarilyRejected, rejected: $rejected, tvdbId: $tvdbId, tvRageId: $tvRageId, imdbId: $imdbId, rejections: $rejections, publishDate: $publishDate, commentUrl: $commentUrl, downloadUrl: $downloadUrl, infoUrl: $infoUrl, episodeRequested: $episodeRequested, downloadAllowed: $downloadAllowed, releaseWeight: $releaseWeight, customFormats: $customFormats, customFormatScore: $customFormatScore, sceneMapping: $sceneMapping, magnetUrl: $magnetUrl, infoHash: $infoHash, seeders: $seeders, leechers: $leechers, protocol: $protocol, indexerFlags: $indexerFlags, isDaily: $isDaily, isAbsoluteNumbering: $isAbsoluteNumbering, isPossibleSpecialEpisode: $isPossibleSpecialEpisode, special: $special, seriesId: $seriesId, episodeId: $episodeId, episodeIds: $episodeIds, downloadClientId: $downloadClientId, downloadClient: $downloadClient, shouldOverride: $shouldOverride} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v3/remotepathmapping
export def "remotepathmapping post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --host: string # nullable
  --remotePath: string # nullable
  --localPath: string # nullable
]: any -> record<id: int, host: string, remotePath: string, localPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/remotepathmapping")
  let body = {id: $id, host: $host, remotePath: $remotePath, localPath: $localPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/remotepathmapping
export def "remotepathmapping list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, host: string, remotePath: string, localPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/remotepathmapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/remotepathmapping/{id}
export def "remotepathmapping delete" [
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
  let full_url = (build-url $base $"/api/v3/remotepathmapping/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/remotepathmapping/{id}
export def "remotepathmapping put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --host: string # nullable
  --remotePath: string # nullable
  --localPath: string # nullable
]: any -> record<id: int, host: string, remotePath: string, localPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/remotepathmapping/($id)")
  let body = {id: $body_id, host: $host, remotePath: $remotePath, localPath: $localPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/remotepathmapping/{id}
export def "remotepathmapping get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, host: string, remotePath: string, localPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/remotepathmapping/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/rename
export def "rename get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesId: int # format: int32
  --seasonNumber: int # format: int32
]: nothing -> table<id: int, seriesId: int, seasonNumber: int, episodeNumbers: list<int>, episodeFileId: int, existingPath: string, newPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "seasonNumber" $seasonNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/rename" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/rootfolder
#
# --unmappedFolders item shape: {name?: string, path?: string, relativePath?: string}
export def "rootfolder post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --path: string # nullable
  --accessible: string@bool-completer
  --freeSpace: int # nullable, format: int64
  --unmappedFolders: list # nullable — item shape: {name?: string, path?: string, relativePath?: string}
]: any -> record<id: int, path: string, accessible: bool, freeSpace: int, unmappedFolders: table<name: string, path: string, relativePath: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/rootfolder")
  let body = {id: $id, path: $path, accessible: $accessible, freeSpace: $freeSpace, unmappedFolders: $unmappedFolders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/rootfolder
export def "rootfolder list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, path: string, accessible: bool, freeSpace: int, unmappedFolders: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/rootfolder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v3/rootfolder/{id}
export def "rootfolder delete" [
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
  let full_url = (build-url $base $"/api/v3/rootfolder/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/rootfolder/{id}
export def "rootfolder get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, path: string, accessible: bool, freeSpace: int, unmappedFolders: table<name: string, path: string, relativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/rootfolder/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/seasonpass
#
# --series item shape: {id?: int, monitored?: bool, seasons?: list}
# --monitoringOptions shape: {ignoreEpisodesWithFiles?: bool, ignoreEpisodesWithoutFiles?: bool, monitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip"}
export def "seasonpass post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --series: list # nullable — item shape: {id?: int, monitored?: bool, seasons?: list}
  --monitoringOptions: record # shape: {ignoreEpisodesWithFiles?: bool, ignoreEpisodesWithoutFiles?: bool, monitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/seasonpass")
  let body = {series: $series, monitoringOptions: $monitoringOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/series
export def "series list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tvdbId: int # format: int32
  --includeSeasonImages: string@bool-completer # default: false
]: nothing -> table<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tvdbId" $tvdbId "scalar") (serialize-qp "includeSeasonImages" $includeSeasonImages "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/series
#
# --alternateTitles item shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
# --images item shape: {coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"clearlogo", url?: string, remoteUrl?: string}
# --originalLanguage shape: {id?: int, name?: string}
# --seasons item shape: {seasonNumber?: int, monitored?: bool, statistics?: record, images?: list}
# --addOptions shape: {ignoreEpisodesWithFiles?: bool, ignoreEpisodesWithoutFiles?: bool, monitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", searchForMissingEpisodes?: bool, searchForCutoffUnmetEpisodes?: bool}
# --ratings shape: {votes?: int, value?: float}
# --statistics shape: {seasonCount?: int, episodeFileCount?: int, episodeCount?: int, totalEpisodeCount?: int, sizeOnDisk?: int, releaseGroups?: list}
export def "series post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --title: string # nullable
  --alternateTitles: list # nullable — item shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
  --sortTitle: string # nullable
  --status: string@status-completer-1
  --profileName: string # nullable
  --overview: string # nullable
  --nextAiring: string # nullable, format: date-time
  --previousAiring: string # nullable, format: date-time
  --network: string # nullable
  --airTime: string # nullable
  --images: list # nullable — item shape: {coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"clearlogo", url?: string, remoteUrl?: string}
  --originalLanguage: record # shape: {id?: int, name?: string}
  --remotePoster: string # nullable
  --seasons: list # nullable — item shape: {seasonNumber?: int, monitored?: bool, statistics?: record, images?: list}
  --year: int # format: int32
  --path: string # nullable
  --qualityProfileId: int # format: int32
  --seasonFolder: string@bool-completer
  --monitored: string@bool-completer
  --monitorNewItems: string@monitorNewItems-completer
  --useSceneNumbering: string@bool-completer
  --runtime: int # format: int32
  --tvdbId: int # format: int32
  --tvRageId: int # format: int32
  --tvMazeId: int # format: int32
  --tmdbId: int # format: int32
  --firstAired: string # nullable, format: date-time
  --lastAired: string # nullable, format: date-time
  --seriesType: string@seriesType-completer
  --cleanTitle: string # nullable
  --imdbId: string # nullable
  --titleSlug: string # nullable
  --rootFolderPath: string # nullable
  --folder: string # nullable
  --certification: string # nullable
  --genres: list # nullable
  --tags: list # nullable
  --added: string # format: date-time
  --addOptions: record # shape: {ignoreEpisodesWithFiles?: bool, ignoreEpisodesWithoutFiles?: bool, monitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", searchForMissingEpisodes?: bool, searchForCutoffUnmetEpisodes?: bool}
  --ratings: record # shape: {votes?: int, value?: float}
  --statistics: record # shape: {seasonCount?: int, episodeFileCount?: int, episodeCount?: int, totalEpisodeCount?: int, sizeOnDisk?: int, releaseGroups?: list}
  --episodesChanged: string@bool-completer # nullable
]: any -> record<id: int, title: string, alternateTitles: table<title: string, seasonNumber: int, sceneSeasonNumber: int, sceneOrigin: string, comment: string>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: table<coverType: string, url: string, remoteUrl: string>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: table<seasonNumber: int, monitored: bool, statistics: record, images: list>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list<string>, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/series")
  let body = {id: $id, title: $title, alternateTitles: $alternateTitles, sortTitle: $sortTitle, status: $status, profileName: $profileName, overview: $overview, nextAiring: $nextAiring, previousAiring: $previousAiring, network: $network, airTime: $airTime, images: $images, originalLanguage: $originalLanguage, remotePoster: $remotePoster, seasons: $seasons, year: $year, path: $path, qualityProfileId: $qualityProfileId, seasonFolder: $seasonFolder, monitored: $monitored, monitorNewItems: $monitorNewItems, useSceneNumbering: $useSceneNumbering, runtime: $runtime, tvdbId: $tvdbId, tvRageId: $tvRageId, tvMazeId: $tvMazeId, tmdbId: $tmdbId, firstAired: $firstAired, lastAired: $lastAired, seriesType: $seriesType, cleanTitle: $cleanTitle, imdbId: $imdbId, titleSlug: $titleSlug, rootFolderPath: $rootFolderPath, folder: $folder, certification: $certification, genres: $genres, tags: $tags, added: $added, addOptions: $addOptions, ratings: $ratings, statistics: $statistics, episodesChanged: $episodesChanged} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/series/{id}
export def "series get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeSeasonImages: string@bool-completer # default: false
]: nothing -> record<id: int, title: string, alternateTitles: table<title: string, seasonNumber: int, sceneSeasonNumber: int, sceneOrigin: string, comment: string>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: table<coverType: string, url: string, remoteUrl: string>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: table<seasonNumber: int, monitored: bool, statistics: record, images: list>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list<string>, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeSeasonImages" $includeSeasonImages "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/series/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/series/{id}
#
# --alternateTitles item shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
# --images item shape: {coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"clearlogo", url?: string, remoteUrl?: string}
# --originalLanguage shape: {id?: int, name?: string}
# --seasons item shape: {seasonNumber?: int, monitored?: bool, statistics?: record, images?: list}
# --addOptions shape: {ignoreEpisodesWithFiles?: bool, ignoreEpisodesWithoutFiles?: bool, monitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", searchForMissingEpisodes?: bool, searchForCutoffUnmetEpisodes?: bool}
# --ratings shape: {votes?: int, value?: float}
# --statistics shape: {seasonCount?: int, episodeFileCount?: int, episodeCount?: int, totalEpisodeCount?: int, sizeOnDisk?: int, releaseGroups?: list}
export def "series put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --moveFiles: string@bool-completer # default: false
  --body-id: int # format: int32
  --title: string # nullable
  --alternateTitles: list # nullable — item shape: {title?: string, seasonNumber?: int, sceneSeasonNumber?: int, sceneOrigin?: string, comment?: string}
  --sortTitle: string # nullable
  --status: string@status-completer-1
  --profileName: string # nullable
  --overview: string # nullable
  --nextAiring: string # nullable, format: date-time
  --previousAiring: string # nullable, format: date-time
  --network: string # nullable
  --airTime: string # nullable
  --images: list # nullable — item shape: {coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"clearlogo", url?: string, remoteUrl?: string}
  --originalLanguage: record # shape: {id?: int, name?: string}
  --remotePoster: string # nullable
  --seasons: list # nullable — item shape: {seasonNumber?: int, monitored?: bool, statistics?: record, images?: list}
  --year: int # format: int32
  --path: string # nullable
  --qualityProfileId: int # format: int32
  --seasonFolder: string@bool-completer
  --monitored: string@bool-completer
  --monitorNewItems: string@monitorNewItems-completer
  --useSceneNumbering: string@bool-completer
  --runtime: int # format: int32
  --tvdbId: int # format: int32
  --tvRageId: int # format: int32
  --tvMazeId: int # format: int32
  --tmdbId: int # format: int32
  --firstAired: string # nullable, format: date-time
  --lastAired: string # nullable, format: date-time
  --seriesType: string@seriesType-completer
  --cleanTitle: string # nullable
  --imdbId: string # nullable
  --titleSlug: string # nullable
  --rootFolderPath: string # nullable
  --folder: string # nullable
  --certification: string # nullable
  --genres: list # nullable
  --tags: list # nullable
  --added: string # format: date-time
  --addOptions: record # shape: {ignoreEpisodesWithFiles?: bool, ignoreEpisodesWithoutFiles?: bool, monitor?: "unknown"|"all"|"future"|"missing"|"existing"|"firstSeason"|"lastSeason"|"latestSeason"|"pilot"|"recent"|"monitorSpecials"|"unmonitorSpecials"|"none"|"skip", searchForMissingEpisodes?: bool, searchForCutoffUnmetEpisodes?: bool}
  --ratings: record # shape: {votes?: int, value?: float}
  --statistics: record # shape: {seasonCount?: int, episodeFileCount?: int, episodeCount?: int, totalEpisodeCount?: int, sizeOnDisk?: int, releaseGroups?: list}
  --episodesChanged: string@bool-completer # nullable
]: any -> record<id: int, title: string, alternateTitles: table<title: string, seasonNumber: int, sceneSeasonNumber: int, sceneOrigin: string, comment: string>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: table<coverType: string, url: string, remoteUrl: string>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: table<seasonNumber: int, monitored: bool, statistics: record, images: list>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list<string>, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moveFiles" $moveFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/series/($id)" $qp)
  let body = {id: $body_id, title: $title, alternateTitles: $alternateTitles, sortTitle: $sortTitle, status: $status, profileName: $profileName, overview: $overview, nextAiring: $nextAiring, previousAiring: $previousAiring, network: $network, airTime: $airTime, images: $images, originalLanguage: $originalLanguage, remotePoster: $remotePoster, seasons: $seasons, year: $year, path: $path, qualityProfileId: $qualityProfileId, seasonFolder: $seasonFolder, monitored: $monitored, monitorNewItems: $monitorNewItems, useSceneNumbering: $useSceneNumbering, runtime: $runtime, tvdbId: $tvdbId, tvRageId: $tvRageId, tvMazeId: $tvMazeId, tmdbId: $tmdbId, firstAired: $firstAired, lastAired: $lastAired, seriesType: $seriesType, cleanTitle: $cleanTitle, imdbId: $imdbId, titleSlug: $titleSlug, rootFolderPath: $rootFolderPath, folder: $folder, certification: $certification, genres: $genres, tags: $tags, added: $added, addOptions: $addOptions, ratings: $ratings, statistics: $statistics, episodesChanged: $episodesChanged} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/series/{id}
export def "series delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteFiles: string@bool-completer # default: false
  --addImportListExclusion: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteFiles" $deleteFiles "scalar") (serialize-qp "addImportListExclusion" $addImportListExclusion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v3/series/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/series/editor
export def "series-editor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesIds: list # nullable
  --monitored: string@bool-completer # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # nullable, format: int32
  --seriesType: string@seriesType-completer
  --seasonFolder: string@bool-completer # nullable
  --rootFolderPath: string # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --moveFiles: string@bool-completer
  --deleteFiles: string@bool-completer
  --addImportListExclusion: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/series/editor")
  let body = {seriesIds: $seriesIds, monitored: $monitored, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, seriesType: $seriesType, seasonFolder: $seasonFolder, rootFolderPath: $rootFolderPath, tags: $tags, applyTags: $applyTags, moveFiles: $moveFiles, deleteFiles: $deleteFiles, addImportListExclusion: $addImportListExclusion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/series/editor
export def "series-editor delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seriesIds: list # nullable
  --monitored: string@bool-completer # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # nullable, format: int32
  --seriesType: string@seriesType-completer
  --seasonFolder: string@bool-completer # nullable
  --rootFolderPath: string # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --moveFiles: string@bool-completer
  --deleteFiles: string@bool-completer
  --addImportListExclusion: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/series/editor")
  let body = {seriesIds: $seriesIds, monitored: $monitored, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, seriesType: $seriesType, seasonFolder: $seasonFolder, rootFolderPath: $rootFolderPath, tags: $tags, applyTags: $applyTags, moveFiles: $moveFiles, deleteFiles: $deleteFiles, addImportListExclusion: $addImportListExclusion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/series/{id}/folder
export def "series-folder get" [
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
  let full_url = (build-url $base $"/api/v3/series/($id)/folder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/series/import
export def "series-import post" [
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
  let full_url = (build-url $base "/api/v3/series/import")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/series/lookup
export def "series-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --term: string
]: nothing -> table<id: int, title: string, alternateTitles: list<record>, sortTitle: string, status: string, ended: bool, profileName: string, overview: string, nextAiring: string, previousAiring: string, network: string, airTime: string, images: list<record>, originalLanguage: record<id: int, name: string>, remotePoster: string, seasons: list<record>, year: int, path: string, qualityProfileId: int, seasonFolder: bool, monitored: bool, monitorNewItems: string, useSceneNumbering: bool, runtime: int, tvdbId: int, tvRageId: int, tvMazeId: int, tmdbId: int, firstAired: string, lastAired: string, seriesType: string, cleanTitle: string, imdbId: string, titleSlug: string, rootFolderPath: string, folder: string, certification: string, genres: list<string>, tags: list<int>, added: string, addOptions: record<ignoreEpisodesWithFiles: bool, ignoreEpisodesWithoutFiles: bool, monitor: string, searchForMissingEpisodes: bool, searchForCutoffUnmetEpisodes: bool>, ratings: record<votes: int, value: float>, statistics: record<seasonCount: int, episodeFileCount: int, episodeCount: int, totalEpisodeCount: int, sizeOnDisk: int, releaseGroups: list, percentOfEpisodes: float>, episodesChanged: bool, languageProfileId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/series/lookup" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /content/{path}
export def "content get" [
  path: string
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
  let full_url = (build-url $base $"/content/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /
export def "static-resource get-by-path" [
  path: string
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
  let full_url = (build-url $base $"/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /{path}
export def "static-resource get-by-path-1" [
  path: string
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
  let full_url = (build-url $base $"/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/system/status
export def "system-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appName: string, instanceName: string, version: string, buildTime: string, isDebug: bool, isProduction: bool, isAdmin: bool, isUserInteractive: bool, startupPath: string, appData: string, osName: string, osVersion: string, isNetCore: bool, isLinux: bool, isOsx: bool, isWindows: bool, isDocker: bool, mode: string, branch: string, authentication: string, sqliteVersion: string, migrationVersion: int, urlBase: string, runtimeVersion: string, runtimeName: string, startTime: string, packageVersion: string, packageAuthor: string, packageUpdateMechanism: string, packageUpdateMechanismMessage: string, databaseVersion: string, databaseType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/system/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/system/routes
export def "system-routes get" [
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
  let full_url = (build-url $base "/api/v3/system/routes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/system/routes/duplicate
export def "system-routes-duplicate get" [
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
  let full_url = (build-url $base "/api/v3/system/routes/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/system/shutdown
export def "system-shutdown post" [
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
  let full_url = (build-url $base "/api/v3/system/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/system/restart
export def "system-restart post" [
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
  let full_url = (build-url $base "/api/v3/system/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/tag
export def "tag list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/tag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v3/tag
export def "tag post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --label: string # nullable
]: any -> record<id: int, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/tag")
  let body = {id: $id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v3/tag/{id}
export def "tag put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --label: string # nullable
]: any -> record<id: int, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/tag/($id)")
  let body = {id: $body_id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v3/tag/{id}
export def "tag delete" [
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
  let full_url = (build-url $base $"/api/v3/tag/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/tag/{id}
export def "tag get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/tag/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/tag/detail
export def "tag-detail list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, label: string, delayProfileIds: list<int>, importListIds: list<int>, notificationIds: list<int>, restrictionIds: list<int>, indexerIds: list<int>, downloadClientIds: list<int>, autoTagIds: list<int>, seriesIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/tag/detail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/tag/detail/{id}
export def "tag-detail get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, label: string, delayProfileIds: list<int>, importListIds: list<int>, notificationIds: list<int>, restrictionIds: list<int>, indexerIds: list<int>, downloadClientIds: list<int>, autoTagIds: list<int>, seriesIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/tag/detail/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/system/task
export def "system-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, taskName: string, interval: int, lastExecution: string, lastStartTime: string, nextExecution: string, lastDuration: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/system/task")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/system/task/{id}
export def "system-task get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, taskName: string, interval: int, lastExecution: string, lastStartTime: string, nextExecution: string, lastDuration: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/system/task/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v3/config/ui/{id}
export def "config-ui put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int32
  --firstDayOfWeek: int # format: int32
  --calendarWeekColumnHeader: string # nullable
  --shortDateFormat: string # nullable
  --longDateFormat: string # nullable
  --timeFormat: string # nullable
  --showRelativeDates: string@bool-completer
  --enableColorImpairedMode: string@bool-completer
  --theme: string # nullable
  --uiLanguage: int # format: int32
]: any -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, theme: string, uiLanguage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/ui/($id)")
  let body = {id: $body_id, firstDayOfWeek: $firstDayOfWeek, calendarWeekColumnHeader: $calendarWeekColumnHeader, shortDateFormat: $shortDateFormat, longDateFormat: $longDateFormat, timeFormat: $timeFormat, showRelativeDates: $showRelativeDates, enableColorImpairedMode: $enableColorImpairedMode, theme: $theme, uiLanguage: $uiLanguage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v3/config/ui/{id}
export def "config-ui get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, theme: string, uiLanguage: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/config/ui/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/config/ui
export def "config-ui list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, theme: string, uiLanguage: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/config/ui")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/update
export def "update get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, version: string, branch: string, releaseDate: string, fileName: string, url: string, installed: bool, installedOn: string, installable: bool, latest: bool, changes: record<new: list, fixed: list>, hash: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/log/file/update
export def "log-file-update list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, filename: string, lastWriteTime: string, contentsUrl: string, downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/log/file/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v3/log/file/update/{filename}
export def "log-file-update get" [
  filename: string
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
  let full_url = (build-url $base $"/api/v3/log/file/update/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
