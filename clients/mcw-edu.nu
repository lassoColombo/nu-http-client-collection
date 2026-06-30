# Auto-generated client for Rat Genome Database REST API v1.1
# Source: https://api.apis.guru/v2/specs/mcw.edu/1.1/openapi.json
# Auth: --token flag or $env.RAT_GENOME_DATABASE_REST_API_TOKEN

const BASE_URL = "http://localhost//rest.rgd.mcw.edu/rgdws"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o RAT_GENOME_DATABASE_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost//rest.rgd.mcw.edu/rgdws"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "agr-affected-genomic-models get-using" } } | get name | first)
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

# Get affected genomic models (rat strains with gene alleles) submitted by RGD to AGR by taxonId
#
# GET /agr/affectedGenomicModels/{taxonId}
# operationId: getAffectedGenomicModelsUsingGET
export def "agr-affected-genomic-models get-using" [
  taxon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonId' must be non-empty" } }
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/affectedGenomicModels/{taxon_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get gene allele records submitted by RGD to AGR by taxonId
#
# GET /agr/alleles/{taxonId}
# operationId: getAllelesForTaxonUsingGET
export def "agr-alleles get-for-taxon-using" [
  taxon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonId' must be non-empty" } }
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/alleles/{taxon_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get expression annotations submitted by RGD to AGR by taxonId
#
# GET /agr/expression/{taxonId}
# operationId: getExpressionForTaxonUsingGET
export def "agr-expression get-for-taxon-using" [
  taxon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonId' must be non-empty" } }
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/expression/{taxon_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get phenotype annotations submitted by RGD to AGR by taxonId
#
# GET /agr/phenotypes/{taxonId}
# operationId: getPhenotypesForTaxonUsingGET
export def "agr-phenotypes get-for-taxon-using" [
  taxon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonId' must be non-empty" } }
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/phenotypes/{taxon_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get basic variant records submitted by RGD to AGR by taxonId
#
# GET /agr/variants/{taxonId}
# operationId: getVariantsForTaxonUsingGET
export def "agr-variants get-for-taxon-using" [
  taxon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonId' must be non-empty" } }
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/variants/{taxon_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get gene records submitted by RGD to AGR by taxonId
#
# GET /agr/{taxonId}
# operationId: getGenesForLatestAssemblyUsingGET
export def "agr get-genes-for-latest-assembly-using" [
  taxon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxon_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonId' must be non-empty" } }
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/{taxon_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes annotated to an ontology term
#
# POST /annotations/
# operationId: getAnnotationsUsingPOST
export def "annotations get-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-codes: list<string>
  --ids: list<string>
  --species-type-keys: list<int>
  --term-acc: string
]: any -> table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotations/" $auth.query)
  let req_body = {"evidenceCodes": $evidence_codes, "ids": $ids, "speciesTypeKeys": $species_type_keys, "termAcc": $term_acc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Returns a list ontology term accession IDs annotated to an rgd object
#
# GET /annotations/accId/{rgdId}
# operationId: getTermAccIdsUsingGET
export def "annotations-acc-id get-term-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<keyValue: string, stringValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/annotations/accId/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns annotation count for ontology accession ID
#
# GET /annotations/count/{accId}/{includeChildren}
# operationId: getAnnotationCountByAccIdUsingGET
export def "annotations-count get-by-acc-using" [
  acc_id: string
  include_children: bool
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($include_children | is-empty) { error make --unspanned { msg: "path parameter 'includeChildren' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), include_children: (encode-path-segment $include_children)} | format pattern "/annotations/count/{acc_id}/{include_children}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns annotation count for ontology accession ID and speicies
#
# GET /annotations/count/{accId}/{speciesTypeKey}/{includeChildren}
# operationId: getAnnotationCountByAccIdAndSpeciesUsingGET
export def "annotations-count get-by-acc-and-species-using" [
  acc_id: string
  species_type_key: int
  include_children: bool
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($include_children | is-empty) { error make --unspanned { msg: "path parameter 'includeChildren' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key), include_children: (encode-path-segment $include_children)} | format pattern "/annotations/count/{acc_id}/{species_type_key}/{include_children}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns annotation count for ontology accession ID and object type
#
# GET /annotations/count/{accId}/{speciesTypeKey}/{includeChildren}/{objectType}
# operationId: getAnnotationCountByAccIdAndObjectTypeUsingGET
export def "annotations-count get-by-acc-and-object-type-using" [
  acc_id: string
  species_type_key: int
  include_children: bool
  object_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($include_children | is-empty) { error make --unspanned { msg: "path parameter 'includeChildren' must be non-empty" } }
  if ($object_type | is-empty) { error make --unspanned { msg: "path parameter 'objectType' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key), include_children: (encode-path-segment $include_children), object_type: (encode-path-segment $object_type)} | format pattern "/annotations/count/{acc_id}/{species_type_key}/{include_children}/{object_type}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of annotations for a reference
#
# GET /annotations/reference/{refRgdId}
# operationId: getAnnotsByRefrerenceUsingGET
export def "annotations-reference get-annots-by-refrerence-using" [
  ref_rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ref_rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'refRgdId' must be non-empty" } }
  let full_url = (build-url $base ({ref_rgd_id: (encode-path-segment $ref_rgd_id)} | format pattern "/annotations/reference/{ref_rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of annotations by RGD ID
#
# GET /annotations/rgdId/{rgdId}
# operationId: getAnnotationsByRgdIdUsingGET
export def "annotations-rgd-id get-by-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/annotations/rgdId/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of annotations by RGD ID and ontology prefix
#
# GET /annotations/rgdId/{rgdId}/{ontologyPrefix}
# operationId: getAnnotationsByRgdIdAndOntologyUsingGET
export def "annotations-rgd-id get-by-and-ontology-using" [
  rgd_id: int
  ontology_prefix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  if ($ontology_prefix | is-empty) { error make --unspanned { msg: "path parameter 'ontologyPrefix' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id), ontology_prefix: (encode-path-segment $ontology_prefix)} | format pattern "/annotations/rgdId/{rgd_id}/{ontology_prefix}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of annotations by RGD ID and ontology term accession ID
#
# GET /annotations/{accId}/{rgdId}
# operationId: getAnnotationsByAccIdAndRgdIdUsingGET
export def "annotations get-by-acc-and-rgd-using" [
  acc_id: string
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), rgd_id: (encode-path-segment $rgd_id)} | format pattern "/annotations/{acc_id}/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list annotations for an ontology term or a term and it's children
#
# GET /annotations/{accId}/{speciesTypeKey}/{includeChildren}
# operationId: getAnnotationsUsingGET
export def "annotations get-using" [
  acc_id: string
  species_type_key: int
  include_children: bool
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<annotatedObjectRgdId: int, annotationExtension: string, aspect: string, createdBy: int, createdDate: string, dataSrc: string, evidence: string, geneProductFormId: string, key: int, lastModifiedBy: int, lastModifiedDate: string, notes: string, objectName: string, objectSymbol: string, originalCreatedDate: string, qualifier: string, refRgdId: int, relativeTo: string, rgdObjectKey: int, speciesTypeKey: int, term: string, termAcc: string, withInfo: string, xrefSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($include_children | is-empty) { error make --unspanned { msg: "path parameter 'includeChildren' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key), include_children: (encode-path-segment $include_children)} | format pattern "/annotations/{acc_id}/{species_type_key}/{include_children}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes annotated to the term.Genes are rgdids separated by comma.Species type is an integer value.term is the ontology
#
# POST /enrichment/annotatedGenes
# operationId: getEnrichmentDataUsingPOST
export def "enrichment-annotated-genes get-data-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acc-id: string
  --gene-symbols: list<string>
  --species: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment/annotatedGenes" $auth.query)
  let req_body = {"accId": $acc_id, "geneSymbols": $gene_symbols, "species": $species} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Return a chart of ontology terms annotated to the genes.Genes are rgdids separated by comma.Species type is an integer value.Aspect is the Ontology group
#
# POST /enrichment/data
# operationId: getEnrichmentDataUsingPOST_1
export def "enrichment-data get-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect: string
  --genes: list<string>
  --species: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment/data" $auth.query)
  let req_body = {"aspect": $aspect, "genes": $genes, "species": $species} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Return a list of genes for an affymetrix ID
#
# GET /genes/affyId/{affyId}/{speciesTypeKey}
# operationId: getGenesByAffyIdUsingGET
export def "genes-affy-id get-by-using" [
  affy_id: string
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($affy_id | is-empty) { error make --unspanned { msg: "path parameter 'affyId' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({affy_id: (encode-path-segment $affy_id), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/affyId/{affy_id}/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes for an alias and species
#
# GET /genes/alias/{aliasSymbol}/{speciesTypeKey}
# operationId: getGenesByAliasSymbolUsingGET
export def "genes-alias get-by-symbol-using" [
  alias_symbol: string
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($alias_symbol | is-empty) { error make --unspanned { msg: "path parameter 'aliasSymbol' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({alias_symbol: (encode-path-segment $alias_symbol), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/alias/{alias_symbol}/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of gene alleles
#
# GET /genes/allele/{rgdId}
# operationId: getGeneAllelesUsingGET
export def "genes-allele get-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/genes/allele/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes annotated to an ontology term
#
# POST /genes/annotation
# operationId: getAnnotatedGenesUsingPOST
export def "genes-annotation get-annotated-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acc-id: string
  --evidence-codes: list<string>
  --species-type-keys: list<int>
]: any -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/genes/annotation" $auth.query)
  let req_body = {"accId": $acc_id, "evidenceCodes": $evidence_codes, "speciesTypeKeys": $species_type_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Return a list of genes annotated to an ontology term
#
# GET /genes/annotation/{accId}
# operationId: getAllAnnotatedGenesUsingGET
export def "genes-annotation get-list-annotated-using" [
  acc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/genes/annotation/{acc_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes annotated to an ontology term
#
# GET /genes/annotation/{accId}/{speciesTypeKey}
# operationId: getGenesAnnotatedUsingGET
export def "genes-annotation get-annotated-using" [
  acc_id: string
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/annotation/{acc_id}/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes by keyword and species type key
#
# GET /genes/keyword/{keyword}/{speciesTypeKey}
# operationId: getGenesByKeywordUsingGET
export def "genes-keyword get-by-using" [
  keyword: string
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($keyword | is-empty) { error make --unspanned { msg: "path parameter 'keyword' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/keyword/{keyword}/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of all genes with position information for an assembly
#
# GET /genes/map/{mapKey}
# operationId: getGeneByMapKeyUsingGET
export def "genes-map get-by-key-using" [
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<chromosome: string, gene: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>, mapKey: int, start: int, stop: int, strand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({map_key: (encode-path-segment $map_key)} | format pattern "/genes/map/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes position and map key
#
# GET /genes/mapped/{chr}/{start}/{stop}/{mapKey}
# operationId: getMappedGenesByPositionUsingGET
export def "genes-mapped get-by-position-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<chromosome: string, gene: record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool>, mapKey: int, start: int, stop: int, strand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/genes/mapped/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of gene orthologs
#
# POST /genes/orthologs
# operationId: getOrthologsByListUsingPOST
export def "genes-orthologs get-by-list-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
  --species-type-keys: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/genes/orthologs" $auth.query)
  let req_body = {"rgdIds": $rgd_ids, "speciesTypeKeys": $species_type_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Return a list of gene orthologs
#
# GET /genes/orthologs/{rgdId}
# operationId: getGeneOrthologsUsingGET
export def "genes-orthologs get-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/genes/orthologs/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes in region
#
# GET /genes/region/{chr}/{start}/{stop}/{mapKey}
# operationId: getGenesInRegionUsingGET
export def "genes-region get-in-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<chromosome: string, mapKey: int, rgdId: int, start: int, stop: int, strand: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/genes/region/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of all genes for a species in RGD
#
# GET /genes/species/{speciesTypeKey}
# operationId: getGenesBySpeciesUsingGET
export def "genes-species get-by-using" [
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/species/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of genes position and map key
#
# GET /genes/{chr}/{start}/{stop}/{mapKey}
# operationId: getGenesByPositionUsingGET
export def "genes get-by-position-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/genes/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a gene record by RGD ID
#
# GET /genes/{rgdId}
# operationId: getGeneByRgdIdUsingGET
export def "genes get-by-rgd-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/genes/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a gene record by symbol and species type key
#
# GET /genes/{symbol}/{speciesTypeKey}
# operationId: getGeneBySymbolUsingGET
export def "genes get-by-using" [
  symbol: string
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agrDescription: string, description: string, ensemblFullName: string, ensemblGeneSymbol: string, ensemblGeneType: string, geneSource: string, key: int, mergedDescription: string, name: string, ncbiAnnotStatus: string, nomenReviewDate: string, nomenSource: string, notes: string, refSeqStatus: string, rgdId: int, soAccId: string, speciesTypeKey: int, symbol: string, type: string, variant: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($symbol | is-empty) { error make --unspanned { msg: "path parameter 'symbol' must be non-empty" } }
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({symbol: (encode-path-segment $symbol), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/{symbol}/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of gene types avialable in RGD
#
# GET /lookup/geneTypes
# operationId: getGeneTypesUsingGET
export def "lookup-gene-types get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/geneTypes" $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to Ensembl Gene IDs
#
# POST /lookup/id/map/EnsemblGene
# operationId: getEnsemblGeneMappingUsingPOST
export def "lookup-id-map-ensembl-gene get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/EnsemblGene" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an Ensembl Gene ID
#
# GET /lookup/id/map/EnsemblGene/{rgdId}
# operationId: getEnsemblGeneMappingUsingGET
export def "lookup-id-map-ensembl-gene get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/EnsemblGene/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to Ensembl Protein IDs
#
# POST /lookup/id/map/EnsemblProtein
# operationId: getEnsemblProteinMappingUsingPOST
export def "lookup-id-map-ensembl-protein get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/EnsemblProtein" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an Ensembl Protein ID
#
# GET /lookup/id/map/EnsemblProtein/{rgdId}
# operationId: getEnsemblProteinMappingUsingGET
export def "lookup-id-map-ensembl-protein get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/EnsemblProtein/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to Ensembl Transcript IDs
#
# POST /lookup/id/map/EnsemblTranscript
# operationId: getEnsemblTranscriptMappingUsingPOST
export def "lookup-id-map-ensembl-transcript get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/EnsemblTranscript" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an Ensembl Transcript ID
#
# GET /lookup/id/map/EnsemblTranscript/{rgdId}
# operationId: getEnsemblTranscriptMappingUsingGET
export def "lookup-id-map-ensembl-transcript get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/EnsemblTranscript/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to GTEx IDs
#
# POST /lookup/id/map/GTEx
# operationId: getGTEXMappingUsingPOST
export def "lookup-id-map-gt-ex get-gtex-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/GTEx" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an GTEx ID
#
# GET /lookup/id/map/GTEx/{rgdId}
# operationId: getGTEXMappingUsingGET
export def "lookup-id-map-gt-ex get-gtex-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/GTEx/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to GenBank Nucleotide IDs
#
# POST /lookup/id/map/GenBankNucleotide
# operationId: getGenBankNucleotideMappingUsingPOST
export def "lookup-id-map-gen-bank-nucleotide get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/GenBankNucleotide" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to a GenBank Nucleotide ID
#
# GET /lookup/id/map/GenBankNucleotide/{rgdId}
# operationId: getGenBankNucleotideMappingUsingGET
export def "lookup-id-map-gen-bank-nucleotide get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/GenBankNucleotide/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to GenBank Protein IDs
#
# POST /lookup/id/map/GenBankProtein
# operationId: getGenBankProteinMappingUsingPOST
export def "lookup-id-map-gen-bank-protein get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/GenBankProtein" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to a GenBank Protein ID
#
# GET /lookup/id/map/GenBankProtein/{rgdId}
# operationId: getGenBankProteinMappingUsingGET
export def "lookup-id-map-gen-bank-protein get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/GenBankProtein/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to HGNC IDs
#
# POST /lookup/id/map/HGNC
# operationId: getHGNCMappingUsingPOST
export def "lookup-id-map-hgnc get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/HGNC" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an HGNC ID
#
# GET /lookup/id/map/HGNC/{rgdId}
# operationId: getHGNCMappingUsingGET
export def "lookup-id-map-hgnc get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/HGNC/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to MGI IDs
#
# POST /lookup/id/map/MGI
# operationId: getMGIMappingUsingPOST
export def "lookup-id-map-mgi get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/MGI" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an MGI ID
#
# GET /lookup/id/map/MGI/{rgdId}
# operationId: getMGIMappingUsingGET
export def "lookup-id-map-mgi get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/MGI/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to NCBI Gene IDs
#
# POST /lookup/id/map/NCBIGene
# operationId: getNCBIGeneMappingUsingPOST
export def "lookup-id-map-ncbi-gene get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/NCBIGene" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to an NCBI Gene ID
#
# GET /lookup/id/map/NCBIGene/{rgdId}
# operationId: getNCBIGeneMappingUsingGET
export def "lookup-id-map-ncbi-gene get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/NCBIGene/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Translate RGD IDs to UniProt IDs
#
# POST /lookup/id/map/UniProt
# operationId: getUniProtMappingUsingPOST
export def "lookup-id-map-uni-prot get-mapping-using-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/UniProt" $auth.query)
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Translate an RGD ID to a UniProt ID
#
# GET /lookup/id/map/UniProt/{rgdId}
# operationId: getUniProtMappingUsingGET
export def "lookup-id-map-uni-prot get-mapping-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/UniProt/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list assembly maps for a species
#
# GET /lookup/maps/{speciesTypeKey}
# operationId: getMapsUsingGET
export def "lookup-maps get-using" [
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<dbsnpVersion: string, description: string, key: int, methodKey: int, name: string, notes: string, primaryRefAssembly: bool, rank: int, refSeqAssemblyAcc: string, refSeqAssemblyName: string, rgdId: int, source: string, speciesTypeKey: int, ucscAssemblyId: string, unit: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key)} | format pattern "/lookup/maps/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a Map of species type keys available in RGD
#
# GET /lookup/speciesTypeKeys
# operationId: getSpeciesTypesUsingGET
export def "lookup-species-type-keys get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/speciesTypeKeys" $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a standardUnit for an ontology if it exists
#
# GET /lookup/standardUnit/{accId}
# operationId: getMapsUsingGET_1
export def "lookup-standard-unit get-maps-using-by-acc-id" [
  acc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/lookup/standardUnit/{acc_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of chromosomes
#
# GET /maps/chr/{chromosome}/{mapKey}
# operationId: getChromosomeByAssemblyUsingGET
export def "maps-chr get-by-assembly-using" [
  chromosome: string
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chromosome: string, contigCount: int, gapCount: int, gapLength: int, genbankId: string, mapKey: int, ordinalNumber: int, refseqId: string, seqLength: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chromosome | is-empty) { error make --unspanned { msg: "path parameter 'chromosome' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chromosome: (encode-path-segment $chromosome), map_key: (encode-path-segment $map_key)} | format pattern "/maps/chr/{chromosome}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of chromosomes
#
# GET /maps/chr/{mapKey}
# operationId: getChromosomesByAssemblyUsingGET
export def "maps-chr get-chromosomes-by-assembly-using" [
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({map_key: (encode-path-segment $map_key)} | format pattern "/maps/chr/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of assemblies
#
# GET /maps/{speciesTypeKey}
# operationId: getMapsBySpeciesUsingGET
export def "maps get-by-species-using" [
  species_type_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<dbsnpVersion: string, description: string, key: int, methodKey: int, name: string, notes: string, primaryRefAssembly: bool, rank: int, refSeqAssemblyAcc: string, refSeqAssemblyName: string, rgdId: int, source: string, speciesTypeKey: int, ucscAssemblyId: string, unit: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key)} | format pattern "/maps/{species_type_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns child and parent terms for Accession ID
#
# GET /ontology/ont/{accId}
# operationId: getOntDagsUsingGET
export def "ontology-ont get-dags-using" [
  acc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/ontology/ont/{acc_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns true or false for terms
#
# GET /ontology/term/{accId1}/{accId2}
# operationId: isDescendantOfUsingGET
export def "ontology-term get-is-descendant-of-using" [
  acc_id1: string
  acc_id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id1 | is-empty) { error make --unspanned { msg: "path parameter 'accId1' must be non-empty" } }
  if ($acc_id2 | is-empty) { error make --unspanned { msg: "path parameter 'accId2' must be non-empty" } }
  let full_url = (build-url $base ({acc_id1: (encode-path-segment $acc_id1), acc_id2: (encode-path-segment $acc_id2)} | format pattern "/ontology/term/{acc_id1}/{acc_id2}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns term for Accession ID
#
# GET /ontology/term/{accId}
# operationId: getTermUsingGET
export def "ontology-term get-using" [
  acc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accId: string, comment: string, createdBy: string, creationDate: string, definition: string, modificationDate: string, obsolete: int, ontologyId: string, term: string, xrefs: table<key: int, termAcc: string, xrefDescription: string, xrefValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/ontology/term/{acc_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of pathways based on search term
#
# GET /pathways/diagrams/search/{searchString}
# operationId: searchPathwaysUsingGET
export def "pathways-diagrams-search get-using" [
  search_string: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, hasAlteredPath: string, id: string, name: string, objectList: list<record>, pathwayCategories: list<string>, referenceList: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($search_string | is-empty) { error make --unspanned { msg: "path parameter 'searchString' must be non-empty" } }
  let full_url = (build-url $base ({search_string: (encode-path-segment $search_string)} | format pattern "/pathways/diagrams/search/{search_string}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of pathways based on category provided
#
# GET /pathways/diagramsForCategory/{category}
# operationId: getPathwaysWithDiagramsForCategoryUsingGET
export def "pathways-diagrams-for-category get-with-using" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, hasAlteredPath: string, id: string, name: string, objectList: list<record>, pathwayCategories: list<string>, referenceList: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/pathways/diagramsForCategory/{category}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of quantitative phenotypes values based on a combination of Clinical Measurement, Experimental Condition, Rat Strain, and/or Measurement Method ontology terms. Results will be all records that match all terms submitted. Ontology ids should be submitted as a comma delimited list (ex. RS:0000029,CMO:0000155,CMO:0000139). Species type is an integer value (3=rat, 4=chinchilla). Reference RGD ID for a study works like a filter.
#
# GET /phenotype/phenominer/chart/{speciesTypeKey}/{refRgdId}/{termString}
# operationId: getChartInfoUsingGET
export def "phenotype-phenominer-chart get-using" [
  species_type_key: int
  ref_rgd_id: int
  term_string: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($ref_rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'refRgdId' must be non-empty" } }
  if ($term_string | is-empty) { error make --unspanned { msg: "path parameter 'termString' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), ref_rgd_id: (encode-path-segment $ref_rgd_id), term_string: (encode-path-segment $term_string)} | format pattern "/phenotype/phenominer/chart/{species_type_key}/{ref_rgd_id}/{term_string}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a list of quantitative phenotypes values based on a combination of Clinical Measurement, Experimental Condition, Rat Strain, and/or Measurement Method ontology terms. Results will be all records that match all terms submitted. Ontology ids should be submitted as a comma delimited list (ex. RS:0000029,CMO:0000155,CMO:0000139). Species type is an integer value (3=rat, 4=chinchilla)
#
# GET /phenotype/phenominer/chart/{speciesTypeKey}/{termString}
# operationId: getChartInfoUsingGET_1
export def "phenotype-phenominer-chart get-using-by-species-type-key-term-string" [
  species_type_key: int
  term_string: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($term_string | is-empty) { error make --unspanned { msg: "path parameter 'termString' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), term_string: (encode-path-segment $term_string)} | format pattern "/phenotype/phenominer/chart/{species_type_key}/{term_string}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list QTL for given position and assembly map
#
# GET /qtls/mapped/{chr}/{start}/{stop}/{mapKey}
# operationId: getMappedQTLByPositionUsingGET
export def "qtls-mapped get-by-position-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<chromosome: string, mapKey: int, qtl: record<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float>, start: int, stop: int, strand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/qtls/mapped/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list QTL for given position and assembly map
#
# GET /qtls/{chr}/{start}/{stop}/{mapKey}
# operationId: getQtlListByPositionUsingGET
export def "qtls get-list-by-position-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/qtls/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a QTL for provided RGD ID
#
# GET /qtls/{rgdId}
# operationId: getQTLByRgdIdUsingGET
export def "qtls get-by-rgd-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chromosome: string, flank1RgdId: int, flank2RgdId: int, inheritanceType: string, key: int, linkageImage: string, lod: float, lodImage: string, mostSignificantCmoTerm: string, name: string, notes: string, peakOffset: int, peakRgdId: int, pvalue: float, rgdId: int, sourceUrl: string, speciesTypeKey: int, symbol: string, variance: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/qtls/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list SSLP for given position and assembly map
#
# GET /sslps/mapped/{chr}/{start}/{stop}/{mapKey}
# operationId: getMappedSSLPByPositionUsingGET
export def "sslps-mapped get-by-position-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<chromosome: string, mapKey: int, sslp: record<expectedSize: int, forwardSeq: string, key: int, name: string, notes: string, reverseSeq: string, rgdId: int, speciesTypeKey: int, sslpType: string, templateSeq: string>, start: int, stop: int, strand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/sslps/mapped/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of active objects by type, for specified species and date
#
# GET /stats/count/activeObject/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getActiveObjectCountUsingGET
export def "stats-count-active-object get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/activeObject/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of gene types, for specified species and date
#
# GET /stats/count/geneType/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getGeneTypeCountUsingGET
export def "stats-count-gene-type get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/geneType/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of objects with given status, for specified species and date
#
# GET /stats/count/objectStatus/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getObjectStatusCountUsingGET
export def "stats-count-object-status get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectStatus/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of objects with reference sequence(s), by object type, for specified species and date
#
# GET /stats/count/objectWithRefSeq/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getObjectsWithRefSeqCountUsingGET
export def "stats-count-object-with-ref-seq get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectWithRefSeq/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of objects with reference, by object type, for specified species and date
#
# GET /stats/count/objectWithReference/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getObjectsWithReferenceCountUsingGET
export def "stats-count-object-with-reference get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectWithReference/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of objects with external database ids, by database id, for specified species, object type and date
#
# GET /stats/count/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateYYYYMMDD}
# operationId: getObjectsWithXDBsCountUsingGET
export def "stats-count-object-with-xdb get-xd-bs-using" [
  species_type_key: int
  object_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($object_key | is-empty) { error make --unspanned { msg: "path parameter 'objectKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), object_key: (encode-path-segment $object_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectWithXdb/{species_type_key}/{object_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of protein interactions, for specified species and date
#
# GET /stats/count/proteinInteraction/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getProteinInteractionCountUsingGET
export def "stats-count-protein-interaction get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/proteinInteraction/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of strains, by qtl inheritance type, for specified species and date
#
# GET /stats/count/qtlInheritanceType/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getQtlInheritanceTypeCountUsingGET
export def "stats-count-qtl-inheritance-type get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/qtlInheritanceType/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of retired objects by type, for specified species and date
#
# GET /stats/count/retiredObject/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getRetiredObjectCountUsingGET
export def "stats-count-retired-object get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/retiredObject/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of strain types, for specified species and date
#
# GET /stats/count/strainType/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getStrainTypeCountUsingGET
export def "stats-count-strain-type get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/strainType/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of withdrawn objects by type, for specified species and date
#
# GET /stats/count/withdrawnObject/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getWithdrawnObjectCountUsingGET
export def "stats-count-withdrawn-object get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/withdrawnObject/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count of external database ids, for specied species and date
#
# GET /stats/count/xdb/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getXdbsCountUsingGET
export def "stats-count-xdb get-using" [
  species_type_key: int
  date_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/xdb/{species_type_key}/{date_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of active objects, by type, for specified species and date range
#
# GET /stats/diff/activeObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getActiveObjectDiffUsingGET
export def "stats-diff-active-object get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/activeObject/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of gene types, for specified species and date range
#
# GET /stats/diff/geneType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getGeneTypeDiffUsingGET
export def "stats-diff-gene-type get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/geneType/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of objects with given status, for specified species and date range
#
# GET /stats/diff/objectStatus/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectStatusDiffUsingGET
export def "stats-diff-object-status get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectStatus/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of objects with reference sequence(s), by object type, for specified species and date range
#
# GET /stats/diff/objectWithRefSeq/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectsWithRefSeqDiffUsingGET
export def "stats-diff-object-with-ref-seq get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectWithRefSeq/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of objects with reference, by object type, for specified species and date range
#
# GET /stats/diff/objectWithReference/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectsWithReferenceDiffUsingGET
export def "stats-diff-object-with-reference get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectWithReference/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of objects with external database ids, by database id, for specified species, object type and date range
#
# GET /stats/diff/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectsWithXDBsDiffUsingGET
export def "stats-diff-object-with-xdb get-xd-bs-using" [
  species_type_key: int
  object_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($object_key | is-empty) { error make --unspanned { msg: "path parameter 'objectKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), object_key: (encode-path-segment $object_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectWithXdb/{species_type_key}/{object_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of protein interactions, for specified species and date range
#
# GET /stats/diff/proteinInteraction/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getProteinInteractionDiffUsingGET
export def "stats-diff-protein-interaction get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/proteinInteraction/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of strains, by qtl inheritance type, for specified species and date range
#
# GET /stats/diff/qtlInheritanceType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getQtlInheritanceTypeDiffUsingGET
export def "stats-diff-qtl-inheritance-type get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/qtlInheritanceType/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of retired objects, by type, for specified species and date range
#
# GET /stats/diff/retiredObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getRetiredObjectDiffUsingGET
export def "stats-diff-retired-object get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/retiredObject/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of strain types, for specified species and date range
#
# GET /stats/diff/strainType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getStrainTypeDiffUsingGET
export def "stats-diff-strain-type get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/strainType/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of withdrawn objects, by type, for specified species and date range
#
# GET /stats/diff/withdrawnObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getWithdrawnObjectDiffUsingGET
export def "stats-diff-withdrawn-object get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/withdrawnObject/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Count difference of external database ids, for specified species and date range
#
# GET /stats/diff/xdb/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getXdbsDiffUsingGET
export def "stats-diff-xdb get-using" [
  species_type_key: int
  date_from_yyyymmdd: string
  date_to_yyyymmdd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($species_type_key | is-empty) { error make --unspanned { msg: "path parameter 'speciesTypeKey' must be non-empty" } }
  if ($date_from_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateFromYYYYMMDD' must be non-empty" } }
  if ($date_to_yyyymmdd | is-empty) { error make --unspanned { msg: "path parameter 'dateToYYYYMMDD' must be non-empty" } }
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/xdb/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# getTermStats
#
# GET /stats/term/{accId}/{filterAccId}
# operationId: getTermStatsUsingGET
export def "stats-term get-using" [
  acc_id: string
  filter_acc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($acc_id | is-empty) { error make --unspanned { msg: "path parameter 'accId' must be non-empty" } }
  if ($filter_acc_id | is-empty) { error make --unspanned { msg: "path parameter 'filterAccId' must be non-empty" } }
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), filter_acc_id: (encode-path-segment $filter_acc_id)} | format pattern "/stats/term/{acc_id}/{filter_acc_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return all active strains in RGD
#
# GET /strains/all
# operationId: getAllStrainsUsingGET
export def "strains-all get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: list<record>, strain: string, strainTypeName: string, substrain: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/strains/all" $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return all active strains by position
#
# GET /strains/{chr}/{start}/{stop}/{mapKey}
# operationId: getStrainsByPositionUsingGET
export def "strains get-by-position-using" [
  chr: string
  start: int
  stop: int
  map_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: list<record>, strain: string, strainTypeName: string, substrain: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($chr | is-empty) { error make --unspanned { msg: "path parameter 'chr' must be non-empty" } }
  if ($start | is-empty) { error make --unspanned { msg: "path parameter 'start' must be non-empty" } }
  if ($stop | is-empty) { error make --unspanned { msg: "path parameter 'stop' must be non-empty" } }
  if ($map_key | is-empty) { error make --unspanned { msg: "path parameter 'mapKey' must be non-empty" } }
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/strains/{chr}/{start}/{stop}/{map_key}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return a strain by RGD ID
#
# GET /strains/{rgdId}
# operationId: getStrainByRgdIdUsingGET
export def "strains get-by-rgd-using" [
  rgd_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<backgroundStrainRgdId: int, chrAltered: string, color: string, geneticStatus: string, genetics: string, imageUrl: string, inbredGen: string, key: int, lastStatus: string, lastStatusObject: record<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, modificationMethod: string, name: string, notes: string, origin: string, researchUse: string, rgdId: int, source: string, speciesTypeKey: int, statusLog: table<cryopreservedEmbryo: bool, cryopreservedSperm: bool, cryorecovery: bool, key: int, liveAnimals: bool, statusDate: string, strainRgdId: int>, strain: string, strainTypeName: string, substrain: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rgd_id | is-empty) { error make --unspanned { msg: "path parameter 'rgdId' must be non-empty" } }
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/strains/{rgd_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
