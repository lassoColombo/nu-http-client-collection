# Auto-generated client for Lumminary API v1.0
# Source: https://api.apis.guru/v2/specs/lumminary.com/1.0/swagger.json
# Auth: --token flag or $env.LUMMINARY_API_TOKEN

const BASE_URL = "https://api.lumminary.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LUMMINARY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "jwt" => { {scheme: $scheme, headers: {Authorization: $"JWT ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.lumminary.com/v1"] }
def auth-scheme-completer [] { ["jwt" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-jwt create" } } | get name | first)
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
export def "auth-jwt create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  username: string # The email for a Client, or the API for a partner product
  password: string # The passowrd for a Client, or the API key for a service
  role: string # The role for which authentication will be made. Value : role_product
]: any -> record<access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/jwt" $auth.query)
  let req_body = {"username": $username, "password": $password, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get gene by symbol
#
# GET /clients/{clientId}/datasets/{datasetId}/genes/{geneSymbol}
# operationId: get_client_gene
export def "clients-datasets-genes get" [
  client_id: string
  dataset_id: string
  gene_symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<molecular_location: record<chromosome_accession: string, start: int, stop: int>, snps: table<chromosome_accession: string, genotyped_alleles: list, location: int, phased: bool, reference_genome: string, snp_id: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($gene_symbol | is-empty) { error make --unspanned { msg: "path parameter 'geneSymbol' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id), dataset_id: (encode-path-segment $dataset_id), gene_symbol: (encode-path-segment $gene_symbol)} | format pattern "/clients/{client_id}/datasets/{dataset_id}/genes/{gene_symbol}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /clients/{clientId}/datasets/{datasetId}/snps/
#
# operationId: get_client_snp_group
export def "clients-datasets-snps get-group" [
  client_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<chromosome_accession: string, genotyped_alleles: list<string>, location: int, phased: bool, reference_genome: string, snp_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/clients/{client_id}/datasets/{dataset_id}/snps/") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a large group of SNPs
#
# POST /clients/{clientId}/datasets/{datasetId}/snps/
# operationId: post_client_snp_group
export def "clients-datasets-snps create-group" [
  client_id: string
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  snps: string # JSON-encoded list of snps to be fetched
]: any -> table<chromosome_accession: string, genotyped_alleles: list<string>, location: int, phased: bool, reference_genome: string, snp_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id), dataset_id: (encode-path-segment $dataset_id)} | format pattern "/clients/{client_id}/datasets/{dataset_id}/snps/") $auth.query)
  let req_body = {"snps": $snps} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get SNP information
#
# GET /clients/{clientId}/datasets/{datasetId}/snps/{snpId}
# operationId: get_client_snp
export def "clients-datasets-snps get" [
  client_id: string
  dataset_id: string
  snp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<chromosome_accession: string, genotyped_alleles: list<string>, location: int, phased: bool, reference_genome: string, snp_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  if ($dataset_id | is-empty) { error make --unspanned { msg: "path parameter 'datasetId' must be non-empty" } }
  if ($snp_id | is-empty) { error make --unspanned { msg: "path parameter 'snpId' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id), dataset_id: (encode-path-segment $dataset_id), snp_id: (encode-path-segment $snp_id)} | format pattern "/clients/{client_id}/datasets/{dataset_id}/snps/{snp_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get product details
#
# GET /products/{productId}
# operationId: get_product
export def "products get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<authorized_scopes: list<string>, email: string, product_uuid: string, redirect_uri: string, snps_authorized: list<string>, snps_authorized_any: bool, snps_min_required: record<min_pct: int, snps: list<string>>, snps_min_required_any: bool> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /products/{productId}/authorizations
#
# operationId: get_authorizations_queue
export def "products-authorizations get-queue" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --seq-num-start: string # The first sequence number from which to fetch (the sequence number of the last processed authorization)
  --x-fields: string # An optional fields mask
]: nothing -> table<authorization_uuid: string, client_uuid: string, create_timestamp: int, is_active: bool, order: string, product_uuid: string, report_credentials: list<record>, report_files: list<record>, scopes: record<address: record, dataset: string, email: string, login: string, name: record, sex: string>, sequence_number: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let qp = [(serialize-qp "seq_num_start" $seq_num_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}/authorizations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"seq_num_start": $seq_num_start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /products/{productId}/authorizations/{authorizationId}
#
# operationId: get_product_authorization
export def "products-authorizations get" [
  product_id: string
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> record<authorization_uuid: string, client_uuid: string, create_timestamp: int, is_active: bool, order: string, product_uuid: string, report_credentials: table<authorization_uuid: string, client_password: string, client_username: string, create_timestamp: int, report_credentials_uuid: string, report_url: string>, report_files: table<authorization_uuid: string, create_timestamp: int, file_location: record, report_file_uuid: string>, scopes: record<address: record<address1: string, address2: string, city: string, country: string, phone: string, state: string, zipcode: string>, dataset: string, email: string, login: string, name: record<first_name: string, last_name: string>, sex: string>, sequence_number: int, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($authorization_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizationId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), authorization_id: (encode-path-segment $authorization_id)} | format pattern "/products/{product_id}/authorizations/{authorization_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Signal that processing is complete, without uploading any result
#
# POST /products/{productId}/authorizations/{authorizationId}
# operationId: post_product_authorization
export def "products-authorizations create" [
  product_id: string
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($authorization_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizationId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), authorization_id: (encode-path-segment $authorization_id)} | format pattern "/products/{product_id}/authorizations/{authorization_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Provide a result for the authorization
#
# POST /products/{productId}/authorizations/{authorizationId}/credentials
# operationId: post_authorization_result_credentials
export def "products-authorizations-credentials create-result" [
  product_id: string
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
  --credentials-username: string # Credentials for accessing the result. Includes password, username and url
  --credentials-password: string # Credentials for accessing the result. Includes password, username and url
  --report-url: string # Credentials for accessing the result. Includes password, username and url
]: any -> record<authorization_uuid: string, client_password: string, client_username: string, create_timestamp: int, report_credentials_uuid: string, report_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($authorization_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizationId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), authorization_id: (encode-path-segment $authorization_id)} | format pattern "/products/{product_id}/authorizations/{authorization_id}/credentials") $auth.query)
  let req_body = {"credentials_username": $credentials_username, "credentials_password": $credentials_password, "report_url": $report_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200 201]
}

# Provide a file result to the authorization, e
#
# POST /products/{productId}/authorizations/{authorizationId}/file
# operationId: post_authorization_result_file
export def "products-authorizations-file create-result" [
  product_id: string
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --original-filename: string # Optional original filename for the report. If not provided, the filename of uploaded file will be used
  --x-fields: string # An optional fields mask
  --file-report: path # A binary file (e.g. pdf) that contains the result of the authorization
]: any -> record<authorization_uuid: string, create_timestamp: int, file_location: record<filename_original: string, host: string, path: string>, report_file_uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($authorization_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizationId' must be non-empty" } }
  let qp = [(serialize-qp "original_filename" $original_filename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), authorization_id: (encode-path-segment $authorization_id)} | format pattern "/products/{product_id}/authorizations/{authorization_id}/file") $qp $auth.query)
  let req_body = {"file_report": $file_report} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file_report"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: ({"original_filename": $original_filename} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200 201]
}

