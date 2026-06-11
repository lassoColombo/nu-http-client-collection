# Auto-generated client for STAPI v0.1.4
# Source: https://stapi.co/api/v1/rest/common/download/stapi.yaml
# Auth: --token flag or $env.STAPI_TOKEN

const BASE_URL = "https://stapi.co/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STAPI_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def base-url-completer [] { ["https://stapi.co/api" "http://stapi.co/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-animal v1GetAnimal" } } | get name | first)
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

# Retrieval of a single animal
#
# GET /v1/rest/animal
# operationId: v1GetAnimal
export def "rest-animal v1GetAnimal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Animal unique ID
]: nothing -> record<animal: record<uid: string, name: string, earthAnimal: bool, earthInsect: bool, avian: bool, canine: bool, feline: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/animal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over animals
#
# GET /v1/rest/animal/search
# operationId: v1PageAnimals
export def "rest-animal-search v1PageAnimals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, animals: table<uid: string, name: string, earthAnimal: bool, earthInsect: bool, avian: bool, canine: bool, feline: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/animal/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching animals
#
# POST /v1/rest/animal/search
# operationId: v1SearchAnimals
export def "rest-animal-search v1SearchAnimals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Animal name
  --earthAnimal: string@bool-completer # Whether it should be an earth animal
  --earthInsect: string@bool-completer # Whether it should be an earth insect
  --avian: string@bool-completer # Whether it should be an avian
  --canine: string@bool-completer # Whether it should be a canine
  --feline: string@bool-completer # Whether it should be a feline
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, animals: table<uid: string, name: string, earthAnimal: bool, earthInsect: bool, avian: bool, canine: bool, feline: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/animal/search" $qp)
  let body = {name: $name, earthAnimal: $earthAnimal, earthInsect: $earthInsect, avian: $avian, canine: $canine, feline: $feline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single astronomical object
#
# GET /v1/rest/astronomicalObject
# DEPRECATED
# operationId: v1GetAstronomicalObject
@deprecated
export def "rest-astronomical-object v1GetAstronomicalObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Astronomical object's unique ID
]: nothing -> record<astronomicalObject: record<uid: string, name: string, astronomicalObjectType: string, location: record<uid: string, name: string, astronomicalObjectType: string, location: record>, astronomicalObjects: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/astronomicalObject" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over astronomical objects
#
# GET /v1/rest/astronomicalObject/search
# DEPRECATED
# operationId: v1PageAstronomicalObjects
@deprecated
export def "rest-astronomical-object-search v1PageAstronomicalObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, astronomicalObjects: table<uid: string, name: string, astronomicalObjectType: string, location: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/astronomicalObject/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching astronomical objects
#
# POST /v1/rest/astronomicalObject/search
# DEPRECATED
# operationId: v1SearchAstronomicalObjects
@deprecated
export def "rest-astronomical-object-search v1SearchAstronomicalObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Astronomical object name
  --astronomicalObjectType: string # Type of astronomical object
  --locationUid: string # Unique ID of astronomical object containing objects being searched
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, astronomicalObjects: table<uid: string, name: string, astronomicalObjectType: string, location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/astronomicalObject/search" $qp)
  let body = {name: $name, astronomicalObjectType: $astronomicalObjectType, locationUid: $locationUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single astronomical object (V2)
#
# GET /v2/rest/astronomicalObject
# operationId: v2GetAstronomicalObject
export def "rest-astronomical-object v2GetAstronomicalObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Astronomical object's unique ID
]: nothing -> record<astronomicalObject: record<uid: string, name: string, astronomicalObjectType: string, location: record<uid: string, name: string, astronomicalObjectType: string, location: record>, astronomicalObjects: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/astronomicalObject" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over astronomical objects (V2)
#
# GET /v2/rest/astronomicalObject/search
# operationId: v2PageAstronomicalObjects
export def "rest-astronomical-object-search v2PageAstronomicalObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, astronomicalObjects: table<uid: string, name: string, astronomicalObjectType: string, location: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/astronomicalObject/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching astronomical objects (v2)
#
# POST /v2/rest/astronomicalObject/search
# operationId: v2SearchAstronomicalObjects
export def "rest-astronomical-object-search v2SearchAstronomicalObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Astronomical object name
  --astronomicalObjectType: string # Type of astronomical object
  --locationUid: string # Unique ID of astronomical object containing objects being searched
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, astronomicalObjects: table<uid: string, name: string, astronomicalObjectType: string, location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/astronomicalObject/search" $qp)
  let body = {name: $name, astronomicalObjectType: $astronomicalObjectType, locationUid: $locationUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single book
#
# GET /v1/rest/book
# DEPRECATED
# operationId: v1GetBook
@deprecated
export def "rest-book v1GetBook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Book unique ID
]: nothing -> record<book: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, novel: bool, referenceBook: bool, biographyBook: bool, rolePlayingBook: bool, ebook: bool, anthology: bool, novelization: bool, audiobook: bool, audiobookAbridged: bool, audiobookPublishedYear: int, audiobookPublishedMonth: int, audiobookPublishedDay: int, audiobookRunTime: int, productionNumber: string, bookSeries: list<record>, authors: list<record>, artists: list<record>, editors: list<record>, audiobookNarrators: list<record>, publishers: list<record>, audiobookPublishers: list<record>, characters: list<record>, references: list<record>, audiobookReferences: list<record>, bookCollections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/book" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over books
#
# GET /v1/rest/book/search
# DEPRECATED
# operationId: v1PageBooks
@deprecated
export def "rest-book-search v1PageBooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, books: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, novel: bool, referenceBook: bool, biographyBook: bool, rolePlayingBook: bool, ebook: bool, anthology: bool, novelization: bool, audiobook: bool, audiobookAbridged: bool, audiobookPublishedYear: int, audiobookPublishedMonth: int, audiobookPublishedDay: int, audiobookRunTime: int, productionNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/book/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching books
#
# POST /v1/rest/book/search
# DEPRECATED
# operationId: v1SearchBooks
@deprecated
export def "rest-book-search v1SearchBooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Book title
  --publishedYearFrom: int # Starting year the book was published (format: int32)
  --publishedYearTo: int # Ending year the book was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
  --stardateFrom: float # Starting stardate of book story (format: float)
  --stardateTo: float # Ending stardate of book story (format: float)
  --yearFrom: int # Starting year of book story (format: int32)
  --yearTo: int # Ending year of book story (format: int32)
  --novel: string@bool-completer # Whether it should be a novel
  --referenceBook: string@bool-completer # Whether it should be a reference book
  --biographyBook: string@bool-completer # Whether it should be a biography book
  --rolePlayingBook: string@bool-completer # Whether it should be a role playing book
  --eBook: string@bool-completer # Whether it should be an e-book
  --anthology: string@bool-completer # Whether it should be an anthology
  --novelization: string@bool-completer # Whether it should be novelization
  --audiobook: string@bool-completer # Whether it should be an audiobook
  --audiobookAbridged: string@bool-completer # Whether it should be an audiobook, abridged
  --audiobookPublishedYearFrom: int # Starting year the audiobook was published (format: int32)
  --audiobookPublishedYearTo: int # Ending year the audiobook was published (format: int32)
  --audiobookRunTimeFrom: int # Minimal audiobook run time, in minutes (format: int32)
  --audiobookRunTimeTo: int # Maximal audiobook run time, in minutes (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, books: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, novel: bool, referenceBook: bool, biographyBook: bool, rolePlayingBook: bool, ebook: bool, anthology: bool, novelization: bool, audiobook: bool, audiobookAbridged: bool, audiobookPublishedYear: int, audiobookPublishedMonth: int, audiobookPublishedDay: int, audiobookRunTime: int, productionNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/book/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, novel: $novel, referenceBook: $referenceBook, biographyBook: $biographyBook, rolePlayingBook: $rolePlayingBook, eBook: $eBook, anthology: $anthology, novelization: $novelization, audiobook: $audiobook, audiobookAbridged: $audiobookAbridged, audiobookPublishedYearFrom: $audiobookPublishedYearFrom, audiobookPublishedYearTo: $audiobookPublishedYearTo, audiobookRunTimeFrom: $audiobookRunTimeFrom, audiobookRunTimeTo: $audiobookRunTimeTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single book (V2)
#
# GET /v2/rest/book
# operationId: v2GetBook
export def "rest-book v2GetBook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Book unique ID
]: nothing -> record<book: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, novel: bool, referenceBook: bool, biographyBook: bool, rolePlayingBook: bool, ebook: bool, anthology: bool, novelization: bool, unauthorizedPublication: bool, audiobook: bool, audiobookAbridged: bool, audiobookPublishedYear: int, audiobookPublishedMonth: int, audiobookPublishedDay: int, audiobookRunTime: int, productionNumber: string, bookSeries: list<record>, authors: list<record>, artists: list<record>, editors: list<record>, audiobookNarrators: list<record>, publishers: list<record>, audiobookPublishers: list<record>, characters: list<record>, references: list<record>, audiobookReferences: list<record>, bookCollections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/book" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over books (V2)
#
# GET /v2/rest/book/search
# operationId: v2PageBooks
export def "rest-book-search v2PageBooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, books: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, novel: bool, referenceBook: bool, biographyBook: bool, rolePlayingBook: bool, ebook: bool, anthology: bool, novelization: bool, unauthorizedPublication: bool, audiobook: bool, audiobookAbridged: bool, audiobookPublishedYear: int, audiobookPublishedMonth: int, audiobookPublishedDay: int, audiobookRunTime: int, productionNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/book/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching books (V2)
#
# POST /v2/rest/book/search
# operationId: v2SearchBooks
export def "rest-book-search v2SearchBooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Book title
  --publishedYearFrom: int # Starting year the book was published (format: int32)
  --publishedYearTo: int # Ending year the book was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
  --stardateFrom: float # Starting stardate of book story (format: float)
  --stardateTo: float # Ending stardate of book story (format: float)
  --yearFrom: int # Starting year of book story (format: int32)
  --yearTo: int # Ending year of book story (format: int32)
  --novel: string@bool-completer # Whether it should be a novel
  --referenceBook: string@bool-completer # Whether it should be a reference book
  --biographyBook: string@bool-completer # Whether it should be a biography book
  --rolePlayingBook: string@bool-completer # Whether it should be a role playing book
  --eBook: string@bool-completer # Whether it should be an e-book
  --anthology: string@bool-completer # Whether it should be an anthology
  --novelization: string@bool-completer # Whether it should be novelization
  --unauthorizedPublication: string@bool-completer # Whether it should be an unauthorized publication
  --audiobook: string@bool-completer # Whether it should be an audiobook
  --audiobookAbridged: string@bool-completer # Whether it should be an audiobook, abridged
  --audiobookPublishedYearFrom: int # Starting year the audiobook was published (format: int32)
  --audiobookPublishedYearTo: int # Ending year the audiobook was published (format: int32)
  --audiobookRunTimeFrom: int # Minimal audiobook run time, in minutes (format: int32)
  --audiobookRunTimeTo: int # Maximal audiobook run time, in minutes (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, books: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, novel: bool, referenceBook: bool, biographyBook: bool, rolePlayingBook: bool, ebook: bool, anthology: bool, novelization: bool, unauthorizedPublication: bool, audiobook: bool, audiobookAbridged: bool, audiobookPublishedYear: int, audiobookPublishedMonth: int, audiobookPublishedDay: int, audiobookRunTime: int, productionNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/book/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, novel: $novel, referenceBook: $referenceBook, biographyBook: $biographyBook, rolePlayingBook: $rolePlayingBook, eBook: $eBook, anthology: $anthology, novelization: $novelization, unauthorizedPublication: $unauthorizedPublication, audiobook: $audiobook, audiobookAbridged: $audiobookAbridged, audiobookPublishedYearFrom: $audiobookPublishedYearFrom, audiobookPublishedYearTo: $audiobookPublishedYearTo, audiobookRunTimeFrom: $audiobookRunTimeFrom, audiobookRunTimeTo: $audiobookRunTimeTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single book collection
#
# GET /v1/rest/bookCollection
# operationId: v1GetBookCollection
export def "rest-book-collection v1GetBookCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Book collection unique ID
]: nothing -> record<bookCollection: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, bookSeries: list<record>, authors: list<record>, artists: list<record>, editors: list<record>, publishers: list<record>, characters: list<record>, references: list<record>, books: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/bookCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over book collections
#
# GET /v1/rest/bookCollection/search
# operationId: v1PageBookCollections
export def "rest-book-collection-search v1PageBookCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, bookCollections: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/bookCollection/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching book collections
#
# POST /v1/rest/bookCollection/search
# operationId: v1SearchBookCollections
export def "rest-book-collection-search v1SearchBookCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Book collection title
  --publishedYearFrom: int # Starting year the book collection was published (format: int32)
  --publishedYearTo: int # Ending year the book collection was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
  --stardateFrom: float # Starting stardate of book collection stories (format: float)
  --stardateTo: float # Ending stardate of book collections stories (format: float)
  --yearFrom: int # Starting year of book collection stories (format: int32)
  --yearTo: int # Ending year of book collections stories (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, bookCollections: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/bookCollection/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single book series
