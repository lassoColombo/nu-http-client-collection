# Auto-generated client for GererMesAffaires {REST:API} v1.0.6
# Source: https://api.apis.guru/v2/specs/gerermesaffaires.com/1.0.6/openapi.json
# Auth: --token flag or $env.GERERMESAFFAIRES_REST_API_TOKEN

const BASE_URL = "https://sandbox.gerermesaffaires.com/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GERERMESAFFAIRES_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox.gerermesaffaires.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Type-completer [] { ["association" "company" "enterprise" "private"] }
def Groups-completer [] { ["legal" "tax" "wealth management"] }
def Role-completer [] { ["collaborator" "manager"] }
def Type-completer-1 [] { ["association" "company" "enterprise"] }
def Sex-completer [] { ["female" "male"] }
def Level-completer [] { ["confidential" "public" "regular"] }
def HasCompanyRegistrationCertificate-completer [] { ["false" "true"] }
def HasStatus-completer [] { ["false" "true"] }
def HasSireneRegister-completer [] { ["false" "true"] }
def HasMinutes-completer [] { ["false" "true"] }
def Event-completer [] { ["Board" "CGM" "ConstituentAssembly" "Consulting" "EGM" "ExecutiveCommittee" "OGM" "Office" "Other" "OtherEvent" "PartnersMeeting" "SolePartner"] }
def accept-completer [] { ["application/json" "multipart/form-data"] }
def Groups-completer-1 [] { ["accounting" "legal" "purchases" "sales" "social" "social manager" "tax" "wealth management"] }
def Role-completer-1 [] { ["assistant" "collaborator" "empty"] }
def Right-completer [] { ["read" "write"] }
def Validated-completer [] { ["false" "true"] }
def ClientManagement-completer [] { ["adn" "manager" "no"] }
def Player-completer [] { ["assistant" "collaborator" "guest" "manager" "owner"] }
def RootFolders-completer [] { ["all"] }
def Type-completer-2 [] { ["amendment" "contract" "delivery-order" "engagement-letter" "other" "purchase-order" "quotation"] }
def Order-completer [] { ["1st advance" "2nd advance" "3rd advance" "4th advance" "regularization"] }
def Account-completer [] { ["CAB" "DIV" "FHR" "IKM" "PRK" "PTT" "RES" "TXI" "VOY"] }
def Status-completer [] { ["R" "V" "W"] }
def Type-completer-3 [] { ["amending-invoice" "commercial-invoice" "credit-note" "credit-self-billing" "down-payment-invoice" "informations-invoice" "self-billing"] }
def WithExtend-completer [] { ["false" "true"] }
def SortOrder-completer [] { ["asc" "desc"] }
def SortName-completer [] { ["ExpenseDate" "InclVAT" "Title"] }
def SortName-completer-1 [] { ["Contracting" "DueDate" "InclVAT" "InvoiceDate" "PaymentDate" "Title"] }
def Category-completer [] { ["bank loan" "current account" "debt spreading" "leasing" "obligation" "overdraft agreement"] }
def Level-completer-1 [] { ["confidential" "regular"] }
def Status-completer-1 [] { ["ended" "validated" "waiting"] }
def Periodicity-completer [] { ["annual" "half-yearly" "monthly" "null" "quarterly"] }
def Type-completer-4 [] { ["mandatory" "null" "optional"] }
def Right-completer-1 [] { ["none" "read" "write"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "box-menus get" } } | get name | first)
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

