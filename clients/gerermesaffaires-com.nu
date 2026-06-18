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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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
def type-completer [] { ["association" "company" "enterprise" "private"] }
def groups-completer [] { ["legal" "tax" "wealth management"] }
def role-completer [] { ["collaborator" "manager"] }
def type-completer-1 [] { ["association" "company" "enterprise"] }
def sex-completer [] { ["female" "male"] }
def level-completer [] { ["confidential" "public" "regular"] }
def has-company-registration-certificate-completer [] { ["false" "true"] }
def has-status-completer [] { ["false" "true"] }
def has-sirene-register-completer [] { ["false" "true"] }
def has-minutes-completer [] { ["false" "true"] }
def event-completer [] { ["Board" "CGM" "ConstituentAssembly" "Consulting" "EGM" "ExecutiveCommittee" "OGM" "Office" "Other" "OtherEvent" "PartnersMeeting" "SolePartner"] }
def accept-completer [] { ["application/json" "multipart/form-data"] }
def groups-completer-1 [] { ["accounting" "legal" "purchases" "sales" "social" "social manager" "tax" "wealth management"] }
def role-completer-1 [] { ["assistant" "collaborator" "empty"] }
def right-completer [] { ["read" "write"] }
def validated-completer [] { ["false" "true"] }
def client-management-completer [] { ["adn" "manager" "no"] }
def player-completer [] { ["assistant" "collaborator" "guest" "manager" "owner"] }
def root-folders-completer [] { ["all"] }
def type-completer-2 [] { ["amendment" "contract" "delivery-order" "engagement-letter" "other" "purchase-order" "quotation"] }
def order-completer [] { ["1st advance" "2nd advance" "3rd advance" "4th advance" "regularization"] }
def account-completer [] { ["CAB" "DIV" "FHR" "IKM" "PRK" "PTT" "RES" "TXI" "VOY"] }
def status-completer [] { ["R" "V" "W"] }
def type-completer-3 [] { ["amending-invoice" "commercial-invoice" "credit-note" "credit-self-billing" "down-payment-invoice" "informations-invoice" "self-billing"] }
def with-extend-completer [] { ["false" "true"] }
def sort-order-completer [] { ["asc" "desc"] }
def sort-name-completer [] { ["ExpenseDate" "InclVAT" "Title"] }
def sort-name-completer-1 [] { ["Contracting" "DueDate" "InclVAT" "InvoiceDate" "PaymentDate" "Title"] }
def category-completer [] { ["bank loan" "current account" "debt spreading" "leasing" "obligation" "overdraft agreement"] }
def level-completer-1 [] { ["confidential" "regular"] }
def status-completer-1 [] { ["ended" "validated" "waiting"] }
def periodicity-completer [] { ["annual" "half-yearly" "monthly" "null" "quarterly"] }
def type-completer-4 [] { ["mandatory" "null" "optional"] }
def right-completer-1 [] { ["none" "read" "write"] }

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
  --name: string # Name of the group (e.g. Dupond)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modifies an object
#
# PATCH /business-groups
export def "business-groups update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # e.g. Client Durand
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-groups")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a group (only for managers and ADN collaborators)
#
# POST /business-groups
export def "business-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # e.g. Client Durand
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-groups")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the group
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar")] | flatten | str join "&"
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/business-groups/{id}"))
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
  --name: string # Name of the space (e.g. Mon Entreprise)
  --type: string@type-completer # Type of the space (e.g. private)
  --registration-number: string # registration number of the space (e.g. 12345)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Type" $type "scalar") (serialize-qp "RegistrationNumber" $registration_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/business-groups/{id}/spaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a customer space from partner
#
# DELETE /business-groups/{id}/spaces/{spaceId}
export def "business-groups-spaces delete" [
  id: string
  space_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), space_id: (encode-path-segment $space_id)} | format pattern "/business-groups/{id}/spaces/{space_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# send an invitation to manager the private space of personId