#
# GET /v1/rest/bookSeries
# operationId: v1GetBookSeries
export def "rest-book-series v1GetBookSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Book series unique ID
]: nothing -> record<bookSeries: record<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedYearTo: int, publishedMonthTo: int, numberOfBooks: int, yearFrom: int, yearTo: int, miniseries: bool, ebookSeries: bool, parentSeries: list<record>, childSeries: list<record>, publishers: list<record>, books: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/bookSeries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over book series
#
# GET /v1/rest/bookSeries/search
# operationId: v1PageBookSeries
export def "rest-book-series-search v1PageBookSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, bookSeries: table<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedYearTo: int, publishedMonthTo: int, numberOfBooks: int, yearFrom: int, yearTo: int, miniseries: bool, ebookSeries: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/bookSeries/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching book series
#
# POST /v1/rest/bookSeries/search
# operationId: v1SearchBookSeries
export def "rest-book-series-search v1SearchBookSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Book series title
  --publishedYearFrom: int # Starting year the book series was published (format: int32)
  --publishedYearTo: int # Ending year the book series was published (format: int32)
  --numberOfBooksFrom: int # Minimal number of books (format: int32)
  --numberOfBooksTo: int # Maximal number of books (format: int32)
  --yearFrom: int # Starting year of book series stories (format: int32)
  --yearTo: int # Ending year of book series stories (format: int32)
  --miniseries: string@bool-completer # Whether it should be a miniseries
  --eBookSeries: string@bool-completer # Whether it should be an e-book series
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, bookSeries: table<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedYearTo: int, publishedMonthTo: int, numberOfBooks: int, yearFrom: int, yearTo: int, miniseries: bool, ebookSeries: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/bookSeries/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfBooksFrom: $numberOfBooksFrom, numberOfBooksTo: $numberOfBooksTo, yearFrom: $yearFrom, yearTo: $yearTo, miniseries: $miniseries, eBookSeries: $eBookSeries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single character
#
# GET /v1/rest/character
# operationId: v1GetCharacter
export def "rest-character v1GetCharacter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Character unique ID
]: nothing -> record<character: record<uid: string, name: string, gender: string, yearOfBirth: int, monthOfBirth: int, dayOfBirth: int, placeOfBirth: string, yearOfDeath: int, monthOfDeath: int, dayOfDeath: int, placeOfDeath: string, height: int, weight: int, deceased: bool, bloodType: string, maritalStatus: string, serialNumber: string, hologramActivationDate: string, hologramStatus: string, hologramDateStatus: string, hologram: bool, fictionalCharacter: bool, mirror: bool, alternateReality: bool, performers: list<record>, episodes: list<record>, movies: list<record>, characterSpecies: list<record>, characterRelations: list<record>, titles: list<record>, occupations: list<record>, organizations: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/character" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over characters
#
# GET /v1/rest/character/search
# operationId: v1PageCharacter
export def "rest-character-search v1PageCharacter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, characters: table<uid: string, name: string, gender: string, yearOfBirth: int, monthOfBirth: int, dayOfBirth: int, placeOfBirth: string, yearOfDeath: int, monthOfDeath: int, dayOfDeath: int, placeOfDeath: string, height: int, weight: int, deceased: bool, bloodType: string, maritalStatus: string, serialNumber: string, hologramActivationDate: string, hologramStatus: string, hologramDateStatus: string, hologram: bool, fictionalCharacter: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/character/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching characters
#
# POST /v1/rest/character/search
# operationId: v1SearchCharacters
export def "rest-character-search v1SearchCharacters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Character name
  --gender: string # Character gender
  --deceased: string@bool-completer # Whether it should be a deceased character
  --hologram: string@bool-completer # Whether it should be a hologram
  --fictionalCharacter: string@bool-completer # Whether it should be a fictional character (from universe point of view)
  --mirror: string@bool-completer # Whether it should be a mirror universe character
  --alternateReality: string@bool-completer # Whether it should be a alternate reality character
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, characters: table<uid: string, name: string, gender: string, yearOfBirth: int, monthOfBirth: int, dayOfBirth: int, placeOfBirth: string, yearOfDeath: int, monthOfDeath: int, dayOfDeath: int, placeOfDeath: string, height: int, weight: int, deceased: bool, bloodType: string, maritalStatus: string, serialNumber: string, hologramActivationDate: string, hologramStatus: string, hologramDateStatus: string, hologram: bool, fictionalCharacter: bool, mirror: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/character/search" $qp)
  let body = {name: $name, gender: $gender, deceased: $deceased, hologram: $hologram, fictionalCharacter: $fictionalCharacter, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single comics
#
# GET /v1/rest/comics
# operationId: v1GetComics
export def "rest-comics v1GetComics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Comics unique ID
]: nothing -> record<comics: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool, adaptation: bool, comicSeries: list<record>, writers: list<record>, artists: list<record>, editors: list<record>, staff: list<record>, publishers: list<record>, characters: list<record>, references: list<record>, comicCollections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over comics
#
# GET /v1/rest/comics/search
# operationId: v1PageComics
export def "rest-comics-search v1PageComics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comics: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool, adaptation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comics/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching comics
#
# POST /v1/rest/comics/search
# operationId: v1SearchComics
export def "rest-comics-search v1SearchComics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Comics title
  --publishedYearFrom: int # Starting year the comics was published (format: int32)
  --publishedYearTo: int # Ending year the comics was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
  --stardateFrom: float # Starting stardate of comics story (format: float)
  --stardateTo: float # Ending stardate of comics story (format: float)
  --yearFrom: int # Starting year of comics story (format: int32)
  --yearTo: int # Ending year of comics story (format: int32)
  --photonovel: string@bool-completer # Whether it should be a photonovel
  --adaptation: string@bool-completer # Whether it should be an adaptation of an episode or a movie
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comics: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool, adaptation: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comics/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, photonovel: $photonovel, adaptation: $adaptation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single comic collection
#
# GET /v1/rest/comicCollection
# DEPRECATED
# operationId: v1GetComicCollection
@deprecated
export def "rest-comic-collection v1GetComicCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Comic collection unique ID
]: nothing -> record<comicCollection: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool, comicSeries: list<record>, writers: list<record>, artists: list<record>, editors: list<record>, staff: list<record>, publishers: list<record>, characters: list<record>, references: list<record>, comics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over comic collections
#
# GET /v1/rest/comicCollection/search
# operationId: v1PageComicCollections
export def "rest-comic-collection-search v1PageComicCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comicCollections: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicCollection/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching comic collections
#
# POST /v1/rest/comicCollection/search
# operationId: v1SearchComicCollections
export def "rest-comic-collection-search v1SearchComicCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Comic collection title
  --publishedYearFrom: int # Starting year the comic collection was published (format: int32)
  --publishedYearTo: int # Ending year the comic collection was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
  --stardateFrom: float # Starting stardate of comic collection stories (format: float)
  --stardateTo: float # Ending stardate of comic collections stories (format: float)
  --yearFrom: int # Starting year of comic collection stories (format: int32)
  --yearTo: int # Ending year of comic collections stories (format: int32)
  --photonovel: string@bool-completer # Whether it should be an photonovel collection
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comicCollections: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicCollection/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, photonovel: $photonovel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single comic collection (V2)
#
# GET /v2/rest/comicCollection
# operationId: v2GetComicCollection
export def "rest-comic-collection v2GetComicCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Comic collection unique ID
]: nothing -> record<comicCollection: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, photonovel: bool, comicSeries: list<record>, childComicSeries: list<record>, writers: list<record>, artists: list<record>, editors: list<record>, staff: list<record>, publishers: list<record>, characters: list<record>, references: list<record>, comics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/comicCollection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieval of a single comic series
#
# GET /v1/rest/comicSeries
# operationId: v1GetComicSeries
export def "rest-comic-series v1GetComicSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Comic series unique ID
]: nothing -> record<comicSeries: record<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedDayFrom: int, publishedYearTo: int, publishedMonthTo: int, publishedDayTo: int, numberOfIssues: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, miniseries: bool, photonovelSeries: bool, parentSeries: list<record>, childSeries: list<record>, publishers: list<record>, comics: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicSeries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over comic series
#
# GET /v1/rest/comicSeries/search
# operationId: v1PageComicSeries
export def "rest-comic-series-search v1PageComicSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comicSeries: table<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedDayFrom: int, publishedYearTo: int, publishedMonthTo: int, publishedDayTo: int, numberOfIssues: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, miniseries: bool, photonovelSeries: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicSeries/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching comic series
#
# POST /v1/rest/comicSeries/search
# operationId: v1SearchComicSeries
export def "rest-comic-series-search v1SearchComicSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Comic series title
  --publishedYearFrom: int # Starting year the comic series was published (format: int32)
  --publishedYearTo: int # Ending year the comic series was published (format: int32)
  --numberOfIssuesFrom: int # Minimal number of issues (format: int32)
  --numberOfIssuesTo: int # Maximal number of issues (format: int32)
  --stardateFrom: float # Starting stardate of comic series stories (format: float)
  --stardateTo: float # Starting stardate of comic series stories (format: float)
  --yearFrom: int # Starting year of comic series stories (format: int32)
  --yearTo: int # Ending year of comic series stories (format: int32)
  --miniseries: string@bool-completer # Whether it should be a miniseries
  --photonovelSeries: string@bool-completer # Whether it should be photonovel series
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comicSeries: table<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedDayFrom: int, publishedYearTo: int, publishedMonthTo: int, publishedDayTo: int, numberOfIssues: int, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, miniseries: bool, photonovelSeries: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicSeries/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfIssuesFrom: $numberOfIssuesFrom, numberOfIssuesTo: $numberOfIssuesTo, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, miniseries: $miniseries, photonovelSeries: $photonovelSeries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single comic strip
#
# GET /v1/rest/comicStrip
# operationId: v1GetComicStrip
export def "rest-comic-strip v1GetComicStrip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Comic strip unique ID
]: nothing -> record<comicStrip: record<uid: string, title: string, periodical: string, publishedYearFrom: int, publishedMonthFrom: int, publishedDayFrom: int, publishedYearTo: int, publishedMonthTo: int, publishedDayTo: int, numberOfPages: int, yearFrom: int, yearTo: int, comicSeries: list<record>, writers: list<record>, artists: list<record>, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicStrip" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over comic strips
#
# GET /v1/rest/comicStrip/search
# operationId: v1PageComicStrips
export def "rest-comic-strip-search v1PageComicStrips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comicStrips: table<uid: string, title: string, periodical: string, publishedYearFrom: int, publishedMonthFrom: int, publishedDayFrom: int, publishedYearTo: int, publishedMonthTo: int, publishedDayTo: int, numberOfPages: int, yearFrom: int, yearTo: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicStrip/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching comic strips
#
# POST /v1/rest/comicStrip/search
# operationId: v1SearchComicStrips
export def "rest-comic-strip-search v1SearchComicStrips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Comic strip title
  --publishedYearFrom: int # Starting year the comic strip was published (format: int32)
  --publishedYearTo: int # Ending year the comic strip was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
  --yearFrom: int # Starting year of comic strip story (format: int32)
  --yearTo: int # Ending year of comic strip story (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, comicStrips: table<uid: string, title: string, periodical: string, publishedYearFrom: int, publishedMonthFrom: int, publishedDayFrom: int, publishedYearTo: int, publishedMonthTo: int, publishedDayTo: int, numberOfPages: int, yearFrom: int, yearTo: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/comicStrip/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo, yearFrom: $yearFrom, yearTo: $yearTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single company
#
# GET /v1/rest/company
# DEPRECATED
# operationId: v1GetCompany
@deprecated
export def "rest-company v1GetCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Company unique ID
]: nothing -> record<company: record<uid: string, name: string, broadcaster: bool, collectibleCompany: bool, conglomerate: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/company" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over companies
#
# GET /v1/rest/company/search
# DEPRECATED
# operationId: v1PageCompanies
@deprecated
export def "rest-company-search v1PageCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, companies: table<uid: string, name: string, broadcaster: bool, collectibleCompany: bool, conglomerate: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/company/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching companies
#
# POST /v1/rest/company/search
# DEPRECATED
# operationId: v1SearchCompanies
@deprecated
export def "rest-company-search v1SearchCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Company name
  --broadcaster: string@bool-completer # Whether it should be a broadcaster
  --collectibleCompany: string@bool-completer # Whether it should be a collectible company
  --conglomerate: string@bool-completer # Whether it should be a conglomerate
  --digitalVisualEffectsCompany: string@bool-completer # Whether it should be a digital visual effects company
  --distributor: string@bool-completer # Whether it should be a distributor
  --gameCompany: string@bool-completer # Whether it should be a game company
  --filmEquipmentCompany: string@bool-completer # Whether it should be a film equipment company
  --makeUpEffectsStudio: string@bool-completer # Whether it should be a make-up effects studio
  --mattePaintingCompany: string@bool-completer # Whether it should be a matte painting company
  --modelAndMiniatureEffectsCompany: string@bool-completer # Whether it should be a model and miniature effects company
  --postProductionCompany: string@bool-completer # Whether it should be a post-production company
  --productionCompany: string@bool-completer # Whether it should be a production company
  --propCompany: string@bool-completer # Whether it should be a prop company
  --recordLabel: string@bool-completer # Whether it should be a record label
  --specialEffectsCompany: string@bool-completer # Whether it should be a special effects company
  --tvAndFilmProductionCompany: string@bool-completer # Whether it should be a TV and film production company
  --videoGameCompany: string@bool-completer # Whether it should be a video game company
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, companies: table<uid: string, name: string, broadcaster: bool, collectibleCompany: bool, conglomerate: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/company/search" $qp)
  let body = {name: $name, broadcaster: $broadcaster, collectibleCompany: $collectibleCompany, conglomerate: $conglomerate, digitalVisualEffectsCompany: $digitalVisualEffectsCompany, distributor: $distributor, gameCompany: $gameCompany, filmEquipmentCompany: $filmEquipmentCompany, makeUpEffectsStudio: $makeUpEffectsStudio, mattePaintingCompany: $mattePaintingCompany, modelAndMiniatureEffectsCompany: $modelAndMiniatureEffectsCompany, postProductionCompany: $postProductionCompany, productionCompany: $productionCompany, propCompany: $propCompany, recordLabel: $recordLabel, specialEffectsCompany: $specialEffectsCompany, tvAndFilmProductionCompany: $tvAndFilmProductionCompany, videoGameCompany: $videoGameCompany} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single company (V2)
#
# GET /v2/rest/company
# operationId: v2GetCompany
export def "rest-company v2GetCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Company unique ID
]: nothing -> record<company: record<uid: string, name: string, broadcaster: bool, streamingService: bool, collectibleCompany: bool, conglomerate: bool, visualEffectsCompany: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool, publisher: bool, publicationArtStudio: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/company" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over companies (V2)
#
# GET /v2/rest/company/search
# operationId: v2PageCompanies
export def "rest-company-search v2PageCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, companies: table<uid: string, name: string, broadcaster: bool, streamingService: bool, collectibleCompany: bool, conglomerate: bool, visualEffectsCompany: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool, publisher: bool, publicationArtStudio: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/company/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching companies (V2)
#
# POST /v2/rest/company/search
# operationId: v2SearchCompanies
export def "rest-company-search v2SearchCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Company name
  --broadcaster: string@bool-completer # Whether it should be a broadcaster
  --streamingService: string@bool-completer # Whether it should be a streaming service
  --collectibleCompany: string@bool-completer # Whether it should be a collectible company
  --conglomerate: string@bool-completer # Whether it should be a conglomerate
  --visualEffectsCompany: string@bool-completer # Whether it should be a visual effects company
  --digitalVisualEffectsCompany: string@bool-completer # Whether it should be a digital visual effects company
  --distributor: string@bool-completer # Whether it should be a distributor
  --gameCompany: string@bool-completer # Whether it should be a game company
  --filmEquipmentCompany: string@bool-completer # Whether it should be a film equipment company
  --makeUpEffectsStudio: string@bool-completer # Whether it should be a make-up effects studio
  --mattePaintingCompany: string@bool-completer # Whether it should be a matte painting company
  --modelAndMiniatureEffectsCompany: string@bool-completer # Whether it should be a model and miniature effects company
  --postProductionCompany: string@bool-completer # Whether it should be a post-production company
  --productionCompany: string@bool-completer # Whether it should be a production company
  --propCompany: string@bool-completer # Whether it should be a prop company
  --recordLabel: string@bool-completer # Whether it should be a record label
  --specialEffectsCompany: string@bool-completer # Whether it should be a special effects company
  --tvAndFilmProductionCompany: string@bool-completer # Whether it should be a TV and film production company
  --videoGameCompany: string@bool-completer # Whether it should be a video game company
  --publisher: string@bool-completer # Whether it should be a publisher
  --publicationArtStudio: string@bool-completer # Whether it should be a publication art studio
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, companies: table<uid: string, name: string, broadcaster: bool, streamingService: bool, collectibleCompany: bool, conglomerate: bool, visualEffectsCompany: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool, publisher: bool, publicationArtStudio: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/company/search" $qp)
  let body = {name: $name, broadcaster: $broadcaster, streamingService: $streamingService, collectibleCompany: $collectibleCompany, conglomerate: $conglomerate, visualEffectsCompany: $visualEffectsCompany, digitalVisualEffectsCompany: $digitalVisualEffectsCompany, distributor: $distributor, gameCompany: $gameCompany, filmEquipmentCompany: $filmEquipmentCompany, makeUpEffectsStudio: $makeUpEffectsStudio, mattePaintingCompany: $mattePaintingCompany, modelAndMiniatureEffectsCompany: $modelAndMiniatureEffectsCompany, postProductionCompany: $postProductionCompany, productionCompany: $productionCompany, propCompany: $propCompany, recordLabel: $recordLabel, specialEffectsCompany: $specialEffectsCompany, tvAndFilmProductionCompany: $tvAndFilmProductionCompany, videoGameCompany: $videoGameCompany, publisher: $publisher, publicationArtStudio: $publicationArtStudio} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single conflict
