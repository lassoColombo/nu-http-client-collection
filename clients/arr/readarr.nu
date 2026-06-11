# Auto-generated client for Readarr v1.0.0
# Source: https://raw.githubusercontent.com/Readarr/Readarr/develop/src/Readarr.Api.V1/openapi.json
# Auth: --token flag or $env.READARR_TOKEN

const BASE_URL = "http://localhost:8787"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o READARR_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost:8787" "https://localhost:8787"] }
def auth-scheme-completer [] { ["x-api-key" "query-apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def status-completer [] { ["continuing" "ended"] }
def monitorNewItems-completer [] { ["all" "new" "none"] }
def applyTags-completer [] { ["add" "remove" "replace"] }
def sortDirection-completer [] { ["ascending" "default" "descending"] }
def priority-completer [] { ["high" "low" "normal"] }
def status-completer-1 [] { ["aborted" "cancelled" "completed" "failed" "orphaned" "queued" "started"] }
def result-completer [] { ["successful" "unknown" "unsuccessful"] }
def trigger-completer [] { ["manual" "scheduled" "unspecified"] }
def preferredProtocol-completer [] { ["torrent" "unknown" "usenet"] }
def protocol-completer [] { ["torrent" "unknown" "usenet"] }
def eventType-completer [] { ["bookFileDeleted" "bookFileImported" "bookFileRenamed" "bookFileRetagged" "bookImportIncomplete" "downloadFailed" "downloadIgnored" "downloadImported" "grabbed" "unknown"] }
def authenticationMethod-completer [] { ["basic" "external" "forms" "none"] }
def authenticationRequired-completer [] { ["disabledForLocalAddresses" "enabled"] }
def updateMechanism-completer [] { ["apt" "builtIn" "docker" "external" "script"] }
def proxyType-completer [] { ["http" "socks4" "socks5"] }
def certificateValidation-completer [] { ["disabled" "disabledForLocalAddresses" "enabled"] }
def shouldMonitor-completer [] { ["entireAuthor" "none" "specificBook"] }
def listType-completer [] { ["goodreads" "other" "program"] }
def downloadPropersAndRepacks-completer [] { ["doNotPrefer" "doNotUpgrade" "preferAndUpgrade"] }
def fileDate-completer [] { ["bookReleaseDate" "none"] }
def rescanAfterRefresh-completer [] { ["afterManual" "always" "never"] }
def allowFingerprinting-completer [] { ["allFiles" "never" "newFiles"] }
def writeAudioTags-completer [] { ["allFiles" "newFiles" "no" "sync"] }
def writeBookTags-completer [] { ["allFiles" "newFiles" "sync"] }
def defaultMonitorOption-completer [] { ["all" "existing" "first" "future" "latest" "missing" "none" "unknown"] }
def defaultNewItemMonitorOption-completer [] { ["all" "new" "none"] }

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
]: nothing -> record<current: string, deprecated: list<string>> {
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

# GET /api/v1/author
export def "author list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/author")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/author
#
# --links item shape: {url?: string, name?: string}
# --nextBook shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
# --lastBook shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
# --images item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
# --addOptions shape: {monitor?: "all"|"future"|"missing"|"existing"|"latest"|"first"|"none"|"unknown", booksToMonitor?: list, monitored?: bool, searchForMissingBooks?: bool}
# --ratings shape: {votes?: int, value?: float}
# --statistics shape: {bookFileCount?: int, bookCount?: int, availableBookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
export def "author post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --authorMetadataId: int # format: int32
  --status: string@status-completer
  --authorName: string # nullable
  --authorNameLastFirst: string # nullable
  --foreignAuthorId: string # nullable
  --titleSlug: string # nullable
  --overview: string # nullable
  --disambiguation: string # nullable
  --links: list # nullable — item shape: {url?: string, name?: string}
  --nextBook: record # shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
  --lastBook: record # shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
  --images: list # nullable — item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
  --remotePoster: string # nullable
  --path: string # nullable
  --qualityProfileId: int # format: int32
  --metadataProfileId: int # format: int32
  --monitored: string@bool-completer
  --monitorNewItems: string@monitorNewItems-completer
  --rootFolderPath: string # nullable
  --folder: string # nullable
  --genres: list # nullable
  --cleanName: string # nullable
  --sortName: string # nullable
  --sortNameLastFirst: string # nullable
  --tags: list # nullable
  --added: string # format: date-time
  --addOptions: record # shape: {monitor?: "all"|"future"|"missing"|"existing"|"latest"|"first"|"none"|"unknown", booksToMonitor?: list, monitored?: bool, searchForMissingBooks?: bool}
  --ratings: record # shape: {votes?: int, value?: float}
  --statistics: record # shape: {bookFileCount?: int, bookCount?: int, availableBookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
]: any -> record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: table<url: string, name: string>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list<record>, genres: list<string>, relatedBooks: list<int>, ratings: record<votes: int, value: float, popularity: float>, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record<addType: string, searchForNewBook: bool>, authorMetadata: record<value: record, isLoaded: bool>, author: record<value: record, isLoaded: bool>, editions: record<value: list, isLoaded: bool>, bookFiles: record<value: list, isLoaded: bool>, seriesLinks: record<value: list, isLoaded: bool>>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list<record>, genres: list<string>, relatedBooks: list<int>, ratings: record<votes: int, value: float, popularity: float>, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record<addType: string, searchForNewBook: bool>, authorMetadata: record<value: record, isLoaded: bool>, author: record<value: record, isLoaded: bool>, editions: record<value: list, isLoaded: bool>, bookFiles: record<value: list, isLoaded: bool>, seriesLinks: record<value: list, isLoaded: bool>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list<string>, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/author")
  let body = {id: $id, authorMetadataId: $authorMetadataId, status: $status, authorName: $authorName, authorNameLastFirst: $authorNameLastFirst, foreignAuthorId: $foreignAuthorId, titleSlug: $titleSlug, overview: $overview, disambiguation: $disambiguation, links: $links, nextBook: $nextBook, lastBook: $lastBook, images: $images, remotePoster: $remotePoster, path: $path, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, monitored: $monitored, monitorNewItems: $monitorNewItems, rootFolderPath: $rootFolderPath, folder: $folder, genres: $genres, cleanName: $cleanName, sortName: $sortName, sortNameLastFirst: $sortNameLastFirst, tags: $tags, added: $added, addOptions: $addOptions, ratings: $ratings, statistics: $statistics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/author/{id}
#
# --links item shape: {url?: string, name?: string}
# --nextBook shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
# --lastBook shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
# --images item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
# --addOptions shape: {monitor?: "all"|"future"|"missing"|"existing"|"latest"|"first"|"none"|"unknown", booksToMonitor?: list, monitored?: bool, searchForMissingBooks?: bool}
# --ratings shape: {votes?: int, value?: float}
# --statistics shape: {bookFileCount?: int, bookCount?: int, availableBookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
export def "author put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --moveFiles: string@bool-completer # default: false
  --body-id: int # format: int32
  --authorMetadataId: int # format: int32
  --status: string@status-completer
  --authorName: string # nullable
  --authorNameLastFirst: string # nullable
  --foreignAuthorId: string # nullable
  --titleSlug: string # nullable
  --overview: string # nullable
  --disambiguation: string # nullable
  --links: list # nullable — item shape: {url?: string, name?: string}
  --nextBook: record # shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
  --lastBook: record # shape: {id?: int, authorMetadataId?: int, foreignBookId?: string, foreignEditionId?: string, titleSlug?: string, title?: string, releaseDate?: string, links?: list, genres?: list, relatedBooks?: list, ratings?: record, lastSearchTime?: string, cleanTitle?: string, monitored?: bool, anyEditionOk?: bool, lastInfoSync?: string, added?: string, addOptions?: record, authorMetadata?: record, author?: record, editions?: record, bookFiles?: record, seriesLinks?: record}
  --images: list # nullable — item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
  --remotePoster: string # nullable
  --path: string # nullable
  --qualityProfileId: int # format: int32
  --metadataProfileId: int # format: int32
  --monitored: string@bool-completer
  --monitorNewItems: string@monitorNewItems-completer
  --rootFolderPath: string # nullable
  --folder: string # nullable
  --genres: list # nullable
  --cleanName: string # nullable
  --sortName: string # nullable
  --sortNameLastFirst: string # nullable
  --tags: list # nullable
  --added: string # format: date-time
  --addOptions: record # shape: {monitor?: "all"|"future"|"missing"|"existing"|"latest"|"first"|"none"|"unknown", booksToMonitor?: list, monitored?: bool, searchForMissingBooks?: bool}
  --ratings: record # shape: {votes?: int, value?: float}
  --statistics: record # shape: {bookFileCount?: int, bookCount?: int, availableBookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
]: any -> record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: table<url: string, name: string>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list<record>, genres: list<string>, relatedBooks: list<int>, ratings: record<votes: int, value: float, popularity: float>, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record<addType: string, searchForNewBook: bool>, authorMetadata: record<value: record, isLoaded: bool>, author: record<value: record, isLoaded: bool>, editions: record<value: list, isLoaded: bool>, bookFiles: record<value: list, isLoaded: bool>, seriesLinks: record<value: list, isLoaded: bool>>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list<record>, genres: list<string>, relatedBooks: list<int>, ratings: record<votes: int, value: float, popularity: float>, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record<addType: string, searchForNewBook: bool>, authorMetadata: record<value: record, isLoaded: bool>, author: record<value: record, isLoaded: bool>, editions: record<value: list, isLoaded: bool>, bookFiles: record<value: list, isLoaded: bool>, seriesLinks: record<value: list, isLoaded: bool>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list<string>, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "moveFiles" $moveFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/author/($id)" $qp)
  let body = {id: $body_id, authorMetadataId: $authorMetadataId, status: $status, authorName: $authorName, authorNameLastFirst: $authorNameLastFirst, foreignAuthorId: $foreignAuthorId, titleSlug: $titleSlug, overview: $overview, disambiguation: $disambiguation, links: $links, nextBook: $nextBook, lastBook: $lastBook, images: $images, remotePoster: $remotePoster, path: $path, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, monitored: $monitored, monitorNewItems: $monitorNewItems, rootFolderPath: $rootFolderPath, folder: $folder, genres: $genres, cleanName: $cleanName, sortName: $sortName, sortNameLastFirst: $sortNameLastFirst, tags: $tags, added: $added, addOptions: $addOptions, ratings: $ratings, statistics: $statistics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/author/{id}
export def "author delete" [
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
  let full_url = (build-url $base $"/api/v1/author/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/author/{id}
export def "author get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: table<url: string, name: string>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list<record>, genres: list<string>, relatedBooks: list<int>, ratings: record<votes: int, value: float, popularity: float>, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record<addType: string, searchForNewBook: bool>, authorMetadata: record<value: record, isLoaded: bool>, author: record<value: record, isLoaded: bool>, editions: record<value: list, isLoaded: bool>, bookFiles: record<value: list, isLoaded: bool>, seriesLinks: record<value: list, isLoaded: bool>>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list<record>, genres: list<string>, relatedBooks: list<int>, ratings: record<votes: int, value: float, popularity: float>, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record<addType: string, searchForNewBook: bool>, authorMetadata: record<value: record, isLoaded: bool>, author: record<value: record, isLoaded: bool>, editions: record<value: list, isLoaded: bool>, bookFiles: record<value: list, isLoaded: bool>, seriesLinks: record<value: list, isLoaded: bool>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list<string>, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/author/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/author/editor
export def "author-editor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorIds: list # nullable
  --monitored: string@bool-completer # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # nullable, format: int32
  --metadataProfileId: int # nullable, format: int32
  --rootFolderPath: string # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --moveFiles: string@bool-completer
  --deleteFiles: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/author/editor")
  let body = {authorIds: $authorIds, monitored: $monitored, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, rootFolderPath: $rootFolderPath, tags: $tags, applyTags: $applyTags, moveFiles: $moveFiles, deleteFiles: $deleteFiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/author/editor
export def "author-editor delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorIds: list # nullable
  --monitored: string@bool-completer # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # nullable, format: int32
  --metadataProfileId: int # nullable, format: int32
  --rootFolderPath: string # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --moveFiles: string@bool-completer
  --deleteFiles: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/author/editor")
  let body = {authorIds: $authorIds, monitored: $monitored, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, rootFolderPath: $rootFolderPath, tags: $tags, applyTags: $applyTags, moveFiles: $moveFiles, deleteFiles: $deleteFiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/author/lookup
export def "author-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/author/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/backup
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
  let full_url = (build-url $base "/api/v1/system/backup")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/system/backup/{id}
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
  let full_url = (build-url $base $"/api/v1/system/backup/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/backup/restore/{id}
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
  let full_url = (build-url $base $"/api/v1/system/backup/restore/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/backup/restore/upload
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
  let full_url = (build-url $base "/api/v1/system/backup/restore/upload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/blocklist
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
  --sortDirection: string@sortDirection-completer
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, authorId: int, bookIds: list, sourceTitle: string, quality: record, customFormats: list, date: string, protocol: string, indexer: string, message: string, author: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/blocklist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/blocklist/{id}
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
  let full_url = (build-url $base $"/api/v1/blocklist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/blocklist/bulk
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
  let full_url = (build-url $base "/api/v1/blocklist/bulk")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/book
export def "book list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
  --bookIds: list
  --titleSlug: string
  --includeAllAuthorBooks: string@bool-completer # default: false
]: nothing -> table<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list, nextBook: record, lastBook: record, images: list, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list, added: string, addOptions: record, ratings: record, statistics: record>, images: list<record>, links: list<record>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar") (serialize-qp "bookIds" $bookIds "multi") (serialize-qp "titleSlug" $titleSlug "scalar") (serialize-qp "includeAllAuthorBooks" $includeAllAuthorBooks "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/book" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/book
#
# --ratings shape: {votes?: int, value?: float}
# --author shape: {id?: int, authorMetadataId?: int, status?: "continuing"|"ended", authorName?: string, authorNameLastFirst?: string, foreignAuthorId?: string, titleSlug?: string, overview?: string, disambiguation?: string, links?: list, nextBook?: record, lastBook?: record, images?: list, remotePoster?: string, path?: string, qualityProfileId?: int, metadataProfileId?: int, monitored?: bool, monitorNewItems?: "all"|"none"|"new", rootFolderPath?: string, folder?: string, genres?: list, cleanName?: string, sortName?: string, sortNameLastFirst?: string, tags?: list, added?: string, addOptions?: record, ratings?: record, statistics?: record}
# --images item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
# --links item shape: {url?: string, name?: string}
# --statistics shape: {bookFileCount?: int, bookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
# --addOptions shape: {addType?: "automatic"|"manual", searchForNewBook?: bool}
# --editions item shape: {id?: int, bookId?: int, foreignEditionId?: string, titleSlug?: string, isbn13?: string, asin?: string, title?: string, language?: string, overview?: string, format?: string, isEbook?: bool, disambiguation?: string, publisher?: string, pageCount?: int, releaseDate?: string, images?: list, links?: list, ratings?: record, monitored?: bool, manualAdd?: bool, remoteCover?: string}
export def "book post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --title: string # nullable
  --authorTitle: string # nullable
  --seriesTitle: string # nullable
  --disambiguation: string # nullable
  --overview: string # nullable
  --authorId: int # format: int32
  --foreignBookId: string # nullable
  --foreignEditionId: string # nullable
  --titleSlug: string # nullable
  --monitored: string@bool-completer
  --anyEditionOk: string@bool-completer
  --ratings: record # shape: {votes?: int, value?: float}
  --releaseDate: string # nullable, format: date-time
  --pageCount: int # format: int32
  --genres: list # nullable
  --author: record # shape: {id?: int, authorMetadataId?: int, status?: "continuing"|"ended", authorName?: string, authorNameLastFirst?: string, foreignAuthorId?: string, titleSlug?: string, overview?: string, disambiguation?: string, links?: list, nextBook?: record, lastBook?: record, images?: list, remotePoster?: string, path?: string, qualityProfileId?: int, metadataProfileId?: int, monitored?: bool, monitorNewItems?: "all"|"none"|"new", rootFolderPath?: string, folder?: string, genres?: list, cleanName?: string, sortName?: string, sortNameLastFirst?: string, tags?: list, added?: string, addOptions?: record, ratings?: record, statistics?: record}
  --images: list # nullable — item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
  --links: list # nullable — item shape: {url?: string, name?: string}
  --statistics: record # shape: {bookFileCount?: int, bookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
  --added: string # nullable, format: date-time
  --addOptions: record # shape: {addType?: "automatic"|"manual", searchForNewBook?: bool}
  --remoteCover: string # nullable
  --lastSearchTime: string # nullable, format: date-time
  --editions: list # nullable — item shape: {id?: int, bookId?: int, foreignEditionId?: string, titleSlug?: string, isbn13?: string, asin?: string, title?: string, language?: string, overview?: string, format?: string, isEbook?: bool, disambiguation?: string, publisher?: string, pageCount?: int, releaseDate?: string, images?: list, links?: list, ratings?: record, monitored?: bool, manualAdd?: bool, remoteCover?: string}
]: any -> record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, links: table<url: string, name: string>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list, links: list, ratings: record, monitored: bool, manualAdd: bool, remoteCover: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/book")
  let body = {id: $id, title: $title, authorTitle: $authorTitle, seriesTitle: $seriesTitle, disambiguation: $disambiguation, overview: $overview, authorId: $authorId, foreignBookId: $foreignBookId, foreignEditionId: $foreignEditionId, titleSlug: $titleSlug, monitored: $monitored, anyEditionOk: $anyEditionOk, ratings: $ratings, releaseDate: $releaseDate, pageCount: $pageCount, genres: $genres, author: $author, images: $images, links: $links, statistics: $statistics, added: $added, addOptions: $addOptions, remoteCover: $remoteCover, lastSearchTime: $lastSearchTime, editions: $editions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/book/{id}/overview
export def "book-overview get" [
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
  let full_url = (build-url $base $"/api/v1/book/($id)/overview")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/book/{id}
#
# --ratings shape: {votes?: int, value?: float}
# --author shape: {id?: int, authorMetadataId?: int, status?: "continuing"|"ended", authorName?: string, authorNameLastFirst?: string, foreignAuthorId?: string, titleSlug?: string, overview?: string, disambiguation?: string, links?: list, nextBook?: record, lastBook?: record, images?: list, remotePoster?: string, path?: string, qualityProfileId?: int, metadataProfileId?: int, monitored?: bool, monitorNewItems?: "all"|"none"|"new", rootFolderPath?: string, folder?: string, genres?: list, cleanName?: string, sortName?: string, sortNameLastFirst?: string, tags?: list, added?: string, addOptions?: record, ratings?: record, statistics?: record}
# --images item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
# --links item shape: {url?: string, name?: string}
# --statistics shape: {bookFileCount?: int, bookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
# --addOptions shape: {addType?: "automatic"|"manual", searchForNewBook?: bool}
# --editions item shape: {id?: int, bookId?: int, foreignEditionId?: string, titleSlug?: string, isbn13?: string, asin?: string, title?: string, language?: string, overview?: string, format?: string, isEbook?: bool, disambiguation?: string, publisher?: string, pageCount?: int, releaseDate?: string, images?: list, links?: list, ratings?: record, monitored?: bool, manualAdd?: bool, remoteCover?: string}
export def "book put" [
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
  --title: string # nullable
  --authorTitle: string # nullable
  --seriesTitle: string # nullable
  --disambiguation: string # nullable
  --overview: string # nullable
  --authorId: int # format: int32
  --foreignBookId: string # nullable
  --foreignEditionId: string # nullable
  --titleSlug: string # nullable
  --monitored: string@bool-completer
  --anyEditionOk: string@bool-completer
  --ratings: record # shape: {votes?: int, value?: float}
  --releaseDate: string # nullable, format: date-time
  --pageCount: int # format: int32
  --genres: list # nullable
  --author: record # shape: {id?: int, authorMetadataId?: int, status?: "continuing"|"ended", authorName?: string, authorNameLastFirst?: string, foreignAuthorId?: string, titleSlug?: string, overview?: string, disambiguation?: string, links?: list, nextBook?: record, lastBook?: record, images?: list, remotePoster?: string, path?: string, qualityProfileId?: int, metadataProfileId?: int, monitored?: bool, monitorNewItems?: "all"|"none"|"new", rootFolderPath?: string, folder?: string, genres?: list, cleanName?: string, sortName?: string, sortNameLastFirst?: string, tags?: list, added?: string, addOptions?: record, ratings?: record, statistics?: record}
  --images: list # nullable — item shape: {url?: string, coverType?: "unknown"|"poster"|"banner"|"fanart"|"screenshot"|"headshot"|"cover"|"disc"|"logo"|"clearlogo", remoteUrl?: string}
  --links: list # nullable — item shape: {url?: string, name?: string}
  --statistics: record # shape: {bookFileCount?: int, bookCount?: int, totalBookCount?: int, sizeOnDisk?: int}
  --added: string # nullable, format: date-time
  --addOptions: record # shape: {addType?: "automatic"|"manual", searchForNewBook?: bool}
  --remoteCover: string # nullable
  --lastSearchTime: string # nullable, format: date-time
  --editions: list # nullable — item shape: {id?: int, bookId?: int, foreignEditionId?: string, titleSlug?: string, isbn13?: string, asin?: string, title?: string, language?: string, overview?: string, format?: string, isEbook?: bool, disambiguation?: string, publisher?: string, pageCount?: int, releaseDate?: string, images?: list, links?: list, ratings?: record, monitored?: bool, manualAdd?: bool, remoteCover?: string}
]: any -> record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, links: table<url: string, name: string>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list, links: list, ratings: record, monitored: bool, manualAdd: bool, remoteCover: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/book/($id)")
  let body = {id: $body_id, title: $title, authorTitle: $authorTitle, seriesTitle: $seriesTitle, disambiguation: $disambiguation, overview: $overview, authorId: $authorId, foreignBookId: $foreignBookId, foreignEditionId: $foreignEditionId, titleSlug: $titleSlug, monitored: $monitored, anyEditionOk: $anyEditionOk, ratings: $ratings, releaseDate: $releaseDate, pageCount: $pageCount, genres: $genres, author: $author, images: $images, links: $links, statistics: $statistics, added: $added, addOptions: $addOptions, remoteCover: $remoteCover, lastSearchTime: $lastSearchTime, editions: $editions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/book/{id}
export def "book delete" [
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
  let full_url = (build-url $base $"/api/v1/book/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/book/{id}
export def "book get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, links: table<url: string, name: string>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list, links: list, ratings: record, monitored: bool, manualAdd: bool, remoteCover: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/book/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/book/monitor
export def "book-monitor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookIds: list # nullable
  --monitored: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/book/monitor")
  let body = {bookIds: $bookIds, monitored: $monitored} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/book/editor
export def "book-editor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookIds: list # nullable
  --monitored: string@bool-completer # nullable
  --deleteFiles: string@bool-completer # nullable
  --addImportListExclusion: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/book/editor")
  let body = {bookIds: $bookIds, monitored: $monitored, deleteFiles: $deleteFiles, addImportListExclusion: $addImportListExclusion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/book/editor
export def "book-editor delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookIds: list # nullable
  --monitored: string@bool-completer # nullable
  --deleteFiles: string@bool-completer # nullable
  --addImportListExclusion: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/book/editor")
  let body = {bookIds: $bookIds, monitored: $monitored, deleteFiles: $deleteFiles, addImportListExclusion: $addImportListExclusion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/bookfile
export def "bookfile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
  --bookFileIds: list
  --bookId: list
  --unmapped: string@bool-completer
]: nothing -> table<id: int, authorId: int, bookId: int, path: string, size: int, dateAdded: string, quality: record<quality: record, revision: record>, qualityWeight: int, indexerFlags: int, mediaInfo: record<id: int, audioChannels: float, audioBitRate: string, audioCodec: string, audioBits: string, audioSampleRate: string>, qualityCutoffNotMet: bool, audioTags: record<title: string, cleanTitle: string, authors: list, authorTitle: string, bookTitle: string, seriesTitle: string, seriesIndex: string, isbn: string, asin: string, goodreadsId: string, authorMBId: string, bookMBId: string, releaseMBId: string, recordingMBId: string, trackMBId: string, discNumber: int, discCount: int, country: record, year: int, publisher: string, label: string, source: string, catalogNumber: string, disambiguation: string, duration: string, quality: record, mediaInfo: record, trackNumbers: list, language: string, releaseGroup: string, releaseHash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar") (serialize-qp "bookFileIds" $bookFileIds "multi") (serialize-qp "bookId" $bookId "multi") (serialize-qp "unmapped" $unmapped "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/bookfile" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/bookfile/{id}
#
# --quality shape: {quality?: record, revision?: record}
# --mediaInfo shape: {id?: int, audioChannels?: float, audioBitRate?: string, audioCodec?: string, audioBits?: string, audioSampleRate?: string}
# --audioTags shape: {title?: string, cleanTitle?: string, authors?: list, bookTitle?: string, seriesTitle?: string, seriesIndex?: string, isbn?: string, asin?: string, goodreadsId?: string, authorMBId?: string, bookMBId?: string, releaseMBId?: string, recordingMBId?: string, trackMBId?: string, discNumber?: int, discCount?: int, country?: record, year?: int, publisher?: string, label?: string, source?: string, catalogNumber?: string, disambiguation?: string, duration?: string, quality?: record, mediaInfo?: record, trackNumbers?: list, language?: string, releaseGroup?: string, releaseHash?: string}
export def "bookfile put" [
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
  --authorId: int # format: int32
  --bookId: int # format: int32
  --path: string # nullable
  --size: int # format: int64
  --dateAdded: string # format: date-time
  --quality: record # shape: {quality?: record, revision?: record}
  --qualityWeight: int # format: int32
  --indexerFlags: int # nullable, format: int32
  --mediaInfo: record # shape: {id?: int, audioChannels?: float, audioBitRate?: string, audioCodec?: string, audioBits?: string, audioSampleRate?: string}
  --qualityCutoffNotMet: string@bool-completer
  --audioTags: record # shape: {title?: string, cleanTitle?: string, authors?: list, bookTitle?: string, seriesTitle?: string, seriesIndex?: string, isbn?: string, asin?: string, goodreadsId?: string, authorMBId?: string, bookMBId?: string, releaseMBId?: string, recordingMBId?: string, trackMBId?: string, discNumber?: int, discCount?: int, country?: record, year?: int, publisher?: string, label?: string, source?: string, catalogNumber?: string, disambiguation?: string, duration?: string, quality?: record, mediaInfo?: record, trackNumbers?: list, language?: string, releaseGroup?: string, releaseHash?: string}
]: any -> record<id: int, authorId: int, bookId: int, path: string, size: int, dateAdded: string, quality: record<quality: record<id: int, name: string>, revision: record<version: int, real: int, isRepack: bool>>, qualityWeight: int, indexerFlags: int, mediaInfo: record<id: int, audioChannels: float, audioBitRate: string, audioCodec: string, audioBits: string, audioSampleRate: string>, qualityCutoffNotMet: bool, audioTags: record<title: string, cleanTitle: string, authors: list<string>, authorTitle: string, bookTitle: string, seriesTitle: string, seriesIndex: string, isbn: string, asin: string, goodreadsId: string, authorMBId: string, bookMBId: string, releaseMBId: string, recordingMBId: string, trackMBId: string, discNumber: int, discCount: int, country: record<twoLetterCode: string, name: string>, year: int, publisher: string, label: string, source: string, catalogNumber: string, disambiguation: string, duration: string, quality: record<quality: record, revision: record>, mediaInfo: record<audioFormat: string, audioBitrate: int, audioChannels: int, audioBits: int, audioSampleRate: int>, trackNumbers: list<int>, language: string, releaseGroup: string, releaseHash: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/bookfile/($id)")
  let body = {id: $body_id, authorId: $authorId, bookId: $bookId, path: $path, size: $size, dateAdded: $dateAdded, quality: $quality, qualityWeight: $qualityWeight, indexerFlags: $indexerFlags, mediaInfo: $mediaInfo, qualityCutoffNotMet: $qualityCutoffNotMet, audioTags: $audioTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/bookfile/{id}
export def "bookfile delete" [
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
  let full_url = (build-url $base $"/api/v1/bookfile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/bookfile/{id}
export def "bookfile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, authorId: int, bookId: int, path: string, size: int, dateAdded: string, quality: record<quality: record<id: int, name: string>, revision: record<version: int, real: int, isRepack: bool>>, qualityWeight: int, indexerFlags: int, mediaInfo: record<id: int, audioChannels: float, audioBitRate: string, audioCodec: string, audioBits: string, audioSampleRate: string>, qualityCutoffNotMet: bool, audioTags: record<title: string, cleanTitle: string, authors: list<string>, authorTitle: string, bookTitle: string, seriesTitle: string, seriesIndex: string, isbn: string, asin: string, goodreadsId: string, authorMBId: string, bookMBId: string, releaseMBId: string, recordingMBId: string, trackMBId: string, discNumber: int, discCount: int, country: record<twoLetterCode: string, name: string>, year: int, publisher: string, label: string, source: string, catalogNumber: string, disambiguation: string, duration: string, quality: record<quality: record, revision: record>, mediaInfo: record<audioFormat: string, audioBitrate: int, audioChannels: int, audioBits: int, audioSampleRate: int>, trackNumbers: list<int>, language: string, releaseGroup: string, releaseHash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/bookfile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/bookfile/editor
#
# --quality shape: {quality?: record, revision?: record}
export def "bookfile-editor put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookFileIds: list # nullable
  --quality: record # shape: {quality?: record, revision?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/bookfile/editor")
  let body = {bookFileIds: $bookFileIds, quality: $quality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/bookfile/bulk
#
# --quality shape: {quality?: record, revision?: record}
export def "bookfile-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookFileIds: list # nullable
  --quality: record # shape: {quality?: record, revision?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/bookfile/bulk")
  let body = {bookFileIds: $bookFileIds, quality: $quality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/book/lookup
export def "book-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/book/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/bookshelf
#
# --authors item shape: {id?: int, monitored?: bool, books?: list}
# --monitoringOptions shape: {monitor?: "all"|"future"|"missing"|"existing"|"latest"|"first"|"none"|"unknown", booksToMonitor?: list, monitored?: bool}
export def "bookshelf post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authors: list # nullable — item shape: {id?: int, monitored?: bool, books?: list}
  --monitoringOptions: record # shape: {monitor?: "all"|"future"|"missing"|"existing"|"latest"|"first"|"none"|"unknown", booksToMonitor?: list, monitored?: bool}
  --monitorNewItems: string@monitorNewItems-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/bookshelf")
  let body = {authors: $authors, monitoringOptions: $monitoringOptions, monitorNewItems: $monitorNewItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/calendar
export def "calendar list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --start: string # format: date-time
  --end: string # format: date-time
  --unmonitored: string@bool-completer # default: false
  --includeAuthor: string@bool-completer # default: false
]: nothing -> table<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list, nextBook: record, lastBook: record, images: list, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list, added: string, addOptions: record, ratings: record, statistics: record>, images: list<record>, links: list<record>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "unmonitored" $unmonitored "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/calendar" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/calendar/{id}
export def "calendar get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, links: table<url: string, name: string>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list, links: list, ratings: record, monitored: bool, manualAdd: bool, remoteCover: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/calendar/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /feed/v1/calendar/readarr.ics
export def "feed-calendar-readarrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pastDays: int # format: int32, default: 7
  --futureDays: int # format: int32, default: 28
  --tagList: string # default: 
  --unmonitored: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pastDays" $pastDays "scalar") (serialize-qp "futureDays" $futureDays "scalar") (serialize-qp "tagList" $tagList "scalar") (serialize-qp "unmonitored" $unmonitored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feed/v1/calendar/readarr.ics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/command
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
  --accept: string@accept-completer # Response content type
  --id: int # format: int32
  --name: string # nullable
  --commandName: string # nullable
  --message: string # nullable
  --body-body: record # shape: {sendUpdatesToClient?: bool, lastExecutionTime?: string, lastStartTime?: string, trigger?: "unspecified"|"manual"|"scheduled", suppressMessages?: bool, clientUserAgent?: string}
  --priority: string@priority-completer
  --status: string@status-completer-1
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
]: any -> record<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isTypeExclusive: bool, isLongRunning: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, result: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/command")
  let body = {id: $id, name: $name, commandName: $commandName, message: $message, body: $body_body, priority: $priority, status: $status, result: $body_result, queued: $queued, started: $started, ended: $ended, duration: $duration, exception: $exception, trigger: $trigger, clientUserAgent: $clientUserAgent, stateChangeTime: $stateChangeTime, sendUpdatesToClient: $sendUpdatesToClient, updateScheduledTask: $updateScheduledTask, lastExecutionTime: $lastExecutionTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/command
export def "command list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isTypeExclusive: bool, isLongRunning: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, result: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/command")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/command/{id}
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
  let full_url = (build-url $base $"/api/v1/command/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/command/{id}
export def "command get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isTypeExclusive: bool, isLongRunning: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, result: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/command/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/customfilter
export def "customfilter list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, type: string, label: string, filters: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customfilter")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/customfilter
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
  let full_url = (build-url $base "/api/v1/customfilter")
  let body = {id: $id, type: $type, label: $label, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/customfilter/{id}
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
  let full_url = (build-url $base $"/api/v1/customfilter/($id)")
  let body = {id: $body_id, type: $type, label: $label, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/customfilter/{id}
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
  let full_url = (build-url $base $"/api/v1/customfilter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/customfilter/{id}
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
  let full_url = (build-url $base $"/api/v1/customfilter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/customformat
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
  let full_url = (build-url $base "/api/v1/customformat")
  let body = {id: $id, name: $name, includeCustomFormatWhenRenaming: $includeCustomFormatWhenRenaming, specifications: $specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/customformat
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
  let full_url = (build-url $base "/api/v1/customformat")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/customformat/{id}
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
  let full_url = (build-url $base $"/api/v1/customformat/($id)")
  let body = {id: $body_id, name: $name, includeCustomFormatWhenRenaming: $includeCustomFormatWhenRenaming, specifications: $specifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/customformat/{id}
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
  let full_url = (build-url $base $"/api/v1/customformat/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/customformat/{id}
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
  let full_url = (build-url $base $"/api/v1/customformat/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/customformat/schema
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
  let full_url = (build-url $base "/api/v1/customformat/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/wanted/cutoff
export def "wanted-cutoff list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string@sortDirection-completer
  --includeAuthor: string@bool-completer # default: false
  --monitored: string@bool-completer # default: true
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "monitored" $monitored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/wanted/cutoff" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/wanted/cutoff/{id}
export def "wanted-cutoff get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, links: table<url: string, name: string>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list, links: list, ratings: record, monitored: bool, manualAdd: bool, remoteCover: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/wanted/cutoff/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/delayprofile
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
  let full_url = (build-url $base "/api/v1/delayprofile")
  let body = {id: $id, enableUsenet: $enableUsenet, enableTorrent: $enableTorrent, preferredProtocol: $preferredProtocol, usenetDelay: $usenetDelay, torrentDelay: $torrentDelay, bypassIfHighestQuality: $bypassIfHighestQuality, bypassIfAboveCustomFormatScore: $bypassIfAboveCustomFormatScore, minimumCustomFormatScore: $minimumCustomFormatScore, order: $order, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/delayprofile
export def "delayprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, enableUsenet: bool, enableTorrent: bool, preferredProtocol: string, usenetDelay: int, torrentDelay: int, bypassIfHighestQuality: bool, bypassIfAboveCustomFormatScore: bool, minimumCustomFormatScore: int, order: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/delayprofile")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/delayprofile/{id}
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
  let full_url = (build-url $base $"/api/v1/delayprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/delayprofile/{id}
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
  let full_url = (build-url $base $"/api/v1/delayprofile/($id)")
  let body = {id: $body_id, enableUsenet: $enableUsenet, enableTorrent: $enableTorrent, preferredProtocol: $preferredProtocol, usenetDelay: $usenetDelay, torrentDelay: $torrentDelay, bypassIfHighestQuality: $bypassIfHighestQuality, bypassIfAboveCustomFormatScore: $bypassIfAboveCustomFormatScore, minimumCustomFormatScore: $minimumCustomFormatScore, order: $order, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/delayprofile/{id}
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
  let full_url = (build-url $base $"/api/v1/delayprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/delayprofile/reorder/{id}
export def "delayprofile-reorder put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --afterId: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "afterId" $afterId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/delayprofile/reorder/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/development
export def "config-development list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, metadataSource: string, consoleLogLevel: string, logSql: bool, logRotate: int, filterSentryEvents: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/development")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/development/{id}
export def "config-development put" [
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
  --metadataSource: string # nullable
  --consoleLogLevel: string # nullable
  --logSql: string@bool-completer
  --logRotate: int # format: int32
  --filterSentryEvents: string@bool-completer
]: any -> record<id: int, metadataSource: string, consoleLogLevel: string, logSql: bool, logRotate: int, filterSentryEvents: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/development/($id)")
  let body = {id: $body_id, metadataSource: $metadataSource, consoleLogLevel: $consoleLogLevel, logSql: $logSql, logRotate: $logRotate, filterSentryEvents: $filterSentryEvents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/development/{id}
export def "config-development get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, metadataSource: string, consoleLogLevel: string, logSql: bool, logRotate: int, filterSentryEvents: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/development/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/diskspace
export def "diskspace get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, path: string, label: string, freeSpace: int, totalSpace: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/diskspace")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/downloadclient
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
  let full_url = (build-url $base "/api/v1/downloadclient")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/downloadclient
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/downloadclient" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/downloadclient/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, removeCompletedDownloads?: bool, removeFailedDownloads?: bool}
export def "downloadclient put" [
  id: string
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/downloadclient/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/downloadclient/{id}
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
  let full_url = (build-url $base $"/api/v1/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/downloadclient/{id}
export def "downloadclient get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/downloadclient/bulk
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
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, removeCompletedDownloads: bool, removeFailedDownloads: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downloadclient/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/downloadclient/bulk
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
  let full_url = (build-url $base "/api/v1/downloadclient/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/downloadclient/schema
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
  let full_url = (build-url $base "/api/v1/downloadclient/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/downloadclient/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  let full_url = (build-url $base "/api/v1/downloadclient/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/downloadclient/testall
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
  let full_url = (build-url $base "/api/v1/downloadclient/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/downloadclient/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  let full_url = (build-url $base $"/api/v1/downloadclient/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, removeCompletedDownloads: $removeCompletedDownloads, removeFailedDownloads: $removeFailedDownloads} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/downloadclient
export def "config-downloadclient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, downloadClientWorkingFolders: string, enableCompletedDownloadHandling: bool, autoRedownloadFailed: bool, autoRedownloadFailedFromInteractiveSearch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/downloadclient")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/downloadclient/{id}
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
  let full_url = (build-url $base $"/api/v1/config/downloadclient/($id)")
  let body = {id: $body_id, downloadClientWorkingFolders: $downloadClientWorkingFolders, enableCompletedDownloadHandling: $enableCompletedDownloadHandling, autoRedownloadFailed: $autoRedownloadFailed, autoRedownloadFailedFromInteractiveSearch: $autoRedownloadFailedFromInteractiveSearch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/downloadclient/{id}
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
  let full_url = (build-url $base $"/api/v1/config/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/edition
export def "edition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --bookId: list
]: nothing -> table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list<record>, links: list<record>, ratings: record<votes: int, value: float, popularity: float>, monitored: bool, manualAdd: bool, remoteCover: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookId" $bookId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/edition" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/filesystem
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
  let full_url = (build-url $base "/api/v1/filesystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/filesystem/type
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
  let full_url = (build-url $base "/api/v1/filesystem/type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/filesystem/mediafiles
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
  let full_url = (build-url $base "/api/v1/filesystem/mediafiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, source: string, type: string, message: string, wikiUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/health")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/history
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
  --sortDirection: string@sortDirection-completer
  --includeAuthor: string@bool-completer
  --includeBook: string@bool-completer
  --eventType: list
  --bookId: int # format: int32
  --downloadId: string
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, bookId: int, authorId: int, sourceTitle: string, quality: record, customFormats: list, customFormatScore: int, qualityCutoffNotMet: bool, date: string, downloadId: string, eventType: string, data: record, book: record, author: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "includeBook" $includeBook "scalar") (serialize-qp "eventType" $eventType "multi") (serialize-qp "bookId" $bookId "scalar") (serialize-qp "downloadId" $downloadId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/history/since
export def "history-since get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --date: string # format: date-time
  --eventType: string@eventType-completer
  --includeAuthor: string@bool-completer # default: false
  --includeBook: string@bool-completer # default: false
]: nothing -> table<id: int, bookId: int, authorId: int, sourceTitle: string, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, qualityCutoffNotMet: bool, date: string, downloadId: string, eventType: string, data: record, book: record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list, nextBook: record, lastBook: record, images: list, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list, added: string, addOptions: record, ratings: record, statistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "includeBook" $includeBook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/history/since" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/history/author
export def "history-author get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
  --bookId: int # format: int32
  --eventType: string@eventType-completer
  --includeAuthor: string@bool-completer # default: false
  --includeBook: string@bool-completer # default: false
]: nothing -> table<id: int, bookId: int, authorId: int, sourceTitle: string, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, qualityCutoffNotMet: bool, date: string, downloadId: string, eventType: string, data: record, book: record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list, nextBook: record, lastBook: record, images: list, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list, added: string, addOptions: record, ratings: record, statistics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar") (serialize-qp "bookId" $bookId "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "includeBook" $includeBook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/history/author" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/history/failed/{id}
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
  let full_url = (build-url $base $"/api/v1/history/failed/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/host
export def "config-host list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, trustCgnatIpAddresses: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/host")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/host/{id}
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
]: any -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, trustCgnatIpAddresses: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/host/($id)")
  let body = {id: $body_id, bindAddress: $bindAddress, port: $port, sslPort: $sslPort, enableSsl: $enableSsl, launchBrowser: $launchBrowser, authenticationMethod: $authenticationMethod, authenticationRequired: $authenticationRequired, analyticsEnabled: $analyticsEnabled, username: $username, password: $password, passwordConfirmation: $passwordConfirmation, logLevel: $logLevel, consoleLogLevel: $consoleLogLevel, branch: $branch, apiKey: $apiKey, sslCertPath: $sslCertPath, sslCertPassword: $sslCertPassword, urlBase: $urlBase, instanceName: $instanceName, applicationUrl: $applicationUrl, updateAutomatically: $updateAutomatically, updateMechanism: $updateMechanism, updateScriptPath: $updateScriptPath, proxyEnabled: $proxyEnabled, proxyType: $proxyType, proxyHostname: $proxyHostname, proxyPort: $proxyPort, proxyUsername: $proxyUsername, proxyPassword: $proxyPassword, proxyBypassFilter: $proxyBypassFilter, proxyBypassLocalAddresses: $proxyBypassLocalAddresses, certificateValidation: $certificateValidation, backupFolder: $backupFolder, backupInterval: $backupInterval, backupRetention: $backupRetention, trustCgnatIpAddresses: $trustCgnatIpAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/host/{id}
export def "config-host get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, trustCgnatIpAddresses: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/host/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/importlist
export def "importlist list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, shouldMonitor: string, shouldMonitorExisting: bool, shouldSearch: bool, rootFolderPath: string, monitorNewItems: string, qualityProfileId: int, metadataProfileId: int, listType: string, listOrder: int, minRefreshInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/importlist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/importlist
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --shouldMonitorExisting: string@bool-completer
  --shouldSearch: string@bool-completer
  --rootFolderPath: string # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # format: int32
  --metadataProfileId: int # format: int32
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, shouldMonitor: string, shouldMonitorExisting: bool, shouldSearch: bool, rootFolderPath: string, monitorNewItems: string, qualityProfileId: int, metadataProfileId: int, listType: string, listOrder: int, minRefreshInterval: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/importlist" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, shouldMonitor: $shouldMonitor, shouldMonitorExisting: $shouldMonitorExisting, shouldSearch: $shouldSearch, rootFolderPath: $rootFolderPath, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/importlist/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
export def "importlist put" [
  id: string
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --shouldMonitorExisting: string@bool-completer
  --shouldSearch: string@bool-completer
  --rootFolderPath: string # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # format: int32
  --metadataProfileId: int # format: int32
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, shouldMonitor: string, shouldMonitorExisting: bool, shouldSearch: bool, rootFolderPath: string, monitorNewItems: string, qualityProfileId: int, metadataProfileId: int, listType: string, listOrder: int, minRefreshInterval: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/importlist/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, shouldMonitor: $shouldMonitor, shouldMonitorExisting: $shouldMonitorExisting, shouldSearch: $shouldSearch, rootFolderPath: $rootFolderPath, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/importlist/{id}
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
  let full_url = (build-url $base $"/api/v1/importlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/importlist/{id}
export def "importlist get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, shouldMonitor: string, shouldMonitorExisting: bool, shouldSearch: bool, rootFolderPath: string, monitorNewItems: string, qualityProfileId: int, metadataProfileId: int, listType: string, listOrder: int, minRefreshInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/importlist/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/importlist/bulk
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
  --metadataProfileId: int # nullable, format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, shouldMonitor: string, shouldMonitorExisting: bool, shouldSearch: bool, rootFolderPath: string, monitorNewItems: string, qualityProfileId: int, metadataProfileId: int, listType: string, listOrder: int, minRefreshInterval: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/importlist/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableAutomaticAdd: $enableAutomaticAdd, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/importlist/bulk
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
  --metadataProfileId: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/importlist/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableAutomaticAdd: $enableAutomaticAdd, rootFolderPath: $rootFolderPath, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/importlist/schema
export def "importlist-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableAutomaticAdd: bool, shouldMonitor: string, shouldMonitorExisting: bool, shouldSearch: bool, rootFolderPath: string, monitorNewItems: string, qualityProfileId: int, metadataProfileId: int, listType: string, listOrder: int, minRefreshInterval: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/importlist/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/importlist/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --shouldMonitorExisting: string@bool-completer
  --shouldSearch: string@bool-completer
  --rootFolderPath: string # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # format: int32
  --metadataProfileId: int # format: int32
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/importlist/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, shouldMonitor: $shouldMonitor, shouldMonitorExisting: $shouldMonitorExisting, shouldSearch: $shouldSearch, rootFolderPath: $rootFolderPath, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/importlist/testall
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
  let full_url = (build-url $base "/api/v1/importlist/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/importlist/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableAutomaticAdd?: bool, shouldMonitor?: "none"|"specificBook"|"entireAuthor", shouldMonitorExisting?: bool, shouldSearch?: bool, rootFolderPath?: string, monitorNewItems?: "all"|"none"|"new", qualityProfileId?: int, metadataProfileId?: int, listType?: "program"|"goodreads"|"other", listOrder?: int, minRefreshInterval?: string}
  --enableAutomaticAdd: string@bool-completer
  --shouldMonitor: string@shouldMonitor-completer
  --shouldMonitorExisting: string@bool-completer
  --shouldSearch: string@bool-completer
  --rootFolderPath: string # nullable
  --monitorNewItems: string@monitorNewItems-completer
  --qualityProfileId: int # format: int32
  --metadataProfileId: int # format: int32
  --listType: string@listType-completer
  --listOrder: int # format: int32
  --minRefreshInterval: string # format: date-span
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/importlist/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableAutomaticAdd: $enableAutomaticAdd, shouldMonitor: $shouldMonitor, shouldMonitorExisting: $shouldMonitorExisting, shouldSearch: $shouldSearch, rootFolderPath: $rootFolderPath, monitorNewItems: $monitorNewItems, qualityProfileId: $qualityProfileId, metadataProfileId: $metadataProfileId, listType: $listType, listOrder: $listOrder, minRefreshInterval: $minRefreshInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/importlistexclusion
export def "importlistexclusion list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, foreignId: string, authorName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/importlistexclusion")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/importlistexclusion
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
  --foreignId: string # nullable
  --authorName: string # nullable
]: any -> record<id: int, foreignId: string, authorName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/importlistexclusion")
  let body = {id: $id, foreignId: $foreignId, authorName: $authorName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/importlistexclusion/{id}
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
  --foreignId: string # nullable
  --authorName: string # nullable
]: any -> record<id: int, foreignId: string, authorName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/importlistexclusion/($id)")
  let body = {id: $body_id, foreignId: $foreignId, authorName: $authorName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/importlistexclusion/{id}
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
  let full_url = (build-url $base $"/api/v1/importlistexclusion/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/importlistexclusion/{id}
export def "importlistexclusion get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, foreignId: string, authorName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/importlistexclusion/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexer
export def "indexer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexer
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --downloadClientId: int # format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexer" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/indexer/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
export def "indexer put" [
  id: string
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --downloadClientId: int # format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/indexer/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/indexer/{id}
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
  let full_url = (build-url $base $"/api/v1/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexer/{id}
export def "indexer get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/indexer/bulk
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
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/indexer/bulk
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
  let full_url = (build-url $base "/api/v1/indexer/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/indexer/schema
export def "indexer-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, supportsRss: bool, supportsSearch: bool, protocol: string, priority: int, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexer/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --downloadClientId: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexer/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/indexer/testall
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
  let full_url = (build-url $base "/api/v1/indexer/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexer/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enableRss?: bool, enableAutomaticSearch?: bool, enableInteractiveSearch?: bool, supportsRss?: bool, supportsSearch?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, downloadClientId?: int}
  --enableRss: string@bool-completer
  --enableAutomaticSearch: string@bool-completer
  --enableInteractiveSearch: string@bool-completer
  --supportsRss: string@bool-completer
  --supportsSearch: string@bool-completer
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --downloadClientId: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexer/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, supportsRss: $supportsRss, supportsSearch: $supportsSearch, protocol: $protocol, priority: $priority, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/indexer
export def "config-indexer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, minimumAge: int, maximumSize: int, retention: int, rssSyncInterval: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/indexer")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/indexer/{id}
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
  --maximumSize: int # format: int32
  --retention: int # format: int32
  --rssSyncInterval: int # format: int32
]: any -> record<id: int, minimumAge: int, maximumSize: int, retention: int, rssSyncInterval: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/indexer/($id)")
  let body = {id: $body_id, minimumAge: $minimumAge, maximumSize: $maximumSize, retention: $retention, rssSyncInterval: $rssSyncInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/indexer/{id}
export def "config-indexer get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, minimumAge: int, maximumSize: int, retention: int, rssSyncInterval: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexerflag
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
  let full_url = (build-url $base "/api/v1/indexerflag")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/language
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
  let full_url = (build-url $base "/api/v1/language")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/language/{id}
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
  let full_url = (build-url $base $"/api/v1/language/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/localization
export def "localization get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/localization")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log
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
  --sortDirection: string@sortDirection-completer
  --level: string
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, time: string, exception: string, exceptionType: string, level: string, logger: string, message: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "level" $level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file
export def "log-file list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, filename: string, lastWriteTime: string, contentsUrl: string, downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/log/file")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file/{filename}
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
  let full_url = (build-url $base $"/api/v1/log/file/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/manualimport
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
  let full_url = (build-url $base "/api/v1/manualimport")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/manualimport
export def "manualimport get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --folder: string
  --downloadId: string
  --authorId: int # format: int32
  --filterExistingFiles: string@bool-completer # default: true
  --replaceExistingFiles: string@bool-completer # default: true
]: nothing -> table<id: int, path: string, name: string, size: int, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list, nextBook: record, lastBook: record, images: list, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list, added: string, addOptions: record, ratings: record, statistics: record>, book: record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>, foreignEditionId: string, quality: record<quality: record, revision: record>, releaseGroup: string, qualityWeight: int, downloadId: string, indexerFlags: int, rejections: list<record>, audioTags: record<title: string, cleanTitle: string, authors: list, authorTitle: string, bookTitle: string, seriesTitle: string, seriesIndex: string, isbn: string, asin: string, goodreadsId: string, authorMBId: string, bookMBId: string, releaseMBId: string, recordingMBId: string, trackMBId: string, discNumber: int, discCount: int, country: record, year: int, publisher: string, label: string, source: string, catalogNumber: string, disambiguation: string, duration: string, quality: record, mediaInfo: record, trackNumbers: list, language: string, releaseGroup: string, releaseHash: string>, additionalFile: bool, replaceExistingFiles: bool, disableReleaseSwitching: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folder" $folder "scalar") (serialize-qp "downloadId" $downloadId "scalar") (serialize-qp "authorId" $authorId "scalar") (serialize-qp "filterExistingFiles" $filterExistingFiles "scalar") (serialize-qp "replaceExistingFiles" $replaceExistingFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/manualimport" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/mediacover/author/{authorId}/{filename}
export def "mediacover-author get" [
  authorId: int
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
  let full_url = (build-url $base $"/api/v1/mediacover/author/($authorId)/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/mediacover/book/{bookId}/{filename}
export def "mediacover-book get" [
  bookId: int
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
  let full_url = (build-url $base $"/api/v1/mediacover/book/($bookId)/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/mediamanagement
export def "config-mediamanagement list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, autoUnmonitorPreviouslyDownloadedBooks: bool, recycleBin: string, recycleBinCleanupDays: int, downloadPropersAndRepacks: string, createEmptyAuthorFolders: bool, deleteEmptyFolders: bool, fileDate: string, watchLibraryForChanges: bool, rescanAfterRefresh: string, allowFingerprinting: string, setPermissionsLinux: bool, chmodFolder: string, chownGroup: string, skipFreeSpaceCheckWhenImporting: bool, minimumFreeSpaceWhenImporting: int, copyUsingHardlinks: bool, importExtraFiles: bool, extraFileExtensions: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/mediamanagement")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/mediamanagement/{id}
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
  --autoUnmonitorPreviouslyDownloadedBooks: string@bool-completer
  --recycleBin: string # nullable
  --recycleBinCleanupDays: int # format: int32
  --downloadPropersAndRepacks: string@downloadPropersAndRepacks-completer
  --createEmptyAuthorFolders: string@bool-completer
  --deleteEmptyFolders: string@bool-completer
  --fileDate: string@fileDate-completer
  --watchLibraryForChanges: string@bool-completer
  --rescanAfterRefresh: string@rescanAfterRefresh-completer
  --allowFingerprinting: string@allowFingerprinting-completer
  --setPermissionsLinux: string@bool-completer
  --chmodFolder: string # nullable
  --chownGroup: string # nullable
  --skipFreeSpaceCheckWhenImporting: string@bool-completer
  --minimumFreeSpaceWhenImporting: int # format: int32
  --copyUsingHardlinks: string@bool-completer
  --importExtraFiles: string@bool-completer
  --extraFileExtensions: string # nullable
]: any -> record<id: int, autoUnmonitorPreviouslyDownloadedBooks: bool, recycleBin: string, recycleBinCleanupDays: int, downloadPropersAndRepacks: string, createEmptyAuthorFolders: bool, deleteEmptyFolders: bool, fileDate: string, watchLibraryForChanges: bool, rescanAfterRefresh: string, allowFingerprinting: string, setPermissionsLinux: bool, chmodFolder: string, chownGroup: string, skipFreeSpaceCheckWhenImporting: bool, minimumFreeSpaceWhenImporting: int, copyUsingHardlinks: bool, importExtraFiles: bool, extraFileExtensions: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/mediamanagement/($id)")
  let body = {id: $body_id, autoUnmonitorPreviouslyDownloadedBooks: $autoUnmonitorPreviouslyDownloadedBooks, recycleBin: $recycleBin, recycleBinCleanupDays: $recycleBinCleanupDays, downloadPropersAndRepacks: $downloadPropersAndRepacks, createEmptyAuthorFolders: $createEmptyAuthorFolders, deleteEmptyFolders: $deleteEmptyFolders, fileDate: $fileDate, watchLibraryForChanges: $watchLibraryForChanges, rescanAfterRefresh: $rescanAfterRefresh, allowFingerprinting: $allowFingerprinting, setPermissionsLinux: $setPermissionsLinux, chmodFolder: $chmodFolder, chownGroup: $chownGroup, skipFreeSpaceCheckWhenImporting: $skipFreeSpaceCheckWhenImporting, minimumFreeSpaceWhenImporting: $minimumFreeSpaceWhenImporting, copyUsingHardlinks: $copyUsingHardlinks, importExtraFiles: $importExtraFiles, extraFileExtensions: $extraFileExtensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/mediamanagement/{id}
export def "config-mediamanagement get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, autoUnmonitorPreviouslyDownloadedBooks: bool, recycleBin: string, recycleBinCleanupDays: int, downloadPropersAndRepacks: string, createEmptyAuthorFolders: bool, deleteEmptyFolders: bool, fileDate: string, watchLibraryForChanges: bool, rescanAfterRefresh: string, allowFingerprinting: string, setPermissionsLinux: bool, chmodFolder: string, chownGroup: string, skipFreeSpaceCheckWhenImporting: bool, minimumFreeSpaceWhenImporting: int, copyUsingHardlinks: bool, importExtraFiles: bool, extraFileExtensions: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/mediamanagement/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/metadata
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
  let full_url = (build-url $base "/api/v1/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/metadata
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
  --enable: string@bool-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/metadata" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/metadata/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
export def "metadata put" [
  id: string
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool}
  --enable: string@bool-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/metadata/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/metadata/{id}
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
  let full_url = (build-url $base $"/api/v1/metadata/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/metadata/{id}
export def "metadata get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metadata/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/metadata/schema
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
  let full_url = (build-url $base "/api/v1/metadata/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/metadata/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  let full_url = (build-url $base "/api/v1/metadata/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/metadata/testall
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
  let full_url = (build-url $base "/api/v1/metadata/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/metadata/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
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
  let full_url = (build-url $base $"/api/v1/metadata/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/metadataprofile
export def "metadataprofile post" [
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
  --minPopularity: float # format: double
  --skipMissingDate: string@bool-completer
  --skipMissingIsbn: string@bool-completer
  --skipPartsAndSets: string@bool-completer
  --skipSeriesSecondary: string@bool-completer
  --allowedLanguages: string # nullable
  --minPages: int # format: int32
  --ignored: list # nullable
]: any -> record<id: int, name: string, minPopularity: float, skipMissingDate: bool, skipMissingIsbn: bool, skipPartsAndSets: bool, skipSeriesSecondary: bool, allowedLanguages: string, minPages: int, ignored: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metadataprofile")
  let body = {id: $id, name: $name, minPopularity: $minPopularity, skipMissingDate: $skipMissingDate, skipMissingIsbn: $skipMissingIsbn, skipPartsAndSets: $skipPartsAndSets, skipSeriesSecondary: $skipSeriesSecondary, allowedLanguages: $allowedLanguages, minPages: $minPages, ignored: $ignored} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/metadataprofile
export def "metadataprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, minPopularity: float, skipMissingDate: bool, skipMissingIsbn: bool, skipPartsAndSets: bool, skipSeriesSecondary: bool, allowedLanguages: string, minPages: int, ignored: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metadataprofile")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/metadataprofile/{id}
export def "metadataprofile delete" [
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
  let full_url = (build-url $base $"/api/v1/metadataprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/metadataprofile/{id}
export def "metadataprofile put" [
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
  --minPopularity: float # format: double
  --skipMissingDate: string@bool-completer
  --skipMissingIsbn: string@bool-completer
  --skipPartsAndSets: string@bool-completer
  --skipSeriesSecondary: string@bool-completer
  --allowedLanguages: string # nullable
  --minPages: int # format: int32
  --ignored: list # nullable
]: any -> record<id: int, name: string, minPopularity: float, skipMissingDate: bool, skipMissingIsbn: bool, skipPartsAndSets: bool, skipSeriesSecondary: bool, allowedLanguages: string, minPages: int, ignored: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metadataprofile/($id)")
  let body = {id: $body_id, name: $name, minPopularity: $minPopularity, skipMissingDate: $skipMissingDate, skipMissingIsbn: $skipMissingIsbn, skipPartsAndSets: $skipPartsAndSets, skipSeriesSecondary: $skipSeriesSecondary, allowedLanguages: $allowedLanguages, minPages: $minPages, ignored: $ignored} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/metadataprofile/{id}
export def "metadataprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, minPopularity: float, skipMissingDate: bool, skipMissingIsbn: bool, skipPartsAndSets: bool, skipSeriesSecondary: bool, allowedLanguages: string, minPages: int, ignored: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metadataprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/metadataprofile/schema
export def "metadataprofile-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, name: string, minPopularity: float, skipMissingDate: bool, skipMissingIsbn: bool, skipPartsAndSets: bool, skipSeriesSecondary: bool, allowedLanguages: string, minPages: int, ignored: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metadataprofile/schema")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/metadataprovider
export def "config-metadataprovider list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, writeAudioTags: string, scrubAudioTags: bool, writeBookTags: string, updateCovers: bool, embedMetadata: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/metadataprovider")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/metadataprovider/{id}
export def "config-metadataprovider put" [
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
  --writeAudioTags: string@writeAudioTags-completer
  --scrubAudioTags: string@bool-completer
  --writeBookTags: string@writeBookTags-completer
  --updateCovers: string@bool-completer
  --embedMetadata: string@bool-completer
]: any -> record<id: int, writeAudioTags: string, scrubAudioTags: bool, writeBookTags: string, updateCovers: bool, embedMetadata: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/metadataprovider/($id)")
  let body = {id: $body_id, writeAudioTags: $writeAudioTags, scrubAudioTags: $scrubAudioTags, writeBookTags: $writeBookTags, updateCovers: $updateCovers, embedMetadata: $embedMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/metadataprovider/{id}
export def "config-metadataprovider get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, writeAudioTags: string, scrubAudioTags: bool, writeBookTags: string, updateCovers: bool, embedMetadata: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/metadataprovider/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/wanted/missing
export def "wanted-missing list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string@sortDirection-completer
  --includeAuthor: string@bool-completer # default: false
  --monitored: string@bool-completer # default: true
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "monitored" $monitored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/wanted/missing" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/wanted/missing/{id}
export def "wanted-missing get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record<votes: int, value: float, popularity: float>, releaseDate: string, pageCount: int, genres: list<string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, images: table<url: string, coverType: string, extension: string, remoteUrl: string>, links: table<url: string, name: string>, statistics: record<bookFileCount: int, bookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>, added: string, addOptions: record<addType: string, searchForNewBook: bool>, remoteCover: string, lastSearchTime: string, editions: table<id: int, bookId: int, foreignEditionId: string, titleSlug: string, isbn13: string, asin: string, title: string, language: string, overview: string, format: string, isEbook: bool, disambiguation: string, publisher: string, pageCount: int, releaseDate: string, images: list, links: list, ratings: record, monitored: bool, manualAdd: bool, remoteCover: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/wanted/missing/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/naming
export def "config-naming list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, renameBooks: bool, replaceIllegalCharacters: bool, colonReplacementFormat: int, standardBookFormat: string, authorFolderFormat: string, includeAuthorName: bool, includeBookTitle: bool, includeQuality: bool, replaceSpaces: bool, separator: string, numberStyle: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/naming")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/naming/{id}
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
  --renameBooks: string@bool-completer
  --replaceIllegalCharacters: string@bool-completer
  --colonReplacementFormat: int # format: int32
  --standardBookFormat: string # nullable
  --authorFolderFormat: string # nullable
  --includeAuthorName: string@bool-completer
  --includeBookTitle: string@bool-completer
  --includeQuality: string@bool-completer
  --replaceSpaces: string@bool-completer
  --separator: string # nullable
  --numberStyle: string # nullable
]: any -> record<id: int, renameBooks: bool, replaceIllegalCharacters: bool, colonReplacementFormat: int, standardBookFormat: string, authorFolderFormat: string, includeAuthorName: bool, includeBookTitle: bool, includeQuality: bool, replaceSpaces: bool, separator: string, numberStyle: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/naming/($id)")
  let body = {id: $body_id, renameBooks: $renameBooks, replaceIllegalCharacters: $replaceIllegalCharacters, colonReplacementFormat: $colonReplacementFormat, standardBookFormat: $standardBookFormat, authorFolderFormat: $authorFolderFormat, includeAuthorName: $includeAuthorName, includeBookTitle: $includeBookTitle, includeQuality: $includeQuality, replaceSpaces: $replaceSpaces, separator: $separator, numberStyle: $numberStyle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/naming/{id}
export def "config-naming get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, renameBooks: bool, replaceIllegalCharacters: bool, colonReplacementFormat: int, standardBookFormat: string, authorFolderFormat: string, includeAuthorName: bool, includeBookTitle: bool, includeQuality: bool, replaceSpaces: bool, separator: string, numberStyle: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/naming/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/naming/examples
export def "config-naming-examples get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --renameBooks: string@bool-completer
  --replaceIllegalCharacters: string@bool-completer
  --colonReplacementFormat: int # format: int32
  --standardBookFormat: string
  --authorFolderFormat: string
  --includeAuthorName: string@bool-completer
  --includeBookTitle: string@bool-completer
  --includeQuality: string@bool-completer
  --replaceSpaces: string@bool-completer
  --separator: string
  --numberStyle: string
  --id: int # format: int32
  --resourceName: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "renameBooks" $renameBooks "scalar") (serialize-qp "replaceIllegalCharacters" $replaceIllegalCharacters "scalar") (serialize-qp "colonReplacementFormat" $colonReplacementFormat "scalar") (serialize-qp "standardBookFormat" $standardBookFormat "scalar") (serialize-qp "authorFolderFormat" $authorFolderFormat "scalar") (serialize-qp "includeAuthorName" $includeAuthorName "scalar") (serialize-qp "includeBookTitle" $includeBookTitle "scalar") (serialize-qp "includeQuality" $includeQuality "scalar") (serialize-qp "replaceSpaces" $replaceSpaces "scalar") (serialize-qp "separator" $separator "scalar") (serialize-qp "numberStyle" $numberStyle "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "resourceName" $resourceName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/config/naming/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/notification
export def "notification list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onReleaseImport: bool, onUpgrade: bool, onRename: bool, onAuthorAdded: bool, onAuthorDelete: bool, onBookDelete: bool, onBookFileDelete: bool, onBookFileDeleteForUpgrade: bool, onHealthIssue: bool, onDownloadFailure: bool, onImportFailure: bool, onBookRetag: bool, onApplicationUpdate: bool, supportsOnGrab: bool, supportsOnReleaseImport: bool, supportsOnUpgrade: bool, supportsOnRename: bool, supportsOnAuthorAdded: bool, supportsOnAuthorDelete: bool, supportsOnBookDelete: bool, supportsOnBookFileDelete: bool, supportsOnBookFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, supportsOnDownloadFailure: bool, supportsOnImportFailure: bool, supportsOnBookRetag: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/notification
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onReleaseImport: string@bool-completer
  --onUpgrade: string@bool-completer
  --onRename: string@bool-completer
  --onAuthorAdded: string@bool-completer
  --onAuthorDelete: string@bool-completer
  --onBookDelete: string@bool-completer
  --onBookFileDelete: string@bool-completer
  --onBookFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --onDownloadFailure: string@bool-completer
  --onImportFailure: string@bool-completer
  --onBookRetag: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnReleaseImport: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnAuthorAdded: string@bool-completer
  --supportsOnAuthorDelete: string@bool-completer
  --supportsOnBookDelete: string@bool-completer
  --supportsOnBookFileDelete: string@bool-completer
  --supportsOnBookFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --supportsOnDownloadFailure: string@bool-completer
  --supportsOnImportFailure: string@bool-completer
  --supportsOnBookRetag: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onReleaseImport: bool, onUpgrade: bool, onRename: bool, onAuthorAdded: bool, onAuthorDelete: bool, onBookDelete: bool, onBookFileDelete: bool, onBookFileDeleteForUpgrade: bool, onHealthIssue: bool, onDownloadFailure: bool, onImportFailure: bool, onBookRetag: bool, onApplicationUpdate: bool, supportsOnGrab: bool, supportsOnReleaseImport: bool, supportsOnUpgrade: bool, supportsOnRename: bool, supportsOnAuthorAdded: bool, supportsOnAuthorDelete: bool, supportsOnBookDelete: bool, supportsOnBookFileDelete: bool, supportsOnBookFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, supportsOnDownloadFailure: bool, supportsOnImportFailure: bool, supportsOnBookRetag: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notification" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onReleaseImport: $onReleaseImport, onUpgrade: $onUpgrade, onRename: $onRename, onAuthorAdded: $onAuthorAdded, onAuthorDelete: $onAuthorDelete, onBookDelete: $onBookDelete, onBookFileDelete: $onBookFileDelete, onBookFileDeleteForUpgrade: $onBookFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, onDownloadFailure: $onDownloadFailure, onImportFailure: $onImportFailure, onBookRetag: $onBookRetag, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, supportsOnReleaseImport: $supportsOnReleaseImport, supportsOnUpgrade: $supportsOnUpgrade, supportsOnRename: $supportsOnRename, supportsOnAuthorAdded: $supportsOnAuthorAdded, supportsOnAuthorDelete: $supportsOnAuthorDelete, supportsOnBookDelete: $supportsOnBookDelete, supportsOnBookFileDelete: $supportsOnBookFileDelete, supportsOnBookFileDeleteForUpgrade: $supportsOnBookFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, supportsOnDownloadFailure: $supportsOnDownloadFailure, supportsOnImportFailure: $supportsOnImportFailure, supportsOnBookRetag: $supportsOnBookRetag, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/notification/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
export def "notification put" [
  id: string
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onReleaseImport: string@bool-completer
  --onUpgrade: string@bool-completer
  --onRename: string@bool-completer
  --onAuthorAdded: string@bool-completer
  --onAuthorDelete: string@bool-completer
  --onBookDelete: string@bool-completer
  --onBookFileDelete: string@bool-completer
  --onBookFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --onDownloadFailure: string@bool-completer
  --onImportFailure: string@bool-completer
  --onBookRetag: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnReleaseImport: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnAuthorAdded: string@bool-completer
  --supportsOnAuthorDelete: string@bool-completer
  --supportsOnBookDelete: string@bool-completer
  --supportsOnBookFileDelete: string@bool-completer
  --supportsOnBookFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --supportsOnDownloadFailure: string@bool-completer
  --supportsOnImportFailure: string@bool-completer
  --supportsOnBookRetag: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onReleaseImport: bool, onUpgrade: bool, onRename: bool, onAuthorAdded: bool, onAuthorDelete: bool, onBookDelete: bool, onBookFileDelete: bool, onBookFileDeleteForUpgrade: bool, onHealthIssue: bool, onDownloadFailure: bool, onImportFailure: bool, onBookRetag: bool, onApplicationUpdate: bool, supportsOnGrab: bool, supportsOnReleaseImport: bool, supportsOnUpgrade: bool, supportsOnRename: bool, supportsOnAuthorAdded: bool, supportsOnAuthorDelete: bool, supportsOnBookDelete: bool, supportsOnBookFileDelete: bool, supportsOnBookFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, supportsOnDownloadFailure: bool, supportsOnImportFailure: bool, supportsOnBookRetag: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/notification/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onReleaseImport: $onReleaseImport, onUpgrade: $onUpgrade, onRename: $onRename, onAuthorAdded: $onAuthorAdded, onAuthorDelete: $onAuthorDelete, onBookDelete: $onBookDelete, onBookFileDelete: $onBookFileDelete, onBookFileDeleteForUpgrade: $onBookFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, onDownloadFailure: $onDownloadFailure, onImportFailure: $onImportFailure, onBookRetag: $onBookRetag, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, supportsOnReleaseImport: $supportsOnReleaseImport, supportsOnUpgrade: $supportsOnUpgrade, supportsOnRename: $supportsOnRename, supportsOnAuthorAdded: $supportsOnAuthorAdded, supportsOnAuthorDelete: $supportsOnAuthorDelete, supportsOnBookDelete: $supportsOnBookDelete, supportsOnBookFileDelete: $supportsOnBookFileDelete, supportsOnBookFileDeleteForUpgrade: $supportsOnBookFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, supportsOnDownloadFailure: $supportsOnDownloadFailure, supportsOnImportFailure: $supportsOnImportFailure, supportsOnBookRetag: $supportsOnBookRetag, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/notification/{id}
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
  let full_url = (build-url $base $"/api/v1/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/notification/{id}
export def "notification get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onReleaseImport: bool, onUpgrade: bool, onRename: bool, onAuthorAdded: bool, onAuthorDelete: bool, onBookDelete: bool, onBookFileDelete: bool, onBookFileDeleteForUpgrade: bool, onHealthIssue: bool, onDownloadFailure: bool, onImportFailure: bool, onBookRetag: bool, onApplicationUpdate: bool, supportsOnGrab: bool, supportsOnReleaseImport: bool, supportsOnUpgrade: bool, supportsOnRename: bool, supportsOnAuthorAdded: bool, supportsOnAuthorDelete: bool, supportsOnBookDelete: bool, supportsOnBookFileDelete: bool, supportsOnBookFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, supportsOnDownloadFailure: bool, supportsOnImportFailure: bool, supportsOnBookRetag: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/notification/schema
export def "notification-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onReleaseImport: bool, onUpgrade: bool, onRename: bool, onAuthorAdded: bool, onAuthorDelete: bool, onBookDelete: bool, onBookFileDelete: bool, onBookFileDeleteForUpgrade: bool, onHealthIssue: bool, onDownloadFailure: bool, onImportFailure: bool, onBookRetag: bool, onApplicationUpdate: bool, supportsOnGrab: bool, supportsOnReleaseImport: bool, supportsOnUpgrade: bool, supportsOnRename: bool, supportsOnAuthorAdded: bool, supportsOnAuthorDelete: bool, supportsOnBookDelete: bool, supportsOnBookFileDelete: bool, supportsOnBookFileDeleteForUpgrade: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, supportsOnDownloadFailure: bool, supportsOnImportFailure: bool, supportsOnBookRetag: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notification/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/notification/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onReleaseImport: string@bool-completer
  --onUpgrade: string@bool-completer
  --onRename: string@bool-completer
  --onAuthorAdded: string@bool-completer
  --onAuthorDelete: string@bool-completer
  --onBookDelete: string@bool-completer
  --onBookFileDelete: string@bool-completer
  --onBookFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --onDownloadFailure: string@bool-completer
  --onImportFailure: string@bool-completer
  --onBookRetag: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnReleaseImport: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnAuthorAdded: string@bool-completer
  --supportsOnAuthorDelete: string@bool-completer
  --supportsOnBookDelete: string@bool-completer
  --supportsOnBookFileDelete: string@bool-completer
  --supportsOnBookFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --supportsOnDownloadFailure: string@bool-completer
  --supportsOnImportFailure: string@bool-completer
  --supportsOnBookRetag: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notification/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onReleaseImport: $onReleaseImport, onUpgrade: $onUpgrade, onRename: $onRename, onAuthorAdded: $onAuthorAdded, onAuthorDelete: $onAuthorDelete, onBookDelete: $onBookDelete, onBookFileDelete: $onBookFileDelete, onBookFileDeleteForUpgrade: $onBookFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, onDownloadFailure: $onDownloadFailure, onImportFailure: $onImportFailure, onBookRetag: $onBookRetag, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, supportsOnReleaseImport: $supportsOnReleaseImport, supportsOnUpgrade: $supportsOnUpgrade, supportsOnRename: $supportsOnRename, supportsOnAuthorAdded: $supportsOnAuthorAdded, supportsOnAuthorDelete: $supportsOnAuthorDelete, supportsOnBookDelete: $supportsOnBookDelete, supportsOnBookFileDelete: $supportsOnBookFileDelete, supportsOnBookFileDeleteForUpgrade: $supportsOnBookFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, supportsOnDownloadFailure: $supportsOnDownloadFailure, supportsOnImportFailure: $supportsOnImportFailure, supportsOnBookRetag: $supportsOnBookRetag, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/notification/testall
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
  let full_url = (build-url $base "/api/v1/notification/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/notification/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
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
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onReleaseImport?: bool, onUpgrade?: bool, onRename?: bool, onAuthorAdded?: bool, onAuthorDelete?: bool, onBookDelete?: bool, onBookFileDelete?: bool, onBookFileDeleteForUpgrade?: bool, onHealthIssue?: bool, onDownloadFailure?: bool, onImportFailure?: bool, onBookRetag?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, supportsOnReleaseImport?: bool, supportsOnUpgrade?: bool, supportsOnRename?: bool, supportsOnAuthorAdded?: bool, supportsOnAuthorDelete?: bool, supportsOnBookDelete?: bool, supportsOnBookFileDelete?: bool, supportsOnBookFileDeleteForUpgrade?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, supportsOnDownloadFailure?: bool, supportsOnImportFailure?: bool, supportsOnBookRetag?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: string@bool-completer
  --onReleaseImport: string@bool-completer
  --onUpgrade: string@bool-completer
  --onRename: string@bool-completer
  --onAuthorAdded: string@bool-completer
  --onAuthorDelete: string@bool-completer
  --onBookDelete: string@bool-completer
  --onBookFileDelete: string@bool-completer
  --onBookFileDeleteForUpgrade: string@bool-completer
  --onHealthIssue: string@bool-completer
  --onDownloadFailure: string@bool-completer
  --onImportFailure: string@bool-completer
  --onBookRetag: string@bool-completer
  --onApplicationUpdate: string@bool-completer
  --supportsOnGrab: string@bool-completer
  --supportsOnReleaseImport: string@bool-completer
  --supportsOnUpgrade: string@bool-completer
  --supportsOnRename: string@bool-completer
  --supportsOnAuthorAdded: string@bool-completer
  --supportsOnAuthorDelete: string@bool-completer
  --supportsOnBookDelete: string@bool-completer
  --supportsOnBookFileDelete: string@bool-completer
  --supportsOnBookFileDeleteForUpgrade: string@bool-completer
  --supportsOnHealthIssue: string@bool-completer
  --includeHealthWarnings: string@bool-completer
  --supportsOnDownloadFailure: string@bool-completer
  --supportsOnImportFailure: string@bool-completer
  --supportsOnBookRetag: string@bool-completer
  --supportsOnApplicationUpdate: string@bool-completer
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notification/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onReleaseImport: $onReleaseImport, onUpgrade: $onUpgrade, onRename: $onRename, onAuthorAdded: $onAuthorAdded, onAuthorDelete: $onAuthorDelete, onBookDelete: $onBookDelete, onBookFileDelete: $onBookFileDelete, onBookFileDeleteForUpgrade: $onBookFileDeleteForUpgrade, onHealthIssue: $onHealthIssue, onDownloadFailure: $onDownloadFailure, onImportFailure: $onImportFailure, onBookRetag: $onBookRetag, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, supportsOnReleaseImport: $supportsOnReleaseImport, supportsOnUpgrade: $supportsOnUpgrade, supportsOnRename: $supportsOnRename, supportsOnAuthorAdded: $supportsOnAuthorAdded, supportsOnAuthorDelete: $supportsOnAuthorDelete, supportsOnBookDelete: $supportsOnBookDelete, supportsOnBookFileDelete: $supportsOnBookFileDelete, supportsOnBookFileDeleteForUpgrade: $supportsOnBookFileDeleteForUpgrade, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, supportsOnDownloadFailure: $supportsOnDownloadFailure, supportsOnImportFailure: $supportsOnImportFailure, supportsOnBookRetag: $supportsOnBookRetag, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/parse
export def "parse get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --title: string
]: nothing -> record<id: int, title: string, parsedBookInfo: record<bookTitle: string, authorName: string, authorTitleInfo: record<title: string, titleWithoutYear: string, year: int>, quality: record<quality: record, revision: record>, releaseDate: string, discography: bool, discographyStart: int, discographyEnd: int, releaseGroup: string, releaseHash: string, releaseVersion: string, releaseTitle: string>, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list<record>, nextBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, lastBook: record<id: int, authorMetadataId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, title: string, releaseDate: string, links: list, genres: list, relatedBooks: list, ratings: record, lastSearchTime: string, cleanTitle: string, monitored: bool, anyEditionOk: bool, lastInfoSync: string, added: string, addOptions: record, authorMetadata: record, author: record, editions: record, bookFiles: record, seriesLinks: record>, images: list<record>, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list<string>, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list<int>, added: string, addOptions: record<monitor: string, booksToMonitor: list, monitored: bool, searchForMissingBooks: bool>, ratings: record<votes: int, value: float, popularity: float>, statistics: record<bookFileCount: int, bookCount: int, availableBookCount: int, totalBookCount: int, sizeOnDisk: int, percentOfBooks: float>>, books: table<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/parse" $qp)
  let accept_val = ($accept | default "text/plain")
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

# PUT /api/v1/qualitydefinition/{id}
#
# --quality shape: {id?: int, name?: string}
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
  --quality: record # shape: {id?: int, name?: string}
  --title: string # nullable
  --weight: int # format: int32
  --minSize: float # nullable, format: double
  --maxSize: float # nullable, format: double
]: any -> record<id: int, quality: record<id: int, name: string>, title: string, weight: int, minSize: float, maxSize: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/qualitydefinition/($id)")
  let body = {id: $body_id, quality: $quality, title: $title, weight: $weight, minSize: $minSize, maxSize: $maxSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/qualitydefinition/{id}
export def "qualitydefinition get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, quality: record<id: int, name: string>, title: string, weight: int, minSize: float, maxSize: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/qualitydefinition/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/qualitydefinition
export def "qualitydefinition list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, quality: record<id: int, name: string>, title: string, weight: int, minSize: float, maxSize: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/qualitydefinition")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/qualitydefinition/update
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
  let full_url = (build-url $base "/api/v1/qualitydefinition/update")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/qualityprofile
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
  --formatItems: list # nullable — item shape: {id?: int, format?: int, name?: string, score?: int}
]: any -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/qualityprofile")
  let body = {id: $id, name: $name, upgradeAllowed: $upgradeAllowed, cutoff: $cutoff, items: $items, minFormatScore: $minFormatScore, cutoffFormatScore: $cutoffFormatScore, formatItems: $formatItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/qualityprofile
export def "qualityprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: list<record>, minFormatScore: int, cutoffFormatScore: int, formatItems: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/qualityprofile")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/qualityprofile/{id}
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
  let full_url = (build-url $base $"/api/v1/qualityprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/qualityprofile/{id}
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
  --formatItems: list # nullable — item shape: {id?: int, format?: int, name?: string, score?: int}
]: any -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/qualityprofile/($id)")
  let body = {id: $body_id, name: $name, upgradeAllowed: $upgradeAllowed, cutoff: $cutoff, items: $items, minFormatScore: $minFormatScore, cutoffFormatScore: $cutoffFormatScore, formatItems: $formatItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/qualityprofile/{id}
export def "qualityprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/qualityprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/qualityprofile/schema
export def "qualityprofile-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, name: string, upgradeAllowed: bool, cutoff: int, items: table<id: int, name: string, quality: record, items: list, allowed: bool>, minFormatScore: int, cutoffFormatScore: int, formatItems: table<id: int, format: int, name: string, score: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/qualityprofile/schema")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/queue/{id}
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
  let full_url = (build-url $base $"/api/v1/queue/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/queue/bulk
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
  let full_url = (build-url $base "/api/v1/queue/bulk" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/queue
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
  --sortDirection: string@sortDirection-completer
  --includeUnknownAuthorItems: string@bool-completer # default: false
  --includeAuthor: string@bool-completer # default: false
  --includeBook: string@bool-completer # default: false
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, authorId: int, bookId: int, author: record, book: record, quality: record, customFormats: list, customFormatScore: int, size: float, title: string, sizeleft: float, timeleft: string, estimatedCompletionTime: string, status: string, trackedDownloadStatus: string, trackedDownloadState: string, statusMessages: list, errorMessage: string, downloadId: string, protocol: string, downloadClient: string, downloadClientHasPostImportCategory: bool, indexer: string, outputPath: string, downloadForced: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "includeUnknownAuthorItems" $includeUnknownAuthorItems "scalar") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "includeBook" $includeBook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/queue/grab/{id}
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
  let full_url = (build-url $base $"/api/v1/queue/grab/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/queue/grab/bulk
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
  let full_url = (build-url $base "/api/v1/queue/grab/bulk")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/queue/details
export def "queue-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
  --bookIds: list
  --includeAuthor: string@bool-completer # default: false
  --includeBook: string@bool-completer # default: true
]: nothing -> table<id: int, authorId: int, bookId: int, author: record<id: int, authorMetadataId: int, status: string, ended: bool, authorName: string, authorNameLastFirst: string, foreignAuthorId: string, titleSlug: string, overview: string, disambiguation: string, links: list, nextBook: record, lastBook: record, images: list, remotePoster: string, path: string, qualityProfileId: int, metadataProfileId: int, monitored: bool, monitorNewItems: string, rootFolderPath: string, folder: string, genres: list, cleanName: string, sortName: string, sortNameLastFirst: string, tags: list, added: string, addOptions: record, ratings: record, statistics: record>, book: record<id: int, title: string, authorTitle: string, seriesTitle: string, disambiguation: string, overview: string, authorId: int, foreignBookId: string, foreignEditionId: string, titleSlug: string, monitored: bool, anyEditionOk: bool, ratings: record, releaseDate: string, pageCount: int, genres: list, author: record, images: list, links: list, statistics: record, added: string, addOptions: record, remoteCover: string, lastSearchTime: string, editions: list>, quality: record<quality: record, revision: record>, customFormats: list<record>, customFormatScore: int, size: float, title: string, sizeleft: float, timeleft: string, estimatedCompletionTime: string, status: string, trackedDownloadStatus: string, trackedDownloadState: string, statusMessages: list<record>, errorMessage: string, downloadId: string, protocol: string, downloadClient: string, downloadClientHasPostImportCategory: bool, indexer: string, outputPath: string, downloadForced: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar") (serialize-qp "bookIds" $bookIds "multi") (serialize-qp "includeAuthor" $includeAuthor "scalar") (serialize-qp "includeBook" $includeBook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/queue/details" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/queue/status
export def "queue-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, totalCount: int, count: int, unknownCount: int, errors: bool, warnings: bool, unknownErrors: bool, unknownWarnings: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/queue/status")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/release
#
# --quality shape: {quality?: record, revision?: record}
# --customFormats item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
export def "release post" [
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
  --discography: string@bool-completer
  --sceneSource: string@bool-completer
  --airDate: string # nullable
  --authorName: string # nullable
  --bookTitle: string # nullable
  --approved: string@bool-completer
  --temporarilyRejected: string@bool-completer
  --rejected: string@bool-completer
  --rejections: list # nullable
  --publishDate: string # format: date-time
  --commentUrl: string # nullable
  --downloadUrl: string # nullable
  --infoUrl: string # nullable
  --downloadAllowed: string@bool-completer
  --releaseWeight: int # format: int32
  --customFormats: list # nullable — item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
  --customFormatScore: int # format: int32
  --magnetUrl: string # nullable
  --infoHash: string # nullable
  --seeders: int # nullable, format: int32
  --leechers: int # nullable, format: int32
  --protocol: string@protocol-completer
  --indexerFlags: int # format: int32
  --authorId: int # nullable, format: int32
  --bookId: int # nullable, format: int32
  --downloadClientId: int # nullable, format: int32
  --downloadClient: string # nullable
]: any -> record<id: int, guid: string, quality: record<quality: record<id: int, name: string>, revision: record<version: int, real: int, isRepack: bool>>, qualityWeight: int, age: int, ageHours: float, ageMinutes: float, size: int, indexerId: int, indexer: string, releaseGroup: string, subGroup: string, releaseHash: string, title: string, discography: bool, sceneSource: bool, airDate: string, authorName: string, bookTitle: string, approved: bool, temporarilyRejected: bool, rejected: bool, rejections: list<string>, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, downloadAllowed: bool, releaseWeight: int, customFormats: table<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: list>, customFormatScore: int, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, indexerFlags: int, authorId: int, bookId: int, downloadClientId: int, downloadClient: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/release")
  let body = {id: $id, guid: $guid, quality: $quality, qualityWeight: $qualityWeight, age: $age, ageHours: $ageHours, ageMinutes: $ageMinutes, size: $size, indexerId: $indexerId, indexer: $indexer, releaseGroup: $releaseGroup, subGroup: $subGroup, releaseHash: $releaseHash, title: $title, discography: $discography, sceneSource: $sceneSource, airDate: $airDate, authorName: $authorName, bookTitle: $bookTitle, approved: $approved, temporarilyRejected: $temporarilyRejected, rejected: $rejected, rejections: $rejections, publishDate: $publishDate, commentUrl: $commentUrl, downloadUrl: $downloadUrl, infoUrl: $infoUrl, downloadAllowed: $downloadAllowed, releaseWeight: $releaseWeight, customFormats: $customFormats, customFormatScore: $customFormatScore, magnetUrl: $magnetUrl, infoHash: $infoHash, seeders: $seeders, leechers: $leechers, protocol: $protocol, indexerFlags: $indexerFlags, authorId: $authorId, bookId: $bookId, downloadClientId: $downloadClientId, downloadClient: $downloadClient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/release
export def "release get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --bookId: int # format: int32
  --authorId: int # format: int32
]: nothing -> table<id: int, guid: string, quality: record<quality: record, revision: record>, qualityWeight: int, age: int, ageHours: float, ageMinutes: float, size: int, indexerId: int, indexer: string, releaseGroup: string, subGroup: string, releaseHash: string, title: string, discography: bool, sceneSource: bool, airDate: string, authorName: string, bookTitle: string, approved: bool, temporarilyRejected: bool, rejected: bool, rejections: list<string>, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, downloadAllowed: bool, releaseWeight: int, customFormats: list<record>, customFormatScore: int, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, indexerFlags: int, authorId: int, bookId: int, downloadClientId: int, downloadClient: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookId" $bookId "scalar") (serialize-qp "authorId" $authorId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/release" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/releaseprofile
export def "releaseprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, enabled: bool, required: list<string>, ignored: list<string>, indexerId: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/releaseprofile")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/releaseprofile
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
  --enabled: string@bool-completer
  --required: list # nullable
  --ignored: list # nullable
  --indexerId: int # format: int32
  --tags: list # nullable
]: any -> record<id: int, enabled: bool, required: list<string>, ignored: list<string>, indexerId: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/releaseprofile")
  let body = {id: $id, enabled: $enabled, required: $required, ignored: $ignored, indexerId: $indexerId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/releaseprofile/{id}
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
  --enabled: string@bool-completer
  --required: list # nullable
  --ignored: list # nullable
  --indexerId: int # format: int32
  --tags: list # nullable
]: any -> record<id: int, enabled: bool, required: list<string>, ignored: list<string>, indexerId: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/releaseprofile/($id)")
  let body = {id: $body_id, enabled: $enabled, required: $required, ignored: $ignored, indexerId: $indexerId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/releaseprofile/{id}
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
  let full_url = (build-url $base $"/api/v1/releaseprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/releaseprofile/{id}
export def "releaseprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, enabled: bool, required: list<string>, ignored: list<string>, indexerId: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/releaseprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/release/push
#
# --quality shape: {quality?: record, revision?: record}
# --customFormats item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
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
  --discography: string@bool-completer
  --sceneSource: string@bool-completer
  --airDate: string # nullable
  --authorName: string # nullable
  --bookTitle: string # nullable
  --approved: string@bool-completer
  --temporarilyRejected: string@bool-completer
  --rejected: string@bool-completer
  --rejections: list # nullable
  --publishDate: string # format: date-time
  --commentUrl: string # nullable
  --downloadUrl: string # nullable
  --infoUrl: string # nullable
  --downloadAllowed: string@bool-completer
  --releaseWeight: int # format: int32
  --customFormats: list # nullable — item shape: {id?: int, name?: string, includeCustomFormatWhenRenaming?: bool, specifications?: list}
  --customFormatScore: int # format: int32
  --magnetUrl: string # nullable
  --infoHash: string # nullable
  --seeders: int # nullable, format: int32
  --leechers: int # nullable, format: int32
  --protocol: string@protocol-completer
  --indexerFlags: int # format: int32
  --authorId: int # nullable, format: int32
  --bookId: int # nullable, format: int32
  --downloadClientId: int # nullable, format: int32
  --downloadClient: string # nullable
]: any -> record<id: int, guid: string, quality: record<quality: record<id: int, name: string>, revision: record<version: int, real: int, isRepack: bool>>, qualityWeight: int, age: int, ageHours: float, ageMinutes: float, size: int, indexerId: int, indexer: string, releaseGroup: string, subGroup: string, releaseHash: string, title: string, discography: bool, sceneSource: bool, airDate: string, authorName: string, bookTitle: string, approved: bool, temporarilyRejected: bool, rejected: bool, rejections: list<string>, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, downloadAllowed: bool, releaseWeight: int, customFormats: table<id: int, name: string, includeCustomFormatWhenRenaming: bool, specifications: list>, customFormatScore: int, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, indexerFlags: int, authorId: int, bookId: int, downloadClientId: int, downloadClient: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/release/push")
  let body = {id: $id, guid: $guid, quality: $quality, qualityWeight: $qualityWeight, age: $age, ageHours: $ageHours, ageMinutes: $ageMinutes, size: $size, indexerId: $indexerId, indexer: $indexer, releaseGroup: $releaseGroup, subGroup: $subGroup, releaseHash: $releaseHash, title: $title, discography: $discography, sceneSource: $sceneSource, airDate: $airDate, authorName: $authorName, bookTitle: $bookTitle, approved: $approved, temporarilyRejected: $temporarilyRejected, rejected: $rejected, rejections: $rejections, publishDate: $publishDate, commentUrl: $commentUrl, downloadUrl: $downloadUrl, infoUrl: $infoUrl, downloadAllowed: $downloadAllowed, releaseWeight: $releaseWeight, customFormats: $customFormats, customFormatScore: $customFormatScore, magnetUrl: $magnetUrl, infoHash: $infoHash, seeders: $seeders, leechers: $leechers, protocol: $protocol, indexerFlags: $indexerFlags, authorId: $authorId, bookId: $bookId, downloadClientId: $downloadClientId, downloadClient: $downloadClient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/remotepathmapping
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
  let full_url = (build-url $base "/api/v1/remotepathmapping")
  let body = {id: $id, host: $host, remotePath: $remotePath, localPath: $localPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/remotepathmapping
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
  let full_url = (build-url $base "/api/v1/remotepathmapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/remotepathmapping/{id}
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
  let full_url = (build-url $base $"/api/v1/remotepathmapping/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/remotepathmapping/{id}
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
  let full_url = (build-url $base $"/api/v1/remotepathmapping/($id)")
  let body = {id: $body_id, host: $host, remotePath: $remotePath, localPath: $localPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/remotepathmapping/{id}
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
  let full_url = (build-url $base $"/api/v1/remotepathmapping/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/rename
export def "rename get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
  --bookId: int # format: int32
]: nothing -> table<id: int, authorId: int, bookId: int, bookFileId: int, existingPath: string, newPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar") (serialize-qp "bookId" $bookId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/rename" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/retag
export def "retag get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
  --bookId: int # format: int32
]: nothing -> table<id: int, authorId: int, bookId: int, trackNumbers: list<int>, bookFileId: int, path: string, changes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar") (serialize-qp "bookId" $bookId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/retag" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/rootfolder
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
  --name: string # nullable
  --path: string # nullable
  --defaultMetadataProfileId: int # format: int32
  --defaultQualityProfileId: int # format: int32
  --defaultMonitorOption: string@defaultMonitorOption-completer
  --defaultNewItemMonitorOption: string@defaultNewItemMonitorOption-completer
  --defaultTags: list # nullable
  --isCalibreLibrary: string@bool-completer
  --host: string # nullable
  --port: int # format: int32
  --urlBase: string # nullable
  --username: string # nullable
  --password: string # nullable
  --library: string # nullable
  --outputFormat: string # nullable
  --outputProfile: string # nullable
  --useSsl: string@bool-completer
  --accessible: string@bool-completer
  --freeSpace: int # nullable, format: int64
  --totalSpace: int # nullable, format: int64
]: any -> record<id: int, name: string, path: string, defaultMetadataProfileId: int, defaultQualityProfileId: int, defaultMonitorOption: string, defaultNewItemMonitorOption: string, defaultTags: list<int>, isCalibreLibrary: bool, host: string, port: int, urlBase: string, username: string, password: string, library: string, outputFormat: string, outputProfile: string, useSsl: bool, accessible: bool, freeSpace: int, totalSpace: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/rootfolder")
  let body = {id: $id, name: $name, path: $path, defaultMetadataProfileId: $defaultMetadataProfileId, defaultQualityProfileId: $defaultQualityProfileId, defaultMonitorOption: $defaultMonitorOption, defaultNewItemMonitorOption: $defaultNewItemMonitorOption, defaultTags: $defaultTags, isCalibreLibrary: $isCalibreLibrary, host: $host, port: $port, urlBase: $urlBase, username: $username, password: $password, library: $library, outputFormat: $outputFormat, outputProfile: $outputProfile, useSsl: $useSsl, accessible: $accessible, freeSpace: $freeSpace, totalSpace: $totalSpace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/rootfolder
export def "rootfolder list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, name: string, path: string, defaultMetadataProfileId: int, defaultQualityProfileId: int, defaultMonitorOption: string, defaultNewItemMonitorOption: string, defaultTags: list<int>, isCalibreLibrary: bool, host: string, port: int, urlBase: string, username: string, password: string, library: string, outputFormat: string, outputProfile: string, useSsl: bool, accessible: bool, freeSpace: int, totalSpace: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/rootfolder")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/rootfolder/{id}
export def "rootfolder put" [
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
  --path: string # nullable
  --defaultMetadataProfileId: int # format: int32
  --defaultQualityProfileId: int # format: int32
  --defaultMonitorOption: string@defaultMonitorOption-completer
  --defaultNewItemMonitorOption: string@defaultNewItemMonitorOption-completer
  --defaultTags: list # nullable
  --isCalibreLibrary: string@bool-completer
  --host: string # nullable
  --port: int # format: int32
  --urlBase: string # nullable
  --username: string # nullable
  --password: string # nullable
  --library: string # nullable
  --outputFormat: string # nullable
  --outputProfile: string # nullable
  --useSsl: string@bool-completer
  --accessible: string@bool-completer
  --freeSpace: int # nullable, format: int64
  --totalSpace: int # nullable, format: int64
]: any -> record<id: int, name: string, path: string, defaultMetadataProfileId: int, defaultQualityProfileId: int, defaultMonitorOption: string, defaultNewItemMonitorOption: string, defaultTags: list<int>, isCalibreLibrary: bool, host: string, port: int, urlBase: string, username: string, password: string, library: string, outputFormat: string, outputProfile: string, useSsl: bool, accessible: bool, freeSpace: int, totalSpace: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rootfolder/($id)")
  let body = {id: $body_id, name: $name, path: $path, defaultMetadataProfileId: $defaultMetadataProfileId, defaultQualityProfileId: $defaultQualityProfileId, defaultMonitorOption: $defaultMonitorOption, defaultNewItemMonitorOption: $defaultNewItemMonitorOption, defaultTags: $defaultTags, isCalibreLibrary: $isCalibreLibrary, host: $host, port: $port, urlBase: $urlBase, username: $username, password: $password, library: $library, outputFormat: $outputFormat, outputProfile: $outputProfile, useSsl: $useSsl, accessible: $accessible, freeSpace: $freeSpace, totalSpace: $totalSpace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/rootfolder/{id}
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
  let full_url = (build-url $base $"/api/v1/rootfolder/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/rootfolder/{id}
export def "rootfolder get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, path: string, defaultMetadataProfileId: int, defaultQualityProfileId: int, defaultMonitorOption: string, defaultNewItemMonitorOption: string, defaultTags: list<int>, isCalibreLibrary: bool, host: string, port: int, urlBase: string, username: string, password: string, library: string, outputFormat: string, outputProfile: string, useSsl: bool, accessible: bool, freeSpace: int, totalSpace: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rootfolder/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/series
export def "series get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --authorId: int # format: int32
]: nothing -> table<id: int, title: string, description: string, links: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorId" $authorId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/series" $qp)
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

# GET /api/v1/system/status
export def "system-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<appName: string, instanceName: string, version: string, buildTime: string, isDebug: bool, isProduction: bool, isAdmin: bool, isUserInteractive: bool, startupPath: string, appData: string, osName: string, osVersion: string, isNetCore: bool, isLinux: bool, isOsx: bool, isWindows: bool, isDocker: bool, mode: string, branch: string, databaseType: string, databaseVersion: string, authentication: string, migrationVersion: int, urlBase: string, runtimeVersion: string, runtimeName: string, startTime: string, packageVersion: string, packageAuthor: string, packageUpdateMechanism: string, packageUpdateMechanismMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/status")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/routes
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
  let full_url = (build-url $base "/api/v1/system/routes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/routes/duplicate
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
  let full_url = (build-url $base "/api/v1/system/routes/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/shutdown
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
  let full_url = (build-url $base "/api/v1/system/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/restart
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
  let full_url = (build-url $base "/api/v1/system/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag
export def "tag list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tag")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/tag
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
  let full_url = (build-url $base "/api/v1/tag")
  let body = {id: $id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/tag/{id}
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
  let full_url = (build-url $base $"/api/v1/tag/($id)")
  let body = {id: $body_id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/tag/{id}
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
  let full_url = (build-url $base $"/api/v1/tag/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag/{id}
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
  let full_url = (build-url $base $"/api/v1/tag/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag/detail
export def "tag-detail list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, label: string, delayProfileIds: list<int>, importListIds: list<int>, notificationIds: list<int>, restrictionIds: list<int>, indexerIds: list<int>, downloadClientIds: list<int>, authorIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tag/detail")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag/detail/{id}
export def "tag-detail get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, label: string, delayProfileIds: list<int>, importListIds: list<int>, notificationIds: list<int>, restrictionIds: list<int>, indexerIds: list<int>, downloadClientIds: list<int>, authorIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tag/detail/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/task
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
  let full_url = (build-url $base "/api/v1/system/task")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/task/{id}
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
  let full_url = (build-url $base $"/api/v1/system/task/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/ui/{id}
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
  --uiLanguage: int # format: int32
  --theme: string # nullable
]: any -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, uiLanguage: int, theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/ui/($id)")
  let body = {id: $body_id, firstDayOfWeek: $firstDayOfWeek, calendarWeekColumnHeader: $calendarWeekColumnHeader, shortDateFormat: $shortDateFormat, longDateFormat: $longDateFormat, timeFormat: $timeFormat, showRelativeDates: $showRelativeDates, enableColorImpairedMode: $enableColorImpairedMode, uiLanguage: $uiLanguage, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/ui/{id}
export def "config-ui get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, uiLanguage: int, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/ui/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/ui
export def "config-ui list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, uiLanguage: int, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/ui")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/update
export def "update get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, version: string, branch: string, releaseDate: string, fileName: string, url: string, installed: bool, installedOn: string, installable: bool, latest: bool, changes: record<new: list, fixed: list>, hash: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/update")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file/update
export def "log-file-update list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, filename: string, lastWriteTime: string, contentsUrl: string, downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/log/file/update")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file/update/{filename}
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
  let full_url = (build-url $base $"/api/v1/log/file/update/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
