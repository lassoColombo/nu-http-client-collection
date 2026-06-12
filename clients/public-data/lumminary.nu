# Auto-generated client for Lumminary API v1.0
# Source: https://api.apis.guru/v2/specs/lumminary.com/1.0/swagger.json
# Auth: --token flag or $env.LUMMINARY_API_TOKEN

const BASE_URL = "https://api.lumminary.com/v1"
const DEFAULT_AUTH = "jwt"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LUMMINARY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "jwt" => { {headers: {Authorization: $"JWT ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.lumminary.com/v1"] }
def auth-scheme-completer [] { ["jwt"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-jwt auth" } } | get name | first)
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

# General-purpose authentication
#
# POST /auth/jwt
# operationId: post_jwt_auth
export def "auth-jwt auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
  username: string # The email for a Client, or the API for a partner product
  password: string # The passowrd for a Client, or the API key for a service
  role: string # The role for which authentication will be made. Value : role_product
]: any -> record<access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt")
  let body = {username: $username, password: $password, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get gene by symbol
#
# GET /clients/{clientId}/datasets/{datasetId}/genes/{geneSymbol}
# operationId: get_client_gene
export def "clients-datasets-genes gene" [
  clientId: string
  datasetId: string
  geneSymbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> record<molecular_location: record<chromosome_accession: string, start: int, stop: int>, snps: table<chromosome_accession: string, genotyped_alleles: list, location: int, phased: bool, reference_genome: string, snp_id: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($clientId)/datasets/($datasetId)/genes/($geneSymbol)")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /clients/{clientId}/datasets/{datasetId}/snps/
#
# operationId: get_client_snp_group
export def "clients-datasets-snps group-by-clientId-datasetId" [
  clientId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> table<chromosome_accession: string, genotyped_alleles: list<string>, location: int, phased: bool, reference_genome: string, snp_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($clientId)/datasets/($datasetId)/snps/")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a large group of SNPs
#
# POST /clients/{clientId}/datasets/{datasetId}/snps/
# operationId: post_client_snp_group
export def "clients-datasets-snps group-by-clientId-datasetId-1" [
  clientId: string
  datasetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
  snps: string # JSON-encoded list of snps to be fetched
]: any -> table<chromosome_accession: string, genotyped_alleles: list<string>, location: int, phased: bool, reference_genome: string, snp_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($clientId)/datasets/($datasetId)/snps/")
  let body = {snps: $snps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get SNP information
#
# GET /clients/{clientId}/datasets/{datasetId}/snps/{snpId}
# operationId: get_client_snp
export def "clients-datasets-snps snp" [
  clientId: string
  datasetId: string
  snpId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> record<chromosome_accession: string, genotyped_alleles: list<string>, location: int, phased: bool, reference_genome: string, snp_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/clients/($clientId)/datasets/($datasetId)/snps/($snpId)")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product details
#
# GET /products/{productId}
# operationId: get_product
export def "products product" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> record<authorized_scopes: list<string>, email: string, product_uuid: string, redirect_uri: string, snps_authorized: list<string>, snps_authorized_any: bool, snps_min_required: record<min_pct: int, snps: list<string>>, snps_min_required_any: bool> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($productId)")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /products/{productId}/authorizations
#
# operationId: get_authorizations_queue
export def "products-authorizations queue" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --seq-num-start: string # The first sequence number from which to fetch (the sequence number of the last processed authorization)
  --X-Fields: string # An optional fields mask
]: nothing -> table<authorization_uuid: string, client_uuid: string, create_timestamp: int, is_active: bool, order: string, product_uuid: string, report_credentials: list<record>, report_files: list<record>, scopes: record<address: record, dataset: string, email: string, login: string, name: record, sex: string>, sequence_number: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seq_num_start" $seq_num_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($productId)/authorizations" $qp)
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /products/{productId}/authorizations/{authorizationId}
#
# operationId: get_product_authorization
export def "products-authorizations authorization-by-productId-authorizationId" [
  productId: string
  authorizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> record<authorization_uuid: string, client_uuid: string, create_timestamp: int, is_active: bool, order: string, product_uuid: string, report_credentials: table<authorization_uuid: string, client_password: string, client_username: string, create_timestamp: int, report_credentials_uuid: string, report_url: string>, report_files: table<authorization_uuid: string, create_timestamp: int, file_location: record, report_file_uuid: string>, scopes: record<address: record<address1: string, address2: string, city: string, country: string, phone: string, state: string, zipcode: string>, dataset: string, email: string, login: string, name: record<first_name: string, last_name: string>, sex: string>, sequence_number: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($productId)/authorizations/($authorizationId)")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Signal that processing is complete, without uploading any result
#
# POST /products/{productId}/authorizations/{authorizationId}
# operationId: post_product_authorization
export def "products-authorizations authorization-by-productId-authorizationId-1" [
  productId: string
  authorizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($productId)/authorizations/($authorizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provide a result for the authorization
#
# POST /products/{productId}/authorizations/{authorizationId}/credentials
# operationId: post_authorization_result_credentials
export def "products-authorizations-credentials credentials" [
  productId: string
  authorizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
  --credentials-username: string # Credentials for accessing the result. Includes password, username and url
  --credentials-password: string # Credentials for accessing the result. Includes password, username and url
  --report-url: string # Credentials for accessing the result. Includes password, username and url
]: any -> record<authorization_uuid: string, client_password: string, client_username: string, create_timestamp: int, report_credentials_uuid: string, report_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($productId)/authorizations/($authorizationId)/credentials")
  let body = {credentials_username: $credentials_username, credentials_password: $credentials_password, report_url: $report_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Provide a file result to the authorization, e
#
# POST /products/{productId}/authorizations/{authorizationId}/file
# operationId: post_authorization_result_file
export def "products-authorizations-file file" [
  productId: string
  authorizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --original-filename: string # Optional original filename for the report. If not provided, the filename of uploaded file will be used
  --X-Fields: string # An optional fields mask
  --file-report: path # A binary file (e.g. pdf) that contains the result of the authorization
]: any -> record<authorization_uuid: string, create_timestamp: int, file_location: record<filename_original: string, host: string, path: string>, report_file_uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "original_filename" $original_filename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($productId)/authorizations/($authorizationId)/file" $qp)
  let body = {file_report: $file_report} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file_report | is-not-empty) { $body | upsert file_report (open -r $file_report) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Catch-all Authorization state, for authorizations that passed all verifications and should reach the partner Product, but cannot be fulfilled for various reasons
#
# POST /products/{productId}/authorizations/{authorizationId}/unfulfillable
# operationId: post_product_authorization_unfulfillable
export def "products-authorizations-unfulfillable unfulfillable" [
  productId: string
  authorizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($productId)/authorizations/($authorizationId)/unfulfillable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generic gene information
#
# GET /reference/genes/databases/{databaseName}/accessions/{accession}
# operationId: get_gene
export def "reference-genes-databases-accessions gene" [
  databaseName: string
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbsnp-build: int # The dbSNP build for which to consider snps belonging to the gene. Defaults to 149 (default: 149)
  --reference-genome: string # The reference genome for which gene annotations will be returned. Defaults to GRCh37p13 (default: GRCH37P13)
  --X-Fields: string # An optional fields mask
]: nothing -> record<chromosome: string, molecular_end_position: int, molecular_start_position: int, parent_accession: string, snp_ids: list<string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dbsnp_build" $dbsnp_build "scalar") (serialize-qp "reference_genome" $reference_genome "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reference/genes/databases/($databaseName)/accessions/($accession)" $qp)
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reference genome builds
#
# GET /reference/genomes/
# operationId: get_reference_genomes_group
export def "reference-genomes group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> table<reference_accession: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reference/genomes/")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reference genome metadata
#
# GET /reference/genomes/{genomeBuildAccession}/chromosomes
# operationId: get_reference_genome
export def "reference-genomes-chromosomes genome" [
  genomeBuildAccession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Fields: string # An optional fields mask
]: nothing -> table<reference_accession: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reference/genomes/($genomeBuildAccession)/chromosomes")
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sequence for a region of the reference genome
#
# GET /reference/genomes/{genomeBuildAccession}/chromosomes/{chromosomeAccession}
# operationId: get_reference_chromosome
export def "reference-genomes-chromosomes chromosome" [
  genomeBuildAccession: string
  chromosomeAccession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --range-start: int # Location on the chromosome
  --range-stop: int # Location on the chromosome
  --X-Fields: string # An optional fields mask
]: nothing -> record<sequence: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "range_start" $range_start "scalar") (serialize-qp "range_stop" $range_stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reference/genomes/($genomeBuildAccession)/chromosomes/($chromosomeAccession)" $qp)
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reference SNP data
#
# GET /reference/snps/{snpAccession}
# operationId: get_reference_snp
export def "reference-snps snp" [
  snpAccession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbsnp-version: int # The dbSNP build. Defaults to 149 (default: 149)
  --grch-version: string # The GRCh build on which to place snips. Defaults to GRCh37p13 (default: GRCH37P13)
  --X-Fields: string # An optional fields mask
]: nothing -> record<alternative_alleles: list<string>, chromosome: string, chromosome_accession: string, dbsnp_version: int, location: int, reference_allele: string, reference_genome: string, snp_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dbsnp_version" $dbsnp_version "scalar") (serialize-qp "grch_version" $grch_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reference/snps/($snpAccession)" $qp)
  let extra_headers = {"X-Fields": $X_Fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