#
# GET /v1/rest/conflict
# DEPRECATED
# operationId: v1GetConflict
@deprecated
export def "rest-conflict v1GetConflict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Conflict unique ID
]: nothing -> record<conflict: record<uid: string, name: string, yearFrom: int, yearTo: int, earthConflict: bool, federationWar: bool, klingonWar: bool, dominionWarBattle: bool, alternateReality: bool, locations: list<record>, firstSideBelligerents: list<record>, firstSideCommanders: list<record>, secondSideBelligerents: list<record>, secondSideCommanders: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/conflict" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over conflicts
#
# GET /v1/rest/conflict/search
# operationId: v1PageConflicts
export def "rest-conflict-search v1PageConflicts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, conflicts: table<uid: string, name: string, yearFrom: int, yearTo: int, earthConflict: bool, federationWar: bool, klingonWar: bool, dominionWarBattle: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/conflict/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching conflicts
#
# POST /v1/rest/conflict/search
# operationId: v1SearchConflicts
export def "rest-conflict-search v1SearchConflicts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Conflict name
  --yearFrom: int # Starting year of the conflict (format: int32)
  --yearTo: int # Ending year of the conflict (format: int32)
  --earthConflict: string@bool-completer # Whether it should be an Earth conflict
  --federationWar: string@bool-completer # Whether this conflict should be a part of war involving Federation
  --klingonWar: string@bool-completer # Whether this conflict should be a part of war involving the Klingons
  --dominionWarBattle: string@bool-completer # Whether this conflict should be a Dominion war battle
  --alternateReality: string@bool-completer # Whether this conflict should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, conflicts: table<uid: string, name: string, yearFrom: int, yearTo: int, earthConflict: bool, federationWar: bool, klingonWar: bool, dominionWarBattle: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/conflict/search" $qp)
  let body = {name: $name, yearFrom: $yearFrom, yearTo: $yearTo, earthConflict: $earthConflict, federationWar: $federationWar, klingonWar: $klingonWar, dominionWarBattle: $dominionWarBattle, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single conflict (V2)
#
# GET /v2/rest/conflict
# operationId: v2GetConflict
export def "rest-conflict v2GetConflict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Conflict unique ID
]: nothing -> record<conflict: record<uid: string, name: string, yearFrom: int, yearTo: int, earthConflict: bool, federationWar: bool, klingonWar: bool, dominionWarBattle: bool, alternateReality: bool, locations: list<record>, firstSideBelligerents: list<record>, firstSideLocations: list<record>, firstSideCommanders: list<record>, secondSideBelligerents: list<record>, secondSideLocations: list<record>, secondSideCommanders: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/conflict" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieval of a data version
#
# GET /v1/rest/common/dataVersion
# operationId: v1GetDataVersion
export def "rest-common-data-version v1GetDataVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dataVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rest/common/dataVersion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieval of a single element
#
# GET /v1/rest/element
# DEPRECATED
# operationId: v1GetElement
@deprecated
export def "rest-element v1GetElement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Element unique ID
]: nothing -> record<element: record<uid: string, name: string, symbol: string, atomicNumber: int, atomicWeight: int, transuranium: bool, gammaSeries: bool, hypersonicSeries: bool, megaSeries: bool, omegaSeries: bool, transonicSeries: bool, worldSeries: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/element" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over elements
#
# GET /v1/rest/element/search
# DEPRECATED
# operationId: v1PageElements
@deprecated
export def "rest-element-search v1PageElements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, elements: table<uid: string, name: string, symbol: string, atomicNumber: int, atomicWeight: int, transuranium: bool, gammaSeries: bool, hypersonicSeries: bool, megaSeries: bool, omegaSeries: bool, transonicSeries: bool, worldSeries: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/element/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching elements
#
# POST /v1/rest/element/search
# DEPRECATED
# operationId: v1SearchElements
@deprecated
export def "rest-element-search v1SearchElements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Element name
  --symbol: string # Element symbol
  --transuranium: string@bool-completer # Whether it should be a transuranium
  --gammaSeries: string@bool-completer # Whether it should belong to Gamma series
  --hypersonicSeries: string@bool-completer # Whether it should belong to Hypersonic series
  --megaSeries: string@bool-completer # Whether it should belong to Mega series
  --omegaSeries: string@bool-completer # Whether it should belong to Omega series
  --transonicSeries: string@bool-completer # Whether it should belong to Transonic series
  --worldSeries: string@bool-completer # Whether it should belong to World series
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, elements: table<uid: string, name: string, symbol: string, atomicNumber: int, atomicWeight: int, transuranium: bool, gammaSeries: bool, hypersonicSeries: bool, megaSeries: bool, omegaSeries: bool, transonicSeries: bool, worldSeries: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/element/search" $qp)
  let body = {name: $name, symbol: $symbol, transuranium: $transuranium, gammaSeries: $gammaSeries, hypersonicSeries: $hypersonicSeries, megaSeries: $megaSeries, omegaSeries: $omegaSeries, transonicSeries: $transonicSeries, worldSeries: $worldSeries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single element (V2)
#
# GET /v2/rest/element
# operationId: v2GetElement
export def "rest-element v2GetElement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Element unique ID
]: nothing -> record<element: record<uid: string, name: string, symbol: string, atomicNumber: int, atomicWeight: int, transuranic: bool, gammaSeries: bool, hypersonicSeries: bool, megaSeries: bool, omegaSeries: bool, transonicSeries: bool, worldSeries: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/element" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over elements (V2)
#
# GET /v2/rest/element/search
# operationId: v2PageElements
export def "rest-element-search v2PageElements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, elements: table<uid: string, name: string, symbol: string, atomicNumber: int, atomicWeight: int, transuranic: bool, gammaSeries: bool, hypersonicSeries: bool, megaSeries: bool, omegaSeries: bool, transonicSeries: bool, worldSeries: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/element/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching elements (V2)
#
# POST /v2/rest/element/search
# operationId: v2SearchElements
export def "rest-element-search v2SearchElements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Element name
  --symbol: string # Element symbol
  --transuranic: string@bool-completer # Whether it should be a transuranic
  --gammaSeries: string@bool-completer # Whether it should belong to Gamma series
  --hypersonicSeries: string@bool-completer # Whether it should belong to Hypersonic series
  --megaSeries: string@bool-completer # Whether it should belong to Mega series
  --omegaSeries: string@bool-completer # Whether it should belong to Omega series
  --transonicSeries: string@bool-completer # Whether it should belong to Transonic series
  --worldSeries: string@bool-completer # Whether it should belong to World series
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, elements: table<uid: string, name: string, symbol: string, atomicNumber: int, atomicWeight: int, transuranic: bool, gammaSeries: bool, hypersonicSeries: bool, megaSeries: bool, omegaSeries: bool, transonicSeries: bool, worldSeries: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/element/search" $qp)
  let body = {name: $name, symbol: $symbol, transuranic: $transuranic, gammaSeries: $gammaSeries, hypersonicSeries: $hypersonicSeries, megaSeries: $megaSeries, omegaSeries: $omegaSeries, transonicSeries: $transonicSeries, worldSeries: $worldSeries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single episode
#
# GET /v1/rest/episode
# operationId: v1GetEpisode
export def "rest-episode v1GetEpisode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Episode unique ID
]: nothing -> record<episode: record<uid: string, title: string, titleGerman: string, titleItalian: string, titleJapanese: string, series: record<uid: string, title: string, abbreviation: string, productionStartYear: int, productionEndYear: int, originalRunStartDate: string, originalRunEndDate: string, seasonsCount: int, episodesCount: int, featureLengthEpisodesCount: int, productionCompany: record, originalBroadcaster: record>, season: record<uid: string, title: string, series: record, seasonNumber: int, numberOfEpisodes: int>, seasonNumber: int, episodeNumber: int, productionSerialNumber: string, featureLength: bool, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, usAirDate: string, finalScriptDate: string, writers: list<record>, teleplayAuthors: list<record>, storyAuthors: list<record>, directors: list<record>, performers: list<record>, stuntPerformers: list<record>, standInPerformers: list<record>, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/episode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over episodes
#
# GET /v1/rest/episode/search
# operationId: v1PageEpisodes
export def "rest-episode-search v1PageEpisodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, episodes: table<uid: string, title: string, titleGerman: string, titleItalian: string, titleJapanese: string, series: record, season: record, seasonNumber: int, episodeNumber: int, productionSerialNumber: string, featureLength: bool, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, usAirDate: string, finalScriptDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/episode/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching episodes
#
# POST /v1/rest/episode/search
# operationId: v1SearchEpisodes
export def "rest-episode-search v1SearchEpisodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Episode title
  --seasonNumberFrom: int # Minimal season number (format: int32)
  --seasonNumberTo: int # Maximal season number (format: int32)
  --episodeNumberFrom: int # Minimal episode number in season (format: int32)
  --episodeNumberTo: int # Maximal episode number in season (format: int32)
  --productionSerialNumber: string # Production serial number
  --featureLength: string@bool-completer # Whether it should be a feature length episode
  --stardateFrom: float # Starting stardate of episode story (format: float)
  --stardateTo: float # Ending stardate of episode story (format: float)
  --yearFrom: int # Starting year of episode story (format: int32)
  --yearTo: int # Ending year of episode story (format: int32)
  --usAirDateFrom: string # Minimal date the episode was first aired in the United States (format: date)
  --usAirDateTo: string # Maximal date the episode was first aired in the United States (format: date)
  --finalScriptDateFrom: string # Minimal date the episode script was completed (format: date)
  --finalScriptDateTo: string # Maximal date the episode script was completed (format: date)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, episodes: table<uid: string, title: string, titleGerman: string, titleItalian: string, titleJapanese: string, series: record, season: record, seasonNumber: int, episodeNumber: int, productionSerialNumber: string, featureLength: bool, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, usAirDate: string, finalScriptDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/episode/search" $qp)
  let body = {title: $title, seasonNumberFrom: $seasonNumberFrom, seasonNumberTo: $seasonNumberTo, episodeNumberFrom: $episodeNumberFrom, episodeNumberTo: $episodeNumberTo, productionSerialNumber: $productionSerialNumber, featureLength: $featureLength, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, usAirDateFrom: $usAirDateFrom, usAirDateTo: $usAirDateTo, finalScriptDateFrom: $finalScriptDateFrom, finalScriptDateTo: $finalScriptDateTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single food
#
# GET /v1/rest/food
# operationId: v1GetFood
export def "rest-food v1GetFood" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Food unique ID
]: nothing -> record<food: record<uid: string, name: string, earthlyOrigin: bool, dessert: bool, fruit: bool, herbOrSpice: bool, sauce: bool, soup: bool, beverage: bool, alcoholicBeverage: bool, juice: bool, tea: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/food" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over foods
#
# GET /v1/rest/food/search
# operationId: v1PageFoods
export def "rest-food-search v1PageFoods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, foods: table<uid: string, name: string, earthlyOrigin: bool, dessert: bool, fruit: bool, herbOrSpice: bool, sauce: bool, soup: bool, beverage: bool, alcoholicBeverage: bool, juice: bool, tea: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/food/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching foods
#
# POST /v1/rest/food/search
# operationId: v1SearchFoods
export def "rest-food-search v1SearchFoods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Food name
  --earthlyOrigin: string@bool-completer # Whether it should be of earthly origin
  --dessert: string@bool-completer # Whether it should be a dessert
  --fruit: string@bool-completer # Whether it should be a fruit
  --herbOrSpice: string@bool-completer # Whether it should be an herb or a spice
  --sauce: string@bool-completer # Whether it should be a sauce
  --soup: string@bool-completer # Whether it should be a soup
  --beverage: string@bool-completer # Whether it should be a beverage
  --alcoholicBeverage: string@bool-completer # Whether it should be an alcoholic beverage
  --juice: string@bool-completer # Whether it should be a juice
  --tea: string@bool-completer # Whether it should be a tea
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, foods: table<uid: string, name: string, earthlyOrigin: bool, dessert: bool, fruit: bool, herbOrSpice: bool, sauce: bool, soup: bool, beverage: bool, alcoholicBeverage: bool, juice: bool, tea: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/food/search" $qp)
  let body = {name: $name, earthlyOrigin: $earthlyOrigin, dessert: $dessert, fruit: $fruit, herbOrSpice: $herbOrSpice, sauce: $sauce, soup: $soup, beverage: $beverage, alcoholicBeverage: $alcoholicBeverage, juice: $juice, tea: $tea} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single literature
#
# GET /v1/rest/literature
# operationId: v1GetLiterature
export def "rest-literature v1GetLiterature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Literature unique ID
]: nothing -> record<literature: record<uid: string, title: string, earthlyOrigin: bool, shakespeareanWork: bool, report: bool, scientificLiterature: bool, technicalManual: bool, religiousLiterature: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/literature" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over literature
#
# GET /v1/rest/literature/search
# operationId: v1PageLiterature
export def "rest-literature-search v1PageLiterature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, literature: table<uid: string, title: string, earthlyOrigin: bool, shakespeareanWork: bool, report: bool, scientificLiterature: bool, technicalManual: bool, religiousLiterature: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/literature/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching literature
#
# POST /v1/rest/literature/search
# operationId: v1SearchLiterature
export def "rest-literature-search v1SearchLiterature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Literature title
  --earthlyOrigin: string@bool-completer # Whether it should be of earthly origin
  --shakespeareanWork: string@bool-completer # Whether it should be a Shakespearean work
  --report: string@bool-completer # Whether it should be a report
  --scientificLiterature: string@bool-completer # Whether it should be a scientific literature
  --technicalManual: string@bool-completer # Whether it should be a technical manual
  --religiousLiterature: string@bool-completer # Whether it should be a religious literature
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, literature: table<uid: string, title: string, earthlyOrigin: bool, shakespeareanWork: bool, report: bool, scientificLiterature: bool, technicalManual: bool, religiousLiterature: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/literature/search" $qp)
  let body = {title: $title, earthlyOrigin: $earthlyOrigin, shakespeareanWork: $shakespeareanWork, report: $report, scientificLiterature: $scientificLiterature, technicalManual: $technicalManual, religiousLiterature: $religiousLiterature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single location
#
# GET /v1/rest/location
# DEPRECATED
# operationId: v1GetLocation
@deprecated
export def "rest-location v1GetLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Location unique ID
]: nothing -> record<location: record<uid: string, name: string, earthlyLocation: bool, fictionalLocation: bool, religiousLocation: bool, geographicalLocation: bool, bodyOfWater: bool, country: bool, subnationalEntity: bool, settlement: bool, usSettlement: bool, bajoranSettlement: bool, colony: bool, landform: bool, landmark: bool, road: bool, structure: bool, shipyard: bool, buildingInterior: bool, establishment: bool, medicalEstablishment: bool, ds9Establishment: bool, school: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/location" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over locations
#
# GET /v1/rest/location/search
# DEPRECATED
# operationId: v1PageLocations
@deprecated
export def "rest-location-search v1PageLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, locations: table<uid: string, name: string, earthlyLocation: bool, fictionalLocation: bool, religiousLocation: bool, geographicalLocation: bool, bodyOfWater: bool, country: bool, subnationalEntity: bool, settlement: bool, usSettlement: bool, bajoranSettlement: bool, colony: bool, landform: bool, landmark: bool, road: bool, structure: bool, shipyard: bool, buildingInterior: bool, establishment: bool, medicalEstablishment: bool, ds9Establishment: bool, school: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/location/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching locations
#
# POST /v1/rest/location/search
# DEPRECATED
# operationId: v1SearchLocations
@deprecated
export def "rest-location-search v1SearchLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Location name
  --earthlyLocation: string@bool-completer # Whether it should be an earthly location
  --fictionalLocation: string@bool-completer # Whether it should be a fictional location
  --religiousLocation: string@bool-completer # Whether it should be a religious location
  --geographicalLocation: string@bool-completer # Whether it should be a geographical location
  --bodyOfWater: string@bool-completer # Whether it should be a body of water
  --country: string@bool-completer # Whether it should be a country
  --subnationalEntity: string@bool-completer # Whether it should be a subnational entity
  --settlement: string@bool-completer # Whether it should be a settlement
  --usSettlement: string@bool-completer # Whether it should be a US settlement
  --bajoranSettlement: string@bool-completer # Whether it should be a Bajoran settlement
  --colony: string@bool-completer # Whether it should be a colony
  --landform: string@bool-completer # Whether it should be a landform
  --landmark: string@bool-completer # Whether it should be a landmark
  --road: string@bool-completer # Whether it should be a road
  --structure: string@bool-completer # Whether it should be a structure
  --shipyard: string@bool-completer # Whether it should be a shipyard
  --buildingInterior: string@bool-completer # Whether it should be a building interior
  --establishment: string@bool-completer # Whether it should be a establishment
  --medicalEstablishment: string@bool-completer # Whether it should be a medical establishment
  --ds9Establishment: string@bool-completer # Whether it should be a DS9 establishment
  --school: string@bool-completer # Whether it should be a school
  --mirror: string@bool-completer # Whether this location should be from mirror universe
  --alternateReality: string@bool-completer # Whether this location should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, locations: table<uid: string, name: string, earthlyLocation: bool, fictionalLocation: bool, religiousLocation: bool, geographicalLocation: bool, bodyOfWater: bool, country: bool, subnationalEntity: bool, settlement: bool, usSettlement: bool, bajoranSettlement: bool, colony: bool, landform: bool, landmark: bool, road: bool, structure: bool, shipyard: bool, buildingInterior: bool, establishment: bool, medicalEstablishment: bool, ds9Establishment: bool, school: bool, mirror: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/location/search" $qp)
  let body = {name: $name, earthlyLocation: $earthlyLocation, fictionalLocation: $fictionalLocation, religiousLocation: $religiousLocation, geographicalLocation: $geographicalLocation, bodyOfWater: $bodyOfWater, country: $country, subnationalEntity: $subnationalEntity, settlement: $settlement, usSettlement: $usSettlement, bajoranSettlement: $bajoranSettlement, colony: $colony, landform: $landform, landmark: $landmark, road: $road, structure: $structure, shipyard: $shipyard, buildingInterior: $buildingInterior, establishment: $establishment, medicalEstablishment: $medicalEstablishment, ds9Establishment: $ds9Establishment, school: $school, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single location (V2)
#
# GET /v2/rest/location
# operationId: v2GetLocation
export def "rest-location v2GetLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Location unique ID
]: nothing -> record<location: record<uid: string, name: string, earthlyLocation: bool, qonosLocation: bool, fictionalLocation: bool, mythologicalLocation: bool, religiousLocation: bool, geographicalLocation: bool, bodyOfWater: bool, country: bool, subnationalEntity: bool, settlement: bool, usSettlement: bool, bajoranSettlement: bool, colony: bool, landform: bool, road: bool, structure: bool, shipyard: bool, buildingInterior: bool, establishment: bool, medicalEstablishment: bool, ds9Establishment: bool, school: bool, restaurant: bool, residence: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/location" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over locations (V2)
#
# GET /v2/rest/location/search
# operationId: v2PageLocations
export def "rest-location-search v2PageLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, locations: table<uid: string, name: string, earthlyLocation: bool, qonosLocation: bool, fictionalLocation: bool, mythologicalLocation: bool, religiousLocation: bool, geographicalLocation: bool, bodyOfWater: bool, country: bool, subnationalEntity: bool, settlement: bool, usSettlement: bool, bajoranSettlement: bool, colony: bool, landform: bool, road: bool, structure: bool, shipyard: bool, buildingInterior: bool, establishment: bool, medicalEstablishment: bool, ds9Establishment: bool, school: bool, restaurant: bool, residence: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/location/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching locations (V2)
#
# POST /v2/rest/location/search
# operationId: v2SearchLocations
export def "rest-location-search v2SearchLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Location name
  --earthlyLocation: string@bool-completer # Whether it should be an earthly location
  --qonosLocation: string@bool-completer # Whether it should be a Qo'nos location
  --fictionalLocation: string@bool-completer # Whether it should be a fictional location
  --mythologicalLocation: string@bool-completer # Whether it should be a mythological location
  --religiousLocation: string@bool-completer # Whether it should be a religious location
  --geographicalLocation: string@bool-completer # Whether it should be a geographical location
  --bodyOfWater: string@bool-completer # Whether it should be a body of water
  --country: string@bool-completer # Whether it should be a country
  --subnationalEntity: string@bool-completer # Whether it should be a subnational entity
  --settlement: string@bool-completer # Whether it should be a settlement
  --usSettlement: string@bool-completer # Whether it should be a US settlement
  --bajoranSettlement: string@bool-completer # Whether it should be a Bajoran settlement
  --colony: string@bool-completer # Whether it should be a colony
  --landform: string@bool-completer # Whether it should be a landform
  --road: string@bool-completer # Whether it should be a road
  --structure: string@bool-completer # Whether it should be a structure
  --shipyard: string@bool-completer # Whether it should be a shipyard
  --buildingInterior: string@bool-completer # Whether it should be a building interior
  --establishment: string@bool-completer # Whether it should be a establishment
  --medicalEstablishment: string@bool-completer # Whether it should be a medical establishment
  --ds9Establishment: string@bool-completer # Whether it should be a DS9 establishment
  --school: string@bool-completer # Whether it should be a school
  --restaurant: string@bool-completer # Whether it should be a restaurant
  --residence: string@bool-completer # Whether it should be a residence
  --mirror: string@bool-completer # Whether this location should be from mirror universe
  --alternateReality: string@bool-completer # Whether this location should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, locations: table<uid: string, name: string, earthlyLocation: bool, qonosLocation: bool, fictionalLocation: bool, mythologicalLocation: bool, religiousLocation: bool, geographicalLocation: bool, bodyOfWater: bool, country: bool, subnationalEntity: bool, settlement: bool, usSettlement: bool, bajoranSettlement: bool, colony: bool, landform: bool, road: bool, structure: bool, shipyard: bool, buildingInterior: bool, establishment: bool, medicalEstablishment: bool, ds9Establishment: bool, school: bool, restaurant: bool, residence: bool, mirror: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/location/search" $qp)
  let body = {name: $name, earthlyLocation: $earthlyLocation, qonosLocation: $qonosLocation, fictionalLocation: $fictionalLocation, mythologicalLocation: $mythologicalLocation, religiousLocation: $religiousLocation, geographicalLocation: $geographicalLocation, bodyOfWater: $bodyOfWater, country: $country, subnationalEntity: $subnationalEntity, settlement: $settlement, usSettlement: $usSettlement, bajoranSettlement: $bajoranSettlement, colony: $colony, landform: $landform, road: $road, structure: $structure, shipyard: $shipyard, buildingInterior: $buildingInterior, establishment: $establishment, medicalEstablishment: $medicalEstablishment, ds9Establishment: $ds9Establishment, school: $school, restaurant: $restaurant, residence: $residence, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single magazine
#
# GET /v1/rest/magazine
# operationId: v1GetMagazine
export def "rest-magazine v1GetMagazine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Magazine unique ID
]: nothing -> record<magazine: record<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, issueNumber: string, magazineSeries: list<record>, editors: list<record>, publishers: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/magazine" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over magazines
#
# GET /v1/rest/magazine/search
# operationId: v1PageMagazines
export def "rest-magazine-search v1PageMagazines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, magazines: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, issueNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/magazine/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching magazines
#
# POST /v1/rest/magazine/search
# operationId: v1SearchMagazines
export def "rest-magazine-search v1SearchMagazines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Magazine title
  --publishedYearFrom: int # Starting year the magazine was published (format: int32)
  --publishedYearTo: int # Ending year the magazine was published (format: int32)
  --numberOfPagesFrom: int # Minimal number of pages (format: int32)
  --numberOfPagesTo: int # Maximal number of pages (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, magazines: table<uid: string, title: string, publishedYear: int, publishedMonth: int, publishedDay: int, coverYear: int, coverMonth: int, coverDay: int, numberOfPages: int, issueNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/magazine/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfPagesFrom: $numberOfPagesFrom, numberOfPagesTo: $numberOfPagesTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single magazine series
