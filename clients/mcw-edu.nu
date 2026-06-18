# Auto-generated client for Rat Genome Database REST API v1.1
# Source: https://api.apis.guru/v2/specs/mcw.edu/1.1/openapi.json
# Auth: --token flag or $env.RAT_GENOME_DATABASE_REST_API_TOKEN

const BASE_URL = "http://localhost//rest.rgd.mcw.edu/rgdws"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RAT_GENOME_DATABASE_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost//rest.rgd.mcw.edu/rgdws"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "agr-affected-genomic-models get-using-get" } } | get name | first)
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
export def "agr-affected-genomic-models get-using-get" [
  taxon_id: string
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
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/affectedGenomicModels/{taxon_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get gene allele records submitted by RGD to AGR by taxonId
#
# GET /agr/alleles/{taxonId}
# operationId: getAllelesForTaxonUsingGET
export def "agr-alleles get-for-taxon-using-get" [
  taxon_id: string
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
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/alleles/{taxon_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get expression annotations submitted by RGD to AGR by taxonId
#
# GET /agr/expression/{taxonId}
# operationId: getExpressionForTaxonUsingGET
export def "agr-expression get-for-taxon-using-get" [
  taxon_id: string
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
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/expression/{taxon_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get phenotype annotations submitted by RGD to AGR by taxonId
#
# GET /agr/phenotypes/{taxonId}
# operationId: getPhenotypesForTaxonUsingGET
export def "agr-phenotypes get-for-taxon-using-get" [
  taxon_id: string
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
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/phenotypes/{taxon_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get basic variant records submitted by RGD to AGR by taxonId
#
# GET /agr/variants/{taxonId}
# operationId: getVariantsForTaxonUsingGET
export def "agr-variants get-for-taxon-using-get" [
  taxon_id: string
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
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/variants/{taxon_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get gene records submitted by RGD to AGR by taxonId
#
# GET /agr/{taxonId}
# operationId: getGenesForLatestAssemblyUsingGET
export def "agr get-genes-for-latest-assembly-using-get" [
  taxon_id: string
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
  let full_url = (build-url $base ({taxon_id: (encode-path-segment $taxon_id)} | format pattern "/agr/{taxon_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-codes: list<string>
  --ids: list<string>
  --species-type-keys: list<int>
  --term-acc: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotations/")
  let req_body = {"evidenceCodes": $evidence_codes, "ids": $ids, "speciesTypeKeys": $species_type_keys, "termAcc": $term_acc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list ontology term accession IDs annotated to an rgd object
#
# GET /annotations/accId/{rgdId}
# operationId: getTermAccIdsUsingGET
export def "annotations-acc-id get-term-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/annotations/accId/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns annotation count for ontology accession ID
#
# GET /annotations/count/{accId}/{includeChildren}
# operationId: getAnnotationCountByAccIdUsingGET
export def "annotations-count get-by-acc-using-get" [
  acc_id: string
  include_children: bool
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), include_children: (encode-path-segment $include_children)} | format pattern "/annotations/count/{acc_id}/{include_children}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns annotation count for ontology accession ID and speicies
#
# GET /annotations/count/{accId}/{speciesTypeKey}/{includeChildren}
# operationId: getAnnotationCountByAccIdAndSpeciesUsingGET
export def "annotations-count get-by-acc-and-species-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key), include_children: (encode-path-segment $include_children)} | format pattern "/annotations/count/{acc_id}/{species_type_key}/{include_children}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns annotation count for ontology accession ID and object type
#
# GET /annotations/count/{accId}/{speciesTypeKey}/{includeChildren}/{objectType}
# operationId: getAnnotationCountByAccIdAndObjectTypeUsingGET
export def "annotations-count get-by-acc-and-object-type-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key), include_children: (encode-path-segment $include_children), object_type: (encode-path-segment $object_type)} | format pattern "/annotations/count/{acc_id}/{species_type_key}/{include_children}/{object_type}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of annotations for a reference
#
# GET /annotations/reference/{refRgdId}
# operationId: getAnnotsByRefrerenceUsingGET
export def "annotations-reference get-annots-by-refrerence-using-get" [
  ref_rgd_id: int
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
  let full_url = (build-url $base ({ref_rgd_id: (encode-path-segment $ref_rgd_id)} | format pattern "/annotations/reference/{ref_rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of annotations by RGD ID
#
# GET /annotations/rgdId/{rgdId}
# operationId: getAnnotationsByRgdIdUsingGET
export def "annotations-rgd-id get-by-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/annotations/rgdId/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of annotations by RGD ID and ontology prefix
#
# GET /annotations/rgdId/{rgdId}/{ontologyPrefix}
# operationId: getAnnotationsByRgdIdAndOntologyUsingGET
export def "annotations-rgd-id get-by-and-ontology-using-get" [
  rgd_id: int
  ontology_prefix: string
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id), ontology_prefix: (encode-path-segment $ontology_prefix)} | format pattern "/annotations/rgdId/{rgd_id}/{ontology_prefix}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of annotations by RGD ID and ontology term accession ID
#
# GET /annotations/{accId}/{rgdId}
# operationId: getAnnotationsByAccIdAndRgdIdUsingGET
export def "annotations get-by-acc-and-rgd-using-get" [
  acc_id: string
  rgd_id: int
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), rgd_id: (encode-path-segment $rgd_id)} | format pattern "/annotations/{acc_id}/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list annotations for an ontology term or a term and it's children
#
# GET /annotations/{accId}/{speciesTypeKey}/{includeChildren}
# operationId: getAnnotationsUsingGET
export def "annotations get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key), include_children: (encode-path-segment $include_children)} | format pattern "/annotations/{acc_id}/{species_type_key}/{include_children}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --acc-id: string
  --gene-symbols: list<string>
  --species: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment/annotatedGenes")
  let req_body = {"accId": $acc_id, "geneSymbols": $gene_symbols, "species": $species} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return a chart of ontology terms annotated to the genes.Genes are rgdids separated by comma.Species type is an integer value.Aspect is the Ontology group
#
# POST /enrichment/data
# operationId: getEnrichmentDataUsingPOST_1
export def "enrichment-data get-using-create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect: string
  --genes: list<string>
  --species: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enrichment/data")
  let req_body = {"aspect": $aspect, "genes": $genes, "species": $species} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return a list of genes for an affymetrix ID
#
# GET /genes/affyId/{affyId}/{speciesTypeKey}
# operationId: getGenesByAffyIdUsingGET
export def "genes-affy-id get-by-using-get" [
  affy_id: string
  species_type_key: int
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
  let full_url = (build-url $base ({affy_id: (encode-path-segment $affy_id), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/affyId/{affy_id}/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of genes for an alias and species
#
# GET /genes/alias/{aliasSymbol}/{speciesTypeKey}
# operationId: getGenesByAliasSymbolUsingGET
export def "genes-alias get-by-symbol-using-get" [
  alias_symbol: string
  species_type_key: int
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
  let full_url = (build-url $base ({alias_symbol: (encode-path-segment $alias_symbol), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/alias/{alias_symbol}/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of gene alleles
#
# GET /genes/allele/{rgdId}
# operationId: getGeneAllelesUsingGET
export def "genes-allele get-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/genes/allele/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --acc-id: string
  --evidence-codes: list<string>
  --species-type-keys: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/genes/annotation")
  let req_body = {"accId": $acc_id, "evidenceCodes": $evidence_codes, "speciesTypeKeys": $species_type_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return a list of genes annotated to an ontology term
#
# GET /genes/annotation/{accId}
# operationId: getAllAnnotatedGenesUsingGET
export def "genes-annotation get-list-annotated-using-get" [
  acc_id: string
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/genes/annotation/{acc_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of genes annotated to an ontology term
#
# GET /genes/annotation/{accId}/{speciesTypeKey}
# operationId: getGenesAnnotatedUsingGET
export def "genes-annotation get-annotated-using-get" [
  acc_id: string
  species_type_key: int
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/annotation/{acc_id}/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of genes by keyword and species type key
#
# GET /genes/keyword/{keyword}/{speciesTypeKey}
# operationId: getGenesByKeywordUsingGET
export def "genes-keyword get-by-using-get" [
  keyword: string
  species_type_key: int
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
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/keyword/{keyword}/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of all genes with position information for an assembly
#
# GET /genes/map/{mapKey}
# operationId: getGeneByMapKeyUsingGET
export def "genes-map get-by-key-using-get" [
  map_key: int
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
  let full_url = (build-url $base ({map_key: (encode-path-segment $map_key)} | format pattern "/genes/map/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of genes position and map key
#
# GET /genes/mapped/{chr}/{start}/{stop}/{mapKey}
# operationId: getMappedGenesByPositionUsingGET
export def "genes-mapped get-by-position-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/genes/mapped/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
  --species-type-keys: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/genes/orthologs")
  let req_body = {"rgdIds": $rgd_ids, "speciesTypeKeys": $species_type_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return a list of gene orthologs
#
# GET /genes/orthologs/{rgdId}
# operationId: getGeneOrthologsUsingGET
export def "genes-orthologs get-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/genes/orthologs/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of genes in region
#
# GET /genes/region/{chr}/{start}/{stop}/{mapKey}
# operationId: getGenesInRegionUsingGET
export def "genes-region get-in-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/genes/region/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of all genes for a species in RGD
#
# GET /genes/species/{speciesTypeKey}
# operationId: getGenesBySpeciesUsingGET
export def "genes-species get-by-using-get" [
  species_type_key: int
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/species/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of genes position and map key
#
# GET /genes/{chr}/{start}/{stop}/{mapKey}
# operationId: getGenesByPositionUsingGET
export def "genes get-by-position-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/genes/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a gene record by RGD ID
#
# GET /genes/{rgdId}
# operationId: getGeneByRgdIdUsingGET
export def "genes get-by-rgd-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/genes/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a gene record by symbol and species type key
#
# GET /genes/{symbol}/{speciesTypeKey}
# operationId: getGeneBySymbolUsingGET
export def "genes get-by-using-get" [
  symbol: string
  species_type_key: int
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
  let full_url = (build-url $base ({symbol: (encode-path-segment $symbol), species_type_key: (encode-path-segment $species_type_key)} | format pattern "/genes/{symbol}/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of gene types avialable in RGD
#
# GET /lookup/geneTypes
# operationId: getGeneTypesUsingGET
export def "lookup-gene-types get-using-get" [
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
  let full_url = (build-url $base "/lookup/geneTypes")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/EnsemblGene")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an Ensembl Gene ID
#
# GET /lookup/id/map/EnsemblGene/{rgdId}
# operationId: getEnsemblGeneMappingUsingGET
export def "lookup-id-map-ensembl-gene get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/EnsemblGene/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/EnsemblProtein")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an Ensembl Protein ID
#
# GET /lookup/id/map/EnsemblProtein/{rgdId}
# operationId: getEnsemblProteinMappingUsingGET
export def "lookup-id-map-ensembl-protein get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/EnsemblProtein/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/EnsemblTranscript")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an Ensembl Transcript ID
#
# GET /lookup/id/map/EnsemblTranscript/{rgdId}
# operationId: getEnsemblTranscriptMappingUsingGET
export def "lookup-id-map-ensembl-transcript get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/EnsemblTranscript/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/GTEx")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an GTEx ID
#
# GET /lookup/id/map/GTEx/{rgdId}
# operationId: getGTEXMappingUsingGET
export def "lookup-id-map-gt-ex get-gtex-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/GTEx/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/GenBankNucleotide")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to a GenBank Nucleotide ID
#
# GET /lookup/id/map/GenBankNucleotide/{rgdId}
# operationId: getGenBankNucleotideMappingUsingGET
export def "lookup-id-map-gen-bank-nucleotide get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/GenBankNucleotide/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/GenBankProtein")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to a GenBank Protein ID
#
# GET /lookup/id/map/GenBankProtein/{rgdId}
# operationId: getGenBankProteinMappingUsingGET
export def "lookup-id-map-gen-bank-protein get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/GenBankProtein/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/HGNC")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an HGNC ID
#
# GET /lookup/id/map/HGNC/{rgdId}
# operationId: getHGNCMappingUsingGET
export def "lookup-id-map-hgnc get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/HGNC/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/MGI")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an MGI ID
#
# GET /lookup/id/map/MGI/{rgdId}
# operationId: getMGIMappingUsingGET
export def "lookup-id-map-mgi get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/MGI/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/NCBIGene")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to an NCBI Gene ID
#
# GET /lookup/id/map/NCBIGene/{rgdId}
# operationId: getNCBIGeneMappingUsingGET
export def "lookup-id-map-ncbi-gene get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/NCBIGene/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --rgd-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lookup/id/map/UniProt")
  let req_body = {"rgdIds": $rgd_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Translate an RGD ID to a UniProt ID
#
# GET /lookup/id/map/UniProt/{rgdId}
# operationId: getUniProtMappingUsingGET
export def "lookup-id-map-uni-prot get-mapping-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/lookup/id/map/UniProt/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list assembly maps for a species
#
# GET /lookup/maps/{speciesTypeKey}
# operationId: getMapsUsingGET
export def "lookup-maps get-using-get" [
  species_type_key: int
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key)} | format pattern "/lookup/maps/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a Map of species type keys available in RGD
#
# GET /lookup/speciesTypeKeys
# operationId: getSpeciesTypesUsingGET
export def "lookup-species-type-keys get-using-get" [
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
  let full_url = (build-url $base "/lookup/speciesTypeKeys")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a standardUnit for an ontology if it exists
#
# GET /lookup/standardUnit/{accId}
# operationId: getMapsUsingGET_1
export def "lookup-standard-unit get-maps-using-get-by-accId" [
  acc_id: string
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/lookup/standardUnit/{acc_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of chromosomes
#
# GET /maps/chr/{chromosome}/{mapKey}
# operationId: getChromosomeByAssemblyUsingGET
export def "maps-chr get-by-assembly-using-get" [
  chromosome: string
  map_key: int
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
  let full_url = (build-url $base ({chromosome: (encode-path-segment $chromosome), map_key: (encode-path-segment $map_key)} | format pattern "/maps/chr/{chromosome}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of chromosomes
#
# GET /maps/chr/{mapKey}
# operationId: getChromosomesByAssemblyUsingGET
export def "maps-chr get-chromosomes-by-assembly-using-get" [
  map_key: int
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
  let full_url = (build-url $base ({map_key: (encode-path-segment $map_key)} | format pattern "/maps/chr/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of assemblies
#
# GET /maps/{speciesTypeKey}
# operationId: getMapsBySpeciesUsingGET
export def "maps get-by-species-using-get" [
  species_type_key: int
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key)} | format pattern "/maps/{species_type_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns child and parent terms for Accession ID
#
# GET /ontology/ont/{accId}
# operationId: getOntDagsUsingGET
export def "ontology-ont get-dags-using-get" [
  acc_id: string
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/ontology/ont/{acc_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({acc_id1: (encode-path-segment $acc_id1), acc_id2: (encode-path-segment $acc_id2)} | format pattern "/ontology/term/{acc_id1}/{acc_id2}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns term for Accession ID
#
# GET /ontology/term/{accId}
# operationId: getTermUsingGET
export def "ontology-term get-using-get" [
  acc_id: string
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id)} | format pattern "/ontology/term/{acc_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({search_string: (encode-path-segment $search_string)} | format pattern "/pathways/diagrams/search/{search_string}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of pathways based on category provided
#
# GET /pathways/diagramsForCategory/{category}
# operationId: getPathwaysWithDiagramsForCategoryUsingGET
export def "pathways-diagrams-for-category get-with-using-get" [
  category: string
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
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/pathways/diagramsForCategory/{category}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of quantitative phenotypes values based on a combination of Clinical Measurement, Experimental Condition, Rat Strain, and/or Measurement Method ontology terms. Results will be all records that match all terms submitted. Ontology ids should be submitted as a comma delimited list (ex. RS:0000029,CMO:0000155,CMO:0000139). Species type is an integer value (3=rat, 4=chinchilla). Reference RGD ID for a study works like a filter.
#
# GET /phenotype/phenominer/chart/{speciesTypeKey}/{refRgdId}/{termString}
# operationId: getChartInfoUsingGET
export def "phenotype-phenominer-chart get-get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), ref_rgd_id: (encode-path-segment $ref_rgd_id), term_string: (encode-path-segment $term_string)} | format pattern "/phenotype/phenominer/chart/{species_type_key}/{ref_rgd_id}/{term_string}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of quantitative phenotypes values based on a combination of Clinical Measurement, Experimental Condition, Rat Strain, and/or Measurement Method ontology terms. Results will be all records that match all terms submitted. Ontology ids should be submitted as a comma delimited list (ex. RS:0000029,CMO:0000155,CMO:0000139). Species type is an integer value (3=rat, 4=chinchilla)
#
# GET /phenotype/phenominer/chart/{speciesTypeKey}/{termString}
# operationId: getChartInfoUsingGET_1
export def "phenotype-phenominer-chart get-get-using-get-by-speciesTypeKey-termString" [
  species_type_key: int
  term_string: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), term_string: (encode-path-segment $term_string)} | format pattern "/phenotype/phenominer/chart/{species_type_key}/{term_string}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list QTL for given position and assembly map
#
# GET /qtls/mapped/{chr}/{start}/{stop}/{mapKey}
# operationId: getMappedQTLByPositionUsingGET
export def "qtls-mapped get-by-position-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/qtls/mapped/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list QTL for given position and assembly map
#
# GET /qtls/{chr}/{start}/{stop}/{mapKey}
# operationId: getQtlListByPositionUsingGET
export def "qtls get-list-by-position-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/qtls/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a QTL for provided RGD ID
#
# GET /qtls/{rgdId}
# operationId: getQTLByRgdIdUsingGET
export def "qtls get-by-rgd-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/qtls/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list SSLP for given position and assembly map
#
# GET /sslps/mapped/{chr}/{start}/{stop}/{mapKey}
# operationId: getMappedSSLPByPositionUsingGET
export def "sslps-mapped get-by-position-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/sslps/mapped/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of active objects by type, for specified species and date
#
# GET /stats/count/activeObject/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getActiveObjectCountUsingGET
export def "stats-count-active-object get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/activeObject/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of gene types, for specified species and date
#
# GET /stats/count/geneType/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getGeneTypeCountUsingGET
export def "stats-count-gene-type get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/geneType/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of objects with given status, for specified species and date
#
# GET /stats/count/objectStatus/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getObjectStatusCountUsingGET
export def "stats-count-object-status get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectStatus/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of objects with reference sequence(s), by object type, for specified species and date
#
# GET /stats/count/objectWithRefSeq/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getObjectsWithRefSeqCountUsingGET
export def "stats-count-object-with-ref-seq get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectWithRefSeq/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of objects with reference, by object type, for specified species and date
#
# GET /stats/count/objectWithReference/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getObjectsWithReferenceCountUsingGET
export def "stats-count-object-with-reference get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectWithReference/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of objects with external database ids, by database id, for specified species, object type and date
#
# GET /stats/count/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateYYYYMMDD}
# operationId: getObjectsWithXDBsCountUsingGET
export def "stats-count-object-with-xdb get-xd-bs-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), object_key: (encode-path-segment $object_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/objectWithXdb/{species_type_key}/{object_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of protein interactions, for specified species and date
#
# GET /stats/count/proteinInteraction/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getProteinInteractionCountUsingGET
export def "stats-count-protein-interaction get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/proteinInteraction/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of strains, by qtl inheritance type, for specified species and date
#
# GET /stats/count/qtlInheritanceType/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getQtlInheritanceTypeCountUsingGET
export def "stats-count-qtl-inheritance-type get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/qtlInheritanceType/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of retired objects by type, for specified species and date
#
# GET /stats/count/retiredObject/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getRetiredObjectCountUsingGET
export def "stats-count-retired-object get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/retiredObject/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of strain types, for specified species and date
#
# GET /stats/count/strainType/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getStrainTypeCountUsingGET
export def "stats-count-strain-type get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/strainType/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of withdrawn objects by type, for specified species and date
#
# GET /stats/count/withdrawnObject/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getWithdrawnObjectCountUsingGET
export def "stats-count-withdrawn-object get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/withdrawnObject/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count of external database ids, for specied species and date
#
# GET /stats/count/xdb/{speciesTypeKey}/{dateYYYYMMDD}
# operationId: getXdbsCountUsingGET
export def "stats-count-xdb get-using-get" [
  species_type_key: int
  date_yyyymmdd: string
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
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_yyyymmdd: (encode-path-segment $date_yyyymmdd)} | format pattern "/stats/count/xdb/{species_type_key}/{date_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of active objects, by type, for specified species and date range
#
# GET /stats/diff/activeObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getActiveObjectDiffUsingGET
export def "stats-diff-active-object get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/activeObject/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of gene types, for specified species and date range
#
# GET /stats/diff/geneType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getGeneTypeDiffUsingGET
export def "stats-diff-gene-type get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/geneType/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of objects with given status, for specified species and date range
#
# GET /stats/diff/objectStatus/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectStatusDiffUsingGET
export def "stats-diff-object-status get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectStatus/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of objects with reference sequence(s), by object type, for specified species and date range
#
# GET /stats/diff/objectWithRefSeq/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectsWithRefSeqDiffUsingGET
export def "stats-diff-object-with-ref-seq get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectWithRefSeq/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of objects with reference, by object type, for specified species and date range
#
# GET /stats/diff/objectWithReference/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectsWithReferenceDiffUsingGET
export def "stats-diff-object-with-reference get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectWithReference/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of objects with external database ids, by database id, for specified species, object type and date range
#
# GET /stats/diff/objectWithXdb/{speciesTypeKey}/{objectKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getObjectsWithXDBsDiffUsingGET
export def "stats-diff-object-with-xdb get-xd-bs-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), object_key: (encode-path-segment $object_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/objectWithXdb/{species_type_key}/{object_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of protein interactions, for specified species and date range
#
# GET /stats/diff/proteinInteraction/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getProteinInteractionDiffUsingGET
export def "stats-diff-protein-interaction get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/proteinInteraction/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of strains, by qtl inheritance type, for specified species and date range
#
# GET /stats/diff/qtlInheritanceType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getQtlInheritanceTypeDiffUsingGET
export def "stats-diff-qtl-inheritance-type get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/qtlInheritanceType/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of retired objects, by type, for specified species and date range
#
# GET /stats/diff/retiredObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getRetiredObjectDiffUsingGET
export def "stats-diff-retired-object get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/retiredObject/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of strain types, for specified species and date range
#
# GET /stats/diff/strainType/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getStrainTypeDiffUsingGET
export def "stats-diff-strain-type get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/strainType/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of withdrawn objects, by type, for specified species and date range
#
# GET /stats/diff/withdrawnObject/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getWithdrawnObjectDiffUsingGET
export def "stats-diff-withdrawn-object get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/withdrawnObject/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count difference of external database ids, for specified species and date range
#
# GET /stats/diff/xdb/{speciesTypeKey}/{dateFromYYYYMMDD}/{dateToYYYYMMDD}
# operationId: getXdbsDiffUsingGET
export def "stats-diff-xdb get-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({species_type_key: (encode-path-segment $species_type_key), date_from_yyyymmdd: (encode-path-segment $date_from_yyyymmdd), date_to_yyyymmdd: (encode-path-segment $date_to_yyyymmdd)} | format pattern "/stats/diff/xdb/{species_type_key}/{date_from_yyyymmdd}/{date_to_yyyymmdd}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTermStats
#
# GET /stats/term/{accId}/{filterAccId}
# operationId: getTermStatsUsingGET
export def "stats-term get-using-get" [
  acc_id: string
  filter_acc_id: string
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
  let full_url = (build-url $base ({acc_id: (encode-path-segment $acc_id), filter_acc_id: (encode-path-segment $filter_acc_id)} | format pattern "/stats/term/{acc_id}/{filter_acc_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return all active strains in RGD
#
# GET /strains/all
# operationId: getAllStrainsUsingGET
export def "strains-all get-using-get" [
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
  let full_url = (build-url $base "/strains/all")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return all active strains by position
#
# GET /strains/{chr}/{start}/{stop}/{mapKey}
# operationId: getStrainsByPositionUsingGET
export def "strains get-by-position-using-get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chr: (encode-path-segment $chr), start: (encode-path-segment $start), stop: (encode-path-segment $stop), map_key: (encode-path-segment $map_key)} | format pattern "/strains/{chr}/{start}/{stop}/{map_key}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a strain by RGD ID
#
# GET /strains/{rgdId}
# operationId: getStrainByRgdIdUsingGET
export def "strains get-by-rgd-using-get" [
  rgd_id: int
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
  let full_url = (build-url $base ({rgd_id: (encode-path-segment $rgd_id)} | format pattern "/strains/{rgd_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