# Catch-all Authorization state, for authorizations that passed all verifications and should reach the partner Product, but cannot be fulfilled for various reasons
#
# POST /products/{productId}/authorizations/{authorizationId}/unfulfillable
# operationId: post_product_authorization_unfulfillable
export def "products-authorizations-unfulfillable create" [
  product_id: string
  authorization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($authorization_id | is-empty) { error make --unspanned { msg: "path parameter 'authorizationId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), authorization_id: (encode-path-segment $authorization_id)} | format pattern "/products/{product_id}/authorizations/{authorization_id}/unfulfillable") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full []
}

# Generic gene information
#
# GET /reference/genes/databases/{databaseName}/accessions/{accession}
# operationId: get_gene
export def "reference-genes-databases-accessions get" [
  database_name: string
  accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbsnp-build: int # The dbSNP build for which to consider snps belonging to the gene. Defaults to 149 (default: 149)
  --reference-genome: string # The reference genome for which gene annotations will be returned. Defaults to GRCh37p13 (default: GRCH37P13)
  --x-fields: string # An optional fields mask
]: nothing -> record<chromosome: string, molecular_end_position: int, molecular_start_position: int, parent_accession: string, snp_ids: list<string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'databaseName' must be non-empty" } }
  if ($accession | is-empty) { error make --unspanned { msg: "path parameter 'accession' must be non-empty" } }
  let qp = [(serialize-qp "dbsnp_build" $dbsnp_build "scalar") (serialize-qp "reference_genome" $reference_genome "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({database_name: (encode-path-segment $database_name), accession: (encode-path-segment $accession)} | format pattern "/reference/genes/databases/{database_name}/accessions/{accession}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dbsnp_build": $dbsnp_build, "reference_genome": $reference_genome} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reference genome builds
#
# GET /reference/genomes/
# operationId: get_reference_genomes_group
export def "reference-genomes get-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<reference_accession: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reference/genomes/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reference genome metadata
#
# GET /reference/genomes/{genomeBuildAccession}/chromosomes
# operationId: get_reference_genome
export def "reference-genomes-chromosomes list" [
  genome_build_accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-fields: string # An optional fields mask
]: nothing -> table<reference_accession: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($genome_build_accession | is-empty) { error make --unspanned { msg: "path parameter 'genomeBuildAccession' must be non-empty" } }
  let full_url = (build-url $base ({genome_build_accession: (encode-path-segment $genome_build_accession)} | format pattern "/reference/genomes/{genome_build_accession}/chromosomes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sequence for a region of the reference genome
#
# GET /reference/genomes/{genomeBuildAccession}/chromosomes/{chromosomeAccession}
# operationId: get_reference_chromosome
export def "reference-genomes-chromosomes get" [
  genome_build_accession: string
  chromosome_accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --range-start: int # Location on the chromosome
  --range-stop: int # Location on the chromosome
  --x-fields: string # An optional fields mask
]: nothing -> record<sequence: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($genome_build_accession | is-empty) { error make --unspanned { msg: "path parameter 'genomeBuildAccession' must be non-empty" } }
  if ($chromosome_accession | is-empty) { error make --unspanned { msg: "path parameter 'chromosomeAccession' must be non-empty" } }
  let qp = [(serialize-qp "range_start" $range_start "scalar") (serialize-qp "range_stop" $range_stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({genome_build_accession: (encode-path-segment $genome_build_accession), chromosome_accession: (encode-path-segment $chromosome_accession)} | format pattern "/reference/genomes/{genome_build_accession}/chromosomes/{chromosome_accession}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"range_start": $range_start, "range_stop": $range_stop} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reference SNP data
#
# GET /reference/snps/{snpAccession}
# operationId: get_reference_snp
export def "reference-snps get" [
  snp_accession: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbsnp-version: int # The dbSNP build. Defaults to 149 (default: 149)
  --grch-version: string # The GRCh build on which to place snips. Defaults to GRCh37p13 (default: GRCH37P13)
  --x-fields: string # An optional fields mask
]: nothing -> record<alternative_alleles: list<string>, chromosome: string, chromosome_accession: string, dbsnp_version: int, location: int, reference_allele: string, reference_genome: string, snp_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  if ($snp_accession | is-empty) { error make --unspanned { msg: "path parameter 'snpAccession' must be non-empty" } }
  let qp = [(serialize-qp "dbsnp_version" $dbsnp_version "scalar") (serialize-qp "grch_version" $grch_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({snp_accession: (encode-path-segment $snp_accession)} | format pattern "/reference/snps/{snp_accession}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Fields": $x_fields} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dbsnp_version": $dbsnp_version, "grch_version": $grch_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