#
# GET /v1/rest/magazineSeries
# operationId: v1GetMagazineSeries
export def "rest-magazine-series v1GetMagazineSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Magazine series unique ID
]: nothing -> record<magazineSeries: record<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedYearTo: int, publishedMonthTo: int, numberOfIssues: int, publishers: list<record>, editors: list<record>, magazines: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/magazineSeries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over magazine series
#
# GET /v1/rest/magazineSeries/search
# operationId: v1PageMagazineSeries
export def "rest-magazine-series-search v1PageMagazineSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, magazineSeries: table<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedYearTo: int, publishedMonthTo: int, numberOfIssues: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/magazineSeries/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching magazine series
#
# POST /v1/rest/magazineSeries/search
# operationId: v1SearchMagazineSeries
export def "rest-magazine-series-search v1SearchMagazineSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Magazine series title
  --publishedYearFrom: int # Starting year the magazine series was published (format: int32)
  --publishedYearTo: int # Ending year the magazine series was published (format: int32)
  --numberOfIssuesFrom: int # Minimal number of issues (format: int32)
  --numberOfIssuesTo: int # Maximal number of issues (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, magazineSeries: table<uid: string, title: string, publishedYearFrom: int, publishedMonthFrom: int, publishedYearTo: int, publishedMonthTo: int, numberOfIssues: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/magazineSeries/search" $qp)
  let body = {title: $title, publishedYearFrom: $publishedYearFrom, publishedYearTo: $publishedYearTo, numberOfIssuesFrom: $numberOfIssuesFrom, numberOfIssuesTo: $numberOfIssuesTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single material
#
# GET /v1/rest/material
# operationId: v1GetMaterial
export def "rest-material v1GetMaterial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Material unique ID
]: nothing -> record<material: record<uid: string, name: string, chemicalCompound: bool, biochemicalCompound: bool, drug: bool, poisonousSubstance: bool, explosive: bool, gemstone: bool, alloyOrComposite: bool, fuel: bool, mineral: bool, preciousMaterial: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/material" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over materials
#
# GET /v1/rest/material/search
# operationId: v1PageMaterials
export def "rest-material-search v1PageMaterials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, materials: table<uid: string, name: string, chemicalCompound: bool, biochemicalCompound: bool, drug: bool, poisonousSubstance: bool, explosive: bool, gemstone: bool, alloyOrComposite: bool, fuel: bool, mineral: bool, preciousMaterial: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/material/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching materials
#
# POST /v1/rest/material/search
# operationId: v1SearchMaterials
export def "rest-material-search v1SearchMaterials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Material name
  --chemicalCompound: string@bool-completer # Whether it should be a chemical compound
  --biochemicalCompound: string@bool-completer # Whether it should be a biochemical compound
  --drug: string@bool-completer # Whether it should be a drug
  --poisonousSubstance: string@bool-completer # Whether it should be a poisonous substance
  --explosive: string@bool-completer # Whether it should be an explosive
  --gemstone: string@bool-completer # Whether it should be a gemstone
  --alloyOrComposite: string@bool-completer # Whether it should be an alloy or a composite
  --fuel: string@bool-completer # Whether it should be a fuel
  --mineral: string@bool-completer # Whether it should be a mineral
  --preciousMaterial: string@bool-completer # Whether it should be a precious material
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, materials: table<uid: string, name: string, chemicalCompound: bool, biochemicalCompound: bool, drug: bool, poisonousSubstance: bool, explosive: bool, gemstone: bool, alloyOrComposite: bool, fuel: bool, mineral: bool, preciousMaterial: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/material/search" $qp)
  let body = {name: $name, chemicalCompound: $chemicalCompound, biochemicalCompound: $biochemicalCompound, drug: $drug, poisonousSubstance: $poisonousSubstance, explosive: $explosive, gemstone: $gemstone, alloyOrComposite: $alloyOrComposite, fuel: $fuel, mineral: $mineral, preciousMaterial: $preciousMaterial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single medical condition
#
# GET /v1/rest/medicalCondition
# operationId: v1GetMedicalCondition
export def "rest-medical-condition v1GetMedicalCondition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Medical condition unique ID
]: nothing -> record<medicalCondition: record<uid: string, name: string, psychologicalCondition: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/medicalCondition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over medical conditions
#
# GET /v1/rest/medicalCondition/search
# operationId: v1PageMedicalConditions
export def "rest-medical-condition-search v1PageMedicalConditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, medicalConditions: table<uid: string, name: string, psychologicalCondition: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/medicalCondition/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching medical conditions
#
# POST /v1/rest/medicalCondition/search
# operationId: v1SearchMedicalConditions
export def "rest-medical-condition-search v1SearchMedicalConditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Medical condition name
  --psychologicalCondition: string@bool-completer # Whether it should be a psychological condition
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, medicalConditions: table<uid: string, name: string, psychologicalCondition: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/medicalCondition/search" $qp)
  let body = {name: $name, psychologicalCondition: $psychologicalCondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single movie
#
# GET /v1/rest/movie
# operationId: v1GetMovie
export def "rest-movie v1GetMovie" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Movie unique ID
]: nothing -> record<movie: record<uid: string, title: string, mainDirector: record<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool>, titleBulgarian: string, titleCatalan: string, titleChineseTraditional: string, titleGerman: string, titleItalian: string, titleJapanese: string, titlePolish: string, titleRussian: string, titleSerbian: string, titleSpanish: string, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, usReleaseDate: string, writers: list<record>, screenplayAuthors: list<record>, storyAuthors: list<record>, directors: list<record>, producers: list<record>, staff: list<record>, performers: list<record>, stuntPerformers: list<record>, standInPerformers: list<record>, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/movie" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over movies
#
# GET /v1/rest/movie/search
# operationId: v1PageMovies
export def "rest-movie-search v1PageMovies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, movies: table<uid: string, title: string, mainDirector: record, titleBulgarian: string, titleCatalan: string, titleChineseTraditional: string, titleGerman: string, titleItalian: string, titleJapanese: string, titlePolish: string, titleRussian: string, titleSerbian: string, titleSpanish: string, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, usReleaseDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/movie/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching movies
#
# POST /v1/rest/movie/search
# operationId: v1SearchMovies
export def "rest-movie-search v1SearchMovies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Movie title
  --stardateFrom: float # Starting stardate of movie story (format: float)
  --stardateTo: float # Ending stardate of movie story (format: float)
  --yearFrom: int # Starting year of movie story (format: int32)
  --yearTo: int # Ending year of movie story (format: int32)
  --usReleaseDateFrom: string # Minimal date the movie was first released in the United States (format: date)
  --usReleaseDateTo: string # Maximal date the movie was first released in the United States (format: date)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, movies: table<uid: string, title: string, mainDirector: record, titleBulgarian: string, titleCatalan: string, titleChineseTraditional: string, titleGerman: string, titleItalian: string, titleJapanese: string, titlePolish: string, titleRussian: string, titleSerbian: string, titleSpanish: string, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, usReleaseDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/movie/search" $qp)
  let body = {title: $title, stardateFrom: $stardateFrom, stardateTo: $stardateTo, yearFrom: $yearFrom, yearTo: $yearTo, usReleaseDateFrom: $usReleaseDateFrom, usReleaseDateTo: $usReleaseDateTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single occupation
#
# GET /v1/rest/occupation
# DEPRECATED
# operationId: v1GetOccupation
@deprecated
export def "rest-occupation v1GetOccupation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Occupation unique ID
]: nothing -> record<occupation: record<uid: string, name: string, legalOccupation: bool, medicalOccupation: bool, scientificOccupation: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/occupation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over occupations
#
# GET /v1/rest/occupation/search
# DEPRECATED
# operationId: v1PageOccupations
@deprecated
export def "rest-occupation-search v1PageOccupations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, occupations: table<uid: string, name: string, legalOccupation: bool, medicalOccupation: bool, scientificOccupation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/occupation/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching occupations
#
# POST /v1/rest/occupation/search
# DEPRECATED
# operationId: v1SearchOccupations
@deprecated
export def "rest-occupation-search v1SearchOccupations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Occupation name
  --legalOccupation: string@bool-completer # Whether it should be a legal occupation
  --medicalOccupation: string@bool-completer # Whether it should be a medical occupation
  --scientificOccupation: string@bool-completer # Whether it should be a scientific occupation
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, occupations: table<uid: string, name: string, legalOccupation: bool, medicalOccupation: bool, scientificOccupation: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/occupation/search" $qp)
  let body = {name: $name, legalOccupation: $legalOccupation, medicalOccupation: $medicalOccupation, scientificOccupation: $scientificOccupation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single occupation (V2)
#
# GET /v2/rest/occupation
# operationId: v2GetOccupation
export def "rest-occupation v2GetOccupation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Occupation unique ID
]: nothing -> record<occupation: record<uid: string, name: string, artsOccupation: bool, communicationOccupation: bool, economicOccupation: bool, educationOccupation: bool, entertainmentOccupation: bool, illegalOccupation: bool, legalOccupation: bool, medicalOccupation: bool, scientificOccupation: bool, sportsOccupation: bool, victualOccupation: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/occupation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over occupations (V2)
#
# GET /v2/rest/occupation/search
# operationId: v2PageOccupations
export def "rest-occupation-search v2PageOccupations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, occupations: table<uid: string, name: string, artsOccupation: bool, communicationOccupation: bool, economicOccupation: bool, educationOccupation: bool, entertainmentOccupation: bool, illegalOccupation: bool, legalOccupation: bool, medicalOccupation: bool, scientificOccupation: bool, sportsOccupation: bool, victualOccupation: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/occupation/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching occupations (V2)
#
# POST /v2/rest/occupation/search
# operationId: v2SearchOccupations
export def "rest-occupation-search v2SearchOccupations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Occupation name
  --artsOccupation: string@bool-completer # Whether it should be an arts occupation
  --communicationOccupation: string@bool-completer # Whether it should be a communication occupation
  --economicOccupation: string@bool-completer # Whether it should be an economic occupation
  --educationOccupation: string@bool-completer # Whether it should be an education occupation
  --entertainmentOccupation: string@bool-completer # Whether it should be an entertainment occupation
  --illegalOccupation: string@bool-completer # Whether it should be an illegal occupation
  --legalOccupation: string@bool-completer # Whether it should be a legal occupation
  --medicalOccupation: string@bool-completer # Whether it should be a medical occupation
  --scientificOccupation: string@bool-completer # Whether it should be a scientific occupation
  --sportsOccupation: string@bool-completer # Whether it should be a sports occupation
  --victualOccupation: string@bool-completer # Whether it should be a victual occupation
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, occupations: table<uid: string, name: string, artsOccupation: bool, communicationOccupation: bool, economicOccupation: bool, educationOccupation: bool, entertainmentOccupation: bool, illegalOccupation: bool, legalOccupation: bool, medicalOccupation: bool, scientificOccupation: bool, sportsOccupation: bool, victualOccupation: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/occupation/search" $qp)
  let body = {name: $name, artsOccupation: $artsOccupation, communicationOccupation: $communicationOccupation, economicOccupation: $economicOccupation, educationOccupation: $educationOccupation, entertainmentOccupation: $entertainmentOccupation, illegalOccupation: $illegalOccupation, legalOccupation: $legalOccupation, medicalOccupation: $medicalOccupation, scientificOccupation: $scientificOccupation, sportsOccupation: $sportsOccupation, victualOccupation: $victualOccupation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single organization
#
# GET /v1/rest/organization
# operationId: v1GetOrganization
export def "rest-organization v1GetOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Organization unique ID
]: nothing -> record<organization: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over organizations
#
# GET /v1/rest/organization/search
# operationId: v1PageOrganizations
export def "rest-organization-search v1PageOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, organizations: table<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/organization/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching organizations
#
# POST /v1/rest/organization/search
# operationId: v1SearchOrganizations
export def "rest-organization-search v1SearchOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Organization name
  --government: string@bool-completer # Whether it should be a government
  --intergovernmentalOrganization: string@bool-completer # Whether it should be an intergovernmental organization
  --researchOrganization: string@bool-completer # Whether it should be a research organization
  --sportOrganization: string@bool-completer # Whether it should be a sport organization
  --medicalOrganization: string@bool-completer # Whether it should be a medical organization
  --militaryOrganization: string@bool-completer # Whether it should be a military organization
  --militaryUnit: string@bool-completer # Whether it should be a military unit
  --governmentAgency: string@bool-completer # Whether it should be a government agency
  --lawEnforcementAgency: string@bool-completer # Whether it should be a law enforcement agency
  --prisonOrPenalColony: string@bool-completer # Whether it should be a prison or penal colony
  --mirror: string@bool-completer # Whether this organization should be from mirror universe
  --alternateReality: string@bool-completer # Whether this organization should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, organizations: table<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/organization/search" $qp)
  let body = {name: $name, government: $government, intergovernmentalOrganization: $intergovernmentalOrganization, researchOrganization: $researchOrganization, sportOrganization: $sportOrganization, medicalOrganization: $medicalOrganization, militaryOrganization: $militaryOrganization, militaryUnit: $militaryUnit, governmentAgency: $governmentAgency, lawEnforcementAgency: $lawEnforcementAgency, prisonOrPenalColony: $prisonOrPenalColony, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single performer
#
# GET /v1/rest/performer
# DEPRECATED
# operationId: v1GetPerformer
@deprecated
export def "rest-performer v1GetPerformer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Performer unique ID
]: nothing -> record<performer: record<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, animalPerformer: bool, disPerformer: bool, ds9Performer: bool, entPerformer: bool, filmPerformer: bool, standInPerformer: bool, stuntPerformer: bool, tasPerformer: bool, tngPerformer: bool, tosPerformer: bool, videoGamePerformer: bool, voicePerformer: bool, voyPerformer: bool, episodesPerformances: list<record>, episodesStuntPerformances: list<record>, episodesStandInPerformances: list<record>, moviesPerformances: list<record>, moviesStuntPerformances: list<record>, moviesStandInPerformances: list<record>, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/performer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over performers
#
# GET /v1/rest/performer/search
# DEPRECATED
# operationId: v1PagePerformers
@deprecated
export def "rest-performer-search v1PagePerformers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, performers: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, animalPerformer: bool, disPerformer: bool, ds9Performer: bool, entPerformer: bool, filmPerformer: bool, standInPerformer: bool, stuntPerformer: bool, tasPerformer: bool, tngPerformer: bool, tosPerformer: bool, videoGamePerformer: bool, voicePerformer: bool, voyPerformer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/performer/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching performers
#
# POST /v1/rest/performer/search
# DEPRECATED
# operationId: v1SearchPerformers
@deprecated
export def "rest-performer-search v1SearchPerformers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Performer name
  --birthName: string # Performer birth name
  --gender: string # Performer gender
  --dateOfBirthFrom: string # Minimal date the performer was born (format: date)
  --dateOfBirthTo: string # Maximal date the performer was born (format: date)
  --placeOfBirth: string # Place the performer was born
  --dateOfDeathFrom: string # Minimal date the performer died (format: date)
  --dateOfDeathTo: string # Maximal date the performer died (format: date)
  --placeOfDeath: string # Place the performer died
  --animalPerformer: string@bool-completer # Whether it should be an animal performer
  --disPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Discovery
  --ds9Performer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Deep Space Nine
  --entPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Enterprise
  --filmPerformer: string@bool-completer # Whether it should be a performer that appeared in a Star Trek movie
  --standInPerformer: string@bool-completer # Whether it should be a stand-in performer
  --stuntPerformer: string@bool-completer # Whether it should be a stunt performer
  --tasPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: The Animated Series
  --tngPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: The Next Generation
  --tosPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: The Original Series
  --videoGamePerformer: string@bool-completer # Whether it should be a video game performer
  --voicePerformer: string@bool-completer # Whether it should be a voice performer
  --voyPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Voyager
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, performers: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, animalPerformer: bool, disPerformer: bool, ds9Performer: bool, entPerformer: bool, filmPerformer: bool, standInPerformer: bool, stuntPerformer: bool, tasPerformer: bool, tngPerformer: bool, tosPerformer: bool, videoGamePerformer: bool, voicePerformer: bool, voyPerformer: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/performer/search" $qp)
  let body = {name: $name, birthName: $birthName, gender: $gender, dateOfBirthFrom: $dateOfBirthFrom, dateOfBirthTo: $dateOfBirthTo, placeOfBirth: $placeOfBirth, dateOfDeathFrom: $dateOfDeathFrom, dateOfDeathTo: $dateOfDeathTo, placeOfDeath: $placeOfDeath, animalPerformer: $animalPerformer, disPerformer: $disPerformer, ds9Performer: $ds9Performer, entPerformer: $entPerformer, filmPerformer: $filmPerformer, standInPerformer: $standInPerformer, stuntPerformer: $stuntPerformer, tasPerformer: $tasPerformer, tngPerformer: $tngPerformer, tosPerformer: $tosPerformer, videoGamePerformer: $videoGamePerformer, voicePerformer: $voicePerformer, voyPerformer: $voyPerformer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single performer (V2)
#
# GET /v2/rest/performer
# operationId: v2GetPerformer
export def "rest-performer v2GetPerformer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Performer unique ID
]: nothing -> record<performer: record<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, animalPerformer: bool, audiobookPerformer: bool, cutPerformer: bool, disPerformer: bool, ds9Performer: bool, entPerformer: bool, filmPerformer: bool, ldPerformer: bool, picPerformer: bool, proPerformer: bool, puppeteer: bool, snwPerformer: bool, standInPerformer: bool, stPerformer: bool, stuntPerformer: bool, tasPerformer: bool, tngPerformer: bool, tosPerformer: bool, videoGamePerformer: bool, voicePerformer: bool, voyPerformer: bool, episodesPerformances: list<record>, episodesStuntPerformances: list<record>, episodesStandInPerformances: list<record>, moviesPerformances: list<record>, moviesStuntPerformances: list<record>, moviesStandInPerformances: list<record>, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/performer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over performers (V2)
#
# GET /v2/rest/performer/search
# operationId: v2PagePerformers
export def "rest-performer-search v2PagePerformers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, performers: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, animalPerformer: bool, audiobookPerformer: bool, cutPerformer: bool, disPerformer: bool, ds9Performer: bool, entPerformer: bool, filmPerformer: bool, ldPerformer: bool, picPerformer: bool, proPerformer: bool, puppeteer: bool, snwPerformer: bool, standInPerformer: bool, stPerformer: bool, stuntPerformer: bool, tasPerformer: bool, tngPerformer: bool, tosPerformer: bool, videoGamePerformer: bool, voicePerformer: bool, voyPerformer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/performer/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching performers (V2)
#
# POST /v2/rest/performer/search
# operationId: v2SearchPerformers
export def "rest-performer-search v2SearchPerformers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Performer name
  --birthName: string # Performer birth name
  --gender: string # Performer gender
  --dateOfBirthFrom: string # Minimal date the performer was born (format: date)
  --dateOfBirthTo: string # Maximal date the performer was born (format: date)
  --placeOfBirth: string # Place the performer was born
  --dateOfDeathFrom: string # Minimal date the performer died (format: date)
  --dateOfDeathTo: string # Maximal date the performer died (format: date)
  --placeOfDeath: string # Place the performer died
  --animalPerformer: string@bool-completer # Whether it should be an animal performer
  --audiobookPerformer: string@bool-completer # Whether it should be an audiobook performer
  --cutPerformer: string@bool-completer # Whether it should be a cut performer
  --disPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Discovery
  --ds9Performer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Deep Space Nine
  --entPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Enterprise
  --filmPerformer: string@bool-completer # Whether it should be a performer that appeared in a Star Trek movie
  --ldPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Lower Decks
  --picPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Picard
  --proPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Prodigy
  --puppeteer: string@bool-completer # Whether it should be a puppeteer
  --snwPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Strange New Worlds
  --standInPerformer: string@bool-completer # Whether it should be a stand-in performer
  --stPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Short Treks
  --stuntPerformer: string@bool-completer # Whether it should be a stunt performer
  --tasPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: The Animated Series
  --tngPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: The Next Generation
  --tosPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: The Original Series
  --videoGamePerformer: string@bool-completer # Whether it should be a video game performer
  --voicePerformer: string@bool-completer # Whether it should be a voice performer
  --voyPerformer: string@bool-completer # Whether it should be a performer that appeared in Star Trek: Voyager
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, performers: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, animalPerformer: bool, audiobookPerformer: bool, cutPerformer: bool, disPerformer: bool, ds9Performer: bool, entPerformer: bool, filmPerformer: bool, ldPerformer: bool, picPerformer: bool, proPerformer: bool, puppeteer: bool, snwPerformer: bool, standInPerformer: bool, stPerformer: bool, stuntPerformer: bool, tasPerformer: bool, tngPerformer: bool, tosPerformer: bool, videoGamePerformer: bool, voicePerformer: bool, voyPerformer: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/performer/search" $qp)
  let body = {name: $name, birthName: $birthName, gender: $gender, dateOfBirthFrom: $dateOfBirthFrom, dateOfBirthTo: $dateOfBirthTo, placeOfBirth: $placeOfBirth, dateOfDeathFrom: $dateOfDeathFrom, dateOfDeathTo: $dateOfDeathTo, placeOfDeath: $placeOfDeath, animalPerformer: $animalPerformer, audiobookPerformer: $audiobookPerformer, cutPerformer: $cutPerformer, disPerformer: $disPerformer, ds9Performer: $ds9Performer, entPerformer: $entPerformer, filmPerformer: $filmPerformer, ldPerformer: $ldPerformer, picPerformer: $picPerformer, proPerformer: $proPerformer, puppeteer: $puppeteer, snwPerformer: $snwPerformer, standInPerformer: $standInPerformer, stPerformer: $stPerformer, stuntPerformer: $stuntPerformer, tasPerformer: $tasPerformer, tngPerformer: $tngPerformer, tosPerformer: $tosPerformer, videoGamePerformer: $videoGamePerformer, voicePerformer: $voicePerformer, voyPerformer: $voyPerformer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single season
#
# GET /v1/rest/season
# operationId: v1GetSeason
export def "rest-season v1GetSeason" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Season unique ID
]: nothing -> record<season: record<uid: string, title: string, series: record<uid: string, title: string, abbreviation: string, productionStartYear: int, productionEndYear: int, originalRunStartDate: string, originalRunEndDate: string, seasonsCount: int, episodesCount: int, featureLengthEpisodesCount: int, productionCompany: record, originalBroadcaster: record>, seasonNumber: int, numberOfEpisodes: int, episodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/season" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over seasons
#
# GET /v1/rest/season/search
# operationId: v1PageSeasons
export def "rest-season-search v1PageSeasons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, seasons: table<uid: string, title: string, series: record, seasonNumber: int, numberOfEpisodes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/season/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching seasons
#
# POST /v1/rest/season/search
# operationId: v1SearchSeasons
export def "rest-season-search v1SearchSeasons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Season title
  --seasonNumberFrom: int # Minimal season number (format: int32)
  --seasonNumberTo: int # Maximal season number (format: int32)
  --numberOfEpisodesFrom: int # Minimal number of episodes in season (format: int32)
  --numberOfEpisodesTo: int # Maximal number of episodes in season (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, seasons: table<uid: string, title: string, series: record, seasonNumber: int, numberOfEpisodes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/season/search" $qp)
  let body = {title: $title, seasonNumberFrom: $seasonNumberFrom, seasonNumberTo: $seasonNumberTo, numberOfEpisodesFrom: $numberOfEpisodesFrom, numberOfEpisodesTo: $numberOfEpisodesTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single series
#
# GET /v1/rest/series
# operationId: v1GetSeries
export def "rest-series v1GetSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Series unique ID
]: nothing -> record<series: record<uid: string, title: string, abbreviation: string, productionStartYear: int, productionEndYear: int, originalRunStartDate: string, originalRunEndDate: string, seasonsCount: int, episodesCount: int, featureLengthEpisodesCount: int, productionCompany: record<uid: string, name: string, broadcaster: bool, collectibleCompany: bool, conglomerate: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool>, originalBroadcaster: record<uid: string, name: string, broadcaster: bool, collectibleCompany: bool, conglomerate: bool, digitalVisualEffectsCompany: bool, distributor: bool, gameCompany: bool, filmEquipmentCompany: bool, makeUpEffectsStudio: bool, mattePaintingCompany: bool, modelAndMiniatureEffectsCompany: bool, postProductionCompany: bool, productionCompany: bool, propCompany: bool, recordLabel: bool, specialEffectsCompany: bool, tvAndFilmProductionCompany: bool, videoGameCompany: bool>, episodes: list<record>, seasons: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over series
#
# GET /v1/rest/series/search
# operationId: v1PageSeries
export def "rest-series-search v1PageSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, series: table<uid: string, title: string, abbreviation: string, productionStartYear: int, productionEndYear: int, originalRunStartDate: string, originalRunEndDate: string, seasonsCount: int, episodesCount: int, featureLengthEpisodesCount: int, productionCompany: record, originalBroadcaster: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/series/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching series
#
# POST /v1/rest/series/search
# operationId: v1SearchSeries
export def "rest-series-search v1SearchSeries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Series title
  --abbreviation: string # Series abbreviation
  --productionStartYearFrom: int # Minimal year the series production started (format: int32)
  --productionStartYearTo: int # Maximal year the series production started (format: int32)
  --productionEndYearFrom: int # Minimal year the series production ended (format: int32)
  --productionEndYearTo: int # Maximal year the series production ended (format: int32)
  --originalRunStartDateFrom: string # Minimal date the series originally ran from (format: date)
  --originalRunStartDateTo: string # Maximal date the series originally ran from (format: date)
  --originalRunEndDateFrom: string # Minimal date the series originally ran to (format: date)
  --originalRunEndDateTo: string # Maximal date the series originally ran to (format: date)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, series: table<uid: string, title: string, abbreviation: string, productionStartYear: int, productionEndYear: int, originalRunStartDate: string, originalRunEndDate: string, seasonsCount: int, episodesCount: int, featureLengthEpisodesCount: int, productionCompany: record, originalBroadcaster: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/series/search" $qp)
  let body = {title: $title, abbreviation: $abbreviation, productionStartYearFrom: $productionStartYearFrom, productionStartYearTo: $productionStartYearTo, productionEndYearFrom: $productionEndYearFrom, productionEndYearTo: $productionEndYearTo, originalRunStartDateFrom: $originalRunStartDateFrom, originalRunStartDateTo: $originalRunStartDateTo, originalRunEndDateFrom: $originalRunEndDateFrom, originalRunEndDateTo: $originalRunEndDateTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single soundtrack
#
# GET /v1/rest/soundtrack
# operationId: v1GetSoundtrack
export def "rest-soundtrack v1GetSoundtrack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Soundtrack unique ID
]: nothing -> record<soundtrack: record<uid: string, title: string, releaseDate: string, length: int, labels: list<record>, composers: list<record>, contributors: list<record>, orchestrators: list<record>, references: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/soundtrack" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over soundtracks
#
# GET /v1/rest/soundtrack/search
# operationId: v1PageSoundtracks
export def "rest-soundtrack-search v1PageSoundtracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, soundtracks: table<uid: string, title: string, releaseDate: string, length: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/soundtrack/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching soundtracks
#
# POST /v1/rest/soundtrack/search
# operationId: v1SearchSoundtracks
export def "rest-soundtrack-search v1SearchSoundtracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Soundtrack title
  --releaseDateFrom: string # Minimal release date (format: date)
  --releaseDateTo: string # Maximal release date (format: date)
  --lengthFrom: int # Minimal length, in seconds (format: int32)
  --lengthTo: int # Maximal length, in seconds (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, soundtracks: table<uid: string, title: string, releaseDate: string, length: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/soundtrack/search" $qp)
  let body = {title: $title, releaseDateFrom: $releaseDateFrom, releaseDateTo: $releaseDateTo, lengthFrom: $lengthFrom, lengthTo: $lengthTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single spacecraft
#
# GET /v1/rest/spacecraft
# DEPRECATED
# operationId: v1GetSpacecraft
@deprecated
export def "rest-spacecraft v1GetSpacecraft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Spacecraft unique ID
]: nothing -> record<spacecraft: record<uid: string, name: string, registry: string, status: string, dateStatus: string, spacecraftClass: record<uid: string, name: string, numberOfDecks: int, warpCapable: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record, owner: record, operator: record, affiliation: record>, owner: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, operator: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, spacecraftTypes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/spacecraft" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over spacecrafts
#
# GET /v1/rest/spacecraft/search
# DEPRECATED
# operationId: v1PageSpacecrafts
@deprecated
export def "rest-spacecraft-search v1PageSpacecrafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecrafts: table<uid: string, name: string, registry: string, status: string, dateStatus: string, spacecraftClass: record, owner: record, operator: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/spacecraft/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching spacecrafts
#
# POST /v1/rest/spacecraft/search
# DEPRECATED
# operationId: v1SearchSpacecrafts
@deprecated
export def "rest-spacecraft-search v1SearchSpacecrafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Spacecraft name
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecrafts: table<uid: string, name: string, registry: string, status: string, dateStatus: string, spacecraftClass: record, owner: record, operator: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/spacecraft/search" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single spacecraft (V2)
#
# GET /v2/rest/spacecraft
# operationId: v2GetSpacecraft
export def "rest-spacecraft v2GetSpacecraft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Spacecraft unique ID
]: nothing -> record<spacecraft: record<uid: string, name: string, registry: string, status: string, dateStatus: string, spacecraftClass: record<uid: string, name: string, numberOfDecks: int, crew: string, warpCapable: bool, mirror: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record>, owner: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, operator: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, affiliation: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, spacecraftTypes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/spacecraft" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over spacecrafts (V2)
#
# GET /v2/rest/spacecraft/search
# operationId: v2PageSpacecrafts
export def "rest-spacecraft-search v2PageSpacecrafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecrafts: table<uid: string, name: string, registry: string, status: string, dateStatus: string, spacecraftClass: record, owner: record, operator: record, affiliation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/spacecraft/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching spacecrafts (V2)
#
# POST /v2/rest/spacecraft/search
# operationId: v2SearchSpacecrafts
export def "rest-spacecraft-search v2SearchSpacecrafts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Spacecraft name
  --registry: string # Spacecraft registry
  --status: string # Spacecraft status
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecrafts: table<uid: string, name: string, registry: string, status: string, dateStatus: string, spacecraftClass: record, owner: record, operator: record, affiliation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/spacecraft/search" $qp)
  let body = {name: $name, registry: $registry, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single spacecraft class
#
# GET /v1/rest/spacecraftClass
# DEPRECATED
# operationId: v1GetSpacecraftClass
@deprecated
export def "rest-spacecraft-class v1GetSpacecraftClass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # SpacecraftClass unique ID
]: nothing -> record<spacecraftClass: record<uid: string, name: string, numberOfDecks: int, warpCapable: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record<uid: string, name: string>, owner: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, operator: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, affiliation: record<uid: string, name: string, government: bool, intergovernmentalOrganization: bool, researchOrganization: bool, sportOrganization: bool, medicalOrganization: bool, militaryOrganization: bool, militaryUnit: bool, governmentAgency: bool, lawEnforcementAgency: bool, prisonOrPenalColony: bool, mirror: bool, alternateReality: bool>, spacecraftTypes: list<record>, spacecrafts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/spacecraftClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over spacecraft classes
#
# GET /v1/rest/spacecraftClass/search
# DEPRECATED
# operationId: v1PageSpacecraftClasses
@deprecated
export def "rest-spacecraft-class-search v1PageSpacecraftClasses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecraftClasses: table<uid: string, name: string, numberOfDecks: int, warpCapable: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record, owner: record, operator: record, affiliation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/spacecraftClass/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching spacecraft classes
#
# POST /v1/rest/spacecraftClass/search
# DEPRECATED
# operationId: v1SearchSpacecraftClasses
@deprecated
export def "rest-spacecraft-class-search v1SearchSpacecraftClasses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Spacecraft class name
  --warpCapableSpecies: string@bool-completer # Whether it should be a warp-capable spacecraft class
  --alternateReality: string@bool-completer # Whether this spacecraft class should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecraftClasses: table<uid: string, name: string, numberOfDecks: int, warpCapable: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record, owner: record, operator: record, affiliation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/spacecraftClass/search" $qp)
  let body = {name: $name, warpCapableSpecies: $warpCapableSpecies, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single spacecraft class (V2)
#
# GET /v2/rest/spacecraftClass
# DEPRECATED
# operationId: v2GetSpacecraftClass
@deprecated
export def "rest-spacecraft-class v2GetSpacecraftClass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # SpacecraftClass unique ID
]: nothing -> record<spacecraftClass: record<uid: string, name: string, numberOfDecks: int, crew: string, warpCapable: bool, mirror: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record<uid: string, name: string, homeworld: record, quadrant: record, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool>, owners: list<record>, operators: list<record>, affiliations: list<record>, spacecraftTypes: list<record>, armaments: list<record>, spacecrafts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/spacecraftClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over spacecraft classes (V2)
#
# GET /v2/rest/spacecraftClass/search
# operationId: v2PageSpacecraftClasses
export def "rest-spacecraft-class-search v2PageSpacecraftClasses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecraftClasses: table<uid: string, name: string, numberOfDecks: int, crew: string, warpCapable: bool, mirror: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/spacecraftClass/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching spacecraft classes (V2)
#
# POST /v2/rest/spacecraftClass/search
# operationId: v2SearchSpacecraftClasses
export def "rest-spacecraft-class-search v2SearchSpacecraftClasses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Spacecraft class name
  --warpCapableSpecies: string@bool-completer # Whether it should be a warp-capable spacecraft class
  --mirror: string@bool-completer # Whether this spacecraft class should be from mirror universe
  --alternateReality: string@bool-completer # Whether this spacecraft class should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, spacecraftClasses: table<uid: string, name: string, numberOfDecks: int, crew: string, warpCapable: bool, mirror: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/spacecraftClass/search" $qp)
  let body = {name: $name, warpCapableSpecies: $warpCapableSpecies, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single spacecraft class (V3)
#
# GET /v3/rest/spacecraftClass
# operationId: v3GetSpacecraftClass
export def "rest-spacecraft-class v3GetSpacecraftClass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Spacecraft class unique ID
]: nothing -> record<spacecraftClass: record<uid: string, name: string, numberOfDecks: int, crew: string, warpCapable: bool, mirror: bool, alternateReality: bool, activeFrom: string, activeTo: string, species: record<uid: string, name: string, homeworld: record, quadrant: record, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool>, owners: list<record>, operators: list<record>, affiliations: list<record>, spacecraftTypes: list<record>, armaments: list<record>, defenses: list<record>, spacecrafts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/rest/spacecraftClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieval of a single species
#
# GET /v1/rest/species
# DEPRECATED
# operationId: v1GetSpecies
@deprecated
export def "rest-species v1GetSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Species unique ID
]: nothing -> record<species: record<uid: string, name: string, homeworld: record<uid: string, name: string, astronomicalObjectType: string, location: record>, quadrant: record<uid: string, name: string, astronomicalObjectType: string, location: record>, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/species" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over species
#
# GET /v1/rest/species/search
# DEPRECATED
# operationId: v1PageSpecies
@deprecated
export def "rest-species-search v1PageSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, species: table<uid: string, name: string, homeworld: record, quadrant: record, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/species/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching species
#
# POST /v1/rest/species/search
# DEPRECATED
# operationId: v1SearchSpecies
@deprecated
export def "rest-species-search v1SearchSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Species name
  --extinctSpecies: string@bool-completer # Whether it should be an extinct species
  --warpCapableSpecies: string@bool-completer # Whether it should be a warp-capable species
  --extraGalacticSpecies: string@bool-completer # Whether it should be an extra-galactic species
  --humanoidSpecies: string@bool-completer # Whether it should be a humanoid species
  --reptilianSpecies: string@bool-completer # Whether it should be a reptilian species
  --nonCorporealSpecies: string@bool-completer # Whether it should be a non-corporeal species
  --shapeshiftingSpecies: string@bool-completer # Whether it should be a shapeshifting species
  --spaceborneSpecies: string@bool-completer # Whether it should be a spaceborne species
  --telepathicSpecies: string@bool-completer # Whether it should be a telepathic species
  --transDimensionalSpecies: string@bool-completer # Whether it should be a trans-dimensional species
  --unnamedSpecies: string@bool-completer # Whether it should be a unnamed species
  --alternateReality: string@bool-completer # Whether this species should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, species: table<uid: string, name: string, homeworld: record, quadrant: record, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/species/search" $qp)
  let body = {name: $name, extinctSpecies: $extinctSpecies, warpCapableSpecies: $warpCapableSpecies, extraGalacticSpecies: $extraGalacticSpecies, humanoidSpecies: $humanoidSpecies, reptilianSpecies: $reptilianSpecies, nonCorporealSpecies: $nonCorporealSpecies, shapeshiftingSpecies: $shapeshiftingSpecies, spaceborneSpecies: $spaceborneSpecies, telepathicSpecies: $telepathicSpecies, transDimensionalSpecies: $transDimensionalSpecies, unnamedSpecies: $unnamedSpecies, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single species (V2)
#
# GET /v2/rest/species
# operationId: v2GetSpecies
export def "rest-species v2GetSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Species unique ID
]: nothing -> record<species: record<uid: string, name: string, homeworld: record<uid: string, name: string, astronomicalObjectType: string, location: record>, quadrant: record<uid: string, name: string, astronomicalObjectType: string, location: record>, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, avianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/species" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over species (V2)
#
# GET /v2/rest/species/search
# operationId: v2PageSpecies
export def "rest-species-search v2PageSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, species: table<uid: string, name: string, homeworld: record, quadrant: record, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, avianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/species/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching species (V2)
#
# POST /v2/rest/species/search
# operationId: v2SearchSpecies
export def "rest-species-search v2SearchSpecies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Species name
  --extinctSpecies: string@bool-completer # Whether it should be an extinct species
  --warpCapableSpecies: string@bool-completer # Whether it should be a warp-capable species
  --extraGalacticSpecies: string@bool-completer # Whether it should be an extra-galactic species
  --humanoidSpecies: string@bool-completer # Whether it should be a humanoid species
  --reptilianSpecies: string@bool-completer # Whether it should be a reptilian species
  --avianSpecies: string@bool-completer # Whether it should be an avian species
  --nonCorporealSpecies: string@bool-completer # Whether it should be a non-corporeal species
  --shapeshiftingSpecies: string@bool-completer # Whether it should be a shapeshifting species
  --spaceborneSpecies: string@bool-completer # Whether it should be a spaceborne species
  --telepathicSpecies: string@bool-completer # Whether it should be a telepathic species
  --transDimensionalSpecies: string@bool-completer # Whether it should be a trans-dimensional species
  --unnamedSpecies: string@bool-completer # Whether it should be a unnamed species
  --alternateReality: string@bool-completer # Whether this species should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, species: table<uid: string, name: string, homeworld: record, quadrant: record, extinctSpecies: bool, warpCapableSpecies: bool, extraGalacticSpecies: bool, humanoidSpecies: bool, reptilianSpecies: bool, avianSpecies: bool, nonCorporealSpecies: bool, shapeshiftingSpecies: bool, spaceborneSpecies: bool, telepathicSpecies: bool, transDimensionalSpecies: bool, unnamedSpecies: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/species/search" $qp)
  let body = {name: $name, extinctSpecies: $extinctSpecies, warpCapableSpecies: $warpCapableSpecies, extraGalacticSpecies: $extraGalacticSpecies, humanoidSpecies: $humanoidSpecies, reptilianSpecies: $reptilianSpecies, avianSpecies: $avianSpecies, nonCorporealSpecies: $nonCorporealSpecies, shapeshiftingSpecies: $shapeshiftingSpecies, spaceborneSpecies: $spaceborneSpecies, telepathicSpecies: $telepathicSpecies, transDimensionalSpecies: $transDimensionalSpecies, unnamedSpecies: $unnamedSpecies, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single staff member
#
# GET /v1/rest/staff
# DEPRECATED
# operationId: v1GetStaff
@deprecated
export def "rest-staff v1GetStaff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Staff unique ID
]: nothing -> record<staff: record<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool, writtenEpisodes: list<record>, teleplayAuthoredEpisodes: list<record>, storyAuthoredEpisodes: list<record>, directedEpisodes: list<record>, episodes: list<record>, writtenMovies: list<record>, screenplayAuthoredMovies: list<record>, storyAuthoredMovies: list<record>, directedMovies: list<record>, producedMovies: list<record>, movies: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/staff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over staff members
#
# GET /v1/rest/staff/search
# DEPRECATED
# operationId: v1PageStaff
@deprecated
export def "rest-staff-search v1PageStaff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, staff: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/staff/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching staff members
#
# POST /v1/rest/staff/search
# DEPRECATED
# operationId: v1SearchStaff
@deprecated
export def "rest-staff-search v1SearchStaff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Staff name
  --birthName: string # Staff birth name
  --gender: string # Staff gender
  --dateOfBirthFrom: string # Minimal date the staff was born (format: date)
  --dateOfBirthTo: string # Maximal date the staff was born (format: date)
  --placeOfBirth: string # Place the staff was born
  --dateOfDeathFrom: string # Minimal date the staff died (format: date)
  --dateOfDeathTo: string # Maximal date the staff died (format: date)
  --placeOfDeath: string # Place the staff died
  --artDepartment: string@bool-completer # Whether this person should be from art department
  --artDirector: string@bool-completer # Whether this person should be an art director
  --productionDesigner: string@bool-completer # Whether this person should be a production designer
  --cameraAndElectricalDepartment: string@bool-completer # Whether this person should be from camera and electrical department
  --cinematographer: string@bool-completer # Whether this person should be a cinematographer
  --castingDepartment: string@bool-completer # Whether this person should be from casting department
  --costumeDepartment: string@bool-completer # Whether this person should be from costume department
  --costumeDesigner: string@bool-completer # Whether this person should be a custume designer
  --director: string@bool-completer # Whether this person should be a director
  --assistantOrSecondUnitDirector: string@bool-completer # Whether this person should be an assistant or second unit director director
  --exhibitAndAttractionStaff: string@bool-completer # Whether this person should be an exhibit and attraction staff
  --filmEditor: string@bool-completer # Whether this person should be a film editor
  --linguist: string@bool-completer # Whether this person should be a linguist
  --locationStaff: string@bool-completer # Whether this person should be a location staff
  --makeupStaff: string@bool-completer # Whether this person should be a make-up staff
  --musicDepartment: string@bool-completer # Whether this person should be from music department
  --composer: string@bool-completer # Whether this person should be a composer
  --personalAssistant: string@bool-completer # Whether this person should be a personal assistant
  --producer: string@bool-completer # Whether this person should be a producer
  --productionAssociate: string@bool-completer # Whether this person should be a production associate
  --productionStaff: string@bool-completer # Whether this person should be a production staff
  --publicationStaff: string@bool-completer # Whether this person should be a publication staff
  --scienceConsultant: string@bool-completer # Whether this person should be a science consultant
  --soundDepartment: string@bool-completer # Whether this person should be from sound department
  --specialAndVisualEffectsStaff: string@bool-completer # Whether this person should be a special and visual effects staff
  --author: string@bool-completer # Whether this person should be an author
  --audioAuthor: string@bool-completer # Whether this person should be an audio author
  --calendarArtist: string@bool-completer # Whether this person should be a calendar artist
  --comicArtist: string@bool-completer # Whether this person should be a comic artist
  --comicAuthor: string@bool-completer # Whether this person should be a comic author
  --comicColorArtist: string@bool-completer # Whether this person should be a comic color artist
  --comicInteriorArtist: string@bool-completer # Whether this person should be a comic interior artist
  --comicInkArtist: string@bool-completer # Whether this person should be a comic ink artist
  --comicPencilArtist: string@bool-completer # Whether this person should be a comic pencil artist
  --comicLetterArtist: string@bool-completer # Whether this person should be a comic letter artist
  --comicStripArtist: string@bool-completer # Whether this person should be a comic strip artist
  --gameArtist: string@bool-completer # Whether this person should be a game artist
  --gameAuthor: string@bool-completer # Whether this person should be a game author
  --novelArtist: string@bool-completer # Whether this person should be a novel artist
  --novelAuthor: string@bool-completer # Whether this person should be a novel author
  --referenceArtist: string@bool-completer # Whether this person should be a reference artist
  --referenceAuthor: string@bool-completer # Whether this person should be a reference author
  --publicationArtist: string@bool-completer # Whether this person should be a publication artist
  --publicationDesigner: string@bool-completer # Whether this person should be a publication designer
  --publicationEditor: string@bool-completer # Whether this person should be a publication editor
  --publicityArtist: string@bool-completer # Whether this person should be a publicity artist
  --cbsDigitalStaff: string@bool-completer # Whether this person should be a part of CBS digital staff
  --ilmProductionStaff: string@bool-completer # Whether this person should be a part of ILM production staff
  --specialFeaturesStaff: string@bool-completer # Whether this person should be a special features artist
  --storyEditor: string@bool-completer # Whether this person should be a story editor
  --studioExecutive: string@bool-completer # Whether this person should be a studio executive
  --stuntDepartment: string@bool-completer # Whether this person should be from stunt department
  --transportationDepartment: string@bool-completer # Whether this person should be from transportation department
  --videoGameProductionStaff: string@bool-completer # Whether this person is video game production staff
  --writer: string@bool-completer # Whether this person should be a writer
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, staff: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/staff/search" $qp)
  let body = {name: $name, birthName: $birthName, gender: $gender, dateOfBirthFrom: $dateOfBirthFrom, dateOfBirthTo: $dateOfBirthTo, placeOfBirth: $placeOfBirth, dateOfDeathFrom: $dateOfDeathFrom, dateOfDeathTo: $dateOfDeathTo, placeOfDeath: $placeOfDeath, artDepartment: $artDepartment, artDirector: $artDirector, productionDesigner: $productionDesigner, cameraAndElectricalDepartment: $cameraAndElectricalDepartment, cinematographer: $cinematographer, castingDepartment: $castingDepartment, costumeDepartment: $costumeDepartment, costumeDesigner: $costumeDesigner, director: $director, assistantOrSecondUnitDirector: $assistantOrSecondUnitDirector, exhibitAndAttractionStaff: $exhibitAndAttractionStaff, filmEditor: $filmEditor, linguist: $linguist, locationStaff: $locationStaff, makeupStaff: $makeupStaff, musicDepartment: $musicDepartment, composer: $composer, personalAssistant: $personalAssistant, producer: $producer, productionAssociate: $productionAssociate, productionStaff: $productionStaff, publicationStaff: $publicationStaff, scienceConsultant: $scienceConsultant, soundDepartment: $soundDepartment, specialAndVisualEffectsStaff: $specialAndVisualEffectsStaff, author: $author, audioAuthor: $audioAuthor, calendarArtist: $calendarArtist, comicArtist: $comicArtist, comicAuthor: $comicAuthor, comicColorArtist: $comicColorArtist, comicInteriorArtist: $comicInteriorArtist, comicInkArtist: $comicInkArtist, comicPencilArtist: $comicPencilArtist, comicLetterArtist: $comicLetterArtist, comicStripArtist: $comicStripArtist, gameArtist: $gameArtist, gameAuthor: $gameAuthor, novelArtist: $novelArtist, novelAuthor: $novelAuthor, referenceArtist: $referenceArtist, referenceAuthor: $referenceAuthor, publicationArtist: $publicationArtist, publicationDesigner: $publicationDesigner, publicationEditor: $publicationEditor, publicityArtist: $publicityArtist, cbsDigitalStaff: $cbsDigitalStaff, ilmProductionStaff: $ilmProductionStaff, specialFeaturesStaff: $specialFeaturesStaff, storyEditor: $storyEditor, studioExecutive: $studioExecutive, stuntDepartment: $stuntDepartment, transportationDepartment: $transportationDepartment, videoGameProductionStaff: $videoGameProductionStaff, writer: $writer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single staff member (V2)
#
# GET /v2/rest/staff
# operationId: v2GetStaff
export def "rest-staff v2GetStaff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Staff unique ID
]: nothing -> record<staff: record<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, filmationProductionStaff: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, merchandiseStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicCoverArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool, writtenEpisodes: list<record>, teleplayAuthoredEpisodes: list<record>, storyAuthoredEpisodes: list<record>, directedEpisodes: list<record>, episodes: list<record>, writtenMovies: list<record>, screenplayAuthoredMovies: list<record>, storyAuthoredMovies: list<record>, directedMovies: list<record>, producedMovies: list<record>, movies: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/staff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over staff members (V2)
#
# GET /v2/rest/staff/search
# operationId: v2PageStaff
export def "rest-staff-search v2PageStaff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, staff: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, filmationProductionStaff: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, merchandiseStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicCoverArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/staff/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching staff members (v2)
#
# POST /v2/rest/staff/search
# operationId: v2SearchStaff
export def "rest-staff-search v2SearchStaff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Staff name
  --birthName: string # Staff birth name
  --gender: string # Staff gender
  --dateOfBirthFrom: string # Minimal date the staff was born (format: date)
  --dateOfBirthTo: string # Maximal date the staff was born (format: date)
  --placeOfBirth: string # Place the staff was born
  --dateOfDeathFrom: string # Minimal date the staff died (format: date)
  --dateOfDeathTo: string # Maximal date the staff died (format: date)
  --placeOfDeath: string # Place the staff died
  --artDepartment: string@bool-completer # Whether this person should be from art department
  --artDirector: string@bool-completer # Whether this person should be an art director
  --productionDesigner: string@bool-completer # Whether this person should be a production designer
  --cameraAndElectricalDepartment: string@bool-completer # Whether this person should be from camera and electrical department
  --cinematographer: string@bool-completer # Whether this person should be a cinematographer
  --castingDepartment: string@bool-completer # Whether this person should be from casting department
  --costumeDepartment: string@bool-completer # Whether this person should be from costume department
  --costumeDesigner: string@bool-completer # Whether this person should be a custume designer
  --director: string@bool-completer # Whether this person should be a director
  --assistantOrSecondUnitDirector: string@bool-completer # Whether this person should be an assistant or second unit director director
  --exhibitAndAttractionStaff: string@bool-completer # Whether this person should be an exhibit and attraction staff
  --filmEditor: string@bool-completer # Whether this person should be a film editor
  --filmationProductionStaff: string@bool-completer # Whether this person should be a part of Filmation production staff
  --linguist: string@bool-completer # Whether this person should be a linguist
  --locationStaff: string@bool-completer # Whether this person should be a location staff
  --makeupStaff: string@bool-completer # Whether this person should be a make-up staff
  --merchandiseStaff: string@bool-completer # Whether this person should be a merchandise staff
  --musicDepartment: string@bool-completer # Whether this person should be from music department
  --composer: string@bool-completer # Whether this person should be a composer
  --personalAssistant: string@bool-completer # Whether this person should be a personal assistant
  --producer: string@bool-completer # Whether this person should be a producer
  --productionAssociate: string@bool-completer # Whether this person should be a production associate
  --productionStaff: string@bool-completer # Whether this person should be a production staff
  --publicationStaff: string@bool-completer # Whether this person should be a publication staff
  --scienceConsultant: string@bool-completer # Whether this person should be a science consultant
  --soundDepartment: string@bool-completer # Whether this person should be from sound department
  --specialAndVisualEffectsStaff: string@bool-completer # Whether this person should be a special and visual effects staff
  --author: string@bool-completer # Whether this person should be an author
  --audioAuthor: string@bool-completer # Whether this person should be an audio author
  --calendarArtist: string@bool-completer # Whether this person should be a calendar artist
  --comicArtist: string@bool-completer # Whether this person should be a comic artist
  --comicAuthor: string@bool-completer # Whether this person should be a comic author
  --comicColorArtist: string@bool-completer # Whether this person should be a comic color artist
  --comicCoverArtist: string@bool-completer # Whether this person should be a comic cover artist
  --comicInteriorArtist: string@bool-completer # Whether this person should be a comic interior artist
  --comicInkArtist: string@bool-completer # Whether this person should be a comic ink artist
  --comicPencilArtist: string@bool-completer # Whether this person should be a comic pencil artist
  --comicLetterArtist: string@bool-completer # Whether this person should be a comic letter artist
  --comicStripArtist: string@bool-completer # Whether this person should be a comic strip artist
  --gameArtist: string@bool-completer # Whether this person should be a game artist
  --gameAuthor: string@bool-completer # Whether this person should be a game author
  --novelArtist: string@bool-completer # Whether this person should be a novel artist
  --novelAuthor: string@bool-completer # Whether this person should be a novel author
  --referenceArtist: string@bool-completer # Whether this person should be a reference artist
  --referenceAuthor: string@bool-completer # Whether this person should be a reference author
  --publicationArtist: string@bool-completer # Whether this person should be a publication artist
  --publicationDesigner: string@bool-completer # Whether this person should be a publication designer
  --publicationEditor: string@bool-completer # Whether this person should be a publication editor
  --publicityArtist: string@bool-completer # Whether this person should be a publicity artist
  --cbsDigitalStaff: string@bool-completer # Whether this person should be a part of CBS digital staff
  --ilmProductionStaff: string@bool-completer # Whether this person should be a part of ILM production staff
  --specialFeaturesStaff: string@bool-completer # Whether this person should be a special features artist
  --storyEditor: string@bool-completer # Whether this person should be a story editor
  --studioExecutive: string@bool-completer # Whether this person should be a studio executive
  --stuntDepartment: string@bool-completer # Whether this person should be from stunt department
  --transportationDepartment: string@bool-completer # Whether this person should be from transportation department
  --videoGameProductionStaff: string@bool-completer # Whether this person is video game production staff
  --writer: string@bool-completer # Whether this person should be a writer
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, staff: table<uid: string, name: string, birthName: string, gender: string, dateOfBirth: string, placeOfBirth: string, dateOfDeath: string, placeOfDeath: string, artDepartment: bool, artDirector: bool, productionDesigner: bool, cameraAndElectricalDepartment: bool, cinematographer: bool, castingDepartment: bool, costumeDepartment: bool, costumeDesigner: bool, director: bool, assistantOrSecondUnitDirector: bool, exhibitAndAttractionStaff: bool, filmEditor: bool, filmationProductionStaff: bool, linguist: bool, locationStaff: bool, makeupStaff: bool, merchandiseStaff: bool, musicDepartment: bool, composer: bool, personalAssistant: bool, producer: bool, productionAssociate: bool, productionStaff: bool, publicationStaff: bool, scienceConsultant: bool, soundDepartment: bool, specialAndVisualEffectsStaff: bool, author: bool, audioAuthor: bool, calendarArtist: bool, comicArtist: bool, comicAuthor: bool, comicColorArtist: bool, comicCoverArtist: bool, comicInteriorArtist: bool, comicInkArtist: bool, comicPencilArtist: bool, comicLetterArtist: bool, comicStripArtist: bool, gameArtist: bool, gameAuthor: bool, novelArtist: bool, novelAuthor: bool, referenceArtist: bool, referenceAuthor: bool, publicationArtist: bool, publicationDesigner: bool, publicationEditor: bool, publicityArtist: bool, cbsDigitalStaff: bool, ilmProductionStaff: bool, specialFeaturesStaff: bool, storyEditor: bool, studioExecutive: bool, stuntDepartment: bool, transportationDepartment: bool, videoGameProductionStaff: bool, writer: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/staff/search" $qp)
  let body = {name: $name, birthName: $birthName, gender: $gender, dateOfBirthFrom: $dateOfBirthFrom, dateOfBirthTo: $dateOfBirthTo, placeOfBirth: $placeOfBirth, dateOfDeathFrom: $dateOfDeathFrom, dateOfDeathTo: $dateOfDeathTo, placeOfDeath: $placeOfDeath, artDepartment: $artDepartment, artDirector: $artDirector, productionDesigner: $productionDesigner, cameraAndElectricalDepartment: $cameraAndElectricalDepartment, cinematographer: $cinematographer, castingDepartment: $castingDepartment, costumeDepartment: $costumeDepartment, costumeDesigner: $costumeDesigner, director: $director, assistantOrSecondUnitDirector: $assistantOrSecondUnitDirector, exhibitAndAttractionStaff: $exhibitAndAttractionStaff, filmEditor: $filmEditor, filmationProductionStaff: $filmationProductionStaff, linguist: $linguist, locationStaff: $locationStaff, makeupStaff: $makeupStaff, merchandiseStaff: $merchandiseStaff, musicDepartment: $musicDepartment, composer: $composer, personalAssistant: $personalAssistant, producer: $producer, productionAssociate: $productionAssociate, productionStaff: $productionStaff, publicationStaff: $publicationStaff, scienceConsultant: $scienceConsultant, soundDepartment: $soundDepartment, specialAndVisualEffectsStaff: $specialAndVisualEffectsStaff, author: $author, audioAuthor: $audioAuthor, calendarArtist: $calendarArtist, comicArtist: $comicArtist, comicAuthor: $comicAuthor, comicColorArtist: $comicColorArtist, comicCoverArtist: $comicCoverArtist, comicInteriorArtist: $comicInteriorArtist, comicInkArtist: $comicInkArtist, comicPencilArtist: $comicPencilArtist, comicLetterArtist: $comicLetterArtist, comicStripArtist: $comicStripArtist, gameArtist: $gameArtist, gameAuthor: $gameAuthor, novelArtist: $novelArtist, novelAuthor: $novelAuthor, referenceArtist: $referenceArtist, referenceAuthor: $referenceAuthor, publicationArtist: $publicationArtist, publicationDesigner: $publicationDesigner, publicationEditor: $publicationEditor, publicityArtist: $publicityArtist, cbsDigitalStaff: $cbsDigitalStaff, ilmProductionStaff: $ilmProductionStaff, specialFeaturesStaff: $specialFeaturesStaff, storyEditor: $storyEditor, studioExecutive: $studioExecutive, stuntDepartment: $stuntDepartment, transportationDepartment: $transportationDepartment, videoGameProductionStaff: $videoGameProductionStaff, writer: $writer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single technology piece
#
# GET /v1/rest/technology
# DEPRECATED
# operationId: v1GetTechnology
@deprecated
export def "rest-technology v1GetTechnology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Technology unique ID
]: nothing -> record<technology: record<uid: string, name: string, borgTechnology: bool, borgComponent: bool, communicationsTechnology: bool, computerTechnology: bool, computerProgramming: bool, subroutine: bool, database: bool, energyTechnology: bool, fictionalTechnology: bool, holographicTechnology: bool, identificationTechnology: bool, lifeSupportTechnology: bool, sensorTechnology: bool, shieldTechnology: bool, tool: bool, culinaryTool: bool, engineeringTool: bool, householdTool: bool, medicalEquipment: bool, transporterTechnology: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/technology" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over technology pieces
#
# GET /v1/rest/technology/search
# DEPRECATED
# operationId: v1PageTechnology
@deprecated
export def "rest-technology-search v1PageTechnology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, technology: table<uid: string, name: string, borgTechnology: bool, borgComponent: bool, communicationsTechnology: bool, computerTechnology: bool, computerProgramming: bool, subroutine: bool, database: bool, energyTechnology: bool, fictionalTechnology: bool, holographicTechnology: bool, identificationTechnology: bool, lifeSupportTechnology: bool, sensorTechnology: bool, shieldTechnology: bool, tool: bool, culinaryTool: bool, engineeringTool: bool, householdTool: bool, medicalEquipment: bool, transporterTechnology: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/technology/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching technology pieces
#
# POST /v1/rest/technology/search
# DEPRECATED
# operationId: v1SearchTechnology
@deprecated
export def "rest-technology-search v1SearchTechnology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Technology name
  --borgTechnology: string@bool-completer # Whether it should be a Borg technology
  --borgComponent: string@bool-completer # Whether it should be a Borg component
  --communicationsTechnology: string@bool-completer # Whether it should be a communications technology
  --computerTechnology: string@bool-completer # Whether it should be a computer technology
  --computerProgramming: string@bool-completer # Whether it should be a technology related to computer programming
  --subroutine: string@bool-completer # Whether it should be a subroutine
  --database: string@bool-completer # Whether it should be a database
  --energyTechnology: string@bool-completer # Whether it should be a energy technology
  --fictionalTechnology: string@bool-completer # Whether it should be a fictional technology
  --holographicTechnology: string@bool-completer # Whether it should be a holographic technology
  --identificationTechnology: string@bool-completer # Whether it should be a identification technology
  --lifeSupportTechnology: string@bool-completer # Whether it should be a life support technology
  --sensorTechnology: string@bool-completer # Whether it should be a sensor technology
  --shieldTechnology: string@bool-completer # Whether it should be a shield technology
  --tool: string@bool-completer # Whether it should be a tool
  --culinaryTool: string@bool-completer # Whether it should be a culinary tool
  --engineeringTool: string@bool-completer # Whether it should be a engineering tool
  --householdTool: string@bool-completer # Whether it should be a household tool
  --medicalEquipment: string@bool-completer # Whether it should be a medical equipment
  --transporterTechnology: string@bool-completer # Whether it's a transporter technology
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, technology: table<uid: string, name: string, borgTechnology: bool, borgComponent: bool, communicationsTechnology: bool, computerTechnology: bool, computerProgramming: bool, subroutine: bool, database: bool, energyTechnology: bool, fictionalTechnology: bool, holographicTechnology: bool, identificationTechnology: bool, lifeSupportTechnology: bool, sensorTechnology: bool, shieldTechnology: bool, tool: bool, culinaryTool: bool, engineeringTool: bool, householdTool: bool, medicalEquipment: bool, transporterTechnology: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/technology/search" $qp)
  let body = {name: $name, borgTechnology: $borgTechnology, borgComponent: $borgComponent, communicationsTechnology: $communicationsTechnology, computerTechnology: $computerTechnology, computerProgramming: $computerProgramming, subroutine: $subroutine, database: $database, energyTechnology: $energyTechnology, fictionalTechnology: $fictionalTechnology, holographicTechnology: $holographicTechnology, identificationTechnology: $identificationTechnology, lifeSupportTechnology: $lifeSupportTechnology, sensorTechnology: $sensorTechnology, shieldTechnology: $shieldTechnology, tool: $tool, culinaryTool: $culinaryTool, engineeringTool: $engineeringTool, householdTool: $householdTool, medicalEquipment: $medicalEquipment, transporterTechnology: $transporterTechnology} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single technology piece (V2)
