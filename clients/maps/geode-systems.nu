# Auto-generated client for geodesystems.com:443 v1.0.0
# Source: https://api.apis.guru/v2/specs/geodesystems.com/1.0.0/openapi.json
# Auth: --token flag or $env.GEODESYSTEMS_COM_443_TOKEN

const BASE_URL = "https://geodesystems.com:443"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEODESYSTEMS_COM_443_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://geodesystems.com:443"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "repository-entry-show extractsheet" } } | get name | first)
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

# API for Extract sheets
#
# GET /repository/entry/show
# operationId: media_tabular_extractsheet
export def "repository-entry-show extractsheet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --output: string # Output type  -don't change (default: media_tabular_extractsheet)
  --entryid: string # Entry ID
  --arg1: string # Sheets
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "entryid" $entryid "scalar") (serialize-qp "arg1" $arg1 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/entry/show" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for '2017 Boulder Election Expenditures' entry type
#
# GET /repository/search/type/2017_boulder_election_expenditures
# operationId: search_2017_boulder_election_expenditures
export def "repository-search-type-2017-boulder-election-expenditures expenditures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-2017-boulder-election-expenditurescommittee: string # Committee
  --searchdb-2017-boulder-election-expenditurestransaction-date: string # Transaction Date
  --searchdb-2017-boulder-election-expendituresname: string # Name
  --searchdb-2017-boulder-election-expendituresstreet: string # Street
  --searchdb-2017-boulder-election-expenditurescity: string # City
  --searchdb-2017-boulder-election-expendituresstate: string # State
  --searchdb-2017-boulder-election-expenditureszip: string # Zip
  --searchdb-2017-boulder-election-expendituresexpenditure: float # Expenditure (format: double)
  --searchdb-2017-boulder-election-expenditurespurpose: string # Purpose
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.committee" $searchdb_2017_boulder_election_expenditurescommittee "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.transaction_date" $searchdb_2017_boulder_election_expenditurestransaction_date "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.name" $searchdb_2017_boulder_election_expendituresname "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.street" $searchdb_2017_boulder_election_expendituresstreet "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.city" $searchdb_2017_boulder_election_expenditurescity "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.state" $searchdb_2017_boulder_election_expendituresstate "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.zip" $searchdb_2017_boulder_election_expenditureszip "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.expenditure" $searchdb_2017_boulder_election_expendituresexpenditure "scalar") (serialize-qp "search.db_2017_boulder_election_expenditures.purpose" $searchdb_2017_boulder_election_expenditurespurpose "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/2017_boulder_election_expenditures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Any file type' entry type
#
# GET /repository/search/type/any
# operationId: search_any
export def "repository-search-type-any any" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/any" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Before and After Images' entry type
#
# GET /repository/search/type/beforeafter
# operationId: search_beforeafter
export def "repository-search-type-beforeafter beforeafter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/beforeafter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Bibliographic Entry' entry type
#
# GET /repository/search/type/biblio
# operationId: search_biblio
export def "repository-search-type-biblio biblio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchbiblioprimary-author: string # Primary Author
  --searchbibliotype: string # Publication Type
  --searchbiblioinstitution: string # Institution
  --searchbiblioother-authors: string # Other Authors
  --searchbibliopublication: string # Publication
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.biblio.primary_author" $searchbiblioprimary_author "scalar") (serialize-qp "search.biblio.type" $searchbibliotype "scalar") (serialize-qp "search.biblio.institution" $searchbiblioinstitution "scalar") (serialize-qp "search.biblio.other_authors" $searchbiblioother_authors "scalar") (serialize-qp "search.biblio.publication" $searchbibliopublication "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/biblio" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'DICOM File' entry type
#
# GET /repository/search/type/bio_dicom
# operationId: search_bio_dicom
export def "repository-search-type-bio-dicom dicom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_dicom" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'DICOM Test File' entry type
#
# GET /repository/search/type/bio_dicom_test
# operationId: search_bio_dicom_test
export def "repository-search-type-bio-dicom-test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchbio-dicom-testPatientName: string # Patient Name
  --searchbio-dicom-testPatientID: string # Patient ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.bio_dicom_test.PatientName" $searchbio_dicom_testPatientName "scalar") (serialize-qp "search.bio_dicom_test.PatientID" $searchbio_dicom_testPatientID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_dicom_test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FASTA File' entry type
#
# GET /repository/search/type/bio_fasta
# operationId: search_bio_fasta
export def "repository-search-type-bio-fasta fasta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_fasta" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FASTQ File' entry type
#
# GET /repository/search/type/bio_fastq
# operationId: search_bio_fastq
export def "repository-search-type-bio-fastq fastq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_fastq" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'HMMER Index File' entry type
#
# GET /repository/search/type/bio_hmmer_index
# operationId: search_bio_hmmer_index
export def "repository-search-type-bio-hmmer-index index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_hmmer_index" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'OME TIFF File' entry type
#
# GET /repository/search/type/bio_ome_tiff
# operationId: search_bio_ome_tiff
export def "repository-search-type-bio-ome-tiff tiff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ome_tiff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Assay' entry type
#
# GET /repository/search/type/bio_ontology_assay
# operationId: search_bio_ontology_assay
export def "repository-search-type-bio-ontology-assay assay" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ontology_assay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Cohort' entry type
#
# GET /repository/search/type/bio_ontology_cohort
# operationId: search_bio_ontology_cohort
export def "repository-search-type-bio-ontology-cohort cohort" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ontology_cohort" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Person' entry type
#
# GET /repository/search/type/bio_ontology_person
# operationId: search_bio_ontology_person
export def "repository-search-type-bio-ontology-person person" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchbio-ontology-persongender: string # Gender
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.bio_ontology_person.gender" $searchbio_ontology_persongender "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ontology_person" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Sample' entry type
#
# GET /repository/search/type/bio_ontology_sample
# operationId: search_bio_ontology_sample
export def "repository-search-type-bio-ontology-sample sample" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ontology_sample" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Series' entry type
#
# GET /repository/search/type/bio_ontology_series
# operationId: search_bio_ontology_series
export def "repository-search-type-bio-ontology-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ontology_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Study' entry type
#
# GET /repository/search/type/bio_ontology_study
# operationId: search_bio_ontology_study
export def "repository-search-type-bio-ontology-study study" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_ontology_study" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SAM Data' entry type
#
# GET /repository/search/type/bio_sam
# operationId: search_bio_sam
export def "repository-search-type-bio-sam sam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_sam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'PDB Protein File' entry type
#
# GET /repository/search/type/bio_sf_pdb
# operationId: search_bio_sf_pdb
export def "repository-search-type-bio-sf-pdb pdb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_sf_pdb" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Sequence Read Archive' entry type
#
# GET /repository/search/type/bio_sra
# operationId: search_bio_sra
export def "repository-search-type-bio-sra sra" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_sra" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Stockholm File' entry type
#
# GET /repository/search/type/bio_stockholm
# operationId: search_bio_stockholm
export def "repository-search-type-bio-stockholm stockholm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_stockholm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Taxonomic Entry' entry type
#
# GET /repository/search/type/bio_taxonomy
# operationId: search_bio_taxonomy
export def "repository-search-type-bio-taxonomy taxonomy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchbio-taxonomyrank: string # Rank
  --searchbio-taxonomyembl-code: string # EMBL Code
  --searchbio-taxonomydivision: string # Divison
  --searchbio-taxonomyinherited-div: oneof<nothing, bool> # Inheritied division
  --searchbio-taxonomyaliases: string # Also known
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.bio_taxonomy.rank" $searchbio_taxonomyrank "scalar") (serialize-qp "search.bio_taxonomy.embl_code" $searchbio_taxonomyembl_code "scalar") (serialize-qp "search.bio_taxonomy.division" $searchbio_taxonomydivision "scalar") (serialize-qp "search.bio_taxonomy.inherited_div" $searchbio_taxonomyinherited_div "scalar") (serialize-qp "search.bio_taxonomy.aliases" $searchbio_taxonomyaliases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bio_taxonomy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Weblog Entry' entry type
#
# GET /repository/search/type/blogentry
# operationId: search_blogentry
export def "repository-search-type-blogentry blogentry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchblogentryblogtext: string # Extra Text
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.blogentry.blogtext" $searchblogentryblogtext "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/blogentry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder Rental Housing' entry type
#
# GET /repository/search/type/bolder_rental_housing
# operationId: search_bolder_rental_housing
export def "repository-search-type-bolder-rental-housing housing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-bolder-rental-housingpropaddr1: string # Property Address
  --searchdb-bolder-rental-housingrentaltype: string # Rental Type
  --searchdb-bolder-rental-housingbldgtype: string # Building Type
  --searchdb-bolder-rental-housingdwellunits: int # Dwelling Units
  --searchdb-bolder-rental-housingroomunits: int # Room Units
  --searchdb-bolder-rental-housingneighbrhd: string # Neighborhood
  --searchdb-bolder-rental-housingcomplexnm: string # Complex Name
  --searchdb-bolder-rental-housingname: string # Name
  --searchdb-bolder-rental-housingpersontype: string # Person Type
  --searchdb-bolder-rental-housingcompany: string # Company
  --searchdb-bolder-rental-housingengcompl: string # Engcompl
  --searchdb-bolder-rental-housinglicenseexp: string # Expiration Date
  --searchdb-bolder-rental-housinglicensenum: string # Licensenum
  --searchdb-bolder-rental-housingppl1-coname: string # Ppl1 Coname
  --searchdb-bolder-rental-housingperson-1: string # Person 1
  --searchdb-bolder-rental-housingppl1-role: string # Ppl1 Role
  --searchdb-bolder-rental-housingppl2-coname: string # Ppl2 Coname
  --searchdb-bolder-rental-housingperson-2: string # Person 2
  --searchdb-bolder-rental-housingppl2-role: string # Ppl2 Role
  --searchdb-bolder-rental-housinglocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_bolder_rental_housing.propaddr1" $searchdb_bolder_rental_housingpropaddr1 "scalar") (serialize-qp "search.db_bolder_rental_housing.rentaltype" $searchdb_bolder_rental_housingrentaltype "scalar") (serialize-qp "search.db_bolder_rental_housing.bldgtype" $searchdb_bolder_rental_housingbldgtype "scalar") (serialize-qp "search.db_bolder_rental_housing.dwellunits" $searchdb_bolder_rental_housingdwellunits "scalar") (serialize-qp "search.db_bolder_rental_housing.roomunits" $searchdb_bolder_rental_housingroomunits "scalar") (serialize-qp "search.db_bolder_rental_housing.neighbrhd" $searchdb_bolder_rental_housingneighbrhd "scalar") (serialize-qp "search.db_bolder_rental_housing.complexnm" $searchdb_bolder_rental_housingcomplexnm "scalar") (serialize-qp "search.db_bolder_rental_housing.name" $searchdb_bolder_rental_housingname "scalar") (serialize-qp "search.db_bolder_rental_housing.persontype" $searchdb_bolder_rental_housingpersontype "scalar") (serialize-qp "search.db_bolder_rental_housing.company" $searchdb_bolder_rental_housingcompany "scalar") (serialize-qp "search.db_bolder_rental_housing.engcompl" $searchdb_bolder_rental_housingengcompl "scalar") (serialize-qp "search.db_bolder_rental_housing.licenseexp" $searchdb_bolder_rental_housinglicenseexp "scalar") (serialize-qp "search.db_bolder_rental_housing.licensenum" $searchdb_bolder_rental_housinglicensenum "scalar") (serialize-qp "search.db_bolder_rental_housing.ppl1_coname" $searchdb_bolder_rental_housingppl1_coname "scalar") (serialize-qp "search.db_bolder_rental_housing.person_1" $searchdb_bolder_rental_housingperson_1 "scalar") (serialize-qp "search.db_bolder_rental_housing.ppl1_role" $searchdb_bolder_rental_housingppl1_role "scalar") (serialize-qp "search.db_bolder_rental_housing.ppl2_coname" $searchdb_bolder_rental_housingppl2_coname "scalar") (serialize-qp "search.db_bolder_rental_housing.person_2" $searchdb_bolder_rental_housingperson_2 "scalar") (serialize-qp "search.db_bolder_rental_housing.ppl2_role" $searchdb_bolder_rental_housingppl2_role "scalar") (serialize-qp "search.db_bolder_rental_housing.location" $searchdb_bolder_rental_housinglocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bolder_rental_housing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Bookmarks' entry type
#
# GET /repository/search/type/bookmarks
# operationId: search_bookmarks
export def "repository-search-type-bookmarks bookmarks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-bookmarkstitle: string # Title
  --searchdb-bookmarksurl: string # URL
  --searchdb-bookmarkscategory: string # Category
  --searchdb-bookmarksdate: string # Date
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_bookmarks.title" $searchdb_bookmarkstitle "scalar") (serialize-qp "search.db_bookmarks.url" $searchdb_bookmarksurl "scalar") (serialize-qp "search.db_bookmarks.category" $searchdb_bookmarkscategory "scalar") (serialize-qp "search.db_bookmarks.date" $searchdb_bookmarksdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/bookmarks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boston Crime' entry type
#
# GET /repository/search/type/boston_crime
# operationId: search_boston_crime
export def "repository-search-type-boston-crime crime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boston-crimeoffense: string # Offense
  --searchdb-boston-crimeoffense-code-group: string # Offense Code Group
  --searchdb-boston-crimeoffense-description: string # Offense Description
  --searchdb-boston-crimedistrict: string # District
  --searchdb-boston-crimereporting-area: string # Reporting Area
  --searchdb-boston-crimeshooting: string # Shooting
  --searchdb-boston-crimeyear: float # Year (format: double)
  --searchdb-boston-crimemonth: float # Month (format: double)
  --searchdb-boston-crimeday-of-week: string # Day Of Week
  --searchdb-boston-crimehour: float # Hour (format: double)
  --searchdb-boston-crimestreet: string # Street
  --searchdb-boston-crimelocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boston_crime.offense" $searchdb_boston_crimeoffense "scalar") (serialize-qp "search.db_boston_crime.offense_code_group" $searchdb_boston_crimeoffense_code_group "scalar") (serialize-qp "search.db_boston_crime.offense_description" $searchdb_boston_crimeoffense_description "scalar") (serialize-qp "search.db_boston_crime.district" $searchdb_boston_crimedistrict "scalar") (serialize-qp "search.db_boston_crime.reporting_area" $searchdb_boston_crimereporting_area "scalar") (serialize-qp "search.db_boston_crime.shooting" $searchdb_boston_crimeshooting "scalar") (serialize-qp "search.db_boston_crime.year" $searchdb_boston_crimeyear "scalar") (serialize-qp "search.db_boston_crime.month" $searchdb_boston_crimemonth "scalar") (serialize-qp "search.db_boston_crime.day_of_week" $searchdb_boston_crimeday_of_week "scalar") (serialize-qp "search.db_boston_crime.hour" $searchdb_boston_crimehour "scalar") (serialize-qp "search.db_boston_crime.street" $searchdb_boston_crimestreet "scalar") (serialize-qp "search.db_boston_crime.location" $searchdb_boston_crimelocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boston_crime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder 2017 Election Contributions' entry type
#
# GET /repository/search/type/boulder_2017_election_contributions
# operationId: search_boulder_2017_election_contributions
export def "repository-search-type-boulder-2017-election-contributions contributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-2017-election-contributionscommittee: string # Committee
  --searchdb-boulder-2017-election-contributionslast-name: string # Last Name
  --searchdb-boulder-2017-election-contributionsfirst-name: string # First Name
  --searchdb-boulder-2017-election-contributionsstreet: string # Street
  --searchdb-boulder-2017-election-contributionscity: string # City
  --searchdb-boulder-2017-election-contributionsstate: string # State
  --searchdb-boulder-2017-election-contributionszip: string # Zip
  --searchdb-boulder-2017-election-contributionscontribution-type: string # Contribution Type
  --searchdb-boulder-2017-election-contributionsfrom-candidate: string # From Candidate
  --searchdb-boulder-2017-election-contributionsdate: string # Date
  --searchdb-boulder-2017-election-contributionsamount: float # Amount (format: double)
  --searchdb-boulder-2017-election-contributionsmatch-amount: float # Match Amount (format: double)
  --searchdb-boulder-2017-election-contributionsytd-amount: float # Ytd Amount (format: double)
  --searchdb-boulder-2017-election-contributionslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.committee" $searchdb_boulder_2017_election_contributionscommittee "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.last_name" $searchdb_boulder_2017_election_contributionslast_name "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.first_name" $searchdb_boulder_2017_election_contributionsfirst_name "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.street" $searchdb_boulder_2017_election_contributionsstreet "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.city" $searchdb_boulder_2017_election_contributionscity "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.state" $searchdb_boulder_2017_election_contributionsstate "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.zip" $searchdb_boulder_2017_election_contributionszip "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.contribution_type" $searchdb_boulder_2017_election_contributionscontribution_type "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.from_candidate" $searchdb_boulder_2017_election_contributionsfrom_candidate "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.date" $searchdb_boulder_2017_election_contributionsdate "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.amount" $searchdb_boulder_2017_election_contributionsamount "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.match_amount" $searchdb_boulder_2017_election_contributionsmatch_amount "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.ytd_amount" $searchdb_boulder_2017_election_contributionsytd_amount "scalar") (serialize-qp "search.db_boulder_2017_election_contributions.location" $searchdb_boulder_2017_election_contributionslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_2017_election_contributions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder Campaign Contributions' entry type
#
# GET /repository/search/type/boulder_campaign_contributions
# operationId: search_boulder_campaign_contributions
export def "repository-search-type-boulder-campaign-contributions contributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-campaign-contributionscommittee: string # Committee
  --searchdb-boulder-campaign-contributionstype: string # Type
  --searchdb-boulder-campaign-contributionscommittee-num: string # Committee Num
  --searchdb-boulder-campaign-contributionscandidate: string # Candidate
  --searchdb-boulder-campaign-contributionsfiling-date: string # Filing Date
  --searchdb-boulder-campaign-contributionsamended-date: string # Amended Date
  --searchdb-boulder-campaign-contributionsofficial-filing: string # Official Filing
  --searchdb-boulder-campaign-contributionstransaction-date: string # Transaction Date
  --searchdb-boulder-campaign-contributionslast-name: string # Last Name
  --searchdb-boulder-campaign-contributionsfirst-name: string # First Name
  --searchdb-boulder-campaign-contributionsstreet: string # Street
  --searchdb-boulder-campaign-contributionscity: string # City
  --searchdb-boulder-campaign-contributionsstate: string # State
  --searchdb-boulder-campaign-contributionszip: string # Zip
  --searchdb-boulder-campaign-contributionscontribution: float # Contribution (format: double)
  --searchdb-boulder-campaign-contributionscontribution-type: string # Contribution Type
  --searchdb-boulder-campaign-contributionsanonymous: string # Anonymous
  --searchdb-boulder-campaign-contributionsfrom-candidate: string # From Candidate
  --searchdb-boulder-campaign-contributionsmatch: float # Match (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_campaign_contributions.committee" $searchdb_boulder_campaign_contributionscommittee "scalar") (serialize-qp "search.db_boulder_campaign_contributions.type" $searchdb_boulder_campaign_contributionstype "scalar") (serialize-qp "search.db_boulder_campaign_contributions.committee_num" $searchdb_boulder_campaign_contributionscommittee_num "scalar") (serialize-qp "search.db_boulder_campaign_contributions.candidate" $searchdb_boulder_campaign_contributionscandidate "scalar") (serialize-qp "search.db_boulder_campaign_contributions.filing_date" $searchdb_boulder_campaign_contributionsfiling_date "scalar") (serialize-qp "search.db_boulder_campaign_contributions.amended_date" $searchdb_boulder_campaign_contributionsamended_date "scalar") (serialize-qp "search.db_boulder_campaign_contributions.official_filing" $searchdb_boulder_campaign_contributionsofficial_filing "scalar") (serialize-qp "search.db_boulder_campaign_contributions.transaction_date" $searchdb_boulder_campaign_contributionstransaction_date "scalar") (serialize-qp "search.db_boulder_campaign_contributions.last_name" $searchdb_boulder_campaign_contributionslast_name "scalar") (serialize-qp "search.db_boulder_campaign_contributions.first_name" $searchdb_boulder_campaign_contributionsfirst_name "scalar") (serialize-qp "search.db_boulder_campaign_contributions.street" $searchdb_boulder_campaign_contributionsstreet "scalar") (serialize-qp "search.db_boulder_campaign_contributions.city" $searchdb_boulder_campaign_contributionscity "scalar") (serialize-qp "search.db_boulder_campaign_contributions.state" $searchdb_boulder_campaign_contributionsstate "scalar") (serialize-qp "search.db_boulder_campaign_contributions.zip" $searchdb_boulder_campaign_contributionszip "scalar") (serialize-qp "search.db_boulder_campaign_contributions.contribution" $searchdb_boulder_campaign_contributionscontribution "scalar") (serialize-qp "search.db_boulder_campaign_contributions.contribution_type" $searchdb_boulder_campaign_contributionscontribution_type "scalar") (serialize-qp "search.db_boulder_campaign_contributions.anonymous" $searchdb_boulder_campaign_contributionsanonymous "scalar") (serialize-qp "search.db_boulder_campaign_contributions.from_candidate" $searchdb_boulder_campaign_contributionsfrom_candidate "scalar") (serialize-qp "search.db_boulder_campaign_contributions.match" $searchdb_boulder_campaign_contributionsmatch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_campaign_contributions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder Consulting Services Database' entry type
#
# GET /repository/search/type/boulder_consulting_services
# operationId: search_boulder_consulting_services
export def "repository-search-type-boulder-consulting-services services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-consulting-servicesfund: string # Fund
  --searchdb-boulder-consulting-servicesdepartment: string # Department
  --searchdb-boulder-consulting-servicesorganization: string # Organization
  --searchdb-boulder-consulting-servicesobject: string # Object
  --searchdb-boulder-consulting-servicesproject: string # Project
  --searchdb-boulder-consulting-servicesaccount-description: string # Account Description
  --searchdb-boulder-consulting-servicesdate: string # Date
  --searchdb-boulder-consulting-servicesamount: float # Amount (format: double)
  --searchdb-boulder-consulting-servicespurchase-order: string # Purchase Order
  --searchdb-boulder-consulting-servicesvendor-name: string # Vendor Name
  --searchdb-boulder-consulting-servicescomment: string # Comment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_consulting_services.fund" $searchdb_boulder_consulting_servicesfund "scalar") (serialize-qp "search.db_boulder_consulting_services.department" $searchdb_boulder_consulting_servicesdepartment "scalar") (serialize-qp "search.db_boulder_consulting_services.organization" $searchdb_boulder_consulting_servicesorganization "scalar") (serialize-qp "search.db_boulder_consulting_services.object" $searchdb_boulder_consulting_servicesobject "scalar") (serialize-qp "search.db_boulder_consulting_services.project" $searchdb_boulder_consulting_servicesproject "scalar") (serialize-qp "search.db_boulder_consulting_services.account_description" $searchdb_boulder_consulting_servicesaccount_description "scalar") (serialize-qp "search.db_boulder_consulting_services.date" $searchdb_boulder_consulting_servicesdate "scalar") (serialize-qp "search.db_boulder_consulting_services.amount" $searchdb_boulder_consulting_servicesamount "scalar") (serialize-qp "search.db_boulder_consulting_services.purchase_order" $searchdb_boulder_consulting_servicespurchase_order "scalar") (serialize-qp "search.db_boulder_consulting_services.vendor_name" $searchdb_boulder_consulting_servicesvendor_name "scalar") (serialize-qp "search.db_boulder_consulting_services.comment" $searchdb_boulder_consulting_servicescomment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_consulting_services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder County Voter Details' entry type
#
# GET /repository/search/type/boulder_county_voter_details
# operationId: search_boulder_county_voter_details
export def "repository-search-type-boulder-county-voter-details details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-county-voter-detailsfirst-name: string # First Name
  --searchdb-boulder-county-voter-detailslast-name: string # Last Name
  --searchdb-boulder-county-voter-detailsregistration-date: string # Registration Date
  --searchdb-boulder-county-voter-detailslast-updated-date: string # Last Updated Date
  --searchdb-boulder-county-voter-detailsresidential-address: string # Residential Address
  --searchdb-boulder-county-voter-detailsresidential-city: string # Residential City
  --searchdb-boulder-county-voter-detailsmailing-zip-code: string # Mailing Zip Code
  --searchdb-boulder-county-voter-detailsvoter-status: string # Voter Status
  --searchdb-boulder-county-voter-detailsparty: string # Party
  --searchdb-boulder-county-voter-detailsgender: string # Gender
  --searchdb-boulder-county-voter-detailsbirth-year: int # Birth Year
  --searchdb-boulder-county-voter-detailsprecinct-code: string # Precinct Code
  --searchdb-boulder-county-voter-detailscongressional: string # Congressional
  --searchdb-boulder-county-voter-detailsstate-senate: string # State Senate
  --searchdb-boulder-county-voter-detailsstate-house: string # State House
  --searchdb-boulder-county-voter-detailsmunicipality: string # Municipality
  --searchdb-boulder-county-voter-detailscity-ward-district: string # City Ward/district
  --searchdb-boulder-county-voter-detailsschool-district: string # School District
  --searchdb-boulder-county-voter-detailslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_county_voter_details.first_name" $searchdb_boulder_county_voter_detailsfirst_name "scalar") (serialize-qp "search.db_boulder_county_voter_details.last_name" $searchdb_boulder_county_voter_detailslast_name "scalar") (serialize-qp "search.db_boulder_county_voter_details.registration_date" $searchdb_boulder_county_voter_detailsregistration_date "scalar") (serialize-qp "search.db_boulder_county_voter_details.last_updated_date" $searchdb_boulder_county_voter_detailslast_updated_date "scalar") (serialize-qp "search.db_boulder_county_voter_details.residential_address" $searchdb_boulder_county_voter_detailsresidential_address "scalar") (serialize-qp "search.db_boulder_county_voter_details.residential_city" $searchdb_boulder_county_voter_detailsresidential_city "scalar") (serialize-qp "search.db_boulder_county_voter_details.mailing_zip_code" $searchdb_boulder_county_voter_detailsmailing_zip_code "scalar") (serialize-qp "search.db_boulder_county_voter_details.voter_status" $searchdb_boulder_county_voter_detailsvoter_status "scalar") (serialize-qp "search.db_boulder_county_voter_details.party" $searchdb_boulder_county_voter_detailsparty "scalar") (serialize-qp "search.db_boulder_county_voter_details.gender" $searchdb_boulder_county_voter_detailsgender "scalar") (serialize-qp "search.db_boulder_county_voter_details.birth_year" $searchdb_boulder_county_voter_detailsbirth_year "scalar") (serialize-qp "search.db_boulder_county_voter_details.precinct_code" $searchdb_boulder_county_voter_detailsprecinct_code "scalar") (serialize-qp "search.db_boulder_county_voter_details.congressional" $searchdb_boulder_county_voter_detailscongressional "scalar") (serialize-qp "search.db_boulder_county_voter_details.state_senate" $searchdb_boulder_county_voter_detailsstate_senate "scalar") (serialize-qp "search.db_boulder_county_voter_details.state_house" $searchdb_boulder_county_voter_detailsstate_house "scalar") (serialize-qp "search.db_boulder_county_voter_details.municipality" $searchdb_boulder_county_voter_detailsmunicipality "scalar") (serialize-qp "search.db_boulder_county_voter_details.city_ward_district" $searchdb_boulder_county_voter_detailscity_ward_district "scalar") (serialize-qp "search.db_boulder_county_voter_details.school_district" $searchdb_boulder_county_voter_detailsschool_district "scalar") (serialize-qp "search.db_boulder_county_voter_details.location" $searchdb_boulder_county_voter_detailslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_county_voter_details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder Crime Reports' entry type
#
# GET /repository/search/type/boulder_crimes
# operationId: search_boulder_crimes
export def "repository-search-type-boulder-crimes crimes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-crimesoffense: string # Offense
  --searchdb-boulder-crimesreportdate: string # Report Date
  --searchdb-boulder-crimesblockadd: string # Address
  --searchdb-boulder-crimeslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_crimes.offense" $searchdb_boulder_crimesoffense "scalar") (serialize-qp "search.db_boulder_crimes.reportdate" $searchdb_boulder_crimesreportdate "scalar") (serialize-qp "search.db_boulder_crimes.blockadd" $searchdb_boulder_crimesblockadd "scalar") (serialize-qp "search.db_boulder_crimes.location" $searchdb_boulder_crimeslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_crimes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder Council Emails' entry type
#
# GET /repository/search/type/boulder_emails
# operationId: search_boulder_emails
export def "repository-search-type-boulder-emails emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-emailssent-from: string # Sent From
  --searchdb-boulder-emailssent-to: string # Sent To
  --searchdb-boulder-emailssent-cc: string # Sent Cc
  --searchdb-boulder-emailsreceived-date: string # Received Date
  --searchdb-boulder-emailsemail-subject: string # Email Subject
  --searchdb-boulder-emailsplain-text-body: string # Email Body
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_emails.sent_from" $searchdb_boulder_emailssent_from "scalar") (serialize-qp "search.db_boulder_emails.sent_to" $searchdb_boulder_emailssent_to "scalar") (serialize-qp "search.db_boulder_emails.sent_cc" $searchdb_boulder_emailssent_cc "scalar") (serialize-qp "search.db_boulder_emails.received_date" $searchdb_boulder_emailsreceived_date "scalar") (serialize-qp "search.db_boulder_emails.email_subject" $searchdb_boulder_emailsemail_subject "scalar") (serialize-qp "search.db_boulder_emails.plain_text_body" $searchdb_boulder_emailsplain_text_body "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_emails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Boulder Employee Salaries' entry type
#
# GET /repository/search/type/boulder_employee_salaries
# operationId: search_boulder_employee_salaries
export def "repository-search-type-boulder-employee-salaries salaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-boulder-employee-salariesposition-description: string # Position Description
  --searchdb-boulder-employee-salariesdepartment: string # Department
  --searchdb-boulder-employee-salariesemployee-flsa-exempt-y-n: string # Employee Flsa Exempt Y N
  --searchdb-boulder-employee-salariespay-range-min: float # Pay Range Min (format: double)
  --searchdb-boulder-employee-salariespay-range-max: float # Pay Range Max (format: double)
  --searchdb-boulder-employee-salariesemployee-hourly-pay-rate: float # Employee Hourly Pay Rate (format: double)
  --searchdb-boulder-employee-salariesemployee-fte-in-this-position: float # Employee Fte In This Position (format: double)
  --searchdb-boulder-employee-salariesemployee-annual-base-salary: float # Employee Annual Base Salary (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_boulder_employee_salaries.position_description" $searchdb_boulder_employee_salariesposition_description "scalar") (serialize-qp "search.db_boulder_employee_salaries.department" $searchdb_boulder_employee_salariesdepartment "scalar") (serialize-qp "search.db_boulder_employee_salaries.employee_flsa_exempt_y_n" $searchdb_boulder_employee_salariesemployee_flsa_exempt_y_n "scalar") (serialize-qp "search.db_boulder_employee_salaries.pay_range_min" $searchdb_boulder_employee_salariespay_range_min "scalar") (serialize-qp "search.db_boulder_employee_salaries.pay_range_max" $searchdb_boulder_employee_salariespay_range_max "scalar") (serialize-qp "search.db_boulder_employee_salaries.employee_hourly_pay_rate" $searchdb_boulder_employee_salariesemployee_hourly_pay_rate "scalar") (serialize-qp "search.db_boulder_employee_salaries.employee_fte_in_this_position" $searchdb_boulder_employee_salariesemployee_fte_in_this_position "scalar") (serialize-qp "search.db_boulder_employee_salaries.employee_annual_base_salary" $searchdb_boulder_employee_salariesemployee_annual_base_salary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/boulder_employee_salaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Calendar' entry type
#
# GET /repository/search/type/calendar
# operationId: search_calendar
export def "repository-search-type-calendar calendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Campaign Donors' entry type
#
# GET /repository/search/type/campaign_donors
# operationId: search_campaign_donors
export def "repository-search-type-campaign-donors donors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-campaign-donorscommittee: string # Committee
  --searchdb-campaign-donorsamount: float # Amount (format: double)
  --searchdb-campaign-donorsparty: string # Party
  --searchdb-campaign-donorsdonor: string # Donor
  --searchdb-campaign-donorsgender: string # Gender
  --searchdb-campaign-donorscity: string # City
  --searchdb-campaign-donorsstate: string # State
  --searchdb-campaign-donorszip-code: string # Zip Code
  --searchdb-campaign-donorsemployer: string # Employer
  --searchdb-campaign-donorsoccupation: string # Occupation
  --searchdb-campaign-donorsdate: string # Date
  --searchdb-campaign-donorslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_campaign_donors.committee" $searchdb_campaign_donorscommittee "scalar") (serialize-qp "search.db_campaign_donors.amount" $searchdb_campaign_donorsamount "scalar") (serialize-qp "search.db_campaign_donors.party" $searchdb_campaign_donorsparty "scalar") (serialize-qp "search.db_campaign_donors.donor" $searchdb_campaign_donorsdonor "scalar") (serialize-qp "search.db_campaign_donors.gender" $searchdb_campaign_donorsgender "scalar") (serialize-qp "search.db_campaign_donors.city" $searchdb_campaign_donorscity "scalar") (serialize-qp "search.db_campaign_donors.state" $searchdb_campaign_donorsstate "scalar") (serialize-qp "search.db_campaign_donors.zip_code" $searchdb_campaign_donorszip_code "scalar") (serialize-qp "search.db_campaign_donors.employer" $searchdb_campaign_donorsemployer "scalar") (serialize-qp "search.db_campaign_donors.occupation" $searchdb_campaign_donorsoccupation "scalar") (serialize-qp "search.db_campaign_donors.date" $searchdb_campaign_donorsdate "scalar") (serialize-qp "search.db_campaign_donors.location" $searchdb_campaign_donorslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/campaign_donors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Campaign Expenditures' entry type
#
# GET /repository/search/type/campaign_expenditures
# operationId: search_campaign_expenditures
export def "repository-search-type-campaign-expenditures expenditures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-campaign-expenditurescommittee: string # Committee
  --searchdb-campaign-expendituresamount: float # Amount (format: double)
  --searchdb-campaign-expendituresparty: string # Party
  --searchdb-campaign-expendituresrecipient: string # Recipient
  --searchdb-campaign-expenditurescity: string # City
  --searchdb-campaign-expendituresstate: string # State
  --searchdb-campaign-expenditureszip-code: string # Zip Code
  --searchdb-campaign-expenditurestransaction-date: string # Transaction Date
  --searchdb-campaign-expenditurespurpose: string # Purpose
  --searchdb-campaign-expendituresmemo-text: string # Memo Text
  --searchdb-campaign-expenditureslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_campaign_expenditures.committee" $searchdb_campaign_expenditurescommittee "scalar") (serialize-qp "search.db_campaign_expenditures.amount" $searchdb_campaign_expendituresamount "scalar") (serialize-qp "search.db_campaign_expenditures.party" $searchdb_campaign_expendituresparty "scalar") (serialize-qp "search.db_campaign_expenditures.recipient" $searchdb_campaign_expendituresrecipient "scalar") (serialize-qp "search.db_campaign_expenditures.city" $searchdb_campaign_expenditurescity "scalar") (serialize-qp "search.db_campaign_expenditures.state" $searchdb_campaign_expendituresstate "scalar") (serialize-qp "search.db_campaign_expenditures.zip_code" $searchdb_campaign_expenditureszip_code "scalar") (serialize-qp "search.db_campaign_expenditures.transaction_date" $searchdb_campaign_expenditurestransaction_date "scalar") (serialize-qp "search.db_campaign_expenditures.purpose" $searchdb_campaign_expenditurespurpose "scalar") (serialize-qp "search.db_campaign_expenditures.memo_text" $searchdb_campaign_expendituresmemo_text "scalar") (serialize-qp "search.db_campaign_expenditures.location" $searchdb_campaign_expenditureslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/campaign_expenditures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Catalog Link' entry type
#
# GET /repository/search/type/cataloglink
# operationId: search_cataloglink
export def "repository-search-type-cataloglink cataloglink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/cataloglink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Gridded Data File' entry type
#
# GET /repository/search/type/cdm_grid
# operationId: search_cdm_grid
export def "repository-search-type-cdm-grid grid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/cdm_grid" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Chat Room' entry type
#
# GET /repository/search/type/chatroom
# operationId: search_chatroom
export def "repository-search-type-chatroom chatroom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/chatroom" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Colorado Water Rights' entry type
#
# GET /repository/search/type/colorado_water_rights
# operationId: search_colorado_water_rights
export def "repository-search-type-colorado-water-rights rights" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-colorado-water-rightsstructure-name: string # Structure Name
  --searchdb-colorado-water-rightsstructure-type: string # Structure Type
  --searchdb-colorado-water-rightswater-source: string # Water Source
  --searchdb-colorado-water-rightscounty: string # County
  --searchdb-colorado-water-rightsadjudication-date: string # Adjudication Date
  --searchdb-colorado-water-rightsappropriation-date: string # Appropriation Date
  --searchdb-colorado-water-rightspriority-no: string # Priority No
  --searchdb-colorado-water-rightsdecreed-uses: string # Decreed Uses
  --searchdb-colorado-water-rightsnet-absolute: float # Net Absolute (format: double)
  --searchdb-colorado-water-rightsnet-conditional: float # Net Conditional (format: double)
  --searchdb-colorado-water-rightsnet-apex-absolute: float # Net Apex Absolute (format: double)
  --searchdb-colorado-water-rightsnet-apex-conditional: float # Net Apex Conditional (format: double)
  --searchdb-colorado-water-rightsdecreed-units: string # Decreed Units
  --searchdb-colorado-water-rightsseasonal-limits: string # Seasonal Limits
  --searchdb-colorado-water-rightscomments: string # Comments
  --searchdb-colorado-water-rightsmore-information: string # More Information
  --searchdb-colorado-water-rightslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_colorado_water_rights.structure_name" $searchdb_colorado_water_rightsstructure_name "scalar") (serialize-qp "search.db_colorado_water_rights.structure_type" $searchdb_colorado_water_rightsstructure_type "scalar") (serialize-qp "search.db_colorado_water_rights.water_source" $searchdb_colorado_water_rightswater_source "scalar") (serialize-qp "search.db_colorado_water_rights.county" $searchdb_colorado_water_rightscounty "scalar") (serialize-qp "search.db_colorado_water_rights.adjudication_date" $searchdb_colorado_water_rightsadjudication_date "scalar") (serialize-qp "search.db_colorado_water_rights.appropriation_date" $searchdb_colorado_water_rightsappropriation_date "scalar") (serialize-qp "search.db_colorado_water_rights.priority_no" $searchdb_colorado_water_rightspriority_no "scalar") (serialize-qp "search.db_colorado_water_rights.decreed_uses" $searchdb_colorado_water_rightsdecreed_uses "scalar") (serialize-qp "search.db_colorado_water_rights.net_absolute" $searchdb_colorado_water_rightsnet_absolute "scalar") (serialize-qp "search.db_colorado_water_rights.net_conditional" $searchdb_colorado_water_rightsnet_conditional "scalar") (serialize-qp "search.db_colorado_water_rights.net_apex_absolute" $searchdb_colorado_water_rightsnet_apex_absolute "scalar") (serialize-qp "search.db_colorado_water_rights.net_apex_conditional" $searchdb_colorado_water_rightsnet_apex_conditional "scalar") (serialize-qp "search.db_colorado_water_rights.decreed_units" $searchdb_colorado_water_rightsdecreed_units "scalar") (serialize-qp "search.db_colorado_water_rights.seasonal_limits" $searchdb_colorado_water_rightsseasonal_limits "scalar") (serialize-qp "search.db_colorado_water_rights.comments" $searchdb_colorado_water_rightscomments "scalar") (serialize-qp "search.db_colorado_water_rights.more_information" $searchdb_colorado_water_rightsmore_information "scalar") (serialize-qp "search.db_colorado_water_rights.location" $searchdb_colorado_water_rightslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/colorado_water_rights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Committee Donations' entry type
#
# GET /repository/search/type/committee_donations
# operationId: search_committee_donations
export def "repository-search-type-committee-donations donations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-committee-donationscommittee: string # Committee
  --searchdb-committee-donationsamount: float # Amount (format: double)
  --searchdb-committee-donationsrecipient: string # Recipient
  --searchdb-committee-donationsdate: string # Date
  --searchdb-committee-donationscity: string # City
  --searchdb-committee-donationsstate: string # State
  --searchdb-committee-donationszip-code: string # Zip Code
  --searchdb-committee-donationsemployer: string # Employer
  --searchdb-committee-donationsoccupation: string # Occupation
  --searchdb-committee-donationslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_committee_donations.committee" $searchdb_committee_donationscommittee "scalar") (serialize-qp "search.db_committee_donations.amount" $searchdb_committee_donationsamount "scalar") (serialize-qp "search.db_committee_donations.recipient" $searchdb_committee_donationsrecipient "scalar") (serialize-qp "search.db_committee_donations.date" $searchdb_committee_donationsdate "scalar") (serialize-qp "search.db_committee_donations.city" $searchdb_committee_donationscity "scalar") (serialize-qp "search.db_committee_donations.state" $searchdb_committee_donationsstate "scalar") (serialize-qp "search.db_committee_donations.zip_code" $searchdb_committee_donationszip_code "scalar") (serialize-qp "search.db_committee_donations.employer" $searchdb_committee_donationsemployer "scalar") (serialize-qp "search.db_committee_donations.occupation" $searchdb_committee_donationsoccupation "scalar") (serialize-qp "search.db_committee_donations.location" $searchdb_committee_donationslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/committee_donations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Data Hub' entry type
#
# GET /repository/search/type/community_datahub
# operationId: search_community_datahub
export def "repository-search-type-community-datahub datahub" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/community_datahub" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Facility' entry type
#
# GET /repository/search/type/community_resource
# operationId: search_community_resource
export def "repository-search-type-community-resource resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchcommunity-resourceresource-type: string # Type
  --searchcommunity-resourceaddress: string # Address
  --searchcommunity-resourcecity: string # City
  --searchcommunity-resourcestate: string # State or Province
  --searchcommunity-resourcezipcode: string # Zip Code
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.community_resource.resource_type" $searchcommunity_resourceresource_type "scalar") (serialize-qp "search.community_resource.address" $searchcommunity_resourceaddress "scalar") (serialize-qp "search.community_resource.city" $searchcommunity_resourcecity "scalar") (serialize-qp "search.community_resource.state" $searchcommunity_resourcestate "scalar") (serialize-qp "search.community_resource.zipcode" $searchcommunity_resourcezipcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/community_resource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Construction Permits' entry type
#
# GET /repository/search/type/construction_permits
# operationId: search_construction_permits
export def "repository-search-type-construction-permits permits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-construction-permitsaddress: string # Address
  --searchdb-construction-permitscase-status: string # Case Status
  --searchdb-construction-permitscategory: string # Category
  --searchdb-construction-permitsbuilding-uses-and-work-scopes: string # Building Uses And Work Scopes
  --searchdb-construction-permitspermit-types: string # Permit Types
  --searchdb-construction-permitstotal-project-value: float # Total Project Value (format: double)
  --searchdb-construction-permitstotal-subpermit-value: float # Total Subpermit Value (format: double)
  --searchdb-construction-permitsapplied: string # Applied
  --searchdb-construction-permitsapproved: string # Approved
  --searchdb-construction-permitsissued: string # Issued
  --searchdb-construction-permitsco-date: string # Co Date
  --searchdb-construction-permitscompletion-date: string # Completion Date
  --searchdb-construction-permitsnew-res-unit: int # New Res Unit
  --searchdb-construction-permitsexisting-res-unit: int # Existing Res Unit
  --searchdb-construction-permitsaffordable-hsg-unit: int # Affordable Hsg Unit
  --searchdb-construction-permitsnew-sf: int # New Sf
  --searchdb-construction-permitsremodel-sf: int # Remodel Sf
  --searchdb-construction-permitsnarrative-description: string # Narrative Description
  --searchdb-construction-permitsprimary-first-name: string # Primary First Name
  --searchdb-construction-permitsprimary-last-name: string # Primary Last Name
  --searchdb-construction-permitsprimary-company: string # Primary Company
  --searchdb-construction-permitscontractor-first-name: string # Contractor First Name
  --searchdb-construction-permitscontractor-last-name: string # Contractor Last Name
  --searchdb-construction-permitscontractor-company: string # Contractor Company
  --searchdb-construction-permitsowner1-first-name: string # Owner1 First Name
  --searchdb-construction-permitsowner1-last-name: string # Owner1 Last Name
  --searchdb-construction-permitsowner1-company: string # Owner1 Company
  --searchdb-construction-permitsowner2-first-name: string # Owner2 First Name
  --searchdb-construction-permitsowner2-last-name: string # Owner2 Last Name
  --searchdb-construction-permitsowner2-company: string # Owner2 Company
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_construction_permits.address" $searchdb_construction_permitsaddress "scalar") (serialize-qp "search.db_construction_permits.case_status" $searchdb_construction_permitscase_status "scalar") (serialize-qp "search.db_construction_permits.category" $searchdb_construction_permitscategory "scalar") (serialize-qp "search.db_construction_permits.building_uses_and_work_scopes" $searchdb_construction_permitsbuilding_uses_and_work_scopes "scalar") (serialize-qp "search.db_construction_permits.permit_types" $searchdb_construction_permitspermit_types "scalar") (serialize-qp "search.db_construction_permits.total_project_value" $searchdb_construction_permitstotal_project_value "scalar") (serialize-qp "search.db_construction_permits.total_subpermit_value" $searchdb_construction_permitstotal_subpermit_value "scalar") (serialize-qp "search.db_construction_permits.applied" $searchdb_construction_permitsapplied "scalar") (serialize-qp "search.db_construction_permits.approved" $searchdb_construction_permitsapproved "scalar") (serialize-qp "search.db_construction_permits.issued" $searchdb_construction_permitsissued "scalar") (serialize-qp "search.db_construction_permits.co_date" $searchdb_construction_permitsco_date "scalar") (serialize-qp "search.db_construction_permits.completion_date" $searchdb_construction_permitscompletion_date "scalar") (serialize-qp "search.db_construction_permits.new_res_unit" $searchdb_construction_permitsnew_res_unit "scalar") (serialize-qp "search.db_construction_permits.existing_res_unit" $searchdb_construction_permitsexisting_res_unit "scalar") (serialize-qp "search.db_construction_permits.affordable_hsg_unit" $searchdb_construction_permitsaffordable_hsg_unit "scalar") (serialize-qp "search.db_construction_permits.new_sf" $searchdb_construction_permitsnew_sf "scalar") (serialize-qp "search.db_construction_permits.remodel_sf" $searchdb_construction_permitsremodel_sf "scalar") (serialize-qp "search.db_construction_permits.narrative_description" $searchdb_construction_permitsnarrative_description "scalar") (serialize-qp "search.db_construction_permits.primary_first_name" $searchdb_construction_permitsprimary_first_name "scalar") (serialize-qp "search.db_construction_permits.primary_last_name" $searchdb_construction_permitsprimary_last_name "scalar") (serialize-qp "search.db_construction_permits.primary_company" $searchdb_construction_permitsprimary_company "scalar") (serialize-qp "search.db_construction_permits.contractor_first_name" $searchdb_construction_permitscontractor_first_name "scalar") (serialize-qp "search.db_construction_permits.contractor_last_name" $searchdb_construction_permitscontractor_last_name "scalar") (serialize-qp "search.db_construction_permits.contractor_company" $searchdb_construction_permitscontractor_company "scalar") (serialize-qp "search.db_construction_permits.owner1_first_name" $searchdb_construction_permitsowner1_first_name "scalar") (serialize-qp "search.db_construction_permits.owner1_last_name" $searchdb_construction_permitsowner1_last_name "scalar") (serialize-qp "search.db_construction_permits.owner1_company" $searchdb_construction_permitsowner1_company "scalar") (serialize-qp "search.db_construction_permits.owner2_first_name" $searchdb_construction_permitsowner2_first_name "scalar") (serialize-qp "search.db_construction_permits.owner2_last_name" $searchdb_construction_permitsowner2_last_name "scalar") (serialize-qp "search.db_construction_permits.owner2_company" $searchdb_construction_permitsowner2_company "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/construction_permits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Contact List' entry type
#
# GET /repository/search/type/contact
# operationId: search_contact
export def "repository-search-type-contact contact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-contactname: string # Name
  --searchdb-contactinstitution: string # Institution
  --searchdb-contactemail: string # Email
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_contact.name" $searchdb_contactname "scalar") (serialize-qp "search.db_contact.institution" $searchdb_contactinstitution "scalar") (serialize-qp "search.db_contact.email" $searchdb_contactemail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/contact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Colorado Health Indicators' entry type
#
# GET /repository/search/type/db_co_indicators
# operationId: search_db_co_indicators
export def "repository-search-type-db-co-indicators indicators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-db-co-indicatorsgeo-name: string # County
  --searchdb-db-co-indicatorsdomain: string # Domain
  --searchdb-db-co-indicatorssubdomain: string # Subdomain
  --searchdb-db-co-indicatorsindicatorName: string # Indicator
  --searchdb-db-co-indicatorsdescription: string # Description
  --searchdb-db-co-indicatorsmeasure: float # Measure (format: double)
  --searchdb-db-co-indicatorslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_db_co_indicators.geo_name" $searchdb_db_co_indicatorsgeo_name "scalar") (serialize-qp "search.db_db_co_indicators.domain" $searchdb_db_co_indicatorsdomain "scalar") (serialize-qp "search.db_db_co_indicators.subdomain" $searchdb_db_co_indicatorssubdomain "scalar") (serialize-qp "search.db_db_co_indicators.indicatorName" $searchdb_db_co_indicatorsindicatorName "scalar") (serialize-qp "search.db_db_co_indicators.description" $searchdb_db_co_indicatorsdescription "scalar") (serialize-qp "search.db_db_co_indicators.measure" $searchdb_db_co_indicatorsmeasure "scalar") (serialize-qp "search.db_db_co_indicators.location" $searchdb_db_co_indicatorslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/db_co_indicators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Landsat Satellite Data' entry type
#
# GET /repository/search/type/earth_satellite_landsat
# operationId: search_earth_satellite_landsat
export def "repository-search-type-earth-satellite-landsat landsat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchearth-satellite-landsatsensor: string # Sensor
  --searchearth-satellite-landsatsatellite: string # Satellite
  --searchearth-satellite-landsatwrs-path-number: int # WRS Path
  --searchearth-satellite-landsatwrs-row-number: int # WRS Row
  --searchearth-satellite-landsatground-station: string # Ground Station
  --searchearth-satellite-landsatarchive-version-number: int # Archive Version Number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.earth_satellite_landsat.sensor" $searchearth_satellite_landsatsensor "scalar") (serialize-qp "search.earth_satellite_landsat.satellite" $searchearth_satellite_landsatsatellite "scalar") (serialize-qp "search.earth_satellite_landsat.wrs_path_number" $searchearth_satellite_landsatwrs_path_number "scalar") (serialize-qp "search.earth_satellite_landsat.wrs_row_number" $searchearth_satellite_landsatwrs_row_number "scalar") (serialize-qp "search.earth_satellite_landsat.ground_station" $searchearth_satellite_landsatground_station "scalar") (serialize-qp "search.earth_satellite_landsat.archive_version_number" $searchearth_satellite_landsatarchive_version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/earth_satellite_landsat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FAQ' entry type
#
# GET /repository/search/type/faq
# operationId: search_faq
export def "repository-search-type-faq faq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/faq" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FEC PACs' entry type
#
# GET /repository/search/type/fec_pacs
# operationId: search_fec_pacs
export def "repository-search-type-fec-pacs pacs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-fec-pacscommittee: string # Committee
  --searchdb-fec-pacstotal-receipts: float # Total Receipts (format: double)
  --searchdb-fec-pacsbeginning-cash: float # Beginning Cash (format: double)
  --searchdb-fec-pacsending-cash: float # Ending Cash (format: double)
  --searchdb-fec-pacscontributions-from-individuals: float # Contributions From Individuals (format: double)
  --searchdb-fec-pacscontributions-from-other-committees: float # Contributions From Other Committees (format: double)
  --searchdb-fec-pacstrans-from-affiliates: float # Trans From Affiliates (format: double)
  --searchdb-fec-pacscontributions-to-other-committee: float # Contributions To Other Committee (format: double)
  --searchdb-fec-pacscontributions-from-candidate: float # Contributions From Candidate (format: double)
  --searchdb-fec-pacsloans-from-candidate: float # Loans From Candidate (format: double)
  --searchdb-fec-pacstotal-loans-received: float # Total Loans Received (format: double)
  --searchdb-fec-pacstotal-distributions: float # Total Distributions (format: double)
  --searchdb-fec-pacstransfers-to-affiliates: float # Transfers To Affiliates (format: double)
  --searchdb-fec-pacsrefunds-to-individuals: float # Refunds To Individuals (format: double)
  --searchdb-fec-pacsrefends-to-othercommittees: float # Refends To Othercommittees (format: double)
  --searchdb-fec-pacscandidate-loan-repayments: float # Candidate Loan Repayments (format: double)
  --searchdb-fec-pacsloan-repayments: float # Loan Repayments (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_fec_pacs.committee" $searchdb_fec_pacscommittee "scalar") (serialize-qp "search.db_fec_pacs.total_receipts" $searchdb_fec_pacstotal_receipts "scalar") (serialize-qp "search.db_fec_pacs.beginning_cash" $searchdb_fec_pacsbeginning_cash "scalar") (serialize-qp "search.db_fec_pacs.ending_cash" $searchdb_fec_pacsending_cash "scalar") (serialize-qp "search.db_fec_pacs.contributions_from_individuals" $searchdb_fec_pacscontributions_from_individuals "scalar") (serialize-qp "search.db_fec_pacs.contributions_from_other_committees" $searchdb_fec_pacscontributions_from_other_committees "scalar") (serialize-qp "search.db_fec_pacs.trans_from_affiliates" $searchdb_fec_pacstrans_from_affiliates "scalar") (serialize-qp "search.db_fec_pacs.contributions_to_other_committee" $searchdb_fec_pacscontributions_to_other_committee "scalar") (serialize-qp "search.db_fec_pacs.contributions_from_candidate" $searchdb_fec_pacscontributions_from_candidate "scalar") (serialize-qp "search.db_fec_pacs.loans_from_candidate" $searchdb_fec_pacsloans_from_candidate "scalar") (serialize-qp "search.db_fec_pacs.total_loans_received" $searchdb_fec_pacstotal_loans_received "scalar") (serialize-qp "search.db_fec_pacs.total_distributions" $searchdb_fec_pacstotal_distributions "scalar") (serialize-qp "search.db_fec_pacs.transfers_to_affiliates" $searchdb_fec_pacstransfers_to_affiliates "scalar") (serialize-qp "search.db_fec_pacs.refunds_to_individuals" $searchdb_fec_pacsrefunds_to_individuals "scalar") (serialize-qp "search.db_fec_pacs.refends_to_othercommittees" $searchdb_fec_pacsrefends_to_othercommittees "scalar") (serialize-qp "search.db_fec_pacs.candidate_loan_repayments" $searchdb_fec_pacscandidate_loan_repayments "scalar") (serialize-qp "search.db_fec_pacs.loan_repayments" $searchdb_fec_pacsloan_repayments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/fec_pacs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Candidates' entry type
#
# GET /repository/search/type/feccandidates
# operationId: search_feccandidates
export def "repository-search-type-feccandidates feccandidates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-feccandidatesname: string # Name
  --searchdb-feccandidatesparty: string # Party
  --searchdb-feccandidatesstate: string # State
  --searchdb-feccandidatesdistrict: string # District
  --searchdb-feccandidatesgender: string # Gender
  --searchdb-feccandidatesbeginning-cash: float # Beginning Cash (format: double)
  --searchdb-feccandidatesending-cash: float # Ending Cash (format: double)
  --searchdb-feccandidatestotal-receipts: float # Total Receipts (format: double)
  --searchdb-feccandidatestotal-indivual-contributions: float # Total Indivual Contributions (format: double)
  --searchdb-feccandidatestransfers-from-committees: float # Transfers From Committees (format: double)
  --searchdb-feccandidatestransfers-to-committees: float # Transfers To Committees (format: double)
  --searchdb-feccandidatestotal-disbursements: float # Total Disbursements (format: double)
  --searchdb-feccandidatescontributions-from-candidate: float # Contributions From Candidate (format: double)
  --searchdb-feccandidatesloans-from-candidates: float # Loans From Candidates (format: double)
  --searchdb-feccandidatesother-loans: float # Other Loans (format: double)
  --searchdb-feccandidatescandidate-loan-repayments: float # Candidate Loan Repayments (format: double)
  --searchdb-feccandidatesother-loan-repayments: float # Other Loan Repayments (format: double)
  --searchdb-feccandidatesdebts-owed-by: float # Debts Owed By (format: double)
  --searchdb-feccandidatescontributions-from-other-committees: float # Contributions From Other Committees (format: double)
  --searchdb-feccandidatescontributions-from-party-committees: float # Contributions From Party Committees (format: double)
  --searchdb-feccandidatescoverage-end-date: string # Coverage End Date
  --searchdb-feccandidatesindividual-refunds: float # Individual Refunds (format: double)
  --searchdb-feccandidatescommittee-refunds: float # Committee Refunds (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_feccandidates.name" $searchdb_feccandidatesname "scalar") (serialize-qp "search.db_feccandidates.party" $searchdb_feccandidatesparty "scalar") (serialize-qp "search.db_feccandidates.state" $searchdb_feccandidatesstate "scalar") (serialize-qp "search.db_feccandidates.district" $searchdb_feccandidatesdistrict "scalar") (serialize-qp "search.db_feccandidates.gender" $searchdb_feccandidatesgender "scalar") (serialize-qp "search.db_feccandidates.beginning_cash" $searchdb_feccandidatesbeginning_cash "scalar") (serialize-qp "search.db_feccandidates.ending_cash" $searchdb_feccandidatesending_cash "scalar") (serialize-qp "search.db_feccandidates.total_receipts" $searchdb_feccandidatestotal_receipts "scalar") (serialize-qp "search.db_feccandidates.total_indivual_contributions" $searchdb_feccandidatestotal_indivual_contributions "scalar") (serialize-qp "search.db_feccandidates.transfers_from_committees" $searchdb_feccandidatestransfers_from_committees "scalar") (serialize-qp "search.db_feccandidates.transfers_to_committees" $searchdb_feccandidatestransfers_to_committees "scalar") (serialize-qp "search.db_feccandidates.total_disbursements" $searchdb_feccandidatestotal_disbursements "scalar") (serialize-qp "search.db_feccandidates.contributions_from_candidate" $searchdb_feccandidatescontributions_from_candidate "scalar") (serialize-qp "search.db_feccandidates.loans_from_candidates" $searchdb_feccandidatesloans_from_candidates "scalar") (serialize-qp "search.db_feccandidates.other_loans" $searchdb_feccandidatesother_loans "scalar") (serialize-qp "search.db_feccandidates.candidate_loan_repayments" $searchdb_feccandidatescandidate_loan_repayments "scalar") (serialize-qp "search.db_feccandidates.other_loan_repayments" $searchdb_feccandidatesother_loan_repayments "scalar") (serialize-qp "search.db_feccandidates.debts_owed_by" $searchdb_feccandidatesdebts_owed_by "scalar") (serialize-qp "search.db_feccandidates.contributions_from_other_committees" $searchdb_feccandidatescontributions_from_other_committees "scalar") (serialize-qp "search.db_feccandidates.contributions_from_party_committees" $searchdb_feccandidatescontributions_from_party_committees "scalar") (serialize-qp "search.db_feccandidates.coverage_end_date" $searchdb_feccandidatescoverage_end_date "scalar") (serialize-qp "search.db_feccandidates.individual_refunds" $searchdb_feccandidatesindividual_refunds "scalar") (serialize-qp "search.db_feccandidates.committee_refunds" $searchdb_feccandidatescommittee_refunds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/feccandidates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'RSS/ATOM Feed' entry type
#
# GET /repository/search/type/feed
# operationId: search_feed
export def "repository-search-type-feed feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'File' entry type
#
# GET /repository/search/type/file
# operationId: search_file
export def "repository-search-type-file file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/file" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FITS Data File' entry type
#
# GET /repository/search/type/fits_data
# operationId: search_fits_data
export def "repository-search-type-fits-data data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchfits-dataorigin: string # Origin
  --searchfits-datatelescope: string # Telescope
  --searchfits-datainstrument: string # Instrument
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.fits_data.origin" $searchfits_dataorigin "scalar") (serialize-qp "search.fits_data.telescope" $searchfits_datatelescope "scalar") (serialize-qp "search.fits_data.instrument" $searchfits_datainstrument "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/fits_data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Remote FTP File View' entry type
#
# GET /repository/search/type/ftp
# operationId: search_ftp
export def "repository-search-type-ftp ftp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/ftp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Countdown' entry type
#
# GET /repository/search/type/gadgets_countdown
# operationId: search_gadgets_countdown
export def "repository-search-type-gadgets-countdown countdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/gadgets_countdown" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Stock Ticker' entry type
#
# GET /repository/search/type/gadgets_stock
# operationId: search_gadgets_stock
export def "repository-search-type-gadgets-stock stock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/gadgets_stock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Weather' entry type
#
# GET /repository/search/type/gadgets_weather
# operationId: search_gadgets_weather
export def "repository-search-type-gadgets-weather weather" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/gadgets_weather" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Census Tracts' entry type
#
# GET /repository/search/type/gazeteer_census_tracts
# operationId: search_gazeteer_census_tracts
export def "repository-search-type-gazeteer-census-tracts tracts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-gazeteer-census-tractsstate: string # State
  --searchdb-gazeteer-census-tractsstate-fips: string # State Fips
  --searchdb-gazeteer-census-tractscounty-name: string # County Name
  --searchdb-gazeteer-census-tractscounty-fips: string # County Fips
  --searchdb-gazeteer-census-tractscensus-tract-id: string # Census Tract Id
  --searchdb-gazeteer-census-tractsfull-census-tract-id: string # Full Census Tract Id
  --searchdb-gazeteer-census-tractsland-area: float # Land Area (format: double)
  --searchdb-gazeteer-census-tractswater-area: float # Water Area (format: double)
  --searchdb-gazeteer-census-tractslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_gazeteer_census_tracts.state" $searchdb_gazeteer_census_tractsstate "scalar") (serialize-qp "search.db_gazeteer_census_tracts.state_fips" $searchdb_gazeteer_census_tractsstate_fips "scalar") (serialize-qp "search.db_gazeteer_census_tracts.county_name" $searchdb_gazeteer_census_tractscounty_name "scalar") (serialize-qp "search.db_gazeteer_census_tracts.county_fips" $searchdb_gazeteer_census_tractscounty_fips "scalar") (serialize-qp "search.db_gazeteer_census_tracts.census_tract_id" $searchdb_gazeteer_census_tractscensus_tract_id "scalar") (serialize-qp "search.db_gazeteer_census_tracts.full_census_tract_id" $searchdb_gazeteer_census_tractsfull_census_tract_id "scalar") (serialize-qp "search.db_gazeteer_census_tracts.land_area" $searchdb_gazeteer_census_tractsland_area "scalar") (serialize-qp "search.db_gazeteer_census_tracts.water_area" $searchdb_gazeteer_census_tractswater_area "scalar") (serialize-qp "search.db_gazeteer_census_tracts.location" $searchdb_gazeteer_census_tractslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/gazeteer_census_tracts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Census Gazeteer Counties' entry type
#
# GET /repository/search/type/gazeteer_counties
# operationId: search_gazeteer_counties
export def "repository-search-type-gazeteer-counties counties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-gazeteer-countiesstate-abbreviation: string # State Abbreviation
  --searchdb-gazeteer-countiesstate-fips: string # State Fips
  --searchdb-gazeteer-countiescounty-fips: string # County Fips
  --searchdb-gazeteer-countiesfull-county-fips: string # Full County Fips
  --searchdb-gazeteer-countiescounty-name: string # County Name
  --searchdb-gazeteer-countiesarea-land: float # Area Land (format: double)
  --searchdb-gazeteer-countiesarea-water: float # Area Water (format: double)
  --searchdb-gazeteer-countieslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_gazeteer_counties.state_abbreviation" $searchdb_gazeteer_countiesstate_abbreviation "scalar") (serialize-qp "search.db_gazeteer_counties.state_fips" $searchdb_gazeteer_countiesstate_fips "scalar") (serialize-qp "search.db_gazeteer_counties.county_fips" $searchdb_gazeteer_countiescounty_fips "scalar") (serialize-qp "search.db_gazeteer_counties.full_county_fips" $searchdb_gazeteer_countiesfull_county_fips "scalar") (serialize-qp "search.db_gazeteer_counties.county_name" $searchdb_gazeteer_countiescounty_name "scalar") (serialize-qp "search.db_gazeteer_counties.area_land" $searchdb_gazeteer_countiesarea_land "scalar") (serialize-qp "search.db_gazeteer_counties.area_water" $searchdb_gazeteer_countiesarea_water "scalar") (serialize-qp "search.db_gazeteer_counties.location" $searchdb_gazeteer_countieslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/gazeteer_counties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'GeoJson File' entry type
#
# GET /repository/search/type/geo_geojson
# operationId: search_geo_geojson
export def "repository-search-type-geo-geojson geojson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_geojson" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'GeoTIFF' entry type
#
# GET /repository/search/type/geo_geotiff
# operationId: search_geo_geotiff
export def "repository-search-type-geo-geotiff geotiff" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_geotiff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'GPX GPS File' entry type
#
# GET /repository/search/type/geo_gpx
# operationId: search_geo_gpx
export def "repository-search-type-geo-gpx gpx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchgeo-gpxdistance: float # Distance (format: double)
  --searchgeo-gpxtotal-time: float # Total Time (format: double)
  --searchgeo-gpxmoving-time: float # Moving Time (format: double)
  --searchgeo-gpxspeed: float # Average Speed (format: double)
  --searchgeo-gpxelevation-gain: float # Elevation Gain (format: double)
  --searchgeo-gpxelevation-loss: float # Elevation Loss (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.geo_gpx.distance" $searchgeo_gpxdistance "scalar") (serialize-qp "search.geo_gpx.total_time" $searchgeo_gpxtotal_time "scalar") (serialize-qp "search.geo_gpx.moving_time" $searchgeo_gpxmoving_time "scalar") (serialize-qp "search.geo_gpx.speed" $searchgeo_gpxspeed "scalar") (serialize-qp "search.geo_gpx.elevation_gain" $searchgeo_gpxelevation_gain "scalar") (serialize-qp "search.geo_gpx.elevation_loss" $searchgeo_gpxelevation_loss "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_gpx" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'HDF5 File' entry type
#
# GET /repository/search/type/geo_hdf5
# operationId: search_geo_hdf5
export def "repository-search-type-geo-hdf5 hdf5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_hdf5" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'KML/KMZ File' entry type
#
# GET /repository/search/type/geo_kml
# operationId: search_geo_kml
export def "repository-search-type-geo-kml kml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_kml" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Shapefile' entry type
#
# GET /repository/search/type/geo_shapefile
# operationId: search_geo_shapefile
export def "repository-search-type-geo-shapefile shapefile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_shapefile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Shapefile with FIPS Code' entry type
#
# GET /repository/search/type/geo_shapefile_fips
# operationId: search_geo_shapefile_fips
export def "repository-search-type-geo-shapefile-fips fips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/geo_shapefile_fips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Glossary' entry type
#
# GET /repository/search/type/glossary
# operationId: search_glossary
export def "repository-search-type-glossary glossary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/glossary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Grid Aggregation' entry type
#
# GET /repository/search/type/gridaggregation
# operationId: search_gridaggregation
export def "repository-search-type-gridaggregation gridaggregation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/gridaggregation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Folder' entry type
#
# GET /repository/search/type/group
# operationId: search_group
export def "repository-search-type-group group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'HipChat Group' entry type
#
# GET /repository/search/type/hipchat_group
# operationId: search_hipchat_group
export def "repository-search-type-hipchat-group group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/hipchat_group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Home Page' entry type
#
# GET /repository/search/type/homepage
# operationId: search_homepage
export def "repository-search-type-homepage homepage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/homepage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Incident' entry type
#
# GET /repository/search/type/incident
# operationId: search_incident
export def "repository-search-type-incident incident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchincidentincidenttype: string # Incident Type
  --searchincidentcause: string # Cause
  --searchincidentstate: string # State
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.incident.incidenttype" $searchincidentincidenttype "scalar") (serialize-qp "search.incident.cause" $searchincidentcause "scalar") (serialize-qp "search.incident.state" $searchincidentstate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/incident" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Jeopardy' entry type
#
# GET /repository/search/type/jeopardy
# operationId: search_jeopardy
export def "repository-search-type-jeopardy jeopardy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-jeopardyquestion: string # Question
  --searchdb-jeopardyanswer: string # Answer
  --searchdb-jeopardyround: string # Round
  --searchdb-jeopardycategory: string # Category
  --searchdb-jeopardyair-date: string # Air Date
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_jeopardy.question" $searchdb_jeopardyquestion "scalar") (serialize-qp "search.db_jeopardy.answer" $searchdb_jeopardyanswer "scalar") (serialize-qp "search.db_jeopardy.round" $searchdb_jeopardyround "scalar") (serialize-qp "search.db_jeopardy.category" $searchdb_jeopardycategory "scalar") (serialize-qp "search.db_jeopardy.air_date" $searchdb_jeopardyair_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/jeopardy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Lat-Lon Image' entry type
#
# GET /repository/search/type/latlonimage
# operationId: search_latlonimage
export def "repository-search-type-latlonimage latlonimage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/latlonimage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'LiDAR Collection' entry type
#
# GET /repository/search/type/lidar_collection
# operationId: search_lidar_collection
export def "repository-search-type-lidar-collection collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/lidar_collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'LAS Lidar Data' entry type
#
# GET /repository/search/type/lidar_las
# operationId: search_lidar_las
export def "repository-search-type-lidar-las las" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/lidar_las" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'LVIS Lidar Data' entry type
#
# GET /repository/search/type/lidar_lvis
# operationId: search_lidar_lvis
export def "repository-search-type-lidar-lvis lvis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/lidar_lvis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Link' entry type
#
# GET /repository/search/type/link
# operationId: search_link
export def "repository-search-type-link link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Server Side Files' entry type
#
# GET /repository/search/type/localfiles
# operationId: search_localfiles
export def "repository-search-type-localfiles localfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/localfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Locations' entry type
#
# GET /repository/search/type/locations
# operationId: search_locations
export def "repository-search-type-locations locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-locationsname: string # Name
  --searchdb-locationstype: string # Type
  --searchdb-locationslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_locations.name" $searchdb_locationsname "scalar") (serialize-qp "search.db_locations.type" $searchdb_locationstype "scalar") (serialize-qp "search.db_locations.location" $searchdb_locationslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Google Map URL' entry type
#
# GET /repository/search/type/map_googlemap
# operationId: search_map_googlemap
export def "repository-search-type-map-googlemap googlemap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/map_googlemap" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Audio File' entry type
#
# GET /repository/search/type/media_audiofile
# operationId: search_media_audiofile
export def "repository-search-type-media-audiofile audiofile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/media_audiofile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Image Loop' entry type
#
# GET /repository/search/type/media_imageloop
# operationId: search_media_imageloop
export def "repository-search-type-media-imageloop imageloop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/media_imageloop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Photo Album' entry type
#
# GET /repository/search/type/media_photoalbum
# operationId: search_media_photoalbum
export def "repository-search-type-media-photoalbum photoalbum" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/media_photoalbum" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Video Channel' entry type
#
# GET /repository/search/type/media_video_channel
# operationId: search_media_video_channel
export def "repository-search-type-media-video-channel channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/media_video_channel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Quicktime Video' entry type
#
# GET /repository/search/type/media_video_quicktime
# operationId: search_media_video_quicktime
export def "repository-search-type-media-video-quicktime quicktime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/media_video_quicktime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'YouTube Video' entry type
#
# GET /repository/search/type/media_youtubevideo
# operationId: search_media_youtubevideo
export def "repository-search-type-media-youtubevideo youtubevideo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/media_youtubevideo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Notes' entry type
#
# GET /repository/search/type/notes
# operationId: search_notes
export def "repository-search-type-notes notes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-notesnote: string # Note
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_notes.note" $searchdb_notesnote "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Json File' entry type
#
# GET /repository/search/type/notes_jsonfile
# operationId: search_notes_jsonfile
export def "repository-search-type-notes-jsonfile jsonfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/notes_jsonfile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Note' entry type
#
# GET /repository/search/type/notes_note
# operationId: search_notes_note
export def "repository-search-type-notes-note note" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/notes_note" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Notebook' entry type
#
# GET /repository/search/type/notes_notebook
# operationId: search_notes_notebook
export def "repository-search-type-notes-notebook notebook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/notes_notebook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NWS Forecast Feed' entry type
#
# GET /repository/search/type/nwsfeed
# operationId: search_nwsfeed
export def "repository-search-type-nwsfeed nwsfeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/nwsfeed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'OPeNDAP Link' entry type
#
# GET /repository/search/type/opendaplink
# operationId: search_opendaplink
export def "repository-search-type-opendaplink opendaplink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/opendaplink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'OWL Class' entry type
#
# GET /repository/search/type/owl.class
# operationId: search_owl.class
export def "repository-search-type-owlclass owlclass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/owl.class" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'OWL Ontology' entry type
#
# GET /repository/search/type/owl.ontology
# operationId: search_owl.ontology
export def "repository-search-type-owlontology owlontology" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/owl.ontology" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Paste Text Entry' entry type
#
# GET /repository/search/type/pasteitentry
# operationId: search_pasteitentry
export def "repository-search-type-pasteitentry pasteitentry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/pasteitentry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Text Point Data' entry type
#
# GET /repository/search/type/point_text
# operationId: search_point_text
export def "repository-search-type-point-text text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/point_text" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Police Stop Data' entry type
#
# GET /repository/search/type/police_stop_data
# operationId: search_police_stop_data
export def "repository-search-type-police-stop-data data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-police-stop-datarace: string # Race
  --searchdb-police-stop-dataethnicity: string # Ethnicity
  --searchdb-police-stop-datasex: string # Sex
  --searchdb-police-stop-dataminutes: int # Minutes
  --searchdb-police-stop-datadate: string # Date
  --searchdb-police-stop-dataaddress: string # Address
  --searchdb-police-stop-dataresident: string # Resident
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_police_stop_data.race" $searchdb_police_stop_datarace "scalar") (serialize-qp "search.db_police_stop_data.ethnicity" $searchdb_police_stop_dataethnicity "scalar") (serialize-qp "search.db_police_stop_data.sex" $searchdb_police_stop_datasex "scalar") (serialize-qp "search.db_police_stop_data.minutes" $searchdb_police_stop_dataminutes "scalar") (serialize-qp "search.db_police_stop_data.date" $searchdb_police_stop_datadate "scalar") (serialize-qp "search.db_police_stop_data.address" $searchdb_police_stop_dataaddress "scalar") (serialize-qp "search.db_police_stop_data.resident" $searchdb_police_stop_dataresident "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/police_stop_data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Poll' entry type
#
# GET /repository/search/type/poll
# operationId: search_poll
export def "repository-search-type-poll poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/poll" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Campaign' entry type
#
# GET /repository/search/type/project_campaign
# operationId: search_project_campaign
export def "repository-search-type-project-campaign campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_campaign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Case Study' entry type
#
# GET /repository/search/type/project_casestudy
# operationId: search_project_casestudy
export def "repository-search-type-project-casestudy casestudy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-casestudyintended-use: string # Intended Use
  --searchproject-casestudylocation: string # Where
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_casestudy.intended_use" $searchproject_casestudyintended_use "scalar") (serialize-qp "search.project_casestudy.location" $searchproject_casestudylocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_casestudy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Research Contribution' entry type
#
# GET /repository/search/type/project_contribution
# operationId: search_project_contribution
export def "repository-search-type-project-contribution contribution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_contribution" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Data Format' entry type
#
# GET /repository/search/type/project_dataformat
# operationId: search_project_dataformat
export def "repository-search-type-project-dataformat dataformat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-dataformatdata-type: string # Data Type
  --searchproject-dataformatfield: string # Field
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_dataformat.data_type" $searchproject_dataformatdata_type "scalar") (serialize-qp "search.project_dataformat.field" $searchproject_dataformatfield "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_dataformat" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Dataset' entry type
#
# GET /repository/search/type/project_dataset
# operationId: search_project_dataset
export def "repository-search-type-project-dataset dataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-datasetdataset-id: string # Dataset ID
  --searchproject-datasetdata-type: string # Data Type
  --searchproject-datasetdata-level: string # Data Level
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_dataset.dataset_id" $searchproject_datasetdataset_id "scalar") (serialize-qp "search.project_dataset.data_type" $searchproject_datasetdata_type "scalar") (serialize-qp "search.project_dataset.data_level" $searchproject_datasetdata_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Deployment' entry type
#
# GET /repository/search/type/project_deployment
# operationId: search_project_deployment
export def "repository-search-type-project-deployment deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_deployment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Experiment' entry type
#
# GET /repository/search/type/project_experiment
# operationId: search_project_experiment
export def "repository-search-type-project-experiment experiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_experiment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Field Note' entry type
#
# GET /repository/search/type/project_fieldnote
# operationId: search_project_fieldnote
export def "repository-search-type-project-fieldnote fieldnote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_fieldnote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Control Points File' entry type
#
# GET /repository/search/type/project_gps_controlpoints
# operationId: search_project_gps_controlpoints
export def "repository-search-type-project-gps-controlpoints controlpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_gps_controlpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Raw GPS File' entry type
#
# GET /repository/search/type/project_gps_raw
# operationId: search_project_gps_raw
export def "repository-search-type-project-gps-raw raw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_gps_raw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'RINEX File' entry type
#
# GET /repository/search/type/project_gps_rinex
# operationId: search_project_gps_rinex
export def "repository-search-type-project-gps-rinex rinex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_gps_rinex" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Instrument Data Collection' entry type
#
# GET /repository/search/type/project_instrument
# operationId: search_project_instrument
export def "repository-search-type-project-instrument instrument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_instrument" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Teaching Resource' entry type
#
# GET /repository/search/type/project_learning_resource
# operationId: search_project_learning_resource
export def "repository-search-type-project-learning-resource resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-learning-resourcetopic: string # Topic
  --searchproject-learning-resourcegrade-level: string # Grade Level
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_learning_resource.topic" $searchproject_learning_resourcetopic "scalar") (serialize-qp "search.project_learning_resource.grade_level" $searchproject_learning_resourcegrade_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_learning_resource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Meeting' entry type
#
# GET /repository/search/type/project_meeting
# operationId: search_project_meeting
export def "repository-search-type-project-meeting meeting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-meetingtopic: string # Topic
  --searchproject-meetinglocation: string # Location
  --searchproject-meetingparticipants: string # Participants
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_meeting.topic" $searchproject_meetingtopic "scalar") (serialize-qp "search.project_meeting.location" $searchproject_meetinglocation "scalar") (serialize-qp "search.project_meeting.participants" $searchproject_meetingparticipants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_meeting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Organization' entry type
#
# GET /repository/search/type/project_organization
# operationId: search_project_organization
export def "repository-search-type-project-organization organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-organizationorganization-type: string # Organization Type
  --searchproject-organizationstatus: string # Status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_organization.organization_type" $searchproject_organizationorganization_type "scalar") (serialize-qp "search.project_organization.status" $searchproject_organizationstatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Program' entry type
#
# GET /repository/search/type/project_program
# operationId: search_project_program
export def "repository-search-type-project-program program" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_program" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Project' entry type
#
# GET /repository/search/type/project_project
# operationId: search_project_project
export def "repository-search-type-project-project project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_project" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Data Access Service' entry type
#
# GET /repository/search/type/project_service
# operationId: search_project_service
export def "repository-search-type-project-service service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-serviceservice-type: string # Service Type
  --searchproject-serviceprovider: string # Provider
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_service.service_type" $searchproject_serviceservice_type "scalar") (serialize-qp "search.project_service.provider" $searchproject_serviceprovider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_service" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Site' entry type
#
# GET /repository/search/type/project_site
# operationId: search_project_site
export def "repository-search-type-project-site site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-siteshort-name: string # Short Name
  --searchproject-sitesite-type: string # Site Type
  --searchproject-sitestatus: string # Status
  --searchproject-sitenetwork: string # Network
  --searchproject-sitecountry: string # Country
  --searchproject-sitestate: string # State/Province
  --searchproject-sitecounty: string # County
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_site.short_name" $searchproject_siteshort_name "scalar") (serialize-qp "search.project_site.site_type" $searchproject_sitesite_type "scalar") (serialize-qp "search.project_site.status" $searchproject_sitestatus "scalar") (serialize-qp "search.project_site.network" $searchproject_sitenetwork "scalar") (serialize-qp "search.project_site.country" $searchproject_sitecountry "scalar") (serialize-qp "search.project_site.state" $searchproject_sitestate "scalar") (serialize-qp "search.project_site.county" $searchproject_sitecounty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_site" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Software Tool' entry type
#
# GET /repository/search/type/project_softwarepackage
# operationId: search_project_softwarepackage
export def "repository-search-type-project-softwarepackage softwarepackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-softwarepackagesoftware-use: string # Software Use
  --searchproject-softwarepackagesoftware-type: string # Software Type
  --searchproject-softwarepackagedomain: string # Science Domain
  --searchproject-softwarepackageplatform: string # Platform
  --searchproject-softwarepackagelicense: string # License
  --searchproject-softwarepackagestatus: string # Development Status
  --searchproject-softwarepackagecapabilities: string # Capabilities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_softwarepackage.software_use" $searchproject_softwarepackagesoftware_use "scalar") (serialize-qp "search.project_softwarepackage.software_type" $searchproject_softwarepackagesoftware_type "scalar") (serialize-qp "search.project_softwarepackage.domain" $searchproject_softwarepackagedomain "scalar") (serialize-qp "search.project_softwarepackage.platform" $searchproject_softwarepackageplatform "scalar") (serialize-qp "search.project_softwarepackage.license" $searchproject_softwarepackagelicense "scalar") (serialize-qp "search.project_softwarepackage.status" $searchproject_softwarepackagestatus "scalar") (serialize-qp "search.project_softwarepackage.capabilities" $searchproject_softwarepackagecapabilities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_softwarepackage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Standard Parameter Name' entry type
#
# GET /repository/search/type/project_standard_name
# operationId: search_project_standard_name
export def "repository-search-type-project-standard-name name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-standard-nameunit: string # Canonical Unit
  --searchproject-standard-namealiases: string # Aliases
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_standard_name.unit" $searchproject_standard_nameunit "scalar") (serialize-qp "search.project_standard_name.aliases" $searchproject_standard_namealiases "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_standard_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Survey Location' entry type
#
# GET /repository/search/type/project_surveylocation
# operationId: search_project_surveylocation
export def "repository-search-type-project-surveylocation surveylocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_surveylocation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Vocabulary Term' entry type
#
# GET /repository/search/type/project_term
# operationId: search_project_term
export def "repository-search-type-project-term term" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchproject-termvalue: string # Term Value
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.project_term.value" $searchproject_termvalue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_term" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Site Visit' entry type
#
# GET /repository/search/type/project_visit
# operationId: search_project_visit
export def "repository-search-type-project-visit visit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_visit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Vocabulary' entry type
#
# GET /repository/search/type/project_vocabulary
# operationId: search_project_vocabulary
export def "repository-search-type-project-vocabulary vocabulary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/project_vocabulary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Property Sales' entry type
#
# GET /repository/search/type/property_sales
# operationId: search_property_sales
export def "repository-search-type-property-sales sales" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-property-salesproperty-address: string # Property Address
  --searchdb-property-salescity: string # City
  --searchdb-property-saleszipcode: string # Zip Code
  --searchdb-property-salessale-price: float # Sale Price (format: double)
  --searchdb-property-salessale-date: string # Sale Date
  --searchdb-property-salesseller: string # Seller
  --searchdb-property-salesbuyer: string # Buyer
  --searchdb-property-salestype: string # Property Type
  --searchdb-property-salesbuilding-description: string # Building Description
  --searchdb-property-salesbuilding-design: string # Building Design
  --searchdb-property-salessubdivision: string # Subdivision
  --searchdb-property-saleslocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_property_sales.property_address" $searchdb_property_salesproperty_address "scalar") (serialize-qp "search.db_property_sales.city" $searchdb_property_salescity "scalar") (serialize-qp "search.db_property_sales.zipcode" $searchdb_property_saleszipcode "scalar") (serialize-qp "search.db_property_sales.sale_price" $searchdb_property_salessale_price "scalar") (serialize-qp "search.db_property_sales.sale_date" $searchdb_property_salessale_date "scalar") (serialize-qp "search.db_property_sales.seller" $searchdb_property_salesseller "scalar") (serialize-qp "search.db_property_sales.buyer" $searchdb_property_salesbuyer "scalar") (serialize-qp "search.db_property_sales.type" $searchdb_property_salestype "scalar") (serialize-qp "search.db_property_sales.building_description" $searchdb_property_salesbuilding_description "scalar") (serialize-qp "search.db_property_sales.building_design" $searchdb_property_salesbuilding_design "scalar") (serialize-qp "search.db_property_sales.subdivision" $searchdb_property_salessubdivision "scalar") (serialize-qp "search.db_property_sales.location" $searchdb_property_saleslocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/property_sales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Property Database' entry type
#
# GET /repository/search/type/propertydb
# operationId: search_propertydb
export def "repository-search-type-propertydb propertydb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-propertydbproperty-id: string # Property ID
  --searchdb-propertydbowner: string # Owner
  --searchdb-propertydbaddress: string # Address
  --searchdb-propertydbcity: string # City
  --searchdb-propertydbstate: string # State
  --searchdb-propertydbvalue: int # Property Value
  --searchdb-propertydbbuilding-type: string # Building Type
  --searchdb-propertydbhouse-size: int # Building Sq Ft
  --searchdb-propertydblot-sqft: int # Lot Size Sq Ft
  --searchdb-propertydblot-acres: float # Lot Size Acres (format: double)
  --searchdb-propertydbprice-sqft: float # $-sqft (format: double)
  --searchdb-propertydblocation: string # Location
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_propertydb.property_id" $searchdb_propertydbproperty_id "scalar") (serialize-qp "search.db_propertydb.owner" $searchdb_propertydbowner "scalar") (serialize-qp "search.db_propertydb.address" $searchdb_propertydbaddress "scalar") (serialize-qp "search.db_propertydb.city" $searchdb_propertydbcity "scalar") (serialize-qp "search.db_propertydb.state" $searchdb_propertydbstate "scalar") (serialize-qp "search.db_propertydb.value" $searchdb_propertydbvalue "scalar") (serialize-qp "search.db_propertydb.building_type" $searchdb_propertydbbuilding_type "scalar") (serialize-qp "search.db_propertydb.house_size" $searchdb_propertydbhouse_size "scalar") (serialize-qp "search.db_propertydb.lot_sqft" $searchdb_propertydblot_sqft "scalar") (serialize-qp "search.db_propertydb.lot_acres" $searchdb_propertydblot_acres "scalar") (serialize-qp "search.db_propertydb.price_sqft" $searchdb_propertydbprice_sqft "scalar") (serialize-qp "search.db_propertydb.location" $searchdb_propertydblocation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/propertydb" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'IPython Notebook file' entry type
#
# GET /repository/search/type/python_notebook
# operationId: search_python_notebook
export def "repository-search-type-python-notebook notebook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/python_notebook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Slack Team' entry type
#
# GET /repository/search/type/slack_team
# operationId: search_slack_team
export def "repository-search-type-slack-team team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/slack_team" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Status Board' entry type
#
# GET /repository/search/type/statusboard
# operationId: search_statusboard
export def "repository-search-type-statusboard statusboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-statusboardwhat: string # What
  --searchdb-statusboardstatus: string # Status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_statusboard.what" $searchdb_statusboardwhat "scalar") (serialize-qp "search.db_statusboard.status" $searchdb_statusboardstatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/statusboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Sunrise/Sunset Display' entry type
#
# GET /repository/search/type/sunrisesunset
# operationId: search_sunrisesunset
export def "repository-search-type-sunrisesunset sunrisesunset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/sunrisesunset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Tasks' entry type
#
# GET /repository/search/type/tasks
# operationId: search_tasks
export def "repository-search-type-tasks tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-taskstitle: string # Title
  --searchdb-taskspriority: string # Priority
  --searchdb-tasksstatus: string # Status
  --searchdb-taskscomplete: float # % Complete (format: double)
  --searchdb-tasksassignedto: string # Assigned To
  --searchdb-tasksstartdate: string # Start Date
  --searchdb-tasksenddate: string # End Date
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_tasks.title" $searchdb_taskstitle "scalar") (serialize-qp "search.db_tasks.priority" $searchdb_taskspriority "scalar") (serialize-qp "search.db_tasks.status" $searchdb_tasksstatus "scalar") (serialize-qp "search.db_tasks.complete" $searchdb_taskscomplete "scalar") (serialize-qp "search.db_tasks.assignedto" $searchdb_tasksassignedto "scalar") (serialize-qp "search.db_tasks.startdate" $searchdb_tasksstartdate "scalar") (serialize-qp "search.db_tasks.enddate" $searchdb_tasksenddate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Tmdb Movies' entry type
#
# GET /repository/search/type/tmdbmovies
# operationId: search_tmdbmovies
export def "repository-search-type-tmdbmovies tmdbmovies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-tmdbmoviesoriginal-title: string # Original Title
  --searchdb-tmdbmoviesoverview: string # Overview
  --searchdb-tmdbmoviesbudget: float # Budget (format: double)
  --searchdb-tmdbmoviesgenres: string # Genres
  --searchdb-tmdbmovieshomepage: string # Homepage
  --searchdb-tmdbmoviesmovie-id: string # Id
  --searchdb-tmdbmovieskeywords: string # Keywords
  --searchdb-tmdbmoviesoriginal-language: string # Original Language
  --searchdb-tmdbmoviespopularity: float # Popularity (format: double)
  --searchdb-tmdbmoviesproduction-companies: string # Production Companies
  --searchdb-tmdbmoviesproduction-countries: string # Production Countries
  --searchdb-tmdbmoviesrelease-date: string # Release Date
  --searchdb-tmdbmoviesrevenue: float # Revenue (format: double)
  --searchdb-tmdbmoviesruntime: float # Runtime (format: double)
  --searchdb-tmdbmoviesspoken-languages: string # Spoken Languages
  --searchdb-tmdbmoviesstatus: string # Status
  --searchdb-tmdbmoviestagline: string # Tagline
  --searchdb-tmdbmoviestitle: string # Title
  --searchdb-tmdbmoviesvote-average: float # Vote Average (format: double)
  --searchdb-tmdbmoviesvote-count: float # Vote Count (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_tmdbmovies.original_title" $searchdb_tmdbmoviesoriginal_title "scalar") (serialize-qp "search.db_tmdbmovies.overview" $searchdb_tmdbmoviesoverview "scalar") (serialize-qp "search.db_tmdbmovies.budget" $searchdb_tmdbmoviesbudget "scalar") (serialize-qp "search.db_tmdbmovies.genres" $searchdb_tmdbmoviesgenres "scalar") (serialize-qp "search.db_tmdbmovies.homepage" $searchdb_tmdbmovieshomepage "scalar") (serialize-qp "search.db_tmdbmovies.movie_id" $searchdb_tmdbmoviesmovie_id "scalar") (serialize-qp "search.db_tmdbmovies.keywords" $searchdb_tmdbmovieskeywords "scalar") (serialize-qp "search.db_tmdbmovies.original_language" $searchdb_tmdbmoviesoriginal_language "scalar") (serialize-qp "search.db_tmdbmovies.popularity" $searchdb_tmdbmoviespopularity "scalar") (serialize-qp "search.db_tmdbmovies.production_companies" $searchdb_tmdbmoviesproduction_companies "scalar") (serialize-qp "search.db_tmdbmovies.production_countries" $searchdb_tmdbmoviesproduction_countries "scalar") (serialize-qp "search.db_tmdbmovies.release_date" $searchdb_tmdbmoviesrelease_date "scalar") (serialize-qp "search.db_tmdbmovies.revenue" $searchdb_tmdbmoviesrevenue "scalar") (serialize-qp "search.db_tmdbmovies.runtime" $searchdb_tmdbmoviesruntime "scalar") (serialize-qp "search.db_tmdbmovies.spoken_languages" $searchdb_tmdbmoviesspoken_languages "scalar") (serialize-qp "search.db_tmdbmovies.status" $searchdb_tmdbmoviesstatus "scalar") (serialize-qp "search.db_tmdbmovies.tagline" $searchdb_tmdbmoviestagline "scalar") (serialize-qp "search.db_tmdbmovies.title" $searchdb_tmdbmoviestitle "scalar") (serialize-qp "search.db_tmdbmovies.vote_average" $searchdb_tmdbmoviesvote_average "scalar") (serialize-qp "search.db_tmdbmovies.vote_count" $searchdb_tmdbmoviesvote_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/tmdbmovies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Todo' entry type
#
# GET /repository/search/type/todo
# operationId: search_todo
export def "repository-search-type-todo todo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-todochecked: oneof<nothing, bool> # Done
  --searchdb-todotitle: string # What
  --searchdb-todocategory: string # Category
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_todo.checked" $searchdb_todochecked "scalar") (serialize-qp "search.db_todo.title" $searchdb_todotitle "scalar") (serialize-qp "search.db_todo.category" $searchdb_todocategory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/todo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Event' entry type
#
# GET /repository/search/type/trip_event
# operationId: search_trip_event
export def "repository-search-type-trip-event event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/trip_event" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Flight Leg' entry type
#
# GET /repository/search/type/trip_flight
# operationId: search_trip_flight
export def "repository-search-type-trip-flight flight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/trip_flight" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Lodging' entry type
#
# GET /repository/search/type/trip_hotel
# operationId: search_trip_hotel
export def "repository-search-type-trip-hotel hotel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/trip_hotel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Trip Report' entry type
#
# GET /repository/search/type/trip_report
# operationId: search_trip_report
export def "repository-search-type-trip-report report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/trip_report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Trip' entry type
#
# GET /repository/search/type/trip_trip
# operationId: search_trip_trip
export def "repository-search-type-trip-trip trip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/trip_trip" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'AWC Weather Observations' entry type
#
# GET /repository/search/type/type_awc_metar
# operationId: search_type_awc_metar
export def "repository-search-type-type-awc-metar metar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-awc-metarsite-id: string # Site ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_awc_metar.site_id" $searchtype_awc_metarsite_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_awc_metar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Stock Ticker Data' entry type
#
# GET /repository/search/type/type_biz_stockseries
# operationId: search_type_biz_stockseries
export def "repository-search-type-type-biz-stockseries stockseries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_biz_stockseries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'BLS Series' entry type
#
# GET /repository/search/type/type_bls_series
# operationId: search_type_bls_series
export def "repository-search-type-type-bls-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-bls-seriessurvey-name: string # Survey Name
  --searchtype-bls-seriesmeasure-data-type: string # Measure Data Type
  --searchtype-bls-seriesindustry: string # Industry
  --searchtype-bls-seriessector: string # Sector
  --searchtype-bls-seriesarea: string # Area
  --searchtype-bls-seriesitem: string # Item
  --searchtype-bls-seriesseasonality: string # Seasonality
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_bls_series.survey_name" $searchtype_bls_seriessurvey_name "scalar") (serialize-qp "search.type_bls_series.measure_data_type" $searchtype_bls_seriesmeasure_data_type "scalar") (serialize-qp "search.type_bls_series.industry" $searchtype_bls_seriesindustry "scalar") (serialize-qp "search.type_bls_series.sector" $searchtype_bls_seriessector "scalar") (serialize-qp "search.type_bls_series.area" $searchtype_bls_seriesarea "scalar") (serialize-qp "search.type_bls_series.item" $searchtype_bls_seriesitem "scalar") (serialize-qp "search.type_bls_series.seasonality" $searchtype_bls_seriesseasonality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_bls_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'BLS Survey' entry type
#
# GET /repository/search/type/type_bls_survey
# operationId: search_type_bls_survey
export def "repository-search-type-type-bls-survey survey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_bls_survey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'US Census ACS Data' entry type
#
# GET /repository/search/type/type_census_acs
# operationId: search_type_census_acs
export def "repository-search-type-type-census-acs acs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-census-acsfields: string # Indicators
  --searchtype-census-acsfor-type: string # For
  --searchtype-census-acsin-type1: string # In
  --searchtype-census-acsin-type2: string # In #2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_census_acs.fields" $searchtype_census_acsfields "scalar") (serialize-qp "search.type_census_acs.for_type" $searchtype_census_acsfor_type "scalar") (serialize-qp "search.type_census_acs.in_type1" $searchtype_census_acsin_type1 "scalar") (serialize-qp "search.type_census_acs.in_type2" $searchtype_census_acsin_type2 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_census_acs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Daymet Daily Weather' entry type
#
# GET /repository/search/type/type_daymet
# operationId: search_type_daymet
export def "repository-search-type-type-daymet daymet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_daymet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Database Table' entry type
#
# GET /repository/search/type/type_db_table
# operationId: search_type_db_table
export def "repository-search-type-type-db-table table" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_db_table" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'CSV File' entry type
#
# GET /repository/search/type/type_document_csv
# operationId: search_type_document_csv
export def "repository-search-type-type-document-csv csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_document_csv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Word File' entry type
#
# GET /repository/search/type/type_document_doc
# operationId: search_type_document_doc
export def "repository-search-type-type-document-doc doc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_document_doc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'HTML File' entry type
#
# GET /repository/search/type/type_document_html
# operationId: search_type_document_html
export def "repository-search-type-type-document-html html" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_document_html" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'PDF File' entry type
#
# GET /repository/search/type/type_document_pdf
# operationId: search_type_document_pdf
export def "repository-search-type-type-document-pdf pdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_document_pdf" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Powerpoint File' entry type
#
# GET /repository/search/type/type_document_ppt
# operationId: search_type_document_ppt
export def "repository-search-type-type-document-ppt ppt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_document_ppt" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Excel File' entry type
#
# GET /repository/search/type/type_document_xls
# operationId: search_type_document_xls
export def "repository-search-type-type-document-xls xls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_document_xls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Drilsdown Case Study' entry type
#
# GET /repository/search/type/type_drilsdown_casestudy
# operationId: search_type_drilsdown_casestudy
export def "repository-search-type-type-drilsdown-casestudy casestudy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_drilsdown_casestudy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SEC EDGAR Filing' entry type
#
# GET /repository/search/type/type_edgar_filing
# operationId: search_type_edgar_filing
export def "repository-search-type-type-edgar-filing filing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-edgar-filingform-type: string # Form Type
  --searchtype-edgar-filingcompany-name: string # Company Name
  --searchtype-edgar-filingcik-number: string # CIK Number
  --searchtype-edgar-filingstandard-industrial-classification: string # Standard Industrial Classification
  --searchtype-edgar-filingirs-number: string # IRS Number
  --searchtype-edgar-filingstate: string # State of Incorporation
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_edgar_filing.form_type" $searchtype_edgar_filingform_type "scalar") (serialize-qp "search.type_edgar_filing.company_name" $searchtype_edgar_filingcompany_name "scalar") (serialize-qp "search.type_edgar_filing.cik_number" $searchtype_edgar_filingcik_number "scalar") (serialize-qp "search.type_edgar_filing.standard_industrial_classification" $searchtype_edgar_filingstandard_industrial_classification "scalar") (serialize-qp "search.type_edgar_filing.irs_number" $searchtype_edgar_filingirs_number "scalar") (serialize-qp "search.type_edgar_filing.state" $searchtype_edgar_filingstate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_edgar_filing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'EIA Category' entry type
#
# GET /repository/search/type/type_eia_category
# operationId: search_type_eia_category
export def "repository-search-type-type-eia-category category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_eia_category" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'EIA Series' entry type
#
# GET /repository/search/type/type_eia_series
# operationId: search_type_eia_series
export def "repository-search-type-type-eia-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_eia_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Feature Server' entry type
#
# GET /repository/search/type/type_esri_featureserver
# operationId: search_type_esri_featureserver
export def "repository-search-type-type-esri-featureserver featureserver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_featureserver" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Geometry Server' entry type
#
# GET /repository/search/type/type_esri_geometryserver
# operationId: search_type_esri_geometryserver
export def "repository-search-type-type-esri-geometryserver geometryserver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_geometryserver" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI GP Server' entry type
#
# GET /repository/search/type/type_esri_gpserver
# operationId: search_type_esri_gpserver
export def "repository-search-type-type-esri-gpserver gpserver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_gpserver" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Image Server' entry type
#
# GET /repository/search/type/type_esri_imageserver
# operationId: search_type_esri_imageserver
export def "repository-search-type-type-esri-imageserver imageserver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_imageserver" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Layer' entry type
#
# GET /repository/search/type/type_esri_layer
# operationId: search_type_esri_layer
export def "repository-search-type-type-esri-layer layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-esri-layerlayer-type: string # Layer Type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_esri_layer.layer_type" $searchtype_esri_layerlayer_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_layer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Map Server' entry type
#
# GET /repository/search/type/type_esri_mapserver
# operationId: search_type_esri_mapserver
export def "repository-search-type-type-esri-mapserver mapserver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_mapserver" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Services Folder' entry type
#
# GET /repository/search/type/type_esri_restfolder
# operationId: search_type_esri_restfolder
export def "repository-search-type-type-esri-restfolder restfolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_restfolder" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Web Server' entry type
#
# GET /repository/search/type/type_esri_restserver
# operationId: search_type_esri_restserver
export def "repository-search-type-type-esri-restserver restserver" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_restserver" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ESRI Rest Service' entry type
#
# GET /repository/search/type/type_esri_restservice
# operationId: search_type_esri_restservice
export def "repository-search-type-type-esri-restservice restservice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_esri_restservice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA Extremes Data' entry type
#
# GET /repository/search/type/type_extremes
# operationId: search_type_extremes
export def "repository-search-type-type-extremes extremes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-extremesregion: string # US Climate Region
  --searchtype-extremesvariable: string # Variable
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_extremes.region" $searchtype_extremesregion "scalar") (serialize-qp "search.type_extremes.variable" $searchtype_extremesvariable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_extremes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FRED Category' entry type
#
# GET /repository/search/type/type_fred_category
# operationId: search_type_fred_category
export def "repository-search-type-type-fred-category category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_fred_category" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FRED Series' entry type
#
# GET /repository/search/type/type_fred_series
# operationId: search_type_fred_series
export def "repository-search-type-type-fred-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_fred_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Transit Agency' entry type
#
# GET /repository/search/type/type_gtfs_agency
# operationId: search_type_gtfs_agency
export def "repository-search-type-type-gtfs-agency agency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_gtfs_agency" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Transit Route' entry type
#
# GET /repository/search/type/type_gtfs_route
# operationId: search_type_gtfs_route
export def "repository-search-type-type-gtfs-route route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-gtfs-routeroute-id: string # Route ID
  --searchtype-gtfs-routestop-names: string # Stop Names
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_gtfs_route.route_id" $searchtype_gtfs_routeroute_id "scalar") (serialize-qp "search.type_gtfs_route.stop_names" $searchtype_gtfs_routestop_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_gtfs_route" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Transit Route Collection' entry type
#
# GET /repository/search/type/type_gtfs_routes
# operationId: search_type_gtfs_routes
export def "repository-search-type-type-gtfs-routes routes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_gtfs_routes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Transit Stop' entry type
#
# GET /repository/search/type/type_gtfs_stop
# operationId: search_type_gtfs_stop
export def "repository-search-type-type-gtfs-stop stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-gtfs-stopstop-id: string # Stop ID
  --searchtype-gtfs-stopstop-code: string # Stop Code
  --searchtype-gtfs-stopzone-id: string # Zone ID
  --searchtype-gtfs-stoplocation-type: string # Location Type
  --searchtype-gtfs-stopwheelchair-boarding: string # Wheelchair Boarding
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_gtfs_stop.stop_id" $searchtype_gtfs_stopstop_id "scalar") (serialize-qp "search.type_gtfs_stop.stop_code" $searchtype_gtfs_stopstop_code "scalar") (serialize-qp "search.type_gtfs_stop.zone_id" $searchtype_gtfs_stopzone_id "scalar") (serialize-qp "search.type_gtfs_stop.location_type" $searchtype_gtfs_stoplocation_type "scalar") (serialize-qp "search.type_gtfs_stop.wheelchair_boarding" $searchtype_gtfs_stopwheelchair_boarding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_gtfs_stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Transit Stop Collection' entry type
#
# GET /repository/search/type/type_gtfs_stops
# operationId: search_type_gtfs_stops
export def "repository-search-type-type-gtfs-stops stops" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_gtfs_stops" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Transit Trip' entry type
#
# GET /repository/search/type/type_gtfs_trip
# operationId: search_type_gtfs_trip
export def "repository-search-type-type-gtfs-trip trip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-gtfs-triptrip-id: string # Trip ID
  --searchtype-gtfs-tripstop-ids: string # Stop IDS
  --searchtype-gtfs-tripwheelchair-accessible: string # Wheelchair Accessible
  --searchtype-gtfs-tripbikes-allowed: string # Bikes Allowed
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_gtfs_trip.trip_id" $searchtype_gtfs_triptrip_id "scalar") (serialize-qp "search.type_gtfs_trip.stop_ids" $searchtype_gtfs_tripstop_ids "scalar") (serialize-qp "search.type_gtfs_trip.wheelchair_accessible" $searchtype_gtfs_tripwheelchair_accessible "scalar") (serialize-qp "search.type_gtfs_trip.bikes_allowed" $searchtype_gtfs_tripbikes_allowed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_gtfs_trip" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Hazard Data' entry type
#
# GET /repository/search/type/type_hazarddata
# operationId: search_type_hazarddata
export def "repository-search-type-type-hazarddata hazarddata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-hazarddatasource: string # Source Agency
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_hazarddata.source" $searchtype_hazarddatasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_hazarddata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Colorado DNR Stream Gage' entry type
#
# GET /repository/search/type/type_hydro_colorado
# operationId: search_type_hydro_colorado
export def "repository-search-type-type-hydro-colorado colorado" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-hydro-coloradosite-id: string # Site ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_hydro_colorado.site_id" $searchtype_hydro_coloradosite_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_hydro_colorado" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'IDV Bundle' entry type
#
# GET /repository/search/type/type_idv_bundle
# operationId: search_type_idv_bundle
export def "repository-search-type-type-idv-bundle bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_idv_bundle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Image' entry type
#
# GET /repository/search/type/type_image
# operationId: search_type_image
export def "repository-search-type-type-image image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_image" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Airport Image' entry type
#
# GET /repository/search/type/type_image_airport
# operationId: search_type_image_airport
export def "repository-search-type-type-image-airport airport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_image_airport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Webcam' entry type
#
# GET /repository/search/type/type_image_webcam
# operationId: search_type_image_webcam
export def "repository-search-type-type-image-webcam webcam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_image_webcam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'MB Bathymetry' entry type
#
# GET /repository/search/type/type_mb
# operationId: search_type_mb
export def "repository-search-type-type-mb mb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_mb" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Bathymetry Collection' entry type
#
# GET /repository/search/type/type_mb_collection
# operationId: search_type_mb_collection
export def "repository-search-type-type-mb-collection collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_mb_collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Basic MB point file' entry type
#
# GET /repository/search/type/type_mb_point_basic
# operationId: search_type_mb_point_basic
export def "repository-search-type-type-mb-point-basic basic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_mb_point_basic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Metadata Dictionary' entry type
#
# GET /repository/search/type/type_metameta_dictionary
# operationId: search_type_metameta_dictionary
export def "repository-search-type-type-metameta-dictionary dictionary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-metameta-dictionaryfield-index: int # Index
  --searchtype-metameta-dictionarydictionary-type: string # Type
  --searchtype-metameta-dictionaryshort-name: string # Short Name
  --searchtype-metameta-dictionarysuper-type: string # Super Type
  --searchtype-metameta-dictionaryisgroup: oneof<nothing, bool> # Is Group
  --searchtype-metameta-dictionaryhandler-class: string # Handler Class
  --searchtype-metameta-dictionaryproperties: string # Properties
  --searchtype-metameta-dictionarywiki-text: string # Wiki Text
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_metameta_dictionary.field_index" $searchtype_metameta_dictionaryfield_index "scalar") (serialize-qp "search.type_metameta_dictionary.dictionary_type" $searchtype_metameta_dictionarydictionary_type "scalar") (serialize-qp "search.type_metameta_dictionary.short_name" $searchtype_metameta_dictionaryshort_name "scalar") (serialize-qp "search.type_metameta_dictionary.super_type" $searchtype_metameta_dictionarysuper_type "scalar") (serialize-qp "search.type_metameta_dictionary.isgroup" $searchtype_metameta_dictionaryisgroup "scalar") (serialize-qp "search.type_metameta_dictionary.handler_class" $searchtype_metameta_dictionaryhandler_class "scalar") (serialize-qp "search.type_metameta_dictionary.properties" $searchtype_metameta_dictionaryproperties "scalar") (serialize-qp "search.type_metameta_dictionary.wiki_text" $searchtype_metameta_dictionarywiki_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_metameta_dictionary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Metadata Field' entry type
#
# GET /repository/search/type/type_metameta_field
# operationId: search_type_metameta_field
export def "repository-search-type-type-metameta-field field" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-metameta-fieldfield-index: int # Index
  --searchtype-metameta-fieldfield-id: string # Field ID
  --searchtype-metameta-fielddatatype: string # Data Type
  --searchtype-metameta-fieldenumeration-values: string # Enumeration Values
  --searchtype-metameta-fieldproperties: string # Properties
  --searchtype-metameta-fielddatabase-column-size: int # Database Column Size
  --searchtype-metameta-fieldmissing: string # Missing Value
  --searchtype-metameta-fieldunit: string # Unit
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_metameta_field.field_index" $searchtype_metameta_fieldfield_index "scalar") (serialize-qp "search.type_metameta_field.field_id" $searchtype_metameta_fieldfield_id "scalar") (serialize-qp "search.type_metameta_field.datatype" $searchtype_metameta_fielddatatype "scalar") (serialize-qp "search.type_metameta_field.enumeration_values" $searchtype_metameta_fieldenumeration_values "scalar") (serialize-qp "search.type_metameta_field.properties" $searchtype_metameta_fieldproperties "scalar") (serialize-qp "search.type_metameta_field.database_column_size" $searchtype_metameta_fielddatabase_column_size "scalar") (serialize-qp "search.type_metameta_field.missing" $searchtype_metameta_fieldmissing "scalar") (serialize-qp "search.type_metameta_field.unit" $searchtype_metameta_fieldunit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_metameta_field" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NASA AMES File' entry type
#
# GET /repository/search/type/type_nasaames
# operationId: search_type_nasaames
export def "repository-search-type-type-nasaames nasaames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_nasaames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NetCDF Point Subset' entry type
#
# GET /repository/search/type/type_ncss
# operationId: search_type_ncss
export def "repository-search-type-type-ncss ncss" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_ncss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NITF File' entry type
#
# GET /repository/search/type/type_nitf
# operationId: search_type_nitf
export def "repository-search-type-type-nitf nitf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_nitf" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Ameriflux Level 2 CSV File' entry type
#
# GET /repository/search/type/type_point_ameriflux_level2
# operationId: search_type_point_ameriflux_level2
export def "repository-search-type-type-point-ameriflux-level2 level2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-ameriflux-level2site-id: string # Site ID
  --searchtype-point-ameriflux-level2contact: string # Contact
  --searchtype-point-ameriflux-level2ecosystem-type: string # Ecosystem Type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_ameriflux_level2.site_id" $searchtype_point_ameriflux_level2site_id "scalar") (serialize-qp "search.type_point_ameriflux_level2.contact" $searchtype_point_ameriflux_level2contact "scalar") (serialize-qp "search.type_point_ameriflux_level2.ecosystem_type" $searchtype_point_ameriflux_level2ecosystem_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ameriflux_level2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'AMRC Final QC Data' entry type
#
# GET /repository/search/type/type_point_amrc_final
# operationId: search_type_point_amrc_final
export def "repository-search-type-type-point-amrc-final final" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-amrc-finalsite-id: string # Site ID
  --searchtype-point-amrc-finalsite-name: string # Site Name
  --searchtype-point-amrc-finalargos-id: string # Argos ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_amrc_final.site_id" $searchtype_point_amrc_finalsite_id "scalar") (serialize-qp "search.type_point_amrc_final.site_name" $searchtype_point_amrc_finalsite_name "scalar") (serialize-qp "search.type_point_amrc_final.argos_id" $searchtype_point_amrc_finalargos_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_amrc_final" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'AMRC Freewave  Data' entry type
#
# GET /repository/search/type/type_point_amrc_freewave
# operationId: search_type_point_amrc_freewave
export def "repository-search-type-type-point-amrc-freewave freewave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-amrc-freewavestation-name: string # Station Name
  --searchtype-point-amrc-freewaveformat: string # File Format
  --searchtype-point-amrc-freewavedatalogger-model: string # Data Logger Model
  --searchtype-point-amrc-freewavedatalogger-serial: string # Data Logger Serial
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_amrc_freewave.station_name" $searchtype_point_amrc_freewavestation_name "scalar") (serialize-qp "search.type_point_amrc_freewave.format" $searchtype_point_amrc_freewaveformat "scalar") (serialize-qp "search.type_point_amrc_freewave.datalogger_model" $searchtype_point_amrc_freewavedatalogger_model "scalar") (serialize-qp "search.type_point_amrc_freewave.datalogger_serial" $searchtype_point_amrc_freewavedatalogger_serial "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_amrc_freewave" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'CZO Display File Format' entry type
#
# GET /repository/search/type/type_point_czo
# operationId: search_type_point_czo
export def "repository-search-type-type-point-czo czo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_czo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'GC-Net Point Data' entry type
#
# GET /repository/search/type/type_point_gcnet
# operationId: search_type_point_gcnet
export def "repository-search-type-type-point-gcnet gcnet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_gcnet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'IAGA 2002 Geomagnetism Data' entry type
#
# GET /repository/search/type/type_point_geomag_iaga2002
# operationId: search_type_point_geomag_iaga2002
export def "repository-search-type-type-point-geomag-iaga2002 iaga2002" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-geomag-iaga2002iaga-code: string # IAGA Code
  --searchtype-point-geomag-iaga2002station-name: string # Station Name
  --searchtype-point-geomag-iaga2002source-of-data: string # Source of data
  --searchtype-point-geomag-iaga2002digital-sampling: string # Digital Sampling
  --searchtype-point-geomag-iaga2002data-interval: string # Data Interval
  --searchtype-point-geomag-iaga2002data-type: string # Data Type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_geomag_iaga2002.iaga_code" $searchtype_point_geomag_iaga2002iaga_code "scalar") (serialize-qp "search.type_point_geomag_iaga2002.station_name" $searchtype_point_geomag_iaga2002station_name "scalar") (serialize-qp "search.type_point_geomag_iaga2002.source_of_data" $searchtype_point_geomag_iaga2002source_of_data "scalar") (serialize-qp "search.type_point_geomag_iaga2002.digital_sampling" $searchtype_point_geomag_iaga2002digital_sampling "scalar") (serialize-qp "search.type_point_geomag_iaga2002.data_interval" $searchtype_point_geomag_iaga2002data_interval "scalar") (serialize-qp "search.type_point_geomag_iaga2002.data_type" $searchtype_point_geomag_iaga2002data_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_geomag_iaga2002" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'WaterML' entry type
#
# GET /repository/search/type/type_point_hydro_waterml
# operationId: search_type_point_hydro_waterml
export def "repository-search-type-type-point-hydro-waterml waterml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-hydro-watermlsite-code: string # Site Code
  --searchtype-point-hydro-watermlsite-name: string # Site Name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_hydro_waterml.site_code" $searchtype_point_hydro_watermlsite_code "scalar") (serialize-qp "search.type_point_hydro_waterml.site_name" $searchtype_point_hydro_watermlsite_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_hydro_waterml" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ATM Ice SSN Data' entry type
#
# GET /repository/search/type/type_point_icebridge_atm_icessn
# operationId: search_type_point_icebridge_atm_icessn
export def "repository-search-type-type-point-icebridge-atm-icessn icessn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_icebridge_atm_icessn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'ATM QFIT Data' entry type
#
# GET /repository/search/type/type_point_icebridge_atm_qfit
# operationId: search_type_point_icebridge_atm_qfit
export def "repository-search-type-type-point-icebridge-atm-qfit qfit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_icebridge_atm_qfit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'McCords Irmcr2 Data' entry type
#
# GET /repository/search/type/type_point_icebridge_mccords_irmcr2
# operationId: search_type_point_icebridge_mccords_irmcr2
export def "repository-search-type-type-point-icebridge-mccords-irmcr2 irmcr2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_icebridge_mccords_irmcr2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'McCords Irmcr3 Data' entry type
#
# GET /repository/search/type/type_point_icebridge_mccords_irmcr3
# operationId: search_type_point_icebridge_mccords_irmcr3
export def "repository-search-type-type-point-icebridge-mccords-irmcr3 irmcr3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_icebridge_mccords_irmcr3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Paris Data' entry type
#
# GET /repository/search/type/type_point_icebridge_paris
# operationId: search_type_point_icebridge_paris
export def "repository-search-type-type-point-icebridge-paris paris" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_icebridge_paris" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'IDV Point File' entry type
#
# GET /repository/search/type/type_point_idv
# operationId: search_type_point_idv
export def "repository-search-type-type-point-idv idv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_idv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Inline Point File' entry type
#
# GET /repository/search/type/type_point_inline
# operationId: search_type_point_inline
export def "repository-search-type-type-point-inline inline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_inline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NC  DC Climate Data' entry type
#
# GET /repository/search/type/type_point_ncdc_climate
# operationId: search_type_point_ncdc_climate
export def "repository-search-type-type-point-ncdc-climate climate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ncdc_climate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NetCDF Point File' entry type
#
# GET /repository/search/type/type_point_netcdf
# operationId: search_type_point_netcdf
export def "repository-search-type-type-point-netcdf netcdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_netcdf" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA Carbon Measurements' entry type
#
# GET /repository/search/type/type_point_noaa_carbon
# operationId: search_type_point_noaa_carbon
export def "repository-search-type-type-point-noaa-carbon carbon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-noaa-carbonsite-id: string # Site ID
  --searchtype-point-noaa-carbonparameter: string # Parameter
  --searchtype-point-noaa-carbonproject: string # Project
  --searchtype-point-noaa-carbonlab-id-number: string # Lab ID Number
  --searchtype-point-noaa-carbonmeasurement-group: string # Measurement Group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_noaa_carbon.site_id" $searchtype_point_noaa_carbonsite_id "scalar") (serialize-qp "search.type_point_noaa_carbon.parameter" $searchtype_point_noaa_carbonparameter "scalar") (serialize-qp "search.type_point_noaa_carbon.project" $searchtype_point_noaa_carbonproject "scalar") (serialize-qp "search.type_point_noaa_carbon.lab_id_number" $searchtype_point_noaa_carbonlab_id_number "scalar") (serialize-qp "search.type_point_noaa_carbon.measurement_group" $searchtype_point_noaa_carbonmeasurement_group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_noaa_carbon" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA Flask Event Measurements' entry type
#
# GET /repository/search/type/type_point_noaa_flask_event
# operationId: search_type_point_noaa_flask_event
export def "repository-search-type-type-point-noaa-flask-event event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-noaa-flask-eventsite-id: string # Site ID
  --searchtype-point-noaa-flask-eventparameter: string # Parameter
  --searchtype-point-noaa-flask-eventproject: string # Project
  --searchtype-point-noaa-flask-eventlab-id-number: string # Lab ID Number
  --searchtype-point-noaa-flask-eventmeasurement-group: string # Measurement Group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_noaa_flask_event.site_id" $searchtype_point_noaa_flask_eventsite_id "scalar") (serialize-qp "search.type_point_noaa_flask_event.parameter" $searchtype_point_noaa_flask_eventparameter "scalar") (serialize-qp "search.type_point_noaa_flask_event.project" $searchtype_point_noaa_flask_eventproject "scalar") (serialize-qp "search.type_point_noaa_flask_event.lab_id_number" $searchtype_point_noaa_flask_eventlab_id_number "scalar") (serialize-qp "search.type_point_noaa_flask_event.measurement_group" $searchtype_point_noaa_flask_eventmeasurement_group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_noaa_flask_event" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA Flask Month Measurements' entry type
#
# GET /repository/search/type/type_point_noaa_flask_month
# operationId: search_type_point_noaa_flask_month
export def "repository-search-type-type-point-noaa-flask-month month" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-noaa-flask-monthsite-id: string # Site ID
  --searchtype-point-noaa-flask-monthparameter: string # Parameter
  --searchtype-point-noaa-flask-monthproject: string # Project
  --searchtype-point-noaa-flask-monthlab-id-number: string # Lab ID Number
  --searchtype-point-noaa-flask-monthmeasurement-group: string # Measurement Group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_noaa_flask_month.site_id" $searchtype_point_noaa_flask_monthsite_id "scalar") (serialize-qp "search.type_point_noaa_flask_month.parameter" $searchtype_point_noaa_flask_monthparameter "scalar") (serialize-qp "search.type_point_noaa_flask_month.project" $searchtype_point_noaa_flask_monthproject "scalar") (serialize-qp "search.type_point_noaa_flask_month.lab_id_number" $searchtype_point_noaa_flask_monthlab_id_number "scalar") (serialize-qp "search.type_point_noaa_flask_month.measurement_group" $searchtype_point_noaa_flask_monthmeasurement_group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_noaa_flask_month" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA MADIS Point Data' entry type
#
# GET /repository/search/type/type_point_noaa_madis
# operationId: search_type_point_noaa_madis
export def "repository-search-type-type-point-noaa-madis madis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_noaa_madis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA Tower Network' entry type
#
# GET /repository/search/type/type_point_noaa_tower
# operationId: search_type_point_noaa_tower
export def "repository-search-type-type-point-noaa-tower tower" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-noaa-towersite-id: string # Site ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_noaa_tower.site_id" $searchtype_point_noaa_towersite_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_noaa_tower" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SeaBird CNV Data' entry type
#
# GET /repository/search/type/type_point_ocean_cnv
# operationId: search_type_point_ocean_cnv
export def "repository-search-type-type-point-ocean-cnv cnv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_cnv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SADO TTS Data' entry type
#
# GET /repository/search/type/type_point_ocean_csv_sado_TTS
# operationId: search_type_point_ocean_csv_sado_TTS
export def "repository-search-type-type-point-ocean-csv-sado-tts TTS" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_csv_sado_TTS" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SADO Meteo Data' entry type
#
# GET /repository/search/type/type_point_ocean_csv_sado_meteo
# operationId: search_type_point_ocean_csv_sado_meteo
export def "repository-search-type-type-point-ocean-csv-sado-meteo meteo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_csv_sado_meteo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SADO Position Data' entry type
#
# GET /repository/search/type/type_point_ocean_csv_sado_position
# operationId: search_type_point_ocean_csv_sado_position
export def "repository-search-type-type-point-ocean-csv-sado-position position" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_csv_sado_position" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NetCDF Glider Data' entry type
#
# GET /repository/search/type/type_point_ocean_netcdf_glider
# operationId: search_type_point_ocean_netcdf_glider
export def "repository-search-type-type-point-ocean-netcdf-glider glider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-ocean-netcdf-trackplatform: string # Platform
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_ocean_netcdf_track.platform" $searchtype_point_ocean_netcdf_trackplatform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_netcdf_glider" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NetCDF Track Data' entry type
#
# GET /repository/search/type/type_point_ocean_netcdf_track
# operationId: search_type_point_ocean_netcdf_track
export def "repository-search-type-type-point-ocean-netcdf-track track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-ocean-netcdf-trackplatform: string # Platform
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_ocean_netcdf_track.platform" $searchtype_point_ocean_netcdf_trackplatform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_netcdf_track" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'OOI Data' entry type
#
# GET /repository/search/type/type_point_ocean_ooi_dmgx
# operationId: search_type_point_ocean_ooi_dmgx
export def "repository-search-type-type-point-ocean-ooi-dmgx dmgx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_ocean_ooi_dmgx" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Open AQ Air Quality' entry type
#
# GET /repository/search/type/type_point_openaq
# operationId: search_type_point_openaq
export def "repository-search-type-type-point-openaq openaq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-openaqlocation: string # Location
  --searchtype-point-openaqcountry: string # Country
  --searchtype-point-openaqcity: string # City
  --searchtype-point-openaqhours-offset: int # Offset Hours
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_openaq.location" $searchtype_point_openaqlocation "scalar") (serialize-qp "search.type_point_openaq.country" $searchtype_point_openaqcountry "scalar") (serialize-qp "search.type_point_openaq.city" $searchtype_point_openaqcity "scalar") (serialize-qp "search.type_point_openaq.hours_offset" $searchtype_point_openaqhours_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_openaq" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'PBO Position Time Series' entry type
#
# GET /repository/search/type/type_point_pbo_position_time_series
# operationId: search_type_point_pbo_position_time_series
export def "repository-search-type-type-point-pbo-position-time-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-pbo-position-time-seriesfour-char-id: string # Four Char ID
  --searchtype-point-pbo-position-time-seriesstation-name: string # Station Name
  --searchtype-point-pbo-position-time-seriesreference-frame: string # Reference Frame
  --searchtype-point-pbo-position-time-seriesformat-version: string # Format Version
  --searchtype-point-pbo-position-time-seriesprocessing-center: string # Processing Center
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_pbo_position_time_series.four_char_id" $searchtype_point_pbo_position_time_seriesfour_char_id "scalar") (serialize-qp "search.type_point_pbo_position_time_series.station_name" $searchtype_point_pbo_position_time_seriesstation_name "scalar") (serialize-qp "search.type_point_pbo_position_time_series.reference_frame" $searchtype_point_pbo_position_time_seriesreference_frame "scalar") (serialize-qp "search.type_point_pbo_position_time_series.format_version" $searchtype_point_pbo_position_time_seriesformat_version "scalar") (serialize-qp "search.type_point_pbo_position_time_series.processing_center" $searchtype_point_pbo_position_time_seriesprocessing_center "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_pbo_position_time_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Simple Records' entry type
#
# GET /repository/search/type/type_point_simple_records
# operationId: search_type_point_simple_records
export def "repository-search-type-type-point-simple-records records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_simple_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SNOTEL Snow Data' entry type
#
# GET /repository/search/type/type_point_snotel
# operationId: search_type_point_snotel
export def "repository-search-type-type-point-snotel snotel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-snotelsite-id: string # Site ID
  --searchtype-point-snotelsite-number: string # Site Number
  --searchtype-point-snotelstate: string # State
  --searchtype-point-snotelnetwork: string # Network
  --searchtype-point-snotelhuc-name: string # HUC Name
  --searchtype-point-snotelhuc-id: string # HUC ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_snotel.site_id" $searchtype_point_snotelsite_id "scalar") (serialize-qp "search.type_point_snotel.site_number" $searchtype_point_snotelsite_number "scalar") (serialize-qp "search.type_point_snotel.state" $searchtype_point_snotelstate "scalar") (serialize-qp "search.type_point_snotel.network" $searchtype_point_snotelnetwork "scalar") (serialize-qp "search.type_point_snotel.huc_name" $searchtype_point_snotelhuc_name "scalar") (serialize-qp "search.type_point_snotel.huc_id" $searchtype_point_snotelhuc_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_snotel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Record Text File' entry type
#
# GET /repository/search/type/type_point_text
# operationId: search_type_point_text
export def "repository-search-type-type-point-text text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_text" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Global Geodynamics GGP Format' entry type
#
# GET /repository/search/type/type_point_wsbb_ggp
# operationId: search_type_point_wsbb_ggp
export def "repository-search-type-type-point-wsbb-ggp ggp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-point-wsbb-ggpstation: string # Station
  --searchtype-point-wsbb-ggpinstrument: string # Instrument
  --searchtype-point-wsbb-ggpauthor: string # Author
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_point_wsbb_ggp.station" $searchtype_point_wsbb_ggpstation "scalar") (serialize-qp "search.type_point_wsbb_ggp.instrument" $searchtype_point_wsbb_ggpinstrument "scalar") (serialize-qp "search.type_point_wsbb_ggp.author" $searchtype_point_wsbb_ggpauthor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_point_wsbb_ggp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NOAA-ESRL-PSD Monthly Climate Index' entry type
#
# GET /repository/search/type/type_psd_monthly_climate_index
# operationId: search_type_psd_monthly_climate_index
export def "repository-search-type-type-psd-monthly-climate-index index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchtype-psd-monthly-climate-indexunits: string # Units
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.type_psd_monthly_climate_index.units" $searchtype_psd_monthly_climate_indexunits "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_psd_monthly_climate_index" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'QUANDL Series' entry type
#
# GET /repository/search/type/type_quandl_series
# operationId: search_type_quandl_series
export def "repository-search-type-type-quandl-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_quandl_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Service Group' entry type
#
# GET /repository/search/type/type_service_group
# operationId: search_type_service_group
export def "repository-search-type-type-service-group group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_service_group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Service Link' entry type
#
# GET /repository/search/type/type_service_link
# operationId: search_type_service_link
export def "repository-search-type-type-service-link link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_service_link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'SOCRATA Series' entry type
#
# GET /repository/search/type/type_socrata_series
# operationId: search_type_socrata_series
export def "repository-search-type-type-socrata-series series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_socrata_series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'COD Sounding' entry type
#
# GET /repository/search/type/type_sounding_cod
# operationId: search_type_sounding_cod
export def "repository-search-type-type-sounding-cod cod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_sounding_cod" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'FRD Sounding' entry type
#
# GET /repository/search/type/type_sounding_frd
# operationId: search_type_sounding_frd
export def "repository-search-type-type-sounding-frd frd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_sounding_frd" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'GSD Sounding' entry type
#
# GET /repository/search/type/type_sounding_gsd
# operationId: search_type_sounding_gsd
export def "repository-search-type-type-sounding-gsd gsd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_sounding_gsd" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'UW Sounding' entry type
#
# GET /repository/search/type/type_sounding_wyoming
# operationId: search_type_sounding_wyoming
export def "repository-search-type-type-sounding-wyoming wyoming" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_sounding_wyoming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'NREL TMY Data' entry type
#
# GET /repository/search/type/type_tmy
# operationId: search_type_tmy
export def "repository-search-type-type-tmy tmy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_tmy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Tweet' entry type
#
# GET /repository/search/type/type_tweet
# operationId: search_type_tweet
export def "repository-search-type-type-tweet tweet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_tweet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'USGS Stream Gauge' entry type
#
# GET /repository/search/type/type_usgs_gauge
# operationId: search_type_usgs_gauge
export def "repository-search-type-type-usgs-gauge gauge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_usgs_gauge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Virtual Group' entry type
#
# GET /repository/search/type/type_virtual
# operationId: search_type_virtual
export def "repository-search-type-type-virtual virtual" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_virtual" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'WMS Capabilities' entry type
#
# GET /repository/search/type/type_wms_capabilities
# operationId: search_type_wms_capabilities
export def "repository-search-type-type-wms-capabilities capabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_wms_capabilities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'WMS Layer' entry type
#
# GET /repository/search/type/type_wms_layer
# operationId: search_type_wms_layer
export def "repository-search-type-type-wms-layer layer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/type_wms_layer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Ufo Sightings' entry type
#
# GET /repository/search/type/ufo_sightings
# operationId: search_ufo_sightings
export def "repository-search-type-ufo-sightings sightings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-ufo-sightingsdatetime: string # Datetime
  --searchdb-ufo-sightingscity: string # City
  --searchdb-ufo-sightingsstate: string # State
  --searchdb-ufo-sightingscountry: string # Country
  --searchdb-ufo-sightingsshape: string # Shape
  --searchdb-ufo-sightingsduration-seconds: float # Duration (seconds) (format: double)
  --searchdb-ufo-sightingsduration-hours-min: string # Duration (hours/min)
  --searchdb-ufo-sightingscomments: string # Comments
  --searchdb-ufo-sightingsdate-posted: string # Date Posted
  --searchdb-ufo-sightingslatitude: float # Latitude (format: double)
  --searchdb-ufo-sightingslongitude: float # Longitude (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_ufo_sightings.datetime" $searchdb_ufo_sightingsdatetime "scalar") (serialize-qp "search.db_ufo_sightings.city" $searchdb_ufo_sightingscity "scalar") (serialize-qp "search.db_ufo_sightings.state" $searchdb_ufo_sightingsstate "scalar") (serialize-qp "search.db_ufo_sightings.country" $searchdb_ufo_sightingscountry "scalar") (serialize-qp "search.db_ufo_sightings.shape" $searchdb_ufo_sightingsshape "scalar") (serialize-qp "search.db_ufo_sightings.duration_seconds" $searchdb_ufo_sightingsduration_seconds "scalar") (serialize-qp "search.db_ufo_sightings.duration_hours_min" $searchdb_ufo_sightingsduration_hours_min "scalar") (serialize-qp "search.db_ufo_sightings.comments" $searchdb_ufo_sightingscomments "scalar") (serialize-qp "search.db_ufo_sightings.date_posted" $searchdb_ufo_sightingsdate_posted "scalar") (serialize-qp "search.db_ufo_sightings.latitude" $searchdb_ufo_sightingslatitude "scalar") (serialize-qp "search.db_ufo_sightings.longitude" $searchdb_ufo_sightingslongitude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/ufo_sightings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'US Places' entry type
#
# GET /repository/search/type/us_places
# operationId: search_us_places
export def "repository-search-type-us-places places" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-us-placesfeature-name: string # Place Name
  --searchdb-us-placesfeature-class: string # Place Type
  --searchdb-us-placesstate-alpha: string # State
  --searchdb-us-placescounty-name: string # County Name
  --searchdb-us-placeslocation: string # Location
  --searchdb-us-placeselev-in-ft: float # Elev In Ft (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_us_places.feature_name" $searchdb_us_placesfeature_name "scalar") (serialize-qp "search.db_us_places.feature_class" $searchdb_us_placesfeature_class "scalar") (serialize-qp "search.db_us_places.state_alpha" $searchdb_us_placesstate_alpha "scalar") (serialize-qp "search.db_us_places.county_name" $searchdb_us_placescounty_name "scalar") (serialize-qp "search.db_us_places.location" $searchdb_us_placeslocation "scalar") (serialize-qp "search.db_us_places.elev_in_ft" $searchdb_us_placeselev_in_ft "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/us_places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Simple Yes-No Vote' entry type
#
# GET /repository/search/type/vote_yesno
# operationId: search_vote_yesno
export def "repository-search-type-vote-yesno yesno" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchdb-vote-yesnovote: string # My Vote
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.db_vote_yesno.vote" $searchdb_vote_yesnovote "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/vote_yesno" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Weblog' entry type
#
# GET /repository/search/type/weblog
# operationId: search_weblog
export def "repository-search-type-weblog weblog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/weblog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search API for 'Wiki Page' entry type
#
# GET /repository/search/type/wikipage
# operationId: search_wikipage
export def "repository-search-type-wikipage wikipage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Search text
  --name: string # Search name
  --description: string # Search description
  --fromdate: string # From date (format: date-time)
  --todate: string # To date (format: date-time)
  --createdatefrom: string # Archive create date from (format: date-time)
  --createdateto: string # Archive create date to (format: date-time)
  --changedatefrom: string # Archive change date from (format: date-time)
  --changedateto: string # Archive change date to (format: date-time)
  --group: string # Parent entry
  --filesuffix: string # File suffix
  --maxlatitude: float # Northern bounds of search (format: float)
  --minlongitude: float # Western bounds of search (format: float)
  --minlatitude: float # Southern bounds of search (format: float)
  --maxlongitude: float # Eastern bounds of search (format: float)
  --max: int # Max number of results
  --skip: int # Number to skip
  --searchwikipagewikitext: string # Wiki Text
  --searchwikipagecategory: string # Wiki Page Category
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "createdate.from" $createdatefrom "scalar") (serialize-qp "createdate.to" $createdateto "scalar") (serialize-qp "changedate.from" $changedatefrom "scalar") (serialize-qp "changedate.to" $changedateto "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "filesuffix" $filesuffix "scalar") (serialize-qp "maxlatitude" $maxlatitude "scalar") (serialize-qp "minlongitude" $minlongitude "scalar") (serialize-qp "minlatitude" $minlatitude "scalar") (serialize-qp "maxlongitude" $maxlongitude "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "search.wikipage.wikitext" $searchwikipagewikitext "scalar") (serialize-qp "search.wikipage.category" $searchwikipagecategory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repository/search/type/wikipage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