# Returns predefined folders and workbooks of the Box for all the spaces
#
# GET /box/menus
export def "box-menus get" [
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
  let full_url = (build-url $base "/box/menus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of groups custom ordered by name
#
# GET /business-groups
export def "business-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the group (e.g. Dupond)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modifies an object
#
# PATCH /business-groups
export def "business-groups patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # e.g. Client Durand
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-groups")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a group (only for managers and ADN collaborators)
#
# POST /business-groups
export def "business-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Name: string # e.g. Client Durand
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-groups")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of groups custom for managers
#
# GET /business-groups/all
export def "business-groups-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business-groups/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a group
#
# GET /business-groups/{id}
export def "business-groups get" [
  id: string
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
  let full_url = (build-url $base $"/business-groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns spaces of the business group with id
#
# GET /business-groups/{id}/spaces
export def "business-groups-spaces get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the space (e.g. Mon Entreprise)
  --Type: string@Type-completer # Type of the space (e.g. private)
  --RegistrationNumber: string # registration number of the space (e.g. 12345)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Type" $Type "scalar") (serialize-qp "RegistrationNumber" $RegistrationNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/business-groups/($id)/spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a customer space from partner
#
# DELETE /business-groups/{id}/spaces/{spaceId}
export def "business-groups-spaces delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/business-groups/($id)/spaces/($spaceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# send an invitation to manager the private space of personId
#
# POST /business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/guest-in-space
export def "business-groups-spaces-legal-entities-customers-guest-in-space post" [
  id: string
  spaceId: string
  personId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Groups: list@Groups-completer # e.g. [tax, legal]
  Role: string@Role-completer # e.g. collaborator
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business-groups/($id)/spaces/($spaceId)/legal-entities/($personId)/customers/($folderId)/guest-in-space")
  let body = {Groups: $Groups, Role: $Role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a Space in a group
#
# POST /business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/spaces
# --Logo shape: {Content64Encoded?: string, Name?: string}
export def "business-groups-spaces-legal-entities-customers-spaces post" [
  id: string
  spaceId: string
  personId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Logo: record # shape: {Content64Encoded?: string, Name?: string}
  --Name: string # e.g. Mon Entreprise
  --TemplateSpaceId: string # e.g. PKOJOFOFKAOKF
  Type: string@Type-completer-1 # e.g. company
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/business-groups/($id)/spaces/($spaceId)/legal-entities/($personId)/customers/($folderId)/spaces")
  let body = {Logo: $Logo, Name: $Name, TemplateSpaceId: $TemplateSpaceId, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns predefined folders and workbooks of the Hub for all the spaces of the business group
#
# GET /hub/business-groups/{Id}/menus
export def "hub-business-groups-menus get" [
  Id: string
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
  let full_url = (build-url $base $"/hub/business-groups/($Id)/menus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document (this document is analyzed to be saved in the correct folder and correct space)
#
# POST /hub/documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-documents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --AddContractAllowed: oneof<nothing, bool> # e.g. true
  --Author: string # e.g. Antoine Dupond
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hub/documents")
  let body = {Accounting: $Accounting, AddContractAllowed: $AddContractAllowed, Author: $Author, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns predefined folders and workbooks of the Hub for all the spaces
#
# GET /hub/menus
export def "hub-menus get" [
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
  let full_url = (build-url $base "/hub/menus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns predefined folders and workbooks of the Hub for all the spaces and customer spaces
#
# GET /hub/menus/all
export def "hub-menus-all get" [
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
  let full_url = (build-url $base "/hub/menus/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payslip (this document is analyzed to be saved in the correct folder and correct space)
#
# POST /hub/payslips
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-payslips post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --AddContractAllowed: oneof<nothing, bool> # e.g. true
  --Author: string # e.g. Antoine Dupond
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hub/payslips")
  let body = {Accounting: $Accounting, AddContractAllowed: $AddContractAllowed, Author: $Author, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a document in a space (this document is analyzed to be saved in the correct folder)
#
# POST /hub/spaces/{spaceId}/documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-spaces-documents post" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hub/spaces/($spaceId)/documents")
  let body = {Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns predefined folders and workbooks of the Hub for the space
#
# GET /hub/spaces/{spaceId}/menus
export def "hub-spaces-menus get" [
  spaceId: string
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
  let full_url = (build-url $base $"/hub/spaces/($spaceId)/menus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payslip in a space (this document is analyzed to be saved in the correct folder)
#
# POST /hub/spaces/{spaceId}/payslips
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-spaces-payslips post" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hub/spaces/($spaceId)/payslips")
  let body = {Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns predefined entries
#
# GET /menus
export def "menus get" [
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
  let full_url = (build-url $base "/menus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# add a document to the target menuId
#
# POST /menus/{menuId}/documents
# --File shape: {Content64Encoded?: string, Name?: string}
export def "menus-documents post" [
  menuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Author: string # e.g. Antoine Dupond
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Report: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/menus/($menuId)/documents")
  let body = {Author: $Author, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns status of member
#
# GET /profile
export def "profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Contract: string # to get a contract (if not signed error 404 + html contract) (e.g. member)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Contract" $Contract "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify infos of profile
#
# PATCH /profile
# --Birth shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
# --IDFile shape: {Content64Encoded?: string, Name?: string}
export def "profile patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Birth: record # shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
  --BirthName: string # e.g. Dupond
  --Email: string # e.g. paule@durand.fr
  --FirstName: string # e.g. Paule
  --IDFile: record # shape: {Content64Encoded?: string, Name?: string}
  --Name: string # e.g. Durand
  --Sex: string@Sex-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let body = {Birth: $Birth, BirthName: $BirthName, Email: $Email, FirstName: $FirstName, IDFile: $IDFile, Name: $Name, Sex: $Sex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# create infos of profile
#
# POST /profile
# --Birth shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
# --IDFile shape: {Content64Encoded?: string, Name?: string}
export def "profile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Birth: record # shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
  BirthName: string # e.g. Dupond
  Email: string # e.g. paule@durand.fr
  FirstName: string # e.g. Paule
  --IDFile: record # shape: {Content64Encoded?: string, Name?: string}
  Name: string # e.g. Durand
  Sex: string@Sex-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let body = {Birth: $Birth, BirthName: $BirthName, Email: $Email, FirstName: $FirstName, IDFile: $IDFile, Name: $Name, Sex: $Sex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# modify email of profile
#
# PATCH /profile/email
export def "profile-email patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Email: string # e.g. paule@durand.fr
  --EmailCode: string # e.g. 1256
  --SMSCode: string # e.g. FAHF
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/email")
  let body = {Email: $Email, EmailCode: $EmailCode, SMSCode: $SMSCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns status of member
#
# GET /profile/id-file
export def "profile-id-file get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Contract: string # to get a contract (if not signed error 404 + html contract) (e.g. member)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Contract" $Contract "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profile/id-file" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify mobile of profile
#
# PATCH /profile/mobile
export def "profile-mobile patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Mobile: string # e.g. 33606060606
  --Password: string # e.g. azerty
  --SMSCode: string # e.g. FAHF
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/mobile")
  let body = {Mobile: $Mobile, Password: $Password, SMSCode: $SMSCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the method to get the validation code or the link to register after invitation
#
# GET /registration
export def "registration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Code: string # Code of the invitation (e.g. HFIHA)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Code" $Code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# complete the invitation
#
# POST /registration
export def "registration post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Code: string # e.g. OJFOA
  --Secret: string # e.g. 123456
]: any -> record<Private: record<FolderId: string, SpaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registration")
  let body = {Code: $Code, Secret: $Secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns member id of user logged
#
# GET /session
export def "session get" [
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
  let full_url = (build-url $base "/session")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns spaces of my group
#
# GET /spaces
export def "spaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the space (e.g. Mon Entreprise)
  --Type: string@Type-completer # Type of the space (e.g. private)
  --RegistrationNumber: string # registration number of the space (e.g. 12345)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Type" $Type "scalar") (serialize-qp "RegistrationNumber" $RegistrationNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Space in my group
#
# POST /spaces
# --Logo shape: {Content64Encoded?: string, Name?: string}
export def "spaces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LegalStatut: string # e.g. SA
  --Logo: record # shape: {Content64Encoded?: string, Name?: string}
  Name: string # e.g. Mon Entreprise
  --RegistrationNumber: string # e.g. 5146486846
  --TemplateSpaceId: string # e.g. PKOJOFOFKAOKF
  Type: string@Type-completer-1 # e.g. company
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spaces")
  let body = {LegalStatut: $LegalStatut, Logo: $Logo, Name: $Name, RegistrationNumber: $RegistrationNumber, TemplateSpaceId: $TemplateSpaceId, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all spaces
#
# GET /spaces/all
export def "spaces-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the space (e.g. Mon Entreprise)
  --Type: string@Type-completer # Type of the space (e.g. private)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Type" $Type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Space (only space not delivered to customer)
#
# DELETE /spaces/{id}
export def "spaces delete" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a space
#
# GET /spaces/{id}
export def "spaces get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Space (except private)
#
# PATCH /spaces/{id}
# --Logo shape: {Content64Encoded?: string, Name?: string}
export def "spaces patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Logo: record # shape: {Content64Encoded?: string, Name?: string}
  --Name: string # e.g. Mon Entreprise
  --TemplateSpaceId: string # e.g. PHAOH8486
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)")
  let body = {Logo: $Logo, Name: $Name, TemplateSpaceId: $TemplateSpaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of accounting years for the space {id}
#
# GET /spaces/{id}/accounting-year
export def "spaces-accounting-year get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --End: string # End date of the accounting year (YYYYMM or YYYYMMDD) (range not available) (e.g. 201603)
  --EffectiveDate: string # Effective date inside  the accounting year  (range not available) (e.g. 20160301)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "End" $End "scalar") (serialize-qp "EffectiveDate" $EffectiveDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/accounting-year" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a accounting year for the space id
#
# POST /spaces/{id}/accounting-year
export def "spaces-accounting-year post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. ogm of the company
  End: string # e.g. 20181231
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --NetIncome: float # e.g. 52634.36
  --NetPosition: float # e.g. 14580.36
  --Start: string # e.g. 20180101
  --Tax: float # e.g. 45698.36
  --TaxableIncome: float # e.g. 869523.36
  --Turnover: float # e.g. 1025.36
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/accounting-year")
  let body = {About: $About, Comment: $Comment, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, NetIncome: $NetIncome, NetPosition: $NetPosition, Start: $Start, Tax: $Tax, TaxableIncome: $TaxableIncome, Turnover: $Turnover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of collective decisions for the space {id}
#
# GET /spaces/{id}/collective-decision
export def "spaces-collective-decision get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # Date of the collective decision YYYMMDD (e.g. 20160302,null)
  --Event: string # Event of the collective decision (see post for the list of events) (e.g. OGM)
  --Range: string # index range of the results (e.g. 10-19)
  --HasCompanyRegistrationCertificate: string@HasCompanyRegistrationCertificate-completer # If true returns only invoices with a CompanyRegistrationCertificate (e.g. true)
  --HasStatus: string@HasStatus-completer # If true returns only invoices with a Status (e.g. true)
  --HasSireneRegister: string@HasSireneRegister-completer # If true returns only invoices with a SireneRegister (e.g. true)
  --HasMinutes: string@HasMinutes-completer # If true returns only invoices with Minutes (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Event" $Event "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "HasCompanyRegistrationCertificate" $HasCompanyRegistrationCertificate "scalar") (serialize-qp "HasStatus" $HasStatus "scalar") (serialize-qp "HasSireneRegister" $HasSireneRegister "scalar") (serialize-qp "HasMinutes" $HasMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/collective-decision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a colletive decision for the space id
#
# POST /spaces/{id}/collective-decision
export def "spaces-collective-decision post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. ogm of the company
  Date: string # e.g. 20180202
  --DividendDistributions: float # e.g. 1025.36
  --DividendDistributionsDate: string # e.g. 20180203
  Event: string@Event-completer # for space type 'company' enums allowed are  'EGM','CGM','OGM','ConstituentAssembly','SolePartner','OtherEvent','Office','ExecutiveCommittee','Consulting','Board','PartnersMeeting' and for space type 'association' enums allowed are 'EGM','CGM','OGM','Other','Office','ExecutiveCommittee' (e.g. EGM)
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/collective-decision")
  let body = {About: $About, Comment: $Comment, Date: $Date, DividendDistributions: $DividendDistributions, DividendDistributionsDate: $DividendDistributionsDate, Event: $Event, Home: $Home, Keywords: $Keywords, Level: $Level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of company entities
#
# GET /spaces/{id}/company-entities
export def "spaces-company-entities list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the company entity (e.g. Source de France)
  --LegalName: string # Legal name of the company entity (e.g. Source de France SAS)
  --RegistrationNumber: string # registration number of the company entity (e.g. 12356213854)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "LegalName" $LegalName "scalar") (serialize-qp "RegistrationNumber" $RegistrationNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/company-entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Company Entity in a Space
#
# POST /spaces/{id}/company-entities
export def "spaces-company-entities post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ApeCode: string # e.g. 420F
  --ArchivalDate: string # e.g. 20160203
  --Comment: string # e.g. my brother
  LegalName: string # e.g. Mon entreprise Dupond
  --LegalStatut: string # e.g. SAS
  Name: string # e.g. Dupond
  --RegistrationNumber: string # e.g. 236542158
  --Type: string # e.g. EPT
  --VatNumber: string # e.g. 46546847864
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/company-entities")
  let body = {ApeCode: $ApeCode, ArchivalDate: $ArchivalDate, Comment: $Comment, LegalName: $LegalName, LegalStatut: $LegalStatut, Name: $Name, RegistrationNumber: $RegistrationNumber, Type: $Type, VatNumber: $VatNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of company entities even company entities archived
#
# GET /spaces/{id}/company-entities/all
export def "spaces-company-entities-all get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the company entity (e.g. Source de France)
  --RegistrationNumber: string # registration number of the company entity (e.g. 12356213854)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "RegistrationNumber" $RegistrationNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/company-entities/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a compay entity
#
# GET /spaces/{id}/company-entities/{companyId}
export def "spaces-company-entities get" [
  id: string
  companyId: string
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
  let full_url = (build-url $base $"/spaces/($id)/company-entities/($companyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a company entity
#
# PATCH /spaces/{id}/company-entities/{companyId}
export def "spaces-company-entities patch" [
  id: string
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ApeCode: string # e.g. 420F
  --ArchivalDate: string # e.g. 20160203
  --Comment: string # e.g. my brother
  --LegalName: string # e.g. Mon entreprise Dupond
  --LegalStatut: string # e.g. SAS
  --Name: string # e.g. Dupond
  --RegistrationNumber: string # e.g. 236542158
  --Type: string # e.g. EPT
  --VatNumber: string # e.g. 46546847864
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/company-entities/($companyId)")
  let body = {ApeCode: $ApeCode, ArchivalDate: $ArchivalDate, Comment: $Comment, LegalName: $LegalName, LegalStatut: $LegalStatut, Name: $Name, RegistrationNumber: $RegistrationNumber, Type: $Type, VatNumber: $VatNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all details of a company entity
#
# GET /spaces/{id}/company-entities/{personId}/details
export def "spaces-company-entities-details get" [
  id: string
  personId: string
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
  let full_url = (build-url $base $"/spaces/($id)/company-entities/($personId)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace or Add a contact detail for a person
#
# POST /spaces/{id}/company-entities/{personId}/details
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
export def "spaces-company-entities-details post" [
  id: string
  personId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  Designation: string # e.g. Office
  --Email: list
  --Phone: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/company-entities/($personId)/details")
  let body = {Address: $Address, Designation: $Designation, Email: $Email, Phone: $Phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a contact detail for a company entity
#
# DELETE /spaces/{id}/company-entities/{personId}/details/{designation}
export def "spaces-company-entities-details delete" [
  id: string
  personId: string
  designation: string
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
  let full_url = (build-url $base $"/spaces/($id)/company-entities/($personId)/details/($designation)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create an archive with documents
#
# POST /spaces/{id}/documents/download
export def "spaces-documents-download post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  DocumentId: list
]: any -> record<ZipFile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/documents/download")
  let body = {DocumentId: $DocumentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# return the access of a person in a customer contract
#
# GET /spaces/{id}/folders/{folderId}/persons/{memberId}
export def "spaces-folders-persons get" [
  id: string
  memberId: string
  folderId: string
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
  let full_url = (build-url $base $"/spaces/($id)/folders/($folderId)/persons/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/Modify/Delete a person in a customer contract (except manager)
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}
export def "spaces-folders-persons patch" [
  id: string
  memberId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Groups: list@Groups-completer-1 # e.g. [social, legal]
  --IsAdmin: oneof<nothing, bool> # e.g. false
  --Role: string@Role-completer-1 # e.g. collaborator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/folders/($folderId)/persons/($memberId)")
  let body = {Groups: $Groups, IsAdmin: $IsAdmin, Role: $Role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# open an access
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}/activeaccess
export def "spaces-folders-persons-activeaccess patch" [
  id: string
  memberId: string
  folderId: string
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
  let full_url = (build-url $base $"/spaces/($id)/folders/($folderId)/persons/($memberId)/activeaccess")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# close an access
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}/unactiveaccess
export def "spaces-folders-persons-unactiveaccess patch" [
  id: string
  memberId: string
  folderId: string
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
  let full_url = (build-url $base $"/spaces/($id)/folders/($folderId)/persons/($memberId)/unactiveaccess")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invite a owner in a space
#
# POST /spaces/{id}/folders/{folderId}/persons/{personId}/guest-in-space
export def "spaces-folders-persons-guest-in-space post" [
  folderId: string
  personId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PersonId: string # e.g. PAIHIHFA79TFA
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/folders/($folderId)/persons/($personId)/guest-in-space")
  let body = {PersonId: $PersonId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of groups
#
# GET /spaces/{id}/groups
export def "spaces-groups list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the groups (e.g. RH)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a group in a Space
#
# POST /spaces/{id}/groups
export def "spaces-groups post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # e.g. 20160203
  Name: string # e.g. RH
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/groups")
  let body = {EndDate: $EndDate, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of groups even archived of the space
#
# GET /spaces/{id}/groups/all
export def "spaces-groups-all get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the group (e.g. RH)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/groups/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a group
#
# GET /spaces/{id}/groups/{groupId}
export def "spaces-groups get" [
  id: string
  groupId: string
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
  let full_url = (build-url $base $"/spaces/($id)/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a group
#
# PATCH /spaces/{id}/groups/{groupId}
export def "spaces-groups patch" [
  id: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # e.g. 20160203
  --Name: string # e.g. RH
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/groups/($groupId)")
  let body = {EndDate: $EndDate, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete access to a folder for a group
#
# DELETE /spaces/{id}/groups/{groupId}/folders/{folderId}
export def "spaces-groups-folders delete" [
  id: string
  groupId: string
  folderId: string
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
  let full_url = (build-url $base $"/spaces/($id)/groups/($groupId)/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add access to a folder for a group
#
# PATCH /spaces/{id}/groups/{groupId}/folders/{folderId}
export def "spaces-groups-folders patch" [
  id: string
  groupId: string
  folderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Right: string@Right-completer # e.g. read
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/groups/($groupId)/folders/($folderId)")
  let body = {Right: $Right} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a person of a group
#
# DELETE /spaces/{id}/groups/{groupId}/persons/{memberId}
export def "spaces-groups-persons delete" [
  id: string
  groupId: string
  memberId: string
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
  let full_url = (build-url $base $"/spaces/($id)/groups/($groupId)/persons/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a person to a group
#
# PATCH /spaces/{id}/groups/{groupId}/persons/{memberId}
export def "spaces-groups-persons patch" [
  id: string
  groupId: string
  memberId: string
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
  let full_url = (build-url $base $"/spaces/($id)/groups/($groupId)/persons/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns legal information of a space (except private)
#
# GET /spaces/{id}/legal
export def "spaces-legal get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)/legal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify legal information of a Space (except private)
#
# PATCH /spaces/{id}/legal
export def "spaces-legal patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IdentificationNumber: string # e.g. 548
  --RegistrationDate: string # e.g. 20190325
  --RegistrationNumber: string # e.g. 123456
  --VATNumber: string # e.g. 123
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/legal")
  let body = {IdentificationNumber: $IdentificationNumber, RegistrationDate: $RegistrationDate, RegistrationNumber: $RegistrationNumber, VATNumber: $VATNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a space with the logo
#
# GET /spaces/{id}/logo
export def "spaces-logo get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of persons
#
# GET /spaces/{id}/persons
export def "spaces-persons list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Function: string # Function of the person (e.g. employee)
  --Range: string # index range of the results (e.g. 10-19)
  --Name: string # Name of the person (e.g. Germain)
  --Validated: string@Validated-completer # Status of the person (e.g. true)
  --Email: string # Email of the person (e.g. maxgermain@maxgermain.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Function" $Function "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "Name" $Name "scalar") (serialize-qp "Validated" $Validated "scalar") (serialize-qp "Email" $Email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/persons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Person in a Space
#
# POST /spaces/{id}/persons
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
# --Birth shape: {Date?: int, Place?: string}
export def "spaces-persons post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --ArchivalDate: string # e.g. 20160203
  --Birth: record # shape: {Date?: int, Place?: string}
  --Comment: string # e.g. my brother
  --Email: string # e.g. bertrand@monmail.com
  FirstName: string # e.g. Bertrand
  --Mobile: string # e.g. +33606060606
  Name: string # e.g. Dupond
  Sex: string@Sex-completer # e.g. male
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/persons")
  let body = {Address: $Address, ArchivalDate: $ArchivalDate, Birth: $Birth, Comment: $Comment, Email: $Email, FirstName: $FirstName, Mobile: $Mobile, Name: $Name, Sex: $Sex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of persons even persons archived
#
# GET /spaces/{id}/persons/all
export def "spaces-persons-all get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the person (e.g. Germain)
  --Function: string # Function of the person (e.g. employee)
  --Range: string # index range of the results (e.g. 10-19)
  --Validated: string@Validated-completer # Status of the person (e.g. true)
  --Email: string # Email of the person (e.g. maxgermain@maxgermain.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Function" $Function "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "Validated" $Validated "scalar") (serialize-qp "Email" $Email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/persons/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the role of a person
#
# PATCH /spaces/{id}/persons/{memberId}/player
export def "spaces-persons-player patch" [
  id: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientManagement: string@ClientManagement-completer
  --IsAdmin: oneof<nothing, bool> # e.g. true
  Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20210203
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/persons/($memberId)/player")
  let body = {ClientManagement: $ClientManagement, IsAdmin: $IsAdmin, Player: $Player, PlayerEnd: $PlayerEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a person
#
# DELETE /spaces/{id}/persons/{personId}
export def "spaces-persons delete" [
  id: string
  personId: string
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
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a person
#
# GET /spaces/{id}/persons/{personId}
export def "spaces-persons get" [
  id: string
  personId: string
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
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a person
#
# PATCH /spaces/{id}/persons/{personId}
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
# --Birth shape: {Date?: int, Place?: string}
export def "spaces-persons patch" [
  id: string
  personId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --ArchivalDate: string # e.g. 20160203
  --Birth: record # shape: {Date?: int, Place?: string}
  --Comment: string # e.g. my brother
  --Email: string # e.g. bertrand@monmail.com
  --FirstName: string # e.g. Bertrand
  --Mobile: string # e.g. +33606060606
  --Name: string # e.g. Dupond
  --Sex: string@Sex-completer # e.g. male
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)")
  let body = {Address: $Address, ArchivalDate: $ArchivalDate, Birth: $Birth, Comment: $Comment, Email: $Email, FirstName: $FirstName, Mobile: $Mobile, Name: $Name, Sex: $Sex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all details of a person
#
# GET /spaces/{id}/persons/{personId}/details
export def "spaces-persons-details get" [
  id: string
  personId: string
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
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace or Add a contact detail for a person
#
# POST /spaces/{id}/persons/{personId}/details
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
export def "spaces-persons-details post" [
  id: string
  personId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  Designation: string # e.g. Office
  --Email: list
  --Phone: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/details")
  let body = {Address: $Address, Designation: $Designation, Email: $Email, Phone: $Phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a contact detail for a person
#
# DELETE /spaces/{id}/persons/{personId}/details/{designation}
export def "spaces-persons-details delete" [
  id: string
  personId: string
  designation: string
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
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/details/($designation)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of folders with exceptionnal access of the person personId
#
# GET /spaces/{id}/persons/{personId}/folders
export def "spaces-persons-folders list" [
  id: string
  personId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of groups of the person personId
#
# GET /spaces/{id}/persons/{personId}/groups
export def "spaces-persons-groups get" [
  id: string
  personId: string
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
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of portfolios of the person personId
#
# GET /spaces/{id}/persons/{personId}/portfolios
export def "spaces-persons-portfolios get" [
  id: string
  personId: string
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
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/portfolios")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a portfolio for the person personId
#
# POST /spaces/{id}/persons/{personId}/portfolios
export def "spaces-persons-portfolios post" [
  id: string
  personId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --ArchivalDate: string # e.g. 20160203
  --Designation: string # e.g. My Portfolio
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Name: string # e.g. Dupond
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/persons/($personId)/portfolios")
  let body = {About: $About, ArchivalDate: $ArchivalDate, Designation: $Designation, Home: $Home, Keywords: $Keywords, Level: $Level, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add/Modify/Delete a person in a portfolio (except manager)
#
# PATCH /spaces/{id}/portfolios/{portfolioId}/persons/{memberId}
export def "spaces-portfolios-persons patch" [
  id: string
  memberId: string
  portfolioId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Apply: oneof<nothing, bool> # e.g. true
  --Groups: list@Groups-completer-1 # e.g. [social, legal]
  --IsAdmin: oneof<nothing, bool> # e.g. false
  --Role: string@Role-completer-1 # e.g. collaborator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/portfolios/($portfolioId)/persons/($memberId)")
  let body = {Apply: $Apply, Groups: $Groups, IsAdmin: $IsAdmin, Role: $Role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of professionalvehicles for the space {id}
#
# GET /spaces/{id}/professional-vehicles
export def "spaces-professional-vehicles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Designation: string # designation of the vehicle (e.g. peugeot)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Designation" $Designation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($id)/professional-vehicles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a professional vehicle for the space
#
# POST /spaces/{id}/professional-vehicles
export def "spaces-professional-vehicles post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Brand: string # e.g. Renault
  --Comment: string # e.g. Peugeot Lyon
  --CompanyTax: oneof<nothing, bool> # e.g. true
  --DateIn: string # e.g. 20201802
  --DateOut: string # e.g. 20201802
  Designation: string # e.g. peugeot siège
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, clio]
  --Level: string@Level-completer # e.g. confidential
  --Model: string # e.g. Clio
  --RegistrationDate: string # e.g. 20181231
  --RegistrationNumber: string # e.g. AA001AA
  --Type: string # e.g. car
  --Value: float # e.g. 1500.23
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/professional-vehicles")
  let body = {About: $About, Brand: $Brand, Comment: $Comment, CompanyTax: $CompanyTax, DateIn: $DateIn, DateOut: $DateOut, Designation: $Designation, Home: $Home, Keywords: $Keywords, Level: $Level, Model: $Model, RegistrationDate: $RegistrationDate, RegistrationNumber: $RegistrationNumber, Type: $Type, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns state of activation of logs
#
# GET /spaces/{id}/settings/nf203/logs
export def "spaces-settings-nf203-logs get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)/settings/nf203/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable/Disable logs
#
# POST /spaces/{id}/settings/nf203/logs
export def "spaces-settings-nf203-logs post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Enabled: oneof<nothing, bool> # e.g. true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/settings/nf203/logs")
  let body = {Enabled: $Enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all status of the space
#
# GET /spaces/{id}/status
export def "spaces-status get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace or Add a status
#
# POST /spaces/{id}/status
export def "spaces-status post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Code: string # e.g. COD
  --Comment: string # e.g. my first code
  Label: string # e.g. code 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/status")
  let body = {Code: $Code, Comment: $Comment, Label: $Label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a status of the space
#
# DELETE /spaces/{id}/status/{code}
export def "spaces-status delete" [
  id: string
  code: string
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
  let full_url = (build-url $base $"/spaces/($id)/status/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of tax contracts for the space {id}
#
# GET /spaces/{id}/tax-contracts
export def "spaces-tax-contracts get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)/tax-contracts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tax contract for the space
#
# POST /spaces/{id}/tax-contracts
export def "spaces-tax-contracts post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. ogm of the company
  Designation: string # e.g. année 2019
  --End: string # e.g. 20181231
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Start: string # e.g. 20180101
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($id)/tax-contracts")
  let body = {About: $About, Comment: $Comment, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of triggers for the space {id}
#
# GET /spaces/{id}/triggers
export def "spaces-triggers get" [
  id: string
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
  let full_url = (build-url $base $"/spaces/($id)/triggers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a trigger for the space id
#
# DELETE /spaces/{id}/triggers/{name}
export def "spaces-triggers delete" [
  id: string
  name: string
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
  let full_url = (build-url $base $"/spaces/($id)/triggers/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a trigger for the space id
#
# POST /spaces/{id}/triggers/{name}
export def "spaces-triggers post" [
  id: string
  name: string
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
  let full_url = (build-url $base $"/spaces/($id)/triggers/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a common folder
#
# DELETE /spaces/{spaceId}/common-folders/{id}
export def "spaces-common-folders delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/common-folders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a common folder
#
# PATCH /spaces/{spaceId}/common-folders/{id}
export def "spaces-common-folders patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --ArchivalDate: string # e.g. 20160203
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Name: string # e.g. Dupond
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/common-folders/($id)")
  let body = {About: $About, ArchivalDate: $ArchivalDate, Home: $Home, Keywords: $Keywords, Level: $Level, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the company entity
#
# GET /spaces/{spaceId}/company-entities/{id}/follow-ups
export def "spaces-company-entities-follow-ups get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/company-entities/($id)/follow-ups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and customer data
#
# GET /spaces/{spaceId}/customers
export def "spaces-customers get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CustomerNumber: string # CustomerNumber of the customer
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CustomerNumber" $CustomerNumber "scalar") (serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and customer data (even archived)
#
# GET /spaces/{spaceId}/customers/all
export def "spaces-customers-all get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CustomerNumber: string # CustomerNumber of the employee
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CustomerNumber" $CustomerNumber "scalar") (serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/customers/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/documents
export def "spaces-documents get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FullText: string # Text to find (e.g. durand)
  --Range: string # index range of the results (e.g. 10-19)
  --Class: string # class of the document to find (e.g. payslip)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FullText" $FullText "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "Class" $Class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a doc
#
# PATCH /spaces/{spaceId}/documents/{documentId}
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
export def "spaces-documents patch" [
  spaceId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  --Title: string # e.g. Facture décembre
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)")
  let body = {Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# read the data of a document
#
# GET /spaces/{spaceId}/documents/{documentId}/extend
export def "spaces-documents-extend get" [
  documentId: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/extend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a data to a document
#
# POST /spaces/{spaceId}/documents/{documentId}/extend
export def "spaces-documents-extend post" [
  documentId: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/extend")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns versions of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/folders
export def "spaces-documents-folders get" [
  documentId: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/folders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# send by mail a document
#
# POST /spaces/{spaceId}/documents/{documentId}/mailing
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
export def "spaces-documents-mailing post" [
  documentId: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --Name: string # e.g. Société Dupond
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/mailing")
  let body = {Address: $Address, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# returns the number of pages and the price of the pdf to send by mail
#
# GET /spaces/{spaceId}/documents/{documentId}/mailingprice
export def "spaces-documents-mailingprice get" [
  documentId: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/mailingprice")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns versions of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/versions
export def "spaces-documents-versions get" [
  documentId: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a version to a document and set it as current
#
# POST /spaces/{spaceId}/documents/{documentId}/versions
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-documents-versions post" [
  documentId: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/versions")
  let body = {Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns current version of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/versions/current
export def "spaces-documents-versions-current get" [
  documentId: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($documentId)/versions/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns accesses of one document
#
# GET /spaces/{spaceId}/documents/{id}/access
export def "spaces-documents-access get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($id)/access")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the document with the accounting property
#
# GET /spaces/{spaceId}/documents/{id}/accounting
export def "spaces-documents-accounting get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($id)/accounting")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns content of one document
#
# GET /spaces/{spaceId}/documents/{id}/download
export def "spaces-documents-download get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/documents/($id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employee data
#
# GET /spaces/{spaceId}/employees
export def "spaces-employees get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SSNumber: string # SSNumber of the employee
  --EmployeeNumber: string # EmployeeNumber of the employee
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SSNumber" $SSNumber "scalar") (serialize-qp "EmployeeNumber" $EmployeeNumber "scalar") (serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/employees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employee data (even archived)
#
# GET /spaces/{spaceId}/employees/all
export def "spaces-employees-all get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SSNumber: string # SSNumber of the employee
  --EmployeeNumber: string # EmployeeNumber of the employee
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SSNumber" $SSNumber "scalar") (serialize-qp "EmployeeNumber" $EmployeeNumber "scalar") (serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/employees/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employer data
#
# GET /spaces/{spaceId}/employers
export def "spaces-employers get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployeeNumber: string # EmployeeNumber of the employer contract
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployeeNumber" $EmployeeNumber "scalar") (serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/employers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employer data (even archived)
#
# GET /spaces/{spaceId}/employers/all
export def "spaces-employers-all get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployeeNumber: string # EmployeeNumber of the employer contract
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployeeNumber" $EmployeeNumber "scalar") (serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/employers/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# read the data of a space
#
# GET /spaces/{spaceId}/extend
export def "spaces-extend get" [
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/extend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a data to a space
#
# POST /spaces/{spaceId}/extend
export def "spaces-extend post" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/extend")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folders of the space
#
# GET /spaces/{spaceId}/folders
export def "spaces-folders get-by-spaceId" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the folder (e.g. Secrétariat juridique)
  --Keywords: string # keywords attached to the folder (e.g. juridique)
  --RootFolders: string@RootFolders-completer # only root folders (e.g. all)
  --Range: string # index range of the results (e.g. 10-19)
  --Class: string # class of the folder (e.g. social)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Keywords" $Keywords "scalar") (serialize-qp "RootFolders" $RootFolders "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "Class" $Class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders of the space (even archived)
#
# GET /spaces/{spaceId}/folders/all
export def "spaces-folders-all get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the folder (e.g. Secrétariat juridique)
  --Range: string # index range of the results (e.g. 10-19)
  --Keywords: string # keywords attached to the folder (e.g. juridique)
  --Class: string # class of the folder (e.g. social)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "Keywords" $Keywords "scalar") (serialize-qp "Class" $Class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a bank statement
#
# DELETE /spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}
export def "spaces-folders-bank-statements delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/bank-statements/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a bank statement
#
# PATCH /spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}
export def "spaces-folders-bank-statements patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Balance: float # format: number, e.g. 1352.63
  --Number: float # format: string, e.g. 10015848
  --StatementDate: string # e.g. 20160801
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/bank-statements/($documentId)")
  let body = {Balance: $Balance, Number: $Number, StatementDate: $StatementDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a contractual document
#
# DELETE /spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}
export def "spaces-folders-contractual-documents delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/contractual-documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a contractual document
#
# PATCH /spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}
export def "spaces-folders-contractual-documents patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: string # e.g. 1001.36
  --Designation: string # e.g. contrat client
  --Reference: string # e.g. 151465AFHIA
  --StartDate: string # e.g. 20181128
  --Type: string@Type-completer-2 # e.g. quotation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/contractual-documents/($documentId)")
  let body = {Amount: $Amount, Designation: $Designation, Reference: $Reference, StartDate: $StartDate, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a corporate tax declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}
export def "spaces-folders-corporate-tax-declarations delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/corporate-tax-declarations/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a coporate tax declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}
export def "spaces-folders-corporate-tax-declarations patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: float # format: float, e.g. 132.63
  --DeclarationDate: string # e.g. 20160801
  --Order: string@Order-completer # e.g. 1st advance
  --Rate: float # format: float, e.g. 10.63
  --TaxBase: float # format: float, e.g. 123.36
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/corporate-tax-declarations/($documentId)")
  let body = {Amount: $Amount, DeclarationDate: $DeclarationDate, Order: $Order, Rate: $Rate, TaxBase: $TaxBase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete an expense proof
#
# DELETE /spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}
export def "spaces-folders-expense-proofs delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/expense-proofs/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an expense report
#
# PATCH /spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}
export def "spaces-folders-expense-proofs patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Account: string@Account-completer # e.g. CAB
  --ArchivalDate: string # e.g. 20211231
  --BeforeVAT: float # e.g. 1000
  --ExpenseDate: string # e.g. 20200202
  --ExpenseReportId: string # e.g. PFOIAHF874984
  --Provider: string # e.g. G7
  --Reason: string # e.g. taxi
  --Status: string@Status-completer # e.g. R
  --VAT: float # e.g. 19.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/expense-proofs/($documentId)")
  let body = {Account: $Account, ArchivalDate: $ArchivalDate, BeforeVAT: $BeforeVAT, ExpenseDate: $ExpenseDate, ExpenseReportId: $ExpenseReportId, Provider: $Provider, Reason: $Reason, Status: $Status, VAT: $VAT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete an expense report
#
# DELETE /spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}
export def "spaces-folders-expense-reports delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/expense-reports/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an expense report
#
# PATCH /spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}
export def "spaces-folders-expense-reports patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BeforeVAT: float # e.g. 1000
  --ExpenseDate: string # e.g. 20200202
  --InclVAT: float # e.g. 1200
  --ProcessingDate: string # e.g. 20200203
  --VAT: float # e.g. 19.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/expense-reports/($documentId)")
  let body = {BeforeVAT: $BeforeVAT, ExpenseDate: $ExpenseDate, InclVAT: $InclVAT, ProcessingDate: $ProcessingDate, VAT: $VAT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete an invoice document
#
# DELETE /spaces/{spaceId}/folders/{folderId}/invoices/{documentId}
export def "spaces-folders-invoices delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/invoices/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a invoice
#
# PATCH /spaces/{spaceId}/folders/{folderId}/invoices/{documentId}
export def "spaces-folders-invoices patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BeforeVAT: float # e.g. 1000
  --DueDate: string # e.g. 20190130
  --InclVAT: float # e.g. 1200
  --InvoiceDate: string # e.g. 20200202
  --Number: string # e.g. 036459879874
  --PaymentDate: string # e.g. 20190131
  --Type: string@Type-completer-3 # e.g. commercial-invoice
  --VAT: float # e.g. 19.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/invoices/($documentId)")
  let body = {BeforeVAT: $BeforeVAT, DueDate: $DueDate, InclVAT: $InclVAT, InvoiceDate: $InvoiceDate, Number: $Number, PaymentDate: $PaymentDate, Type: $Type, VAT: $VAT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# get a nominative social declaration
#
# GET /spaces/{spaceId}/folders/{folderId}/nominative-social-declarations/{documentId}
export def "spaces-folders-nominative-social-declarations get" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/nominative-social-declarations/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a tax declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}
export def "spaces-folders-other-taxes delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/other-taxes/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an other tax declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}
export def "spaces-folders-other-taxes patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: float # format: float, e.g. 132.63
  --DeclarationDate: string # e.g. 20160801
  --Reference: string # e.g. décla CFE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/other-taxes/($documentId)")
  let body = {Amount: $Amount, DeclarationDate: $DeclarationDate, Reference: $Reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a payroll
#
# DELETE /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}
export def "spaces-folders-payrolls delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/payrolls/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a payroll
#
# PATCH /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}
export def "spaces-folders-payrolls patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Begin: string # e.g. 20160801
  --EmployeeContributions: float # format: float, e.g. 1352.63
  --EmployerContributions: float # format: float, e.g. 132.63
  --End: string # e.g. 20160831
  --NetAmount: float # format: float, e.g. 1005.63
  --TotalGrossAmount: float # format: float, e.g. 1548.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/payrolls/($documentId)")
  let body = {Begin: $Begin, EmployeeContributions: $EmployeeContributions, EmployerContributions: $EmployerContributions, End: $End, NetAmount: $NetAmount, TotalGrossAmount: $TotalGrossAmount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# recalculate a payroll
#
# POST /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}/refresh
export def "spaces-folders-payrolls-refresh post" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/payrolls/($documentId)/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a payslip
#
# DELETE /spaces/{spaceId}/folders/{folderId}/payslips/{documentId}
export def "spaces-folders-payslips delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/payslips/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a payslip
#
# PATCH /spaces/{spaceId}/folders/{folderId}/payslips/{documentId}
export def "spaces-folders-payslips patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Begin: string # e.g. 20160801
  --EmployeeContributions: float # format: float, e.g. 2000.5
  --EmployerContributions: float # format: float, e.g. 400.5
  --End: string # e.g. 20160831
  --FixedGrossAmount: float # format: float, e.g. 1352.63
  --NetAmount: float # format: float, e.g. 1005.63
  --TotalGrossAmount: float # format: float, e.g. 1548.63
  --Vacation: float # format: float, e.g. 20.5
  --VariableGrossAmount: float # format: float, e.g. 132.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/payslips/($documentId)")
  let body = {Begin: $Begin, EmployeeContributions: $EmployeeContributions, EmployerContributions: $EmployerContributions, End: $End, FixedGrossAmount: $FixedGrossAmount, NetAmount: $NetAmount, TotalGrossAmount: $TotalGrossAmount, Vacation: $Vacation, VariableGrossAmount: $VariableGrossAmount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a social contract
#
# DELETE /spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}
export def "spaces-folders-social-contracts delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/social-contracts/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a social contract
#
# PATCH /spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}
export def "spaces-folders-social-contracts patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ContractDate: string # e.g. 20190202
  --ContractDuration: string # e.g. 6 mois
  --ContractualChange: string # e.g. augmentation
  --Position: string # e.g. cadre
  --WageDevelopments: float # format: float, e.g. 1548.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/social-contracts/($documentId)")
  let body = {ContractDate: $ContractDate, ContractDuration: $ContractDuration, ContractualChange: $ContractualChange, Position: $Position, WageDevelopments: $WageDevelopments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a social declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}
export def "spaces-folders-social-declarations delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/social-declarations/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a social declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}
export def "spaces-folders-social-declarations patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: float # format: float, e.g. 132.63
  --DeclarationDate: string # e.g. 20160801
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/social-declarations/($documentId)")
  let body = {Amount: $Amount, DeclarationDate: $DeclarationDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a VAT declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}
export def "spaces-folders-vat-declarations delete" [
  spaceId: string
  folderId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/vat-declarations/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a vat declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}
export def "spaces-folders-vat-declarations patch" [
  spaceId: string
  folderId: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Begin: string # e.g. 20160801
  --CollectedVAT: float # format: float, e.g. 1548.63
  --CreditVAT: float # format: float, e.g. 400.5
  --DeductibleVAT: float # format: float, e.g. 20.5
  --End: string # e.g. 20160831
  --ExemptTurnover: float # format: float, e.g. 132.63
  --Number: string # e.g. 153126
  --PayableVAT: float # format: float, e.g. 2000.5
  --TaxableTurnover: float # format: float, e.g. 1352.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($folderId)/vat-declarations/($documentId)")
  let body = {Begin: $Begin, CollectedVAT: $CollectedVAT, CreditVAT: $CreditVAT, DeductibleVAT: $DeductibleVAT, End: $End, ExemptTurnover: $ExemptTurnover, Number: $Number, PayableVAT: $PayableVAT, TaxableTurnover: $TaxableTurnover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder with Id
#
# GET /spaces/{spaceId}/folders/{id}
export def "spaces-folders get-by-id-spaceId" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate)
#
# PATCH /spaces/{spaceId}/folders/{id}
export def "spaces-folders patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)")
  let body = {About: $About, Home: $Home, Keywords: $Keywords, Level: $Level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete an AccountingYear
#
# DELETE /spaces/{spaceId}/folders/{id}/accounting-year
export def "spaces-folders-accounting-year delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/accounting-year")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and AccountingYear data
#
# PATCH /spaces/{spaceId}/folders/{id}/accounting-year
export def "spaces-folders-accounting-year patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. ogm of the company
  --End: string # e.g. 20181231
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --NetIncome: float # e.g. 52634.36
  --NetPosition: float # e.g. 14580.36
  --Start: string # e.g. 20180101
  --Tax: float # e.g. 45698.36
  --TaxableIncome: float # e.g. 869523.36
  --Turnover: float # e.g. 1025.36
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/accounting-year")
  let body = {About: $About, Comment: $Comment, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, NetIncome: $NetIncome, NetPosition: $NetPosition, Start: $Start, Tax: $Tax, TaxableIncome: $TaxableIncome, Turnover: $Turnover} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns accountings documents of the folder (results and taxation or accountingyear)
#
# GET /spaces/{spaceId}/folders/{id}/accountings
export def "spaces-folders-accountings get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # date range of the documents (e.g. 20160321,null)
  --FolderDate: string # date range of attachment (e.g. 20180306,null)
  --Title: string # Title of the accounting document (e.g. Accounting)
  --Workbook: string # workbook of the accounting (e.g. Accounting)
  --Class: string # class of the accounting (e.g. Invoice)
  --AccountedOn: string # accountedon of the accounting (boolean available) (e.g. 20180201,null)
  --WithFolders: string # if present, the folders containing the documents are returned (e.g. yes)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "FolderDate" $FolderDate "scalar") (serialize-qp "Title" $Title "scalar") (serialize-qp "Workbook" $Workbook "scalar") (serialize-qp "Class" $Class "scalar") (serialize-qp "AccountedOn" $AccountedOn "scalar") (serialize-qp "WithFolders" $WithFolders "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/accountings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# journal of accountings document delivered to a customer
#
# GET /spaces/{spaceId}/folders/{id}/accountings-journal
export def "spaces-folders-accountings-journal get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeliveryDate: string # delivery dates of the document (e.g. 20191123082536,null)
  --AccountingDate: string # accounting dates of the document (e.g. 20170215,null)
  --Number: int # numbers of the document (e.g. 12,17)
  --Workbook: string # workbook of the document (e.g. cashwoucher)
  --YearMonth: string # yearmonth of the document (e.g. 201802)
  --Class: string # class of the document (e.g. invoice)
  --Code: string # code of the document (e.g. delivered)
  --TargetFolderName: string # Name of the target folder of the document (e.g. Exercice*)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeliveryDate" $DeliveryDate "scalar") (serialize-qp "AccountingDate" $AccountingDate "scalar") (serialize-qp "Number" $Number "scalar") (serialize-qp "Workbook" $Workbook "scalar") (serialize-qp "YearMonth" $YearMonth "scalar") (serialize-qp "Class" $Class "scalar") (serialize-qp "Code" $Code "scalar") (serialize-qp "TargetFolderName" $TargetFolderName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/accountings-journal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Bank data
#
# DELETE /spaces/{spaceId}/folders/{id}/bank
export def "spaces-folders-bank delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/bank")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and bank data
#
# GET /spaces/{spaceId}/folders/{id}/bank
export def "spaces-folders-bank get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/bank")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Bank data
#
# PATCH /spaces/{spaceId}/folders/{id}/bank
export def "spaces-folders-bank patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --ContractReference: string # e.g. 13587449420F
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/bank")
  let body = {About: $About, Comment: $Comment, ContractReference: $ContractReference, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns bank statements of the folder bank
#
# GET /spaces/{spaceId}/folders/{id}/bank-statements
export def "spaces-folders-bank-statements get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Number: string # Number of the bank statement (e.g. 201603)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Number" $Number "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/bank-statements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a bank statement in a folder bank
#
# POST /spaces/{spaceId}/folders/{id}/bank-statements
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-bank-statements post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Balance: float # format: number, e.g. 1352.63
  DocumentId: string # e.g. PBUFBAUBF1531
  --Number: float # format: string, e.g. 10015848
  StatementDate: string # e.g. 20160801
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/bank-statements")
  let body = {Balance: $Balance, DocumentId: $DocumentId, Number: $Number, StatementDate: $StatementDate, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Collective Decision data
#
# PATCH /spaces/{spaceId}/folders/{id}/collective-decision
export def "spaces-folders-collective-decision patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. ogm of the company
  --Date: string # e.g. 20180202
  --DividendDistributions: float # e.g. 1025.36
  --DividendDistributionsDate: string # e.g. 20180203
  --Event: string@Event-completer # for space type 'company' enums allowed are  'EGM','CGM','OGM','ConstituentAssembly','SolePartner','OtherEvent','Office','ExecutiveCommittee','Consulting','Board','PartnersMeeting' and for space type 'association' enums allowed are 'EGM','CGM','OGM','Other','Office','ExecutiveCommittee' (e.g. EGM)
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/collective-decision")
  let body = {About: $About, Comment: $Comment, Date: $Date, DividendDistributions: $DividendDistributions, DividendDistributionsDate: $DividendDistributionsDate, Event: $Event, Home: $Home, Keywords: $Keywords, Level: $Level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns common folders of a folder
#
# GET /spaces/{spaceId}/folders/{id}/common-folders
export def "spaces-folders-common-folders get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the folder (e.g. Folder one)
  --Keywords: string # keywords attached to the folder (e.g. juridique)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Keywords" $Keywords "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/common-folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a common folder in another folder
#
# POST /spaces/{spaceId}/folders/{id}/common-folders
export def "spaces-folders-common-folders post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --ArchivalDate: string # e.g. 20160203
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  Name: string # e.g. Dupond
  --Rights: oneof<nothing, bool> # e.g. true
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/common-folders")
  let body = {About: $About, ArchivalDate: $ArchivalDate, Home: $Home, Keywords: $Keywords, Level: $Level, Name: $Name, Rights: $Rights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns common folders (even archived) of a folder
#
# GET /spaces/{spaceId}/folders/{id}/common-folders/all
export def "spaces-folders-common-folders-all get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # Name of the folder (e.g. Folder one)
  --Keywords: string # keywords attached to the folder (e.g. juridique)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "Keywords" $Keywords "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/common-folders/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all contracting partners of a contract
#
# GET /spaces/{spaceId}/folders/{id}/contracting-partner
export def "spaces-folders-contracting-partner get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/contracting-partner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns collector space of a contract
#
# GET /spaces/{spaceId}/folders/{id}/contracting-partner/space
export def "spaces-folders-contracting-partner-space get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/contracting-partner/space")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/folders/{id}/contractual-documents
export def "spaces-folders-contractual-documents get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # date range of the documents (e.g. 20160321,null)
  --FolderDate: string # date range of attachment (e.g. 20180306,null)
  --Type: string@Type-completer-2 # Type of the document (e.g. amendment)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "FolderDate" $FolderDate "scalar") (serialize-qp "Type" $Type "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/contractual-documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/contractual-documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-contractual-documents post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: string # e.g. 1001.36
  --Designation: string # e.g. contrat client
  DocumentId: string # e.g. PBUFBAUBF1531
  --Reference: string # e.g. 151465AFHIA
  --StartDate: string # e.g. 20181128
  --Type: string@Type-completer-2 # e.g. quotation
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: any # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/contractual-documents")
  let body = {Amount: $Amount, Designation: $Designation, DocumentId: $DocumentId, Reference: $Reference, StartDate: $StartDate, Type: $Type, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder with Id and contractual-relationship data
#
# GET /spaces/{spaceId}/folders/{id}/contractual-relationship
export def "spaces-folders-contractual-relationship get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/contractual-relationship")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns corporate tax declarations
#
# GET /spaces/{spaceId}/folders/{id}/coporate-tax-declarations
export def "spaces-folders-coporate-tax-declarations get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/coporate-tax-declarations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a corporate tax declaration
#
# POST /spaces/{spaceId}/folders/{id}/coporate-tax-declarations
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-coporate-tax-declarations post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: float # format: float, e.g. 132.63
  --DeclarationDate: string # e.g. 20160801
  DocumentId: string # e.g. PBUFBAUBF1531
  --Order: string@Order-completer # e.g. 1st advance
  --Rate: float # format: float, e.g. 10.63
  --TaxBase: float # format: float, e.g. 123.36
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/coporate-tax-declarations")
  let body = {Amount: $Amount, DeclarationDate: $DeclarationDate, DocumentId: $DocumentId, Order: $Order, Rate: $Rate, TaxBase: $TaxBase, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a customer
#
# DELETE /spaces/{spaceId}/folders/{id}/customer
export def "spaces-folders-customer delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/customer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and customer data
#
# GET /spaces/{spaceId}/folders/{id}/customer
export def "spaces-folders-customer get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/customer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Customer data
#
# PATCH /spaces/{spaceId}/folders/{id}/customer
export def "spaces-folders-customer patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --CustomerNumber: string # e.g. 13587449420F
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --KeepOld: oneof<nothing, bool> # e.g. true
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --PortfolioId: string # e.g. T1OJFOAZ7449420F
  --SecondaryPortfolioId: string # e.g. T1OJFOAZ7449420F
  --Start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/customer")
  let body = {About: $About, Comment: $Comment, CustomerNumber: $CustomerNumber, Designation: $Designation, End: $End, Home: $Home, KeepOld: $KeepOld, Keywords: $Keywords, Level: $Level, PortfolioId: $PortfolioId, SecondaryPortfolioId: $SecondaryPortfolioId, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# journal of documents delivered to a customer
#
# GET /spaces/{spaceId}/folders/{id}/deliveries-journal
export def "spaces-folders-deliveries-journal get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeliveryDate: string # delivery dates of the document (e.g. 20191123082536,null)
  --AccountingDate: string # accounting dates of the document (e.g. 20170215,null)
  --Number: int # numbers of the document (e.g. 12,17)
  --Class: string # class of the document (e.g. invoice)
  --TargetFolderName: string # Name of the target folder of the document (e.g. Exercice*)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeliveryDate" $DeliveryDate "scalar") (serialize-qp "AccountingDate" $AccountingDate "scalar") (serialize-qp "Number" $Number "scalar") (serialize-qp "Class" $Class "scalar") (serialize-qp "TargetFolderName" $TargetFolderName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/deliveries-journal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/folders/{id}/documents
export def "spaces-folders-documents get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # date range of the documents (e.g. 20160321,null)
  --Title: string # Title of the document (e.g. Facture EDF)
  --FolderDate: string # date range of attachment (e.g. 20180306,null)
  --Class: string # Class of document (e.g. Contract)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Title" $Title "scalar") (serialize-qp "FolderDate" $FolderDate "scalar") (serialize-qp "Class" $Class "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-documents post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DocumentId: string # e.g. PBUFBAUBF1531
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/documents")
  let body = {DocumentId: $DocumentId, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detach a doc of a folder
#
# PATCH /spaces/{spaceId}/folders/{id}/documents/{documentId}/detach
export def "spaces-folders-documents-detach patch" [
  id: string
  spaceId: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/documents/($documentId)/detach")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Employee data
#
# DELETE /spaces/{spaceId}/folders/{id}/employee
export def "spaces-folders-employee delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/employee")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and employee data
#
# GET /spaces/{spaceId}/folders/{id}/employee
export def "spaces-folders-employee get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/employee")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Employee data
#
# PATCH /spaces/{spaceId}/folders/{id}/employee
export def "spaces-folders-employee patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --ContractType: string # e.g. 01
  --EmployeeNumber: string # e.g. 13587FAZCD420F
  --End: string # e.g. 20190101
  --Function: string # e.g. commercial
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --PostalMail: oneof<nothing, bool> # e.g. true
  --SSNumber: string # e.g. 1542012365985215
  --Start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/employee")
  let body = {About: $About, Comment: $Comment, ContractType: $ContractType, EmployeeNumber: $EmployeeNumber, End: $End, Function: $Function, Home: $Home, Keywords: $Keywords, Level: $Level, PostalMail: $PostalMail, SSNumber: $SSNumber, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns expense proofs of the folder (social, followup or exchange)
#
# GET /spaces/{spaceId}/folders/{id}/expense-proofs
export def "spaces-folders-expense-proofs get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # date range of the documents (e.g. 20160321,null)
  --FolderDate: string # date range of attachment (e.g. 20180306,null)
  --Status: string@Status-completer # Status of the expense proof (e.g. R)
  --NoExpenseReport: oneof<nothing, bool> # To return expense proofs not attached to an expense report (e.g. 1)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "FolderDate" $FolderDate "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "NoExpenseReport" $NoExpenseReport "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/expense-proofs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a expense proof in a folder followup or exchange
#
# POST /spaces/{spaceId}/folders/{id}/expense-proofs
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-expense-proofs post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Account: string@Account-completer # e.g. CAB
  --ArchivalDate: string # e.g. 20211231
  --BeforeVAT: float # e.g. 1000
  DocumentId: string # e.g. PBUFBAUBF1531
  --ExpenseDate: string # e.g. 20200202
  --ExpenseReportId: string # e.g. PFOIAHF874984
  --Provider: string # e.g. G7
  --Reason: string # e.g. taxi
  --Status: string@Status-completer # e.g. R
  --VAT: float # e.g. 19.5
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/expense-proofs")
  let body = {Account: $Account, ArchivalDate: $ArchivalDate, BeforeVAT: $BeforeVAT, DocumentId: $DocumentId, ExpenseDate: $ExpenseDate, ExpenseReportId: $ExpenseReportId, Provider: $Provider, Reason: $Reason, Status: $Status, VAT: $VAT, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns expense reports of the folder (social or followup)
#
# GET /spaces/{spaceId}/folders/{id}/expense-reports
export def "spaces-folders-expense-reports get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # date range of the documents (e.g. 20160321,null)
  --FolderDate: string # date range of attachment (e.g. 20180306,null)
  --WithExtend: string@WithExtend-completer # If present returns also the data extend (e.g. true)
  --Range: string # index range of the results (e.g. 10-19)
  --ProcessingDate: string # range of processing date (boolean available) (e.g. 20180526,null)
  --ExpenseDate: string # range of ExpenseDate (valid available) (e.g. 20180526,null)
  --SortOrder: string@SortOrder-completer # order of sort (if absent default is asc) (e.g. asc)
  --SortName: string@SortName-completer # name of value for sort (e.g. ExpenseDate)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "FolderDate" $FolderDate "scalar") (serialize-qp "WithExtend" $WithExtend "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "ProcessingDate" $ProcessingDate "scalar") (serialize-qp "ExpenseDate" $ExpenseDate "scalar") (serialize-qp "SortOrder" $SortOrder "scalar") (serialize-qp "SortName" $SortName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/expense-reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a expense report in a folder followup
#
# POST /spaces/{spaceId}/folders/{id}/expense-reports
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-expense-reports post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BeforeVAT: float # e.g. 1000
  --Date: string # e.g. 20161203
  DocumentId: string # e.g. PBUFBAUBF1531
  --ExpenseDate: string # e.g. 20200202
  --InclVAT: float # e.g. 1200
  --ProcessingDate: string # e.g. 20200203
  --VAT: float # e.g. 19.5
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/expense-reports")
  let body = {BeforeVAT: $BeforeVAT, Date: $Date, DocumentId: $DocumentId, ExpenseDate: $ExpenseDate, InclVAT: $InclVAT, ProcessingDate: $ProcessingDate, VAT: $VAT, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns expense proofs linked to the expenseReportId
#
# GET /spaces/{spaceId}/folders/{id}/expense-reports/{expenseReportId}/expense-proofs
export def "spaces-folders-expense-reports-expense-proofs get" [
  id: string
  spaceId: string
  expenseReportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # Date of the documents (YYYY or YYYYMM or YYYYMMDD) (e.g. 20160321)
  --Status: string@Status-completer # Status of the expense proof (e.g. R)
  --FolderDate: string # Date of upload of the document (YYYY or YYYYMM or YYYYMMDD) (e.g. 20180202000000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "FolderDate" $FolderDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/expense-reports/($expenseReportId)/expense-proofs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Insurance data
#
# DELETE /spaces/{spaceId}/folders/{id}/insurance
export def "spaces-folders-insurance delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/insurance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and insurance data
#
# GET /spaces/{spaceId}/folders/{id}/insurance
export def "spaces-folders-insurance get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/insurance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Insurance data
#
# PATCH /spaces/{spaceId}/folders/{id}/insurance
export def "spaces-folders-insurance patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --CustomerNumber: string # e.g. 13587449420F
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --PolicyNumber: string # e.g. 1358
  --Start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/insurance")
  let body = {About: $About, Comment: $Comment, CustomerNumber: $CustomerNumber, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, PolicyNumber: $PolicyNumber, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns invoices of the folder (customer, provider, accountingyear or root folders customers or providers)
#
# GET /spaces/{spaceId}/folders/{id}/invoices
export def "spaces-folders-invoices get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Title: string # Title of the documents (e.g. factrure)
  --Date: string # date range of the documents (e.g. 20160321,null)
  --Number: string # Number of the invoice (e.g. 23585)
  --InclVAT: float # amount incl. VAT (e.g. 100.50,123.69)
  --BeforeVAT: float # amount before VAT (e.g. 102.50,123.69)
  --DueDate: string # date due payment (e.g. 20201231,20211231)
  --PaymentDate: string # date of payment (boolean and valid available) (e.g. 20201201,20211201)
  --InvoiceDate: string # range date of invoice (e.g. 20201201)
  --FolderDate: string # date range of attachment (e.g. 20180306,null)
  --AccountedOn: string # value of AccountedOn (boolean available but not range) (e.g. 20220101)
  --WithExtend: string # If present returns also the data extend (e.g. 202102,null)
  --Extend: string # json object to filter extend data (e.g. [{"Name":"field1","Equals":"test"},{"Name":"field2","Start":"20180101"},{"Name":"field3","End":"20190101"}])
  --Range: string # index range of the results (e.g. 10-19)
  --SortOrder: string@SortOrder-completer # order of sort (if absent default is asc) (e.g. asc)
  --SortName: string@SortName-completer-1 # name of value for sort (e.g. PaymentDate)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Title" $Title "scalar") (serialize-qp "Date" $Date "scalar") (serialize-qp "Number" $Number "scalar") (serialize-qp "InclVAT" $InclVAT "scalar") (serialize-qp "BeforeVAT" $BeforeVAT "scalar") (serialize-qp "DueDate" $DueDate "scalar") (serialize-qp "PaymentDate" $PaymentDate "scalar") (serialize-qp "InvoiceDate" $InvoiceDate "scalar") (serialize-qp "FolderDate" $FolderDate "scalar") (serialize-qp "AccountedOn" $AccountedOn "scalar") (serialize-qp "WithExtend" $WithExtend "scalar") (serialize-qp "Extend" $Extend "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "SortOrder" $SortOrder "scalar") (serialize-qp "SortName" $SortName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a invoice in a folder of a customer or a provider
#
# POST /spaces/{spaceId}/folders/{id}/invoices
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-invoices post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BeforeVAT: float # e.g. 1000
  --Date: string # e.g. 20161203
  DocumentId: string # e.g. PBUFBAUBF1531
  --DueDate: string # e.g. 20190130
  --InclVAT: float # e.g. 1200
  --InvoiceDate: string # e.g. 20200202
  --Number: string # e.g. 036459879874
  --PaymentDate: string # e.g. 20190131
  --Type: string@Type-completer-3 # e.g. commercial-invoice
  --VAT: float # e.g. 19.5
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/invoices")
  let body = {BeforeVAT: $BeforeVAT, Date: $Date, DocumentId: $DocumentId, DueDate: $DueDate, InclVAT: $InclVAT, InvoiceDate: $InvoiceDate, Number: $Number, PaymentDate: $PaymentDate, Type: $Type, VAT: $VAT, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns legal entity of a follow up folder
#
# GET /spaces/{spaceId}/folders/{id}/legal-entity
export def "spaces-folders-legal-entity get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/legal-entity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Loan data
#
# DELETE /spaces/{spaceId}/folders/{id}/loan
export def "spaces-folders-loan delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/loan")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and loan data
#
# GET /spaces/{spaceId}/folders/{id}/loan
export def "spaces-folders-loan get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/loan")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Loan data
#
# PATCH /spaces/{spaceId}/folders/{id}/loan
export def "spaces-folders-loan patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Amount: float # format: float, e.g. 1000
  --Category: string@Category-completer # e.g. debt spreading
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. emprunt entreprise
  --DueAmount: float # format: float, e.g. 1000.6
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --MonthsNumber: float # e.g. 12
  --Rate: float # format: float, e.g. 2.5
  --Start: string # e.g. 20180630
  --TotalCost: float # format: float, e.g. 10200
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/loan")
  let body = {About: $About, Amount: $Amount, Category: $Category, Comment: $Comment, Designation: $Designation, DueAmount: $DueAmount, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, MonthsNumber: $MonthsNumber, Rate: $Rate, Start: $Start, TotalCost: $TotalCost} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns messages of the folder
#
# GET /spaces/{spaceId}/folders/{id}/messages
export def "spaces-folders-messages list" [
  spaceId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Text: string # Name of the message (e.g. *welcom*)
  --Range: string # index range of the results (e.g. 10-19)
  --MessageDate: string # date of the message (e.g. 20190202)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Text" $Text "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "MessageDate" $MessageDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write a message in the journal of a folder
#
# POST /spaces/{spaceId}/folders/{id}/messages
# --Notify shape: {How?: "std"|"mail"|"sms", MemberIds?: list}
export def "spaces-folders-messages post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Level: string@Level-completer-1 # e.g. confidential
  --MessageDate: string # e.g. 20160203
  --Notify: record # shape: {How?: "std"|"mail"|"sms", MemberIds?: list}
  Text: string # e.g. <p> hello world </p>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/messages")
  let body = {Level: $Level, MessageDate: $MessageDate, Notify: $Notify, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns message with Id
#
# GET /spaces/{spaceId}/folders/{id}/messages/{messageId}
export def "spaces-folders-messages get" [
  id: string
  spaceId: string
  messageId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/messages/($messageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Message
#
# PATCH /spaces/{spaceId}/folders/{id}/messages/{messageId}
# --Notify shape: {How?: "std"|"mail"|"sms", MemberIds?: list}
export def "spaces-folders-messages patch" [
  id: string
  spaceId: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Level: string@Level-completer-1 # e.g. confidential
  --MessageDate: string # e.g. 20160203
  --Notify: record # shape: {How?: "std"|"mail"|"sms", MemberIds?: list}
  --Text: string # e.g. <p> hello world </p>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/messages/($messageId)")
  let body = {Level: $Level, MessageDate: $MessageDate, Notify: $Notify, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns nominative social declarations of the folder social
#
# GET /spaces/{spaceId}/folders/{id}/nominative-social-declarations
export def "spaces-folders-nominative-social-declarations list" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/nominative-social-declarations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns other taxes declarations
#
# GET /spaces/{spaceId}/folders/{id}/other-taxes
export def "spaces-folders-other-taxes get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/other-taxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tax declaration
#
# POST /spaces/{spaceId}/folders/{id}/other-taxes
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-other-taxes post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: float # format: float, e.g. 132.63
  --DeclarationDate: string # e.g. 20160801
  DocumentId: string # e.g. PBUFBAUBF1531
  --Reference: string # e.g. décla CFE
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/other-taxes")
  let body = {Amount: $Amount, DeclarationDate: $DeclarationDate, DocumentId: $DocumentId, Reference: $Reference, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns identifiers/passwords of the folder
#
# GET /spaces/{spaceId}/folders/{id}/passwords
export def "spaces-folders-passwords list" [
  spaceId: string
  id: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/passwords")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write a identifier/password in aa folder
#
# POST /spaces/{spaceId}/folders/{id}/passwords
export def "spaces-folders-passwords post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # e.g. mon compte google
  Designation: string # e.g. compte google
  --Ident: string # e.g. test
  --Link: string # e.g. www.google.fr
  --Password: string # e.g. azerty
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/passwords")
  let body = {Comment: $Comment, Designation: $Designation, Ident: $Ident, Link: $Link, Password: $Password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a password
#
# DELETE /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "spaces-folders-passwords delete" [
  id: string
  spaceId: string
  passwordId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/passwords/($passwordId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns password with Id
#
# GET /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "spaces-folders-passwords get" [
  id: string
  spaceId: string
  passwordId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/passwords/($passwordId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Password
#
# PATCH /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "spaces-folders-passwords patch" [
  id: string
  spaceId: string
  passwordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # e.g. mon compte google
  --Designation: string # e.g. compte google
  --Ident: string # e.g. test
  --Link: string # e.g. www.google.fr
  --Password: string # e.g. azerty
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/passwords/($passwordId)")
  let body = {Comment: $Comment, Designation: $Designation, Ident: $Ident, Link: $Link, Password: $Password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns payrolls of the folder social
#
# GET /spaces/{spaceId}/folders/{id}/payrolls
export def "spaces-folders-payrolls get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Begin: string # begin date of the payrolls (e.g. 20160321,null)
  --End: string # end date of the payrolls (e.g. 20160321,null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Begin" $Begin "scalar") (serialize-qp "End" $End "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/payrolls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payroll in a folder social
#
# POST /spaces/{spaceId}/folders/{id}/payrolls
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-payrolls post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Begin: string # e.g. 20160801
  DocumentId: string # e.g. PBUFBAUBF1531
  --EmployeeContributions: float # format: float, e.g. 1352.63
  --EmployerContributions: float # format: float, e.g. 132.63
  --End: string # e.g. 20160831
  --NetAmount: float # format: float, e.g. 1005.63
  --TotalGrossAmount: float # format: float, e.g. 1548.63
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/payrolls")
  let body = {Begin: $Begin, DocumentId: $DocumentId, EmployeeContributions: $EmployeeContributions, EmployerContributions: $EmployerContributions, End: $End, NetAmount: $NetAmount, TotalGrossAmount: $TotalGrossAmount, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a nominative social declaration in a folder social
#
# DELETE /spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration
export def "spaces-folders-payrolls-nominative-social-declaration delete" [
  id: string
  spaceId: string
  payrollId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/payrolls/($payrollId)/nominative-social-declaration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a nominative social declaration in a folder social
#
# POST /spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-payrolls-nominative-social-declaration post" [
  id: string
  spaceId: string
  payrollId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DocumentId: string # e.g. PBUFBAUBF1531
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/payrolls/($payrollId)/nominative-social-declaration")
  let body = {DocumentId: $DocumentId, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns payslips of the folder employee
#
# GET /spaces/{spaceId}/folders/{id}/payslips
export def "spaces-folders-payslips get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/payslips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payslip in a folder employee
#
# POST /spaces/{spaceId}/folders/{id}/payslips
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-payslips post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Begin: string # e.g. 20160801
  DocumentId: string # e.g. PBUFBAUBF1531
  --EmployeeContributions: float # format: float, e.g. 2000.5
  --EmployerContributions: float # format: float, e.g. 400.5
  --End: string # e.g. 20160831
  --FixedGrossAmount: float # format: float, e.g. 1352.63
  --NetAmount: float # format: float, e.g. 1005.63
  --TotalGrossAmount: float # format: float, e.g. 1548.63
  --Vacation: float # format: float, e.g. 20.5
  --VariableGrossAmount: float # format: float, e.g. 132.63
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/payslips")
  let body = {Begin: $Begin, DocumentId: $DocumentId, EmployeeContributions: $EmployeeContributions, EmployerContributions: $EmployerContributions, End: $End, FixedGrossAmount: $FixedGrossAmount, NetAmount: $NetAmount, TotalGrossAmount: $TotalGrossAmount, Vacation: $Vacation, VariableGrossAmount: $VariableGrossAmount, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a secondary portfolio of a customer contract
#
# DELETE /spaces/{spaceId}/folders/{id}/portfolio/{portfolioId}
export def "spaces-folders-portfolio delete" [
  id: string
  spaceId: string
  portfolioId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/portfolio/($portfolioId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a Professional Vehicle
#
# DELETE /spaces/{spaceId}/folders/{id}/professional-vehicle
export def "spaces-folders-professional-vehicle delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/professional-vehicle")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Professional Vehicle data
#
# PATCH /spaces/{spaceId}/folders/{id}/professional-vehicle
export def "spaces-folders-professional-vehicle patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Brand: string # e.g. Renault
  --Comment: string # e.g. Peugeot Lyon
  --CompanyTax: oneof<nothing, bool> # e.g. true
  --DateIn: string # e.g. 20201802
  --DateOut: string # e.g. 20201802
  --Designation: string # e.g. peugeot siège
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, clio]
  --Level: string@Level-completer # e.g. confidential
  --Model: string # e.g. Clio
  --RegistrationDate: string # e.g. 20181231
  --RegistrationNumber: string # e.g. AA001AA
  --Type: string # e.g. car
  --Value: float # e.g. 1500.23
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/professional-vehicle")
  let body = {About: $About, Brand: $Brand, Comment: $Comment, CompanyTax: $CompanyTax, DateIn: $DateIn, DateOut: $DateOut, Designation: $Designation, Home: $Home, Keywords: $Keywords, Level: $Level, Model: $Model, RegistrationDate: $RegistrationDate, RegistrationNumber: $RegistrationNumber, Type: $Type, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a provider
#
# DELETE /spaces/{spaceId}/folders/{id}/provider
export def "spaces-folders-provider delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and provider data
#
# GET /spaces/{spaceId}/folders/{id}/provider
export def "spaces-folders-provider get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Provider data
#
# PATCH /spaces/{spaceId}/folders/{id}/provider
export def "spaces-folders-provider patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --ProviderNumber: string # e.g. 13587449420F
  --Start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/provider")
  let body = {About: $About, Comment: $Comment, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, ProviderNumber: $ProviderNumber, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# list of the required documents for a person
#
# GET /spaces/{spaceId}/folders/{id}/required-documents
export def "spaces-folders-required-documents get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/required-documents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the status of a requireddocument
#
# PATCH /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}
export def "spaces-folders-required-documents patch" [
  id: string
  spaceId: string
  requireddocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string@Status-completer-1 # e.g. waiting
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/required-documents/($requireddocumentid)")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a required document to a line
#
# POST /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-required-documents post" [
  id: string
  spaceId: string
  requireddocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  File: record # shape: {Content64Encoded?: string, Name?: string}
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/required-documents/($requireddocumentid)")
  let body = {File: $File} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a document from a required document
#
# DELETE /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}/documents/{documentId}
export def "spaces-folders-required-documents-documents delete" [
  id: string
  spaceId: string
  requireddocumentid: string
  documentId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/required-documents/($requireddocumentid)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns sections of the folder
#
# GET /spaces/{spaceId}/folders/{id}/sections
export def "spaces-folders-sections get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/sections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns social contracts of the folder employee
#
# GET /spaces/{spaceId}/folders/{id}/social-contracts
export def "spaces-folders-social-contracts get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-contracts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a social contract in a folder employee
#
# POST /spaces/{spaceId}/folders/{id}/social-contracts
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-social-contracts post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ContractDate: string # e.g. 20190202
  --ContractDuration: string # e.g. 6 mois
  --ContractualChange: string # e.g. augmentation
  DocumentId: string # e.g. PBUFBAUBF1531
  --Position: string # e.g. cadre
  --WageDevelopments: float # format: float, e.g. 1548.63
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-contracts")
  let body = {ContractDate: $ContractDate, ContractDuration: $ContractDuration, ContractualChange: $ContractualChange, DocumentId: $DocumentId, Position: $Position, WageDevelopments: $WageDevelopments, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns social declarations
#
# GET /spaces/{spaceId}/folders/{id}/social-declarations
export def "spaces-folders-social-declarations get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-declarations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a social declaration
#
# POST /spaces/{spaceId}/folders/{id}/social-declarations
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-social-declarations post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Amount: float # format: float, e.g. 132.63
  --DeclarationDate: string # e.g. 20160801
  DocumentId: string # e.g. PBUFBAUBF1531
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-declarations")
  let body = {Amount: $Amount, DeclarationDate: $DeclarationDate, DocumentId: $DocumentId, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a social regime
#
# DELETE /spaces/{spaceId}/folders/{id}/social-regimes
export def "spaces-folders-social-regimes delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-regimes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and social regime data
#
# GET /spaces/{spaceId}/folders/{id}/social-regimes
export def "spaces-folders-social-regimes get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-regimes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Social Regime data
#
# PATCH /spaces/{spaceId}/folders/{id}/social-regimes
export def "spaces-folders-social-regimes patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Periodicity: string@Periodicity-completer # e.g. monthly
  --Start: string # e.g. 20180630
  --Type: string@Type-completer-4 # e.g. mandatory
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/social-regimes")
  let body = {About: $About, Comment: $Comment, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, Periodicity: $Periodicity, Start: $Start, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns sum of invoices of the folder (customer, provider, accountingyear or root folders customers or providers)
#
# GET /spaces/{spaceId}/folders/{id}/sum-invoices
export def "spaces-folders-sum-invoices get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Number: string # Number of the invoice (e.g. 23585)
  --InclVat: float # amount incl. VAT (e.g. 100.50,101.50)
  --BeforeVAT: float # amount before VAT (e.g. 102.50,101.50)
  --DueDate: string # range date due payment (e.g. 20201231)
  --PaymentDate: string # range date of payment (e.g. 20201201,null)
  --InvoiceDate: string # range date of invoice (e.g. 20201201,null)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Number" $Number "scalar") (serialize-qp "InclVat" $InclVat "scalar") (serialize-qp "BeforeVAT" $BeforeVAT "scalar") (serialize-qp "DueDate" $DueDate "scalar") (serialize-qp "PaymentDate" $PaymentDate "scalar") (serialize-qp "InvoiceDate" $InvoiceDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/sum-invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and tax contract data
#
# DELETE /spaces/{spaceId}/folders/{id}/tax-contract
export def "spaces-folders-tax-contract delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/tax-contract")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Tax Contract data
#
# PATCH /spaces/{spaceId}/folders/{id}/tax-contract
export def "spaces-folders-tax-contract patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --ArchivalDate: string # e.g. 20160203
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. taxes foncières
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/tax-contract")
  let body = {About: $About, ArchivalDate: $ArchivalDate, Comment: $Comment, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns vat declarations
#
# GET /spaces/{spaceId}/folders/{id}/vat-declarations
export def "spaces-folders-vat-declarations get" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # range date of the documents (e.g. 20160321, null)
  --Range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar") (serialize-qp "Range" $Range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/vat-declarations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a vat declaration
#
# POST /spaces/{spaceId}/folders/{id}/vat-declarations
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-vat-declarations post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Begin: string # e.g. 20160801
  --CollectedVAT: float # format: float, e.g. 1548.63
  --CreditVAT: float # format: float, e.g. 400.5
  --DeductibleVAT: float # format: float, e.g. 20.5
  DocumentId: string # e.g. PBUFBAUBF1531
  End: string # e.g. 20160831
  --ExemptTurnover: float # format: float, e.g. 132.63
  --Number: string # e.g. 153126
  --PayableVAT: float # format: float, e.g. 2000.5
  --TaxableTurnover: float # format: float, e.g. 1352.63
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/vat-declarations")
  let body = {Begin: $Begin, CollectedVAT: $CollectedVAT, CreditVAT: $CreditVAT, DeductibleVAT: $DeductibleVAT, DocumentId: $DocumentId, End: $End, ExemptTurnover: $ExemptTurnover, Number: $Number, PayableVAT: $PayableVAT, TaxableTurnover: $TaxableTurnover, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete a class document
#
# DELETE /spaces/{spaceId}/folders/{id}/{documentClass}
export def "spaces-folders delete" [
  spaceId: string
  id: string
  documentClass: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/($documentClass)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns document of documentClass (without specific data) of the folder
#
# GET /spaces/{spaceId}/folders/{id}/{documentClass}
export def "spaces-folders get-by-id-spaceId-documentClass" [
  id: string
  spaceId: string
  documentClass: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/($documentClass)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/{documentClass}
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders post" [
  id: string
  spaceId: string
  documentClass: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DocumentId: string # e.g. PBUFBAUBF1531
  --Accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --Author: string # e.g. Antoine Dupond
  --Code: string # e.g. COD
  --Comment: string # e.g. my document
  --Date: string # e.g. 20161203
  File: record # shape: {Content64Encoded?: string, Name?: string}
  Title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/folders/($id)/($documentClass)")
  let body = {DocumentId: $DocumentId, Accounting: $Accounting, Author: $Author, Code: $Code, Comment: $Comment, Date: $Date, File: $File, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of bank folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/banks
export def "spaces-legal-entities-banks get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/banks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a bank
#
# POST /spaces/{spaceId}/legal-entities/{id}/banks
export def "spaces-legal-entities-banks post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --ContractReference: string # e.g. 13587449420F
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/banks")
  let body = {About: $About, Comment: $Comment, ContractReference: $ContractReference, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the banks even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/banks/all
export def "spaces-legal-entities-banks-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/banks/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all contract folders of the legal entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/contracts
export def "spaces-legal-entities-contracts get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/contracts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the others contract with legal entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/contractual-relationships
export def "spaces-legal-entities-contractual-relationships get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/contractual-relationships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the others contract with legal entity (even archived)
#
# GET /spaces/{spaceId}/legal-entities/{id}/contractual-relationships/all
export def "spaces-legal-entities-contractual-relationships-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/contractual-relationships/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the customer
#
# GET /spaces/{spaceId}/legal-entities/{id}/customers
export def "spaces-legal-entities-customers get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/customers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a customer
#
# POST /spaces/{spaceId}/legal-entities/{id}/customers
export def "spaces-legal-entities-customers post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --CustomerNumber: string # e.g. 13587449420F
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --PortfolioId: string # e.g. T1OJFOAZ7449420F
  --Start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/customers")
  let body = {About: $About, Comment: $Comment, CustomerNumber: $CustomerNumber, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, PortfolioId: $PortfolioId, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the customers (even archived)
#
# GET /spaces/{spaceId}/legal-entities/{id}/customers/all
export def "spaces-legal-entities-customers-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/customers/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of insurance folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/insurances
export def "spaces-legal-entities-insurances get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/insurances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a insurance
#
# POST /spaces/{spaceId}/legal-entities/{id}/insurances
export def "spaces-legal-entities-insurances post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --CustomerNumber: string # e.g. 13587449420F
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --PolicyNumber: string # e.g. 1358
  --Start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/insurances")
  let body = {About: $About, Comment: $Comment, CustomerNumber: $CustomerNumber, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, PolicyNumber: $PolicyNumber, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the insurances even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/insurances/all
export def "spaces-legal-entities-insurances-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/insurances/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the loan
#
# GET /spaces/{spaceId}/legal-entities/{id}/loans
export def "spaces-legal-entities-loans get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/loans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a loan
#
# POST /spaces/{spaceId}/legal-entities/{id}/loans
export def "spaces-legal-entities-loans post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Amount: float # format: float, e.g. 1000
  --Category: string@Category-completer # e.g. debt spreading
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. emprunt entreprise
  --DueAmount: float # format: float, e.g. 1000.6
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --MonthsNumber: float # e.g. 12
  --Rate: float # format: float, e.g. 2.5
  --Start: string # e.g. 20180630
  --TotalCost: float # format: float, e.g. 10200
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/loans")
  let body = {About: $About, Amount: $Amount, Category: $Category, Comment: $Comment, Designation: $Designation, DueAmount: $DueAmount, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, MonthsNumber: $MonthsNumber, Rate: $Rate, Start: $Start, TotalCost: $TotalCost} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the loans even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/loans/all
export def "spaces-legal-entities-loans-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/loans/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of providers folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/providers
export def "spaces-legal-entities-providers get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a provider
#
# POST /spaces/{spaceId}/legal-entities/{id}/providers
export def "spaces-legal-entities-providers post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --ProviderNumber: string # e.g. 13587449420F
  --Start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/providers")
  let body = {About: $About, Comment: $Comment, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, ProviderNumber: $ProviderNumber, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the providers even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/providers/all
export def "spaces-legal-entities-providers-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/providers/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of social regimes folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/social-regimes
export def "spaces-legal-entities-social-regimes get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/social-regimes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a social regime
#
# POST /spaces/{spaceId}/legal-entities/{id}/social-regimes
export def "spaces-legal-entities-social-regimes post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --Designation: string # e.g. client pièces détachées
  --End: string # e.g. 20190101
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --Periodicity: string@Periodicity-completer # e.g. monthly
  --Start: string # e.g. 20180630
  --Type: string@Type-completer-4 # e.g. mandatory
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/social-regimes")
  let body = {About: $About, Comment: $Comment, Designation: $Designation, End: $End, Home: $Home, Keywords: $Keywords, Level: $Level, Periodicity: $Periodicity, Start: $Start, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the social regimes even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/social-regimes/all
export def "spaces-legal-entities-social-regimes-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/legal-entities/($id)/social-regimes/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of all loan folders of the space
#
# GET /spaces/{spaceId}/loans
export def "spaces-loans get" [
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/loans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of all loan folders even archived of the space
#
# GET /spaces/{spaceId}/loans/all
export def "spaces-loans-all get" [
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/loans/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify the invitation of a person to collect documents
#
# PATCH /spaces/{spaceId}/persons/{id}/call-for-document
export def "spaces-persons-call-for-document patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Categories: list
  --ClientManagement: string@ClientManagement-completer
  --IsAdmin: oneof<nothing, bool> # e.g. true
  --Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20190601
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/call-for-document")
  let body = {Categories: $Categories, ClientManagement: $ClientManagement, IsAdmin: $IsAdmin, Player: $Player, PlayerEnd: $PlayerEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# invite a person to collect documents
#
# POST /spaces/{spaceId}/persons/{id}/call-for-document
export def "spaces-persons-call-for-document post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Categories: list # e.g. [ID, Invoices]
  --ClientManagement: string@ClientManagement-completer
  --Comment: string # e.g. first invitation
  --Contact: string # e.g. Dupond
  --IsAdmin: oneof<nothing, bool> # e.g. true
  --Message: string # e.g. <p> Bienvenue dans l'espace de l'entreprise SOCIETE </p>
  --Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20190601
  --Signature: string # e.g. cordialement
  --Subject: string # e.g. invitation sur le coffre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/call-for-document")
  let body = {Categories: $Categories, ClientManagement: $ClientManagement, Comment: $Comment, Contact: $Contact, IsAdmin: $IsAdmin, Message: $Message, Player: $Player, PlayerEnd: $PlayerEnd, Signature: $Signature, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of the employee
#
# GET /spaces/{spaceId}/persons/{id}/employees
export def "spaces-persons-employees get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/employees")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a employee
#
# POST /spaces/{spaceId}/persons/{id}/employees
export def "spaces-persons-employees post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --About: string # e.g. <b> Mon premier dossier </b>
  --Comment: string # e.g. pieces company
  --ContractType: string # e.g. 01
  --EmployeeNumber: string # e.g. 13587FAZCD420F
  --End: string # e.g. 20190101
  --Function: string # e.g. commercial
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
  --PostalMail: oneof<nothing, bool> # e.g. true
  --SSNumber: string # e.g. 1542012365985215
  --Start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/employees")
  let body = {About: $About, Comment: $Comment, ContractType: $ContractType, EmployeeNumber: $EmployeeNumber, End: $End, Function: $Function, Home: $Home, Keywords: $Keywords, Level: $Level, PostalMail: $PostalMail, SSNumber: $SSNumber, Start: $Start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder of all employees (even archived)
#
# GET /spaces/{spaceId}/persons/{id}/employees/all
export def "spaces-persons-employees-all get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/employees/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder exchange of the person
#
# GET /spaces/{spaceId}/persons/{id}/exchange
export def "spaces-persons-exchange get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/exchange")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the person
#
# GET /spaces/{spaceId}/persons/{id}/follow-ups
export def "spaces-persons-follow-ups get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/follow-ups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete the invitation of a person in a space
#
# DELETE /spaces/{spaceId}/persons/{id}/guest-in-space
export def "spaces-persons-guest-in-space delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/guest-in-space")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invite a person in a space
#
# PATCH /spaces/{spaceId}/persons/{id}/guest-in-space
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-guest-in-space patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientManagement: string@ClientManagement-completer
  --Folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --GroupIds: list
  --IsAdmin: oneof<nothing, bool> # e.g. true
  --Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20190601
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/guest-in-space")
  let body = {ClientManagement: $ClientManagement, Folders: $Folders, GroupIds: $GroupIds, IsAdmin: $IsAdmin, Player: $Player, PlayerEnd: $PlayerEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# invite a person in a space
#
# POST /spaces/{spaceId}/persons/{id}/guest-in-space
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-guest-in-space post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientManagement: string@ClientManagement-completer
  --Comment: string # e.g. first invitation
  --Contact: string # e.g. Dupond
  --Folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --GroupIds: list
  --IsAdmin: oneof<nothing, bool> # e.g. true
  --MemberId: string # e.g. PAIHIHFA79TFA
  --Message: string # e.g. <p> Bienvenue dans l'espace de l'entreprise SOCIETE </p>
  --Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20190601
  --Signature: string # e.g. cordialement
  --Subject: string # e.g. invitation sur le coffre
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/guest-in-space")
  let body = {ClientManagement: $ClientManagement, Comment: $Comment, Contact: $Contact, Folders: $Folders, GroupIds: $GroupIds, IsAdmin: $IsAdmin, MemberId: $MemberId, Message: $Message, Player: $Player, PlayerEnd: $PlayerEnd, Signature: $Signature, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete the invitation of a person in a space
#
# DELETE /spaces/{spaceId}/persons/{id}/invitation
export def "spaces-persons-invitation delete" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/invitation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns invitation of a person
#
# GET /spaces/{spaceId}/persons/{id}/invitation
export def "spaces-persons-invitation get" [
  id: string
  spaceId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/invitation")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an invitation
#
# PATCH /spaces/{spaceId}/persons/{id}/invitation
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-invitation patch" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientManagement: string@ClientManagement-completer
  --EmployeeAccess: oneof<nothing, bool> # e.g. true
  --Folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --GroupIds: list
  --IsAdmin: oneof<nothing, bool> # e.g. true
  --Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20190601
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/invitation")
  let body = {ClientManagement: $ClientManagement, EmployeeAccess: $EmployeeAccess, Folders: $Folders, GroupIds: $GroupIds, IsAdmin: $IsAdmin, Player: $Player, PlayerEnd: $PlayerEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# create an invitation in a space for a person
#
# POST /spaces/{spaceId}/persons/{id}/invitation
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-invitation post" [
  id: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClientManagement: string@ClientManagement-completer
  --EmployeeAccess: oneof<nothing, bool> # e.g. true
  --Folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --GroupIds: list
  --IsAdmin: oneof<nothing, bool> # e.g. true
  --Player: string@Player-completer # e.g. guest
  --PlayerEnd: string # e.g. 20190601
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/invitation")
  let body = {ClientManagement: $ClientManagement, EmployeeAccess: $EmployeeAccess, Folders: $Folders, GroupIds: $GroupIds, IsAdmin: $IsAdmin, Player: $Player, PlayerEnd: $PlayerEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# send the invitation of a person in a space
#
# POST /spaces/{spaceId}/persons/{id}/invitation/{invitationId}/send
export def "spaces-persons-invitation-send post" [
  id: string
  invitationId: string
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Contact: string # e.g. Dupond
  --Message: string # e.g. <p> Bienvenue dans l'espace de l'envtreprise SOCIETE </p>
  --Signature: string # e.g. cordialement
  --Subject: string # e.g. invitation sur le coffre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($id)/invitation/($invitationId)/send")
  let body = {Contact: $Contact, Message: $Message, Signature: $Signature, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folderId with the access of the person
#
# GET /spaces/{spaceId}/persons/{memberId}/folders/{id}
export def "spaces-persons-folders get" [
  id: string
  spaceId: string
  memberId: string
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
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($memberId)/folders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an access
#
# PATCH /spaces/{spaceId}/persons/{memberId}/folders/{id}
export def "spaces-persons-folders patch" [
  id: string
  spaceId: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Right: string@Right-completer-1 # e.g. write
  --About: string # e.g. <b> Mon premier dossier </b>
  --Home: oneof<nothing, bool> # e.g. yes
  --Keywords: list # e.g. [paris, comptabilité]
  --Level: string@Level-completer # e.g. confidential
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/spaces/($spaceId)/persons/($memberId)/folders/($id)")
  let body = {Right: $Right, About: $About, Home: $Home, Keywords: $Keywords, Level: $Level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns folder with Id and provider data
#
# GET /spaces/{spaceId}/providers
export def "spaces-providers get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and provider data (even archived)
#
# GET /spaces/{spaceId}/providers/all
export def "spaces-providers-all get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/providers/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Research text inside documents, folders or messages
#
# GET /spaces/{spaceId}/search
export def "spaces-search get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Query: string # Text to find (e.g. durand)
  --Range: string # index range of the results (e.g. 10-19)
  --QueryContext: record # context of research
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Query" $Query "scalar") (serialize-qp "Range" $Range "scalar") (serialize-qp "QueryContext" $QueryContext "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and social regime data
#
# GET /spaces/{spaceId}/social-regimes
export def "spaces-social-regimes get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/social-regimes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and social regime data (even archived)
#
# GET /spaces/{spaceId}/social-regimes/all
export def "spaces-social-regimes-all get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --WithContractingPartner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $WithContractingPartner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/social-regimes/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns CSV Invoicings of the spaces for the account of the spaceId
#
# GET /spaces/{spaceId}/spaces-invoicings
export def "spaces-spaces-invoicings get" [
  spaceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # date range of the documents (e.g. 20160321,null)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $Date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/spaces/($spaceId)/spaces-invoicings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