#
# GET /v2/rest/technology
# operationId: v2GetTechnology
export def "rest-technology v2GetTechnology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Technology unique ID
]: nothing -> record<technology: record<uid: string, name: string, borgTechnology: bool, borgComponent: bool, communicationsTechnology: bool, computerTechnology: bool, computerProgramming: bool, subroutine: bool, database: bool, energyTechnology: bool, fictionalTechnology: bool, holographicTechnology: bool, identificationTechnology: bool, lifeSupportTechnology: bool, sensorTechnology: bool, shieldTechnology: bool, securityTechnology: bool, propulsionTechnology: bool, spacecraftComponent: bool, warpTechnology: bool, transwarpTechnology: bool, timeTravelTechnology: bool, militaryTechnology: bool, victualTechnology: bool, tool: bool, culinaryTool: bool, engineeringTool: bool, householdTool: bool, medicalEquipment: bool, transporterTechnology: bool, transportationTechnology: bool, weaponComponent: bool, artificialLifeformComponent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/technology" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over technology pieces (V2)
#
# GET /v2/rest/technology/search
# operationId: v2PageTechnology
export def "rest-technology-search v2PageTechnology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, technology: table<uid: string, name: string, borgTechnology: bool, borgComponent: bool, communicationsTechnology: bool, computerTechnology: bool, computerProgramming: bool, subroutine: bool, database: bool, energyTechnology: bool, fictionalTechnology: bool, holographicTechnology: bool, identificationTechnology: bool, lifeSupportTechnology: bool, sensorTechnology: bool, shieldTechnology: bool, securityTechnology: bool, propulsionTechnology: bool, spacecraftComponent: bool, warpTechnology: bool, transwarpTechnology: bool, timeTravelTechnology: bool, militaryTechnology: bool, victualTechnology: bool, tool: bool, culinaryTool: bool, engineeringTool: bool, householdTool: bool, medicalEquipment: bool, transporterTechnology: bool, transportationTechnology: bool, weaponComponent: bool, artificialLifeformComponent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/technology/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching technology pieces (V2)
#
# POST /v2/rest/technology/search
# operationId: v2SearchTechnology
export def "rest-technology-search v2SearchTechnology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Technology name
  --borgTechnology: string@bool-completer # Whether it should be a Borg technology
  --borgComponent: string@bool-completer # Whether it should be a Borg component
  --communicationsTechnology: string@bool-completer # Whether it should be a communications technology
  --computerTechnology: string@bool-completer # Whether it should be a computer technology
  --computerProgramming: string@bool-completer # Whether it should be a technology related to computer programming
  --subroutine: string@bool-completer # Whether it should be a subroutine
  --database: string@bool-completer # Whether it should be a database
  --energyTechnology: string@bool-completer # Whether it should be a energy technology
  --fictionalTechnology: string@bool-completer # Whether it should be a fictional technology
  --holographicTechnology: string@bool-completer # Whether it should be a holographic technology
  --identificationTechnology: string@bool-completer # Whether it should be a identification technology
  --lifeSupportTechnology: string@bool-completer # Whether it should be a life support technology
  --sensorTechnology: string@bool-completer # Whether it should be a sensor technology
  --shieldTechnology: string@bool-completer # Whether it should be a shield technology
  --securityTechnology: string@bool-completer # Whether it should be a security technology
  --propulsionTechnology: string@bool-completer # Whether it should be a propulsion technology
  --spacecraftComponent: string@bool-completer # Whether it should be a spacecraft component
  --warpTechnology: string@bool-completer # Whether it should be a warp technology
  --transwarpTechnology: string@bool-completer # Whether it should be a transwarp technology
  --timeTravelTechnology: string@bool-completer # Whether it should be a time travel technology
  --militaryTechnology: string@bool-completer # Whether it should be a military technology
  --victualTechnology: string@bool-completer # Whether it should be a victual technology
  --tool: string@bool-completer # Whether it should be a tool
  --culinaryTool: string@bool-completer # Whether it should be a culinary tool
  --engineeringTool: string@bool-completer # Whether it should be a engineering tool
  --householdTool: string@bool-completer # Whether it should be a household tool
  --medicalEquipment: string@bool-completer # Whether it should be a medical equipment
  --transporterTechnology: string@bool-completer # Whether it's a transporter technology
  --transportationTechnology: string@bool-completer # Whether it's a transportation technology
  --weaponComponent: string@bool-completer # Whether it's a weapon component
  --artificialLifeformComponent: string@bool-completer # Whether it's an artificial lifeform component
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, technology: table<uid: string, name: string, borgTechnology: bool, borgComponent: bool, communicationsTechnology: bool, computerTechnology: bool, computerProgramming: bool, subroutine: bool, database: bool, energyTechnology: bool, fictionalTechnology: bool, holographicTechnology: bool, identificationTechnology: bool, lifeSupportTechnology: bool, sensorTechnology: bool, shieldTechnology: bool, securityTechnology: bool, propulsionTechnology: bool, spacecraftComponent: bool, warpTechnology: bool, transwarpTechnology: bool, timeTravelTechnology: bool, militaryTechnology: bool, victualTechnology: bool, tool: bool, culinaryTool: bool, engineeringTool: bool, householdTool: bool, medicalEquipment: bool, transporterTechnology: bool, transportationTechnology: bool, weaponComponent: bool, artificialLifeformComponent: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/technology/search" $qp)
  let body = {name: $name, borgTechnology: $borgTechnology, borgComponent: $borgComponent, communicationsTechnology: $communicationsTechnology, computerTechnology: $computerTechnology, computerProgramming: $computerProgramming, subroutine: $subroutine, database: $database, energyTechnology: $energyTechnology, fictionalTechnology: $fictionalTechnology, holographicTechnology: $holographicTechnology, identificationTechnology: $identificationTechnology, lifeSupportTechnology: $lifeSupportTechnology, sensorTechnology: $sensorTechnology, shieldTechnology: $shieldTechnology, securityTechnology: $securityTechnology, propulsionTechnology: $propulsionTechnology, spacecraftComponent: $spacecraftComponent, warpTechnology: $warpTechnology, transwarpTechnology: $transwarpTechnology, timeTravelTechnology: $timeTravelTechnology, militaryTechnology: $militaryTechnology, victualTechnology: $victualTechnology, tool: $tool, culinaryTool: $culinaryTool, engineeringTool: $engineeringTool, householdTool: $householdTool, medicalEquipment: $medicalEquipment, transporterTechnology: $transporterTechnology, transportationTechnology: $transportationTechnology, weaponComponent: $weaponComponent, artificialLifeformComponent: $artificialLifeformComponent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single title
#
# GET /v1/rest/title
# DEPRECATED
# operationId: v1GetTitle
@deprecated
export def "rest-title v1GetTitle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Title unique ID
]: nothing -> record<title: record<uid: string, name: string, militaryRank: bool, fleetRank: bool, religiousTitle: bool, position: bool, mirror: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/title" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over titles
#
# GET /v1/rest/title/search
# DEPRECATED
# operationId: v1PageTitles
@deprecated
export def "rest-title-search v1PageTitles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, titles: table<uid: string, name: string, militaryRank: bool, fleetRank: bool, religiousTitle: bool, position: bool, mirror: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/title/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching titles
#
# POST /v1/rest/title/search
# DEPRECATED
# operationId: v1SearchTitles
@deprecated
export def "rest-title-search v1SearchTitles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Title name
  --militaryRank: string@bool-completer # Whether it should be a military rank
  --fleetRank: string@bool-completer # Whether it should be a fleet rank
  --religiousTitle: string@bool-completer # Whether it should be a religious title
  --position: string@bool-completer # Whether it should be a position
  --mirror: string@bool-completer # Whether this title should be from mirror universe
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, titles: table<uid: string, name: string, militaryRank: bool, fleetRank: bool, religiousTitle: bool, position: bool, mirror: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/title/search" $qp)
  let body = {name: $name, militaryRank: $militaryRank, fleetRank: $fleetRank, religiousTitle: $religiousTitle, position: $position, mirror: $mirror} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single title (V2)