#
# POST /business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/guest-in-space
export def "business-groups-spaces-legal-entities-customers-guest-in-space create" [
  id: string
  space_id: string
  person_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>@groups-completer # e.g. [tax, legal]
  role: string@role-completer # e.g. collaborator
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), space_id: (encode-path-segment $space_id), person_id: (encode-path-segment $person_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/business-groups/{id}/spaces/{space_id}/legal-entities/{person_id}/customers/{folder_id}/guest-in-space"))
  let req_body = {"Groups": $groups, "Role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add a Space in a group
#
# POST /business-groups/{id}/spaces/{spaceId}/legal-entities/{personId}/customers/{folderId}/spaces
# --Logo shape: {Content64Encoded?: string, Name?: string}
export def "business-groups-spaces-legal-entities-customers-spaces create" [
  id: string
  space_id: string
  person_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: record # shape: {Content64Encoded?: string, Name?: string}
  --name: string # e.g. Mon Entreprise
  --template-space-id: string # e.g. PKOJOFOFKAOKF
  type: string@type-completer-1 # e.g. company
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), space_id: (encode-path-segment $space_id), person_id: (encode-path-segment $person_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/business-groups/{id}/spaces/{space_id}/legal-entities/{person_id}/customers/{folder_id}/spaces"))
  let req_body = {"Logo": $logo, "Name": $name, "TemplateSpaceId": $template_space_id, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns predefined folders and workbooks of the Hub for all the spaces of the business group
#
# GET /hub/business-groups/{Id}/menus
export def "hub-business-groups-menus get" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/hub/business-groups/{id}/menus"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document (this document is analyzed to be saved in the correct folder and correct space)
#
# POST /hub/documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --add-contract-allowed: oneof<nothing, bool> # e.g. true
  --author: string # e.g. Antoine Dupond
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hub/documents")
  let req_body = {"Accounting": $accounting, "AddContractAllowed": $add_contract_allowed, "Author": $author, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
export def "hub-payslips create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --add-contract-allowed: oneof<nothing, bool> # e.g. true
  --author: string # e.g. Antoine Dupond
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hub/payslips")
  let req_body = {"Accounting": $accounting, "AddContractAllowed": $add_contract_allowed, "Author": $author, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add a document in a space (this document is analyzed to be saved in the correct folder)
#
# POST /hub/spaces/{spaceId}/documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-spaces-documents create" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/hub/spaces/{space_id}/documents"))
  let req_body = {"Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns predefined folders and workbooks of the Hub for the space
#
# GET /hub/spaces/{spaceId}/menus
export def "hub-spaces-menus get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/hub/spaces/{space_id}/menus"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payslip in a space (this document is analyzed to be saved in the correct folder)
#
# POST /hub/spaces/{spaceId}/payslips
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "hub-spaces-payslips create" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/hub/spaces/{space_id}/payslips"))
  let req_body = {"Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
export def "menus-documents create" [
  menu_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: string # e.g. Antoine Dupond
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Report: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({menu_id: (encode-path-segment $menu_id)} | format pattern "/menus/{menu_id}/documents"))
  let req_body = {"Author": $author, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --contract: string # to get a contract (if not signed error 404 + html contract) (e.g. member)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Contract" $contract "scalar")] | flatten | str join "&"
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
export def "profile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --birth: record # shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
  --birth-name: string # e.g. Dupond
  --email: string # e.g. paule@durand.fr
  --first-name: string # e.g. Paule
  --id-file: record # shape: {Content64Encoded?: string, Name?: string}
  --name: string # e.g. Durand
  --sex: string@sex-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let req_body = {"Birth": $birth, "BirthName": $birth_name, "Email": $email, "FirstName": $first_name, "IDFile": $id_file, "Name": $name, "Sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# create infos of profile
#
# POST /profile
# --Birth shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
# --IDFile shape: {Content64Encoded?: string, Name?: string}
export def "profile create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  birth: record # shape: {City?: string, Country?: string, Date?: string, ZipCode?: string}
  birth_name: string # e.g. Dupond
  email: string # e.g. paule@durand.fr
  first_name: string # e.g. Paule
  --id-file: record # shape: {Content64Encoded?: string, Name?: string}
  name: string # e.g. Durand
  sex: string@sex-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let req_body = {"Birth": $birth, "BirthName": $birth_name, "Email": $email, "FirstName": $first_name, "IDFile": $id_file, "Name": $name, "Sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# modify email of profile
#
# PATCH /profile/email
export def "profile-email update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. paule@durand.fr
  --email-code: string # e.g. 1256
  --sms-code: string # e.g. FAHF
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/email")
  let req_body = {"Email": $email, "EmailCode": $email_code, "SMSCode": $sms_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --contract: string # to get a contract (if not signed error 404 + html contract) (e.g. member)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Contract" $contract "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profile/id-file" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify mobile of profile
#
# PATCH /profile/mobile
export def "profile-mobile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mobile: string # e.g. 33606060606
  --password: string # e.g. azerty
  --sms-code: string # e.g. FAHF
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/mobile")
  let req_body = {"Mobile": $mobile, "Password": $password, "SMSCode": $sms_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --code: string # Code of the invitation (e.g. HFIHA)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# complete the invitation
#
# POST /registration
export def "registration create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # e.g. OJFOA
  --secret: string # e.g. 123456
]: any -> record<Private: record<FolderId: string, SpaceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registration")
  let req_body = {"Code": $code, "Secret": $secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the space (e.g. Mon Entreprise)
  --type: string@type-completer # Type of the space (e.g. private)
  --registration-number: string # registration number of the space (e.g. 12345)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Type" $type "scalar") (serialize-qp "RegistrationNumber" $registration_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Space in my group
#
# POST /spaces
# --Logo shape: {Content64Encoded?: string, Name?: string}
export def "spaces create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legal-statut: string # e.g. SA
  --logo: record # shape: {Content64Encoded?: string, Name?: string}
  name: string # e.g. Mon Entreprise
  --registration-number: string # e.g. 5146486846
  --template-space-id: string # e.g. PKOJOFOFKAOKF
  type: string@type-completer-1 # e.g. company
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spaces")
  let req_body = {"LegalStatut": $legal_statut, "Logo": $logo, "Name": $name, "RegistrationNumber": $registration_number, "TemplateSpaceId": $template_space_id, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the space (e.g. Mon Entreprise)
  --type: string@type-completer # Type of the space (e.g. private)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Type" $type "scalar")] | flatten | str join "&"
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}"))
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Space (except private)
#
# PATCH /spaces/{id}
# --Logo shape: {Content64Encoded?: string, Name?: string}
export def "spaces update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: record # shape: {Content64Encoded?: string, Name?: string}
  --name: string # e.g. Mon Entreprise
  --template-space-id: string # e.g. PHAOH8486
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}"))
  let req_body = {"Logo": $logo, "Name": $name, "TemplateSpaceId": $template_space_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --end: string # End date of the accounting year (YYYYMM or YYYYMMDD) (range not available) (e.g. 201603)
  --effective-date: string # Effective date inside the accounting year (range not available) (e.g. 20160301)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "End" $end "scalar") (serialize-qp "EffectiveDate" $effective_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/accounting-year") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a accounting year for the space id
#
# POST /spaces/{id}/accounting-year
export def "spaces-accounting-year create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  end: string # e.g. 20181231
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --net-income: float # e.g. 52634.36
  --net-position: float # e.g. 14580.36
  --start: string # e.g. 20180101
  --tax: float # e.g. 45698.36
  --taxable-income: float # e.g. 869523.36
  --turnover: float # e.g. 1025.36
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/accounting-year"))
  let req_body = {"About": $about, "Comment": $comment, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "NetIncome": $net_income, "NetPosition": $net_position, "Start": $start, "Tax": $tax, "TaxableIncome": $taxable_income, "Turnover": $turnover} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --date: string # Date of the collective decision YYYMMDD (e.g. 20160302,null)
  --event: string # Event of the collective decision (see post for the list of events) (e.g. OGM)
  --range: string # index range of the results (e.g. 10-19)
  --has-company-registration-certificate: string@has-company-registration-certificate-completer # If true returns only invoices with a CompanyRegistrationCertificate (e.g. true)
  --has-status: string@has-status-completer # If true returns only invoices with a Status (e.g. true)
  --has-sirene-register: string@has-sirene-register-completer # If true returns only invoices with a SireneRegister (e.g. true)
  --has-minutes: string@has-minutes-completer # If true returns only invoices with Minutes (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Event" $event "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "HasCompanyRegistrationCertificate" $has_company_registration_certificate "scalar") (serialize-qp "HasStatus" $has_status "scalar") (serialize-qp "HasSireneRegister" $has_sirene_register "scalar") (serialize-qp "HasMinutes" $has_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/collective-decision") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a colletive decision for the space id
#
# POST /spaces/{id}/collective-decision
export def "spaces-collective-decision create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  date: string # e.g. 20180202
  --dividend-distributions: float # e.g. 1025.36
  --dividend-distributions-date: string # e.g. 20180203
  event: string@event-completer # for space type 'company' enums allowed are 'EGM','CGM','OGM','ConstituentAssembly','SolePartner','OtherEvent','Office','ExecutiveCommittee','Consulting','Board','PartnersMeeting' and for space type 'association' enums allowed are 'EGM','CGM','OGM','Other','Office','ExecutiveCommittee' (e.g. EGM)
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/collective-decision"))
  let req_body = {"About": $about, "Comment": $comment, "Date": $date, "DividendDistributions": $dividend_distributions, "DividendDistributionsDate": $dividend_distributions_date, "Event": $event, "Home": $home, "Keywords": $keywords, "Level": $level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the company entity (e.g. Source de France)
  --legal-name: string # Legal name of the company entity (e.g. Source de France SAS)
  --registration-number: string # registration number of the company entity (e.g. 12356213854)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "LegalName" $legal_name "scalar") (serialize-qp "RegistrationNumber" $registration_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/company-entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Company Entity in a Space
#
# POST /spaces/{id}/company-entities
export def "spaces-company-entities create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ape-code: string # e.g. 420F
  --archival-date: string # e.g. 20160203
  --comment: string # e.g. my brother
  legal_name: string # e.g. Mon entreprise Dupond
  --legal-statut: string # e.g. SAS
  name: string # e.g. Dupond
  --registration-number: string # e.g. 236542158
  --type: string # e.g. EPT
  --vat-number: string # e.g. 46546847864
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/company-entities"))
  let req_body = {"ApeCode": $ape_code, "ArchivalDate": $archival_date, "Comment": $comment, "LegalName": $legal_name, "LegalStatut": $legal_statut, "Name": $name, "RegistrationNumber": $registration_number, "Type": $type, "VatNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the company entity (e.g. Source de France)
  --registration-number: string # registration number of the company entity (e.g. 12356213854)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "RegistrationNumber" $registration_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/company-entities/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a compay entity
#
# GET /spaces/{id}/company-entities/{companyId}
export def "spaces-company-entities get" [
  id: string
  company_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), company_id: (encode-path-segment $company_id)} | format pattern "/spaces/{id}/company-entities/{company_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a company entity
#
# PATCH /spaces/{id}/company-entities/{companyId}
export def "spaces-company-entities update" [
  id: string
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ape-code: string # e.g. 420F
  --archival-date: string # e.g. 20160203
  --comment: string # e.g. my brother
  --legal-name: string # e.g. Mon entreprise Dupond
  --legal-statut: string # e.g. SAS
  --name: string # e.g. Dupond
  --registration-number: string # e.g. 236542158
  --type: string # e.g. EPT
  --vat-number: string # e.g. 46546847864
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), company_id: (encode-path-segment $company_id)} | format pattern "/spaces/{id}/company-entities/{company_id}"))
  let req_body = {"ApeCode": $ape_code, "ArchivalDate": $archival_date, "Comment": $comment, "LegalName": $legal_name, "LegalStatut": $legal_statut, "Name": $name, "RegistrationNumber": $registration_number, "Type": $type, "VatNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all details of a company entity
#
# GET /spaces/{id}/company-entities/{personId}/details
export def "spaces-company-entities-details get" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/company-entities/{person_id}/details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace or Add a contact detail for a person
#
# POST /spaces/{id}/company-entities/{personId}/details
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
export def "spaces-company-entities-details create" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  designation: string # e.g. Office
  --email: list<string>
  --phone: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/company-entities/{person_id}/details"))
  let req_body = {"Address": $address, "Designation": $designation, "Email": $email, "Phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a contact detail for a company entity
#
# DELETE /spaces/{id}/company-entities/{personId}/details/{designation}
export def "spaces-company-entities-details delete" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id), designation: (encode-path-segment $designation)} | format pattern "/spaces/{id}/company-entities/{person_id}/details/{designation}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create an archive with documents
#
# POST /spaces/{id}/documents/download
export def "spaces-documents-download create" [
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
  document_id: list<string>
]: any -> record<ZipFile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/documents/download"))
  let req_body = {"DocumentId": $document_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# return the access of a person in a customer contract
#
# GET /spaces/{id}/folders/{folderId}/persons/{memberId}
export def "spaces-folders-persons get" [
  id: string
  folder_id: string
  member_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), folder_id: (encode-path-segment $folder_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/folders/{folder_id}/persons/{member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/Modify/Delete a person in a customer contract (except manager)
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}
export def "spaces-folders-persons update" [
  id: string
  folder_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>@groups-completer-1 # e.g. [social, legal]
  --is-admin: oneof<nothing, bool> # e.g. false
  --role: string@role-completer-1 # e.g. collaborator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), folder_id: (encode-path-segment $folder_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/folders/{folder_id}/persons/{member_id}"))
  let req_body = {"Groups": $groups, "IsAdmin": $is_admin, "Role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# open an access
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}/activeaccess
export def "spaces-folders-persons-activeaccess update" [
  id: string
  folder_id: string
  member_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), folder_id: (encode-path-segment $folder_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/folders/{folder_id}/persons/{member_id}/activeaccess"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# close an access
#
# PATCH /spaces/{id}/folders/{folderId}/persons/{memberId}/unactiveaccess
export def "spaces-folders-persons-unactiveaccess update" [
  id: string
  folder_id: string
  member_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), folder_id: (encode-path-segment $folder_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/folders/{folder_id}/persons/{member_id}/unactiveaccess"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invite a owner in a space
#
# POST /spaces/{id}/folders/{folderId}/persons/{personId}/guest-in-space
export def "spaces-folders-persons-guest-in-space create" [
  id: string
  folder_id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-person-id: string # e.g. PAIHIHFA79TFA
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), folder_id: (encode-path-segment $folder_id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/folders/{folder_id}/persons/{person_id}/guest-in-space"))
  let req_body = {"PersonId": $body_person_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the groups (e.g. RH)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a group in a Space
#
# POST /spaces/{id}/groups
export def "spaces-groups create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # e.g. 20160203
  name: string # e.g. RH
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/groups"))
  let req_body = {"EndDate": $end_date, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the group (e.g. RH)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/groups/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a group
#
# GET /spaces/{id}/groups/{groupId}
export def "spaces-groups get" [
  id: string
  group_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), group_id: (encode-path-segment $group_id)} | format pattern "/spaces/{id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a group
#
# PATCH /spaces/{id}/groups/{groupId}
export def "spaces-groups update" [
  id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # e.g. 20160203
  --name: string # e.g. RH
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), group_id: (encode-path-segment $group_id)} | format pattern "/spaces/{id}/groups/{group_id}"))
  let req_body = {"EndDate": $end_date, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete access to a folder for a group
#
# DELETE /spaces/{id}/groups/{groupId}/folders/{folderId}
export def "spaces-groups-folders delete" [
  id: string
  group_id: string
  folder_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), group_id: (encode-path-segment $group_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/spaces/{id}/groups/{group_id}/folders/{folder_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add access to a folder for a group
#
# PATCH /spaces/{id}/groups/{groupId}/folders/{folderId}
export def "spaces-groups-folders update" [
  id: string
  group_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  right: string@right-completer # e.g. read
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), group_id: (encode-path-segment $group_id), folder_id: (encode-path-segment $folder_id)} | format pattern "/spaces/{id}/groups/{group_id}/folders/{folder_id}"))
  let req_body = {"Right": $right} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a person of a group
#
# DELETE /spaces/{id}/groups/{groupId}/persons/{memberId}
export def "spaces-groups-persons delete" [
  id: string
  group_id: string
  member_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), group_id: (encode-path-segment $group_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/groups/{group_id}/persons/{member_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a person to a group
#
# PATCH /spaces/{id}/groups/{groupId}/persons/{memberId}
export def "spaces-groups-persons update" [
  id: string
  group_id: string
  member_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), group_id: (encode-path-segment $group_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/groups/{group_id}/persons/{member_id}"))
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/legal"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify legal information of a Space (except private)
#
# PATCH /spaces/{id}/legal
export def "spaces-legal update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identification-number: string # e.g. 548
  --registration-date: string # e.g. 20190325
  --registration-number: string # e.g. 123456
  --vat-number: string # e.g. 123
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/legal"))
  let req_body = {"IdentificationNumber": $identification_number, "RegistrationDate": $registration_date, "RegistrationNumber": $registration_number, "VATNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/logo"))
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
  --function: string # Function of the person (e.g. employee)
  --range: string # index range of the results (e.g. 10-19)
  --name: string # Name of the person (e.g. Germain)
  --validated: string@validated-completer # Status of the person (e.g. true)
  --email: string # Email of the person (e.g. maxgermain@maxgermain.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Function" $function "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "Name" $name "scalar") (serialize-qp "Validated" $validated "scalar") (serialize-qp "Email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/persons") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Person in a Space
#
# POST /spaces/{id}/persons
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
# --Birth shape: {Date?: int, Place?: string}
export def "spaces-persons create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --archival-date: string # e.g. 20160203
  --birth: record # shape: {Date?: int, Place?: string}
  --comment: string # e.g. my brother
  --email: string # e.g. bertrand@monmail.com
  first_name: string # e.g. Bertrand
  --mobile: string # e.g. +33606060606
  name: string # e.g. Dupond
  sex: string@sex-completer # e.g. male
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/persons"))
  let req_body = {"Address": $address, "ArchivalDate": $archival_date, "Birth": $birth, "Comment": $comment, "Email": $email, "FirstName": $first_name, "Mobile": $mobile, "Name": $name, "Sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --name: string # Name of the person (e.g. Germain)
  --function: string # Function of the person (e.g. employee)
  --range: string # index range of the results (e.g. 10-19)
  --validated: string@validated-completer # Status of the person (e.g. true)
  --email: string # Email of the person (e.g. maxgermain@maxgermain.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Function" $function "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "Validated" $validated "scalar") (serialize-qp "Email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/persons/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the role of a person
#
# PATCH /spaces/{id}/persons/{memberId}/player
export def "spaces-persons-player update" [
  id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-management: string@client-management-completer
  --is-admin: oneof<nothing, bool> # e.g. true
  player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20210203
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/persons/{member_id}/player"))
  let req_body = {"ClientManagement": $client_management, "IsAdmin": $is_admin, "Player": $player, "PlayerEnd": $player_end} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a person
#
# DELETE /spaces/{id}/persons/{personId}
export def "spaces-persons delete" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a person
#
# GET /spaces/{id}/persons/{personId}
export def "spaces-persons get" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a person
#
# PATCH /spaces/{id}/persons/{personId}
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
# --Birth shape: {Date?: int, Place?: string}
export def "spaces-persons update" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --archival-date: string # e.g. 20160203
  --birth: record # shape: {Date?: int, Place?: string}
  --comment: string # e.g. my brother
  --email: string # e.g. bertrand@monmail.com
  --first-name: string # e.g. Bertrand
  --mobile: string # e.g. +33606060606
  --name: string # e.g. Dupond
  --sex: string@sex-completer # e.g. male
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}"))
  let req_body = {"Address": $address, "ArchivalDate": $archival_date, "Birth": $birth, "Comment": $comment, "Email": $email, "FirstName": $first_name, "Mobile": $mobile, "Name": $name, "Sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all details of a person
#
# GET /spaces/{id}/persons/{personId}/details
export def "spaces-persons-details get" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}/details"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace or Add a contact detail for a person
#
# POST /spaces/{id}/persons/{personId}/details
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
export def "spaces-persons-details create" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  designation: string # e.g. Office
  --email: list<string>
  --phone: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}/details"))
  let req_body = {"Address": $address, "Designation": $designation, "Email": $email, "Phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a contact detail for a person
#
# DELETE /spaces/{id}/persons/{personId}/details/{designation}
export def "spaces-persons-details delete" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id), designation: (encode-path-segment $designation)} | format pattern "/spaces/{id}/persons/{person_id}/details/{designation}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of folders with exceptionnal access of the person personId
#
# GET /spaces/{id}/persons/{personId}/folders
export def "spaces-persons-folders list" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}/folders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of groups of the person personId
#
# GET /spaces/{id}/persons/{personId}/groups
export def "spaces-persons-groups get" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}/groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of portfolios of the person personId
#
# GET /spaces/{id}/persons/{personId}/portfolios
export def "spaces-persons-portfolios get" [
  id: string
  person_id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}/portfolios"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a portfolio for the person personId
#
# POST /spaces/{id}/persons/{personId}/portfolios
export def "spaces-persons-portfolios create" [
  id: string
  person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --designation: string # e.g. My Portfolio
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --name: string # e.g. Dupond
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), person_id: (encode-path-segment $person_id)} | format pattern "/spaces/{id}/persons/{person_id}/portfolios"))
  let req_body = {"About": $about, "ArchivalDate": $archival_date, "Designation": $designation, "Home": $home, "Keywords": $keywords, "Level": $level, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add/Modify/Delete a person in a portfolio (except manager)
#
# PATCH /spaces/{id}/portfolios/{portfolioId}/persons/{memberId}
export def "spaces-portfolios-persons update" [
  id: string
  portfolio_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply: oneof<nothing, bool> # e.g. true
  --groups: list<string>@groups-completer-1 # e.g. [social, legal]
  --is-admin: oneof<nothing, bool> # e.g. false
  --role: string@role-completer-1 # e.g. collaborator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), portfolio_id: (encode-path-segment $portfolio_id), member_id: (encode-path-segment $member_id)} | format pattern "/spaces/{id}/portfolios/{portfolio_id}/persons/{member_id}"))
  let req_body = {"Apply": $apply, "Groups": $groups, "IsAdmin": $is_admin, "Role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  --designation: string # designation of the vehicle (e.g. peugeot)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Designation" $designation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/professional-vehicles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a professional vehicle for the space
#
# POST /spaces/{id}/professional-vehicles
export def "spaces-professional-vehicles create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --brand: string # e.g. Renault
  --comment: string # e.g. Peugeot Lyon
  --company-tax: oneof<nothing, bool> # e.g. true
  --date-in: string # e.g. 20201802
  --date-out: string # e.g. 20201802
  designation: string # e.g. peugeot siège
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, clio]
  --level: string@level-completer # e.g. confidential
  --model: string # e.g. Clio
  --registration-date: string # e.g. 20181231
  --registration-number: string # e.g. AA001AA
  --type: string # e.g. car
  --value: float # e.g. 1500.23
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/professional-vehicles"))
  let req_body = {"About": $about, "Brand": $brand, "Comment": $comment, "CompanyTax": $company_tax, "DateIn": $date_in, "DateOut": $date_out, "Designation": $designation, "Home": $home, "Keywords": $keywords, "Level": $level, "Model": $model, "RegistrationDate": $registration_date, "RegistrationNumber": $registration_number, "Type": $type, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/settings/nf203/logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable/Disable logs
#
# POST /spaces/{id}/settings/nf203/logs
export def "spaces-settings-nf203-logs create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # e.g. true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/settings/nf203/logs"))
  let req_body = {"Enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace or Add a status
#
# POST /spaces/{id}/status
export def "spaces-status create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # e.g. COD
  --comment: string # e.g. my first code
  label: string # e.g. code 1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/status"))
  let req_body = {"Code": $code, "Comment": $comment, "Label": $label} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), code: (encode-path-segment $code)} | format pattern "/spaces/{id}/status/{code}"))
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/tax-contracts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tax contract for the space
#
# POST /spaces/{id}/tax-contracts
export def "spaces-tax-contracts create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  designation: string # e.g. année 2019
  --end: string # e.g. 20181231
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180101
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/tax-contracts"))
  let req_body = {"About": $about, "Comment": $comment, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spaces/{id}/triggers"))
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), name: (encode-path-segment $name)} | format pattern "/spaces/{id}/triggers/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a trigger for the space id
#
# POST /spaces/{id}/triggers/{name}
export def "spaces-triggers create" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id), name: (encode-path-segment $name)} | format pattern "/spaces/{id}/triggers/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a common folder
#
# DELETE /spaces/{spaceId}/common-folders/{id}
export def "spaces-common-folders delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/common-folders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a common folder
#
# PATCH /spaces/{spaceId}/common-folders/{id}
export def "spaces-common-folders update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --name: string # e.g. Dupond
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/common-folders/{id}"))
  let req_body = {"About": $about, "ArchivalDate": $archival_date, "Home": $home, "Keywords": $keywords, "Level": $level, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the company entity
#
# GET /spaces/{spaceId}/company-entities/{id}/follow-ups
export def "spaces-company-entities-follow-ups get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/company-entities/{id}/follow-ups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and customer data
#
# GET /spaces/{spaceId}/customers
export def "spaces-customers get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-number: string # CustomerNumber of the customer
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CustomerNumber" $customer_number "scalar") (serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/customers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and customer data (even archived)
#
# GET /spaces/{spaceId}/customers/all
export def "spaces-customers-all get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-number: string # CustomerNumber of the employee
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "CustomerNumber" $customer_number "scalar") (serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/customers/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/documents
export def "spaces-documents get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --full-text: string # Text to find (e.g. durand)
  --range: string # index range of the results (e.g. 10-19)
  --class: string # class of the document to find (e.g. payslip)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FullText" $full_text "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "Class" $class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a doc
#
# PATCH /spaces/{spaceId}/documents/{documentId}
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
export def "spaces-documents update" [
  space_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  --title: string # e.g. Facture décembre
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}"))
  let req_body = {"Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# read the data of a document
#
# GET /spaces/{spaceId}/documents/{documentId}/extend
export def "spaces-documents-extend get" [
  space_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/extend"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a data to a document
#
# POST /spaces/{spaceId}/documents/{documentId}/extend
export def "spaces-documents-extend create" [
  space_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/extend"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns versions of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/folders
export def "spaces-documents-folders get" [
  space_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/folders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# send by mail a document
#
# POST /spaces/{spaceId}/documents/{documentId}/mailing
# --Address shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
export def "spaces-documents-mailing create" [
  space_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {City?: string, Complement?: string, Country?: string, Street?: string, ZipCode?: string}
  --name: string # e.g. Société Dupond
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/mailing"))
  let req_body = {"Address": $address, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# returns the number of pages and the price of the pdf to send by mail
#
# GET /spaces/{spaceId}/documents/{documentId}/mailingprice
export def "spaces-documents-mailingprice get" [
  space_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/mailingprice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns versions of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/versions
export def "spaces-documents-versions get" [
  space_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a version to a document and set it as current
#
# POST /spaces/{spaceId}/documents/{documentId}/versions
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-documents-versions create" [
  space_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/versions"))
  let req_body = {"Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns current version of the document
#
# GET /spaces/{spaceId}/documents/{documentId}/versions/current
export def "spaces-documents-versions-current get" [
  space_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/documents/{document_id}/versions/current"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns accesses of one document
#
# GET /spaces/{spaceId}/documents/{id}/access
export def "spaces-documents-access get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/documents/{id}/access"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the document with the accounting property
#
# GET /spaces/{spaceId}/documents/{id}/accounting
export def "spaces-documents-accounting get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/documents/{id}/accounting"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns content of one document
#
# GET /spaces/{spaceId}/documents/{id}/download
export def "spaces-documents-download get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/documents/{id}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employee data
#
# GET /spaces/{spaceId}/employees
export def "spaces-employees get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ss-number: string # SSNumber of the employee
  --employee-number: string # EmployeeNumber of the employee
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SSNumber" $ss_number "scalar") (serialize-qp "EmployeeNumber" $employee_number "scalar") (serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/employees") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employee data (even archived)
#
# GET /spaces/{spaceId}/employees/all
export def "spaces-employees-all get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ss-number: string # SSNumber of the employee
  --employee-number: string # EmployeeNumber of the employee
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SSNumber" $ss_number "scalar") (serialize-qp "EmployeeNumber" $employee_number "scalar") (serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/employees/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employer data
#
# GET /spaces/{spaceId}/employers
export def "spaces-employers get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employee-number: string # EmployeeNumber of the employer contract
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployeeNumber" $employee_number "scalar") (serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/employers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders with Id and employer data (even archived)
#
# GET /spaces/{spaceId}/employers/all
export def "spaces-employers-all get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employee-number: string # EmployeeNumber of the employer contract
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployeeNumber" $employee_number "scalar") (serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/employers/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# read the data of a space
#
# GET /spaces/{spaceId}/extend
export def "spaces-extend get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/extend"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a data to a space
#
# POST /spaces/{spaceId}/extend
export def "spaces-extend create" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/extend"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folders of the space
#
# GET /spaces/{spaceId}/folders
export def "spaces-folders get-by-spaceId" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Secrétariat juridique)
  --keywords: string # keywords attached to the folder (e.g. juridique)
  --root-folders: string@root-folders-completer # only root folders (e.g. all)
  --range: string # index range of the results (e.g. 10-19)
  --class: string # class of the folder (e.g. social)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Keywords" $keywords "scalar") (serialize-qp "RootFolders" $root_folders "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "Class" $class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/folders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folders of the space (even archived)
#
# GET /spaces/{spaceId}/folders/all
export def "spaces-folders-all get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Secrétariat juridique)
  --range: string # index range of the results (e.g. 10-19)
  --keywords: string # keywords attached to the folder (e.g. juridique)
  --class: string # class of the folder (e.g. social)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "Keywords" $keywords "scalar") (serialize-qp "Class" $class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/folders/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a bank statement
#
# DELETE /spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}
export def "spaces-folders-bank-statements delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/bank-statements/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a bank statement
#
# PATCH /spaces/{spaceId}/folders/{folderId}/bank-statements/{documentId}
export def "spaces-folders-bank-statements update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance: float # format: number, e.g. 1352.63
  --number: float # format: string, e.g. 10015848
  --statement-date: string # e.g. 20160801
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/bank-statements/{document_id}"))
  let req_body = {"Balance": $balance, "Number": $number, "StatementDate": $statement_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a contractual document
#
# DELETE /spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}
export def "spaces-folders-contractual-documents delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/contractual-documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a contractual document
#
# PATCH /spaces/{spaceId}/folders/{folderId}/contractual-documents/{documentId}
export def "spaces-folders-contractual-documents update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # e.g. 1001.36
  --designation: string # e.g. contrat client
  --reference: string # e.g. 151465AFHIA
  --start-date: string # e.g. 20181128
  --type: string@type-completer-2 # e.g. quotation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/contractual-documents/{document_id}"))
  let req_body = {"Amount": $amount, "Designation": $designation, "Reference": $reference, "StartDate": $start_date, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a corporate tax declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}
export def "spaces-folders-corporate-tax-declarations delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/corporate-tax-declarations/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a coporate tax declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/corporate-tax-declarations/{documentId}
export def "spaces-folders-corporate-tax-declarations update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  --order: string@order-completer # e.g. 1st advance
  --rate: float # format: float, e.g. 10.63
  --tax-base: float # format: float, e.g. 123.36
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/corporate-tax-declarations/{document_id}"))
  let req_body = {"Amount": $amount, "DeclarationDate": $declaration_date, "Order": $order, "Rate": $rate, "TaxBase": $tax_base} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete an expense proof
#
# DELETE /spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}
export def "spaces-folders-expense-proofs delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/expense-proofs/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an expense report
#
# PATCH /spaces/{spaceId}/folders/{folderId}/expense-proofs/{documentId}
export def "spaces-folders-expense-proofs update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string@account-completer # e.g. CAB
  --archival-date: string # e.g. 20211231
  --before-vat: float # e.g. 1000
  --expense-date: string # e.g. 20200202
  --expense-report-id: string # e.g. PFOIAHF874984
  --provider: string # e.g. G7
  --reason: string # e.g. taxi
  --status: string@status-completer # e.g. R
  --vat: float # e.g. 19.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/expense-proofs/{document_id}"))
  let req_body = {"Account": $account, "ArchivalDate": $archival_date, "BeforeVAT": $before_vat, "ExpenseDate": $expense_date, "ExpenseReportId": $expense_report_id, "Provider": $provider, "Reason": $reason, "Status": $status, "VAT": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete an expense report
#
# DELETE /spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}
export def "spaces-folders-expense-reports delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/expense-reports/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an expense report
#
# PATCH /spaces/{spaceId}/folders/{folderId}/expense-reports/{documentId}
export def "spaces-folders-expense-reports update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-vat: float # e.g. 1000
  --expense-date: string # e.g. 20200202
  --incl-vat: float # e.g. 1200
  --processing-date: string # e.g. 20200203
  --vat: float # e.g. 19.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/expense-reports/{document_id}"))
  let req_body = {"BeforeVAT": $before_vat, "ExpenseDate": $expense_date, "InclVAT": $incl_vat, "ProcessingDate": $processing_date, "VAT": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete an invoice document
#
# DELETE /spaces/{spaceId}/folders/{folderId}/invoices/{documentId}
export def "spaces-folders-invoices delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/invoices/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a invoice
#
# PATCH /spaces/{spaceId}/folders/{folderId}/invoices/{documentId}
export def "spaces-folders-invoices update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-vat: float # e.g. 1000
  --due-date: string # e.g. 20190130
  --incl-vat: float # e.g. 1200
  --invoice-date: string # e.g. 20200202
  --number: string # e.g. 036459879874
  --payment-date: string # e.g. 20190131
  --type: string@type-completer-3 # e.g. commercial-invoice
  --vat: float # e.g. 19.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/invoices/{document_id}"))
  let req_body = {"BeforeVAT": $before_vat, "DueDate": $due_date, "InclVAT": $incl_vat, "InvoiceDate": $invoice_date, "Number": $number, "PaymentDate": $payment_date, "Type": $type, "VAT": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# get a nominative social declaration
#
# GET /spaces/{spaceId}/folders/{folderId}/nominative-social-declarations/{documentId}
export def "spaces-folders-nominative-social-declarations get" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/nominative-social-declarations/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a tax declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}
export def "spaces-folders-other-taxes delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/other-taxes/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an other tax declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/other-taxes/{documentId}
export def "spaces-folders-other-taxes update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  --reference: string # e.g. décla CFE
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/other-taxes/{document_id}"))
  let req_body = {"Amount": $amount, "DeclarationDate": $declaration_date, "Reference": $reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a payroll
#
# DELETE /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}
export def "spaces-folders-payrolls delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/payrolls/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a payroll
#
# PATCH /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}
export def "spaces-folders-payrolls update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --employee-contributions: float # format: float, e.g. 1352.63
  --employer-contributions: float # format: float, e.g. 132.63
  --end: string # e.g. 20160831
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/payrolls/{document_id}"))
  let req_body = {"Begin": $begin, "EmployeeContributions": $employee_contributions, "EmployerContributions": $employer_contributions, "End": $end, "NetAmount": $net_amount, "TotalGrossAmount": $total_gross_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# recalculate a payroll
#
# POST /spaces/{spaceId}/folders/{folderId}/payrolls/{documentId}/refresh
export def "spaces-folders-payrolls-refresh create" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/payrolls/{document_id}/refresh"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a payslip
#
# DELETE /spaces/{spaceId}/folders/{folderId}/payslips/{documentId}
export def "spaces-folders-payslips delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/payslips/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a payslip
#
# PATCH /spaces/{spaceId}/folders/{folderId}/payslips/{documentId}
export def "spaces-folders-payslips update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --employee-contributions: float # format: float, e.g. 2000.5
  --employer-contributions: float # format: float, e.g. 400.5
  --end: string # e.g. 20160831
  --fixed-gross-amount: float # format: float, e.g. 1352.63
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
  --vacation: float # format: float, e.g. 20.5
  --variable-gross-amount: float # format: float, e.g. 132.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/payslips/{document_id}"))
  let req_body = {"Begin": $begin, "EmployeeContributions": $employee_contributions, "EmployerContributions": $employer_contributions, "End": $end, "FixedGrossAmount": $fixed_gross_amount, "NetAmount": $net_amount, "TotalGrossAmount": $total_gross_amount, "Vacation": $vacation, "VariableGrossAmount": $variable_gross_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a social contract
#
# DELETE /spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}
export def "spaces-folders-social-contracts delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/social-contracts/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a social contract
#
# PATCH /spaces/{spaceId}/folders/{folderId}/social-contracts/{documentId}
export def "spaces-folders-social-contracts update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-date: string # e.g. 20190202
  --contract-duration: string # e.g. 6 mois
  --contractual-change: string # e.g. augmentation
  --position: string # e.g. cadre
  --wage-developments: float # format: float, e.g. 1548.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/social-contracts/{document_id}"))
  let req_body = {"ContractDate": $contract_date, "ContractDuration": $contract_duration, "ContractualChange": $contractual_change, "Position": $position, "WageDevelopments": $wage_developments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a social declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}
export def "spaces-folders-social-declarations delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/social-declarations/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a social declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/social-declarations/{documentId}
export def "spaces-folders-social-declarations update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/social-declarations/{document_id}"))
  let req_body = {"Amount": $amount, "DeclarationDate": $declaration_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a VAT declaration
#
# DELETE /spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}
export def "spaces-folders-vat-declarations delete" [
  space_id: string
  folder_id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/vat-declarations/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify a vat declaration
#
# PATCH /spaces/{spaceId}/folders/{folderId}/vat-declarations/{documentId}
export def "spaces-folders-vat-declarations update" [
  space_id: string
  folder_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --collected-vat: float # format: float, e.g. 1548.63
  --credit-vat: float # format: float, e.g. 400.5
  --deductible-vat: float # format: float, e.g. 20.5
  --end: string # e.g. 20160831
  --exempt-turnover: float # format: float, e.g. 132.63
  --number: string # e.g. 153126
  --payable-vat: float # format: float, e.g. 2000.5
  --taxable-turnover: float # format: float, e.g. 1352.63
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), folder_id: (encode-path-segment $folder_id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{folder_id}/vat-declarations/{document_id}"))
  let req_body = {"Begin": $begin, "CollectedVAT": $collected_vat, "CreditVAT": $credit_vat, "DeductibleVAT": $deductible_vat, "End": $end, "ExemptTurnover": $exempt_turnover, "Number": $number, "PayableVAT": $payable_vat, "TaxableTurnover": $taxable_turnover} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder with Id
#
# GET /spaces/{spaceId}/folders/{id}
export def "spaces-folders get-by-spaceId-id" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate)
#
# PATCH /spaces/{spaceId}/folders/{id}
export def "spaces-folders update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}"))
  let req_body = {"About": $about, "Home": $home, "Keywords": $keywords, "Level": $level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete an AccountingYear
#
# DELETE /spaces/{spaceId}/folders/{id}/accounting-year
export def "spaces-folders-accounting-year delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/accounting-year"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and AccountingYear data
#
# PATCH /spaces/{spaceId}/folders/{id}/accounting-year
export def "spaces-folders-accounting-year update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  --end: string # e.g. 20181231
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --net-income: float # e.g. 52634.36
  --net-position: float # e.g. 14580.36
  --start: string # e.g. 20180101
  --tax: float # e.g. 45698.36
  --taxable-income: float # e.g. 869523.36
  --turnover: float # e.g. 1025.36
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/accounting-year"))
  let req_body = {"About": $about, "Comment": $comment, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "NetIncome": $net_income, "NetPosition": $net_position, "Start": $start, "Tax": $tax, "TaxableIncome": $taxable_income, "Turnover": $turnover} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns accountings documents of the folder (results and taxation or accountingyear)
#
# GET /spaces/{spaceId}/folders/{id}/accountings
export def "spaces-folders-accountings get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --title: string # Title of the accounting document (e.g. Accounting)
  --workbook: string # workbook of the accounting (e.g. Accounting)
  --class: string # class of the accounting (e.g. Invoice)
  --accounted-on: string # accountedon of the accounting (boolean available) (e.g. 20180201,null)
  --with-folders: string # if present, the folders containing the documents are returned (e.g. yes)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "FolderDate" $folder_date "scalar") (serialize-qp "Title" $title "scalar") (serialize-qp "Workbook" $workbook "scalar") (serialize-qp "Class" $class "scalar") (serialize-qp "AccountedOn" $accounted_on "scalar") (serialize-qp "WithFolders" $with_folders "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/accountings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# journal of accountings document delivered to a customer
#
# GET /spaces/{spaceId}/folders/{id}/accountings-journal
export def "spaces-folders-accountings-journal get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delivery-date: string # delivery dates of the document (e.g. 20191123082536,null)
  --accounting-date: string # accounting dates of the document (e.g. 20170215,null)
  --number: int # numbers of the document (e.g. 12,17)
  --workbook: string # workbook of the document (e.g. cashwoucher)
  --year-month: string # yearmonth of the document (e.g. 201802)
  --class: string # class of the document (e.g. invoice)
  --code: string # code of the document (e.g. delivered)
  --target-folder-name: string # Name of the target folder of the document (e.g. Exercice*)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeliveryDate" $delivery_date "scalar") (serialize-qp "AccountingDate" $accounting_date "scalar") (serialize-qp "Number" $number "scalar") (serialize-qp "Workbook" $workbook "scalar") (serialize-qp "YearMonth" $year_month "scalar") (serialize-qp "Class" $class "scalar") (serialize-qp "Code" $code "scalar") (serialize-qp "TargetFolderName" $target_folder_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/accountings-journal") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Bank data
#
# DELETE /spaces/{spaceId}/folders/{id}/bank
export def "spaces-folders-bank delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/bank"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and bank data
#
# GET /spaces/{spaceId}/folders/{id}/bank
export def "spaces-folders-bank get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/bank"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Bank data
#
# PATCH /spaces/{spaceId}/folders/{id}/bank
export def "spaces-folders-bank update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-reference: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/bank"))
  let req_body = {"About": $about, "Comment": $comment, "ContractReference": $contract_reference, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns bank statements of the folder bank
#
# GET /spaces/{spaceId}/folders/{id}/bank-statements
export def "spaces-folders-bank-statements get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --number: string # Number of the bank statement (e.g. 201603)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Number" $number "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/bank-statements") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a bank statement in a folder bank
#
# POST /spaces/{spaceId}/folders/{id}/bank-statements
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-bank-statements create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance: float # format: number, e.g. 1352.63
  document_id: string # e.g. PBUFBAUBF1531
  --number: float # format: string, e.g. 10015848
  statement_date: string # e.g. 20160801
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/bank-statements"))
  let req_body = {"Balance": $balance, "DocumentId": $document_id, "Number": $number, "StatementDate": $statement_date, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Collective Decision data
#
# PATCH /spaces/{spaceId}/folders/{id}/collective-decision
export def "spaces-folders-collective-decision update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. ogm of the company
  --date: string # e.g. 20180202
  --dividend-distributions: float # e.g. 1025.36
  --dividend-distributions-date: string # e.g. 20180203
  --event: string@event-completer # for space type 'company' enums allowed are 'EGM','CGM','OGM','ConstituentAssembly','SolePartner','OtherEvent','Office','ExecutiveCommittee','Consulting','Board','PartnersMeeting' and for space type 'association' enums allowed are 'EGM','CGM','OGM','Other','Office','ExecutiveCommittee' (e.g. EGM)
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/collective-decision"))
  let req_body = {"About": $about, "Comment": $comment, "Date": $date, "DividendDistributions": $dividend_distributions, "DividendDistributionsDate": $dividend_distributions_date, "Event": $event, "Home": $home, "Keywords": $keywords, "Level": $level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns common folders of a folder
#
# GET /spaces/{spaceId}/folders/{id}/common-folders
export def "spaces-folders-common-folders get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Folder one)
  --keywords: string # keywords attached to the folder (e.g. juridique)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Keywords" $keywords "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/common-folders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a common folder in another folder
#
# POST /spaces/{spaceId}/folders/{id}/common-folders
export def "spaces-folders-common-folders create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  name: string # e.g. Dupond
  --rights: oneof<nothing, bool> # e.g. true
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/common-folders"))
  let req_body = {"About": $about, "ArchivalDate": $archival_date, "Home": $home, "Keywords": $keywords, "Level": $level, "Name": $name, "Rights": $rights} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns common folders (even archived) of a folder
#
# GET /spaces/{spaceId}/folders/{id}/common-folders/all
export def "spaces-folders-common-folders-all get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Folder one)
  --keywords: string # keywords attached to the folder (e.g. juridique)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $name "scalar") (serialize-qp "Keywords" $keywords "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/common-folders/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all contracting partners of a contract
#
# GET /spaces/{spaceId}/folders/{id}/contracting-partner
export def "spaces-folders-contracting-partner get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/contracting-partner"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns collector space of a contract
#
# GET /spaces/{spaceId}/folders/{id}/contracting-partner/space
export def "spaces-folders-contracting-partner-space get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/contracting-partner/space"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/folders/{id}/contractual-documents
export def "spaces-folders-contractual-documents get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --type: string@type-completer-2 # Type of the document (e.g. amendment)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "FolderDate" $folder_date "scalar") (serialize-qp "Type" $type "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/contractual-documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/contractual-documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-contractual-documents create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # e.g. 1001.36
  --designation: string # e.g. contrat client
  document_id: string # e.g. PBUFBAUBF1531
  --reference: string # e.g. 151465AFHIA
  --start-date: string # e.g. 20181128
  --type: string@type-completer-2 # e.g. quotation
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: any # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/contractual-documents"))
  let req_body = {"Amount": $amount, "Designation": $designation, "DocumentId": $document_id, "Reference": $reference, "StartDate": $start_date, "Type": $type, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder with Id and contractual-relationship data
#
# GET /spaces/{spaceId}/folders/{id}/contractual-relationship
export def "spaces-folders-contractual-relationship get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/contractual-relationship"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns corporate tax declarations
#
# GET /spaces/{spaceId}/folders/{id}/coporate-tax-declarations
export def "spaces-folders-coporate-tax-declarations get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/coporate-tax-declarations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a corporate tax declaration
#
# POST /spaces/{spaceId}/folders/{id}/coporate-tax-declarations
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-coporate-tax-declarations create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --order: string@order-completer # e.g. 1st advance
  --rate: float # format: float, e.g. 10.63
  --tax-base: float # format: float, e.g. 123.36
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/coporate-tax-declarations"))
  let req_body = {"Amount": $amount, "DeclarationDate": $declaration_date, "DocumentId": $document_id, "Order": $order, "Rate": $rate, "TaxBase": $tax_base, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a customer
#
# DELETE /spaces/{spaceId}/folders/{id}/customer
export def "spaces-folders-customer delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/customer"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and customer data
#
# GET /spaces/{spaceId}/folders/{id}/customer
export def "spaces-folders-customer get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/customer"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Customer data
#
# PATCH /spaces/{spaceId}/folders/{id}/customer
export def "spaces-folders-customer update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keep-old: oneof<nothing, bool> # e.g. true
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --portfolio-id: string # e.g. T1OJFOAZ7449420F
  --secondary-portfolio-id: string # e.g. T1OJFOAZ7449420F
  --start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/customer"))
  let req_body = {"About": $about, "Comment": $comment, "CustomerNumber": $customer_number, "Designation": $designation, "End": $end, "Home": $home, "KeepOld": $keep_old, "Keywords": $keywords, "Level": $level, "PortfolioId": $portfolio_id, "SecondaryPortfolioId": $secondary_portfolio_id, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# journal of documents delivered to a customer
#
# GET /spaces/{spaceId}/folders/{id}/deliveries-journal
export def "spaces-folders-deliveries-journal get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delivery-date: string # delivery dates of the document (e.g. 20191123082536,null)
  --accounting-date: string # accounting dates of the document (e.g. 20170215,null)
  --number: int # numbers of the document (e.g. 12,17)
  --class: string # class of the document (e.g. invoice)
  --target-folder-name: string # Name of the target folder of the document (e.g. Exercice*)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeliveryDate" $delivery_date "scalar") (serialize-qp "AccountingDate" $accounting_date "scalar") (serialize-qp "Number" $number "scalar") (serialize-qp "Class" $class "scalar") (serialize-qp "TargetFolderName" $target_folder_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/deliveries-journal") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns documents of the folder
#
# GET /spaces/{spaceId}/folders/{id}/documents
export def "spaces-folders-documents get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
  --title: string # Title of the document (e.g. Facture EDF)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --class: string # Class of document (e.g. Contract)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Title" $title "scalar") (serialize-qp "FolderDate" $folder_date "scalar") (serialize-qp "Class" $class "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/documents
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-documents create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/documents"))
  let req_body = {"DocumentId": $document_id, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Detach a doc of a folder
#
# PATCH /spaces/{spaceId}/folders/{id}/documents/{documentId}/detach
export def "spaces-folders-documents-detach update" [
  space_id: string
  id: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{id}/documents/{document_id}/detach"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Employee data
#
# DELETE /spaces/{spaceId}/folders/{id}/employee
export def "spaces-folders-employee delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/employee"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and employee data
#
# GET /spaces/{spaceId}/folders/{id}/employee
export def "spaces-folders-employee get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/employee"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Employee data
#
# PATCH /spaces/{spaceId}/folders/{id}/employee
export def "spaces-folders-employee update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-type: string # e.g. 01
  --employee-number: string # e.g. 13587FAZCD420F
  --end: string # e.g. 20190101
  --function: string # e.g. commercial
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --postal-mail: oneof<nothing, bool> # e.g. true
  --ss-number: string # e.g. 1542012365985215
  --start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/employee"))
  let req_body = {"About": $about, "Comment": $comment, "ContractType": $contract_type, "EmployeeNumber": $employee_number, "End": $end, "Function": $function, "Home": $home, "Keywords": $keywords, "Level": $level, "PostalMail": $postal_mail, "SSNumber": $ss_number, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns expense proofs of the folder (social, followup or exchange)
#
# GET /spaces/{spaceId}/folders/{id}/expense-proofs
export def "spaces-folders-expense-proofs get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --status: string@status-completer # Status of the expense proof (e.g. R)
  --no-expense-report: oneof<nothing, bool> # To return expense proofs not attached to an expense report (e.g. 1)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "FolderDate" $folder_date "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "NoExpenseReport" $no_expense_report "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/expense-proofs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a expense proof in a folder followup or exchange
#
# POST /spaces/{spaceId}/folders/{id}/expense-proofs
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-expense-proofs create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string@account-completer # e.g. CAB
  --archival-date: string # e.g. 20211231
  --before-vat: float # e.g. 1000
  document_id: string # e.g. PBUFBAUBF1531
  --expense-date: string # e.g. 20200202
  --expense-report-id: string # e.g. PFOIAHF874984
  --provider: string # e.g. G7
  --reason: string # e.g. taxi
  --status: string@status-completer # e.g. R
  --vat: float # e.g. 19.5
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/expense-proofs"))
  let req_body = {"Account": $account, "ArchivalDate": $archival_date, "BeforeVAT": $before_vat, "DocumentId": $document_id, "ExpenseDate": $expense_date, "ExpenseReportId": $expense_report_id, "Provider": $provider, "Reason": $reason, "Status": $status, "VAT": $vat, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns expense reports of the folder (social or followup)
#
# GET /spaces/{spaceId}/folders/{id}/expense-reports
export def "spaces-folders-expense-reports get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --with-extend: string@with-extend-completer # If present returns also the data extend (e.g. true)
  --range: string # index range of the results (e.g. 10-19)
  --processing-date: string # range of processing date (boolean available) (e.g. 20180526,null)
  --expense-date: string # range of ExpenseDate (valid available) (e.g. 20180526,null)
  --sort-order: string@sort-order-completer # order of sort (if absent default is asc) (e.g. asc)
  --sort-name: string@sort-name-completer # name of value for sort (e.g. ExpenseDate)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "FolderDate" $folder_date "scalar") (serialize-qp "WithExtend" $with_extend "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "ProcessingDate" $processing_date "scalar") (serialize-qp "ExpenseDate" $expense_date "scalar") (serialize-qp "SortOrder" $sort_order "scalar") (serialize-qp "SortName" $sort_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/expense-reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a expense report in a folder followup
#
# POST /spaces/{spaceId}/folders/{id}/expense-reports
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-expense-reports create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-vat: float # e.g. 1000
  --date: string # e.g. 20161203
  document_id: string # e.g. PBUFBAUBF1531
  --expense-date: string # e.g. 20200202
  --incl-vat: float # e.g. 1200
  --processing-date: string # e.g. 20200203
  --vat: float # e.g. 19.5
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/expense-reports"))
  let req_body = {"BeforeVAT": $before_vat, "Date": $date, "DocumentId": $document_id, "ExpenseDate": $expense_date, "InclVAT": $incl_vat, "ProcessingDate": $processing_date, "VAT": $vat, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns expense proofs linked to the expenseReportId
#
# GET /spaces/{spaceId}/folders/{id}/expense-reports/{expenseReportId}/expense-proofs
export def "spaces-folders-expense-reports-expense-proofs get" [
  space_id: string
  id: string
  expense_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of the documents (YYYY or YYYYMM or YYYYMMDD) (e.g. 20160321)
  --status: string@status-completer # Status of the expense proof (e.g. R)
  --folder-date: string # Date of upload of the document (YYYY or YYYYMM or YYYYMMDD) (e.g. 20180202000000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "FolderDate" $folder_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), expense_report_id: (encode-path-segment $expense_report_id)} | format pattern "/spaces/{space_id}/folders/{id}/expense-reports/{expense_report_id}/expense-proofs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Insurance data
#
# DELETE /spaces/{spaceId}/folders/{id}/insurance
export def "spaces-folders-insurance delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/insurance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and insurance data
#
# GET /spaces/{spaceId}/folders/{id}/insurance
export def "spaces-folders-insurance get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/insurance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Insurance data
#
# PATCH /spaces/{spaceId}/folders/{id}/insurance
export def "spaces-folders-insurance update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --policy-number: string # e.g. 1358
  --start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/insurance"))
  let req_body = {"About": $about, "Comment": $comment, "CustomerNumber": $customer_number, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "PolicyNumber": $policy_number, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns invoices of the folder (customer, provider, accountingyear or root folders customers or providers)
#
# GET /spaces/{spaceId}/folders/{id}/invoices
export def "spaces-folders-invoices get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Title of the documents (e.g. factrure)
  --date: string # date range of the documents (e.g. 20160321,null)
  --number: string # Number of the invoice (e.g. 23585)
  --incl-vat: float # amount incl. VAT (e.g. 100.50,123.69)
  --before-vat: float # amount before VAT (e.g. 102.50,123.69)
  --due-date: string # date due payment (e.g. 20201231,20211231)
  --payment-date: string # date of payment (boolean and valid available) (e.g. 20201201,20211201)
  --invoice-date: string # range date of invoice (e.g. 20201201)
  --folder-date: string # date range of attachment (e.g. 20180306,null)
  --accounted-on: string # value of AccountedOn (boolean available but not range) (e.g. 20220101)
  --with-extend: string # If present returns also the data extend (e.g. 202102,null)
  --extend: string # json object to filter extend data (e.g. [{"Name":"field1","Equals":"test"},{"Name":"field2","Start":"20180101"},{"Name":"field3","End":"20190101"}])
  --range: string # index range of the results (e.g. 10-19)
  --sort-order: string@sort-order-completer # order of sort (if absent default is asc) (e.g. asc)
  --sort-name: string@sort-name-completer-1 # name of value for sort (e.g. PaymentDate)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Title" $title "scalar") (serialize-qp "Date" $date "scalar") (serialize-qp "Number" $number "scalar") (serialize-qp "InclVAT" $incl_vat "scalar") (serialize-qp "BeforeVAT" $before_vat "scalar") (serialize-qp "DueDate" $due_date "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "InvoiceDate" $invoice_date "scalar") (serialize-qp "FolderDate" $folder_date "scalar") (serialize-qp "AccountedOn" $accounted_on "scalar") (serialize-qp "WithExtend" $with_extend "scalar") (serialize-qp "Extend" $extend "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "SortOrder" $sort_order "scalar") (serialize-qp "SortName" $sort_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a invoice in a folder of a customer or a provider
#
# POST /spaces/{spaceId}/folders/{id}/invoices
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-invoices create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-vat: float # e.g. 1000
  --date: string # e.g. 20161203
  document_id: string # e.g. PBUFBAUBF1531
  --due-date: string # e.g. 20190130
  --incl-vat: float # e.g. 1200
  --invoice-date: string # e.g. 20200202
  --number: string # e.g. 036459879874
  --payment-date: string # e.g. 20190131
  --type: string@type-completer-3 # e.g. commercial-invoice
  --vat: float # e.g. 19.5
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/invoices"))
  let req_body = {"BeforeVAT": $before_vat, "Date": $date, "DocumentId": $document_id, "DueDate": $due_date, "InclVAT": $incl_vat, "InvoiceDate": $invoice_date, "Number": $number, "PaymentDate": $payment_date, "Type": $type, "VAT": $vat, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns legal entity of a follow up folder
#
# GET /spaces/{spaceId}/folders/{id}/legal-entity
export def "spaces-folders-legal-entity get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/legal-entity"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and Loan data
#
# DELETE /spaces/{spaceId}/folders/{id}/loan
export def "spaces-folders-loan delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/loan"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and loan data
#
# GET /spaces/{spaceId}/folders/{id}/loan
export def "spaces-folders-loan get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/loan"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Loan data
#
# PATCH /spaces/{spaceId}/folders/{id}/loan
export def "spaces-folders-loan update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --amount: float # format: float, e.g. 1000
  --category: string@category-completer # e.g. debt spreading
  --comment: string # e.g. pieces company
  --designation: string # e.g. emprunt entreprise
  --due-amount: float # format: float, e.g. 1000.6
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --months-number: float # e.g. 12
  --rate: float # format: float, e.g. 2.5
  --start: string # e.g. 20180630
  --total-cost: float # format: float, e.g. 10200
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/loan"))
  let req_body = {"About": $about, "Amount": $amount, "Category": $category, "Comment": $comment, "Designation": $designation, "DueAmount": $due_amount, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "MonthsNumber": $months_number, "Rate": $rate, "Start": $start, "TotalCost": $total_cost} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns messages of the folder
#
# GET /spaces/{spaceId}/folders/{id}/messages
export def "spaces-folders-messages list" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Name of the message (e.g. *welcom*)
  --range: string # index range of the results (e.g. 10-19)
  --message-date: string # date of the message (e.g. 20190202)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Text" $text "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "MessageDate" $message_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write a message in the journal of a folder
#
# POST /spaces/{spaceId}/folders/{id}/messages
# --Notify shape: {How?: "std"|"mail"|"sms", MemberIds?: list<string>}
export def "spaces-folders-messages create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string@level-completer-1 # e.g. confidential
  --message-date: string # e.g. 20160203
  --notify: record # shape: {How?: "std"|"mail"|"sms", MemberIds?: list<string>}
  text: string # e.g. <p> hello world </p>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/messages"))
  let req_body = {"Level": $level, "MessageDate": $message_date, "Notify": $notify, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns message with Id
#
# GET /spaces/{spaceId}/folders/{id}/messages/{messageId}
export def "spaces-folders-messages get" [
  space_id: string
  id: string
  message_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/spaces/{space_id}/folders/{id}/messages/{message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Message
#
# PATCH /spaces/{spaceId}/folders/{id}/messages/{messageId}
# --Notify shape: {How?: "std"|"mail"|"sms", MemberIds?: list<string>}
export def "spaces-folders-messages update" [
  space_id: string
  id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string@level-completer-1 # e.g. confidential
  --message-date: string # e.g. 20160203
  --notify: record # shape: {How?: "std"|"mail"|"sms", MemberIds?: list<string>}
  --text: string # e.g. <p> hello world </p>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), message_id: (encode-path-segment $message_id)} | format pattern "/spaces/{space_id}/folders/{id}/messages/{message_id}"))
  let req_body = {"Level": $level, "MessageDate": $message_date, "Notify": $notify, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns nominative social declarations of the folder social
#
# GET /spaces/{spaceId}/folders/{id}/nominative-social-declarations
export def "spaces-folders-nominative-social-declarations list" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/nominative-social-declarations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns other taxes declarations
#
# GET /spaces/{spaceId}/folders/{id}/other-taxes
export def "spaces-folders-other-taxes get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/other-taxes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tax declaration
#
# POST /spaces/{spaceId}/folders/{id}/other-taxes
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-other-taxes create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --reference: string # e.g. décla CFE
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/other-taxes"))
  let req_body = {"Amount": $amount, "DeclarationDate": $declaration_date, "DocumentId": $document_id, "Reference": $reference, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns identifiers/passwords of the folder
#
# GET /spaces/{spaceId}/folders/{id}/passwords
export def "spaces-folders-passwords list" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/passwords"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Write a identifier/password in aa folder
#
# POST /spaces/{spaceId}/folders/{id}/passwords
export def "spaces-folders-passwords create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. mon compte google
  designation: string # e.g. compte google
  --ident: string # e.g. test
  --link: string # e.g. www.google.fr
  --password: string # e.g. azerty
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/passwords"))
  let req_body = {"Comment": $comment, "Designation": $designation, "Ident": $ident, "Link": $link, "Password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a password
#
# DELETE /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "spaces-folders-passwords delete" [
  space_id: string
  id: string
  password_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), password_id: (encode-path-segment $password_id)} | format pattern "/spaces/{space_id}/folders/{id}/passwords/{password_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns password with Id
#
# GET /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "spaces-folders-passwords get" [
  space_id: string
  id: string
  password_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), password_id: (encode-path-segment $password_id)} | format pattern "/spaces/{space_id}/folders/{id}/passwords/{password_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Password
#
# PATCH /spaces/{spaceId}/folders/{id}/passwords/{passwordId}
export def "spaces-folders-passwords update" [
  space_id: string
  id: string
  password_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. mon compte google
  --designation: string # e.g. compte google
  --ident: string # e.g. test
  --link: string # e.g. www.google.fr
  --password: string # e.g. azerty
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), password_id: (encode-path-segment $password_id)} | format pattern "/spaces/{space_id}/folders/{id}/passwords/{password_id}"))
  let req_body = {"Comment": $comment, "Designation": $designation, "Ident": $ident, "Link": $link, "Password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns payrolls of the folder social
#
# GET /spaces/{spaceId}/folders/{id}/payrolls
export def "spaces-folders-payrolls get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --begin: string # begin date of the payrolls (e.g. 20160321,null)
  --end: string # end date of the payrolls (e.g. 20160321,null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Begin" $begin "scalar") (serialize-qp "End" $end "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/payrolls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payroll in a folder social
#
# POST /spaces/{spaceId}/folders/{id}/payrolls
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-payrolls create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --employee-contributions: float # format: float, e.g. 1352.63
  --employer-contributions: float # format: float, e.g. 132.63
  --end: string # e.g. 20160831
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/payrolls"))
  let req_body = {"Begin": $begin, "DocumentId": $document_id, "EmployeeContributions": $employee_contributions, "EmployerContributions": $employer_contributions, "End": $end, "NetAmount": $net_amount, "TotalGrossAmount": $total_gross_amount, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a nominative social declaration in a folder social
#
# DELETE /spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration
export def "spaces-folders-payrolls-nominative-social-declaration delete" [
  space_id: string
  id: string
  payroll_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), payroll_id: (encode-path-segment $payroll_id)} | format pattern "/spaces/{space_id}/folders/{id}/payrolls/{payroll_id}/nominative-social-declaration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a nominative social declaration in a folder social
#
# POST /spaces/{spaceId}/folders/{id}/payrolls/{payrollId}/nominative-social-declaration
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-payrolls-nominative-social-declaration create" [
  space_id: string
  id: string
  payroll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), payroll_id: (encode-path-segment $payroll_id)} | format pattern "/spaces/{space_id}/folders/{id}/payrolls/{payroll_id}/nominative-social-declaration"))
  let req_body = {"DocumentId": $document_id, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns payslips of the folder employee
#
# GET /spaces/{spaceId}/folders/{id}/payslips
export def "spaces-folders-payslips get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/payslips") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a payslip in a folder employee
#
# POST /spaces/{spaceId}/folders/{id}/payslips
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-payslips create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --employee-contributions: float # format: float, e.g. 2000.5
  --employer-contributions: float # format: float, e.g. 400.5
  --end: string # e.g. 20160831
  --fixed-gross-amount: float # format: float, e.g. 1352.63
  --net-amount: float # format: float, e.g. 1005.63
  --total-gross-amount: float # format: float, e.g. 1548.63
  --vacation: float # format: float, e.g. 20.5
  --variable-gross-amount: float # format: float, e.g. 132.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/payslips"))
  let req_body = {"Begin": $begin, "DocumentId": $document_id, "EmployeeContributions": $employee_contributions, "EmployerContributions": $employer_contributions, "End": $end, "FixedGrossAmount": $fixed_gross_amount, "NetAmount": $net_amount, "TotalGrossAmount": $total_gross_amount, "Vacation": $vacation, "VariableGrossAmount": $variable_gross_amount, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a secondary portfolio of a customer contract
#
# DELETE /spaces/{spaceId}/folders/{id}/portfolio/{portfolioId}
export def "spaces-folders-portfolio delete" [
  space_id: string
  id: string
  portfolio_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), portfolio_id: (encode-path-segment $portfolio_id)} | format pattern "/spaces/{space_id}/folders/{id}/portfolio/{portfolio_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete a Professional Vehicle
#
# DELETE /spaces/{spaceId}/folders/{id}/professional-vehicle
export def "spaces-folders-professional-vehicle delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/professional-vehicle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Professional Vehicle data
#
# PATCH /spaces/{spaceId}/folders/{id}/professional-vehicle
export def "spaces-folders-professional-vehicle update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --brand: string # e.g. Renault
  --comment: string # e.g. Peugeot Lyon
  --company-tax: oneof<nothing, bool> # e.g. true
  --date-in: string # e.g. 20201802
  --date-out: string # e.g. 20201802
  --designation: string # e.g. peugeot siège
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, clio]
  --level: string@level-completer # e.g. confidential
  --model: string # e.g. Clio
  --registration-date: string # e.g. 20181231
  --registration-number: string # e.g. AA001AA
  --type: string # e.g. car
  --value: float # e.g. 1500.23
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/professional-vehicle"))
  let req_body = {"About": $about, "Brand": $brand, "Comment": $comment, "CompanyTax": $company_tax, "DateIn": $date_in, "DateOut": $date_out, "Designation": $designation, "Home": $home, "Keywords": $keywords, "Level": $level, "Model": $model, "RegistrationDate": $registration_date, "RegistrationNumber": $registration_number, "Type": $type, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a provider
#
# DELETE /spaces/{spaceId}/folders/{id}/provider
export def "spaces-folders-provider delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/provider"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and provider data
#
# GET /spaces/{spaceId}/folders/{id}/provider
export def "spaces-folders-provider get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/provider"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Provider data
#
# PATCH /spaces/{spaceId}/folders/{id}/provider
export def "spaces-folders-provider update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --provider-number: string # e.g. 13587449420F
  --start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/provider"))
  let req_body = {"About": $about, "Comment": $comment, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "ProviderNumber": $provider_number, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# list of the required documents for a person
#
# GET /spaces/{spaceId}/folders/{id}/required-documents
export def "spaces-folders-required-documents get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/required-documents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the status of a requireddocument
#
# PATCH /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}
export def "spaces-folders-required-documents update" [
  space_id: string
  id: string
  requireddocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # e.g. waiting
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), requireddocumentid: (encode-path-segment $requireddocumentid)} | format pattern "/spaces/{space_id}/folders/{id}/required-documents/{requireddocumentid}"))
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add a required document to a line
#
# POST /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-required-documents create" [
  space_id: string
  id: string
  requireddocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: record # shape: {Content64Encoded?: string, Name?: string}
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), requireddocumentid: (encode-path-segment $requireddocumentid)} | format pattern "/spaces/{space_id}/folders/{id}/required-documents/{requireddocumentid}"))
  let req_body = {"File": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a document from a required document
#
# DELETE /spaces/{spaceId}/folders/{id}/required-documents/{requireddocumentid}/documents/{documentId}
export def "spaces-folders-required-documents-documents delete" [
  space_id: string
  id: string
  requireddocumentid: string
  document_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), requireddocumentid: (encode-path-segment $requireddocumentid), document_id: (encode-path-segment $document_id)} | format pattern "/spaces/{space_id}/folders/{id}/required-documents/{requireddocumentid}/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns sections of the folder
#
# GET /spaces/{spaceId}/folders/{id}/sections
export def "spaces-folders-sections get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/sections"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns social contracts of the folder employee
#
# GET /spaces/{spaceId}/folders/{id}/social-contracts
export def "spaces-folders-social-contracts get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-contracts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a social contract in a folder employee
#
# POST /spaces/{spaceId}/folders/{id}/social-contracts
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-social-contracts create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-date: string # e.g. 20190202
  --contract-duration: string # e.g. 6 mois
  --contractual-change: string # e.g. augmentation
  document_id: string # e.g. PBUFBAUBF1531
  --position: string # e.g. cadre
  --wage-developments: float # format: float, e.g. 1548.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-contracts"))
  let req_body = {"ContractDate": $contract_date, "ContractDuration": $contract_duration, "ContractualChange": $contractual_change, "DocumentId": $document_id, "Position": $position, "WageDevelopments": $wage_developments, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns social declarations
#
# GET /spaces/{spaceId}/folders/{id}/social-declarations
export def "spaces-folders-social-declarations get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-declarations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a social declaration
#
# POST /spaces/{spaceId}/folders/{id}/social-declarations
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-social-declarations create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # format: float, e.g. 132.63
  --declaration-date: string # e.g. 20160801
  document_id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-declarations"))
  let req_body = {"Amount": $amount, "DeclarationDate": $declaration_date, "DocumentId": $document_id, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a social regime
#
# DELETE /spaces/{spaceId}/folders/{id}/social-regimes
export def "spaces-folders-social-regimes delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-regimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and social regime data
#
# GET /spaces/{spaceId}/folders/{id}/social-regimes
export def "spaces-folders-social-regimes get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-regimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Social Regime data
#
# PATCH /spaces/{spaceId}/folders/{id}/social-regimes
export def "spaces-folders-social-regimes update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --periodicity: string@periodicity-completer # e.g. monthly
  --start: string # e.g. 20180630
  --type: string@type-completer-4 # e.g. mandatory
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/social-regimes"))
  let req_body = {"About": $about, "Comment": $comment, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "Periodicity": $periodicity, "Start": $start, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns sum of invoices of the folder (customer, provider, accountingyear or root folders customers or providers)
#
# GET /spaces/{spaceId}/folders/{id}/sum-invoices
export def "spaces-folders-sum-invoices get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: string # Number of the invoice (e.g. 23585)
  --incl-vat: float # amount incl. VAT (e.g. 100.50,101.50)
  --before-vat: float # amount before VAT (e.g. 102.50,101.50)
  --due-date: string # range date due payment (e.g. 20201231)
  --payment-date: string # range date of payment (e.g. 20201201,null)
  --invoice-date: string # range date of invoice (e.g. 20201201,null)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Number" $number "scalar") (serialize-qp "InclVat" $incl_vat "scalar") (serialize-qp "BeforeVAT" $before_vat "scalar") (serialize-qp "DueDate" $due_date "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "InvoiceDate" $invoice_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/sum-invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Folder (except Name, Class, ModificationDate and ArchivalDate) and tax contract data
#
# DELETE /spaces/{spaceId}/folders/{id}/tax-contract
export def "spaces-folders-tax-contract delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/tax-contract"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Folder (except Name, Class, ModificationDate and ArchivalDate) and Tax Contract data
#
# PATCH /spaces/{spaceId}/folders/{id}/tax-contract
export def "spaces-folders-tax-contract update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --archival-date: string # e.g. 20160203
  --comment: string # e.g. pieces company
  --designation: string # e.g. taxes foncières
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180630
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/tax-contract"))
  let req_body = {"About": $about, "ArchivalDate": $archival_date, "Comment": $comment, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns vat declarations
#
# GET /spaces/{spaceId}/folders/{id}/vat-declarations
export def "spaces-folders-vat-declarations get" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # range date of the documents (e.g. 20160321, null)
  --range: string # index range of the results (e.g. 10-19)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar") (serialize-qp "Range" $range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/vat-declarations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a vat declaration
#
# POST /spaces/{spaceId}/folders/{id}/vat-declarations
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders-vat-declarations create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --begin: string # e.g. 20160801
  --collected-vat: float # format: float, e.g. 1548.63
  --credit-vat: float # format: float, e.g. 400.5
  --deductible-vat: float # format: float, e.g. 20.5
  document_id: string # e.g. PBUFBAUBF1531
  end: string # e.g. 20160831
  --exempt-turnover: float # format: float, e.g. 132.63
  --number: string # e.g. 153126
  --payable-vat: float # format: float, e.g. 2000.5
  --taxable-turnover: float # format: float, e.g. 1352.63
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/folders/{id}/vat-declarations"))
  let req_body = {"Begin": $begin, "CollectedVAT": $collected_vat, "CreditVAT": $credit_vat, "DeductibleVAT": $deductible_vat, "DocumentId": $document_id, "End": $end, "ExemptTurnover": $exempt_turnover, "Number": $number, "PayableVAT": $payable_vat, "TaxableTurnover": $taxable_turnover, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete a class document
#
# DELETE /spaces/{spaceId}/folders/{id}/{documentClass}
export def "spaces-folders delete" [
  space_id: string
  id: string
  document_class: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), document_class: (encode-path-segment $document_class)} | format pattern "/spaces/{space_id}/folders/{id}/{document_class}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns document of documentClass (without specific data) of the folder
#
# GET /spaces/{spaceId}/folders/{id}/{documentClass}
export def "spaces-folders get-by-spaceId-id-documentClass" [
  space_id: string
  id: string
  document_class: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), document_class: (encode-path-segment $document_class)} | format pattern "/spaces/{space_id}/folders/{id}/{document_class}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a document in a folder
#
# POST /spaces/{spaceId}/folders/{id}/{documentClass}
# --Accounting shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
# --File shape: {Content64Encoded?: string, Name?: string}
export def "spaces-folders create" [
  space_id: string
  id: string
  document_class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string # e.g. PBUFBAUBF1531
  --accounting: record # shape: {AccountedOn?: string, Workbook?: "customer"|"provider"|"bank"|"cashWoucher"|"fiscal"|"insurance"|"social"|"other"|"permanent", YearMonth?: string}
  --author: string # e.g. Antoine Dupond
  --code: string # e.g. COD
  --comment: string # e.g. my document
  --date: string # e.g. 20161203
  file: record # shape: {Content64Encoded?: string, Name?: string}
  title: string # e.g. Facture décembre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), document_class: (encode-path-segment $document_class)} | format pattern "/spaces/{space_id}/folders/{id}/{document_class}"))
  let req_body = {"DocumentId": $document_id, "Accounting": $accounting, "Author": $author, "Code": $code, "Comment": $comment, "Date": $date, "File": $file, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of bank folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/banks
export def "spaces-legal-entities-banks get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/banks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a bank
#
# POST /spaces/{spaceId}/legal-entities/{id}/banks
export def "spaces-legal-entities-banks create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-reference: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/banks"))
  let req_body = {"About": $about, "Comment": $comment, "ContractReference": $contract_reference, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the banks even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/banks/all
export def "spaces-legal-entities-banks-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/banks/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all contract folders of the legal entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/contracts
export def "spaces-legal-entities-contracts get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/contracts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the others contract with legal entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/contractual-relationships
export def "spaces-legal-entities-contractual-relationships get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/contractual-relationships"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the others contract with legal entity (even archived)
#
# GET /spaces/{spaceId}/legal-entities/{id}/contractual-relationships/all
export def "spaces-legal-entities-contractual-relationships-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/contractual-relationships/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the customer
#
# GET /spaces/{spaceId}/legal-entities/{id}/customers
export def "spaces-legal-entities-customers get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/customers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a customer
#
# POST /spaces/{spaceId}/legal-entities/{id}/customers
export def "spaces-legal-entities-customers create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --portfolio-id: string # e.g. T1OJFOAZ7449420F
  --start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/customers"))
  let req_body = {"About": $about, "Comment": $comment, "CustomerNumber": $customer_number, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "PortfolioId": $portfolio_id, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the customers (even archived)
#
# GET /spaces/{spaceId}/legal-entities/{id}/customers/all
export def "spaces-legal-entities-customers-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/customers/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of insurance folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/insurances
export def "spaces-legal-entities-insurances get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/insurances"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a insurance
#
# POST /spaces/{spaceId}/legal-entities/{id}/insurances
export def "spaces-legal-entities-insurances create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --customer-number: string # e.g. 13587449420F
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --policy-number: string # e.g. 1358
  --start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/insurances"))
  let req_body = {"About": $about, "Comment": $comment, "CustomerNumber": $customer_number, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "PolicyNumber": $policy_number, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the insurances even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/insurances/all
export def "spaces-legal-entities-insurances-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/insurances/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the loan
#
# GET /spaces/{spaceId}/legal-entities/{id}/loans
export def "spaces-legal-entities-loans get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/loans"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a loan
#
# POST /spaces/{spaceId}/legal-entities/{id}/loans
export def "spaces-legal-entities-loans create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --amount: float # format: float, e.g. 1000
  --category: string@category-completer # e.g. debt spreading
  --comment: string # e.g. pieces company
  --designation: string # e.g. emprunt entreprise
  --due-amount: float # format: float, e.g. 1000.6
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --months-number: float # e.g. 12
  --rate: float # format: float, e.g. 2.5
  --start: string # e.g. 20180630
  --total-cost: float # format: float, e.g. 10200
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/loans"))
  let req_body = {"About": $about, "Amount": $amount, "Category": $category, "Comment": $comment, "Designation": $designation, "DueAmount": $due_amount, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "MonthsNumber": $months_number, "Rate": $rate, "Start": $start, "TotalCost": $total_cost} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the loans even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/loans/all
export def "spaces-legal-entities-loans-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/loans/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of providers folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/providers
export def "spaces-legal-entities-providers get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/providers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a provider
#
# POST /spaces/{spaceId}/legal-entities/{id}/providers
export def "spaces-legal-entities-providers create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --provider-number: string # e.g. 13587449420F
  --start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/providers"))
  let req_body = {"About": $about, "Comment": $comment, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "ProviderNumber": $provider_number, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the providers even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/providers/all
export def "spaces-legal-entities-providers-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/providers/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of social regimes folders for a legal-entity
#
# GET /spaces/{spaceId}/legal-entities/{id}/social-regimes
export def "spaces-legal-entities-social-regimes get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/social-regimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a social regime
#
# POST /spaces/{spaceId}/legal-entities/{id}/social-regimes
export def "spaces-legal-entities-social-regimes create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --designation: string # e.g. client pièces détachées
  --end: string # e.g. 20190101
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --periodicity: string@periodicity-completer # e.g. monthly
  --start: string # e.g. 20180630
  --type: string@type-completer-4 # e.g. mandatory
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/social-regimes"))
  let req_body = {"About": $about, "Comment": $comment, "Designation": $designation, "End": $end, "Home": $home, "Keywords": $keywords, "Level": $level, "Periodicity": $periodicity, "Start": $start, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the social regimes even archived
#
# GET /spaces/{spaceId}/legal-entities/{id}/social-regimes/all
export def "spaces-legal-entities-social-regimes-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/legal-entities/{id}/social-regimes/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of all loan folders of the space
#
# GET /spaces/{spaceId}/loans
export def "spaces-loans get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/loans"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of all loan folders even archived of the space
#
# GET /spaces/{spaceId}/loans/all
export def "spaces-loans-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/loans/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify the invitation of a person to collect documents
#
# PATCH /spaces/{spaceId}/persons/{id}/call-for-document
export def "spaces-persons-call-for-document update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string>
  --client-management: string@client-management-completer
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/call-for-document"))
  let req_body = {"Categories": $categories, "ClientManagement": $client_management, "IsAdmin": $is_admin, "Player": $player, "PlayerEnd": $player_end} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# invite a person to collect documents
#
# POST /spaces/{spaceId}/persons/{id}/call-for-document
export def "spaces-persons-call-for-document create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # e.g. [ID, Invoices]
  --client-management: string@client-management-completer
  --comment: string # e.g. first invitation
  --contact: string # e.g. Dupond
  --is-admin: oneof<nothing, bool> # e.g. true
  --message: string # e.g. <p> Bienvenue dans l'espace de l'entreprise SOCIETE </p>
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
  --signature: string # e.g. cordialement
  --subject: string # e.g. invitation sur le coffre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/call-for-document"))
  let req_body = {"Categories": $categories, "ClientManagement": $client_management, "Comment": $comment, "Contact": $contact, "IsAdmin": $is_admin, "Message": $message, "Player": $player, "PlayerEnd": $player_end, "Signature": $signature, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of the employee
#
# GET /spaces/{spaceId}/persons/{id}/employees
export def "spaces-persons-employees get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/employees"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a folder for a employee
#
# POST /spaces/{spaceId}/persons/{id}/employees
export def "spaces-persons-employees create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. <b> Mon premier dossier </b>
  --comment: string # e.g. pieces company
  --contract-type: string # e.g. 01
  --employee-number: string # e.g. 13587FAZCD420F
  --end: string # e.g. 20190101
  --function: string # e.g. commercial
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
  --postal-mail: oneof<nothing, bool> # e.g. true
  --ss-number: string # e.g. 1542012365985215
  --start: string # e.g. 20180630
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/employees"))
  let req_body = {"About": $about, "Comment": $comment, "ContractType": $contract_type, "EmployeeNumber": $employee_number, "End": $end, "Function": $function, "Home": $home, "Keywords": $keywords, "Level": $level, "PostalMail": $postal_mail, "SSNumber": $ss_number, "Start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder of all employees (even archived)
#
# GET /spaces/{spaceId}/persons/{id}/employees/all
export def "spaces-persons-employees-all get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/employees/all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder exchange of the person
#
# GET /spaces/{spaceId}/persons/{id}/exchange
export def "spaces-persons-exchange get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/exchange"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder of the person
#
# GET /spaces/{spaceId}/persons/{id}/follow-ups
export def "spaces-persons-follow-ups get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/follow-ups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# delete the invitation of a person in a space
#
# DELETE /spaces/{spaceId}/persons/{id}/guest-in-space
export def "spaces-persons-guest-in-space delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/guest-in-space"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# invite a person in a space
#
# PATCH /spaces/{spaceId}/persons/{id}/guest-in-space
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-guest-in-space update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-management: string@client-management-completer
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/guest-in-space"))
  let req_body = {"ClientManagement": $client_management, "Folders": $folders, "GroupIds": $group_ids, "IsAdmin": $is_admin, "Player": $player, "PlayerEnd": $player_end} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# invite a person in a space
#
# POST /spaces/{spaceId}/persons/{id}/guest-in-space
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-guest-in-space create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-management: string@client-management-completer
  --comment: string # e.g. first invitation
  --contact: string # e.g. Dupond
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --member-id: string # e.g. PAIHIHFA79TFA
  --message: string # e.g. <p> Bienvenue dans l'espace de l'entreprise SOCIETE </p>
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
  --signature: string # e.g. cordialement
  --subject: string # e.g. invitation sur le coffre
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/guest-in-space"))
  let req_body = {"ClientManagement": $client_management, "Comment": $comment, "Contact": $contact, "Folders": $folders, "GroupIds": $group_ids, "IsAdmin": $is_admin, "MemberId": $member_id, "Message": $message, "Player": $player, "PlayerEnd": $player_end, "Signature": $signature, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# delete the invitation of a person in a space
#
# DELETE /spaces/{spaceId}/persons/{id}/invitation
export def "spaces-persons-invitation delete" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/invitation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns invitation of a person
#
# GET /spaces/{spaceId}/persons/{id}/invitation
export def "spaces-persons-invitation get" [
  space_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/invitation"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify an invitation
#
# PATCH /spaces/{spaceId}/persons/{id}/invitation
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-invitation update" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-management: string@client-management-completer
  --employee-access: oneof<nothing, bool> # e.g. true
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/invitation"))
  let req_body = {"ClientManagement": $client_management, "EmployeeAccess": $employee_access, "Folders": $folders, "GroupIds": $group_ids, "IsAdmin": $is_admin, "Player": $player, "PlayerEnd": $player_end} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# create an invitation in a space for a person
#
# POST /spaces/{spaceId}/persons/{id}/invitation
# --Folders item shape: {Id?: string, Right?: "read"|"write"}
export def "spaces-persons-invitation create" [
  space_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-management: string@client-management-completer
  --employee-access: oneof<nothing, bool> # e.g. true
  --folders: list # item shape: {Id?: string, Right?: "read"|"write"}
  --group-ids: list<string>
  --is-admin: oneof<nothing, bool> # e.g. true
  --player: string@player-completer # e.g. guest
  --player-end: string # e.g. 20190601
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{id}/invitation"))
  let req_body = {"ClientManagement": $client_management, "EmployeeAccess": $employee_access, "Folders": $folders, "GroupIds": $group_ids, "IsAdmin": $is_admin, "Player": $player, "PlayerEnd": $player_end} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# send the invitation of a person in a space
#
# POST /spaces/{spaceId}/persons/{id}/invitation/{invitationId}/send
export def "spaces-persons-invitation-send create" [
  space_id: string
  id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact: string # e.g. Dupond
  --message: string # e.g. <p> Bienvenue dans l'espace de l'envtreprise SOCIETE </p>
  --signature: string # e.g. cordialement
  --subject: string # e.g. invitation sur le coffre
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), id: (encode-path-segment $id), invitation_id: (encode-path-segment $invitation_id)} | format pattern "/spaces/{space_id}/persons/{id}/invitation/{invitation_id}/send"))
  let req_body = {"Contact": $contact, "Message": $message, "Signature": $signature, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folderId with the access of the person
#
# GET /spaces/{spaceId}/persons/{memberId}/folders/{id}
export def "spaces-persons-folders get" [
  space_id: string
  member_id: string
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
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), member_id: (encode-path-segment $member_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{member_id}/folders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an access
#
# PATCH /spaces/{spaceId}/persons/{memberId}/folders/{id}
export def "spaces-persons-folders update" [
  space_id: string
  member_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --right: string@right-completer-1 # e.g. write
  --about: string # e.g. <b> Mon premier dossier </b>
  --home: oneof<nothing, bool> # e.g. yes
  --keywords: list<string> # e.g. [paris, comptabilité]
  --level: string@level-completer # e.g. confidential
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id), member_id: (encode-path-segment $member_id), id: (encode-path-segment $id)} | format pattern "/spaces/{space_id}/persons/{member_id}/folders/{id}"))
  let req_body = {"Right": $right, "About": $about, "Home": $home, "Keywords": $keywords, "Level": $level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns folder with Id and provider data
#
# GET /spaces/{spaceId}/providers
export def "spaces-providers get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/providers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and provider data (even archived)
#
# GET /spaces/{spaceId}/providers/all
export def "spaces-providers-all get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/providers/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Research text inside documents, folders or messages
#
# GET /spaces/{spaceId}/search
export def "spaces-search get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Text to find (e.g. durand)
  --range: string # index range of the results (e.g. 10-19)
  --query-context: record # context of research
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Query" $query "scalar") (serialize-qp "Range" $range "scalar") (serialize-qp "QueryContext" $query_context "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and social regime data
#
# GET /spaces/{spaceId}/social-regimes
export def "spaces-social-regimes get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/social-regimes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns folder with Id and social regime data (even archived)
#
# GET /spaces/{spaceId}/social-regimes/all
export def "spaces-social-regimes-all get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-contracting-partner: string # if present returns infos of the ContractingPartner too
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "WithContractingPartner" $with_contracting_partner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/social-regimes/all") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns CSV Invoicings of the spaces for the account of the spaceId
#
# GET /spaces/{spaceId}/spaces-invoicings
export def "spaces-spaces-invoicings get" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # date range of the documents (e.g. 20160321,null)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({space_id: (encode-path-segment $space_id)} | format pattern "/spaces/{space_id}/spaces-invoicings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