#
# GET /v2/rest/title
# operationId: v2GetTitle
export def "rest-title v2GetTitle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Title unique ID
]: nothing -> record<title: record<uid: string, name: string, militaryRank: bool, fleetRank: bool, religiousTitle: bool, educationTitle: bool, mirror: bool, characters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/title" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over titles (V2)
#
# GET /v2/rest/title/search
# operationId: v2PageTitles
export def "rest-title-search v2PageTitles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, titles: table<uid: string, name: string, militaryRank: bool, fleetRank: bool, religiousTitle: bool, educationTitle: bool, mirror: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/title/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching titles (V2)
#
# POST /v2/rest/title/search
# operationId: v2SearchTitles
export def "rest-title-search v2SearchTitles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Title name
  --militaryRank: string@bool-completer # Whether it should be a military rank
  --fleetRank: string@bool-completer # Whether it should be a fleet rank
  --religiousTitle: string@bool-completer # Whether it should be a religious title
  --educationTitle: string@bool-completer # Whether it should be a education title
  --mirror: string@bool-completer # Whether this title should be from mirror universe
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, titles: table<uid: string, name: string, militaryRank: bool, fleetRank: bool, religiousTitle: bool, educationTitle: bool, mirror: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/title/search" $qp)
  let body = {name: $name, militaryRank: $militaryRank, fleetRank: $fleetRank, religiousTitle: $religiousTitle, educationTitle: $educationTitle, mirror: $mirror} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single trading card
#
# GET /v1/rest/tradingCard
# operationId: v1GetTradingCard
export def "rest-trading-card v1GetTradingCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Trading card unique ID
]: nothing -> record<tradingCard: record<uid: string, name: string, tradingCardSet: record<uid: string, name: string, releaseYear: int, releaseMonth: int, releaseDay: int, cardsPerPack: int, packsPerBox: int, boxesPerCase: int, productionRun: int, productionRunUnit: string, cardWidth: float, cardHeight: float>, tradingCardDeck: record<uid: string, name: string, frequency: string, tradingCardSet: record>, number: string, releaseYear: int, productionRun: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over trading cards
#
# GET /v1/rest/tradingCard/search
# operationId: v1PageTradingCards
export def "rest-trading-card-search v1PageTradingCards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, tradingCards: table<uid: string, name: string, number: string, releaseYear: int, productionRun: int, tradingCardSet: record, tradingCardDeck: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCard/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching trading cards
#
# POST /v1/rest/tradingCard/search
# operationId: v1SearchTradingCards
export def "rest-trading-card-search v1SearchTradingCards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Trading card name
  --tradingCardDeckUid: string # UID of trading card deck
  --tradingCardSetUid: string # UID of trading card set
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, tradingCards: table<uid: string, name: string, number: string, releaseYear: int, productionRun: int, tradingCardSet: record, tradingCardDeck: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCard/search" $qp)
  let body = {name: $name, tradingCardDeckUid: $tradingCardDeckUid, tradingCardSetUid: $tradingCardSetUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single trading card deck
#
# GET /v1/rest/tradingCardDeck
# operationId: v1GetTradingCardDeck
export def "rest-trading-card-deck v1GetTradingCardDeck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # trading card deck unique ID
]: nothing -> record<tradingCardDeck: record<uid: string, name: string, frequency: string, tradingCardSet: record<uid: string, name: string>, tradingCards: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCardDeck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over trading card decks
#
# GET /v1/rest/tradingCardDeck/search
# operationId: v1PageTradingCardDecks
export def "rest-trading-card-deck-search v1PageTradingCardDecks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, tradingCardDecks: table<uid: string, name: string, frequency: string, tradingCardSet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCardDeck/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching trading card decks
#
# POST /v1/rest/tradingCardDeck/search
# operationId: v1SearchTradingCardDecks
export def "rest-trading-card-deck-search v1SearchTradingCardDecks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Trading card deck name
  --tradingCardSetUid: string # UID of trading card set
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, tradingCardDecks: table<uid: string, name: string, frequency: string, tradingCardSet: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCardDeck/search" $qp)
  let body = {name: $name, tradingCardSetUid: $tradingCardSetUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single trading card set
#
# GET /v1/rest/tradingCardSet
# operationId: v1GetTradingCardSet
export def "rest-trading-card-set v1GetTradingCardSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Trading card set unique ID
]: nothing -> record<tradingCardSet: record<uid: string, name: string, releaseYear: int, releaseMonth: int, releaseDay: int, cardsPerPack: int, packsPerBox: int, boxesPerCase: int, productionRun: int, productionRunUnit: string, cardWidth: float, cardHeight: float, manufacturers: list<record>, tradingCardDecks: list<record>, tradingCards: list<record>, countriesOfOrigin: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCardSet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over trading card sets
#
# GET /v1/rest/tradingCardSet/search
# operationId: v1PageTradingCardSets
export def "rest-trading-card-set-search v1PageTradingCardSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, tradingCardSets: table<uid: string, name: string, releaseYear: int, releaseMonth: int, releaseDay: int, cardsPerPack: int, packsPerBox: int, boxesPerCase: int, productionRun: int, productionRunUnit: string, cardWidth: float, cardHeight: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCardSet/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching trading card sets
#
# POST /v1/rest/tradingCardSet/search
# operationId: v1SearchTradingCardSets
export def "rest-trading-card-set-search v1SearchTradingCardSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Trading card set name
  --releaseYearFrom: int # Starting year the trading card set was released (format: int32)
  --releaseYearTo: int # Ending year the trading card set was released (format: int32)
  --cardsPerPackFrom: int # Minimal number of cards per deck (format: int32)
  --cardsPerPackTo: int # Minimal number of cards per deck (format: int32)
  --packsPerBoxFrom: int # Minimal number of packs per box (format: int32)
  --packsPerBoxTo: int # Minimal number of packs per box (format: int32)
  --boxesPerCaseFrom: int # Minimal number of boxes per case (format: int32)
  --boxesPerCaseTo: int # Minimal number of boxes per case (format: int32)
  --productionRunFrom: int # Minimal production run (format: int32)
  --productionRunTo: int # Minimal production run (format: int32)
  --productionRunUnit: string # Production run unit
  --cardWidthFrom: float # Minimal card width, in inches (format: double)
  --cardWidthTo: float # Minimal card width, in inches (format: double)
  --cardHeightFrom: float # Minimal card height, in inches (format: double)
  --cardHeightTo: float # Minimal card height, in inches (format: double)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, tradingCardSets: table<uid: string, name: string, releaseYear: int, releaseMonth: int, releaseDay: int, cardsPerPack: int, packsPerBox: int, boxesPerCase: int, productionRun: int, productionRunUnit: string, cardWidth: float, cardHeight: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/tradingCardSet/search" $qp)
  let body = {name: $name, releaseYearFrom: $releaseYearFrom, releaseYearTo: $releaseYearTo, cardsPerPackFrom: $cardsPerPackFrom, cardsPerPackTo: $cardsPerPackTo, packsPerBoxFrom: $packsPerBoxFrom, packsPerBoxTo: $packsPerBoxTo, boxesPerCaseFrom: $boxesPerCaseFrom, boxesPerCaseTo: $boxesPerCaseTo, productionRunFrom: $productionRunFrom, productionRunTo: $productionRunTo, productionRunUnit: $productionRunUnit, cardWidthFrom: $cardWidthFrom, cardWidthTo: $cardWidthTo, cardHeightFrom: $cardHeightFrom, cardHeightTo: $cardHeightTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single video game
#
# GET /v1/rest/videoGame
# operationId: v1GetVideoGame
export def "rest-video-game v1GetVideoGame" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # VideoGame unique ID
]: nothing -> record<videoGame: record<uid: string, title: string, releaseDate: string, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, systemRequirements: string, publishers: list<record>, developers: list<record>, platforms: list<record>, genres: list<record>, ratings: list<record>, references: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/videoGame" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over video games
#
# GET /v1/rest/videoGame/search
# operationId: v1PageVideoGames
export def "rest-video-game-search v1PageVideoGames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, videoGames: table<uid: string, title: string, releaseDate: string, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, systemRequirements: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/videoGame/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching video games
#
# POST /v1/rest/videoGame/search
# operationId: v1SearchVideoGames
export def "rest-video-game-search v1SearchVideoGames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Video game title
  --releaseDateFrom: string # Minimal date the video game was first released (format: date)
  --releaseDateTo: string # Minimal date the video game was first released (format: date)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, videoGames: table<uid: string, title: string, releaseDate: string, stardateFrom: float, stardateTo: float, yearFrom: int, yearTo: int, systemRequirements: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/videoGame/search" $qp)
  let body = {title: $title, releaseDateFrom: $releaseDateFrom, releaseDateTo: $releaseDateTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single video release
#
# GET /v1/rest/videoRelease
# DEPRECATED
# operationId: v1GetVideoRelease
@deprecated
export def "rest-video-release v1GetVideoRelease" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Video release unique ID
]: nothing -> record<videoRelease: record<uid: string, title: string, series: record<uid: string, title: string, abbreviation: string, productionStartYear: int, productionEndYear: int, originalRunStartDate: string, originalRunEndDate: string, seasonsCount: int, episodesCount: int, featureLengthEpisodesCount: int, productionCompany: record, originalBroadcaster: record>, season: record<uid: string, title: string, series: record, seasonNumber: int, numberOfEpisodes: int>, format: string, numberOfEpisodes: int, numberOfFeatureLengthEpisodes: int, numberOfDataCarriers: int, runTime: int, yearFrom: int, yearTo: int, regionFreeReleaseDate: string, region1AReleaseDate: string, region1SlimlineReleaseDate: string, region2BReleaseDate: string, region2SlimlineReleaseDate: string, region4AReleaseDate: string, region4SlimlineReleaseDate: string, amazonDigitalRelease: bool, dailymotionDigitalRelease: bool, googlePlayDigitalRelease: bool, itunesDigitalRelease: bool, ultraVioletDigitalRelease: bool, vimeoDigitalRelease: bool, vuduDigitalRelease: bool, xboxSmartGlassDigitalRelease: bool, youTubeDigitalRelease: bool, netflixDigitalRelease: bool, references: list<record>, ratings: list<record>, languages: list<record>, languagesSubtitles: list<record>, languagesDubbed: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/videoRelease" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over video releases
#
# GET /v1/rest/videoRelease/search
# DEPRECATED
# operationId: v1PageVideoReleases
@deprecated
export def "rest-video-release-search v1PageVideoReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, videoReleases: table<uid: string, title: string, series: record, season: record, format: string, numberOfEpisodes: int, numberOfFeatureLengthEpisodes: int, numberOfDataCarriers: int, runTime: int, yearFrom: int, yearTo: int, regionFreeReleaseDate: string, region1AReleaseDate: string, region1SlimlineReleaseDate: string, region2BReleaseDate: string, region2SlimlineReleaseDate: string, region4AReleaseDate: string, region4SlimlineReleaseDate: string, amazonDigitalRelease: bool, dailymotionDigitalRelease: bool, googlePlayDigitalRelease: bool, itunesDigitalRelease: bool, ultraVioletDigitalRelease: bool, vimeoDigitalRelease: bool, vuduDigitalRelease: bool, xboxSmartGlassDigitalRelease: bool, youTubeDigitalRelease: bool, netflixDigitalRelease: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/videoRelease/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching video releases
#
# POST /v1/rest/videoRelease/search
# DEPRECATED
# operationId: v1SearchVideoReleases
@deprecated
export def "rest-video-release-search v1SearchVideoReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Video release title
  --yearFrom: int # Starting year of video release story (format: int32)
  --yearTo: int # Ending year of video release story (format: int32)
  --runTimeFrom: int # Minimal run time, in minutes (format: int32)
  --runTimeTo: int # Minimal run time, in minutes (format: int32)
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, videoReleases: table<uid: string, title: string, series: record, season: record, format: string, numberOfEpisodes: int, numberOfFeatureLengthEpisodes: int, numberOfDataCarriers: int, runTime: int, yearFrom: int, yearTo: int, regionFreeReleaseDate: string, region1AReleaseDate: string, region1SlimlineReleaseDate: string, region2BReleaseDate: string, region2SlimlineReleaseDate: string, region4AReleaseDate: string, region4SlimlineReleaseDate: string, amazonDigitalRelease: bool, dailymotionDigitalRelease: bool, googlePlayDigitalRelease: bool, itunesDigitalRelease: bool, ultraVioletDigitalRelease: bool, vimeoDigitalRelease: bool, vuduDigitalRelease: bool, xboxSmartGlassDigitalRelease: bool, youTubeDigitalRelease: bool, netflixDigitalRelease: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/videoRelease/search" $qp)
  let body = {title: $title, yearFrom: $yearFrom, yearTo: $yearTo, runTimeFrom: $runTimeFrom, runTimeTo: $runTimeTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single video release (V2)
#
# GET /v2/rest/videoRelease
# operationId: v2GetVideoRelease
export def "rest-video-release v2GetVideoRelease" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Video release unique ID
]: nothing -> record<videoRelease: record<uid: string, title: string, series: list<record>, seasons: list<record>, movies: list<record>, format: string, numberOfEpisodes: int, numberOfFeatureLengthEpisodes: int, numberOfDataCarriers: int, runTime: int, yearFrom: int, yearTo: int, regionFreeReleaseDate: string, region1AReleaseDate: string, region1SlimlineReleaseDate: string, region2BReleaseDate: string, region2SlimlineReleaseDate: string, region4AReleaseDate: string, region4SlimlineReleaseDate: string, amazonDigitalRelease: bool, dailymotionDigitalRelease: bool, googlePlayDigitalRelease: bool, itunesDigitalRelease: bool, ultraVioletDigitalRelease: bool, vimeoDigitalRelease: bool, vuduDigitalRelease: bool, xboxSmartGlassDigitalRelease: bool, youTubeDigitalRelease: bool, netflixDigitalRelease: bool, documentary: bool, specialFeatures: bool, references: list<record>, ratings: list<record>, languages: list<record>, languagesSubtitles: list<record>, languagesDubbed: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/videoRelease" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over video releases (V2)
#
# GET /v2/rest/videoRelease/search
# operationId: v2PageVideoReleases
export def "rest-video-release-search v2PageVideoReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, videoReleases: table<uid: string, title: string, series: record, season: record, format: string, numberOfEpisodes: int, numberOfFeatureLengthEpisodes: int, numberOfDataCarriers: int, runTime: int, yearFrom: int, yearTo: int, regionFreeReleaseDate: string, region1AReleaseDate: string, region1SlimlineReleaseDate: string, region2BReleaseDate: string, region2SlimlineReleaseDate: string, region4AReleaseDate: string, region4SlimlineReleaseDate: string, amazonDigitalRelease: bool, dailymotionDigitalRelease: bool, googlePlayDigitalRelease: bool, itunesDigitalRelease: bool, ultraVioletDigitalRelease: bool, vimeoDigitalRelease: bool, vuduDigitalRelease: bool, xboxSmartGlassDigitalRelease: bool, youTubeDigitalRelease: bool, netflixDigitalRelease: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/videoRelease/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching video releases (V2)
#
# POST /v2/rest/videoRelease/search
# operationId: v2SearchVideoReleases
export def "rest-video-release-search v2SearchVideoReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --title: string # Video release title
  --yearFrom: int # Starting year of video release story (format: int32)
  --yearTo: int # Ending year of video release story (format: int32)
  --runTimeFrom: int # Minimal run time, in minutes (format: int32)
  --runTimeTo: int # Minimal run time, in minutes (format: int32)
  --documentary: string@bool-completer # Whether it should be a documentary
  --specialFeatures: string@bool-completer # Whether it should contain special features
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, videoReleases: table<uid: string, title: string, format: string, numberOfEpisodes: int, numberOfFeatureLengthEpisodes: int, numberOfDataCarriers: int, runTime: int, yearFrom: int, yearTo: int, regionFreeReleaseDate: string, region1AReleaseDate: string, region1SlimlineReleaseDate: string, region2BReleaseDate: string, region2SlimlineReleaseDate: string, region4AReleaseDate: string, region4SlimlineReleaseDate: string, amazonDigitalRelease: bool, dailymotionDigitalRelease: bool, googlePlayDigitalRelease: bool, itunesDigitalRelease: bool, ultraVioletDigitalRelease: bool, vimeoDigitalRelease: bool, vuduDigitalRelease: bool, xboxSmartGlassDigitalRelease: bool, youTubeDigitalRelease: bool, netflixDigitalRelease: bool, documentary: bool, specialFeatures: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/videoRelease/search" $qp)
  let body = {title: $title, yearFrom: $yearFrom, yearTo: $yearTo, runTimeFrom: $runTimeFrom, runTimeTo: $runTimeTo, documentary: $documentary, specialFeatures: $specialFeatures} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single weapon
#
# GET /v1/rest/weapon
# DEPRECATED
# operationId: v1GetWeapon
@deprecated
export def "rest-weapon v1GetWeapon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Weapon unique ID
]: nothing -> record<weapon: record<uid: string, name: string, handHeldWeapon: bool, laserTechnology: bool, plasmaTechnology: bool, photonicTechnology: bool, phaserTechnology: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/weapon" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over weapons
#
# GET /v1/rest/weapon/search
# DEPRECATED
# operationId: v1PageWeapons
@deprecated
export def "rest-weapon-search v1PageWeapons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, weapons: table<uid: string, name: string, handHeldWeapon: bool, laserTechnology: bool, plasmaTechnology: bool, photonicTechnology: bool, phaserTechnology: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/weapon/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching weapons
#
# POST /v1/rest/weapon/search
# DEPRECATED
# operationId: v1SearchWeapons
@deprecated
export def "rest-weapon-search v1SearchWeapons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Weapon name
  --handHeldWeapon: string@bool-completer # Whether it should be a hand-help weapon
  --laserTechnology: string@bool-completer # Whether it should be a laser technology
  --plasmaTechnology: string@bool-completer # Whether it should be a plasma technology
  --photonicTechnology: string@bool-completer # Whether it should be a photonic technology
  --phaserTechnology: string@bool-completer # Whether it should be a phaser technology
  --mirror: string@bool-completer # Whether this weapon should be from mirror universe
  --alternateReality: string@bool-completer # Whether this weapon should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, weapons: table<uid: string, name: string, handHeldWeapon: bool, laserTechnology: bool, plasmaTechnology: bool, photonicTechnology: bool, phaserTechnology: bool, mirror: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/rest/weapon/search" $qp)
  let body = {name: $name, handHeldWeapon: $handHeldWeapon, laserTechnology: $laserTechnology, plasmaTechnology: $plasmaTechnology, photonicTechnology: $photonicTechnology, phaserTechnology: $phaserTechnology, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieval of a single weapon (V2)
#
# GET /v2/rest/weapon
# operationId: v2GetWeapon
export def "rest-weapon v2GetWeapon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uid: string # Weapon unique ID
]: nothing -> record<weapon: record<uid: string, name: string, handHeldWeapon: bool, laserTechnology: bool, plasmaTechnology: bool, photonicTechnology: bool, phaserTechnology: bool, directedEnergyWeapon: bool, explosiveWeapon: bool, projectileWeapon: bool, fictionalWeapon: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/weapon" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pagination over weapons (V2)
#
# GET /v2/rest/weapon/search
# operationId: v2PageWeapons
export def "rest-weapon-search v2PageWeapons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
]: nothing -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, weapons: table<uid: string, name: string, handHeldWeapon: bool, laserTechnology: bool, plasmaTechnology: bool, photonicTechnology: bool, phaserTechnology: bool, directedEnergyWeapon: bool, explosiveWeapon: bool, projectileWeapon: bool, fictionalWeapon: bool, mirror: bool, alternateReality: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/weapon/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searching weapons (V2)
#
# POST /v2/rest/weapon/search
# operationId: v2SearchWeapons
export def "rest-weapon-search v2SearchWeapons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageNumber: int # Zero-based page number (format: int32)
  --pageSize: int # Page size (format: int32)
  --qp-sort: string # Sorting, serialized like this: fieldName,ASC;anotherFieldName,DESC
  --name: string # Weapon name
  --handHeldWeapon: string@bool-completer # Whether it should be a hand-help weapon
  --laserTechnology: string@bool-completer # Whether it should be a laser technology
  --plasmaTechnology: string@bool-completer # Whether it should be a plasma technology
  --photonicTechnology: string@bool-completer # Whether it should be a photonic technology
  --phaserTechnology: string@bool-completer # Whether it should be a phaser technology
  --directedEnergyWeapon: string@bool-completer # Whether it should be a directed energy weapon
  --explosiveWeapon: string@bool-completer # Whether it should be an explosive weapon
  --projectileWeapon: string@bool-completer # Whether it should be a projectile weapon
  --fictionalWeapon: string@bool-completer # Whether it should be a fictional weapon
  --mirror: string@bool-completer # Whether this weapon should be from mirror universe
  --alternateReality: string@bool-completer # Whether this weapon should be from alternate reality
]: any -> record<page: record<pageNumber: int, pageSize: int, numberOfElements: int, totalElements: int, totalPages: int, firstPage: bool, lastPage: bool>, sort: record<clauses: list<record>>, weapons: table<uid: string, name: string, handHeldWeapon: bool, laserTechnology: bool, plasmaTechnology: bool, photonicTechnology: bool, phaserTechnology: bool, directedEnergyWeapon: bool, explosiveWeapon: bool, projectileWeapon: bool, fictionalWeapon: bool, mirror: bool, alternateReality: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rest/weapon/search" $qp)
  let body = {name: $name, handHeldWeapon: $handHeldWeapon, laserTechnology: $laserTechnology, plasmaTechnology: $plasmaTechnology, photonicTechnology: $photonicTechnology, phaserTechnology: $phaserTechnology, directedEnergyWeapon: $directedEnergyWeapon, explosiveWeapon: $explosiveWeapon, projectileWeapon: $projectileWeapon, fictionalWeapon: $fictionalWeapon, mirror: $mirror, alternateReality: $alternateReality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
